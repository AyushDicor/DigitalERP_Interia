import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_controller.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_controller.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/recent_activity_open.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/shop_floor_summary.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/app_profile_image.dart';

/// Action Center dashboard: tappable pending-action tiles + a recent-activity
/// feed (both backed by /api/dashboardnew/* ), plus the attendance summary.
class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      init: DashboardController(),
      builder: (controller) {
        // Resolved once here so the profile card's attendance pill and the
        // attendance table below it read the same controller instance.
        final attendance = Get.isRegistered<AttendanceController>()
            ? Get.find<AttendanceController>()
            : Get.put(AttendanceController());

        return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _backdrop(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _dashAppBar(controller, context),
                  Expanded(
                    child: RefreshIndicator(
                      color: newBlueColor,
                      onRefresh: () async {
                        controller.fetchPendency();
                        controller.fetchApprovalPending();
                        controller.fetchActivity();
                        if (Get.isRegistered<ShopFloorController>()) {
                          Get.find<ShopFloorController>().load();
                        }
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profileCard(controller, attendance),
                            const SizedBox(height: 22),
                            // My Jobs / Order Tracking, each only for the
                            // user the backend granted it to. Draws nothing
                            // at all otherwise.
                            const ShopFloorSummary(),
                            _sectionTitle('Action Center'),
                            const SizedBox(height: 12),
                            _actionGrid(controller),
                            const SizedBox(height: 24),
                            _sectionTitle('Recent Activity',
                                trailing: 'Last 3 days'),
                            const SizedBox(height: 12),
                            _activityFeed(controller),
                            const SizedBox(height: 24),
                            _sectionTitle('Attendance'),
                            const SizedBox(height: 12),
                            _attendanceTable(attendance),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────
  Widget _dashAppBar(DashboardController controller, BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => controller.openDrawer(context),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.menu_rounded, size: 24, color: newTextPrimary),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Dashboard',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: newTextPrimary)),
          ),
        ],
      ),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────

  /// Greeting header: who you are, what day it is, whether you have punched in
  /// and how much work is waiting — the four things worth knowing before the
  /// tiles below are read.
  Widget _profileCard(DashboardController controller, AttendanceController a) {
    final user = controller.homeController.currentUserData;
    final pending =
        _visibleTiles(controller).fold<int>(0, (sum, t) => sum + t.count);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B4BE0), purpleColor, Color(0xFF738EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: purpleColor.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Soft light rings — depth without another image asset.
            Positioned(top: -46, right: -26, child: _ring(120, 0.13)),
            Positioned(top: 18, right: 34, child: _ring(70, 0.10)),
            Positioned(bottom: -54, left: -30, child: _ring(110, 0.09)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar with a translucent ring around it.
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        child: ProfileImageView(
                          size: 52,
                          imageUrl: user?.photo ?? '',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if ((user?.usertype ?? '').trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded,
                                        size: 11, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      user!.usertype!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _datePill(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                      height: 1, color: Colors.white.withValues(alpha: 0.18)),
                  const SizedBox(height: 12),
                  // Live strip: attendance follows AttendanceController, so it
                  // updates the moment the summary loads or a punch is made.
                  GetBuilder<AttendanceController>(
                    init: a,
                    builder: (att) {
                      final status = _todayAttendance(att);
                      return Row(
                        children: [
                          Expanded(
                            child: _headerStat(
                                status.icon, status.label, status.caption),
                          ),
                          Container(
                              width: 1,
                              height: 26,
                              color: Colors.white.withValues(alpha: 0.18)),
                          Expanded(
                            child: _headerStat(
                                Icons.pending_actions_rounded,
                                pending == 0 ? 'All clear' : '$pending items',
                                'Pending actions'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: alpha), width: 16),
        ),
      );

  Widget _datePill() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(days[now.weekday - 1],
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 1),
          Text('${now.day}',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1)),
          Text(months[now.month - 1],
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _headerStat(IconData icon, String value, String caption) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15)),
                Text(caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Today's punch state, read from the same summary the attendance table uses.
  ({IconData icon, String label, String caption}) _todayAttendance(
      AttendanceController a) {
    final now = DateTime.now();
    final today = '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}';

    final details = (a.attendanceSummaryData?.isNotEmpty ?? false)
        ? (a.attendanceSummaryData![0].details ?? [])
        : [];

    String inTime = '', outTime = '';
    for (final d in details) {
      if (d.date == today) {
        inTime = d.inTime ?? '';
        outTime = d.outTime ?? '';
        break;
      }
    }

    if (inTime.isEmpty) {
      return (
        icon: Icons.schedule_rounded,
        label: 'Not marked',
        caption: "Today's attendance"
      );
    }
    if (outTime.isEmpty) {
      return (
        icon: Icons.login_rounded,
        label: 'In $inTime',
        caption: 'Checked in today'
      );
    }
    return (
      icon: Icons.check_circle_rounded,
      label: '$inTime – $outTime',
      caption: 'Day closed'
    );
  }

  Widget _sectionTitle(String title, {String? trailing}) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary)),
          if (trailing != null) ...[
            const Spacer(),
            Text(trailing,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary)),
          ],
        ],
      );

  // ── Action tile grid ─────────────────────────────────────────────────────

  /// The pending-action tiles this user is allowed to see. Shared by the grid
  /// and the profile card's "pending" pill so both always agree.
  List<_ActionTile> _visibleTiles(DashboardController controller) {
    final p = controller.pendency;
    // Menu ids match HomeViewNewController.getRouteNameById.
    final tiles = <_ActionTile>[
      // Counted like the Approval Hub does (see approvalPending) so the tile and
      // the hub's "Pending" stat can't disagree.
      _ActionTile(
          'Approvals',
          controller.approvalPending ?? p.pendingApprovals,
          Icons.fact_check_outlined,
          purpleColor,
          AppRoutes.approvalHub,
          2384),
      _ActionTile('Sale Orders', p.pendingSaleOrders,
          Icons.shopping_bag_outlined, const Color(0xFFF59E0B),
          AppRoutes.orderView, 2378),
      _ActionTile('Purchase Orders', p.pendingPO, Icons.receipt_long_outlined,
          const Color(0xFFEF4444), AppRoutes.purchaseOrder, 9402),
      _ActionTile('MRN', p.pendingMRN, Icons.inventory_2_outlined,
          const Color(0xFF16A34A), AppRoutes.mrnScreen, 2754),
      _ActionTile('Indent', p.pendingIndent, Icons.assignment_outlined,
          const Color(0xFF8B5CF6), AppRoutes.indentList, 2762),
      _ActionTile('Tasks', p.pendingTasks, Icons.task_alt_outlined,
          const Color(0xFF0EA5E9), AppRoutes.taskManagement, 2385),
    ];

    // Only show modules this user's menu actually grants. Without this the
    // dashboard shows counts (and taps through) to screens they can't reach.
    final menu = Get.isRegistered<HomeViewNewController>()
        ? Get.find<HomeViewNewController>()
        : null;
    return menu == null
        ? tiles
        : tiles.where((t) => menu.hasMenu(t.menuId)).toList();
  }

  Widget _actionGrid(DashboardController controller) {
    final visible = _visibleTiles(controller);
    if (visible.isEmpty) return const SizedBox.shrink();

    // Three per row: the tiles are compact enough that a 2-column grid wasted
    // most of each card on empty space.
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      // Short cards — icon and count on one row, label under them. Kept at 1.3
      // rather than tighter so a two-line label still fits on narrow phones.
      childAspectRatio: 1.3,
      children: visible.map(_actionCard).toList(),
    );
  }

  Widget _actionCard(_ActionTile t) {
    return GestureDetector(
      onTap: t.route == null ? null : () => Get.toNamed(t.route!),
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 7,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon on the left, the pending count on the card itself opposite
            // it — big enough to read at a glance, tinted to match the icon so
            // the two clearly belong to the same module.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(t.icon, size: 14, color: t.color),
                ),
                const Spacer(),
                Text('${t.count}',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: t.count > 0 ? t.color : newTextSecondary,
                        height: 1.0)),
              ],
            ),
            const Spacer(),
            Text(t.title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: newTextPrimary,
                    height: 1.15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ══════════════════════ Glass backdrop + charts ══════════════════════════
  // Soft gradient + blurred colour blobs so the frosted-glass cards read well.
  Widget _backdrop() {
    return Positioned.fill(
      child: ClipRect(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4F6FE), Color(0xFFFAFAFD), Color(0xFFF6F4FC)],
            ),
          ),
          child: Stack(children: [
            Positioned(
                top: -90,
                right: -80,
                child: _blob(260,  purpleColor.withValues(alpha: 0.14))),
            Positioned(
                top: 260,
                left: -110,
                child: _blob(240, const Color(0xFF8B5CF6).withValues(alpha: 0.10))),
            Positioned(
                bottom: -60,
                right: -70,
                child: _blob(220, const Color(0xFF0EA5E9).withValues(alpha: 0.10))),
          ]),
        ),
      ),
    );
  }

  // A soft, heavily-blurred colour glow (ambient light, not a hard circle).
  Widget _blob(double size, Color color) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );

  static String _money(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  // ── Recent activity feed ─────────────────────────────────────────────────
  // Real documents from the last few days, taken from each granted module's own
  // list endpoint (see RecentActivityRepo). Rows are tappable and open the
  // module they came from.
  Widget _activityFeed(DashboardController controller) {
    if (controller.activityLoading && controller.recentActivity.isEmpty) {
      return _feedShell(
        const SizedBox(
          height: 90,
          child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: newBlueColor))),
        ),
      );
    }

    final items = controller.recentActivity;
    if (items.isEmpty) {
      return _feedShell(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Icon(Icons.history_rounded,
                  size: 36, color: newTextSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              const Text('Nothing in the last 3 days',
                  style: TextStyle(fontSize: 13, color: newTextSecondary)),
            ],
          ),
        ),
      );
    }

    return _feedShell(
      Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          final color = _moduleColor(item.menuId);

          return InkWell(
            // Opens the document itself where the module allows it, else its
            // list — see openRecentActivity.
            onTap: () => openRecentActivity(item),
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? const Radius.circular(16) : Radius.zero,
              bottom: isLast ? const Radius.circular(16) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: newBorderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(_moduleIcon(item.menuId), size: 17, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.isEmpty ? item.module : item.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: newTextPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            item.module,
                            if (item.subtitle.isNotEmpty) item.subtitle,
                            _relativeDay(item.date),
                          ].join('  •  '),
                          style: const TextStyle(
                              fontSize: 11, color: newTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.amount != null && item.amount! > 0)
                        Text('₹${_money(item.amount!)}',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: newTextPrimary)),
                      if ((item.status ?? '').isNotEmpty) ...[
                        if (item.amount != null && item.amount! > 0)
                          const SizedBox(height: 3),
                        _statusChip(item.status!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _feedShell(Widget child) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      );

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color c = newTextSecondary;
    if (s.contains('pend') || s.contains('plan') || s.contains('hold')) {
      c = const Color(0xFFF59E0B);
    } else if (s.contains('approv') ||
        s.contains('complet') ||
        s.contains('close') ||
        s.contains('done') ||
        s.contains('final')) {
      c = newGreenColor;
    } else if (s.contains('reject') || s.contains('cancel')) {
      c = newRedColor;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }

  /// "Today" / "Yesterday" / "18 Aug" — a 3-day feed reads better this way.
  String _relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  IconData _moduleIcon(int menuId) {
    switch (menuId) {
      case 2384: return Icons.fact_check_outlined;
      case 2385: return Icons.task_alt_outlined;
      case 2379: return Icons.place_outlined;
      case 9401: return Icons.shopping_bag_outlined;
      case 9402: return Icons.receipt_long_outlined;
      case 2754: return Icons.inventory_2_outlined;
      case 2760: return Icons.local_shipping_outlined;
      case 2762: return Icons.assignment_outlined;
      default:   return Icons.description_outlined;
    }
  }

  Color _moduleColor(int menuId) {
    switch (menuId) {
      case 2384: return purpleColor;
      case 2385: return const Color(0xFF0EA5E9);
      case 2379: return const Color(0xFF0D9488);
      case 9401: return const Color(0xFFF59E0B);
      case 9402: return const Color(0xFFEF4444);
      case 2754: return const Color(0xFF16A34A);
      case 2760: return const Color(0xFFEC4899);
      case 2762: return const Color(0xFF8B5CF6);
      default:   return newBlueColor;
    }
  }

  // ── Attendance summary (unchanged, real data) ────────────────────────────
  Widget _attendanceTable(AttendanceController controller) {
    final summary = controller.attendanceSummaryData;
    if (summary == null || summary.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text('No attendance records',
              style: TextStyle(fontSize: 13, color: newTextSecondary)),
        ),
      );
    }

    final details = controller.attendanceSummaryData?[0].details ?? [];
    // Show latest first. The API returns oldest→newest, so sort descending by the
    // dd-MM-yyyy date (string sort would be wrong) before taking the top 5.
    DateTime parseDate(String? s) {
      final p = (s ?? '').split(RegExp(r'[-/]'));
      if (p.length == 3) {
        return DateTime(int.tryParse(p[2]) ?? 1900, int.tryParse(p[1]) ?? 1,
            int.tryParse(p[0]) ?? 1);
      }
      return DateTime(1900);
    }

    final sorted = [...details]
      ..sort((a, b) => parseDate(b.date).compareTo(parseDate(a.date)));
    final displayList = sorted.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: newSurfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Date',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: newTextSecondary,
                          letterSpacing: 0.4)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('In Time',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: newTextSecondary,
                          letterSpacing: 0.4)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Out Time',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: newTextSecondary,
                          letterSpacing: 0.4)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Status',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: newTextSecondary,
                          letterSpacing: 0.4)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: newBorderColor),
          if (displayList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No attendance records',
                    style: TextStyle(fontSize: 13, color: newTextSecondary)),
              ),
            )
          else
            ...displayList.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final bool inProgress =
                  item.outTime == null || item.outTime!.isEmpty;
              final statusColor =
                  inProgress ? const Color(0xFFF59E0B) : newGreenColor;
              final statusLabel = inProgress ? 'In Progress' : 'Present';
              final isLast = index == displayList.length - 1;

              return Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: index.isOdd ? newSurfaceColor : Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.date ?? '-',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: newTextPrimary),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.inTime ?? 'N/A',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: newGreenColor),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.outTime?.isNotEmpty == true
                                ? item.outTime!
                                : 'N/A',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: inProgress
                                    ? const Color(0xFFF59E0B)
                                    : newRedColor),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, color: newBorderColor),
                ],
              );
            }),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: newBorderColor, width: 0.5)),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: TextButton(
              onPressed: () {
                Get.find<HomeController>().onItemTapped(1); // 1 = Attendance tab
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View All',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: newBlueColor)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: newBlueColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String? route; // null = not tappable (no dedicated screen)
  /// Menu id this tile belongs to. The tile is hidden when the user's menu
  /// doesn't grant that module — otherwise the dashboard advertises counts for
  /// screens they can't open.
  final int menuId;
  const _ActionTile(this.title, this.count, this.icon, this.color, this.route,
      this.menuId);
}
