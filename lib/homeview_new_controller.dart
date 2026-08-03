// import 'dart:convert';
// import 'dart:developer';
//
// import 'package:newdigitalerp/Menu_new_list_responce.dart';
// import 'package:newdigitalerp/app_routes/app_routes.dart';
//
// import 'package:newdigitalerp/utils/app_assets.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import 'payment_request/payment_request_controller.dart';
// import 'screen/ui/graph/graph_controller.dart';
// import 'screen/ui/graph/graph_filter_controller.dart';
// import 'screen/ui/home/approval/submit/update_approvalstatus_responce.dart';
// import 'screen/ui/home/home_controller.dart';
// import 'services/api_service/request_keys.dart';
// import 'utils/show_message.dart';
//
// class HomeViewNewController extends AppBaseController {
//   HomeController homeController = Get.find<HomeController>();
//   RxInt unApprovalCount = 0.obs;
//   List<UpdateApprovalstatusResponse> value = [];
//   List<MenuNewData> menuListData = [];
//
//   @override
//   void onInit() {
//     super.onInit();
//
//     getUnApprovalCount();
//     getNewMenuList(0);
//   }
//
//   Future<void> getUnApprovalCount() async {
//     setBusy(true);
//     try {
//       Map<String, String> body = {};
//       body[RequestKeys.compId] =
//           homeController.currentUserData!.compId.toString();
//       body[RequestKeys.userId] =
//           homeController.currentUserData!.userid.toString();
//       body[RequestKeys.branchId] =
//           homeController.currentUserData!.branchId.toString();
//       var res = await api.getUnApprovalCount(body);
//       if (res.status == 200) {
//         unApprovalCount.value =
//             res.data?.first.counttotalunapproved?.toInt() ?? 0;
//         // for (int i = 0; i <= unApprovalCount.length - 1; i++) {
//         //   totalCount.add({"itemid": unApprovalCount[i].counttotalunapproved});
//
//         // await SharedPre.setValue(SharedPre.unApprovalCount, json.encode(unApprovalCount));
//       } else {
//         // ShowMessage.showSnackBar(
//         // 'getUnApprovalCount res.status not 200', res.message.toString());
//       }
//     } catch (e) {
//       ShowMessage.showSnackBar('Server Res', '$e');
//     } finally {
//       setBusy(false);
//     }
//   }
//
//   bool _fetchInProgress = false;
//
//   Future<void> getNewMenuList(int menuId) async {
//     if (_fetchInProgress) return;
//     _fetchInProgress = true;
//
//     try {
//       isBusy = true;
//       update();
//
//       // 1) Wait until user data is available (compId/branchId/userid not null)
//       await _waitForUserDataReady();
//
//       // 2) If menuId must be > 0, wait for that too (optional)
//       if (menuId == 0) {
//         debugPrint("⏳ menuId is 0; waiting a tick...");
//         await Future.delayed(const Duration(milliseconds: 150));
//       }
//
//       final body = <String, String>{
//         RequestKeys.compId: homeController.currentUserData!.compId.toString(),
//         RequestKeys.branchId:
//             homeController.currentUserData!.branchId.toString(),
//         RequestKeys.userId: homeController.currentUserData!.userid.toString(),
//         RequestKeys.menuId: menuId.toString(),
//       };
//
//       debugPrint("[REQ] $body");
//
//       final res = await api.getNewMenuList(body);
//
//       final data = (res.data as List?)?.toList() ?? [];
//
//       final rawData = res.data;
//       if (rawData is List<MenuNewData>) {
//         // Already parsed
//         menuListData = rawData;
//         debugPrint("[OK] items=${menuListData.length}");
//       } else {
//         debugPrint("[ERR ${res.status}] items=${menuListData.length}");
//       }
//       menuListData = (res.data as List<dynamic>?)
//           ?.map((e) => MenuNewData.fromJson(e as Map<String, dynamic>))
//           .toList() ??
//           [];
//
//       // Only logout if you’re SURE empty means invalid user
//       if (menuListData.isEmpty) {
//         debugPrint("⚠ Empty menu → skip logout for first-load race conditions");
//         await logout();
//         // return;
//       }
//     } catch (e, st) {
//       debugPrint("getNewMenuList error: $e\n$st");
//       ShowMessage.showSnackBar('getMenuList catch', '$e');
//     } finally {
//       isBusy = false;
//       update();
//       _fetchInProgress = false;
//     }
//     for (var item in menuListData) {
//       debugPrint("Menu: ${item.menuname} → ID: ${item.menuid}");
//     }
//   }
//
//   Future<void> _waitForUserDataReady() async {
//     // If you already populate currentUserData via async init, just await that Future instead.
//     for (int i = 0; i < 30; i++) {
//       // ~3s max
//       final u = homeController.currentUserData;
//       if (u != null &&
//           u.compId != null &&
//           u.branchId != null &&
//           u.userid != null) {
//         return;
//       }
//       await Future.delayed(const Duration(milliseconds: 100));
//     }
//     // If still not ready, throw to avoid sending nulls to API
//     throw StateError("User data not ready (compId/branchId/userId are null).");
//   }
//
//   Map<String, dynamic> imageList() {
//     return {
//       'Executive': 'assets/iconsnew/Executive.png',
//       'Order Module': AppAssets.ordernewIcon,
//       'Visit': AppAssets.visitnewIcon,
//       'Payment Request': AppAssets.expensenewIcon,
//       'Party List': AppAssets.partylistnewIcon,
//       'Image': AppAssets.imagenewIcon,
//       'Accounts': AppAssets.accountNewIcon,
//       'MIS': AppAssets.misnewIcon,
//       'Approval': AppAssets.approvalnewIcon,
//       'Task Management': AppAssets.taskManagementnewIcon,
//       'Document Management': AppAssets.documentnewIcon,
//       'Follow Up': AppAssets.orderfollowpnewIcon,
//       'Lead Management': AppAssets.leadManagementNewIcon,
//       'Category Catalouge': 'assets/iconsnew/Category Catalogue.png',
//       'Complaints': AppAssets.complaintsIcon,
//       'Reimbursement': 'assets/iconsnew/Reimbursements.png',
//       'Performance': AppAssets.performancenewIcon,
//       'Attendance': AppAssets.attendencenewIcon,
//       'MRN': AppAssets.mrnIcon,
//       'Material Received':AppAssets.mrnrIcon
//     };
//     // map['Executive'] = AppAssets.executivenewIcon;
//     // map['Order Management'] = AppAssets.ordernewIcon;
//     // map['Visit'] = AppAssets.visitnewIcon;
//     // map['Party List'] = AppAssets.partylistnewIcon;
//     // map['Image'] = AppAssets.imagenewIcon;
//     // map['Accounts'] = 'Accounts';
//     // map['MIS'] = AppAssets.misnewIcon;
//     // map['Approval'] = AppAssets.approvalnewIcon;
//     // map['Task Management'] = 'Task Management';
//     // map['Document Management'] = AppAssets.documentnewIcon;
//     // map['Follow Up'] = AppAssets.followupIcon;
//     // return map;
//   }
//
//   static String getRouteNameById(int? menuId) {
//     // return AppRoutes.menuDefaultView;
//     if (menuId == 2377) {
//       return AppRoutes.executiveListView;
//     } else if (menuId == 2378) {
//       return AppRoutes.orderView;
//     } else if (menuId == 2379) {
//       return AppRoutes.visitPlan;
//     } else if (menuId == 2380) {
//       return AppRoutes.partyList;
//     } else if (menuId == 2381) {
//       return AppRoutes.imageView;
//     } else if (menuId == 2382) {
//       return AppRoutes.accountModule;
//     } else if (menuId == 2383) {
//       return AppRoutes.misModule;
//     } else if (menuId == 2384) {
//       return AppRoutes.approvalList;
//     } else if (menuId == 2385) {
//       return AppRoutes.taskManagement;
//     } else if (menuId == 2386) {
//       return AppRoutes.documentDownload;
//     } else if (menuId == 2387) {
//       return AppRoutes.orderFollowup;
//     } else if (menuId == 2419) {
//       return AppRoutes.leadManagement;
//     } else if (menuId == 2423) {
//       return AppRoutes.performance;
//     } else if (menuId == 2429) {
//       return AppRoutes.catalougeListView;
//     } else if (menuId == 2586) {
//       return AppRoutes.paymentRequestScreen;
//     }
//     //else if (menuId == 2700) {return AppRoutes.complaints; // make sure this exists
//     //}
//     else if (menuId == 2701) {
//       return AppRoutes.expense; // make sure this exists
//     }
//     else if (menuId == 2754) {
//       return AppRoutes.mrnScreen;
//     } else if (menuId == 2755) {
//       return AppRoutes.materialReceiptScreen;
//     }
//     else {
//       return AppRoutes.homeNew;
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/Menu_new_list_responce.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/response/update_approvalstatus_responce.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'services/api_service/request_keys.dart';
import 'utils/show_message.dart';

class HomeViewNewController extends AppBaseController {
  // Lazy getter (NOT a field initializer): HomeController.onInit creates this
  // controller, so resolving HomeController at construction time caused a
  // circular init → StackOverflow (hard crash in release builds). Deferring the
  // lookup to first use breaks the cycle.
  HomeController get homeController => Get.find<HomeController>();
  RxInt unApprovalCount = 0.obs;
  List<UpdateApprovalstatusResponse> value = [];
  List<MenuNewData> menuListData = [];
  bool get hasApprovalAccess => menuListData.any((m) => m.menuid == 2384);

  bool isOpeningExternalFile = false;

  @override
  void onInit() {
    super.onInit();
    // Load the real menu from the mobile API for the logged-in user.
    getNewMenuList(0);
    // _loadDummyMenuList();
  }

  void _loadDummyMenuList() {
    menuListData = [
      MenuNewData()
        ..menuid = 2384
        ..menuname = 'Approval'
        ..child = 0,
      // MenuNewData()
      //   ..menuid   = 2385
      //   ..menuname = 'Task Management'
      //   ..child    = 0,
      // MenuNewData()
      //   ..menuid   = 2754
      //   ..menuname = 'MRN'
      //   ..child    = 0,
      // MenuNewData()
      //   ..menuid   = 2701
      //   ..menuname = 'Reimbursement'
      //   ..child    = 0,
      // MenuNewData()
      //   ..menuid   = 2586
      //   ..menuname = 'Payment Request'
      //   ..child    = 0,
      // MenuNewData()
      //   ..menuid   = 2378
      //   ..menuname = 'Order Module'
      //   ..child    = 0,
      // MenuNewData()
      //   ..menuid   = 2379
      //   ..menuname = 'Visit'
      //   ..child    = 0,
      // MenuNewData()
      //   ..menuid   = 2380
      //   ..menuname = 'Party List'
      //   ..child    = 0,
    ];
    update();
  }

  void markOpeningExternalFile() {
    isOpeningExternalFile = true;
    Future.delayed(const Duration(seconds: 4), () {
      isOpeningExternalFile = false;
    });
  }

  Future<void> getUnApprovalCount() async {
    setBusy(true);
    try {
      final body = {
        RequestKeys.compId: homeController.currentUserData!.compId.toString(),
        RequestKeys.userId: homeController.currentUserData!.userid.toString(),
        RequestKeys.branchId: homeController.currentUserData!.branchId
            .toString(),
      };
      final res = await api.getUnApprovalCount(body);
      if (res.status == 200) {
        unApprovalCount.value =
            res.data?.first.counttotalunapproved?.toInt() ?? 0;
      }
    } catch (e) {
      ShowMessage.showSnackBar('Server Res', '$e');
    } finally {
      setBusy(false);
    }
  }

  bool _fetchInProgress = false;

  Future<void> getNewMenuList(int menuId) async {
    if (_fetchInProgress) return;
    _fetchInProgress = true;

    try {
      isBusy = true;
      update();

      // Not logged in yet (this controller can init before login) → skip the
      // menu fetch silently. No error toast on the login screen; the menu loads
      // normally once real user data is available after login.
      if (!await _waitForUserDataReady()) return;

      if (menuId == 0) {
        await Future.delayed(const Duration(milliseconds: 150));
      }

      final body = <String, String>{
        RequestKeys.compId: homeController.currentUserData!.compId.toString(),
        RequestKeys.branchId: homeController.currentUserData!.branchId
            .toString(),
        RequestKeys.userId: homeController.currentUserData!.userid.toString(),
        RequestKeys.menuId: menuId.toString(),
      };

      final res = await api.getNewMenuList(body);
      debugPrint("res.data runtimeType = ${res.data.runtimeType}");
      debugPrint("res.data = ${res.data}");
      final rawData = res.data;

      if (rawData == null) {
        menuListData = [];
        debugPrint("[WARN] res.data is null");
      } else if (rawData is List<MenuNewData>) {
        // Already correctly typed
        menuListData = rawData;
        debugPrint(
          "[OK] already-parsed MenuNewData, items=${menuListData.length}",
        );
      } else if (rawData is List) {
        // Safely map each item — skip anything that isn't a Map
        menuListData = rawData
            .whereType<Map<String, dynamic>>()
            .map((e) {
              try {
                return MenuNewData.fromJson(e);
              } catch (parseErr) {
                debugPrint("[SKIP] Failed to parse menu item: $parseErr");
                return null;
              }
            })
            .whereType<MenuNewData>()
            .toList();
        debugPrint("[OK] json-parsed, items=${menuListData.length}");
      } else {
        menuListData = [];
        debugPrint("[ERR] Unexpected res.data type: ${rawData.runtimeType}");
      }

      // Ensure new mobile modules are visible even when the logged-in user's menu
      // permissions don't include them. These menuIds already route correctly
      // (2701 → reimbursement, 2586 → paymentRequestListScreen). Added so the new
      // modules can be reached without changing prod/master menu-permission tables.
      void ensureMenu(int id, String name) {
        if (menuListData.isNotEmpty &&
            !menuListData.any((m) => m.menuid == id)) {
          menuListData.add(
            MenuNewData()
              ..menuid = id
              ..menuname = name
              ..child = 0,
          );
        }
      }

      ensureMenu(2701, 'Reimbursement');
      // ensureMenu(2586, 'Payment Request'); // hidden for now (per request 2026-06-22)
      ensureMenu(2754, 'MRN');
      ensureMenu(2761, 'MRN QC');
      ensureMenu(2762, 'Indent');
      ensureMenu(2419, 'Lead Management'); // native Lead module (LeadController)
      // Performa Invoice (CreateSaleOrder) — read-only list+detail (SaleOrderController).
      // 9401 is a mobile-injected id; swap for the real ERP menu id once known so it
      // shows via the user's menu grant instead of force-injection.
      ensureMenu(9401, 'Performa Invoice');
      // Purchase Order (flag 'Purchaseorder') — list+detail+create (PurchaseOrderController).
      // 9402 is likewise a mobile-injected placeholder id.
      ensureMenu(9402, 'Purchase Order');
      // Pending Indent for PO — approved indents awaiting a PO; tap to generate a PO
      // seeded from the indent (PurchaseOrderController.PendingIndents/IndentForPo).
      // 97 is the real ERP menu id for this screen.
      ensureMenu(97, 'Pending Indent for PO');
      // Tap Card — personal business-card wallet, ported from the standalone
      // TapCard app (TapCardController, dbo.MobileTapCard). App-native, so the
      // ERP has no menu id for it; 9403 continues the 94xx placeholder series
      // (9401 Performa, 9402 PO). Do not use 2755 — Material Received owns it.
      ensureMenu(9403, 'Tap Card');
      // MIS (menuid 127) already comes from the backend menu and opens the
      // Reports Hub (see _getDirectRoute) — Stock Report is listed there.

      // Hide the Dashboard quick-link tile (menuid 126) — not needed (2026-06-22).
      menuListData.removeWhere((m) => m.menuid == 126);

      if (menuListData.isEmpty) {
        debugPrint("Empty menu list — logging out with message");
        await logout(); // clears session
        Get.offAllNamed(
          AppRoutes.login,
          arguments: {
            'error':
                'Menu not configured for your account. Please contact your administrator.',
          },
        );
      }
    } catch (e, st) {
      debugPrint("getNewMenuList error: $e\n$st");
      ShowMessage.showSnackBar('getMenuList catch', '$e');
    } finally {
      isBusy = false;
      update();
      _fetchInProgress = false;
    }

    for (final item in menuListData) {
      debugPrint("Menu: ${item.menuname} -> ID: ${item.menuid}");
    }
  }

  /// Returns true once the logged-in user's compId/branchId/userId are set.
  /// Returns false (no throw) if they never arrive — caller skips the fetch
  /// quietly instead of showing an error toast before login.
  Future<bool> _waitForUserDataReady() async {
    for (int i = 0; i < 20; i++) {
      final u = homeController.currentUserData;
      if (u != null &&
          u.compId != null &&
          u.branchId != null &&
          u.userid != null) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  Map<String, dynamic> imageList() {
    return {
      'Executive'           : 'assets/iconsnew/Executive2.png',
      'Order'               : AppAssets.ordernewIcon,
      'Visit'               : AppAssets.visitnewIcon,
      'Payment Request'     : AppAssets.expensenewIcon,
      'Party List'          : AppAssets.partylistnewIcon,
      'Image'               : AppAssets.imagenewIcon,
      'Accounts'            : AppAssets.accountNewIcon,
      'MIS'                 : AppAssets.misnewIcon,
      'Approval'            : AppAssets.approvalnewIcon,
      'Task'                : AppAssets.taskManagementnewIcon,
      'Document Management' : AppAssets.documentnewIcon,
      'Follow Up'           : AppAssets.orderfollowpnewIcon,
      'Lead Management'     : AppAssets.leadManagementNewIcon,
      'Performa Invoice'    : AppAssets.invoiceIcon,
      'Purchase Order'      : AppAssets.poIcon,
      'Pending Indent for PO' : AppAssets.poIcon,
      'Category Catalouge'  : 'assets/iconsnew/Category Catalogue.png',
      'Complaints'          : AppAssets.complaintsIcon,
      'Reimbursement'       : 'assets/iconsnew/Reimbursements.png',
      'Performance'         : AppAssets.performancenewIcon,
      'Attendance'          : AppAssets.attendencenewIcon,
      'MRN'                 : AppAssets.mrnIcon,
      'GRN Entry'           : AppAssets.grnIcon,
      'MRN QC'              : AppAssets.mrnQcIcon,
      'Material Received'   : AppAssets.mrnrIcon,
      'Indent'              : AppAssets.indentIcon,
      'Tap Card'            : AppAssets.tapCardIcon,
    };
  }

  static String getRouteNameById(int? menuId) {
    if (menuId == 2377) return AppRoutes.executiveListView;
    if (menuId == 2378) return AppRoutes.orderView;
    if (menuId == 2379) return AppRoutes.visitPlan;
    if (menuId == 2380) return AppRoutes.partyList;
    if (menuId == 2381) return AppRoutes.imageView;
    if (menuId == 2382) return AppRoutes.accountModule;
    if (menuId == 2383) return AppRoutes.misModule;
    if (menuId == 2384) return AppRoutes.approvalHub;
    if (menuId == 2385) return AppRoutes.taskManagement;
    if (menuId == 2386) return AppRoutes.documentDownload;
    if (menuId == 2387) return AppRoutes.orderFollowup;
    if (menuId == 2419) return AppRoutes.leadManagement;
    if (menuId == 9401) return AppRoutes.performaInvoice;
    if (menuId == 9402) return AppRoutes.purchaseOrder;
    if (menuId == 97  ) return AppRoutes.pendingIndentForPo;
    if (menuId == 2423) return AppRoutes.performance;
    if (menuId == 2429) return AppRoutes.catalougeListView;
    if (menuId == 2586) return AppRoutes.paymentRequestListScreen;
    if (menuId == 2701) return AppRoutes.reimbursement;
    if (menuId == 2754) return AppRoutes.mrnScreen;
    if (menuId == 2760) return AppRoutes.grnScreen;
    if (menuId == 2761) return AppRoutes.mrnQcList;
    if (menuId == 2762) return AppRoutes.indentList;
    if (menuId == 2755) return AppRoutes.materialReceiptScreen;
    // Tap Card. NOT 2755 — that id already belongs to Material Received above,
    // so the old `2755 -> tapCardList` line here was unreachable and the tile
    // fell through to '/materialReceived', whose GetPage is commented out.
    if (menuId == 9403) return AppRoutes.tapCardList;
    return AppRoutes.homeNew;
  }
}
