import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/base_api_helper.dart';
import 'package:newdigitalerp/repo/base_url.dart';
import 'package:newdigitalerp/repo/mis_repo.dart';
import 'package:newdigitalerp/utils/excel_export.dart';
import 'package:newdigitalerp/utils/show_message.dart';

/// Drives one MIS report: the filter bar (branch + date range), the KPI cards,
/// the charts and the grid. Everything it renders comes from /api/mis/data, so
/// this controller is report-agnostic.
class MisReportController extends GetxController {
  final HomeController home = Get.find<HomeController>();

  String get _compId => home.currentUserData?.compId?.toString() ?? '';
  String get _userId => home.currentUserData?.userid?.toString() ?? '';

  late MisReport report;

  MisData? data;
  bool loading = false;

  // ── Filters ──
  /// '0' = all branches. Defaults to all so head-office users see real totals
  /// rather than their own branch's handful of rows.
  String branchId = '0';
  List<({int id, String name})> branches = [];

  late DateTime fromDate;
  late DateTime toDate;

  /// Which quick preset is active. 'Custom' once a manual range is picked.
  String datePreset = 'Last 30 Days';

  /// Presets in the order they appear in the sheet. Covers what people actually
  /// ask a report for, so the calendar is only needed for odd ranges.
  static const List<String> datePresets = [
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Financial Year',
  ];

  String get fromLabel => DateFormat('dd-MM-yyyy').format(fromDate);
  String get toLabel => DateFormat('dd-MM-yyyy').format(toDate);

  /// Chip text: the preset name when one is active, else the actual range.
  String get dateLabel =>
      datePreset == 'Custom' ? '$fromLabel – $toLabel' : datePreset;

  /// Always shown under the chip label so the real range is never hidden.
  String get dateRangeLabel => '$fromLabel – $toLabel';

  /// Resolves a preset to its dates without applying it — so the picker can
  /// show each option's real range next to its name.
  ({DateTime from, DateTime to})? rangeFor(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case 'Today':
        return (from: today, to: today);
      case 'Yesterday':
        final y = today.subtract(const Duration(days: 1));
        return (from: y, to: y);
      case 'Last 7 Days':
        return (from: today.subtract(const Duration(days: 6)), to: today);
      case 'Last 30 Days':
        return (from: today.subtract(const Duration(days: 30)), to: today);
      case 'This Month':
        return (from: DateTime(today.year, today.month, 1), to: today);
      case 'Last Month':
        return (
          from: DateTime(today.year, today.month - 1, 1),
          // Day 0 of this month = last day of the previous month.
          to: DateTime(today.year, today.month, 0),
        );
      case 'This Quarter':
        final q = ((today.month - 1) ~/ 3) * 3 + 1;
        return (from: DateTime(today.year, q, 1), to: today);
      case 'This Financial Year':
        // Indian FY: 1 April – 31 March.
        final fyStart = today.month >= 4 ? today.year : today.year - 1;
        return (from: DateTime(fyStart, 4, 1), to: today);
      default:
        return null;
    }
  }

  /// "19 Jul – 18 Aug 2026" / "18 Aug 2026" when it's a single day.
  String labelForRange(DateTime from, DateTime to) {
    final f = DateFormat('dd MMM');
    if (from.year == to.year && from.month == to.month && from.day == to.day) {
      return DateFormat('dd MMM yyyy').format(from);
    }
    return '${f.format(from)} – ${DateFormat('dd MMM yyyy').format(to)}';
  }

  String? presetRangeLabel(String preset) {
    final r = rangeFor(preset);
    return r == null ? null : labelForRange(r.from, r.to);
  }

  void applyPreset(String preset) {
    final r = rangeFor(preset);
    if (r == null) return;
    fromDate = r.from;
    toDate = r.to;
    datePreset = preset;
    load();
  }
  String get branchLabel => branchId == '0'
      ? 'All Branches'
      : branches
          .firstWhere((b) => b.id.toString() == branchId,
              orElse: () => (id: 0, name: 'All Branches'))
          .name;

  @override
  void onInit() {
    final args = Get.arguments;
    report = (args is MisReport)
        ? args
        : const MisReport(
            id: 0, reportName: '', reportType: '', formName: '',
            drillEnabled: false);

    // Last 30 days, matching the other list screens in the app.
    toDate = DateTime.now();
    fromDate = toDate.subtract(const Duration(days: 30));

    loadBranches();
    load();
    super.onInit();
  }

  Future<void> loadBranches() async {
    try {
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'branchlist/getbranch',
          {'compid': _compId, 'userid': _userId});
      final list = (res.data as Map<String, dynamic>?)?['data'];
      if (list is! List) return;
      branches = list
          .whereType<Map>()
          .map((b) => (
                id: int.tryParse('${b['branchid']}') ?? 0,
                name: '${b['branchname'] ?? ''}',
              ))
          .where((b) => b.id > 0)
          .toList();
      update();
    } catch (_) {/* the All Branches default still works without this */}
  }

  Future<void> load() async {
    if (report.id <= 0) return;
    loading = true;
    update();
    try {
      data = await MisRepo.data(
        reportid: report.id,
        compid: _compId,
        branchid: branchId,
        userid: _userId,
        fromdate: DateFormat('yyyy-MM-dd').format(fromDate),
        todate: DateFormat('yyyy-MM-dd').format(toDate),
      );
    } finally {
      loading = false;
      update();
    }
  }

  void setBranch(String? id) {
    if (id == null || id == branchId) return;
    branchId = id;
    load();
  }

  Future<void> pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
    );
    if (picked == null) return;
    fromDate = picked.start;
    toDate = picked.end;
    datePreset = 'Custom';
    load();
  }

  // ── Excel export ──

  bool exporting = false;

  /// Exports exactly what the report shows — same columns, same rows, same
  /// filters. The file name carries the report and period so a folder of
  /// exports stays identifiable.
  Future<void> exportToExcel() async {
    final d = data;
    if (d == null || d.rows.isEmpty) return;
    exporting = true;
    update();
    try {
      final res = await ExcelExport.export(
        columns: d.visibleColumns,
        rows: d.rows,
        fileNameBase: '${report.reportName}_${fromLabel}_to_$toLabel',
        headerFor: (col) {
          final spaced = col.replaceAll('_', ' ').trim();
          return spaced.isEmpty
              ? col
              : spaced[0].toUpperCase() + spaced.substring(1);
        },
      );

      if (res.error != null || res.path == null) {
        ShowMessage.showSnackBar(
            'Export failed', res.error ?? 'Could not create the file');
        return;
      }

      if (res.opened) {
        ShowMessage.showSnackBar(
            'Exported', '${d.rows.length} records saved to Excel');
        return;
      }

      // File is fine, but nothing on the device opens .xlsx — offer to share
      // it instead of leaving the tap looking like it did nothing.
      Get.snackbar(
        'Excel saved',
        '${d.rows.length} records exported. No app here opens .xlsx — share it?',
        duration: const Duration(seconds: 6),
        mainButton: TextButton(
          onPressed: () =>
              ExcelExport.share(res.path!, subject: report.reportName),
          child: const Text('SHARE'),
        ),
      );
    } finally {
      exporting = false;
      update();
    }
  }

  // ── Drill-down ──

  bool drillLoading = false;
  List<Map<String, dynamic>> drillRows = [];

  /// Rows carry their key as `mainid`; without one there is nothing to drill to.
  int mainIdOf(Map<String, dynamic> row) =>
      int.tryParse('${row['mainid'] ?? row['MainId'] ?? 0}') ?? 0;

  bool get canDrill => data?.drillEnabled == true;

  Future<void> loadDrilldown(int mainId) async {
    drillLoading = true;
    drillRows = [];
    update();
    try {
      drillRows = await MisRepo.drilldown(
        reportid: report.id,
        mainid: mainId,
        compid: _compId,
        branchid: branchId,
        userid: _userId,
      );
    } finally {
      drillLoading = false;
      update();
    }
  }
}
