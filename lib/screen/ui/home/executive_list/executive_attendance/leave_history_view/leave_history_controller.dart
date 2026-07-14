
import 'package:get/get.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_controller.dart';
import 'package:newdigitalerp/response/approved_or_rejected_leave_response.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_model/executive_list_model.dart';
import 'package:newdigitalerp/response/pending_leave_list_response.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/custom_dialogbox.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class LeaveHistoryController extends AppBaseController {
  AttendanceController attendanceController = Get.find<AttendanceController>();
  List<LeaveData> leaveHistoryList = [];
  List<PendingLeaveData> pendingLeaveList = [];
  bool isManager = false;
  MonthData? selectedMonth;

  List<ExecutiveDropdownData> executiveList = [];
  ExecutiveDropdownData? selectedDropdownValue;

  void setSelectDropdownValue(ExecutiveDropdownData v) {
    selectedDropdownValue = v;
    update();
  }

  @override
  void onInit() {
    getDropdownList();
    getDetails();
    getPendingLeaveList();
    super.onInit();
  }

  Future<void> getDetails({String? fromDate, String? toDate}) async {
    leaveHistoryList.clear();
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = attendanceController.homeController.currentUserData?.userid.toString() ?? '342613';
      body[RequestKeys.compId] = attendanceController.homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.filter] = 'yes';
      body[RequestKeys.fromDate] = fromDate ?? getStartDateOfMonth(DateTime.now());
      body[RequestKeys.toDate] =
          toDate ?? formatDate(DateTime.now().toString(), AppString.dateTimeFormat, AppString.yyyyMMdd);
      var res = await api.getLeaveHistoryDetail(body);
      if (res.status == 200) {
        leaveHistoryList.addAll((res.data ?? []).cast<LeaveData>());

        /// For sorting date wise List
        leaveHistoryList.sort((a, b) {
          if (DateTime.parse(formatDate(a.date!.split(' ').first.toString(), AppString.ddMMyyyy, AppString.yyyyMMdd))
              .isAfter(DateTime.parse(
                  formatDate(b.date!.split(' ').first.toString(), AppString.ddMMyyyy, AppString.yyyyMMdd)))) {
            return 1;
          }
          return 0;
        });
        update();
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> getDropdownList() async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = attendanceController.homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.compId] = attendanceController.homeController.currentUserData?.compId.toString() ?? '';
      var res = await api.getExecutiveDropdown(body);
      if (res.status == 200) {
        executiveList.addAll((res.data ?? []).cast<ExecutiveDropdownData>());
        if (executiveList.length == 1) {
          setSelectDropdownValue(executiveList[0]);
        }
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> getPendingLeaveList({String? executiveId, String? fromDate, String? toDate}) async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = attendanceController.homeController.currentUserData?.userid.toString() ?? '342613';
      body[RequestKeys.compId] = attendanceController.homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.executiveId] = executiveId ?? '0';
      body[RequestKeys.fromDate] = fromDate ?? getStartDateOfMonth(DateTime.now());
      body[RequestKeys.toDate] =
          toDate ?? formatDate(DateTime.now().toString(), AppString.dateTimeFormat, AppString.yyyyMMdd);
      var res = await api.getPendingLeaveList(body);
      if (res.status == 200) {
        pendingLeaveList.addAll((res.data ?? []).cast<PendingLeaveData>());

        /// For sorting date wise List
        pendingLeaveList.sort((a, b) {
          if (DateTime.parse(formatDate(a.date!.split(' ').first.toString(), AppString.ddMMyyyy, AppString.yyyyMMdd))
              .isAfter(DateTime.parse(
                  formatDate(b.date!.split(' ').first.toString(), AppString.ddMMyyyy, AppString.yyyyMMdd)))) {
            return 1;
          }
          return 0;
        });
        update();
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> leaveStatusUpdate({required String id, required bool isApproved}) async {
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = attendanceController.homeController.currentUserData?.userid.toString() ?? '342613';
      body[RequestKeys.compId] = attendanceController.homeController.currentUserData?.compId.toString() ?? '39';
      body[RequestKeys.id] = id;
      body[RequestKeys.status] = isApproved ? 'approved' : 'reject';
      var res = await api.updateLeaveStatus(body);
      if (res.status == 200) {
        ShowMessage.showSnackBar('Success Server Res', res.message.toString());
        update();
      } else {
        ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {}
  }
}
