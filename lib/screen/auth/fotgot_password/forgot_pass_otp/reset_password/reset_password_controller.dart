
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/auth/base/base_contoller.dart';
import 'package:newdigitalerp/auth/fotgot_password/forgot_pass_otp/forgot_pass_otp_controller.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class ResetPasswordController extends AppBaseController {
  final ForgotPassOtpController forgotPassOtpController = Get.find<ForgotPassOtpController>();
  final TextEditingController confirmPasswordCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();
  bool isShowPassword = true;

  Future<void> clickOResetPassword() async {
    passwordFocus.unfocus();
    confirmPasswordFocus.unfocus();
    setBusy(true);
    try {
      if (_isValidate()) {
        Map<String, String> body = {};
        body[RequestKeys.userId] = forgotPassOtpController.responseData.toString();
        body[RequestKeys.newPassword] = confirmPasswordCtrl.text.trim();
        var res = await api.resetPassword(body);
        if (res.status == 200) {
          Get.offAllNamed(AppRoutes.login);
          ShowMessage.showSnackBar('success', res.message.toString());
        } else {
          ShowMessage.showSnackBar('Server Res', res.message.toString());
        }
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  void tapOnShowPassword() {
    isShowPassword = !isShowPassword;
    update();
  }

  bool _isValidate() {
    if (passwordCtrl.text.isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterPasswordTxt.tr,
      );
      return false;
    }
    if (passwordCtrl.text.toString() != confirmPasswordCtrl.text.toString()) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.passAnConPassNotMatchTxt.tr,
      );
      return false;
    }
    return true;
  }
}
