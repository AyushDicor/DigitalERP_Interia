// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:get/get.dart';
//
// import '../../app_routes/app_routes.dart';
// import '../../services/api_service/request_keys.dart';
// import '../../utils/shared_pre.dart';
// import '../../utils/show_message.dart';
// import '../login/login_controller.dart';
// import '../login/login_model.dart';
//
// class OtpController extends AppBaseController {
//   final LoginController loginController = Get.find<LoginController>();
//   int secondsRemaining = 59;
//   bool enableResend = false;
//   Timer? timer;
//
//   final TextEditingController otpController = TextEditingController();
//
//   bool isOneMinuteDone = false;
//   UserData? userData;
//
//   @override
//   void onInit() {
//     // TODO: implement onInit
//     getUserData();
//     timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (secondsRemaining != 0) {
//         secondsRemaining--;
//         update();
//       } else {
//         enableResend = true;
//         update();
//       }
//     });
//     super.onInit();
//   }
//
//   void getUserData() async {
//     var obj = SharedPre.getObjs(SharedPre.userData) ?? {};
//     userData = UserData.fromJson(obj);
//   }
//
//   void resendCode() async {
//     secondsRemaining = 59;
//     enableResend = false;
//     update();
//     await loginController.clickOnLogin();
//     getUserData();
//   }
//
//   String addZero() {
//     if (secondsRemaining < 10) {
//       return '0';
//     }
//     return '';
//   }
//
//   void tapOnVerify(String password) async {
//     if (!_validate()) return;
//
//     setBusy(true);
//     try {
//       await otpVerifyAPI(password);
//     } catch (e) {
//       final msg = e.toString();
//
//       if (msg.contains('incorrect_otp')) {
//         ShowMessage.showSnackBar(
//             'Wrong OTP', 'The OTP you entered is incorrect. Please try again.');
//       } else if (msg.contains('otp_expired')) {
//         ShowMessage.showSnackBar(
//             'OTP Expired', 'Your OTP has expired. Please request a new one.');
//       } else if (msg.contains('too_many_attempts')) {
//         ShowMessage.showSnackBar('Too Many Attempts',
//             'Max attempts reached. Please request a new OTP.');
//       } else {
//         ShowMessage.showSnackBar(
//             'Failed', 'Something went wrong. Please try again.');
//       }
//     } finally {
//       setBusy(false);
//     }
//   }
//
//   Future<void> otpVerifyAPI(String pass) async {
//     try {
//       Map<String, String> body = {};
//       body[RequestKeys.mobileNo] = userData?.mobile.toString() ?? '';
//       body[RequestKeys.password] = pass;
//       body[RequestKeys.otp] = otpController.value.text;
//
//       OtpVerifyResponse res = await api.otpVerify(body);
//
//       if (res.success == true) {
//         // ✅ Success
//         loginController.mobileCtrl.clear();
//         loginController.passwordCtrl.clear();
//
//         UserData? otpUserData = res.data;
//
//         //  Preserve branchId from login if OTP response returns 0
//         if ((otpUserData?.branchId ?? 0) == 0 &&
//             (userData?.branchId ?? 0) != 0) {
//           otpUserData?.branchId = userData!.branchId;
//         }
//
//         SharedPre.setValue(SharedPre.userData, otpUserData?.toJson());
//
//         if (otpUserData?.profileStatus == 0) {
//           Get.offAndToNamed(AppRoutes.setupProfile);
//         } else {
//           Get.offAndToNamed(AppRoutes.home);
//         }
//       } else {
//         throw Exception('incorrect_otp');
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }
//
//   bool _validate() {
//     if (otpController.value.text.isEmpty) {
//       ShowMessage.showSnackBar(
//           'Field Empty', 'Please enter the OTP sent to your mobile.');
//       return false;
//     }
//     if (otpController.value.text.length < 6) {
//       ShowMessage.showSnackBar(
//           'Invalid OTP', 'OTP must be 6 digits. Please check and try again.');
//       return false;
//     }
//     if (!RegExp(r'^\d+$').hasMatch(otpController.value.text)) {
//       ShowMessage.showSnackBar(
//           'Invalid Input', 'OTP should contain numbers only.');
//       return false;
//     }
//     return true;
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app_routes/app_routes.dart';

// ── Dummy OTP for static testing ─────────────────────────────────────────────
const int _dummyOtp = 123456;
// ─────────────────────────────────────────────────────────────────────────────

class OtpController extends GetxController {
  final TextEditingController otpController = TextEditingController();

  int secondsRemaining = 59;
  bool enableResend = false;
  bool isBusy = false;

  // Exposed so the OTP view can show it as a hint during static testing
  final int dummyOtpHint = _dummyOtp;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  @override
  void onClose() {
    if (otpController.hasListeners) {  // or use a disposed flag
      otpController.dispose();
    }
    super.onClose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsRemaining > 0) {
        secondsRemaining--;
        update();
      } else {
        enableResend = true;
        update();
      }
    });
  }

  void resendCode() {
    secondsRemaining = 59;
    enableResend = false;
    otpController.clear();
    update();
    _startTimer();
    _showSnack('OTP Resent', 'Use the test OTP: $_dummyOtp');
  }

  String addZero() => secondsRemaining < 10 ? '0' : '';

  Future<void> tapOnVerify(String password) async {
    if (!_validate()) return;

    _setBusy(true);
    await Future.delayed(const Duration(milliseconds: 800));

    final entered = int.tryParse(otpController.text.trim()) ?? 0;

    if (entered == _dummyOtp) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      _showSnack('Wrong OTP', 'The OTP you entered is incorrect. Try $_dummyOtp');
    }

    _setBusy(false);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _setBusy(bool value) {
    isBusy = value;
    update();
  }

  bool _validate() {
    final text = otpController.text.trim();
    if (text.isEmpty) {
      _showSnack('Field Empty', 'Please enter the OTP sent to your mobile.');
      return false;
    }
    if (text.length < 6) {
      _showSnack('Invalid OTP', 'OTP must be 6 digits.');
      return false;
    }
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      _showSnack('Invalid Input', 'OTP should contain numbers only.');
      return false;
    }
    return true;
  }

  void _showSnack(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0F172A),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}