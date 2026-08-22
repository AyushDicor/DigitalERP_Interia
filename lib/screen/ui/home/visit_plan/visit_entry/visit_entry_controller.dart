import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/repo/visit_entry_repo.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';
import 'package:newdigitalerp/utils/show_message.dart';

/// New Visit form + visit detail, mirroring the web ERP's Visit screen.
class VisitEntryController extends GetxController {
  final HomeController home = Get.find<HomeController>();

  String get _compId => home.currentUserData?.compId?.toString() ?? '';
  String get _branchId => home.currentUserData?.branchId?.toString() ?? '';
  String get _userId => home.currentUserData?.userid?.toString() ?? '';

  // Purpose Type — the web ERP's dropdown. Stored as free text, so this list is
  // just the common set; anything the ERP already uses still displays fine.
  static const List<String> purposeTypes = [
    'Meeting',
    'Visit',
    'Follow-Up',
    'Demo',
    'Installation',
    'Collection',
    'Support',
    'Other',
  ];

  // ── Form state ──
  final locationCtrl = TextEditingController();
  final contactPersonCtrl = TextEditingController();
  final contactNoCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final travelModeCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final outcomeCtrl = TextEditingController();

  String purposeType = '';
  DateTime? checkIn;
  DateTime? checkOut;
  DateTime visitDate = DateTime.now();

  /// Party this visit is against. Set by the caller (customer picker); the
  /// visit still saves without one, matching the web form.
  int partyId = 0;
  String visitTo = '';

  /// Files chosen on the form — uploaded after the visit exists, because the
  /// attachment store keys them by the new visit's id.
  final List<PickedAttachment> pendingAttachments = [];

  bool saving = false;

  // ── Detail state ──
  VisitDetailData? detail;
  bool detailLoading = false;
  bool uploadingAttachment = false;
  final followupCtrl = TextEditingController();

  @override
  void onClose() {
    for (final c in [
      locationCtrl, contactPersonCtrl, contactNoCtrl, distanceCtrl,
      travelModeCtrl, purposeCtrl, outcomeCtrl, followupCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  void prefillParty({required int id, required String name}) {
    partyId = id;
    visitTo = name;
    update();
  }

  void setPurposeType(String? v) {
    purposeType = v ?? '';
    update();
  }

  void setVisitDate(DateTime d) {
    visitDate = d;
    update();
  }

  void setCheckIn(DateTime? d) {
    checkIn = d;
    update();
  }

  void setCheckOut(DateTime? d) {
    checkOut = d;
    update();
  }

  String label(DateTime? d) =>
      d == null ? '' : DateFormat('dd-MM-yyyy HH:mm').format(d);

  Future<void> pickAttachments_() async {
    final picked = await pickAttachments();
    if (picked.isEmpty) return;
    pendingAttachments.addAll(picked);
    update();
  }

  void removePendingAttachment(int i) {
    if (i < 0 || i >= pendingAttachments.length) return;
    pendingAttachments.removeAt(i);
    update();
  }

  void resetForm() {
    for (final c in [
      locationCtrl, contactPersonCtrl, contactNoCtrl, distanceCtrl,
      travelModeCtrl, purposeCtrl, outcomeCtrl,
    ]) {
      c.clear();
    }
    purposeType = '';
    checkIn = null;
    checkOut = null;
    visitDate = DateTime.now();
    partyId = 0;
    visitTo = '';
    pendingAttachments.clear();
    update();
  }

  /// Saves the visit, then uploads any chosen files against its new id.
  /// Returns the new visit id, or 0 on failure.
  Future<int> saveVisit() async {
    if (purposeType.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Please select a purpose type');
      return 0;
    }
    if (checkIn != null && checkOut != null && checkOut!.isBefore(checkIn!)) {
      ShowMessage.showSnackBar('Check dates', 'Check-out is before check-in');
      return 0;
    }

    saving = true;
    update();
    try {
      final fields = <String, dynamic>{
        'compid': _compId,
        'branchid': _branchId,
        'userid': _userId,
        'visitedbyid': _userId,
        'visitdate': DateFormat('yyyy-MM-dd').format(visitDate),
        if (partyId > 0) 'partyid': partyId.toString(),
        if (visitTo.isNotEmpty) 'visitto': visitTo,
        'purposetype': purposeType,
        'purpose': purposeCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'contactperson': contactPersonCtrl.text.trim(),
        'contactno': contactNoCtrl.text.trim(),
        if (checkIn != null)
          'checkintime': DateFormat('yyyy-MM-dd HH:mm').format(checkIn!),
        if (checkOut != null)
          'checkouttime': DateFormat('yyyy-MM-dd HH:mm').format(checkOut!),
        'distancekm': distanceCtrl.text.trim(),
        'travelmode': travelModeCtrl.text.trim(),
        'outcome': outcomeCtrl.text.trim(),
        'status': checkOut != null ? 'Completed' : 'Pending',
      };

      final res = await VisitEntryRepo.save(fields);
      if (res.id <= 0) {
        ShowMessage.showSnackBar('Error', res.error ?? 'Could not save visit');
        return 0;
      }

      await _uploadPending(res.id);
      resetForm();
      ShowMessage.showSnackBar('Success', 'Visit ${res.visitNo} saved');
      return res.id;
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
      return 0;
    } finally {
      saving = false;
      update();
    }
  }

  /// /visit/save ignores an uploaded file, so attachments go to the shared
  /// store keyed by ('Visit', visitId) — which /visit/detail reads back.
  Future<void> _uploadPending(int visitId) async {
    for (final file in pendingAttachments) {
      final err = await AttachmentRepo.upload(
        filePath: file.path,
        compid: _compId,
        modulekey: VisitEntryRepo.moduleKey,
        recordid: visitId,
        userid: _userId,
      );
      if (err != null) {
        ShowMessage.showSnackBar('Attachment', '${file.name}: $err');
      }
    }
  }

  // ── Detail ──

  Future<void> loadDetail(int id) async {
    detailLoading = true;
    detail = null;
    update();
    try {
      detail = await VisitEntryRepo.detail(compid: _compId, id: id);
    } finally {
      detailLoading = false;
      update();
    }
  }

  Future<void> addAttachmentToVisit(int visitId) async {
    final picked = await pickAttachments();
    if (picked.isEmpty) return;
    uploadingAttachment = true;
    update();
    try {
      for (final file in picked) {
        final err = await AttachmentRepo.upload(
          filePath: file.path,
          compid: _compId,
          modulekey: VisitEntryRepo.moduleKey,
          recordid: visitId,
          userid: _userId,
        );
        if (err != null) {
          ShowMessage.showSnackBar('Attachment', '${file.name}: $err');
        }
      }
    } finally {
      uploadingAttachment = false;
      update();
      await loadDetail(visitId);
    }
  }

  Future<void> deleteAttachment(int attachmentId, int visitId) async {
    final ok = await AttachmentRepo.delete(compid: _compId, id: attachmentId);
    if (!ok) {
      ShowMessage.showSnackBar('Attachment', 'Could not remove the file');
      return;
    }
    await loadDetail(visitId);
  }

  Future<void> addFollowup(int visitId) async {
    final text = followupCtrl.text.trim();
    if (text.isEmpty) return;
    final ok = await VisitEntryRepo.addFollowup(
        compid: _compId, id: visitId, comment: text, userid: _userId);
    if (!ok) {
      ShowMessage.showSnackBar('Followup', 'Could not add the followup');
      return;
    }
    followupCtrl.clear();
    await loadDetail(visitId);
  }
}
