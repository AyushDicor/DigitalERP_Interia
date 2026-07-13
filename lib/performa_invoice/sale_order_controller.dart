// Performa Invoice (Sale Order) controller — read-only list + detail, with a
// free-text search and dynamic dropdown filters whose options are auto-derived
// from the loaded records (same pattern as Lead Management).

import 'package:get/get.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'sale_order_models.dart';

class SaleOrderController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  List<SaleOrderListItem> allOrders = [];
  String searchText = '';

  // Dynamic dropdown filters ('' = not applied); options auto-derived below.
  String filterParty = '';
  String filterCreatedBy = '';
  String filterCurrency = '';
  String filterSeries = '';

  // Detail screen state.
  SaleOrderHeader? selectedHeader;
  List<SaleOrderItem> selectedItems = [];
  bool detailBusy = false;

  String get _compId =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';

  // ── Server-side date window (on Create Date) ──
  // Defaults to the last 30 days, like the other modules. Widen it from the
  // Date Range filter to pull older records.
  // NOTE: we deliberately do NOT send `yearid`. Login returns a numeric year *id*
  // ("9") while TransMaster.YearID stores the label ("2026-27"), so sending it
  // matched nothing and the list came back empty.
  static const int defaultWindowDays = 30;
  DateTime fromDate =
      DateTime.now().subtract(const Duration(days: defaultWindowDays));
  DateTime toDate = DateTime.now();

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  static String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String get dateRangeLabel => '${_dmy(fromDate)} — ${_dmy(toDate)}';

  bool get isDefaultDateRange {
    final d = toDate.difference(fromDate).inDays;
    return d == defaultWindowDays || d == defaultWindowDays - 1;
  }

  /// Widen/narrow the window, then re-query the server.
  Future<void> setDateRange(DateTime from, DateTime to) async {
    fromDate = from;
    toDate = to;
    update();
    await loadList();
  }

  Future<void> resetDateRange() => setDateRange(
        DateTime.now().subtract(const Duration(days: defaultWindowDays)),
        DateTime.now(),
      );

  @override
  void onInit() {
    super.onInit();
    loadList();
  }

  // ── List with filters + search applied ──
  List<SaleOrderListItem> get orderList {
    Iterable<SaleOrderListItem> list = allOrders;
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
    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
          o.orderno.toLowerCase().contains(q) ||
          o.partyname.toLowerCase().contains(q) ||
          o.buyerorderno.toLowerCase().contains(q) ||
          o.createdby.toLowerCase().contains(q) ||
          o.mainid.toString().contains(q));
    }
    return list.toList();
  }

  int get totalRecords => allOrders.length;
  int get filteredCount => orderList.length;

  // ── Filter options, auto-derived from loaded records ──
  List<String> _distinct(String Function(SaleOrderListItem) sel) {
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

  int get activeFilterCount =>
      (filterParty.isNotEmpty ? 1 : 0) +
      (filterCreatedBy.isNotEmpty ? 1 : 0) +
      (filterCurrency.isNotEmpty ? 1 : 0) +
      (filterSeries.isNotEmpty ? 1 : 0);

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

  void resetFilters() {
    filterParty = '';
    filterCreatedBy = '';
    filterCurrency = '';
    filterSeries = '';
    update();
  }

  // ── Data ──
  Future<void> loadList() async {
    setBusy(true);
    try {
      final res = await api.getSaleOrderList({
        'compid': _compId,
        'branchid': _branchId,
        'fromdate': _ymd(fromDate),
        'todate': _ymd(toDate),
      });
      if (res.status == 200) {
        allOrders = res.data;
      } else {
        allOrders = [];
        ShowMessage.showSnackBar('Performa Invoice', res.message);
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
      final res = await api.getSaleOrderDetail({
        'id': id.toString(),
        'compid': _compId,
      });
      if (res.status == 200) {
        selectedHeader = res.header;
        selectedItems = res.items;
      } else {
        ShowMessage.showSnackBar('Performa Invoice', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      detailBusy = false;
      update();
    }
  }
}
