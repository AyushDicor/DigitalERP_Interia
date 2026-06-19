import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/order_report_response.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class SalesReportController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  List<OrderReportItem> orders = [];
  OrderReportSummary summary = OrderReportSummary();

  // Default range: first day of current month -> today.
  late DateTime fromDate;
  late DateTime toDate;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = now;
    loadReport();
  }

  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  void setFromDate(DateTime d) {
    fromDate = d;
    update();
  }

  void setToDate(DateTime d) {
    toDate = d;
    update();
  }

  Future<void> loadReport() async {
    setBusy(true);
    try {
      final body = <String, String>{
        'compid': homeController.currentUserData?.compId.toString() ?? '',
        'branchid': homeController.currentUserData?.branchId.toString() ?? '',
        'executiveid': '0',
        'fromdate': fmt(fromDate),
        'todate': fmt(toDate),
      };
      final res = await api.getSalesOrderReport(body);
      if (res.status == 200 && res.data != null) {
        orders = res.data!.data;
        summary = res.data!.summary;
      } else {
        orders = [];
        summary = OrderReportSummary();
      }
    } catch (e) {
      ShowMessage.showSnackBar('Sales Report', '$e');
      orders = [];
      summary = OrderReportSummary();
    } finally {
      setBusy(false);
      update();
    }
  }
}
