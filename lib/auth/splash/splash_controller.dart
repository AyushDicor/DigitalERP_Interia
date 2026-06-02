// import 'dart:async';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// import '../../app_routes/app_routes.dart';
// import '../../utils/shared_pre.dart';
// import '../login/login_model.dart';
//
// class SplashController extends AppBaseController {
//   @override
//   void onReady() {
//     super.onReady();
//     _runTimer();
//   }
//
//   void _runTimer() async {
//     Timer(
//       const Duration(seconds: 2),
//           () async {
//         final isLogin = await SharedPre.getBoolValue(SharedPre.isLogin);
//         if (isLogin) {
//           final obj = SharedPre.getObjs(SharedPre.userData) ?? {};
//           if (obj.isEmpty) {
//             Get.offAllNamed(AppRoutes.login);
//             return;
//           }
//           UserData userdata = UserData.fromJson(obj);
//           if (userdata.mobileVerifyStatus == 0) {
//             Get.offAllNamed(AppRoutes.login);
//           } else {
//             Get.offAllNamed(AppRoutes.home);
//           }
//         } else {
//           Get.offAllNamed(AppRoutes.login);
//         }
//       },
//     );
//   }
// }

import 'dart:async';
import 'package:get/get.dart';
import '../../app_routes/app_routes.dart';

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