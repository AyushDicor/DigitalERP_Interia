import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/response/preview_visit_data_response.dart';
import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/screen/ui/home/visit_plan/visit_plan_controller.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/repo/visit_entry_repo.dart';
import 'package:newdigitalerp/screen/ui/home/visit_plan/new_visit_planing/new_visit_planing_controller.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import '../../../../../../home/home_contoller.dart';

class PreviewController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();
  VisitPlanController visitPlanController = Get.find<VisitPlanController>();

  List<PreviewVisitDataList> previewVisitDataList = [];

  // ── Visit details (same field set as the web ERP's New Visit form) ────────
  // Captured here and sent with the /api/visit/save call on Submit.

  // Option lists come from /api/visit/dropdowns; the defaults below are only a
  // fallback if that call fails. Do NOT hardcode guesses here — the ERP's real
  // statuses are Completed / Planned / Cancelled ("Pending" is not valid).
  List<String> purposeTypes = VisitDropdowns.defaultPurposeTypes;
  List<String> statuses = VisitDropdowns.defaultStatuses;
  List<String> travelModes = VisitDropdowns.defaultTravelModes;

  /// Who / what was visited — the web form's required
  /// "Visited (party / place / person)" field.
  final visitedCtrl = TextEditingController();
  String status = 'Completed'; // same default as the web form
  String travelMode = '';

  void setStatus(String? v) { status = v ?? 'Completed'; update(); }
  void setTravelMode(String? v) { travelMode = v ?? ''; update(); }

  Future<void> loadDropdowns() async {
    final compid = homeController.currentUserData?.compId.toString() ?? '';
    if (compid.isEmpty) return;
    final d = await VisitEntryRepo.dropdowns(compid: compid);
    if (d.isEmpty) return;
    if (d.purposeTypes.isNotEmpty) purposeTypes = d.purposeTypes;
    if (d.statuses.isNotEmpty) {
      statuses = d.statuses;
      if (!statuses.contains(status)) status = statuses.first;
    }
    if (d.travelModes.isNotEmpty) travelModes = d.travelModes;
    update();
  }

  final locationCtrl = TextEditingController();
  final contactPersonCtrl = TextEditingController();
  final contactNoCtrl = TextEditingController();
  final distanceCtrl = TextEditingController();
  final purposeCtrl = TextEditingController();
  final outcomeCtrl = TextEditingController();

  String purposeType = '';
  DateTime? checkIn;
  DateTime? checkOut;

  /// Files chosen for this visit — uploaded after the plan is saved.
  final List<PickedAttachment> pendingAttachments = [];
  bool uploadingAttachment = false;

  void setPurposeType(String? v) { purposeType = v ?? ''; update(); }
  void setCheckIn(DateTime? d) { checkIn = d; update(); }
  void setCheckOut(DateTime? d) { checkOut = d; update(); }

  String dtLabel(DateTime? d) =>
      d == null ? '' : DateFormat('dd-MM-yyyy HH:mm').format(d);

  Future<void> pickVisitAttachments() async {
    final picked = await pickAttachments();
    if (picked.isEmpty) return;
    pendingAttachments.addAll(picked);
    update();
  }

  void removeAttachment(int i) {
    if (i < 0 || i >= pendingAttachments.length) return;
    pendingAttachments.removeAt(i);
    update();
  }

  @override
  void onClose() {
    for (final c in [
      visitedCtrl, locationCtrl, contactPersonCtrl, contactNoCtrl,
      distanceCtrl, purposeCtrl, outcomeCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
  @override
  void onInit() {
    // TODO: implement onInit
    previewAddedVisitList();
    loadDropdowns();
    super.onInit();
  }

  void tapOnCard() {
    Get.toNamed(AppRoutes.visitPlanDetail);
  }

  void tapOnSubmit() async {
    bool isSuccess = await submitAndSaveVisit();

    if (isSuccess) {
      debugPrint('______________${isSuccess}_________');

      backTap();
      //

      //Get.offNamed(AppRoutes.home);
    } else {}
  }

  tapOnDelete(int index) async {
    await deleteVisitAtIndex(index);
    if (previewVisitDataList.isEmpty) {
      backTap();
    }
    update();
  }

  Future<void> previewAddedVisitList() async {
    isBusy = true;
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? '39';

      var res = await api.previewVisitData(body);
      if (res.status == 200) {
        previewVisitDataList = res.data ?? [];
        update();
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBusy = false;
    }
  }

  Future<void> deleteVisitAtIndex(int index) async {
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? '39';
      body[RequestKeys.id] = previewVisitDataList[index].id.toString();

      var res = await api.deleteVisitData(body);
      if (res.status == 200) {
        previewVisitDataList.removeAt(index);
        //
        if (previewVisitDataList.isEmpty) {
          backTap(msg: res.message.toString());
        } else {
          ShowMessage.showSnackBar('Server Res', res.message.toString());
        }
        update();
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBusy = false;
    }
  }

  /// The preview rows come back from the API without a partyid, so resolve it
  /// by name from the customer picker while that screen is still in memory.
  /// Returns 0 when it can't be determined — partyid is optional on save.
  int _partyIdFor(String? clientName) {
    final name = (clientName ?? '').trim().toLowerCase();
    if (name.isEmpty) return 0;
    if (!Get.isRegistered<NewVisitPlaningController>()) return 0;
    try {
      final list = Get.find<NewVisitPlaningController>().visitPlanCustomerList;
      for (final c in list) {
        if ((c.customername ?? '').trim().toLowerCase() == name) {
          return c.partyid ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Removes the staged rows this screen previewed, so they don't reappear
  /// next time. Not a save — the visits themselves are already stored by
  /// /api/visit/save; these are just the leftover add-to-list entries.
  Future<void> _clearStagedRows() async {
    final compid = homeController.currentUserData?.compId.toString() ?? '';
    final userid = homeController.currentUserData?.userid.toString() ?? '';
    for (final row in List.of(previewVisitDataList)) {
      if (row.id == null) continue;
      try {
        await api.deleteVisitData({
          RequestKeys.compId: compid,
          RequestKeys.userId: userid,
          RequestKeys.id: row.id.toString(),
        });
      } catch (_) {/* best-effort cleanup — never fail the save for this */}
    }
    previewVisitDataList.clear();
  }

  /// Saves each previewed customer as a visit through /api/visit/save — the
  /// single save endpoint, the same one the web ERP uses. Files then go to the
  /// shared attachment store keyed by ('Visit', visitId), which /visit/detail
  /// and /visit/attachments both read back.
  Future<bool> submitAndSaveVisit() async {
    final String date = formatDate(
        previewVisitDataList.first.visitdate ?? "", 'dd-MM-yyyy', 'yyyy-MM-dd');
    final compid = homeController.currentUserData?.compId.toString() ?? '';
    final branchid = homeController.currentUserData?.branchId.toString() ?? '';
    final userid = homeController.currentUserData?.userid.toString() ?? '';

    if (visitedCtrl.text.trim().isEmpty && previewVisitDataList.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Please enter who was visited');
      return false;
    }

    try {
      // Detail fields shared by every visit saved from this screen.
      // Param names follow the backend's published contract for /api/visit/save:
      // compid, id(0=new), userid, branchid, visitdate, visitto, partyid,
      // purposetype, location, contactperson, contactno, checkin, checkout,
      // distance, travelmode, purpose, outcome, status, yearid.
      final details = <String, dynamic>{
        'compid': compid,
        'id': 0, // 0 = create a new visit
        'userid': userid,
        'branchid': branchid,
        'yearid': homeController.currentUserData?.yearId?.toString() ?? '',
        'visitdate': date,
        'status': status,
        'purposetype': purposeType,
        'purpose': purposeCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'contactperson': contactPersonCtrl.text.trim(),
        'contactno': contactNoCtrl.text.trim(),
        'distance': distanceCtrl.text.trim(),
        'travelmode': travelMode,
        'outcome': outcomeCtrl.text.trim(),
        if (checkIn != null)
          'checkin': DateFormat('yyyy-MM-dd HH:mm').format(checkIn!),
        if (checkOut != null)
          'checkout': DateFormat('yyyy-MM-dd HH:mm').format(checkOut!),
      };

      final typedVisitTo = visitedCtrl.text.trim();
      final savedIds = <int>[];

      for (final row in previewVisitDataList) {
        // "Visited (party / place / person)" — the typed value wins, else the
        // customer this row was planned against. Party itself is optional on
        // the web form and the preview rows don't carry a partyid.
        final partyId = _partyIdFor(row.clientname);
        final body = Map<String, dynamic>.from(details)
          ..['visitto'] =
              typedVisitTo.isNotEmpty ? typedVisitTo : (row.clientname ?? '')
          ..['location'] = locationCtrl.text.trim().isNotEmpty
              ? locationCtrl.text.trim()
              : (row.areaname ?? '');
        if (partyId > 0) body['partyid'] = partyId.toString();

        final res = await VisitEntryRepo.save(body);
        if (res.id > 0) {
          savedIds.add(res.id);
        } else {
          ShowMessage.showSnackBar(
              'Visit', res.error ?? 'Could not save ${row.clientname ?? ''}');
        }
      }

      if (savedIds.isEmpty) return false;
      await _uploadAttachments(savedIds);
      await _clearStagedRows();

      backTap(msg: 'Visit saved');
      return true;
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
      return false;
    } finally {
      isBusy = false;
    }
  }

  /// Attaches the chosen files to every visit created by this submit.
  Future<void> _uploadAttachments(List<int> visitIds) async {
    if (pendingAttachments.isEmpty || visitIds.isEmpty) return;
    uploadingAttachment = true;
    update();
    try {
      final compid = homeController.currentUserData?.compId.toString() ?? '';
      final userid = homeController.currentUserData?.userid.toString() ?? '';
      for (final visitId in visitIds) {
        for (final f in pendingAttachments) {
          final err = await AttachmentRepo.upload(
            filePath: f.path,
            compid: compid,
            modulekey: VisitEntryRepo.moduleKey, // 'Visit'
            recordid: visitId,
            userid: userid,
          );
          if (err != null) {
            ShowMessage.showSnackBar('Attachment', '${f.name}: $err');
          }
        }
      }
      pendingAttachments.clear();
    } finally {
      uploadingAttachment = false;
      update();
    }
  }
}
