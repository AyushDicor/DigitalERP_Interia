
import 'package:get/get.dart';
import 'package:newdigitalerp/auth/login/login_controller.dart';
import 'package:newdigitalerp/auth/login/login_screen.dart';


class AppDependencies {
  static Future<void> init() async {
    Get.lazyPut(() => const LoginView());
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);


    // Get.create(() => const ProductDetailsView());
    // Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
    // Get.lazyPut<LeaveHistoryController>(() => LeaveHistoryController(), fenix: true);
    // Get.lazyPut<SelectCategoryController>(() => SelectCategoryController(), fenix: true);


/*    Get.put(const DashboardView(), permanent: true);
    Get.put(const AttendanceView(), permanent: true);
    Get.put(const ExecutiveListView(), permanent: true);
    Get.put(const OrderView(), permanent: true);
    Get.put(const VisitPlanView(), permanent: true);
    Get.put(const CustomerListView(), permanent: true);
    Get.put(const ImageView(), permanent: true);
    Get.put(const AccountModuleView(), permanent: true);*/
  }
}
