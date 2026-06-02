// import 'dart:async';
// // import 'package:digitalerp/home_view_new.dart';
// // import 'package:digitalerp/homeview_new_controller.dart';
// // import 'package:digitalerp/payment_request/payment_request_controller.dart';
// // import 'package:digitalerp/response/bottom_tab_item.dart';
// // import 'package:digitalerp/response/cart_count_response.dart';
// // import 'package:digitalerp/response/login_response.dart';
// // import 'package:digitalerp/response/token_update_response.dart';
// // import 'package:digitalerp/screen/base/base_controller.dart';
// // import 'package:digitalerp/screen/ui/graph/all_graph_screen.dart';
// // import 'package:digitalerp/screen/ui/home/attendance/attendance_view.dart';
// // import 'package:digitalerp/screen/ui/home/dashboard/dashboard_view.dart';
// // import 'package:digitalerp/screen/ui/home/executive_list/executive_list_view.dart';
// // import 'package:digitalerp/screen/ui/home/order/order_view.dart';
// // import 'package:digitalerp/screen/ui/home/visit_plan/visit_plan_view.dart';
// // import 'package:digitalerp/services/api_service/request_keys.dart';
// // import 'package:digitalerp/utils/app_constant.dart';
// // import 'package:digitalerp/utils/shared_pre.dart';
// // import 'package:digitalerp/utils/show_message.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:newdigitalerp/app_routes/app_routes.dart';
// import 'package:newdigitalerp/auth/base/base_contoller.dart';
// import 'package:newdigitalerp/auth/login/login_model.dart';
// import 'package:newdigitalerp/homeview_new_controller.dart';
// import 'package:newdigitalerp/response/bottom_tab_item.dart';
// import 'package:newdigitalerp/response/token_update_response.dart';
// import 'package:newdigitalerp/services/api_service/request_keys.dart';
// import 'package:newdigitalerp/utils/shared_pre.dart';
// import 'package:newdigitalerp/utils/show_message.dart';
// import 'package:upgrader/upgrader.dart';
//
//
// class HomeController extends AppBaseController {
//   BottomTabItem? selectedTab;
//   int selectedTabV = 0;
//   int selectedTabI = 0;
//   UserData? currentUserData = UserData();
//   List<BottomTabItem> bottomList = [];
//   List<Position> userPositionsList = [];
//   bool isLocationSend = false;
//   int currentYear = 0;
//   bool? isCustomer;
//   String? name;
//   RxInt itemInCart = 0.obs;
//   RxInt unApprovalCount = 0.obs;
//   static StreamController<String> counterController =
//   StreamController<String>.broadcast();
//   static String cartCount = '';
//
//   void setLocationSending(bool value) {
//     isLocationSend = value;
//     update();
//   }
//
//   @override
//   void onInit() async {
//     // ✅ LOAD USER DATA WITH BRANCH ID
//     await loadUserData();
//
//     isCustomer = currentUserData?.usertype == 'Customer';
//     name = currentUserData?.name.toString();
//     scaffoldKey = GlobalKey<ScaffoldState>();
//
//     // Register synchronously FIRST so GetBuilder can find it immediately
//     final menuCtrl = Get.put<HomeViewNewController>(HomeViewNewController());
//
//     int index = 0;
//     onItemTapped(index);
//     update(); // ← trigger HomeView to build with shimmer showing
//
//     // NOW fetch async in background — shimmer shows while this runs
//     menuCtrl.getNewMenuList(0);
//     menuCtrl.getUnApprovalCount();
//
//     sendLocations();
//     String? token = await FirebaseMessaging.instance.getToken();
//     updateToken(token);
//    // Get.put<PaymentRequestController>(PaymentRequestController());
//
//     super.onInit();
//   }
//
//   // ✅ NEW: Load user data from SharedPreferences
//   Future<void> loadUserData() async {
//     try {
//       final obj = SharedPre.getObjs(SharedPre.userData); // no await needed, it's sync
//
//       if (obj == null || obj.isEmpty) {
//         debugPrint("⚠️ No user data found — redirecting to login");
//         Get.offAllNamed(AppRoutes.login);
//         return;
//       }
//
//       currentUserData = UserData.fromJson(obj);
//
//       debugPrint("📱 HomeController - User Data Loaded:");
//       debugPrint("   User ID: ${currentUserData?.userid}");
//       debugPrint("   Company ID: ${currentUserData?.compId}");
//       debugPrint("   Branch ID: ${currentUserData?.branchId}");
//       debugPrint("   Name: ${currentUserData?.name}");
//
//       // Corrupt saved data — force re-login
//       if ((currentUserData?.branchId ?? 0) == 0) {
//         debugPrint("⚠️ branchId is 0 — clearing bad data, redirecting to login");
//         await SharedPre.clear(SharedPre.userData);
//         Get.offAllNamed(AppRoutes.login);
//         return;
//       }
//
//       update();
//     } catch (e) {
//       debugPrint("❌ Error loading user data: $e");
//       Get.offAllNamed(AppRoutes.login);
//     }
//   }
//
//   // ✅ NEW: Refresh user data (call this after login or branch change)
//   Future<void> refreshUserData() async {
//     debugPrint("🔄 Refreshing user data...");
//     await loadUserData();
//   }
//
//   void menulist() {
//     Get.find<HomeViewNewController>().getNewMenuList(0);
//     Get.put<HomeViewNewController>(HomeViewNewController())
//         .getUnApprovalCount();
//   }
//
//   // Future<void> getCartCount() async {
//   //   try {
//   //     Map<String, String> body = {};
//   //     body[RequestKeys.userId] = currentUserData?.userid.toString() ?? '';
//   //     body[RequestKeys.compId] = currentUserData?.compId.toString() ?? '';
//   //
//   //     // ✅ DEBUG: Print request body
//   //     debugPrint("🛒 Getting cart count with: $body");
//   //
//   //     CartCountResponse res = await api.getCartCount(body);
//   //     if (res.status == 200) {
//   //       itemInCart.value = res.data?.first.totalcartcount?.toInt() ?? 0;
//   //     } else {
//   //       ShowMessage.showSnackBar(
//   //           'getCartCount res.status not 200', res.message.toString());
//   //     }
//   //   } catch (e) {
//   //     ShowMessage.showSnackBar('getCartCount Catch', '$e');
//   //   }
//   // }
//
//   void onItemTapped(int index) {
//     selectedTabI = index;
//     selectedTabV = index;
//     update();
//   }
//
//   void collectLocations() {
//     Timer.periodic(
//       const Duration(seconds: 5),
//           (timer) async {
//         if (kDebugMode) {
//           print('-----${DateTime.now()}---');
//           var pos = await getUserCurrentPosition();
//           userPositionsList.add(pos);
//         }
//       },
//     );
//   }
//
//   void sendLocations() {
//     Timer.periodic(
//       const Duration(minutes: 15),
//           (timer) async {
//         if (await SharedPre.getBoolValue(SharedPre.isLocationSend)) {
//           saveLocationAPI();
//           debugPrint("-------------locationSent---------");
//         } else {
//           debugPrint("-------------locationNotSent---------");
//         }
//       },
//     );
//   }
//
//   Future<void> saveLocationAPI() async {
//     Position currentPosition = await getUserCurrentPosition();
//     String currentAddress = await getUserCurrentAddress();
//     String battery = await getBatteryPercent();
//     String? deviceID = await getDeviceIdentifier();
//     try {
//       Map<String, String> body = {};
//       body[RequestKeys.compId] = currentUserData?.compId.toString() ?? '';
//       body[RequestKeys.branchId] = currentUserData?.branchId.toString() ?? '';
//       body[RequestKeys.userId] = currentUserData?.userid.toString() ?? '';
//       body[RequestKeys.yearId] = currentUserData?.yearId.toString() ?? '';
//       body[RequestKeys.latitude] = currentPosition.latitude.toString();
//       body[RequestKeys.longitude] = currentPosition.longitude.toString();
//       body[RequestKeys.location] = currentAddress;
//       body[RequestKeys.deviceId] = deviceID ?? '';
//       body[RequestKeys.batteryLevel] = '$battery %';
//
//       // ✅ DEBUG: Print location request
//       debugPrint("📍 Saving location with branchId: ${body[RequestKeys.branchId]}");
//
//       var res = await api.saveLocationRoute(body);
//       if (res.status != 200) {
//         ShowMessage.showSnackBar(
//             'saveLocationRoute  res.status not 200', res.message.toString());
//       }
//     } catch (e) {
//       ShowMessage.showSnackBar('saveLocationRoute catch', '$e');
//     } finally {}
//   }
//
//   Future<void> updateToken(String? token) async {
//     try {
//       Map<String, String> body = {};
//       body[RequestKeys.compId] = currentUserData!.compId.toString();
//       body[RequestKeys.userId] = currentUserData!.userid.toString();
//       body[RequestKeys.token] = token ?? 'abcde874556';
//       TokenUpdateResponse res = await api.tokenUpdate(body);
//       if (res.status == 200) {
//         print('======Token Updated Successfully=====');
//       } else {
//         ShowMessage.showSnackBar(
//             'tokenUpdate res.status not 200', res.message.toString());
//       }
//     } catch (e) {
//       ShowMessage.showSnackBar('tokenUpdate catch', '$e');
//     }
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/auth/base/base_contoller.dart';
import 'package:newdigitalerp/auth/login/login_model.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/response/bottom_tab_item.dart';
import 'package:geolocator/geolocator.dart';

// ── Static dummy user — no API, no SharedPreferences needed ──────────────────
UserData _dummyUser() => UserData.fromJson({
  'userid': 1,
  'name': 'Rahul Sharma',
  'usertype': 'Manager',
  'compid': 39,
  'branchid': 1,
  'yearid': '2024-2025',
  'accountcode': 101,
  'mobile': '9999999999',
  'photo': '',
});
// ─────────────────────────────────────────────────────────────────────────────

class HomeController extends AppBaseController {
  BottomTabItem? selectedTab;
  int selectedTabV = 0;
  int selectedTabI = 0;
  UserData? currentUserData;
  List<BottomTabItem> bottomList = [];
  List<Position> userPositionsList = [];
  bool isLocationSend = false;
  int currentYear = 0;
  bool? isCustomer;
  String? name;
  RxInt itemInCart = 0.obs;
  RxInt unApprovalCount = 0.obs;
  static StreamController<String> counterController =
  StreamController<String>.broadcast();
  static String cartCount = '';

  void setLocationSending(bool value) {
    isLocationSend = value;
    update();
  }

  @override
  void onInit() async {
    // ── Inject dummy user directly — no SharedPreferences, no API ────────────
    currentUserData = _dummyUser();
    isCustomer = currentUserData?.usertype == 'Customer'; // false → Manager
    name = currentUserData?.name;
    scaffoldKey = GlobalKey<ScaffoldState>();

    // Register HomeViewNewController so HomeView can find it
    if (!Get.isRegistered<HomeViewNewController>()) {
      Get.put<HomeViewNewController>(HomeViewNewController());
    }

    onItemTapped(0);
    update();
    super.onInit();
  }

  void menulist() {}

  void onItemTapped(int index) {
    selectedTabI = index;
    selectedTabV = index;
    update();
  }

  void sendLocations() {}
  void collectLocations() {}
  Future<void> saveLocationAPI() async {}
  Future<void> updateToken(String? token) async {}
  Future<void> loadUserData() async {}
  Future<void> refreshUserData() async {}
}