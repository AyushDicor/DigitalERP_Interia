// ─────────────────────────────────────────────────────────────────────────────
// issue_item_list_controller.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/issue%20item/issue_item_response/issue_item_model.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';

class IssueItemListController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoadingList = false;
  List<IssueItemListItem> issueItems = [];
  String searchQuery = '';

  // ── Date controllers ───────────────────────────────────────────────────────
  final TextEditingController fromDateCtrl = TextEditingController();
  final TextEditingController toDateCtrl = TextEditingController();

  // ── Filtered list (search only — add MrnGrnFilter here if needed) ──────────
  List<IssueItemListItem> get filteredItems {
    if (searchQuery.trim().isEmpty) return List.from(issueItems);
    final q = searchQuery.toLowerCase();
    return issueItems
        .where((i) =>
            i.issueNo.toLowerCase().contains(q) ||
            i.issueTo.toLowerCase().contains(q) ||
            i.issuedBy.toLowerCase().contains(q) ||
            i.issueType.toLowerCase().contains(q) ||
            i.godown.toLowerCase().contains(q))
        .toList();
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 30));
    fromDateCtrl.text = DateFormat('yyyy-MM-dd').format(from);
    toDateCtrl.text = DateFormat('yyyy-MM-dd').format(today);
    fetchIssueItemList();
  }

  @override
  void onClose() {
    fromDateCtrl.dispose();
    toDateCtrl.dispose();
    super.onClose();
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  void onSearch(String q) {
    searchQuery = q;
    update();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  bool _isFetching = false;

  Future<void> fetchIssueItemList() async {
    if (_isFetching) return;
    _isFetching = true;

    isLoadingList = true;
    issueItems = [];
    searchQuery = '';
    update();

    try {
      // ── TEMPORARY MOCK: remove once API is ready ──────────────────────
      await Future.delayed(const Duration(seconds: 1));
      issueItems = [
        IssueItemListItem(
          id: 1,
          issueNo: 'ISS-2024-001',
          issueDate: '2024-05-01',
          issueType: 'Internal',
          issueTo: 'Site A',
          issuedBy: 'GAURAV DWIVEDI',
          godown: 'Main Godown',
          itemIssueType: 'IT',
          billNo: 'BILL-001',
          remarks: 'Test remark',
          totalQty: 10,
          totalAmount: 5000,
          grandTotal: 5000,
          status: 'Draft',
        ),
        IssueItemListItem(
          id: 2,
          issueNo: 'ISS-2024-002',
          issueDate: '2024-05-10',
          issueType: 'External',
          issueTo: 'Site B',
          issuedBy: 'Neha Gautam',
          godown: 'Store 2',
          itemIssueType: 'HR',
          billNo: 'BILL-002',
          remarks: '',
          totalQty: 5,
          totalAmount: 2500,
          grandTotal: 2500,
          status: 'Approved',
        ),
      ];
      // ── END MOCK ──────────────────────────────────────────────────────

      // ── REAL API: uncomment when ready ────────────────────────────────
      // final body = {
      //   'compid':   homeController.currentUserData?.compId   ?? 0,
      //   'branchid': homeController.currentUserData?.branchId ?? 0,
      //   'userid':   homeController.currentUserData?.userid   ?? 0,
      //   'fromdate': fromDateCtrl.text,
      //   'todate':   toDateCtrl.text,
      // };
      // final res = await api.getIssueItemList(body);
      // if (res.status == 200 || res.success == true) {
      //   issueItems = res.data;
      // } else {
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     ShowMessage.showSnackBar('Issue Items', res.message ?? 'Failed to load');
      //   });
      // }
      // ─────────────────────────────────────────────────────────────────
    } catch (e) {
      if (kDebugMode) print('IssueItemList exception: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowMessage.showSnackBar('Error', '$e');
      });
    } finally {
      isLoadingList = false;
      _isFetching = false;
      update();
    }
  }

  // Future<void> fetchIssueItemList() async {
  //   isLoadingList = true;
  //   issueItems    = [];
  //   searchQuery   = '';
  //   update();
  //   try {
  //     final body = {
  //       'compid':   homeController.currentUserData?.compId   ?? 0,
  //       'branchid': homeController.currentUserData?.branchId ?? 0,
  //       'userid':   homeController.currentUserData?.userid   ?? 0,
  //       'fromdate': fromDateCtrl.text,
  //       'todate':   toDateCtrl.text,
  //     };
  //     final res = await api.getIssueItemList(body);
  //     if (res.status == 200 || res.success == true) {
  //       issueItems = res.data;
  //     } else {
  //       ShowMessage.showSnackBar('Issue Items', res.message ?? 'Failed to load');
  //     }
  //   } catch (e) {
  //     if (kDebugMode) print('IssueItemList exception: $e');
  //     ShowMessage.showSnackBar('Error', '$e');
  //   } finally {
  //     isLoadingList = false;
  //     update();
  //   }
  // }

  // ── Date pickers ───────────────────────────────────────────────────────────
  Future<void> pickFromDate(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.tryParse(fromDateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      fromDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      update();
    }
  }

  Future<void> pickToDate(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.tryParse(toDateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      toDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      update();
    }
  }

  // ── Pull-to-refresh ────────────────────────────────────────────────────────
  Future<void> refresh() => fetchIssueItemList();
}
