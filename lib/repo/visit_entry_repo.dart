import 'dart:convert';
import 'dart:developer';

import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/repo/base_api_helper.dart';
import 'package:newdigitalerp/repo/base_url.dart';

/// Visit entry API — the same endpoints the web ERP's Visit screen uses.
///
/// Contract verified against the live API on 2026-08-17:
///   POST /api/visit/save    json  -> {id, visitno}
///   POST /api/visit/detail  json  -> {visit, attachments[], followups[]}
///   POST /api/visit/list    json  -> rows
///   POST /api/visit/delete  json
///   POST /api/visit/addfollowup   (compid, id, comment)
///
/// ⚠️ Two things learned the hard way:
///  * Passing `id` to /visit/save (i.e. an UPDATE) returns HTTP 500 — the
///    update path is broken server-side. Create works. [see saveVisit]
///  * /visit/save IGNORES an uploaded file. Attachments must go separately to
///    /api/attachment/upload with modulekey 'Visit' and the visit id — which
///    /visit/attachments and /visit/detail both read back.
class VisitEntryRepo {
  static const String moduleKey = 'Visit';

  /// Creates a visit. Returns the new id, or 0 with [error] set.
  ///
  /// Do NOT pass an existing id hoping to update — the server 500s on that.
  static Future<({int id, String visitNo, String? error})> save(
      Map<String, dynamic> fields) async {
    final url = AppUrls.baseUrl + 'visit/save';
    try {
      // BaseApiHelper only prints the status code, so log the request and the
      // response here — otherwise Submit shows nothing useful in the console.
      log('POST $url');
      log('visit/save REQ => ${jsonEncode(fields)}');

      final res = await BaseApiHelper.postRequest(url, fields);
      log('visit/save RES => ${jsonEncode(res.data)}');

      final body = res.data as Map<String, dynamic>?;
      if (body == null || body['success'] != true) {
        return (id: 0, visitNo: '', error: body?['message']?.toString() ?? res.message ?? 'Save failed');
      }
      final data = body['data'] as Map<String, dynamic>?;
      return (
        id: int.tryParse('${data?['id'] ?? 0}') ?? 0,
        visitNo: '${data?['visitno'] ?? ''}',
        error: null,
      );
    } catch (e) {
      log('visit/save failed: $e');
      return (id: 0, visitNo: '', error: e.toString());
    }
  }

  /// Purpose Type / Status / Travel Mode option lists (/api/visit/dropdowns).
  /// Returns empty lists on failure so callers can fall back to their defaults.
  static Future<VisitDropdowns> dropdowns({required String compid}) async {
    try {
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'visit/dropdowns', {'compid': compid});
      final data = (res.data as Map<String, dynamic>?)?['data'];
      if (data is! Map) return const VisitDropdowns();
      List<String> pick(String key) =>
          (data[key] is List) ? (data[key] as List).map((e) => '$e').toList() : const [];
      return VisitDropdowns(
        purposeTypes: pick('purposeTypes'),
        statuses: pick('statuses'),
        travelModes: pick('travelModes'),
      );
    } catch (e) {
      log('visit/dropdowns failed: $e');
      return const VisitDropdowns();
    }
  }

  /// Full visit record + its attachments + followups, in one call.
  static Future<VisitDetailData?> detail(
      {required String compid, required int id}) async {
    try {
      log('POST ${AppUrls.baseUrl}visit/detail {compid: $compid, id: $id}');
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'visit/detail', {'compid': compid, 'id': id});
      final body = res.data as Map<String, dynamic>?;
      final data = body?['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      log('visit/detail RES => ${jsonEncode(data)}');
      return VisitDetailData.fromJson(data);
    } catch (e) {
      log('visit/detail failed: $e');
      return null;
    }
  }

  static Future<List<VisitListRow>> list(
      {required String compid, String? userid}) async {
    try {
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'visit/list',
          {'compid': compid, if (userid != null) 'userid': userid});
      final data = (res.data as Map<String, dynamic>?)?['data'];
      if (data is! List) return [];
      return data.whereType<Map>().map(VisitListRow.fromJson).toList();
    } catch (e) {
      log('visit/list failed: $e');
      return [];
    }
  }

  static Future<bool> delete(
      {required String compid, required int id, String? userid}) async {
    try {
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'visit/delete',
          {'compid': compid, 'id': id, if (userid != null) 'userid': userid});
      return (res.data as Map<String, dynamic>?)?['success'] == true;
    } catch (e) {
      log('visit/delete failed: $e');
      return false;
    }
  }

  static Future<bool> addFollowup({
    required String compid,
    required int id,
    required String comment,
    String? userid,
  }) async {
    try {
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'visit/addfollowup', {
        'compid': compid,
        'id': id,
        'comment': comment,
        if (userid != null) 'userid': userid,
      });
      return (res.data as Map<String, dynamic>?)?['success'] == true;
    } catch (e) {
      log('visit/addfollowup failed: $e');
      return false;
    }
  }
}

/// Option lists for the visit form. Defaults mirror what the live API returns,
/// so the form still works if the call fails.
class VisitDropdowns {
  final List<String> purposeTypes;
  final List<String> statuses;
  final List<String> travelModes;

  const VisitDropdowns({
    this.purposeTypes = const [],
    this.statuses = const [],
    this.travelModes = const [],
  });

  bool get isEmpty =>
      purposeTypes.isEmpty && statuses.isEmpty && travelModes.isEmpty;

  static const List<String> defaultPurposeTypes = [
    'Sales', 'Service', 'Collection', 'Meeting', 'Delivery', 'Follow-up', 'Other',
  ];
  static const List<String> defaultStatuses = ['Completed', 'Planned', 'Cancelled'];
  static const List<String> defaultTravelModes = [
    'Car', 'Bike', 'Cab', 'Bus', 'Train', 'Flight', 'Own Vehicle', 'Walk', 'Other',
  ];
}

String _s(dynamic v) => v == null ? '' : v.toString();
int _i(dynamic v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);

class VisitListRow {
  final int id;
  final String visitNo, visitDate, visitedBy, visitTo, purposeType, location,
      contactPerson, status;

  const VisitListRow({
    required this.id,
    required this.visitNo,
    required this.visitDate,
    required this.visitedBy,
    required this.visitTo,
    required this.purposeType,
    required this.location,
    required this.contactPerson,
    required this.status,
  });

  factory VisitListRow.fromJson(Map j) => VisitListRow(
        id: _i(j['Id']),
        visitNo: _s(j['VisitNo']),
        visitDate: _s(j['VisitDate']),
        visitedBy: _s(j['VisitedByName']),
        visitTo: _s(j['VisitTo']),
        purposeType: _s(j['PurposeType']),
        location: _s(j['Location']),
        contactPerson: _s(j['ContactPerson']),
        status: _s(j['Status']),
      );
}

/// One visit with everything the web ERP's detail pane shows.
class VisitDetailData {
  final int id;
  final String visitNo, visitDate, visitedBy, visitTo, purposeType, purpose,
      location, contactPerson, contactNo, checkIn, checkOut, travelMode,
      outcome, status, createdBy, areaName;
  final double distanceKm;
  final List<AttachmentItem> attachments;
  final List<VisitFollowup> followups;

  const VisitDetailData({
    required this.id,
    required this.visitNo,
    required this.visitDate,
    required this.visitedBy,
    required this.visitTo,
    required this.purposeType,
    required this.purpose,
    required this.location,
    required this.contactPerson,
    required this.contactNo,
    required this.checkIn,
    required this.checkOut,
    required this.travelMode,
    required this.outcome,
    required this.status,
    required this.createdBy,
    required this.areaName,
    required this.distanceKm,
    required this.attachments,
    required this.followups,
  });

  factory VisitDetailData.fromJson(Map<String, dynamic> data) {
    final v = (data['visit'] is Map)
        ? data['visit'] as Map
        : const <String, dynamic>{};
    final att = (data['attachments'] is List) ? data['attachments'] as List : [];
    final fol = (data['followups'] is List) ? data['followups'] as List : [];
    return VisitDetailData(
      id: _i(v['Id']),
      visitNo: _s(v['VisitNo']),
      // The API sends both a raw timestamp and a display string; prefer the latter.
      visitDate: _s(v['VisitDateText']).isNotEmpty
          ? _s(v['VisitDateText'])
          : _s(v['VisitDate']),
      visitedBy: _s(v['VisitedByName']),
      visitTo: _s(v['VisitTo']),
      purposeType: _s(v['PurposeType']),
      purpose: _s(v['Purpose']),
      location: _s(v['Location']),
      contactPerson: _s(v['ContactPerson']),
      contactNo: _s(v['ContactNo']),
      checkIn: _s(v['CheckInText']),
      checkOut: _s(v['CheckOutText']),
      travelMode: _s(v['TravelMode']),
      outcome: _s(v['Outcome']),
      status: _s(v['Status']),
      createdBy: _s(v['CreatedByName']),
      areaName: _s(v['AreaName']),
      distanceKm: v['DistanceKm'] == null
          ? 0
          : double.tryParse('${v['DistanceKm']}') ?? 0,
      attachments:
          att.whereType<Map>().map(AttachmentItem.fromJson).toList(),
      followups: fol.whereType<Map>().map(VisitFollowup.fromJson).toList(),
    );
  }
}

class VisitFollowup {
  final int id;
  final String comment, byName, date;
  const VisitFollowup(
      {required this.id,
      required this.comment,
      required this.byName,
      required this.date});

  factory VisitFollowup.fromJson(Map j) => VisitFollowup(
        id: _i(j['Id'] ?? j['id']),
        comment: _s(j['Comment'] ?? j['comment'] ?? j['CommentText']),
        byName: _s(j['CreatedByName'] ?? j['UserName'] ?? j['createdbyname']),
        date: _s(j['CreatedDateText'] ?? j['CreatedDate'] ?? j['createddate']),
      );
}
