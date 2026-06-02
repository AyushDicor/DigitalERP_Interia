import 'dart:convert';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:newdigitalerp/Menu_new_list_responce.dart';
import 'package:newdigitalerp/auth/login/login_model.dart';
import 'package:newdigitalerp/auth/otp/otp_model.dart';
import 'package:newdigitalerp/response/executive_list_with_lat_long_response.dart';
import 'package:newdigitalerp/response/exicutive_whole_day_location_response.dart';
import 'package:newdigitalerp/response/forgot_otp_verfiy_response.dart';
import 'package:newdigitalerp/response/forgot_pass_response.dart';
import 'package:newdigitalerp/response/menu_details_response.dart';
import 'package:newdigitalerp/response/token_update_response.dart';
import 'package:newdigitalerp/response/unApproval_Count_Responce.dart';
import 'package:newdigitalerp/response/update_approvalstatus_responce.dart';
import 'package:newdigitalerp/response/update_profile_response.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approval_details_responce.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approval_document_responce.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approvals_list_responce.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/status_list_responce.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_model/approved_or_reject_leave_model.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_model/attendance_list_model.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_model/attendance_model.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_model.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_model/executive_list_model.dart';
import 'package:newdigitalerp/screen/ui/home/executive_list/executive_list_model/pending_leave_list_model.dart';
import 'package:newdigitalerp/services/api_service/api_client.dart';
import 'package:newdigitalerp/services/api_service/api_methods.dart';

class Api {
  final ApiMethods _apiMethods = ApiMethods();
  final ApiClient _apiClient = ApiClient();

  static final Api _api = Api._internal();
  final Connectivity connectivity = Connectivity();

  factory Api() {
    return _api;
  }

  Api._internal();

  Map<String, String> getHeader() {
    return {'Content-Type': 'application/json'};
  }

  Future<LoginResponse> loginApi(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.login,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          log('LOGIN RES :=> $res');
          return loginResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return LoginResponse(status: 500, message: e.toString());
        }
      } else {
        return LoginResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return LoginResponse(status: 500, message: 'No Internet');
    }
  }

  Future<ExecutiveDropdownResponse> getExecutiveDropdown(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.executiveDropDown,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return executiveDropdownResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ExecutiveDropdownResponse(status: 500, message: e.toString());
        }
      } else {
        return ExecutiveDropdownResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return ExecutiveDropdownResponse(status: 500, message: 'No Internet');
    }
  }

  Future<UpdateProfileResponse> updateProfileJson(var body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethodJson(
          method: _apiMethods.updateProfile,
          body: body,
          header: {'Content-Type': 'application/json'},
        );
        if (res.isNotEmpty) {
          return updateProfileResponseFromJson(res);
        } else {
          return UpdateProfileResponse(
            status: 500,
            message: 'Something went wrong',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return UpdateProfileResponse(status: 500, message: e.toString());
      }
    } else {
      return UpdateProfileResponse(status: 500, message: 'No Internet');
    }
  }

  Future<OtpVerifyResponse> otpVerify(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.mobileOtpVerify,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return otpVerifyResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OtpVerifyResponse(status: 500, message: e.toString());
        }
      } else {
        return OtpVerifyResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return OtpVerifyResponse(status: 500, message: 'No internet');
    }
  }

  Future<TokenUpdateResponse> tokenUpdate(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.updateToken,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return tokenUpdateResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return TokenUpdateResponse(status: 500, message: e.toString());
        }
      } else {
        return TokenUpdateResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return TokenUpdateResponse(status: 500, message: 'No internet');
    }
  }

  Future<MenuDetailsResponse> getMenuList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.menuDetails,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          log('===MENU LIST===$res');

          return menuDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return MenuDetailsResponse(status: 500, message: e.toString());
        }
      } else {
        return MenuDetailsResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return MenuDetailsResponse(status: 500, message: 'No internet');
    }
  }

  Future<MenuNewListResponse> getNewMenuList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.menuUserNew,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          log('===MENU New LIST===$res');
          return menuNewListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
            print('Find Error');
          }
          return MenuNewListResponse(status: 500, message: e.toString());
        }
      } else {
        return MenuNewListResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return MenuNewListResponse(status: 500, message: 'No internet');
    }
  }

  Future<DashboardDetailsResponse> getDashboardDetails(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.dashboardDetails,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return dashboardDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DashboardDetailsResponse(status: 500, message: e.toString());
        }
      } else {
        return DashboardDetailsResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return DashboardDetailsResponse(status: 500, message: 'No internet');
    }
  }

  Future<AttendanceSummaryResponse> getAttendanceSummary(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.attendanceSummary,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return attendanceSummaryResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AttendanceSummaryResponse(status: 500, message: e.toString());
        }
      } else {
        return AttendanceSummaryResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return AttendanceSummaryResponse(status: 500, message: 'No internet');
    }
  }

  Future<AttendanceListResponse> getAttendanceList(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.attendanceList,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return attendanceListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AttendanceListResponse(status: 500, message: e.toString());
        }
      } else {
        return AttendanceListResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return AttendanceListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> markAttendance(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.markAttendance,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return commonResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CommonResponse(status: 500, message: e.toString());
        }
      } else {
        return CommonResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CommonResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> logout(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.logout,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return commonResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CommonResponse(status: 500, message: e.toString());
        }
      } else {
        return CommonResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CommonResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> applyLeave(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.applyLeave,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return commonResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CommonResponse(status: 500, message: e.toString());
        }
      } else {
        return CommonResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CommonResponse(status: 500, message: 'No internet');
    }
  }

  Future<ApprovedOrRejectLeaveResponse> getLeaveDetail(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.getLeaveData,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return approvedOrRejectLeaveResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovedOrRejectLeaveResponse(
            status: 500,
            message: e.toString(),
          );
        }
      } else {
        return ApprovedOrRejectLeaveResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return ApprovedOrRejectLeaveResponse(status: 500, message: 'No internet');
    }
  }

  Future<ApprovedOrRejectLeaveResponse> getLeaveHistoryDetail(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.leaveHistory,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return approvedOrRejectLeaveResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovedOrRejectLeaveResponse(
            status: 500,
            message: e.toString(),
          );
        }
      } else {
        return ApprovedOrRejectLeaveResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return ApprovedOrRejectLeaveResponse(status: 500, message: 'No internet');
    }
  }

  Future<PendingLeaveListResponse> getPendingLeaveList(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.pendingLeaveList,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return pendingLeaveListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PendingLeaveListResponse(status: 500, message: e.toString());
        }
      } else {
        return PendingLeaveListResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return PendingLeaveListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> updateLeaveStatus(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.updateLeaveStatus,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return commonResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CommonResponse(status: 500, message: e.toString());
        }
      } else {
        return CommonResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CommonResponse(status: 500, message: 'No internet');
    }
  }

  Future<ExecutiveListResponse> getExecutiveListWithLatLong(
    Map<String, String> body,
  ) async {
    List<ConnectivityResult> connectivityResults = await connectivity
        .checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.executiveListWithLatAndLong,
        body: body,
      );
      if (res.isNotEmpty) {
        try {
          return executiveListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ExecutiveListResponse(status: 500, message: e.toString());
        }
      } else {
        return ExecutiveListResponse(
          status: 500,
          message: 'Something went wrong',
        );
      }
    } else {
      return ExecutiveListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> saveLocationRoute(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.locationRouteSave, body: body);
      if (res.isNotEmpty) {
        try {
          return commonResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CommonResponse(status: 500, message: e.toString());
        }
      } else {
        return CommonResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CommonResponse(status: 500, message: 'No internet');
    }
  }

  Future<ExecutiveDayLocationDataResponse> getExecutiveDayLocationData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.executiveDayLocation, body: body);
      if (res.isNotEmpty) {
        try {
          return executiveDayLocationDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ExecutiveDayLocationDataResponse(
              status: 500, message: e.toString());
        }
      } else {
        return ExecutiveDayLocationDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ExecutiveDayLocationDataResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<ForgotPasswordResponse> forgotPasswordAPI(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.forgotPassword, body: body);
      if (res.isNotEmpty) {
        try {
          return forgotPasswordResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ForgotPasswordResponse(status: 500, message: e.toString());
        }
      } else {
        return ForgotPasswordResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ForgotPasswordResponse(status: 500, message: 'No internet');
    }
  }

  Future<ForgotOtpVerifyResponse> forgotOtpVerifyAPI(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.forgotOtpVerify, body: body);
      if (res.isNotEmpty) {
        try {
          return forgotOtpVerifyResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ForgotOtpVerifyResponse(status: 500, message: e.toString());
        }
      } else {
        return ForgotOtpVerifyResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ForgotOtpVerifyResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> resetPassword(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.resetPassword, body: body);
      if (res.isNotEmpty) {
        try {
          return commonResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CommonResponse(status: 500, message: e.toString());
        }
      } else {
        return CommonResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CommonResponse(status: 500, message: 'No internet');
    }
  }
  Future<UnApprovalCountResponse> getUnApprovalCount(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log('getUnApprovalCount REQ MODEL=>${jsonEncode(body)}');
      String res = await _apiClient.postMethod(
          method: _apiMethods.unApprovalCount, body: body);
      if (res.isNotEmpty) {
        try {
          log('getUnApprovalCount==>$res');
          return unApprovalCountResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return UnApprovalCountResponse(status: 500, message: e.toString());
        }
      } else {
        return UnApprovalCountResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return UnApprovalCountResponse(status: 500, message: 'No internet');
    }
  }


   ///Approval APIs
  Future<ApprovalsListResponse> getApprovalListData(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.approvalList, body: body);
      if (res.isNotEmpty) {
        try {
          return approvalListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovalsListResponse(status: 500, message: e.toString());
        }
      } else {
        return ApprovalsListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ApprovalsListResponse(status: 500, message: 'No internet');
    }
  }

  Future<ApprovalDetailsResponse> getApprovalDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.approvaldetails, body: body);
      if (res.isNotEmpty) {
        try {
          return approvalDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovalDetailsResponse(status: 500, message: e.toString());
        }
      } else {
        return ApprovalDetailsResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ApprovalDetailsResponse(status: 500, message: 'No internet');
    }
  }

  Future<ApprovalDocumentResponse> getApprovalDocument(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.approvalDocument, body: body);
      if (res.isNotEmpty) {
        try {
          return approvalDocumentResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovalDocumentResponse(status: 500, message: e.toString());
        }
      } else {
        return ApprovalDocumentResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ApprovalDocumentResponse(status: 500, message: 'No internet');
    }
  }

  Future<UpdateApprovalstatusResponse> updateApprovalStatusApi(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.approvalupdatestatus,
        body: jsonEncode(body), // ← encode here
        header: {'Content-Type': 'application/json'}, // ← pass header
      );
      if (res.isNotEmpty) {
        try {
          return updateApprovalstatusResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return UpdateApprovalstatusResponse(
              status: 500, message: e.toString());
        }
      } else {
        return UpdateApprovalstatusResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return UpdateApprovalstatusResponse(status: 500, message: 'No internet');
    }
  }

  Future<StatusListResponse> getStatusData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.statusList, body: body);
      if (res.isNotEmpty) {
        try {
          return statusListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StatusListResponse(status: 500, message: e.toString());
        }
      } else {
        return StatusListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return StatusListResponse(status: 500, message: 'No internet');
    }
  }
}
