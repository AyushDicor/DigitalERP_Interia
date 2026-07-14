import 'dart:convert';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:newdigitalerp/Menu_new_list_responce.dart';
import 'package:newdigitalerp/catalouge/catalogue_list_response.dart';
import 'package:newdigitalerp/lead%20management/lead_list_response.dart';
import 'package:newdigitalerp/lead%20management/lead_form_models.dart';
import 'package:newdigitalerp/performa_invoice/sale_order_models.dart';
import 'package:newdigitalerp/performa_invoice/sale_order_form_models.dart';
import 'package:newdigitalerp/purchase_order/purchase_order_models.dart';
import 'package:newdigitalerp/purchase_order/purchase_order_form_models.dart';
import 'package:newdigitalerp/purchase_order/pending_indent_po/pending_indent_po_models.dart';
import 'package:newdigitalerp/change_company/Company_list_responce.dart';
import 'package:newdigitalerp/change_company/branch_list_response.dart';
import 'package:newdigitalerp/change_company/financial_year_response.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/pendency_response.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/order_report_response.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/report_models.dart';
import 'package:newdigitalerp/screen/ui/home/task_module/task_models.dart';
import 'package:newdigitalerp/contactsview/Designation_dropdown_responce.dart';
import 'package:newdigitalerp/contactsview/add_contacts_details_responce.dart';
import 'package:newdigitalerp/contactsview/contacts_view_responce.dart';
// import 'package:newdigitalerp/download_document_management/download_document_type_.dart';
// import 'package:newdigitalerp/download_document_management/download_document-list_responce.dart';
// import 'package:newdigitalerp/download_document_management/download_document_print_response.dart';
// import 'package:newdigitalerp/orderfollowup/order_followup_details_response.dart';
// import 'package:newdigitalerp/orderfollowup/order_followup_save_response.dart';
// import 'package:newdigitalerp/orderfollowup/orderfollowup_list_response.dart';
// import 'package:newdigitalerp/paymenfollow%20up/payment_followup_response/payment_followup_details_response.dart';
// import 'package:newdigitalerp/paymenfollow%20up/payment_followup_response/payment_followup_list_response.dart';
// import 'package:newdigitalerp/paymenfollow%20up/payment_followup_response/payment_followup_save_response.dart';
// import 'package:newdigitalerp/performace_management/perfomace_list_response.dart';
import 'package:newdigitalerp/response/add_customer_to_visit_response.dart';
import 'package:newdigitalerp/response/add_to_cart_response.dart';
import 'package:newdigitalerp/response/all_visit_data_response.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approvals_list_responce.dart';
import 'package:newdigitalerp/response/approved_or_rejected_leave_response.dart';
import 'package:newdigitalerp/response/area_data_response.dart';
import 'package:newdigitalerp/response/attendance_list_response.dart';
import 'package:newdigitalerp/response/attendance_summary_response.dart';
import 'package:newdigitalerp/response/brand_list_data_response.dart';
import 'package:newdigitalerp/response/brand_list_response.dart';
import 'package:newdigitalerp/response/cart_count_response.dart';
import 'package:newdigitalerp/response/cash_bank_ledger_response.dart';
import 'package:newdigitalerp/response/city_data_response.dart';
import 'package:newdigitalerp/response/collection_customer_list_response.dart';
import 'package:newdigitalerp/response/collection_list_response.dart';
import 'package:newdigitalerp/response/customer_data_response.dart';
import 'package:newdigitalerp/response/customer_detail_response.dart';
import 'package:newdigitalerp/response/customer_location_update_response.dart';
import 'package:newdigitalerp/response/customer_remarks_update_response.dart';
import 'package:newdigitalerp/response/dashboard_details_response.dart';
import 'package:newdigitalerp/response/dashboard_graphs_response.dart';
import 'package:newdigitalerp/response/delete_visit_data_response.dart';
import 'package:newdigitalerp/response/distance_details_response.dart';
import 'package:newdigitalerp/response/download_salary_sleep_res.dart';
import 'package:newdigitalerp/response/dsr_pdf_response.dart';
import 'package:newdigitalerp/response/executive_list_response.dart';
import 'package:newdigitalerp/response/executive_list_with_lat_long_response.dart';
import 'package:newdigitalerp/response/executive_order_list_response.dart';
import 'package:newdigitalerp/response/exicutive_whole_day_location_response.dart';
import 'package:newdigitalerp/response/forgot_otp_verfiy_response.dart';
import 'package:newdigitalerp/response/forgot_pass_response.dart';
import 'package:newdigitalerp/response/get_account_register_ledger_resp.dart';
import 'package:newdigitalerp/response/get_approver_name_res_model.dart';
import 'package:newdigitalerp/response/get_attendance_report_resp.dart';
import 'package:newdigitalerp/response/get_branchand_sit_res_model.dart';
import 'package:newdigitalerp/response/get_cart_list_response.dart';
import 'package:newdigitalerp/response/get_executive_dropdown_response.dart';
import 'package:newdigitalerp/response/get_invoice_detail_res_model.dart';
import 'package:newdigitalerp/response/get_month_wise_sales_res_model.dart';
import 'package:newdigitalerp/response/get_order_report_resp.dart';
import 'package:newdigitalerp/response/get_parentgroup_resp.dart';
import 'package:newdigitalerp/response/get_party_for_parent_resp.dart';
import 'package:newdigitalerp/response/get_pending_shipping_resp.dart';
import 'package:newdigitalerp/response/get_sales_receipt_graph_res_model.dart';
import 'package:newdigitalerp/response/get_shipping_status_resp.dart';
import 'package:newdigitalerp/response/get_stock_report_resp.dart';
import 'package:newdigitalerp/response/get_store_name_resp.dart';
import 'package:newdigitalerp/response/stock_enquiry_item_resp.dart';
import 'package:newdigitalerp/response/stock_enquiry_godown_resp.dart';
import 'package:newdigitalerp/response/image_list_resp.dart';
import 'package:newdigitalerp/response/incentive_graph_detail_res_model.dart';
import 'package:newdigitalerp/response/login_response.dart';
import 'package:newdigitalerp/response/logout_response.dart';
import 'package:newdigitalerp/response/menu_details_response.dart';
import 'package:newdigitalerp/response/nearby_data_response.dart';
import 'package:newdigitalerp/response/order_detail_pdf_url_response.dart';
import 'package:newdigitalerp/response/order_detail_response.dart';
import 'package:newdigitalerp/response/otp_verify_response.dart';
import 'package:newdigitalerp/response/outstanding_data_response.dart';
import 'package:newdigitalerp/response/party_balance_detail_response.dart';
import 'package:newdigitalerp/response/party_dropdown_list_response.dart';
import 'package:newdigitalerp/response/party_latlng_check_response.dart';
import 'package:newdigitalerp/response/party_ledger_response.dart';
import 'package:newdigitalerp/response/payment_entry_submit_response.dart';
import 'package:newdigitalerp/response/pending_leave_list_response.dart';
import 'package:newdigitalerp/response/preview_visit_data_response.dart';
import 'package:newdigitalerp/response/product_detail_response.dart';
import 'package:newdigitalerp/response/rack_list_response.dart';
import 'package:newdigitalerp/response/related_product_response.dart';
import 'package:newdigitalerp/response/sales_invoice_list_response.dart';
import 'package:newdigitalerp/response/show_all_party_outstanding_resp.dart';
import 'package:newdigitalerp/response/show_performance_graph_res_model.dart';
import 'package:newdigitalerp/response/state_data_response.dart';
import 'package:newdigitalerp/response/stcok_category_data_response.dart';
import 'package:newdigitalerp/response/stock_reconcilation_report_response.dart';
import 'package:newdigitalerp/response/stock_reconciliation_submit_response.dart';
import 'package:newdigitalerp/response/stock_submit_data_response.dart';
import 'package:newdigitalerp/response/submit_visit_data_response.dart';
import 'package:newdigitalerp/response/token_update_response.dart';
import 'package:newdigitalerp/response/transaction_list_response.dart';
import 'package:newdigitalerp/response/unApproval_Count_Responce.dart';
import 'package:newdigitalerp/response/unit_list_response.dart';
import 'package:newdigitalerp/response/update_cart_quantity_response.dart';
import 'package:newdigitalerp/response/update_profile_response.dart';
import 'package:newdigitalerp/response/validate_user_order_response.dart';
import 'package:newdigitalerp/response/visit_check_in_response.dart';
import 'package:newdigitalerp/response/visit_check_out_response.dart';
import 'package:newdigitalerp/response/visit_plan_detail_data_response.dart';
import 'package:newdigitalerp/response/voucher_list_response.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approval_details_responce.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/approval_document_responce.dart';
import 'package:newdigitalerp/screen/ui/home/approval_management/approval_model/status_list_responce.dart';
import 'package:newdigitalerp/screen/ui/home/grn/grn_response/grn_models.dart';
import 'package:newdigitalerp/screen/ui/home/indent/indent_response/indent_model.dart';
import 'package:newdigitalerp/screen/ui/home/issue%20item/issue_item_response/issue_item_model.dart';
import 'package:newdigitalerp/screen/ui/home/mrn_module/mrn_response/mrn_models.dart';
import 'package:newdigitalerp/screen/ui/home/mrn_qc/mrn_qc_model/mrn_qc_models.dart';
import 'package:newdigitalerp/services/api_service/api_client.dart';
import 'package:newdigitalerp/services/api_service/api_methods.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';

import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as dio;


import '../../download_document_management/download_document-list_responce.dart';
import '../../download_document_management/download_document_print_response.dart';
import '../../download_document_management/download_document_type_.dart';
import '../../orderfollowup/order_followup_details_response.dart';
import '../../orderfollowup/order_followup_save_response.dart';
import '../../orderfollowup/orderfollowup_list_response.dart';
import '../../paymenfollow up/payment_followup_response/payment_followup_details_response.dart';
import '../../paymenfollow up/payment_followup_response/payment_followup_list_response.dart';
import '../../paymenfollow up/payment_followup_response/payment_followup_save_response.dart';
import '../../performace_management/perfomace_list_response.dart';
import '../../response/select_category_list_response.dart';
import '../../response/subcategory_brand_response.dart';
import '../../response/task_dropdown_response.dart';
import '../../response/create_task_response.dart';
import '../../response/save_followup_response.dart';
import '../../response/update_approvalstatus_responce.dart';
import '../../screen/ui/home/approval/approval_filtter/approval_filtter_responce/client_list_responce.dart';
import '../../screen/ui/home/approval/approval_filtter/approval_filtter_responce/documentname_responce.dart';
import '../../screen/ui/home/approval/approval_filtter/approval_filtter_responce/item_list_responce.dart';
import '../../screen/ui/home/approval/approval_filtter/approval_filtter_responce/vendor_list_responce.dart';
import '../../screen/ui/home/task management/task models/Assign_task_responce.dart';
import '../../screen/ui/home/task management/task models/Task_details_responce.dart';
import '../../screen/ui/home/task management/task models/Task_list_responce.dart';
import '../../screen/ui/home/task management/task models/Task_update_responce.dart';
import '../../shipMangement/shipping_details_list_response.dart';
import '../../shipMangement/shipping_status_response.dart';
import '../../shipMangement/shipping_update_details_response.dart';
import '../../shipMangement/update_shipping_value_response.dart';

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
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res =
      await _apiClient.postMethod(method: _apiMethods.login, body: body);
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
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.executiveDropDown, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ExecutiveDropdownResponse(status: 500, message: 'No Internet');
    }
  }

  Future<UpdateProfileResponse> updateProfileJson(var body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethodJson(
            method: _apiMethods.updateProfile,
            body: body,
            header: {'Content-Type': 'application/json'});
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
        return UpdateProfileResponse(
          status: 500,
          message: e.toString(),
        );
      }
    } else {
      return UpdateProfileResponse(
        status: 500,
        message: 'No Internet',
      );
    }
  }

  Future<OtpVerifyResponse> otpVerify(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.mobileOtpVerify, body: body);
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
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateToken, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return TokenUpdateResponse(status: 500, message: 'No internet');
    }
  }

  Future<MenuDetailsResponse> getMenuList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.menuDetails, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return MenuDetailsResponse(status: 500, message: 'No internet');
    }
  }

  Future<MenuNewListResponse> getNewMenuList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return MenuNewListResponse(status: 500, message: 'No internet');
    }
  }

  Future<DashboardDetailsResponse> getDashboardDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.dashboardDetails, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DashboardDetailsResponse(status: 500, message: 'No internet');
    }
  }

  Future<AttendanceSummaryResponse> getAttendanceSummary(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.attendanceSummary, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return AttendanceSummaryResponse(status: 500, message: 'No internet');
    }
  }

  Future<AttendanceListResponse> getAttendanceList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.attendanceList, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return AttendanceListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> markAttendance(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.markAttendance, body: body);
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
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res =
      await _apiClient.postMethod(method: _apiMethods.logout, body: body);
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
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.applyLeave, body: body);
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
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getLeaveData, body: body);
      if (res.isNotEmpty) {
        try {
          return approvedOrRejectLeaveResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovedOrRejectLeaveResponse(
              status: 500, message: e.toString());
        }
      } else {
        return ApprovedOrRejectLeaveResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ApprovedOrRejectLeaveResponse(status: 500, message: 'No internet');
    }
  }

  Future<ApprovedOrRejectLeaveResponse> getLeaveHistoryDetail(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leaveHistory, body: body);
      if (res.isNotEmpty) {
        try {
          return approvedOrRejectLeaveResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ApprovedOrRejectLeaveResponse(
              status: 500, message: e.toString());
        }
      } else {
        return ApprovedOrRejectLeaveResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ApprovedOrRejectLeaveResponse(status: 500, message: 'No internet');
    }
  }

  Future<PendingLeaveListResponse> getPendingLeaveList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.pendingLeaveList, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return PendingLeaveListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> updateLeaveStatus(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateLeaveStatus, body: body);
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
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.executiveListWithLatAndLong, body: body);
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
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ExecutiveListResponse(status: 500, message: 'No internet');
    }
  }

  Future<ExecutiveOrderListResponse> getExecutiveOrderList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.executiveOrderList, body: body);
      if (res.isNotEmpty) {
        try {
          return executiveOrderListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ExecutiveOrderListResponse(status: 500, message: e.toString());
        }
      } else {
        return ExecutiveOrderListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ExecutiveOrderListResponse(status: 500, message: 'No internet');
    }
  }

  Future<GetSalesReceiptGraphResModel> getSalesReceiptGraph(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getsalesreceiptgraphController, body: body);
      if (res.isNotEmpty) {
        try {
          return GetSalesReceiptGraphResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetSalesReceiptGraphResModel(
              status: 500, message: e.toString());
        }
      } else {
        return GetSalesReceiptGraphResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetSalesReceiptGraphResModel(status: 500, message: 'No internet');
    }
  }

  Future<GetMonthWiseSalesResModel> getMonthWiseSales(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getmonthwisesales, body: body);
      if (res.isNotEmpty) {
        try {
          return GetMonthWiseSalesResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetMonthWiseSalesResModel(status: 500, message: e.toString());
        }
      } else {
        return GetMonthWiseSalesResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetMonthWiseSalesResModel(status: 500, message: 'No internet');
    }
  }

  Future<GetInvoiceDetailResModel> getInvoiceDetail(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getinvoicedetail, body: body);
      if (res.isNotEmpty) {
        try {
          return GetInvoiceDetailResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetInvoiceDetailResModel(status: 500, message: e.toString());
        }
      } else {
        return GetInvoiceDetailResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetInvoiceDetailResModel(status: 500, message: 'No internet');
    }
  }

  Future<ShowPerformanceGraphResModel> showPerformanceGraph(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.showperformancegraph, body: body);
      if (res.isNotEmpty) {
        try {
          return ShowPerformanceGraphResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ShowPerformanceGraphResModel(
              status: 500, message: e.toString());
        }
      } else {
        return ShowPerformanceGraphResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ShowPerformanceGraphResModel(status: 500, message: 'No internet');
    }
  }

  Future<IncentiveGraphDetailResModel> incentiveGraphDetail(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.incentivegrapdetail, body: body);
      if (res.isNotEmpty) {
        try {
          return IncentiveGraphDetailResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return IncentiveGraphDetailResModel(
              status: 500, message: e.toString());
        }
      } else {
        return IncentiveGraphDetailResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return IncentiveGraphDetailResModel(status: 500, message: 'No internet');
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

  Future<PartyDropdownListResponse> getPartyDropdownList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.partyDropdownNew, body: body);
      if (res.isNotEmpty) {
        try {
          return partyDropdownListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PartyDropdownListResponse(status: 500, message: e.toString());
        }
      } else {
        return PartyDropdownListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return PartyDropdownListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<AddContactsViewResponse> getAddContactsView(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.addContactsView, body: body);
      if (res.isNotEmpty) {
        try {
          return addContactsViewResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AddContactsViewResponse(status: 500, message: e.toString());
        }
      } else {
        return AddContactsViewResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return AddContactsViewResponse(status: 500, message: 'No Internet');
    }
  }

  Future<AddContactsDetailsResponse> getAddContactsDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.addContactsDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return addContactsDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AddContactsDetailsResponse(status: 500, message: e.toString());
        }
      } else {
        return AddContactsDetailsResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return AddContactsDetailsResponse(status: 500, message: 'No Internet');
    }
  }

  Future<DesignationDropdownResponse> getSDesignationDropdown(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.designationDropDown, body: body);
      if (res.isNotEmpty) {
        try {
          return designationDropdownResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DesignationDropdownResponse(
              status: 500, message: e.toString());
        }
      } else {
        return DesignationDropdownResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DesignationDropdownResponse(status: 500, message: 'No Internet');
    }
  }

  // Future<AssignTaskResponse> getAssignTaskView(Map<String, String> body) async {
  //   List<ConnectivityResult> connectivityResults =
  //       await connectivity.checkConnectivity();
  //
  //   if (connectivityResults.contains(ConnectivityResult.wifi) ||
  //       connectivityResults.contains(ConnectivityResult.mobile)) {
  //     String res = await _apiClient.postMethod(
  //         method: _apiMethods.assignTask, body: body);
  //     if (res.isNotEmpty) {
  //       try {
  //         return assignTaskResponseFromJson(res);
  //       } catch (e) {
  //         if (kDebugMode) {
  //           print(e);
  //         }
  //         return AssignTaskResponse(status: 500, message: e.toString());
  //       }
  //     } else {
  //       return AssignTaskResponse(status: 500, message: 'Something went wrong');
  //     }
  //   } else {
  //     return AssignTaskResponse(status: 500, message: 'No Internet');
  //   }
  // }

  Future<TaskListResponse> getTaskListView(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res =
      await _apiClient.postMethod(method: _apiMethods.taskList, body: body);
      if (res.isNotEmpty) {
        try {
          return taskListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return TaskListResponse(status: 500, message: e.toString());
        }
      } else {
        return TaskListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return TaskListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<TaskUpdateResponse> getTaskUpdateDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.taskUpdateDetails,
          body: jsonEncode(body),
          header: {"Content-Type": 'application/json'});
      if (res.isNotEmpty) {
        try {
          return taskUpdateResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return TaskUpdateResponse(status: 500, message: e.toString());
        }
      } else {
        return TaskUpdateResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return TaskUpdateResponse(status: 500, message: 'No Internet');
    }
  }

  Future<TaskDetailsResponse> getTaskDetails(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.taskDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return taskDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return TaskDetailsResponse(status: 500, message: e.toString());
        }
      } else {
        return TaskDetailsResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return TaskDetailsResponse(status: 500, message: 'No Internet');
    }
  }

  Future<SaveFollowupResponse> saveTaskFollowup(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.saveTaskFollowup,
          body: jsonEncode(body),
          header: {'Content-Type': 'application/json'});
      if (res.isNotEmpty) {
        try {
          return saveFollowupResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return SaveFollowupResponse(status: 500, message: e.toString());
        }
      } else {
        return SaveFollowupResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return SaveFollowupResponse(status: 500, message: 'No Internet');
    }
  }

  Future<CompanyListResponse> getCompanyList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.companylist, body: body);
      if (res.isNotEmpty) {
        try {
          return companyListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CompanyListResponse(status: 500, message: e.toString());
        }
      } else {
        return CompanyListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CompanyListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<CreateDirectTaskResponse> createDirectTask(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.createDirectTask,
          body: jsonEncode(body),
          header: {'Content-Type': 'application/json'});
      if (res.isNotEmpty) {
        try {
          return createDirectTaskResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return CreateDirectTaskResponse(status: 500, message: e.toString());
        }
      } else {
        return CreateDirectTaskResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CreateDirectTaskResponse(status: 500, message: 'No Internet');
    }
  }

  Future<TaskDropdownResponse> getTaskDropdown(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.taskDropdown,
          body: jsonEncode(body),
          header: {'Content-Type': 'application/json'});
      if (res.isNotEmpty) {
        try {
          return taskDropdownResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskDropdownResponse(status: 500, message: e.toString());
        }
      } else {
        return TaskDropdownResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return TaskDropdownResponse(status: 500, message: 'No Internet');
    }
  }

  Future<BranchListResponse> getBranchList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.branchlist, body: body);
      if (res.isNotEmpty) {
        try {
          return branchListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return BranchListResponse(status: 500, message: e.toString());
        }
      } else {
        return BranchListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return BranchListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<ReportResponse> getReportGeneric(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.genericReport, body: body);
      if (res.isNotEmpty) {
        try {
          return reportResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return ReportResponse(status: 500, message: e.toString());
        }
      }
      return ReportResponse(status: 500, message: 'Something went wrong');
    }
    return ReportResponse(status: 500, message: 'No Internet');
  }

  Future<ReportDetailResponse> getReportDetailGeneric(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.genericReportDetail, body: body);
      if (res.isNotEmpty) {
        try {
          return reportDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return ReportDetailResponse(status: 500, message: e.toString());
        }
      }
      return ReportDetailResponse(status: 500, message: 'Something went wrong');
    }
    return ReportDetailResponse(status: 500, message: 'No Internet');
  }

  Future<OrderReportResponse> getSalesOrderReport(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.orderReport, body: body);
      if (res.isNotEmpty) {
        try {
          return orderReportResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OrderReportResponse(status: 500, message: e.toString());
        }
      } else {
        return OrderReportResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return OrderReportResponse(status: 500, message: 'No Internet');
    }
  }

  Future<PendencyResponse> getDashboardPendency(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.dashboardPendency, body: body);
      if (res.isNotEmpty) {
        try {
          return pendencyResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PendencyResponse(status: 500, message: e.toString());
        }
      } else {
        return PendencyResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return PendencyResponse(status: 500, message: 'No Internet');
    }
  }

  /// Chart data for the home dashboard (order trend / doc mix / by-party / recent).
  Future<DashboardGraphsResponse> getDashboardGraphs(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.dashboardGraphs, body: body);
      if (res.isNotEmpty) {
        try {
          return dashboardGraphsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return DashboardGraphsResponse(status: 500, message: e.toString());
        }
      }
      return DashboardGraphsResponse(status: 500, message: 'Something went wrong');
    }
    return DashboardGraphsResponse(status: 500, message: 'No internet');
  }

  // ─────────────────────────── Task module ───────────────────────────
  Future<TaskListResp> getTaskList(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) || c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.taskListV2, body: body);
      if (res.isNotEmpty) {
        try {
          return taskListRespFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskListResp(
              success: false, status: 500, message: e.toString(),
              rows: [], summary: TaskSummary());
        }
      }
      return TaskListResp(
          success: false, status: 500, message: 'Something went wrong',
          rows: [], summary: TaskSummary());
    }
    return TaskListResp(
        success: false, status: 500, message: 'No Internet',
        rows: [], summary: TaskSummary());
  }

  Future<TaskDetailResponse> getTaskDetailV2(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) || c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.taskDetailV2, body: body);
      if (res.isNotEmpty) {
        try {
          return taskDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskDetailResponse(
              success: false, status: 500, message: e.toString(),
              task: null, followups: []);
        }
      }
      return TaskDetailResponse(
          success: false, status: 500, message: 'Something went wrong',
          task: null, followups: []);
    }
    return TaskDetailResponse(
        success: false, status: 500, message: 'No Internet',
        task: null, followups: []);
  }

  Future<TaskDropdownResp> getTaskDropdownsV2(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) || c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.taskDropdownsV2, body: body);
      if (res.isNotEmpty) {
        try {
          return taskDropdownRespFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskDropdownResp(
              success: false, status: 500, message: e.toString(),
              assignees: [], statuses: [], priorities: []);
        }
      }
      return TaskDropdownResp(
          success: false, status: 500, message: 'Something went wrong',
          assignees: [], statuses: [], priorities: []);
    }
    return TaskDropdownResp(
        success: false, status: 500, message: 'No Internet',
        assignees: [], statuses: [], priorities: []);
  }

  Future<TaskActionResponse> createTaskV2(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) || c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.taskCreateV2, body: body);
      if (res.isNotEmpty) {
        try {
          return taskActionResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskActionResponse(success: false, status: 500, message: e.toString());
        }
      }
      return TaskActionResponse(success: false, status: 500, message: 'Something went wrong');
    }
    return TaskActionResponse(success: false, status: 500, message: 'No Internet');
  }

  Future<TaskActionResponse> addTaskFollowupV2(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) || c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.taskFollowupV2, body: body);
      if (res.isNotEmpty) {
        try {
          return taskActionResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskActionResponse(success: false, status: 500, message: e.toString());
        }
      }
      return TaskActionResponse(success: false, status: 500, message: 'Something went wrong');
    }
    return TaskActionResponse(success: false, status: 500, message: 'No Internet');
  }

  Future<TaskActionResponse> updateTaskStatusV2(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) || c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.taskStatusV2, body: body);
      if (res.isNotEmpty) {
        try {
          return taskActionResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return TaskActionResponse(success: false, status: 500, message: e.toString());
        }
      }
      return TaskActionResponse(success: false, status: 500, message: 'Something went wrong');
    }
    return TaskActionResponse(success: false, status: 500, message: 'No Internet');
  }

  Future<FinancialYearResponse> getFinancialYear(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.financialYear, body: body);
      if (res.isNotEmpty) {
        try {
          return financialYearResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return FinancialYearResponse(status: 500, message: e.toString());
        }
      } else {
        return FinancialYearResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return FinancialYearResponse(status: 500, message: 'No Internet');
    }
  }

  Future<OrderFollowupListResponse> getOrderFollowupListResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.orderFollowupList, body: body);
      if (res.isNotEmpty) {
        try {
          return orderFollowupListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OrderFollowupListResponse(status: 500, message: e.toString());
        }
      } else {
        return OrderFollowupListResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return OrderFollowupListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<OrderFollowupDetailsResponse> getOrderFollowupDetailsResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.orderFollowupDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return orderFollowupDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OrderFollowupDetailsResponse(
              status: 500, message: e.toString());
        }
      } else {
        return OrderFollowupDetailsResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return OrderFollowupDetailsResponse(status: 500, message: 'No Internet');
    }
  }

  Future<OrderFollowupSaveResponse> getOrderFollowupSaveResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.orderFollowupSave, body: body);
      if (res.isNotEmpty) {
        try {
          return orderFollowupSaveResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OrderFollowupSaveResponse(status: 500, message: e.toString());
        }
      } else {
        return OrderFollowupSaveResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return OrderFollowupSaveResponse(status: 500, message: 'No Internet');
    }
  }

  Future<PaymentFollowupListResponse> getPaymentFollowupListResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.paymentFollowupList, body: body);
      if (res.isNotEmpty) {
        try {
          return paymentFollowupListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PaymentFollowupListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return PaymentFollowupListResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return PaymentFollowupListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<PaymentFollowupDetailsResponse> getPaymentFollowupDetailsResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.paymentFollowupDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return paymentFollowupDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PaymentFollowupDetailsResponse(
              status: 500, message: e.toString());
        }
      } else {
        return PaymentFollowupDetailsResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return PaymentFollowupDetailsResponse(
          status: 500, message: 'No Internet');
    }
  }

  Future<PaymentFollowupSaveResponse> getPaymentFollowupSaveResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.paymentFollowupSave, body: body);
      if (res.isNotEmpty) {
        try {
          return paymentFollowupSaveResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PaymentFollowupSaveResponse(
              status: 500, message: e.toString());
        }
      } else {
        return PaymentFollowupSaveResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return PaymentFollowupSaveResponse(status: 500, message: 'No Internet');
    }
  }

  Future<PerformanceListResponse> getPerformanceResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.performance, body: body);
      if (res.isNotEmpty) {
        try {
          return performanceListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PerformanceListResponse(status: 500, message: e.toString());
        }
      } else {
        return PerformanceListResponse(
            status: 500, message: ' Something went Wrong');
      }
    } else {
      return PerformanceListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<DownloadDocumentTypeResponse> getDownloadDocuments(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.downloadDocumentType, body: body);
      if (res.isNotEmpty) {
        try {
          return downloadDocumentTypeResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DownloadDocumentTypeResponse(
              status: 500, message: e.toString());
        }
      } else {
        return DownloadDocumentTypeResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DownloadDocumentTypeResponse(status: 500, message: 'No Internet');
    }
  }

  Future<DownloadDocumentListResponse> getDownloadDocumentsList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.downloadDocumentListWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return downloadDocumentListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DownloadDocumentListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return DownloadDocumentListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DownloadDocumentListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<DownloadDocumentPrintResponse> getDownloadDocumentsPrint(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.downloadDocumentPrint, body: body);
      if (res.isNotEmpty) {
        try {
          return downloadDocumentPrintResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DownloadDocumentPrintResponse(
              status: 500, message: e.toString());
        }
      } else {
        return DownloadDocumentPrintResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DownloadDocumentPrintResponse(status: 500, message: 'No Internet');
    }
  }

  Future<ShippingUpdateDetailsResponse> getShippingUpdateDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.shippingUpdateDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return shippingUpdateDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ShippingUpdateDetailsResponse(
              status: 500, message: e.toString());
        }
      } else {
        return ShippingUpdateDetailsResponse(
            status: 500, message: 'Something want  wong');
      }
    } else {
      return ShippingUpdateDetailsResponse(status: 500, message: 'No Internet');
    }
  }

  Future<ShippingStatusResponse> getShippingStatusDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.shippingStatus, body: body);
      if (res.isNotEmpty) {
        try {
          return shippingStatusResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ShippingStatusResponse(status: 500, message: e.toString());
        }
      } else {
        return ShippingStatusResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ShippingStatusResponse(status: 500, message: 'No Internet');
    }
  }

  Future<ShippingDetailsListResponse> getShippingDetailsListResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.shippingDetailsList, body: body);
      if (res.isNotEmpty) {
        try {
          return shippingDetailsListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ShippingDetailsListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return ShippingDetailsListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ShippingDetailsListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<UpdateShippingValueResponse> getUpdateShippingValueResponse(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateShippingValue, body: body);
      if (res.isNotEmpty) {
        try {
          return updateShippingValueResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return UpdateShippingValueResponse(
              status: 500, message: e.toString());
        }
      } else {
        return UpdateShippingValueResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return UpdateShippingValueResponse(status: 500, message: 'No Internet');
    }
  }

  Future<UserValidateForOrderResponse> checkPartyValidation(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.validateUserForOrder, body: body);
      if (res.isNotEmpty) {
        try {
          return userValidateForOrderResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return UserValidateForOrderResponse(
              status: 500, message: e.toString());
        }
      } else {
        return UserValidateForOrderResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return UserValidateForOrderResponse(status: 500, message: 'No Internet');
    }
  }

  Future<PartylatLngCheck> matchPartyLatLng(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.matchUserLocation, body: body);
      if (res.isNotEmpty) {
        try {
          return partylatLngCheckFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PartylatLngCheck(status: 500, message: e.toString());
        }
      } else {
        return PartylatLngCheck(status: 500, message: 'Something went wrong');
      }
    } else {
      return PartylatLngCheck(status: 500, message: 'No Internet');
    }
  }

  Future<OrderDetailResponse> getOrderDetail(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.singleOrderDetail, body: body);
      if (res.isNotEmpty) {
        try {
          return orderDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OrderDetailResponse(status: 500, message: e.toString());
        }
      } else {
        return OrderDetailResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return OrderDetailResponse(status: 500, message: 'No Internet');
    }
  }

  Future<OrderDetailPdfDownloadResponse> getOrderDetailPdfUrl(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getOrderPdf, body: body);
      if (res.isNotEmpty) {
        try {
          return orderDetailPdfDownloadResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OrderDetailPdfDownloadResponse(
              status: 500, message: e.toString());
        }
      } else {
        return OrderDetailPdfDownloadResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return OrderDetailPdfDownloadResponse(
          status: 500, message: 'No Internet');
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

  Future<CommonResponse> updateOrderStatusApi(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateOrderStatus, body: body);
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

  Future<PartyBalanceDetailResponse> getPartyBalanceDetail(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.partyBalanceDetail, body: body);
      if (res.isNotEmpty) {
        try {
          return partyBalanceDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PartyBalanceDetailResponse(status: 500, message: e.toString());
        }
      } else {
        return PartyBalanceDetailResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return PartyBalanceDetailResponse(status: 500, message: 'No internet');
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

  Future<SelectCategoryListPageBanner> getBannerData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.categoryBannerImage, body: body);
      if (res.isNotEmpty) {
        try {
          return selectCategoryListPageBannerFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return SelectCategoryListPageBanner(
              status: 500, message: e.toString());
        }
      } else {
        return SelectCategoryListPageBanner(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return SelectCategoryListPageBanner(status: 500, message: 'No Internet');
    }
  }

  Future<BrandDataResponse> getBrandData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.brandDataList, body: body);
      if (res.isNotEmpty) {
        try {
          return brandDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return BrandDataResponse(status: 500, message: e.toString());
        }
      } else {
        return BrandDataResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return BrandDataResponse(status: 500, message: 'No Internet');
    }
  }

  Future<CategoryData> getCategoryData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.categoryBrandDataList, body: body);
      if (res.isNotEmpty) {
        try {
          return categoryDataFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CategoryData(status: 500, message: e.toString());
        }
      } else {
        return CategoryData(status: 500, message: 'Something went wrong');
      }
    } else {
      return CategoryData(status: 500, message: 'No Internet');
    }
  }

  Future<SubCategoryBrandData> getSubCategoryBrandData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.subcategoryList, body: body);
      if (res.isNotEmpty) {
        try {
          return subCategoryBrandDataFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return SubCategoryBrandData(status: 500, message: e.toString());
        }
      } else {
        return SubCategoryBrandData(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return SubCategoryBrandData(status: 500, message: 'No Internet');
    }
  }

  Future<BrandListResponse> getBrandList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.brandList, body: body);
      if (res.isNotEmpty) {
        try {
          return brandListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return BrandListResponse(status: 500, message: e.toString());
        }
      } else {
        return BrandListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return BrandListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<RackListResponse> getRackNoList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.rackNoList, body: body);
      if (res.isNotEmpty) {
        try {
          return rackListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return RackListResponse(status: 500, message: e.toString());
        }
      } else {
        return RackListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return RackListResponse(status: 500, message: 'No Internet');
    }
  }

  Future<StockReconciliationReportResponse> getStockReconciliationReportDetails(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stockReconciliationReportDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return stockReconciliationReportResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StockReconciliationReportResponse(
              status: 500, message: e.toString());
        }
      } else {
        return StockReconciliationReportResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return StockReconciliationReportResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<StockReconciliationSubmitResponse> submitReconciliationReportDetails(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stockReconciliationSubmit,
          body: jsonEncode(body),
          header: {"Content-Type": 'application/json'});
      if (res.isNotEmpty) {
        try {
          return stockReconciliationSubmitResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StockReconciliationSubmitResponse(
              status: 500, message: e.toString());
        }
      } else {
        return StockReconciliationSubmitResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return StockReconciliationSubmitResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<ProductData> getProductData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.productListItem, body: body);
      if (res.isNotEmpty) {
        try {
          return productDataFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ProductData(status: 500, message: e.toString());
        }
      } else {
        return ProductData(status: 500, message: 'Something went wrong');
      }
    } else {
      return ProductData(status: 500, message: 'No Internet');
    }
  }

  Future<ProductDetailResponse> productDetail(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.productDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return productDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ProductDetailResponse(status: 500, message: e.toString());
        }
      } else {
        return ProductDetailResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ProductDetailResponse(status: 500, message: 'No internet');
    }
  }

  Future<UnitListResponse> unitDetail(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.unitDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return unitListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return UnitListResponse(status: 500, message: e.toString());
        }
      } else {
        return UnitListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return UnitListResponse(status: 500, message: 'No internet');
    }
  }

  Future<RelatedProductsResponse> relatedProducts(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.itemListVariant, body: body);
      if (res.isNotEmpty) {
        try {
          return relatedProductsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return RelatedProductsResponse(status: 500, message: e.toString());
        }
      } else {
        return RelatedProductsResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return RelatedProductsResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> addCompanyJson(var body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethodJson(
            method: _apiMethods.addPartyOrCompanyNew,
            body: body,
            header: {'Content-Type': 'application/json'});
        if (res.isNotEmpty) {
          return commonResponseFromJson(res);
        } else {
          return CommonResponse(
            status: 500,
            message: 'Something went wrong',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return CommonResponse(
          status: 500,
          message: e.toString(),
        );
      }
    } else {
      return CommonResponse(
        status: 500,
        message: 'No Internet',
      );
    }
  }

  Future<GetCartListResponse> getCartList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getCartDetail, body: body);
      if (res.isNotEmpty) {
        try {
          return getCartListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetCartListResponse(status: 500, message: e.toString());
        }
      } else {
        return GetCartListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetCartListResponse(status: 500, message: 'No internet');
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

  Future<AddToCartResponse> addToCart(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.addToCart, body: body);
      if (res.isNotEmpty) {
        try {
          return addToCartResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AddToCartResponse(status: 500, message: e.toString());
        }
      } else {
        return AddToCartResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return AddToCartResponse(status: 500, message: 'No internet');
    }
  }

  Future<AddToCartResponse> removeFromCart(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.removeFromCart, body: body);
      if (res.isNotEmpty) {
        try {
          return addToCartResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AddToCartResponse(status: 500, message: e.toString());
        }
      } else {
        return AddToCartResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return AddToCartResponse(status: 500, message: 'No internet');
    }
  }

  Future<UpdateCart> updateCart(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateCartDecimalQty, body: body);
      if (res.isNotEmpty) {
        try {
          return updateCartFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return UpdateCart(status: 500, message: e.toString());
        }
      } else {
        return UpdateCart(status: 500, message: 'Something went wrong');
      }
    } else {
      return UpdateCart(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> orderPlace(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.placeOrder, body: body);
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

  Future<CartCountResponse> getCartCount(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.cartCount, body: body);
      if (res.isNotEmpty) {
        try {
          return cartCountResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CartCountResponse(status: 500, message: e.toString());
        }
      } else {
        return CartCountResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CartCountResponse(status: 500, message: 'No internet');
    }
  }

  Future<CustomerDetailResponse> getCustomersDetail(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.customersList, body: body);
      if (res.isNotEmpty) {
        try {
          return customerDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CustomerDetailResponse(status: 500, message: e.toString());
        }
      } else {
        return CustomerDetailResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CustomerDetailResponse(status: 500, message: 'No internet');
    }
  }

  Future<CustomerDetailResponse> getPartyWithBranch(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.partyDetailsWithBranch, body: body);
      if (res.isNotEmpty) {
        try {
          return customerDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CustomerDetailResponse(status: 500, message: e.toString());
        }
      } else {
        return CustomerDetailResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CustomerDetailResponse(status: 500, message: 'No internet');
    }
  }

  Future<CustomerDetailResponse> getCustomer(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.showAccountCustomer, body: body);
      if (res.isNotEmpty) {
        try {
          return customerDetailResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CustomerDetailResponse(status: 500, message: e.toString());
        }
      } else {
        return CustomerDetailResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CustomerDetailResponse(status: 500, message: 'No internet');
    }
  }

  Future<GetBranchandSitResModel> getBranchandSite(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getbranchandsite, body: body);
      if (res.isNotEmpty) {
        try {
          return GetBranchandSitResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetBranchandSitResModel(status: 500, message: e.toString());
        }
      } else {
        return GetBranchandSitResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetBranchandSitResModel(status: 500, message: 'No internet');
    }
  }

  Future<GetApproverNameResModel> getApproverName(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getapprovername, body: body);
      if (res.isNotEmpty) {
        try {
          return GetApproverNameResModel.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetApproverNameResModel(status: 500, message: e.toString());
        }
      } else {
        return GetApproverNameResModel(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetApproverNameResModel(status: 500, message: 'No internet');
    }
  }

  /// Get Payment Request Dropdown
  Future<CommonResponse> paymentRequestDropdown(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log("paymentRequestDropdown :=> ${jsonEncode(body)}");

      String res = await _apiClient.postMethod(
          method: _apiMethods.paymentRequestDropdown, // ← add this constant too
          body: jsonEncode(body),
          header: {"Content-Type": "application/json"});

      log("paymentRequestDropdown RES :=> $res");

      if (res.isNotEmpty) {
        try {
          return CommonResponse.fromJson(jsonDecode(res));
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

  Future<CommonResponse> paymentRequestEntry(Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log("paymentRequestEntry :=> ${jsonEncode(body)}");
      String res = await _apiClient.postMethod(
          method: _apiMethods.paymentrequestentry,
          body: jsonEncode(body),
          header: {"Content-Type": "application/json"});
      log("paymentRequestEntry RES :=> $res");
      if (res.isNotEmpty) {
        try {
          return CommonResponse.fromJson(jsonDecode(res));
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

  /// Get Payment Request List
  Future<CommonResponse> getPaymentRequestList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log("getPaymentRequestList :=> ${jsonEncode(body)}");

      String res = await _apiClient.postMethod(
          method: _apiMethods.paymentRequestList, // ← will use the constant
          body: jsonEncode(body),
          header: {"Content-Type": "application/json"});

      log("getPaymentRequestList RES :=> $res");

      if (res.isNotEmpty) {
        try {
          return CommonResponse.fromJson(jsonDecode(res));
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

  /// Update Payment Request Status (Cancel etc.)
  Future<CommonResponse> updatePaymentRequestStatus(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log("updatePaymentRequestStatus :=> ${jsonEncode(body)}");

      String res = await _apiClient.postMethod(
          method: _apiMethods.updatePaymentRequestStatus,
          body: jsonEncode(body),
          header: {"Content-Type": "application/json"});

      log("updatePaymentRequestStatus RES :=> $res");

      if (res.isNotEmpty) {
        try {
          return CommonResponse.fromJson(jsonDecode(res));
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

  Future<CustomerLocationUpdateResponse> updateCustomersLocation(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateCustomerLocation, body: body);
      if (res.isNotEmpty) {
        try {
          return customerLocationUpdateResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CustomerLocationUpdateResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CustomerLocationUpdateResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CustomerLocationUpdateResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<CustomerRemarkUpdateResponse> updateCustomersRemarks(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.updateCustomerRemark, body: body);
      if (res.isNotEmpty) {
        try {
          return customerRemarkUpdateResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CustomerRemarkUpdateResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CustomerRemarkUpdateResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CustomerRemarkUpdateResponse(status: 500, message: 'No internet');
    }
  }

  Future<DsrPdfResponse> getDSRPdf(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getDsrPdf, body: body);
      if (res.isNotEmpty) {
        try {
          return dsrPdfResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DsrPdfResponse(status: 500, message: e.toString());
        }
      } else {
        return DsrPdfResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return DsrPdfResponse(status: 500, message: 'No internet');
    }
  }

  Future<ExecutiveListDataResponse> getExecutiveListData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.executiveListData, body: body);
      if (res.isNotEmpty) {
        try {
          return executiveListDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ExecutiveListDataResponse(status: 500, message: e.toString());
        }
      } else {
        return ExecutiveListDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ExecutiveListDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<StateDataResponse> getStateData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stateNameList, body: body);
      if (res.isNotEmpty) {
        try {
          return stateDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StateDataResponse(status: 500, message: e.toString());
        }
      } else {
        return StateDataResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return StateDataResponse(status: 500, message: 'No internet');
    }
  }

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

  Future<DocumentnameResponse> getDocumentData(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.documentname, body: body);
      if (res.isNotEmpty) {
        try {
          return documentnameResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DocumentnameResponse(status: 500, message: e.toString());
        }
      } else {
        return DocumentnameResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DocumentnameResponse(status: 500, message: 'No internet');
    }
  }

  Future<ItemListResponse> getItemData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res =
      await _apiClient.postMethod(method: _apiMethods.itemList, body: body);
      if (res.isNotEmpty) {
        try {
          return itemListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ItemListResponse(status: 500, message: e.toString());
        }
      } else {
        return ItemListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return ItemListResponse(status: 500, message: 'No internet');
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

  Future<VendorListResponse> getVendorData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.vendorList, body: body);
      if (res.isNotEmpty) {
        try {
          return vendorListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return VendorListResponse(status: 500, message: e.toString());
        }
      } else {
        return VendorListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return VendorListResponse(status: 500, message: 'No internet');
    }
  }

  Future<ClientListResponse> getClientData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.clientNameList, body: body);
      if (res.isNotEmpty) {
        try {
          return clientListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ClientListResponse(status: 500, message: e.toString());
        }
      } else {
        return ClientListResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return ClientListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CityDataResponse> getCityData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.cityNameList, body: body);
      if (res.isNotEmpty) {
        try {
          return cityDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CityDataResponse(status: 500, message: e.toString());
        }
      } else {
        return CityDataResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return CityDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<AreaDataResponse> getAreaData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.areaNameList, body: body);
      if (res.isNotEmpty) {
        try {
          return areaDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AreaDataResponse(status: 500, message: e.toString());
        }
      } else {
        return AreaDataResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return AreaDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<StockCategoryDataResponse> getStockCategoryData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stockCategory, body: body);
      if (res.isNotEmpty) {
        try {
          return stockCategoryDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StockCategoryDataResponse(status: 500, message: e.toString());
        }
      } else {
        return StockCategoryDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return StockCategoryDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<StockCategoryDataResponse> getCategoryCatalougeData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.categoryNewList, body: body);
      if (res.isNotEmpty) {
        try {
          return stockCategoryDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StockCategoryDataResponse(status: 500, message: e.toString());
        }
      } else {
        return StockCategoryDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return StockCategoryDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<StockSubmitDataResponse> stockSubmitData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stockTaking, body: body);
      if (res.isNotEmpty) {
        try {
          return stockSubmitDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StockSubmitDataResponse(status: 500, message: e.toString());
        }
      } else {
        return StockSubmitDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return StockSubmitDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<CustomerDataResponse> customerListData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.searchAreaWiseClientForVisit, body: body);
      if (res.isNotEmpty) {
        try {
          return customerDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CustomerDataResponse(status: 500, message: e.toString());
        }
      } else {
        return CustomerDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CustomerDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<AddCustomerToVisitDataResponse> addVisitDataToVisit(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.addToVisit, body: body);
      if (res.isNotEmpty) {
        try {
          return addCustomerToVisitDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AddCustomerToVisitDataResponse(
              status: 500, message: e.toString());
        }
      } else {
        return AddCustomerToVisitDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return AddCustomerToVisitDataResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<NearByDataResponse> nearByData(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.nearByList, body: body);
      if (res.isNotEmpty) {
        try {
          return nearByDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return NearByDataResponse(status: 500, message: e.toString());
        }
      } else {
        return NearByDataResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return NearByDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<PreviewVisitDataResponse> previewVisitData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.previewVisitList, body: body);
      if (res.isNotEmpty) {
        try {
          return previewVisitDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PreviewVisitDataResponse(status: 500, message: e.toString());
        }
      } else {
        return PreviewVisitDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return PreviewVisitDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<DeleteVisitDataResponse> deleteVisitData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.deleteVisitList, body: body);
      if (res.isNotEmpty) {
        try {
          return deleteVisitDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DeleteVisitDataResponse(status: 500, message: e.toString());
        }
      } else {
        return DeleteVisitDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DeleteVisitDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<SubmitVisitDataResponse> saveVisitData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.saveVisitEntry, body: body);
      if (res.isNotEmpty) {
        try {
          return submitVisitDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return SubmitVisitDataResponse(status: 500, message: e.toString());
        }
      } else {
        return SubmitVisitDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return SubmitVisitDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<AllVisitDataResponse> allVisitListData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.allVisitList, body: body);
      if (res.isNotEmpty) {
        try {
          return allVisitDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return AllVisitDataResponse(status: 500, message: e.toString());
        }
      } else {
        return AllVisitDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return AllVisitDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<DistanceDetailsResponse> distanceDetailsData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.distanceDetails, body: body);
      if (res.isNotEmpty) {
        try {
          return distanceDetailsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DistanceDetailsResponse(status: 500, message: e.toString());
        }
      } else {
        return DistanceDetailsResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DistanceDetailsResponse(status: 500, message: 'No internet');
    }
  }

  Future<VisitPlanDetailDataResponse> visitPlanDetailListData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.visitPlanDetail, body: body);
      if (res.isNotEmpty) {
        try {
          return visitPlanDetailDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return VisitPlanDetailDataResponse(
              status: 500, message: e.toString());
        }
      } else {
        return VisitPlanDetailDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return VisitPlanDetailDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<VisitCheckInResponse> visitCheckInData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log("CHECK IN BODY :==> ${jsonEncode(body)}");
      String res = await _apiClient.postMethod(
          method: _apiMethods.visitCheckIn, body: body);
      if (res.isNotEmpty) {
        try {
          return visitCheckInResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return VisitCheckInResponse(status: 500, message: e.toString());
        }
      } else {
        return VisitCheckInResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return VisitCheckInResponse(status: 500, message: 'No internet');
    }
  }

  Future<VisitCheckOutResponse> visitCheckOutData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      log("CHECK IN BODY :==> ${jsonEncode(body)}");
      String res = await _apiClient.postMethod(
          method: _apiMethods.visitPlanCheckout, body: body);
      if (res.isNotEmpty) {
        try {
          return visitCheckOutResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return VisitCheckOutResponse(status: 500, message: e.toString());
        }
      } else {
        return VisitCheckOutResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return VisitCheckOutResponse(status: 500, message: 'No internet');
    }
  }

  Future<CashAndbankLedgerResponse> cashAndBankLedgerData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.showCashAndBankAccount, body: body);
      if (res.isNotEmpty) {
        try {
          return cashAndbankLedgerResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CashAndbankLedgerResponse(status: 500, message: e.toString());
        }
      } else {
        return CashAndbankLedgerResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CashAndbankLedgerResponse(status: 500, message: 'No internet');
    }
  }

  Future<PaymentEntrySubmitResponse> collectionEntrySubmitData(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.paymentEntrySubmit,
        body: json.encode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return paymentEntrySubmitResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PaymentEntrySubmitResponse(status: 500, message: e.toString());
        }
      } else {
        return PaymentEntrySubmitResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return PaymentEntrySubmitResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionCustomerListResponse> collectionCustomerList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.customerList, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionCustomerListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionCustomerListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CollectionCustomerListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionCustomerListResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> collectionEntrySubmit(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.collectionEntry,
          body: jsonEncode(body),
          header: {'Content-Type': 'application/json'});
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

  Future<CollectionListResponse> collectionList({
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: VoucherType.collection,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionListResponse> listWithFilter({
    required String voucherType,
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: voucherType.toString(),
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionListResponse> receiptList({
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: VoucherType.receipt,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionListResponse> paymentList({
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: VoucherType.payment,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionListResponse> expenseList({
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: VoucherType.expense,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionListResponse> contraList({
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: VoucherType.contra,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionListResponse> journalList({
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: VoucherType.journal,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionListResponse(status: 500, message: e.toString());
        }
      } else {
        return CollectionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<VoucherListResponse> vouchersList({
    required String voucherType,
    required String compId,
    required String branchId,
    required String userId,
    required String partyId,
    required String fromDate,
    required String toDate,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      Map<String, String> body = {
        RequestKeys.voucherType: voucherType,
        RequestKeys.compId: compId,
        RequestKeys.branchId: branchId,
        RequestKeys.userId: userId,
        RequestKeys.partyId: partyId,
        RequestKeys.fromDate: fromDate,
        RequestKeys.toDate: toDate
      };

      String res = await _apiClient.postMethod(
          method: _apiMethods.listWithFilter, body: body);
      if (res.isNotEmpty) {
        try {
          return voucherListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return VoucherListResponse(status: 500, message: e.toString());
        }
      } else {
        return VoucherListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return VoucherListResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionCustomerListResponse> expensesHeadList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.expensesHead, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionCustomerListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionCustomerListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CollectionCustomerListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionCustomerListResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> contraEntrySubmit(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.contraEntry, body: body);
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

  Future<CollectionCustomerListResponse> fromAccount(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.fromAccount, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionCustomerListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionCustomerListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CollectionCustomerListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionCustomerListResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> journalEntry(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.journalEntry, body: body);
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

  Future<CollectionCustomerListResponse> debitCreditAccountList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.debitCreditAccount, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionCustomerListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionCustomerListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CollectionCustomerListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionCustomerListResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<TransactionListResponse> transactionList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.transactionList, body: body);
      if (res.isNotEmpty) {
        try {
          return transactionListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return TransactionListResponse(status: 500, message: e.toString());
        }
      } else {
        return TransactionListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return TransactionListResponse(status: 500, message: 'No internet');
    }
  }

  Future<OutstandingDataResponse> getPartyOutstanding(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.partyOutstanding, body: body);
      if (res.isNotEmpty) {
        try {
          return outstandingDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return OutstandingDataResponse(status: 500, message: e.toString());
        }
      } else {
        return OutstandingDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return OutstandingDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<PdfUrlResponse> partyLedgerPDF(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.printPartyLedger, body: body);
      if (res.isNotEmpty) {
        try {
          return pdfUrlResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PdfUrlResponse(status: 500, message: e.toString());
        }
      } else {
        return PdfUrlResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return PdfUrlResponse(status: 500, message: 'No internet');
    }
  }

  Future<CollectionCustomerListResponse> contraDropdownList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.showCashAndBankAccount, body: body);
      if (res.isNotEmpty) {
        try {
          return collectionCustomerListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CollectionCustomerListResponse(
              status: 500, message: e.toString());
        }
      } else {
        return CollectionCustomerListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CollectionCustomerListResponse(
          status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> expenseEntrySubmit(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.voucherEntrySubmit,
        body: json.encode(body),
        header: {'Content-Type': 'application/json'},
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

  Future<CommonResponse> voucherEntrySubmit(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.voucherEntrySubmit,
          body: body,
          header: {'Content-Type': 'application/json'});
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

  /// mis Module
  Future<GetParentGroupResp> getParentGroup(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.getParentGroup,
        body: body,
        // header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return getParentGroupRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetParentGroupResp(status: 500, message: e.toString());
        }
      } else {
        return GetParentGroupResp(status: 500, message: 'Something went wrong');
      }
    } else {
      return GetParentGroupResp(status: 500, message: 'No internet');
    }
  }

  Future<GetPartyForParentResp> getPartyForParent(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
        method: _apiMethods.getPartyForParent,
        body: body,
        // header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return getPartyForParentRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetPartyForParentResp(status: 500, message: e.toString());
        }
      } else {
        return GetPartyForParentResp(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetPartyForParentResp(status: 500, message: 'No internet');
    }
  }

  Future<MisOutstandingResp> showAllPartyOutstanding(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.showAllPartyOutstanding,
          body: jsonEncode(body),
          header: {
            'Content-Type': 'application'
                '/json'
          });
      if (res.isNotEmpty) {
        try {
          return misOutstandingRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return MisOutstandingResp(status: 500, message: e.toString());
        }
      } else {
        return MisOutstandingResp(status: 500, message: 'Something went wrong');
      }
    } else {
      return MisOutstandingResp(status: 500, message: 'No internet');
    }
  }

  Future<PdfUrlResponse> printAccountMisReport(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.printAccountMisReport, body: body);
      if (res.isNotEmpty) {
        try {
          return pdfUrlResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PdfUrlResponse(status: 500, message: e.toString());
        }
      } else {
        return PdfUrlResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return PdfUrlResponse(status: 500, message: 'No internet');
    }
  }

  Future<PdfUrlResponse> printAccountRegisterMisReport(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.printAccountRegisterMisReport, body: body);
      if (res.isNotEmpty) {
        try {
          return pdfUrlResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return PdfUrlResponse(status: 500, message: e.toString());
        }
      } else {
        return PdfUrlResponse(status: 500, message: 'Something went wrong');
      }
    } else {
      return PdfUrlResponse(status: 500, message: 'No internet');
    }
  }

  Future<GetAccountRegisterLedgerResp> getAccountRegisterLedger(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getAccountRegisterLedger, body: body);
      if (res.isNotEmpty) {
        try {
          return getAccountRegisterLedgerRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetAccountRegisterLedgerResp(
              status: 500, message: e.toString());
        }
      } else {
        return GetAccountRegisterLedgerResp(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetAccountRegisterLedgerResp(status: 500, message: 'No internet');
    }
  }

  Future<GetShippingStatusResp> getShippingStatus(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getShippingStatus, body: body);
      if (res.isNotEmpty) {
        try {
          return getShippingStatusRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetShippingStatusResp(status: 500, message: e.toString());
        }
      } else {
        return GetShippingStatusResp(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetShippingStatusResp(status: 500, message: 'No internet');
    }
  }

  Future<GetPendingShippingResp> getPendingShipping(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getPendingShipping, body: body);
      if (res.isNotEmpty) {
        try {
          return getPendingShippingRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetPendingShippingResp(status: 500, message: e.toString());
        }
      } else {
        return GetPendingShippingResp(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetPendingShippingResp(status: 500, message: 'No internet');
    }
  }

  Future<GetAttendanceReportResp> getAttendanceReport(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getAttendanceReport, body: body);
      if (res.isNotEmpty) {
        try {
          return getAttendanceReportRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetAttendanceReportResp(status: 500, message: e.toString());
        }
      } else {
        return GetAttendanceReportResp(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetAttendanceReportResp(status: 500, message: 'No internet');
    }
  }

  Future<GetOrderReportResp> getOrderReport(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getOrderReport, body: body);
      if (res.isNotEmpty) {
        try {
          return getOrderReportRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetOrderReportResp(status: 500, message: e.toString());
        }
      } else {
        return GetOrderReportResp(status: 500, message: 'Something went wrong');
      }
    } else {
      return GetOrderReportResp(status: 500, message: 'No internet');
    }
  }

  Future<GetStoreNameResp> getStoreName(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getStoreName, body: body);
      if (res.isNotEmpty) {
        try {
          return getStoreNameRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetStoreNameResp(status: 500, message: e.toString());
        }
      } else {
        return GetStoreNameResp(status: 500, message: 'Something went wrong');
      }
    } else {
      return GetStoreNameResp(status: 500, message: 'No internet');
    }
  }

  Future<GetStockReportResp> getStockReport(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.getStockReport, body: body);
      if (res.isNotEmpty) {
        try {
          return getStockReportRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return GetStockReportResp(status: 500, message: e.toString());
        }
      } else {
        return GetStockReportResp(status: 500, message: 'Something went wrong');
      }
    } else {
      return GetStockReportResp(status: 500, message: 'No internet');
    }
  }

  // ── Stock / Item Enquiry ──
  /// Item list with total current stock (search + optional category filter).
  Future<StockEnquiryItemResp> getStockEnquiryItems(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stockEnquiryItems, body: body);
      if (res.isNotEmpty) {
        try {
          return stockEnquiryItemRespFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return StockEnquiryItemResp(status: 500, message: e.toString());
        }
      }
      return StockEnquiryItemResp(status: 500, message: 'Something went wrong');
    }
    return StockEnquiryItemResp(status: 500, message: 'No internet');
  }

  /// One item's stock broken down per godown (+ header totals).
  Future<StockEnquiryGodownResp> getStockEnquiryGodownWise(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.stockEnquiryGodownWise, body: body);
      if (res.isNotEmpty) {
        try {
          return stockEnquiryGodownRespFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return StockEnquiryGodownResp(status: 500, message: e.toString());
        }
      }
      return StockEnquiryGodownResp(
          status: 500, message: 'Something went wrong');
    }
    return StockEnquiryGodownResp(status: 500, message: 'No internet');
  }

  // ── Lead Management ──
  /// Full dashboard bundle (leads + follow-ups + tasks + notes + estimates +
  /// quotations) from the ERP proc leaddetailsdetestnew in a single round-trip.
  Future<LeadBundleResponse> getLeadDashboard(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leadDashboard, body: body);
      if (res.isNotEmpty) {
        try {
          return leadBundleResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadBundleResponse(status: 500, message: e.toString());
        }
      }
      return LeadBundleResponse(status: 500, message: 'Something went wrong');
    }
    return LeadBundleResponse(status: 500, message: 'No internet');
  }

  /// Lead Entry form dropdowns (status, source, category, priority, designation,
  /// segment, industry, assign-to, company-type, units).
  Future<LeadFormResponse> getLeadFormDropdowns(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leadFormDropdowns, body: body);
      if (res.isNotEmpty) {
        try {
          return leadFormResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadFormResponse(status: 500, message: e.toString());
        }
      }
      return LeadFormResponse(status: 500, message: 'Something went wrong');
    }
    return LeadFormResponse(status: 500, message: 'No internet');
  }

  /// Existing companies (parties) for the "Existing" company type.
  Future<LeadOptionsResponse> getLeadCompanies(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leadCompanies, body: body);
      if (res.isNotEmpty) {
        try {
          return leadOptionsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadOptionsResponse(status: 500, message: e.toString());
        }
      }
      return LeadOptionsResponse(status: 500, message: 'Something went wrong');
    }
    return LeadOptionsResponse(status: 500, message: 'No internet');
  }

  /// Item master for the item grid.
  Future<LeadOptionsResponse> getLeadItemMaster(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leadItemMaster, body: body);
      if (res.isNotEmpty) {
        try {
          return leadOptionsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadOptionsResponse(status: 500, message: e.toString());
        }
      }
      return LeadOptionsResponse(status: 500, message: 'Something went wrong');
    }
    return LeadOptionsResponse(status: 500, message: 'No internet');
  }

  /// Party auto-fill when an Existing company is selected.
  Future<LeadPartyResponse> getLeadPartyDetail(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leadPartyDetail, body: body);
      if (res.isNotEmpty) {
        try {
          return leadPartyResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadPartyResponse(status: 500, message: e.toString());
        }
      }
      return LeadPartyResponse(status: 500, message: 'Something went wrong');
    }
    return LeadPartyResponse(status: 500, message: 'No internet');
  }

  /// Create/update a lead (ERP proc create_LeadEntrywithsizecolor).
  Future<CommonResponse> saveLead(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res =
            await _apiClient.postMethod(method: _apiMethods.leadSave, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  /// Lead header + item lines (ERP proc EditLeadEntry) for the detail screen.
  Future<LeadItemsResponse> getLeadItems(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.leadItems, body: body);
      if (res.isNotEmpty) {
        try {
          return leadItemsResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadItemsResponse(status: 500, message: e.toString());
        }
      }
      return LeadItemsResponse(status: 500, message: 'Something went wrong');
    }
    return LeadItemsResponse(status: 500, message: 'No internet');
  }

  Future<LeadListResponse> getLeadList(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res =
          await _apiClient.postMethod(method: _apiMethods.leadList, body: body);
      if (res.isNotEmpty) {
        try {
          return leadListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadListResponse(status: 500, message: e.toString());
        }
      }
      return LeadListResponse(status: 500, message: 'Something went wrong');
    }
    return LeadListResponse(status: 500, message: 'No internet');
  }

  Future<LeadFollowupResponse> getLeadFollowups(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.leadFollowups, body: body);
      if (res.isNotEmpty) {
        try {
          return leadFollowupResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print(e);
          return LeadFollowupResponse(status: 500, message: e.toString());
        }
      }
      return LeadFollowupResponse(status: 500, message: 'Something went wrong');
    }
    return LeadFollowupResponse(status: 500, message: 'No internet');
  }

  Future<CommonResponse> createLead(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethod(
            method: _apiMethods.leadCreate, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  Future<CommonResponse> addLeadFollowup(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethod(
            method: _apiMethods.leadAddFollowup, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  Future<CommonResponse> addLeadTask(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethod(
            method: _apiMethods.leadAddTask, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  Future<CommonResponse> saveLeadEstimate(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethod(
            method: _apiMethods.leadSaveEstimate, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  // ── Performa Invoice (Sale Order) — read-only ──
  Future<SaleOrderListResponse> getSaleOrderList(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.saleorderList, body: body);
        if (res.isNotEmpty) {
          return SaleOrderListResponse.fromJson(jsonDecode(res));
        }
        return SaleOrderListResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return SaleOrderListResponse(status: 500, message: e.toString());
      }
    }
    return SaleOrderListResponse(status: 500, message: 'No internet');
  }

  Future<SaleOrderDetailResponse> getSaleOrderDetail(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.saleorderDetail, body: body);
        if (res.isNotEmpty) {
          return SaleOrderDetailResponse.fromJson(jsonDecode(res));
        }
        return SaleOrderDetailResponse(
            status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return SaleOrderDetailResponse(status: 500, message: e.toString());
      }
    }
    return SaleOrderDetailResponse(status: 500, message: 'No internet');
  }

  // ── Performa Invoice CREATE form ──
  Future<SaleOrderFormResponse> getSaleOrderFormDropdowns(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.saleorderFormDropdowns, body: body);
      if (res.isNotEmpty) return SaleOrderFormResponse.fromJson(jsonDecode(res));
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return SaleOrderFormResponse(status: 500, message: 'Something went wrong');
  }

  Future<SaleOrderOptionListResponse> getSaleOrderPartyNames(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.saleorderPartyNames, body: body);
      if (res.isNotEmpty) {
        return SaleOrderOptionListResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return SaleOrderOptionListResponse(status: 500);
  }

  Future<SaleOrderOptionListResponse> getSaleOrderStoreContacts(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.saleorderStoreContacts, body: body);
      if (res.isNotEmpty) {
        return SaleOrderOptionListResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return SaleOrderOptionListResponse(status: 500);
  }

  Future<SaleOrderOptionListResponse> getSaleOrderItemMaster(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.saleorderItemMaster, body: body);
      if (res.isNotEmpty) {
        return SaleOrderOptionListResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return SaleOrderOptionListResponse(status: 500);
  }

  Future<SaleOrderPartyDetailResponse> getSaleOrderPartyDetail(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.saleorderPartyDetail, body: body);
      if (res.isNotEmpty) {
        return SaleOrderPartyDetailResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return SaleOrderPartyDetailResponse(status: 500);
  }

  Future<CommonResponse> saveSaleOrder(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.saleorderSave, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  // ── Purchase Order — read-only ──
  Future<PurchaseOrderListResponse> getPurchaseOrderList(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.purchaseorderList, body: body);
        if (res.isNotEmpty) {
          return PurchaseOrderListResponse.fromJson(jsonDecode(res));
        }
        return PurchaseOrderListResponse(
            status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return PurchaseOrderListResponse(status: 500, message: e.toString());
      }
    }
    return PurchaseOrderListResponse(status: 500, message: 'No internet');
  }

  Future<PurchaseOrderDetailResponse> getPurchaseOrderDetail(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.purchaseorderDetail, body: body);
        if (res.isNotEmpty) {
          return PurchaseOrderDetailResponse.fromJson(jsonDecode(res));
        }
        return PurchaseOrderDetailResponse(
            status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return PurchaseOrderDetailResponse(status: 500, message: e.toString());
      }
    }
    return PurchaseOrderDetailResponse(status: 500, message: 'No internet');
  }

  // ── Purchase Order CREATE form ──
  Future<PoFormResponse> getPurchaseOrderFormDropdowns(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.purchaseorderFormDropdowns, body: body);
      if (res.isNotEmpty) return PoFormResponse.fromJson(jsonDecode(res));
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return PoFormResponse(status: 500, message: 'Something went wrong');
  }

  Future<PoOptionListResponse> getPurchaseOrderPartyNames(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.purchaseorderPartyNames, body: body);
      if (res.isNotEmpty) {
        return PoOptionListResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return PoOptionListResponse(status: 500);
  }

  Future<PoOptionListResponse> getPurchaseOrderStoreContacts(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.purchaseorderStoreContacts, body: body);
      if (res.isNotEmpty) {
        return PoOptionListResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return PoOptionListResponse(status: 500);
  }

  Future<PoOptionListResponse> getPurchaseOrderItemMaster(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.purchaseorderItemMaster, body: body);
      if (res.isNotEmpty) {
        return PoOptionListResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return PoOptionListResponse(status: 500);
  }

  Future<PoPartyDetailResponse> getPurchaseOrderPartyDetail(
      Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.purchaseorderPartyDetail, body: body);
      if (res.isNotEmpty) {
        return PoPartyDetailResponse.fromJson(jsonDecode(res));
      }
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return PoPartyDetailResponse(status: 500);
  }

  Future<CommonResponse> savePurchaseOrder(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.purchaseorderSave, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  // ── Pending Indent for PO ──
  Future<PendingIndentListResponse> getPendingIndentsForPo(
      Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        final res = await _apiClient.postMethod(
            method: _apiMethods.purchaseorderPendingIndents, body: body);
        if (res.isNotEmpty) {
          return PendingIndentListResponse.fromJson(jsonDecode(res));
        }
        return PendingIndentListResponse(
            status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return PendingIndentListResponse(status: 500, message: e.toString());
      }
    }
    return PendingIndentListResponse(status: 500, message: 'No internet');
  }

  Future<IndentSeedResponse> getIndentForPo(Map<String, String> body) async {
    try {
      final res = await _apiClient.postMethod(
          method: _apiMethods.purchaseorderIndentForPo, body: body);
      if (res.isNotEmpty) return IndentSeedResponse.fromJson(jsonDecode(res));
    } catch (e) {
      if (kDebugMode) print(e);
    }
    return IndentSeedResponse(status: 500, message: 'Something went wrong');
  }

  Future<CommonResponse> saveLeadQuotation(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethod(
            method: _apiMethods.leadSaveQuotation, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  Future<CommonResponse> addLeadNote(Map<String, String> body) async {
    final c = await connectivity.checkConnectivity();
    if (c.contains(ConnectivityResult.wifi) ||
        c.contains(ConnectivityResult.mobile)) {
      try {
        String res = await _apiClient.postMethod(
            method: _apiMethods.leadAddNote, body: body);
        if (res.isNotEmpty) return commonResponseFromJson(res);
        return CommonResponse(status: 500, message: 'Something went wrong');
      } catch (e) {
        if (kDebugMode) print(e);
        return CommonResponse(status: 500, message: e.toString());
      }
    }
    return CommonResponse(status: 500, message: 'No internet');
  }

  Future<ExecutiveListDataResponse> executiveReportPersonListForeImageStamping(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.executiveReportPersonListForeImageStamping,
          body: body);
      if (res.isNotEmpty) {
        try {
          return executiveListDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ExecutiveListDataResponse(status: 500, message: e.toString());
        }
      } else {
        return ExecutiveListDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ExecutiveListDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<ImageListResp> imageList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.imageList, body: body);
      if (res.isNotEmpty) {
        try {
          return imageListRespFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return ImageListResp(status: 500, message: e.toString());
        }
      } else {
        return ImageListResp(status: 500, message: 'Something went wrong');
      }
    } else {
      return ImageListResp(status: 500, message: 'No internet');
    }
  }

  Future<StockCategoryDataResponse> categoryListForeImageStamping(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.categoryListForeImageStamping, body: body);
      if (res.isNotEmpty) {
        try {
          return stockCategoryDataResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return StockCategoryDataResponse(status: 500, message: e.toString());
        }
      } else {
        return StockCategoryDataResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return StockCategoryDataResponse(status: 500, message: 'No internet');
    }
  }

  Future<CommonResponse> saveImageStamping(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.saveImageStamping, body: body);
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

  Future<CatalougeListResponse> catalogueList(Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.categoryCatalouge, body: body);
      if (res.isNotEmpty) {
        try {
          return catalogueListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return CatalougeListResponse(status: 500, message: e.toString());
        }
      } else {
        return CatalougeListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return CatalougeListResponse(status: 500, message: 'No internet');
    }
  }

  Future<SalesInvoiceListResponse> salesInvoiceList(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.salesInvoice, body: body);
      if (res.isNotEmpty) {
        try {
          return salesInvoiceListResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return SalesInvoiceListResponse(status: 500, message: e.toString());
        }
      } else {
        return SalesInvoiceListResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return SalesInvoiceListResponse(status: 500, message: 'No internet');
    }
  }

  Future<DownloadSalarySleepRes> salarySleepApi(
      Map<String, String> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethod(
          method: _apiMethods.downloadSalarySleep, body: body);
      if (res.isNotEmpty) {
        try {
          return downloadSalarySleepResFromJson(res);
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          return DownloadSalarySleepRes(status: 500, message: e.toString());
        }
      } else {
        return DownloadSalarySleepRes(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return DownloadSalarySleepRes(status: 500, message: 'No internet');
    }
  }

  ///MRN APIs

  Future<MrnListResponse> getMrnList(MrnListRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getMrnList, // add 'api/getmrnlist' to _apiMethods
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnListResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getMrnList parse error: $e');
          return MrnListResponse(status: 500, message: e.toString());
        }
      }
      return MrnListResponse(status: 500, message: 'Something went wrong');
    }
    return MrnListResponse(status: 500, message: 'No Internet');
  }

  Future<MrnDetailResponse> getMrnDetail(Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getMrnDetail,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getMrnDetail parse error: $e');
          return MrnDetailResponse(status: 500, message: e.toString());
        }
      }
      return MrnDetailResponse(status: 500, message: 'Something went wrong');
    }
    return MrnDetailResponse(status: 500, message: 'No Internet');
  }

  Future<MrnDropdownResponse> getMrnDropdownList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getMrnDropdownList,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnDropdownResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print(e);
          return MrnDropdownResponse(status: 500, message: e.toString());
        }
      } else {
        return MrnDropdownResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return MrnDropdownResponse(status: 500, message: 'No Internet');
    }
  }

  Future<GetPendingPoResponse> getPendingPoList(
      GetPendingPoRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getPendingPo,
        body: request.toJsonString(),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return getPendingPoResponseFromJson(res);
        } catch (e) {
          if (kDebugMode) print('getPendingPoList parse error: $e');
          return GetPendingPoResponse(status: 500, message: e.toString());
        }
      } else {
        return GetPendingPoResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GetPendingPoResponse(status: 500, message: 'No Internet');
    }
  }

  Future<ProcessPendingPoResponse> processPoItems(
      ProcessPendingPoRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.processPendingPoList, // ✅ add this to _apiMethods
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return ProcessPendingPoResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('processPoItems parse error: $e');
          return ProcessPendingPoResponse(status: 500, message: e.toString());
        }
      } else {
        return ProcessPendingPoResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return ProcessPendingPoResponse(status: 500, message: 'No Internet');
    }
  }

  Future<MrnSubmitResponse> saveMrnEntry(Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.saveMrnEntry, // add: 'api/savemrnentry'
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnSubmitResponse.fromJson(jsonDecode(res));
        } catch (e) {
          return MrnSubmitResponse(status: 500, message: e.toString());
        }
      }
      return MrnSubmitResponse(status: 500, message: 'Something went wrong');
    }
    return MrnSubmitResponse(status: 500, message: 'No Internet');
  }

  Future<MrnItemDetailResponse> getItemDetail({
    required int compid,
    required int itemid,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      final body = jsonEncode({'compid': compid, 'itemid': itemid});
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getItemDetail,
        body: body,
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnItemDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getItemDetail error: $e');
          return MrnItemDetailResponse(status: 500, message: e.toString());
        }
      }
      return MrnItemDetailResponse(
          status: 500, message: 'Something went wrong');
    }
    return MrnItemDetailResponse(status: 500, message: 'No Internet');
  }

  ///GRN APIs-------------------------------------------------------------------
  Future<GrnSubmitResponse> saveGrnEntry(Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.saveGrnEntry, // add: 'api/savegrnentry'
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return GrnSubmitResponse.fromJson(jsonDecode(res));
        } catch (e) {
          return GrnSubmitResponse(status: 500, message: e.toString());
        }
      }
      return GrnSubmitResponse(status: 500, message: 'Something went wrong');
    }
    return GrnSubmitResponse(status: 500, message: 'No Internet');
  }

  Future<GrnDetailResponse> getGrnDetail(Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getGrnDetail,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return GrnDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getGrnDetail parse error: $e');
          return GrnDetailResponse(status: 500, message: e.toString());
        }
      }
      return GrnDetailResponse(status: 500, message: 'Something went wrong');
    }
    return GrnDetailResponse(status: 500, message: 'No Internet');
  }

  Future<GrnListResponse> getGrnList(GrnListRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getGrnList, // add 'api/getgrnlist' to _apiMethods
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return GrnListResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getGrnList parse error: $e');
          return GrnListResponse(status: 500, message: e.toString());
        }
      }
      return GrnListResponse(status: 500, message: 'Something went wrong');
    }
    return GrnListResponse(status: 500, message: 'No Internet');
  }

  Future<GrnDropdownResponse> getGrnDropdownList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getGrnDropdownList,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return GrnDropdownResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print(e);
          return GrnDropdownResponse(status: 500, message: e.toString());
        }
      } else {
        return GrnDropdownResponse(
            status: 500, message: 'Something went wrong');
      }
    } else {
      return GrnDropdownResponse(status: 500, message: 'No Internet');
    }
  }

  Future<GrnItemDetailResponse> getGrnItemDetail({
    required int compid,
    required int itemid,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      final body = jsonEncode({'compid': compid, 'itemid': itemid});
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getGrnItemDetail,
        body: body,
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return GrnItemDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getItemDetail error: $e');
          return GrnItemDetailResponse(status: 500, message: e.toString());
        }
      }
      return GrnItemDetailResponse(
          status: 500, message: 'Something went wrong');
    }
    return GrnItemDetailResponse(status: 500, message: 'No Internet');
  }

  Future<DependentDetailResponse> getDependentAllDetail(
      DependentDetailRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method:
        _apiMethods.getDependentAllDetail, // 'api/getdependentalldetail'
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return DependentDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getDependentAllDetail parse error: $e');
          return DependentDetailResponse(status: 500, message: e.toString());
        }
      }
      return DependentDetailResponse(
          status: 500, message: 'Something went wrong');
    }
    return DependentDetailResponse(status: 500, message: 'No Internet');
  }

  Future<LedgerAddressResponse> getLedgerAddressAndValuePercent(
      LedgerAddressRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getAddress,
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );

      if (res.isNotEmpty) {
        try {
          return LedgerAddressResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print('getLedgerAddressAndValuePercent parse error: $e');
          }
          return LedgerAddressResponse(
            status: 500,
            message: e.toString(),
          );
        }
      }

      return LedgerAddressResponse(
        status: 500,
        message: 'Something went wrong',
      );
    }

    return LedgerAddressResponse(
      status: 500,
      message: 'No Internet',
    );
  }

  Future<MrnLedgerAddressResponse> getMrnLedgerAddressAndValuePercent(
      MrnLedgerAddressRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getAddress,
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );

      if (res.isNotEmpty) {
        try {
          return MrnLedgerAddressResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) {
            print('getLedgerAddressAndValuePercent parse error: $e');
          }
          return MrnLedgerAddressResponse(
            status: 500,
            message: e.toString(),
          );
        }
      }

      return MrnLedgerAddressResponse(
        status: 500,
        message: 'Something went wrong',
      );
    }

    return MrnLedgerAddressResponse(
      status: 500,
      message: 'No Internet',
    );
  }

  /// MRN QC APIS --------------------------------------------------------------
  Future<MrnQcListResponse> getMrnQcList(MrnQcListRequest request) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getMrnQcList, // add 'api/getmrnlist' to _apiMethods
        body: jsonEncode(request.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnQcListResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getMrnList parse error: $e');
          return MrnQcListResponse(status: 500, message: e.toString());
        }
      }
      return MrnQcListResponse(status: 500, message: 'Something went wrong');
    }
    return MrnQcListResponse(status: 500, message: 'No Internet');
  }

  Future<MrnQcDetailResponse> getMrnQcDetail(MrnQcDetailRequest req) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getMrnQcDetail, // add 'api/mrnandqcdetail' to _apiMethods
        body: jsonEncode(req.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return MrnQcDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getMrnQcDetail parse error: $e');
          return MrnQcDetailResponse(
              success: false, status: 500, message: e.toString());
        }
      }
      return MrnQcDetailResponse(
          success: false, status: 500, message: 'Something went wrong');
    }
    return MrnQcDetailResponse(
        success: false, status: 500, message: 'No Internet');
  }

  Future<SaveQcEntryResponse> saveQcEntry(SaveQcEntryRequest req) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.saveQcEntry, // add 'api/saveqcentry' to _apiMethods
        body: jsonEncode(req.toJson()),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return SaveQcEntryResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('saveQcEntry parse error: $e');
          return SaveQcEntryResponse(
              success: false, status: 500, message: e.toString());
        }
      }
      return SaveQcEntryResponse(
          success: false, status: 500, message: 'Something went wrong');
    }
    return SaveQcEntryResponse(
        success: false, status: 500, message: 'No Internet');
  }

  ///Indent Module

  Future<IndentDropdownResponse> getIndentDropdownList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIndentDropdownList,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IndentDropdownResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIndentDropdownList parse error: $e');
          return IndentDropdownResponse(status: 500, message: e.toString());
        }
      }
      return IndentDropdownResponse(status: 500, message: 'Something went wrong');
    }
    return IndentDropdownResponse(status: 500, message: 'No Internet');
  }

  Future<IndentListResponse> getIndentList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIndentList,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IndentListResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIndentList parse error: $e');
          return IndentListResponse(status: 500, message: e.toString());
        }
      }
      return IndentListResponse(status: 500, message: 'Something went wrong');
    }
    return IndentListResponse(status: 500, message: 'No Internet');
  }

  Future<IndentDetailResponse> getIndentDetail(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIndentDetail,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IndentDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIndentDetail parse error: $e');
          return IndentDetailResponse(status: 500, message: e.toString());
        }
      }
      return IndentDetailResponse(status: 500, message: 'Something went wrong');
    }
    return IndentDetailResponse(status: 500, message: 'No Internet');
  }

  Future<IndentSubmitResponse> saveIndent(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.saveIndent,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IndentSubmitResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('saveIndent parse error: $e');
          return IndentSubmitResponse(status: 500, message: e.toString());
        }
      }
      return IndentSubmitResponse(status: 500, message: 'Something went wrong');
    }
    return IndentSubmitResponse(status: 500, message: 'No Internet');
  }

  Future<IndentItemStockResponse> getIndentItemStock({
    required int itemId,
    required int siteId,
    required int compId,
    required int branchId,
  }) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      final body = jsonEncode({
        'itemid': itemId,
        'siteid': siteId,
        'compid': compId,
        'branchid': branchId,
      });
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIndentItemStock,
        body: body,
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IndentItemStockResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIndentItemStock parse error: $e');
          return IndentItemStockResponse(status: 500, message: e.toString());
        }
      }
      return IndentItemStockResponse(status: 500, message: 'Something went wrong');
    }
    return IndentItemStockResponse(status: 500, message: 'No Internet');
  }

  /// Issue Item Module -----------------------------------------------------------

  Future<IssueItemDropdownResponse> getIssueItemDropdownList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIssueItemDropdown,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IssueItemDropdownResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIssueItemDropdownList parse error: $e');
          return IssueItemDropdownResponse(status: 500, message: e.toString());
        }
      }
      return IssueItemDropdownResponse(status: 500, message: 'Something went wrong');
    }
    return IssueItemDropdownResponse(status: 500, message: 'No Internet');
  }

  Future<IssueItemListResponse> getIssueItemList(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIssueItemList,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IssueItemListResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIssueItemList parse error: $e');
          return IssueItemListResponse(status: 500, message: e.toString());
        }
      }
      return IssueItemListResponse(status: 500, message: 'Something went wrong');
    }
    return IssueItemListResponse(status: 500, message: 'No Internet');
  }

  Future<IssueItemDetailResponse> getIssueItemDetail(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.getIssueItemDetail,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IssueItemDetailResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('getIssueItemDetail parse error: $e');
          return IssueItemDetailResponse(status: 500, message: e.toString());
        }
      }
      return IssueItemDetailResponse(status: 500, message: 'Something went wrong');
    }
    return IssueItemDetailResponse(status: 500, message: 'No Internet');
  }

  Future<IssueItemSubmitResponse> saveIssueItem(
      Map<String, dynamic> body) async {
    List<ConnectivityResult> connectivityResults =
    await connectivity.checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.wifi) ||
        connectivityResults.contains(ConnectivityResult.mobile)) {
      String res = await _apiClient.postMethodJson(
        method: _apiMethods.saveIssueItem,
        body: jsonEncode(body),
        header: {'Content-Type': 'application/json'},
      );
      if (res.isNotEmpty) {
        try {
          return IssueItemSubmitResponse.fromJson(jsonDecode(res));
        } catch (e) {
          if (kDebugMode) print('saveIssueItem parse error: $e');
          return IssueItemSubmitResponse(status: 500, message: e.toString());
        }
      }
      return IssueItemSubmitResponse(status: 500, message: 'Something went wrong');
    }
    return IssueItemSubmitResponse(status: 500, message: 'No Internet');
  }
}
