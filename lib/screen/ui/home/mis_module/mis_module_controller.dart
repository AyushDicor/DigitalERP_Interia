import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/mis_repo.dart';
import 'package:newdigitalerp/screen/base/base_controller.dart';

/// One report tile on the MIS hub.
class MisTile {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String group;

  const MisTile({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.group,
  });
}

/// Section headings, in the order they should appear.
const List<String> misGroups = [
  'Accounts',
  'Sales & Orders',
  'Inventory',
  'People',
];

class MisModuleController extends AppBaseController {
  // ── Server-driven reports (/api/mis/reports) ──────────────────────────────
  // These are configured on the web (MISReport table), so new reports appear
  // here without an app update. The hard-coded tiles below stay as they are —
  // accounts/stock reports run on different endpoints and aren't in this list.

  List<MisReport> reports = [];
  bool reportsLoading = false;

  /// Grouped by module, so "Sales Order Summary" and "Sales Order Details" sit
  /// together instead of scattered through 24 flat rows.
  Map<String, List<MisReport>> get reportsByModule {
    final map = <String, List<MisReport>>{};
    for (final r in reports) {
      (map[r.formName] ??= []).add(r);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.reportType.compareTo(b.reportType));
    }
    return map;
  }

  @override
  void onInit() {
    loadReports();
    super.onInit();
  }

  Future<void> loadReports() async {
    reportsLoading = true;
    update();
    try {
      final home = Get.find<HomeController>();
      reports = await MisRepo.reports(
        compid: home.currentUserData?.compId?.toString() ?? '',
        userid: home.currentUserData?.userid?.toString() ?? '',
      );
    } finally {
      reportsLoading = false;
      update();
    }
  }

  void openReport(MisReport r) =>
      Get.toNamed(AppRoutes.misDynamicReport, arguments: r);

  /// The MIS hub is a fixed (hard-coded) list of reports the app supports —
  /// it is NOT driven by the menu API. Add a report here to expose it.
  final List<MisTile> menuList = const [
    // Accounts
    MisTile(
      name: 'Account Register',
      subtitle: 'Ledger-wise entries',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF5B5BD6),
      route: AppRoutes.misAccountRegister,
      group: 'Accounts',
    ),
    MisTile(
      name: 'Day Book',
      subtitle: 'All vouchers, date-wise',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF0EA5E9),
      route: AppRoutes.misDayBook,
      group: 'Accounts',
    ),
    MisTile(
      name: 'Balance Sheet',
      subtitle: 'Assets vs liabilities',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF16A34A),
      route: AppRoutes.misBalanceSheet,
      group: 'Accounts',
    ),
    MisTile(
      name: 'Profit and Loss',
      subtitle: 'Income vs expense',
      icon: Icons.trending_up_rounded,
      color: Color(0xFFEF4444),
      route: AppRoutes.misProfitLoss,
      group: 'Accounts',
    ),
    MisTile(
      name: 'Trial Balance',
      subtitle: 'Debit / credit summary',
      icon: Icons.calculate_outlined,
      color: Color(0xFF8B5CF6),
      route: AppRoutes.misTrialBalance,
      group: 'Accounts',
    ),
    MisTile(
      name: 'Outstanding',
      subtitle: 'Receivables & payables',
      icon: Icons.request_quote_outlined,
      color: Color(0xFFF97316),
      route: AppRoutes.misOutstanding,
      group: 'Accounts',
    ),

    // Sales & Orders
    MisTile(
      name: 'Order Report',
      subtitle: 'Order-wise sales',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFF59E0B),
      route: AppRoutes.misOrderReport,
      group: 'Sales & Orders',
    ),
    MisTile(
      name: 'Pending Shipping',
      subtitle: 'Orders yet to dispatch',
      icon: Icons.local_shipping_outlined,
      color: Color(0xFF14B8A6),
      route: AppRoutes.misPendingShipping,
      group: 'Sales & Orders',
    ),

    // Inventory
    MisTile(
      name: 'Stock Report',
      subtitle: 'Godown-wise stock',
      icon: Icons.warehouse_outlined,
      color: Color(0xFFCC9900),
      route: AppRoutes.misStockReport,
      group: 'Inventory',
    ),

    // People
    MisTile(
      name: 'Attendance Report',
      subtitle: 'Present / absent by month',
      icon: Icons.people_alt_outlined,
      color: Color(0xFF059669),
      route: AppRoutes.misAttendanceReport,
      group: 'People',
    ),
  ];

  /// Live search text typed in the header.
  String query = '';

  void onSearch(String value) {
    query = value.trim();
    update();
  }

  /// Tiles matching the current search, in declaration order.
  List<MisTile> get filteredList {
    if (query.isEmpty) return menuList;
    final q = query.toLowerCase();
    return menuList
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.subtitle.toLowerCase().contains(q) ||
            t.group.toLowerCase().contains(q))
        .toList();
  }

  /// Groups that still have at least one visible tile.
  List<String> get visibleGroups => misGroups
      .where((g) => filteredList.any((t) => t.group == g))
      .toList();

  List<MisTile> tilesOf(String group) =>
      filteredList.where((t) => t.group == group).toList();

  void openTile(MisTile tile) => Get.toNamed(tile.route);
}
