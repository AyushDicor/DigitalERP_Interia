
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_controller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/leave_history_view/leave_history_controller.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_model.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_model/executive_list_model.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class LeaveApplyController extends AppBaseController {
  AttendanceController attendanceController = Get.find<AttendanceController>();
  HomeController homeController = Get.find<HomeController>();
  LeaveHistoryController leaveHistoryController = Get.isRegistered<LeaveHistoryController>()
      ? Get.find<LeaveHistoryController>()
      : Get.put(LeaveHistoryController());

  int selectedSegmentVal = 0;
  int selectedButton = 0;

  DateTime? leaveStartDate;
  DateTime? leaveEndDate;
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController responsibleController = TextEditingController();
  final FocusNode reasonFocus = FocusNode();
  final FocusNode responsibleFocus = FocusNode();

  String fromDate = AppString.dateTimeEmpty;
  String toDate = AppString.dateTimeEmpty;


  List<DashboardDetailsData>? dashboardDetailsData = [];
  List<ExecutiveDropdownData>? executiveList = [];
  ExecutiveDropdownData? selectedDropdownValue;

  @override
  void onInit() {
    getExecutiveDropdownList();
    super.onInit();
  }

  void setSelectDropdownValue(ExecutiveDropdownData value) {
    selectedDropdownValue = value;
    update();
  }



  void tapOnLeaveHistory() {
    Get.toNamed(AppRoutes.leaveHistory);
  }
  //
  // void setSegmentValue(int i) {
  //   selectedSegmentVal = i;
  //   fromDate = AppString.dateTimeEmpty;
  //   toDate = AppString.dateTimeEmpty;
  //   reasonController.clear();
  //   reasonFocus.unfocus();
  //   update();
  // }
  void setSegmentValue(int i) {

    if (selectedSegmentVal != i) {
      selectedSegmentVal = i;
      update();
    }
  }


  Future<void> tapOnApply() async {
    if (_validate()) {
      setBusy(true);
      try {
        Map<String, String> body = {};
        body[RequestKeys.compId] = attendanceController.homeController.currentUserData?.compId.toString() ?? '';
        body[RequestKeys.branchId] = attendanceController.homeController.currentUserData?.branchId.toString() ?? '';
        body[RequestKeys.userId] = attendanceController.homeController.currentUserData?.userid.toString() ?? '';
        body[RequestKeys.yearId] = attendanceController.homeController.currentUserData?.yearId.toString() ?? '';
        body[RequestKeys.fromDate] = formatDate(fromDate, AppString.ddMMyyyy, AppString.yyyyMMdd);
        body[RequestKeys.toDate] = selectedSegmentVal == 0
            ? formatDate(fromDate, AppString.ddMMyyyy, AppString.yyyyMMdd)
            : formatDate(toDate, AppString.ddMMyyyy, AppString.yyyyMMdd);
        body[RequestKeys.reason] = reasonController.text;
        body["forward"] = responsibleController.text;

        var res = await api.applyLeave(body);
        if (res.status == 200) {
          setSegmentValue(0);
        //  leaveHistoryController.getDetails();
          ShowMessage.showSnackBar('Apply leave', res.message.toString());
        } else {
          ShowMessage.showSnackBar('Server Res', res.message.toString());
        }
      } catch (e) {
        ShowMessage.showSnackBar('Server Res', '$e');
      }
      finally {
        setBusy(false);
      }
    }
  }

  bool _validate() {
    if (selectedSegmentVal == 0 && fromDate == AppString.dateTimeEmpty) {
      ShowMessage.showSnackBar('Field Empty', AppString.pleaseSelectDate);
      return false;} else if (selectedSegmentVal == 1) {
      if (fromDate == AppString.dateTimeEmpty) {
        ShowMessage.showSnackBar('Field Empty', AppString.selectFromDateTxt);
        return false;
      } else if (toDate == AppString.dateTimeEmpty) {
        ShowMessage.showSnackBar('Field Empty', AppString.selectToDateTxt);
        return false;
      }
    }
    if (reasonController.text.isEmpty) {
      ShowMessage.showSnackBar('Field Empty', 'Please enter leave reason');
      return false;
    } if (responsibleController.text.isEmpty) {
      ShowMessage.showSnackBar('Field Empty', 'Please enter Responsible person name');
      return false;
    }
    return true;
  }

  Future<void> getExecutiveDropdownList({String? selectedForwardName}) async {
    // setBusy(true);
    // try {
    //   Map<String, String> body = {
    //     RequestKeys.userId: homeController.currentUserData?.userid.toString() ?? '',
    //     RequestKeys.compId: homeController.currentUserData?.compId.toString() ?? '',
    //   };
    //
    //   var res = await api.getExecutiveDropdown(body);
    //   if (res.status == 200) {
    //     executiveList = res.data ?? [];
    //
    //     // 💡 Set default selected value if name is passed
    //     if (selectedForwardName != null && selectedForwardName.isNotEmpty) {
    //       final matched = executiveList!.firstWhere(
    //             (e) => e.executiveName == selectedForwardName,
    //         orElse: () => ExecutiveDropdownData(), // fallback
    //       );
    //
    //       if (matched.executiveId != null) {
    //         selectedDropdownValue = matched;
    //       }
    //     }
    //   }
    //   // else {
    //   //   ShowMessage.showSnackBar(
    //   //       'getExecutiveDropdown Server res.status not 200', res.message.toString());
    //   // }
    // } catch (e) {
    //   ShowMessage.showSnackBar('Server Res', '$e');
    // } finally {
    //   setBusy(false);
      executiveList = [];
      update();
    //}
  }



  void setDate(String value, bool isFirstDate) {
    if (isFirstDate) {
      fromDate = value;
    } else {
      toDate = value;
    }
    update();
  }
}
