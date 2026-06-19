import 'dart:convert';


import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/shared_pre.dart';
import 'package:newdigitalerp/utils/show_message.dart';

class ProfileController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();
  final TextEditingController userTypeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final FocusNode userTypeFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode addressFocus = FocusNode();
  final picker = ImagePicker();
  var selectedImage = ''.obs;
  var selectedImageBase64 = ''.obs;
  var selectedImageFileName = ''.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    init();
    super.onInit();
  }

  init() async {
    nameController.text = homeController.currentUserData!.name.toString();
    emailController.text = homeController.currentUserData!.email.toString();
    addressController.text = homeController.currentUserData!.address.toString();
    userTypeController.text = homeController.currentUserData!.usertype.toString();
    update();
  }

  void setSelectedImage(String value) {
    selectedImage.value = value;
    update();
  }

  void tapOnEditProfile() {
    nameFocus.unfocus();
    emailFocus.unfocus();
    addressFocus.unfocus();
    updateProfile();
  }

  bool _isValidate() {
    if (nameController.text.isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterNameTxt.tr,
      );
      return false;
    }
    if (emailController.text.isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterEmailTxt.tr,
      );
      return false;
    }
    if (!emailController.text.isEmail) {
      ShowMessage.showSnackBar(
        AppString.pleaseCheckTxt.tr,
        AppString.pleaseEnterValidEmailTxt.tr,
      );
      return false;
    }
    if (emailController.text.isHaveEmoji) {
      ShowMessage.showSnackBar(
        AppString.pleaseCheckTxt.tr,
        AppString.pleaseEnterValidEmailTxt.tr,
      );
      return false;
    }
    if (addressController.text.isEmpty) {
      ShowMessage.showSnackBar(
        AppString.requiredFieldTxt.tr,
        AppString.pleaseEnterAddress.tr,
      );
      return false;
    }
    if (addressController.text.isHaveEmoji) {
      ShowMessage.showSnackBar(
        AppString.pleaseCheckTxt.tr,
        AppString.pleaseEnterValidAddressTxt.tr,
      );
      return false;
    }
    return true;
  }

  void updateProfile() async {
    setBusy(true);
    try {
      if (_isValidate()) {
        Map<String, String> body = {};
        body[RequestKeys.userId] = homeController.currentUserData!.userid.toString();
        body[RequestKeys.compId] = homeController.currentUserData!.compId.toString();
        // Preserve current branch & financial year (profile update must not reset them).
        body[RequestKeys.branchId] = homeController.currentUserData!.branchId.toString();
        body[RequestKeys.yearId] = homeController.currentUserData!.yearId.toString();
        body[RequestKeys.name] = nameController.text.trim();
        body[RequestKeys.email] = emailController.text.trim();
        body[RequestKeys.address] = addressController.text.trim();
        body[RequestKeys.photo] = selectedImageBase64.value;
        body[RequestKeys.filename] = selectedImageFileName.value;
        var res = await api.updateProfileJson(json.encode(body));
        // var res = await api.updateProfile(body);
        if (res.status == 200) {
          // backTap();
          ShowMessage.showSnackBar('Success Server Res', res.message.toString());
          SharedPre.setValue(SharedPre.userData, res.data?.toJson());
          homeController.currentUserData = await userDataController.getUserData;
        } else {
          ShowMessage.showSnackBar('Failed Server Res', res.message.toString());
        }
      }
    } catch (e) {
      ShowMessage.showSnackBar('', '$e');
    } finally {
      setBusy(false);
    }
  }
}
