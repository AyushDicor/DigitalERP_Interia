import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_controller.dart';
import 'package:newdigitalerp/response/dashboard_details_response.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_controller.dart';
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
      builder: (controller) => Scaffold(
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
                        controller.fetchActivity();
                        controller.fetchGraphs();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profileCard(controller),
                            const SizedBox(height: 22),
                            _sectionTitle('Action Center'),
                            const SizedBox(height: 12),
                            _actionGrid(controller),
                            const SizedBox(height: 24),
                            _sectionTitle('Overview'),
                            const SizedBox(height: 12),
                            _chartsSection(controller),
                            const SizedBox(height: 24),
                            _sectionTitle('Recent Activity'),
                            const SizedBox(height: 12),
                            _activityFeed(controller),
                            const SizedBox(height: 24),
                            _sectionTitle('Attendance'),
                            const SizedBox(height: 12),
                            _attendanceTable(
                              Get.isRegistered<AttendanceController>()
                                  ? Get.find<AttendanceController>()
                                  : Get.put(AttendanceController()),
                            ),
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
      ),
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
  Widget _profileCard(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4361EE), Color(0xFF738EFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ProfileImageView(
            size: 52,
            imageUrl: controller.homeController.currentUserData?.photo ?? '',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.homeController.currentUserData?.name ?? 'User',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  controller.homeController.currentUserData?.usertype ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: newTextPrimary));

  // ── Action tile grid ─────────────────────────────────────────────────────
  Widget _actionGrid(DashboardController controller) {
    final p = controller.pendency;
    final tiles = <_ActionTile>[
      _ActionTile('Approvals', p.pendingApprovals, Icons.fact_check_outlined,
          const Color(0xFF4361EE), AppRoutes.approvalHub),
      _ActionTile('Sale Orders', p.pendingSaleOrders,
          Icons.shopping_bag_outlined, const Color(0xFFF59E0B),
          AppRoutes.orderView),
      _ActionTile('Purchase Orders', p.pendingPO, Icons.receipt_long_outlined,
          const Color(0xFFEF4444), null),
      _ActionTile('MRN', p.pendingMRN, Icons.inventory_2_outlined,
          const Color(0xFF16A34A), AppRoutes.mrnScreen),
      _ActionTile('Indent', p.pendingIndent, Icons.assignment_outlined,
          const Color(0xFF8B5CF6), AppRoutes.indentList),
      _ActionTile('Tasks', p.pendingTasks, Icons.task_alt_outlined,
          const Color(0xFF0EA5E9), AppRoutes.taskManagement),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.42,
      children: tiles.map(_actionCard).toList(),
    );
  }

  Widget _actionCard(_ActionTile t) {
    return GestureDetector(
      onTap: t.route == null ? null : () => Get.toNamed(t.route!),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(t.icon, size: 20, color: t.color),
                ),
                const Spacer(),
                if (t.route != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: newTextSecondary.withValues(alpha: 0.6)),
              ],
            ),
            const Spacer(),
            Text('${t.count}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary)),
            const SizedBox(height: 2),
            Text(t.title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary),
                maxLines: 1,
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
                child: _blob(260, const Color(0xFF4361EE).withValues(alpha: 0.14))),
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

  // A frosted-glass card.
  Widget _glass({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _chartHeader(String title, IconData icon) => Row(children: [
        Icon(icon, size: 16, color: newBlueColor),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: newTextPrimary)),
      ]);

  Widget _noData([String msg = 'No data available']) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: Column(children: [
            Icon(Icons.bar_chart_rounded,
                size: 30, color: newTextSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 6),
            Text(msg,
                style: const TextStyle(fontSize: 12, color: newTextSecondary)),
          ]),
        ),
      );

  static const List<Color> _mixColors = [
    Color(0xFF4361EE),
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFFEF4444),
  ];

  Widget _chartsSection(DashboardController c) {
    if (c.graphsLoading &&
        c.graphs.orderTrend.isEmpty &&
        c.graphs.documentMix.isEmpty) {
      return _glass(
        child: const SizedBox(
          height: 120,
          child: Center(
              child: CircularProgressIndicator(
                  color: newBlueColor, strokeWidth: 2.5)),
        ),
      );
    }
    return Column(children: [
      _trendCard(c),
      const SizedBox(height: 14),
      _mixCard(c),
      const SizedBox(height: 14),
      _partyCard(c),
      const SizedBox(height: 14),
      _recentOrdersCard(c),
    ]);
  }

  // Order trend (line)
  Widget _trendCard(DashboardController c) {
    final data = c.graphs.orderTrend;
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].count.toDouble())
    ];
    final maxV = data.isEmpty
        ? 1.0
        : data.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();
    return _glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _chartHeader('Order Trend', Icons.show_chart_rounded),
        const SizedBox(height: 14),
        if (data.isEmpty)
          _noData()
        else
          SizedBox(
            height: 150,
            child: LineChart(LineChartData(
              minY: 0,
              maxY: maxV * 1.35 + 0.5,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.black.withValues(alpha: 0.05),
                      strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 9, color: newTextSecondary)))),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval:
                            (data.length / 4).ceil().clamp(1, 999).toDouble(),
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= data.length) return const SizedBox();
                          final parts = data[i].date.split(RegExp(r'[-/]'));
                          final label = parts.length >= 2
                              ? '${parts[0]}-${parts[1]}'
                              : data[i].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label,
                                style: const TextStyle(
                                    fontSize: 8, color: newTextSecondary)),
                          );
                        })),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: newBlueColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(colors: [
                      newBlueColor.withValues(alpha: 0.22),
                      newBlueColor.withValues(alpha: 0.0),
                    ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                ),
              ],
            )),
          ),
      ]),
    );
  }

  // Document mix (donut)
  Widget _mixCard(DashboardController c) {
    final data = c.graphs.documentMix;
    final total = data.fold<int>(0, (a, b) => a + b.count);
    return _glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _chartHeader('Document Mix', Icons.donut_large_rounded),
        const SizedBox(height: 14),
        if (data.isEmpty)
          _noData()
        else
          Row(children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(alignment: Alignment.center, children: [
                PieChart(PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 34,
                  sections: [
                    for (var i = 0; i < data.length; i++)
                      PieChartSectionData(
                        value: data[i].count.toDouble(),
                        color: _mixColors[i % _mixColors.length],
                        radius: 22,
                        showTitle: false,
                      ),
                  ],
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: newTextPrimary)),
                  const Text('docs',
                      style:
                          TextStyle(fontSize: 10, color: newTextSecondary)),
                ]),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < data.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: _mixColors[i % _mixColors.length],
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(data[i].name,
                                style: const TextStyle(
                                    fontSize: 12, color: newTextPrimary))),
                        Text('${data[i].count}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: newTextSecondary)),
                      ]),
                    ),
                ],
              ),
            ),
          ]),
      ]),
    );
  }

  // Orders by party (bar)
  Widget _partyCard(DashboardController c) {
    final data = c.graphs.ordersByParty;
    final maxV = data.isEmpty
        ? 1.0
        : data.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();
    return _glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _chartHeader('Orders by Party', Icons.groups_2_outlined),
        const SizedBox(height: 8),
        if (data.isEmpty)
          _noData()
        else
          ...data.map((e) {
            final frac = maxV == 0 ? 0.0 : e.count / maxV;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(e.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: newTextPrimary)),
                      ),
                      Text('${e.count}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: newBlueColor)),
                    ]),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: frac.clamp(0.05, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.black.withValues(alpha: 0.05),
                        valueColor:
                            const AlwaysStoppedAnimation(newBlueColor),
                      ),
                    ),
                  ]),
            );
          }),
      ]),
    );
  }

  // Recent orders (list)
  Widget _recentOrdersCard(DashboardController c) {
    final data = c.graphs.recentOrders;
    return _glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _chartHeader('Recent Sale Orders', Icons.receipt_long_outlined),
        const SizedBox(height: 8),
        if (data.isEmpty)
          _noData('No recent orders')
        else
          ...data.map((o) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: newBlueColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.description_outlined,
                        size: 17, color: newBlueColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.party.isEmpty ? o.orderno : o.party,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: newTextPrimary)),
                          Text('${o.orderno}  ·  ${o.date}',
                              style: const TextStyle(
                                  fontSize: 11, color: newTextSecondary)),
                        ]),
                  ),
                  Text('₹${_money(o.amount)}',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: newTextPrimary)),
                ]),
              )),
      ]),
    );
  }

  static String _money(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  // ── Recent activity feed ─────────────────────────────────────────────────
  Widget _activityFeed(DashboardController controller) {
    final data = controller.dashboardDetailsData ?? [];

    if (data.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded,
                size: 36, color: newTextSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            const Text('No recent activity',
                style: TextStyle(fontSize: 13, color: newTextSecondary)),
          ],
        ),
      );
    }

    final items = data.take(8).toList();
    return Container(
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
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                      bottom: BorderSide(color: newBorderColor, width: 0.5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: newBlueLightColor,
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(_activityIcon(item.documentType),
                      size: 17, color: newBlueColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activityTitle(item),
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
                          item.executiveName,
                          item.documentDate,
                        ].where((e) => (e ?? '').trim().isNotEmpty && e != 'null').join('  •  '),
                        style: const TextStyle(
                            fontSize: 11, color: newTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _activityTitle(DashboardDetailsData item) {
    final parts = <String>[];
    final type = (item.documentType ?? '').trim();
    final no = (item.documentNumber ?? '').trim();
    if (type.isNotEmpty && type != 'null') parts.add(type);
    if (no.isNotEmpty && no != 'null') parts.add(no);
    final head = parts.join(' ');
    final desc = (item.description ?? '').trim();
    if (head.isNotEmpty) return head;
    if (desc.isNotEmpty && desc != 'null') return desc;
    return (item.title ?? 'Activity');
  }

  IconData _activityIcon(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('order')) return Icons.shopping_bag_outlined;
    if (t.contains('mrn') || t.contains('receipt')) return Icons.inventory_2_outlined;
    if (t.contains('indent')) return Icons.assignment_outlined;
    if (t.contains('approv')) return Icons.fact_check_outlined;
    if (t.contains('task')) return Icons.task_alt_outlined;
    if (t.contains('attend')) return Icons.access_time_rounded;
    if (t.contains('payment') || t.contains('voucher')) return Icons.payments_outlined;
    return Icons.description_outlined;
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
    final displayList = details.take(5).toList();

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
  const _ActionTile(this.title, this.count, this.icon, this.color, this.route);
}
