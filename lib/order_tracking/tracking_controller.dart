// Order Production Tracking — state.
//
// Call flow (per the backend's API doc):
//   open        → kpis + orders in parallel, then items(first order),
//                 then detail(first item)
//   order/item  → items / detail
//   filters     → detail again (search debounced ~400 ms); the dropdown lists
//                 come from the unfiltered trail so they stay stable
//   export      → CSV with the same filters → share sheet

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'tracking_models.dart';
import 'tracking_repo.dart';
import 'tracking_widgets.dart';

class TrackingController extends GetxController {
  final HomeController _home = Get.find<HomeController>();
  final TrackingRepo repo = TrackingRepo();

  int get compid => int.tryParse('${_home.currentUserData?.compId ?? ''}') ?? 0;

  /// 0 = every branch. This is an overseer view and production sits on the
  /// factory branch, while the supervisor usually logs in on the head-office
  /// one — filtering by his own branch showed him an empty screen.
  static const int branchid = 0;

  /// Tabs: Overview · Activity · People.
  int tab = 0;
  void setTab(int i) {
    tab = i;
    update();
  }

  // ── Data ──
  TrackKpis? kpis;
  List<TrackOrder> orders = [];
  List<TrackItem> items = [];
  TrackDetail? detail;

  TrackOrder? order;
  TrackItem? item;

  /// Downtime / bottleneck events across every order. A line that is stopped
  /// right now is the most urgent thing on this screen, so it is loaded with
  /// the KPIs and shown above them.
  List<TrackStoppage> stoppages = [];

  /// Still running — no end time recorded. Newest first.
  List<TrackStoppage> get ongoingStoppages =>
      stoppages.where((s) => s.isOngoing).toList()
        ..sort((a, b) => b.fromtime.compareTo(a.fromtime));

  /// Everything logged against the item currently being looked at.
  List<TrackStoppage> get itemStoppages {
    final i = item;
    if (i == null) return [];
    return stoppages
        .where((s) => s.challanid == i.challanid && s.itemid == i.itemid)
        .toList()
      ..sort((a, b) {
        if (a.isOngoing != b.isOngoing) return a.isOngoing ? -1 : 1;
        return b.fromtime.compareTo(a.fromtime);
      });
  }

  /// Minutes lost on this item (closed events only).
  int get itemLostMinutes =>
      itemStoppages.fold(0, (a, s) => a + (s.isOngoing ? 0 : s.durationmin));

  bool loading = false; // first load / order change
  bool detailLoading = false; // item or filter change
  bool exporting = false;
  String error = '';

  // ── Trail filters ──
  String stage = '';
  String person = '';
  final TextEditingController searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  /// Activity view: timeline (day groups) or flat table.
  bool tableView = false;
  void setTableView(bool v) {
    tableView = v;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  /// Open / pull-to-refresh: KPIs + orders together, then drill into the
  /// current selection (or the first order and item).
  Future<void> load() async {
    loading = true;
    error = '';
    update();
    try {
      final res = await Future.wait([
        repo.kpis(compid, branchid: branchid),
        repo.orders(compid, branchid: branchid),
        repo.stoppages(compid),
      ]);
      kpis = (res[0] as TrackResult<TrackKpis>).data;
      stoppages = (res[2] as TrackResult<List<TrackStoppage>>).data ?? [];
      final o = res[1] as TrackResult<List<TrackOrder>>;
      orders = o.data ?? [];
      if (orders.isEmpty) {
        error = o.message.isNotEmpty ? o.message : 'No orders in production.';
        items = [];
        detail = null;
        return;
      }
      final keep = order == null
          ? null
          : orders.where((x) => x.orderid == order!.orderid).firstOrNull;
      await selectOrder(keep ?? orders.first, silent: true);
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      update();
    }
  }

  /// Pick an order → load its items → open the first (or the kept) item.
  Future<void> selectOrder(TrackOrder o, {bool silent = false}) async {
    order = o;
    if (!silent) {
      loading = true;
      update();
    }
    try {
      final r = await repo.items(compid, o.orderid);
      items = r.data ?? [];
      final keep = item == null
          ? null
          : items.where((x) => x.key == item!.key).firstOrNull;
      item = keep ?? (items.isEmpty ? null : items.first);
      if (item == null) {
        detail = null;
        return;
      }
      await loadDetail();
    } finally {
      if (!silent) {
        loading = false;
      }
      update();
    }
  }

  /// Jump from a stoppage alert to the item it happened on. The order is
  /// usually the one already open; otherwise look through the others (a
  /// handful of calls at most, and only when the supervisor taps).
  Future<void> focusStoppage(TrackStoppage s) async {
    final here = items
        .where((x) => x.challanid == s.challanid && x.itemid == s.itemid)
        .firstOrNull;
    if (here != null) {
      await selectItem(here);
      setTab(0);
      return;
    }
    for (final o in orders) {
      final r = await repo.items(compid, o.orderid);
      final m = (r.data ?? [])
          .where((x) => x.challanid == s.challanid && x.itemid == s.itemid)
          .firstOrNull;
      if (m != null) {
        order = o;
        items = r.data ?? [];
        await selectItem(m);
        setTab(0);
        return;
      }
    }
    trackSnack(
      'Not in production',
      'That item is not in the orders currently in production.',
    );
  }

  Future<void> selectItem(TrackItem i) async {
    item = i;
    // A different item has its own people and stages — start unfiltered.
    stage = '';
    person = '';
    searchCtrl.clear();
    update();
    await loadDetail();
  }

  Future<void> loadDetail() async {
    final o = order, i = item;
    if (o == null || i == null) return;
    detailLoading = true;
    update();
    try {
      final r = await repo.detail(
        compid,
        orderid: o.orderid,
        challanid: i.challanid,
        itemid: i.itemid,
        stage: stage,
        person: person,
        search: searchCtrl.text.trim(),
      );
      if (r.ok && r.data != null) {
        detail = r.data;
        error = '';
      } else {
        error = r.message.isNotEmpty ? r.message : 'Could not load the trail.';
      }
    } catch (e) {
      error = '$e';
    } finally {
      detailLoading = false;
      update();
    }
  }

  void setStage(String s) {
    stage = s;
    update();
    loadDetail();
  }

  void setPerson(String p) {
    person = p;
    update();
    loadDetail();
  }

  /// Typing in the search box — one call ~400 ms after the last keystroke.
  void onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => loadDetail(),
    );
    update();
  }

  void clearSearch() {
    searchCtrl.clear();
    _searchDebounce?.cancel();
    loadDetail();
  }

  bool get hasFilters =>
      stage.isNotEmpty ||
      person.isNotEmpty ||
      searchCtrl.text.trim().isNotEmpty;

  void clearFilters() {
    stage = '';
    person = '';
    searchCtrl.clear();
    _searchDebounce?.cancel();
    update();
    loadDetail();
  }

  /// Export the trail (same filters) and hand it to the share sheet.
  Future<void> exportCsv() async {
    final i = item;
    if (i == null || exporting) return;
    exporting = true;
    update();
    try {
      final r = await repo.exportCsv(
        compid,
        challanid: i.challanid,
        itemid: i.itemid,
        stage: stage,
        person: person,
        search: searchCtrl.text.trim(),
      );
      if (r.bytes == null) {
        trackSnack('Export failed', r.error, kind: TrackSnackKind.error);
        return;
      }
      final dir = await getTemporaryDirectory();
      final name = 'production-tracking-${i.challanid}-${i.itemid}.csv';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(r.bytes!, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          text: 'Production tracking — ${i.itemname}',
          files: [XFile(file.path, name: name, mimeType: 'text/csv')],
        ),
      );
    } catch (e) {
      trackSnack('Export failed', '$e', kind: TrackSnackKind.error);
    } finally {
      exporting = false;
      update();
    }
  }
}
