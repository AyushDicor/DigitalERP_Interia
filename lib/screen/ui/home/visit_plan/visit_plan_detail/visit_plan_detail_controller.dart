import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/repo/visit_entry_repo.dart';
import 'package:newdigitalerp/response/all_visit_data_response.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';
import 'package:newdigitalerp/response/visit_check_in_response.dart';
import 'package:newdigitalerp/response/visit_check_out_response.dart';
import 'package:newdigitalerp/response/visit_plan_detail_data_response.dart';
import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/shared_pre.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../../home/home_contoller.dart';

class VisitPlanDetailController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  VisitListData? argument;
  String? visitId;
  List<VisitPlanDetailsDataList> visitPlanDetailList = [];
  List<VisitCheckInData> visitCheckInList = [];
  List<VisitCheckOutData> visitCheckOutList = [];
  TextEditingController remarkController = TextEditingController();

  @override
  void onInit() {
    // TODO: implement onInit
    argument = Get.arguments;
    getVisitPlanDetailList();
    super.onInit();
  }

  void tapOnStock(VisitPlanDetailsDataList item) {
    Get.toNamed(AppRoutes.stockTakingView, arguments: item.partyid);
  }

  void tapOnOrder(int index) async {
    if (visitPlanDetailList[index].checkstatus == 'Check In') {
    } else if (visitPlanDetailList[index].checkstatus == 'Check Out') {
      ///object convert in json and then saved

      await SharedPre.setValue(SharedPre.selectedCustomer2, visitPlanDetailList[index].toJson());
      Get.toNamed(AppRoutes.orderList, arguments: visitPlanDetailList[index]);
    }
  }

  void tapOnCheckIn(int index) {
    checkInCustomer(index);
    visitPlanDetailList[index].checkstatus = 'Check Out';
    update();
  }

  void tapOnCheckOut(int index) {
    if (visitCheckOutList.isEmpty ? false : visitCheckOutList[index].checkstatus == '') {
    } else {
      checkOutCustomer(index);
      visitPlanDetailList[index].checkstatus = '';
      update();
    }
  }

  void tapOnPayment(int? partyid) {
    Get.toNamed(AppRoutes.collection, arguments: partyid.toString());
  }

  /// Attachments and followups on the open visit, from /api/visit/detail.
  List<AttachmentItem> attachments = [];
  List<VisitFollowup> followups = [];
  bool uploadingAttachment = false;
  final followupCtrl = TextEditingController();

  int get _visitId => argument?.visitid ?? 0;
  String get _compId => homeController.currentUserData?.compId.toString() ?? '';
  String get _userId => homeController.currentUserData?.userid.toString() ?? '';

  /// Reads the visit from /api/visit/detail and maps it into the same row model
  /// the screen already renders, so all the web-ERP fields show up. Also picks
  /// up the attachments and followups the same call returns.
  Future<bool> _loadFromVisitApi() async {
    if (_visitId <= 0) return false;
    final detail = await VisitEntryRepo.detail(compid: _compId, id: _visitId);
    if (detail == null) return false;

    attachments = detail.attachments;
    followups = detail.followups;
    visitPlanDetailList = [
      VisitPlanDetailsDataList.fromJson({
        'Customername': detail.visitTo,
        'VisitNo': detail.visitNo,
        'visitdate': detail.visitDate,
        'visittime': detail.checkIn,
        'Status': detail.status,
        'DistanceKm': detail.distanceKm,
        'PurposeType': detail.purposeType,
        'Purpose': detail.purpose,
        'Location': detail.location,
        'ContactPerson': detail.contactPerson,
        'ContactNo': detail.contactNo,
        'TravelMode': detail.travelMode,
        'Outcome': detail.outcome,
        'CheckInText': detail.checkIn,
        'CheckOutText': detail.checkOut,
      })
    ];
    return true;
  }

  Future<void> addAttachment() async {
    if (_visitId <= 0) return;
    final picked = await pickAttachments();
    if (picked.isEmpty) return;
    uploadingAttachment = true;
    update();
    try {
      for (final f in picked) {
        final err = await AttachmentRepo.upload(
          filePath: f.path,
          compid: _compId,
          modulekey: VisitEntryRepo.moduleKey,
          recordid: _visitId,
          userid: _userId,
        );
        if (err != null) ShowMessage.showSnackBar('Attachment', '${f.name}: $err');
      }
    } finally {
      uploadingAttachment = false;
      await getVisitPlanDetailList();
    }
  }

  Future<void> removeAttachment(int attachmentId) async {
    final ok = await AttachmentRepo.delete(compid: _compId, id: attachmentId);
    if (!ok) {
      ShowMessage.showSnackBar('Attachment', 'Could not remove the file');
      return;
    }
    await getVisitPlanDetailList();
  }

  Future<void> addFollowup() async {
    final text = followupCtrl.text.trim();
    if (text.isEmpty || _visitId <= 0) return;
    final ok = await VisitEntryRepo.addFollowup(
        compid: _compId, id: _visitId, comment: text, userid: _userId);
    if (!ok) {
      ShowMessage.showSnackBar('Followup', 'Could not add the followup');
      return;
    }
    followupCtrl.clear();
    await getVisitPlanDetailList();
  }

  /// Removes the whole visit (/api/visit/delete).
  Future<void> deleteVisit() async {
    if (_visitId <= 0) return;
    final ok = await VisitEntryRepo.delete(
        compid: _compId, id: _visitId, userid: _userId);
    if (!ok) {
      ShowMessage.showSnackBar('Visit', 'Could not delete this visit');
      return;
    }
    backTap(msg: 'Visit deleted');
  }

  Future<void> getVisitPlanDetailList() async {
    isBusy = true;
    final location = await getUserCurrentPosition();
    try {
      //visitPlanDetailList.clear();
      Map<String, String> body = {};
      body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? ''; //39.toString();
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? ''; //39.toString();
      body[RequestKeys.visitId] = argument?.visitid.toString() ?? ''; //39.toString();
      body[RequestKeys.latitude] = location.latitude.toString(); //39.toString();
      body[RequestKeys.longitude] = location.longitude.toString(); //39.toString();

      // /api/visit/detail is the source now — the list's row id is a VISIT id,
      // and only this endpoint carries the full record plus its attachments
      // and followups. The legacy endpoint stays as a fallback for older plan
      // rows whose ids belong to the previous API.
      final loaded = await _loadFromVisitApi();
      if (!loaded) {
        var res = await api.visitPlanDetailListData(body);
        if (res.status == 200) visitPlanDetailList = res.data ?? [];
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBusy = false;
      update();
    }
  }

  Future<void> checkInCustomer(int index) async {
    isBusy = true;

    final location = await getUserCurrentPosition();
    final address = await getUserCurrentAddress();

    try {
      //visitPlanDetailList.clear();
      Map<String, String> body = {};
      body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? ''; //39.toString();
      body[RequestKeys.branchId] = homeController.currentUserData?.branchId.toString() ?? ''; //39.toString();
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? ''; //39.toString();
      body[RequestKeys.partyId] = visitPlanDetailList[index].partyid.toString(); //39.toString();
      body[RequestKeys.visitId] = argument?.visitid.toString() ?? ''; //39.toString();
      body[RequestKeys.latitude] = location.latitude.toString(); //39.toString();
      body[RequestKeys.longitude] = location.longitude.toString(); //39.toString();
      body[RequestKeys.location] = address; //39.toString();

      var res = await api.visitCheckInData(body);
      if (res.status == 200) {
        visitCheckInList = res.data ?? [];
      } else {
        //ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBusy = false;
      update();
    }
  }

  Future<void> checkOutCustomer(int index) async {
    isBusy = true;
    final location = await getUserCurrentPosition();
    final address = await getUserCurrentAddress();
    try {
      //visitPlanDetailList.clear();
      Map<String, String> body = {};
      body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? ''; //39.toString();
      body[RequestKeys.branchId] = homeController.currentUserData?.branchId.toString() ?? ''; //39.toString();
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? ''; //39.toString();
      body[RequestKeys.partyId] = visitPlanDetailList[index].partyid.toString(); //39.toString();
      body[RequestKeys.visitId] = argument?.visitid.toString() ?? ''; //39.toString();
      body[RequestKeys.latitude] = location.latitude.toString(); //39.toString();
      body[RequestKeys.longitude] = location.longitude.toString(); //39.toString();
      body[RequestKeys.location] = address; //39.toString();
      body["remark"] = remarkController.text.isEmpty?"":remarkController.text; //39.toString();
      var res = await api.visitCheckOutData(body);
      if (res.status == 200) {
        visitCheckOutList = res.data ?? [];
      } else {
        // ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      isBusy = false;
      update();
    }
  }
}
