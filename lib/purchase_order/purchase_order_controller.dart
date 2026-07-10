// Purchase Order controller — read-only list + detail, with a free-text search
// and dynamic dropdown filters whose options are auto-derived from the loaded
// records (same pattern as Performa Invoice / Lead Management).

import 'package:get/get.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'purchase_order_models.dart';

class PurchaseOrderController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  List<PurchaseOrderListItem> allOrders = [];
  String searchText = '';

  // Dynamic dropdown filters ('' = not applied); options auto-derived below.
  String filterParty = '';
  String filterCreatedBy = '';
  String filterCurrency = '';
  String filterSeries = '';
  String filterEntryType = '';

  // Detail screen state.
  PurchaseOrderHeader? selectedHeader;
  List<PurchaseOrderItem> selectedItems = [];
  bool detailBusy = false;

  String get _compId =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';
  String get _yearId => homeController.currentUserData?.yearId?.toString() ?? '';

  @override
  void onInit() {
    super.onInit();
    loadList();
  }

  // ── List with filters + search applied ──
  List<PurchaseOrderListItem> get orderList {
    Iterable<PurchaseOrderListItem> list = allOrders;
    if (filterParty.isNotEmpty) {
      list = list.where((o) => o.partyname.trim() == filterParty);
    }
    if (filterCreatedBy.isNotEmpty) {
      list = list.where((o) => o.createdby.trim() == filterCreatedBy);
    }
    if (filterCurrency.isNotEmpty) {
      list = list.where((o) => o.currency.trim() == filterCurrency);
    }
    if (filterSeries.isNotEmpty) {
      list = list.where((o) => o.series.trim() == filterSeries);
    }
    if (filterEntryType.isNotEmpty) {
      list = list.where((o) => o.entrytype.trim() == filterEntryType);
    }
    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
          o.orderno.toLowerCase().contains(q) ||
          o.partyname.toLowerCase().contains(q) ||
          o.entrytype.toLowerCase().contains(q) ||
          o.createdby.toLowerCase().contains(q) ||
          o.mainid.toString().contains(q));
    }
    return list.toList();
  }

  int get totalRecords => allOrders.length;
  int get filteredCount => orderList.length;

  // ── Filter options, auto-derived from loaded records ──
  List<String> _distinct(String Function(PurchaseOrderListItem) sel) {
    final s = allOrders
        .map(sel)
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return s;
  }

  List<String> get partyOptions => _distinct((o) => o.partyname);
  List<String> get createdByOptions => _distinct((o) => o.createdby);
  List<String> get currencyOptions => _distinct((o) => o.currency);
  List<String> get seriesOptions => _distinct((o) => o.series);
  List<String> get entryTypeOptions => _distinct((o) => o.entrytype);

  int get activeFilterCount =>
      (filterParty.isNotEmpty ? 1 : 0) +
      (filterCreatedBy.isNotEmpty ? 1 : 0) +
      (filterCurrency.isNotEmpty ? 1 : 0) +
      (filterSeries.isNotEmpty ? 1 : 0) +
      (filterEntryType.isNotEmpty ? 1 : 0);

  void onSearch(String v) {
    searchText = v;
    update();
  }

  void setFilterParty(String v) {
    filterParty = v;
    update();
  }

  void setFilterCreatedBy(String v) {
    filterCreatedBy = v;
    update();
  }

  void setFilterCurrency(String v) {
    filterCurrency = v;
    update();
  }

  void setFilterSeries(String v) {
    filterSeries = v;
    update();
  }

  void setFilterEntryType(String v) {
    filterEntryType = v;
    update();
  }

  void resetFilters() {
    filterParty = '';
    filterCreatedBy = '';
    filterCurrency = '';
    filterSeries = '';
    filterEntryType = '';
    update();
  }

  // ── Data ──
  Future<void> loadList() async {
    setBusy(true);
    try {
      final res = await api.getPurchaseOrderList({
        'compid': _compId,
        'branchid': _branchId,
        'yearid': _yearId,
      });
      if (res.status == 200) {
        allOrders = res.data;
      } else {
        allOrders = [];
        ShowMessage.showSnackBar('Purchase Order', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> loadDetail(int id) async {
    selectedHeader = null;
    selectedItems = [];
    detailBusy = true;
    update();
    try {
      final res = await api.getPurchaseOrderDetail({
        'id': id.toString(),
        'compid': _compId,
      });
      if (res.status == 200) {
        selectedHeader = res.header;
        selectedItems = res.items;
      } else {
        ShowMessage.showSnackBar('Purchase Order', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      detailBusy = false;
      update();
    }
  }
}
