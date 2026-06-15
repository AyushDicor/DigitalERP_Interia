import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/response/executive_order_list_response.dart';
import 'package:newdigitalerp/response/visit_plan_detail_data_response.dart';
import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/screen/ui/home/visit_plan/visit_plan_detail/visit_plan_detail_controller.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:get/get.dart';

import '../../../../../home/home_contoller.dart';

class OrderListController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();
  VisitPlanDetailController visitPlanDetailController = Get.find<VisitPlanDetailController>();

  List<ExecutiveOrderData>? executiveOrderList = [];
  VisitPlanDetailsDataList? argument;
  int selectedSegmentVal = 0;

  @override
  void onInit() {
    // TODO: implement onInit
    argument = Get.arguments;
    getOrderList();
    super.onInit();
  }

  setSegmentValue(int i) {
    print('______________${selectedSegmentVal}_________');
    print('______________${i}_________');
    selectedSegmentVal = i;
    String status;
    if (i == 0) {
      status = 'Pending';
    } else if (i == 1) {
      status = 'Approved';
    } else {
      status = 'Rejected';
    }
    getOrderList(status: status);
    update();
  }

  void tapOnApply() {}

  void tapOnLeaveHistory() {}

  void tapOnAdd() {
    Get.toNamed(AppRoutes.selectBrand);

    // Get.toNamed(AppRoutes.selectCategory);
  }

  void tapOnCard(String orderId) {
    Get.toNamed(AppRoutes.orderDetail, arguments: orderId);
  }

  Future<void> getOrderList({String? status}) async {
    //isListLoading = true;
    //update();
    isBusy = true;
    executiveOrderList?.clear();

    /*var customer = await SharedPre.getStringValue(SharedPre.selectedCustomer);
    if(customer.isNotEmpty){
      decodedMap = CustomerListData.fromJson(json.decode(customer));}*/
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = homeController.currentUserData?.userid.toString() ?? '';
      body[RequestKeys.fromDate] = getStartDateOfMonth(DateTime.now());
      body[RequestKeys.toDate] = /*todate ??*/
          formatDate(DateTime.now().toString(), AppString.dateTimeFormat, AppString.yyyyMMdd);
      body[RequestKeys.partyId] = argument?.partyid.toString() ?? '123';
      body[RequestKeys.Executiveid] = homeController.currentUserData?.accountCode.toString() ?? '139841';
      body[RequestKeys.status] = status ?? 'Pending';
      body [RequestKeys.branchId] = homeController.currentUserData?.branchId.toString()??'';
      var res = await api.getExecutiveOrderList(body);
      if (res.status == 200) {
        body[RequestKeys.compId] = homeController.currentUserData?.compId.toString() ?? '';
        executiveOrderList?.addAll(res.data ?? []);
        //executiveList.reversed;
      } else {
        // ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('catch Server Res', '$e');
    } finally {
      isBusy = false;
      update();
    }
  }
}
