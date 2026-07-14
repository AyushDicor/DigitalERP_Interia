import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/response/stcok_category_data_response.dart';
import 'package:newdigitalerp/response/stock_enquiry_item_resp.dart';
import 'package:newdigitalerp/response/stock_enquiry_godown_resp.dart';
import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/services/api_service/request_keys.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import '../../../../../home/home_contoller.dart';

/// Stock / Item Enquiry — search items and view each item's total current stock,
/// then drill into a single item (see [StockEnquiryDetailController]) for its
/// godown-wise breakdown. Read-only; backed by /api/stockenquiry/*.
class StockEnquiryController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  final TextEditingController searchCtr = TextEditingController();

  List<StockCategoryList> categoryList = [];
  StockCategoryList? selectedCategory;

  List<StockEnquiryItem> items = [];
  bool hasSearched = false;

  String get _compId =>
      homeController.currentUserData?.compId.toString() ?? '2';
  String get _branchId =>
      homeController.currentUserData?.branchId.toString() ?? '0';

  @override
  void onInit() {
    getCategoryList();
    getItems();
    super.onInit();
  }

  @override
  void onClose() {
    searchCtr.dispose();
    super.onClose();
  }

  Future<void> getCategoryList() async {
    try {
      final res = await api.getStockCategoryData({RequestKeys.compId: _compId});
      if (res.status == 200) {
        categoryList = res.data ?? [];
        update();
      }
    } catch (_) {
      // category filter is optional; ignore load failures silently
    }
  }

  void setCategory(StockCategoryList? c) {
    selectedCategory = c;
    update();
    getItems();
  }

  void clearFilters() {
    searchCtr.clear();
    selectedCategory = null;
    update();
    getItems();
  }

  Future<void> getItems() async {
    setBusy(true);
    items = [];
    try {
      final Map<String, String> body = {
        RequestKeys.compId: _compId,
        RequestKeys.branchId: _branchId,
        RequestKeys.categoryId: selectedCategory?.categoryid.toString() ?? '0',
        'search': searchCtr.text.trim(),
      };
      final res = await api.getStockEnquiryItems(body);
      if (res.status == 200) {
        items = res.data ?? [];
      } else {
        ShowMessage.showSnackBar('Server', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      hasSearched = true;
      setBusy(false);
      update();
    }
  }
}

/// Loads and holds one item's godown-wise stock breakdown.
class StockEnquiryDetailController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();
  final int itemId;
  final String itemTitle;

  StockEnquiryDetailController(this.itemId, this.itemTitle);

  StockEnquiryGodownData? data;

  @override
  void onInit() {
    load();
    super.onInit();
  }

  Future<void> load() async {
    setBusy(true);
    try {
      final Map<String, String> body = {
        RequestKeys.compId:
            homeController.currentUserData?.compId.toString() ?? '2',
        RequestKeys.branchId:
            homeController.currentUserData?.branchId.toString() ?? '0',
        RequestKeys.itemId: itemId.toString(),
      };
      final res = await api.getStockEnquiryGodownWise(body);
      if (res.status == 200) {
        data = res.data;
      } else {
        ShowMessage.showSnackBar('Server', res.message.toString());
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      setBusy(false);
      update();
    }
  }
}
