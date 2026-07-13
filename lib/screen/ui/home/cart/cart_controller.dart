import 'dart:convert';

import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/response/get_cart_list_response.dart';

import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/offline_cart_list.dart';
import 'package:newdigitalerp/utils/shared_pre.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../response/login_response.dart';
import '../../../base/base_controller.dart';
class CartController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  final quantityTextController = TextEditingController();
  final quantityTextFocus = FocusNode();

  UserData? currentUserData;
  List<GetCartListData> cartList = [];
  List<GetCartListData> cartDeletedListItem = [];
  int? flag;
  // Offline cart cache. MUST be initialized (not `late final`): getOfflineList()
  // only assigns it when the cache is non-empty, so a `late` field would throw a
  // LateInitializationError in tapOnDelete when the cache is empty — which silently
  // aborted the delete before the server call ever ran (item could never be removed).
  List list = [];

  init() async {
    // TODO: implement onInit
    var obj = SharedPre.getObjs(SharedPre.userData) ?? {};
    currentUserData = UserData.fromJson(obj);
    getDetails();
    getOfflineList();

  }
  @override
  void onInit() {
    // TODO: implement onInit
    init();
    super.onInit();
  }

  void tapOnDelete(int index) async {
    var item = cartList[index];
    // Best-effort offline-cache cleanup — must never block the server removal.
    try {
      list.removeWhere((element) => element.itemId == cartList[index].productid);
      await SharedPre.setValue(SharedPre.offlineCartList, json.encode(list));
    } catch (_) {/* offline cache empty/out of sync — ignore and remove server-side */}
    //cartDeletedListItem.add(item); /// using for manage product list cart color on back tap
    bool deleted = await removeFromCartAPI(itemId: item.id.toString());
    if (deleted) {
      cartList.removeAt(index);
      if(cartList.isEmpty){
        await SharedPre.clear(SharedPre.offlineCartList);
      }
      homeController.itemInCart.value = homeController.itemInCart.value-1 ;
      getDetails();
      update();
    }
  }

  void tapOnProcess() {
    if (cartList.isNotEmpty) {
      Get.toNamed(AppRoutes.yourOrder);
    } else {
      ShowMessage.showSnackBar('', 'Cart List is Empty');
      backTap();
    }
  }

  void getOfflineList() async{
    var list1 = await SharedPre.getStringValue(SharedPre.offlineCartList);
    if(list1.isNotEmpty) {
      var obj1 = json.decode(list1);
      list = obj1.map((model) => OfflineCart.fromJson(model)).toList();
    }
  }

  void tapOnProduct(String itemId) {
    Get.toNamed(AppRoutes.productDetails, arguments: itemId,);
  }

  void tapOnQuantityText(int index){
    for(var element in cartList){
      element.isTextField = false;
    }

    cartList[index].isTextField = true ;
    quantityTextController.clear();
    update();
  }

  void productQtyDecrease(int index) {
    cartList[index].quantity = (cartList[index].quantity?.toInt() ?? 0) - 1;
    cartListLength = cartListLength! - 1;

    var item = cartList[index];
    flag = 0;
    updateCartAPI(item.id.toString(), cartList[index].quantity.toString());
    update();
  }

  void productQtyDecreaseFromTextField(int index) {
    //cartList[index].quantity = int.parse(quantityTextController.text) - 1;
    quantityTextController.text = (double.parse(quantityTextController.text) - 1).toString();
    var item = cartList[index];
    flag = 0;
    /*updateCartAPI(item.id.toString(), cartList[index].quantity.toString());

    update();*/
    update();
  }


  void productQtyIncrease(int index) {
    cartList[index].quantity = (cartList[index].quantity?.toInt() ?? 0) + 1;
    cartListLength = cartListLength! + 1;
    var item = cartList[index];
    flag = 1;
    updateCartAPI(item.id.toString(), cartList[index].quantity.toString());
    update();
  }

  void productQtyIncreaseFromTextField(int index) {
   // cartList[index].quantity = int.parse(quantityTextController.text) + 1;
    quantityTextController.text = (double.parse(quantityTextController.text) + 1).toString();
    var item = cartList[index];
    flag = 1;
    /*updateCartAPI(item.id.toString(), cartList[index].quantity.toString());
    update();*/
    update();
  }

 void onSubmitTextFieldQty(String qty, int index){
if(quantityTextController.text.isNotEmpty && double.parse(quantityTextController.text) > 0){
  //cartList[index].quantity = int.parse(qty);
  var item = cartList[index];
  updateCartAPI(item.id.toString(), qty);
}else{
  ShowMessage.showSnackBar('MSG', 'QUANTITY MUST BE GRATER THEN 0');
}

 }


  Future<bool> updateCartAPI(String id, String qty) async {
    // UserData? currentUserData = await userDataController.getUserData;
    try {
      Map<String, String> body = {};
      body[RequestKeys.userId] = currentUserData?.userid?.toString() ?? '';
      body[RequestKeys.compId] = currentUserData?.compId?.toString() ?? '';
      body[RequestKeys.id] = id;
      body[RequestKeys.quantity] = qty;

      var res = await api.updateCart(body);
      if (res.status == 200) {
        ShowMessage.showSnackBar('', res.message.toString());

        getDetails();
        update();
        return true;
      } else {
        ShowMessage.showSnackBar('', '${res.message}');
        return false;
      }
    } catch (e) {
      ShowMessage.showSnackBar('', '$e');
      return false;
    } finally {}
  }

  Future<void> getDetails() async {
    setBusy(true);
    try {
      Map<String, String> body = {};
      body[RequestKeys.compId] = currentUserData!.compId.toString();
      body[RequestKeys.userId] = currentUserData!.userid.toString();
      var res = await api.getCartList(body);
      if (res.status == 200) {
        cartList = res.data ?? [];
        cartListLength = cartList.length;
        SharedPre.setValue(SharedPre.cartListLength, cartListLength);
      } else {
        ShowMessage.showSnackBar('Server Res', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }
}
