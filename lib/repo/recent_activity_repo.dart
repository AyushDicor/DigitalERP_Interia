import 'dart:developer';

import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/repo/base_api_helper.dart';
import 'package:newdigitalerp/repo/base_url.dart';

/// One line in the dashboard's Recent Activity feed.
class RecentActivityItem {
  /// Menu id of the module this came from — the feed only ever contains
  /// modules the user's menu grants.
  final int menuId;

  /// Module label shown on the row ('Approval', 'Task', …).
  final String module;

  /// Document number / task title.
  final String title;

  /// Party, assignee or whoever created it.
  final String subtitle;

  final String? status;
  final double? amount;
  final DateTime date;

  /// The record's own id — approval id, task id, visit id, order mainid …
  /// Used to open the document itself rather than just its module.
  final int id;

  /// The source row, kept so a detail screen that needs more than an id (the
  /// Approval detail wants the whole list row) can be opened without re-fetching.
  final Map<String, dynamic> raw;

  /// Module list route — the fallback when the record can't be opened directly.
  final String? route;

  const RecentActivityItem({
    required this.menuId,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.date,
    this.id = 0,
    this.raw = const {},
    this.status,
    this.amount,
    this.route,
  });
}

/// Builds the dashboard's Recent Activity feed out of the *real* documents each
/// module created in the last few days.
///
/// The old feed read `Activitylogmaster` via /dashboardnew/dashboardDetailsnew,
/// which is empty for this company — the transaction procs never write to it —
/// so the section was permanently blank. This asks each module's own list
/// endpoint instead, and only for the modules the user's menu grants, so the
/// feed matches what that user can actually open.
class RecentActivityRepo {
  const RecentActivityRepo._();

  /// How far back the feed looks.
  static const int windowDays = 3;

  /// Most rows kept after merging every module.
  static const int maxItems = 12;

  static Future<List<RecentActivityItem>> load({
    required String compid,
    required String branchid,
    required String userid,
    required bool Function(int menuId) hasMenu,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(const Duration(days: windowDays));
    final fromStr = _fmt(from);
    final toStr = _fmt(today);

    final base = <String, dynamic>{
      'compid': compid,
      'branchid': branchid,
      'userid': userid,
      'fromdate': fromStr,
      'todate': toStr,
    };

    // menu id -> loader. Adding a module is one line here.
    final jobs = <Future<List<RecentActivityItem>>>[
      if (hasMenu(2384)) _approvals(base),
      if (hasMenu(2385)) _tasks(base),
      if (hasMenu(2379)) _visits(compid, userid),
      if (hasMenu(9401)) _orders(base, 'saleorder/list', 9401, 'Sale Order',
          AppRoutes.performaInvoice),
      if (hasMenu(9402)) _orders(base, 'purchaseorder/list', 9402,
          'Purchase Order', AppRoutes.purchaseOrder),
      if (hasMenu(2754)) _mrn(base, 'getmrnlist', 2754, 'MRN', AppRoutes.mrnScreen),
      if (hasMenu(2760)) _mrn(base, 'getgrnlist', 2760, 'GRN', AppRoutes.grnScreen),
      if (hasMenu(2762)) _indents(base),
    ];
    if (jobs.isEmpty) return [];

    final results = await Future.wait(jobs);
    final items = results
        .expand((e) => e)
        // Endpoints that ignore the date params (visits) are trimmed here.
        .where((i) => !i.date.isBefore(from))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return items.take(maxItems).toList();
  }

  // ── Per-module loaders ───────────────────────────────────────────────────

  static Future<List<RecentActivityItem>> _approvals(
      Map<String, dynamic> base) async {
    // status '' = every status, so the feed shows what was raised, not only
    // what is still pending.
    final rows = await _rows('GetApprovalList', {
      ...base,
      'documentname': '',
      'status': '',
    });
    return rows
        .map((r) {
          final date = _date(r['DocumentDate']);
          if (date == null) return null;
          return RecentActivityItem(
            menuId: 2384,
            module: _str(r['ApprovalType']).isEmpty
                ? 'Approval'
                : _str(r['ApprovalType']),
            title: _str(r['DocumentNo']),
            subtitle: _str(r['RequestedBy']),
            status: _str(r['Status']),
            amount: _num(r['Amount']),
            date: date,
            // The approval detail screen is driven by the whole list row.
            id: _int(r['NavigateId'] ?? r['DocumentId']),
            raw: Map<String, dynamic>.from(r),
            route: AppRoutes.approvalHub,
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

  static Future<List<RecentActivityItem>> _tasks(
      Map<String, dynamic> base) async {
    // task/list wraps its rows: data.rows.
    final data = await _data('task/list', base);
    final rows = (data is Map && data['rows'] is List)
        ? (data['rows'] as List).whereType<Map>().toList()
        : const <Map>[];
    return rows
        .map((r) {
          final date = _date(r['createddate']);
          if (date == null) return null;
          final assignee = _str(r['assignee']);
          final by = _str(r['createdby']);
          return RecentActivityItem(
            menuId: 2385,
            module: 'Task',
            title: _str(r['title']),
            subtitle: [
              if (by.isNotEmpty) by,
              if (assignee.isNotEmpty) 'to $assignee',
            ].join(' '),
            status: _str(r['status']),
            date: date,
            id: _int(r['taskid']),
            route: AppRoutes.taskManagement,
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

  /// /visit/list takes no date range, so everything is fetched and then
  /// trimmed by the caller's window.
  static Future<List<RecentActivityItem>> _visits(
      String compid, String userid) async {
    final rows = await _rows('visit/list', {'compid': compid, 'userid': userid});
    return rows
        .map((r) {
          final date = _date(r['VisitDate']);
          if (date == null) return null;
          final to = _str(r['VisitTo']);
          final by = _str(r['VisitedByName']);
          return RecentActivityItem(
            menuId: 2379,
            module: 'Visit',
            title: _str(r['VisitNo']),
            subtitle: [
              if (by.isNotEmpty) by,
              if (to.isNotEmpty) '· $to',
            ].join(' '),
            status: _str(r['Status']),
            date: date,
            id: _int(r['Id']),
            route: AppRoutes.visitPlan,
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

  /// Sale orders and purchase orders share one row shape.
  static Future<List<RecentActivityItem>> _orders(Map<String, dynamic> base,
      String path, int menuId, String module, String route) async {
    final rows = await _rows(path, base);
    return rows
        .map((r) {
          final date = _date(r['createdate'] ?? r['createddate']);
          if (date == null) return null;
          final party = _str(r['partyname']);
          final by = _str(r['createdby']);
          return RecentActivityItem(
            menuId: menuId,
            module: module,
            title: _str(r['orderno']),
            subtitle: party.isNotEmpty ? party : by,
            amount: _num(r['grandtotal']),
            date: date,
            id: _int(r['mainid']),
            route: route,
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

  /// MRN and GRN share one row shape.
  static Future<List<RecentActivityItem>> _mrn(Map<String, dynamic> base,
      String path, int menuId, String module, String route) async {
    final rows = await _rows(path, base);
    return rows
        .map((r) {
          final date = _date(r['mrndate'] ?? r['grndate'] ?? r['Mrndate']);
          if (date == null) return null;
          return RecentActivityItem(
            menuId: menuId,
            module: module,
            title: _str(r['Mrnno'] ?? r['Grnno'] ?? r['mrnno']),
            subtitle: _str(r['PartyName']),
            amount: _num(r['TotalAmt']),
            date: date,
            route: route,
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

  static Future<List<RecentActivityItem>> _indents(
      Map<String, dynamic> base) async {
    final rows = await _rows('getindentlist', base);
    return rows
        .map((r) {
          final date = _date(r['IndentDate']);
          if (date == null) return null;
          return RecentActivityItem(
            menuId: 2762,
            module: 'Indent',
            title: _str(r['IndentNo']),
            subtitle: _str(r['CreatedBy']),
            status: _str(r['ApprovalStatus']).isEmpty
                ? _str(r['IndentStatus'])
                : _str(r['ApprovalStatus']),
            date: date,
            route: AppRoutes.indentList,
          );
        })
        .whereType<RecentActivityItem>()
        .toList();
  }

  // ── Plumbing ─────────────────────────────────────────────────────────────

  /// A failing module must never take the whole feed down with it.
  static Future<dynamic> _data(String path, Map<String, dynamic> body) async {
    try {
      final res = await BaseApiHelper.postRequest(AppUrls.baseUrl + path, body);
      return (res.data as Map<String, dynamic>?)?['data'];
    } catch (e) {
      log('recent activity: $path failed — $e');
      return null;
    }
  }

  static Future<List<Map>> _rows(String path, Map<String, dynamic> body) async {
    final data = await _data(path, body);
    return data is List ? data.whereType<Map>().toList() : const <Map>[];
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  static String _str(dynamic v) {
    final s = '${v ?? ''}'.trim();
    return (s == 'null') ? '' : s;
  }

  static double? _num(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(_str(v)) ?? 0;

  static const Map<String, int> _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// The modules disagree on date format: dd-MM-yyyy (task, PO, MRN, indent)
  /// and 'dd MMM yyyy' (approval, visit). Both are handled, plus ISO as a
  /// last resort.
  static DateTime? _date(dynamic v) {
    final s = _str(v);
    if (s.isEmpty) return null;

    final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(s);
    if (dmy != null) {
      return DateTime(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!),
          int.parse(dmy.group(1)!));
    }

    final dMonY = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3,})\s+(\d{4})').firstMatch(s);
    if (dMonY != null) {
      final m = _months[dMonY.group(2)!.substring(0, 3).toLowerCase()];
      if (m != null) {
        return DateTime(
            int.parse(dMonY.group(3)!), m, int.parse(dMonY.group(1)!));
      }
    }

    return DateTime.tryParse(s);
  }
}
