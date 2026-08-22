import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:newdigitalerp/repo/base_api_helper.dart';
import 'package:newdigitalerp/repo/base_url.dart';
import 'package:newdigitalerp/services/api_service/api_client.dart';

/// Shared attachment store: files are keyed by (compid, modulekey, recordid) and
/// live in their own table, not on the parent document. Any module can use it —
/// pass its own `modulekey` ("Task", "Visit", …) and the record's id.
///
///   POST /api/attachment/upload   multipart: compid, modulekey, recordid, file
///   POST /api/attachment/list     json: compid, modulekey, recordid
///   POST /api/attachment/delete   json: compid, id
///
/// `list` returns presigned S3 URLs that expire (1 hour), so always re-fetch
/// rather than caching the Url long-term.
/// The `modulekey` each module files its attachments under.
///
/// ⚠️ The API does NOT validate this string — `modulekey: "ZZZNONSENSE"` is
/// accepted and returns an empty list. The key also becomes the S3 folder
/// (`company-2/<modulekey>/<recordid>/…`). So a key the web ERP doesn't read
/// means files upload "successfully" and are invisible forever.
///
/// Only add a constant here once the backend has confirmed the exact string,
/// and only after checking whether the ERP reads this store for that module or
/// still reads the file key saved on the document itself.
class AttachmentModule {
  /// Confirmed: /api/attachment/list returns real files for Task 41 and 44.
  static const String task = 'Task';

  /// Confirmed working: upload returns `2/Visit/<visitId>/…`, and
  /// /api/visit/attachments reads it back.
  static const String visit = 'Visit';

  /// Attendance selfies. A punch has no id of its own, so the record id is the
  /// **userid** — keys look like `2/Attendance/<userid>/<timestamp>_name.jpg`.
  static const String attendance = 'Attendance';

  // Awaiting confirmation from the backend team — do NOT guess these:
  //   purchaseOrder, saleOrder/performa, mrn, grn, indent,
  //   reimbursement, paymentRequest, visit, approval
}

class AttachmentRepo {
  /// Deprecated alias — use [AttachmentModule.task].
  static const String moduleTask = AttachmentModule.task;

  static const _upload = 'attachment/upload';
  static const _list = 'attachment/list';
  static const _delete = 'attachment/delete';

  /// Files attached to one record, newest first as the API returns them.
  static Future<List<AttachmentItem>> list({
    required String compid,
    required String modulekey,
    required int recordid,
  }) async {
    if (recordid <= 0) return [];
    try {
      final res = await BaseApiHelper.postRequest(
        AppUrls.baseUrl + _list,
        {'compid': compid, 'modulekey': modulekey, 'recordid': recordid},
      );
      final data = (res.data as Map<String, dynamic>?)?['data'];
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map(AttachmentItem.fromJson)
          .toList();
    } catch (e) {
      log('attachment/list failed: $e');
      return [];
    }
  }

  /// Uploads one file against a record. Returns null on success, else a message.
  static Future<String?> upload({
    required String filePath,
    required String compid,
    required String modulekey,
    required int recordid,
    String? userid,
  }) async =>
      (await uploadReturningKey(
        filePath: filePath,
        compid: compid,
        modulekey: modulekey,
        recordid: recordid,
        userid: userid,
      ))
          .error;

  /// Same upload, but also hands back the stored `objectKey` — needed where the
  /// caller has to persist the reference itself (e.g. the attendance row keeps
  /// its selfie in a `photo` column rather than in the attachment list).
  static Future<({String? error, String objectKey})> uploadReturningKey({
    required String filePath,
    required String compid,
    required String modulekey,
    required int recordid,
    String? userid,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(AppUrls.baseUrl + _upload));
      // Multipart bypasses the shared header builder — send the key explicitly.
      request.headers['X-Api-Key'] = ApiClient.apiKey;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      request.fields['compid'] = compid;
      request.fields['modulekey'] = modulekey;
      request.fields['recordid'] = recordid.toString();
      if (userid != null) request.fields['userid'] = userid;

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      log('attachment/upload [${streamed.statusCode}]: $body');

      if (streamed.statusCode != 200) {
        return (error: 'Upload failed (${streamed.statusCode})', objectKey: '');
      }
      final map = jsonDecode(body) as Map<String, dynamic>;
      if (map['success'] != true) {
        return (
          error: map['message']?.toString() ?? 'Upload failed',
          objectKey: ''
        );
      }
      // data is a list — one entry per uploaded file.
      final data = map['data'];
      final first = (data is List && data.isNotEmpty) ? data.first : null;
      final key = (first is Map ? first['objectKey'] : null)?.toString() ?? '';
      return (error: null, objectKey: key);
    } catch (e) {
      log('attachment/upload exception: $e');
      return (error: e.toString(), objectKey: '');
    }
  }

  /// Removes one attachment by its row id.
  static Future<bool> delete({
    required String compid,
    required int id,
  }) async {
    try {
      final res = await BaseApiHelper.postRequest(
        AppUrls.baseUrl + _delete,
        {'compid': compid, 'id': id},
      );
      return (res.data as Map<String, dynamic>?)?['success'] == true;
    } catch (e) {
      log('attachment/delete failed: $e');
      return false;
    }
  }
}

class AttachmentItem {
  final int id;
  final String fileName;
  final String fileExt;
  final int fileSize;
  final String objectKey;
  final String uploadedBy;
  final String uploadedDate;
  /// Presigned download URL — expires, so don't persist it.
  final String url;

  const AttachmentItem({
    required this.id,
    required this.fileName,
    required this.fileExt,
    required this.fileSize,
    required this.objectKey,
    required this.uploadedBy,
    required this.uploadedDate,
    required this.url,
  });

  factory AttachmentItem.fromJson(Map j) => AttachmentItem(
        id: int.tryParse('${j['Id'] ?? j['id'] ?? 0}') ?? 0,
        fileName: '${j['FileName'] ?? j['filename'] ?? ''}',
        fileExt: '${j['FileExt'] ?? j['fileext'] ?? ''}',
        fileSize: int.tryParse('${j['FileSize'] ?? j['filesize'] ?? 0}') ?? 0,
        objectKey: '${j['ObjectKey'] ?? j['objectkey'] ?? ''}',
        uploadedBy: '${j['UploadedByName'] ?? j['uploadedbyname'] ?? ''}',
        uploadedDate: '${j['UploadedDate'] ?? j['uploadeddate'] ?? ''}',
        url: '${j['Url'] ?? j['url'] ?? ''}',
      );

  bool get isImage =>
      const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp']
          .contains(fileExt.toLowerCase());

  bool get isPdf => fileExt.toLowerCase() == 'pdf';

  /// "313 KB" / "2.4 MB"
  String get sizeLabel {
    if (fileSize <= 0) return '';
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).round()} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
