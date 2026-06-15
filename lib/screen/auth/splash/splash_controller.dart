import 'dart:async';
import 'package:get/get.dart';
import '../../../app_routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _runTimer();
  }

  void _runTimer() {
    Timer(const Duration(seconds: 2), () {
      // STATIC: Always go to login
      Get.offAllNamed(AppRoutes.login);
    });
  }
}