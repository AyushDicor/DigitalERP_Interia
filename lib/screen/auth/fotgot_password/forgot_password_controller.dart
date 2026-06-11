
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/auth/base/base_contoller.dart';
import 'package:newdigitalerp/response/forgot_pass_response.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class ForgotPasswordController extends AppBaseController {
  final TextEditingController mobileCtrl = TextEditingController();
  final FocusNode mobileFocus = FocusNode();
  ForgotPassResData? responseData;

  Future<void> clickOnSendOtp() async {
    mobileFocus.unfocus();
    setBusy(true);
    try {
      if (_isValidate()) {
        Map<String, String> body = {};
        body[RequestKeys.mobileNo] = mobileCtrl.text.trim();
        var res = await api.forgotPasswordAPI(body);
        if (res.status == 200) {
          responseData = res.data;
          Get.toNamed(AppRoutes.forgotPassOtp)?.then((value) => mobileCtrl.clear());
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

  bool _isValidate() {
    if (mobileCtrl.text.isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterMobileTxt.tr,
      );
      return false;
    }
    return true;
  }
}
