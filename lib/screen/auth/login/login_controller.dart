// // import 'package:newdigitalerp/app_routes/app_routes.dart';
// // 
// // import 'package:newdigitalerp/services/api_service/request_keys.dart';
// // import 'package:newdigitalerp/utils/show_message.dart';
// // import 'package:flutter/cupertino.dart';
// // import 'package:get/get.dart';
// // import '../../../change_company/branch_list_response.dart';
// // import '../../services/api_service/request_keys.dart';
// // import '../../utils/app_constant_new.dart';
// // import '../../utils/shared_pre.dart';
// // import 'login_model.dart';
// //
// // class LoginController extends AppBaseController {
// //   final TextEditingController mobileCtrl = TextEditingController();
// //   final TextEditingController passwordCtrl = TextEditingController();
// //   final FocusNode mobileFocus = FocusNode();
// //   final FocusNode passwordFocus = FocusNode();
// //   bool isShowPassword = true;
// //
// //   @override
// //   void onInit() {
// //     super.onInit();
// //
// //     // Safe cast — OTP screen passes List<String>, error args pass Map
// //     final args = Get.arguments;
// //     if (args is Map && args['error'] != null) {
// //       WidgetsBinding.instance.addPostFrameCallback((_) {
// //         ShowMessage.showSnackBar('Access Denied', args['error']);
// //       });
// //     }
// //   }
// //
// //   // Add this method inside LoginController class
// //   Future<void> _autoSelectFirstBranch() async {
// //     try {
// //       // Get the latest saved user data
// //       UserData? userData = await getLoginUserData();   // This is from your BaseController
// //
// //       if (userData == null) {
// //         debugPrint("UserData not found");
// //         return;
// //       }
// //
// //       // Prepare body for branch list API
// //       Map<String, String> body = {
// //         RequestKeys.compId: userData.compId?.toString() ?? '39',
// //         RequestKeys.userId: userData.userid?.toString() ?? '',
// //       };
// //
// //       // Call your branch list API
// //       BranchListResponse res = await api.getBranchList(body);
// //
// //       if (res.status == 200 &&
// //           res.data != null &&
// //           res.data!.isNotEmpty) {
// //
// //         // Filter out invalid branches (branchid = 0)
// //         final validBranches = res.data!.where((b) => b.branchid != 0).toList();
// //
// //         if (validBranches.isEmpty) {
// //           debugPrint("No valid branches found");
// //           return;
// //         }
// //
// //         // ✅ AUTO SELECT THE FIRST BRANCH
// //         final firstBranch = validBranches.first;
// //
// //         // Update userData with selected branch
// //         userData.branchId = firstBranch.branchid;
// //
// //         // Save updated userData back to SharedPreferences
// //         await SharedPre.setValue(SharedPre.userData, userData.toJson());
// //
// //         // Also save current branch separately (recommended)
// //         await SharedPre.setValue(SharedPre.currentBranchId, firstBranch.branchid.toString());
// //         await SharedPre.setValue(SharedPre.currentBranchName, firstBranch.branchname ?? "Default Branch");
// //
// //         debugPrint("✅ Auto-selected first branch: ${firstBranch.branchid} - ${firstBranch.branchname}");
// //
// //       } else {
// //         debugPrint("Branch list API failed: ${res.message}");
// //       }
// //     } catch (e) {
// //       debugPrint("Auto select first branch error: $e");
// //     }
// //   }
// //
// //   Future<void> clickOnLogin() async {
// //     mobileFocus.unfocus();
// //     passwordFocus.unfocus();
// //     String? deviceID = await getDeviceIdentifier();
// //     setBusy(true);
// //     try {
// //       if (_isValidate()) {
// //         Map<String, String> body = {};
// //         body[RequestKeys.mobile] = mobileCtrl.text.trim();
// //         body[RequestKeys.password] = passwordCtrl.text.trim();
// //         body[RequestKeys.deviceId] = deviceID ?? 'abcde874556';
// //         LoginResponse res = await api.loginApi(body);
// //
// //         if (res.status == 200 && res.data != null) {
// //           UserData? userData = res.data;
// //
// //           SharedPre.setValue(SharedPre.userData, userData?.toJson());
// //           SharedPre.setValue(SharedPre.isLogin, true);
// //
// //           if (userData?.mobileVerifyStatus == 0) {
// //             Get.toNamed(AppRoutes.otp, arguments: [
// //               mobileCtrl.text.trim(),
// //               passwordCtrl.text.trim()
// //             ]);
// //           } else if (userData?.profileStatus == 0) {
// //             Get.offAndToNamed(AppRoutes.setupProfile);
// //           } else {
// //             await _autoSelectFirstBranch();
// //
// //
// //             mobileCtrl.clear();
// //             passwordCtrl.clear();
// //             Get.offAndToNamed(AppRoutes.home);
// //           }
// //         }
// //         // else {
// //         //   // ✅ SHOW ACTUAL ERROR
// //         //   ShowMessage.showSnackBar(
// //         //     'Login Failed',
// //         //     res.message ?? 'Invalid credentials',
// //         //   );
// //         // }
// //         else {
// //           String msg = res.message ?? "";
// //
// //           if (msg.toLowerCase().contains("mobile")) {
// //             msg = "Invalid mobile number or password";
// //           }
// //
// //           ShowMessage.showSnackBar("Login Failed", msg);
// //         }
// //       }
// //     } catch (e) {
// //       ShowMessage.showSnackBar('Server Res', '$e');
// //     } finally {
// //       setBusy(false);
// //     }
// //     update();
// //   }
// //
// //   void tapOnShowPassword() {
// //     isShowPassword = !isShowPassword;
// //     update();
// //   }
// //
// //   bool _isValidate() {
// //     if (mobileCtrl.text.isEmpty) {
// //       ShowMessage.showSnackBar(
// //         AppString.requiredFieldTxt.tr,
// //         AppString.pleaseEnterMobileTxt.tr,
// //       );
// //       return false;
// //     }
// //     if (passwordCtrl.text.isEmpty) {
// //       ShowMessage.showSnackBar(
// //         AppString.requiredFieldTxt.tr,
// //         AppString.pleaseEnterPasswordTxt.tr,
// //       );
// //       return false;
// //     }
// //     return true;
// //   }
// //
// //   void tapOnForgotPassword() {
// //     mobileFocus.unfocus();
// //     passwordFocus.unfocus();
// //     Get.toNamed(AppRoutes.forgotPassword)?.then((value) {
// //       mobileCtrl.clear();
// //       passwordCtrl.clear();
// //       return null;
// //     });
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../app_routes/app_routes.dart';
//
// // ─── Dummy credentials for static testing ───────────────────────────────────
// const String _dummyMobile   = '9999999999';
// const String _dummyPassword = 'Test@1234';
// // ────────────────────────────────────────────────────────────────────────────
//
// class LoginController extends GetxController {
//   final TextEditingController mobileCtrl   = TextEditingController();
//   final TextEditingController passwordCtrl = TextEditingController();
//   final FocusNode mobileFocus   = FocusNode();
//   final FocusNode passwordFocus = FocusNode();
//
//   bool isShowPassword = true;
//   bool isBusy = false;
//
//   // ── Dummy user info (used by OTP screen / anywhere needing user data) ──────
//   final String dummyUserName   = 'Rahul Sharma';
//   final String dummyUserMobile = _dummyMobile;
//   final int    dummyOtp        = 123456; // shown on OTP screen for testing
//
//   @override
//   void onClose() {
//     mobileCtrl.dispose();
//     passwordCtrl.dispose();
//     mobileFocus.dispose();
//     passwordFocus.dispose();
//     super.onClose();
//   }
//
//   Future<void> clickOnLogin() async {
//     mobileFocus.unfocus();
//     passwordFocus.unfocus();
//
//     if (!_isValidate()) return;
//
//     _setBusy(true);
//
//     // Simulate network delay
//     await Future.delayed(const Duration(seconds: 1));
//
//     final mobile   = mobileCtrl.text.trim();
//     final password = passwordCtrl.text.trim();
//
//     if (mobile == _dummyMobile && password == _dummyPassword) {
//       // STATIC: skip OTP for now and go straight to home
//       // To test OTP flow: swap the line below with Get.toNamed(AppRoutes.otp)
//       Get.offAllNamed(AppRoutes.home);
//       // Uncomment to test OTP flow:
//       // Get.toNamed(AppRoutes.otp, arguments: [mobile, password]);
//     } else {
//       _showSnack('Login Failed', 'Invalid mobile number or password');
//     }
//
//     _setBusy(false);
//   }
//
//   void tapOnShowPassword() {
//     isShowPassword = !isShowPassword;
//     update();
//   }
//
//   void tapOnForgotPassword() {
//     mobileFocus.unfocus();
//     passwordFocus.unfocus();
//     Get.toNamed(AppRoutes.forgotPassword);
//   }
//
//   // ── Helpers ─────────────────────────────────────────────────────────────────
//
//   void _setBusy(bool value) {
//     isBusy = value;
//     update();
//   }
//
//   bool _isValidate() {
//     if (mobileCtrl.text.trim().isEmpty) {
//       _showSnack('Required', 'Please enter your mobile number');
//       return false;
//     }
//     if (passwordCtrl.text.trim().isEmpty) {
//       _showSnack('Required', 'Please enter your password');
//       return false;
//     }
//     return true;
//   }
//
//   void _showSnack(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: const Color(0xFF0F172A),
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(16),
//       borderRadius: 12,
//       duration: const Duration(seconds: 3),
//     );
//   }
// }
//
//


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/services/api_service/api.dart';
import 'package:newdigitalerp/utils/shared_pre.dart';

const String _dummyMobile   = '9999999999';
const String _dummyPassword = 'Test@1234';

/// Skip the OTP screen: `/api/Login` already returns the OTP (no SMS
/// provider), so the app verifies it itself and goes straight to the
/// dashboard. Flip to false to make users type the code again.
const bool kSkipOtp = true;

class LoginController extends GetxController {
  final TextEditingController mobileCtrl   = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final FocusNode mobileFocus   = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool isShowPassword = true;
  bool isBusy = false;

  @override
  void onClose() {
    mobileCtrl.dispose();
    passwordCtrl.dispose();
    mobileFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  Future<void> clickOnLogin() async {
    mobileFocus.unfocus();
    passwordFocus.unfocus();
    if (!_isValidate()) return;
    _setBusy(true);
    await Future.delayed(const Duration(seconds: 1));

    final mobile   = mobileCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    // Offline dummy bypass (kept for quick UI testing).
    if (mobile == _dummyMobile && password == _dummyPassword) {
      if (!Get.isRegistered<HomeController>()) Get.put(HomeController());
      Get.toNamed(AppRoutes.otp, arguments: [mobile, password]);
      _setBusy(false);
      return;
    }

    // Real login against the mobile API (/api/Login).
    try {
      final res = await Api().loginApi({
        'mobile': mobile,
        'password': password,
        'deviceid': 'flutter-app',
      });

      if (res.status == 200 && res.data != null) {
        final otp = res.data?.otp?.toString() ?? '';
        // There is no SMS provider — /api/Login hands the OTP straight back, so
        // the screen was only asking the user to retype what the app already
        // had. Verify it silently and land on the dashboard. Set [kSkipOtp]
        // false to bring the OTP screen back.
        if (kSkipOtp && otp.isNotEmpty && await _verifySilently(mobile, password, otp)) {
          return;
        }
        // Fallback (no OTP in the response, or verification failed): show the
        // screen so the user can type / resend it.
        Get.toNamed(AppRoutes.otp, arguments: [mobile, password, otp]);
      } else {
        _showSnack('Login Failed',
            (res.message?.isNotEmpty ?? false) ? res.message! : 'Invalid mobile number or password');
      }
    } catch (e) {
      _showSnack('Login Failed', '$e');
    } finally {
      _setBusy(false);
    }
  }

  /// Run the normal OTP verification in the background: it is the call that
  /// returns the full user record and creates the session, so the login path
  /// stays exactly as before — only the screen is skipped.
  /// Returns true when the user is on the dashboard.
  Future<bool> _verifySilently(
      String mobile, String password, String otp) async {
    try {
      final v = await Api().otpVerify({
        'mobileno': mobile,
        'password': password,
        'otp': otp,
      });
      if (v.status != 200 || v.data == null) return false;
      await SharedPre.setValue(SharedPre.userData, v.data!.toJson());
      await SharedPre.setValue(SharedPre.isLogin, true);
      final home = Get.isRegistered<HomeController>()
          ? Get.find<HomeController>()
          : Get.put(HomeController(), permanent: true);
      await home.loadUserData();
      Get.offAllNamed(AppRoutes.home);
      return true;
    } catch (_) {
      return false;
    }
  }

  void tapOnShowPassword() {
    isShowPassword = !isShowPassword;
    update();
  }

  void tapOnForgotPassword() {
    mobileFocus.unfocus();
    passwordFocus.unfocus();
    Get.toNamed(AppRoutes.forgotPassword);
  }

  void _setBusy(bool value) {
    isBusy = value;
    update();
  }

  bool _isValidate() {
    if (mobileCtrl.text.trim().isEmpty) {
      _showSnack('Required', 'Please enter your mobile, email or username');
      return false;
    }
    if (passwordCtrl.text.trim().isEmpty) {
      _showSnack('Required', 'Please enter your password');
      return false;
    }
    return true;
  }

  void _showSnack(String title, String message) {
    Get.snackbar(title, message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3));
  }
}
