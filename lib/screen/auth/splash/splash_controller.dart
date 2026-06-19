import 'dart:async';
import 'package:get/get.dart';
import '../../../app_routes/app_routes.dart';
import '../../../utils/shared_pre.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _runTimer();
  }

  void _runTimer() {
    Timer(const Duration(seconds: 2), () {
      // Keep the user logged in across app restarts: if a valid session was
      // saved at login, go straight to Home; otherwise show Login.
      final saved = SharedPre.getObjs(SharedPre.userData);
      final hasSession = saved != null &&
          saved.isNotEmpty &&
          saved['userid'] != null &&
          saved['compid'] != null &&
          saved['branchId'] != null;

      Get.offAllNamed(hasSession ? AppRoutes.home : AppRoutes.login);
    });
  }
}
