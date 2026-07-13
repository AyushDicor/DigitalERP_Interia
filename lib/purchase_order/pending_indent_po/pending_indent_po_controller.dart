// Pending Indent for PO — lists approved indents not yet fully converted to a PO
// (the ERP "Pending Indent for Po" grid, menu 97). Tapping a row opens the PO
// create form pre-seeded from that indent. No default date window: a pending
// indent must stay visible however old it is.

import 'package:get/get.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'pending_indent_po_models.dart';

class PendingIndentPoController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  List<PendingIndentItem> allIndents = [];
  String searchText = '';

  // Dynamic filters ('' = not applied). Options auto-derived from loaded rows.
  String filterSeries = '';
  String filterReqBy = '';
  String filterRequestTo = '';
  String filterPlant = '';

  // Optional date window on the indent's create date (null = no restriction —
  // the pending list shows all ages by default).
  DateTime? fromDate;
  DateTime? toDate;

  static DateTime? _parseDmy(String s) {
    final p = s.split(RegExp(r'[-/]'));
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]), m = int.tryParse(p[1]), y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  static String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-${d.year}';

  String get dateRangeLabel {
    if (fromDate == null && toDate == null) return 'All dates';
    final f = fromDate == null ? '…' : _dmy(fromDate!);
    final t = toDate == null ? '…' : _dmy(toDate!);
    return '$f  →  $t';
  }

  String get _compId =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';

  @override
  void onInit() {
    super.onInit();
    loadList();
  }

  List<PendingIndentItem> get indentList {
    Iterable<PendingIndentItem> list = allIndents;
    if (filterSeries.isNotEmpty) {
      list = list.where((o) => o.seriestype.trim() == filterSeries);
    }
    if (filterReqBy.isNotEmpty) {
      list = list.where((o) => o.reqby.trim() == filterReqBy);
    }
    if (filterRequestTo.isNotEmpty) {
      list = list.where((o) => o.requestto.trim() == filterRequestTo);
    }
    if (filterPlant.isNotEmpty) {
      list = list.where((o) => o.plant.trim() == filterPlant);
    }
    if (fromDate != null || toDate != null) {
      list = list.where((o) {
        final d = _parseDmy(o.createdate);
        if (d == null) return false;
        if (fromDate != null && d.isBefore(fromDate!)) return false;
        if (toDate != null && d.isAfter(toDate!)) return false;
        return true;
      });
    }
    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((o) =>
          o.indentno.toLowerCase().contains(q) ||
          o.reqby.toLowerCase().contains(q) ||
          o.requestto.toLowerCase().contains(q) ||
          o.plant.toLowerCase().contains(q) ||
          o.indentid.toString().contains(q));
    }
    return list.toList();
  }

  int get totalRecords => allIndents.length;
  int get filteredCount => indentList.length;

  // ── Filter options, auto-derived from loaded rows ──
  List<String> _distinct(String Function(PendingIndentItem) sel) {
    final s = allIndents
        .map(sel)
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return s;
  }

  List<String> get seriesOptions => _distinct((o) => o.seriestype);
  List<String> get reqByOptions => _distinct((o) => o.reqby);
  List<String> get requestToOptions => _distinct((o) => o.requestto);
  List<String> get plantOptions => _distinct((o) => o.plant);

  int get activeFilterCount =>
      (filterSeries.isNotEmpty ? 1 : 0) +
      (filterReqBy.isNotEmpty ? 1 : 0) +
      (filterRequestTo.isNotEmpty ? 1 : 0) +
      (filterPlant.isNotEmpty ? 1 : 0) +
      ((fromDate != null || toDate != null) ? 1 : 0);

  void setFromDate(DateTime? d) {
    fromDate = d == null ? null : DateTime(d.year, d.month, d.day);
    update();
  }

  void setToDate(DateTime? d) {
    toDate = d == null ? null : DateTime(d.year, d.month, d.day);
    update();
  }

  void setFilterSeries(String v) {
    filterSeries = v;
    update();
  }

  void setFilterReqBy(String v) {
    filterReqBy = v;
    update();
  }

  void setFilterRequestTo(String v) {
    filterRequestTo = v;
    update();
  }

  void setFilterPlant(String v) {
    filterPlant = v;
    update();
  }

  void resetFilters() {
    filterSeries = '';
    filterReqBy = '';
    filterRequestTo = '';
    filterPlant = '';
    fromDate = null;
    toDate = null;
    update();
  }

  void onSearch(String v) {
    searchText = v;
    update();
  }

  Future<void> loadList() async {
    setBusy(true);
    try {
      final res = await api.getPendingIndentsForPo({
        'compid': _compId,
        'branchid': _branchId,
      });
      if (res.status == 200) {
        allIndents = res.data;
      } else {
        allIndents = [];
        ShowMessage.showSnackBar('Pending Indent for PO', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      setBusy(false);
    }
  }
}
