import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/screen/ui/home/attendance/attendance_controller.dart';
import 'package:newdigitalerp/screen/ui/home/dashboard/dashboard_controller.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/app_profile_image.dart';



class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashboardController>(
      init: DashboardController(),
      builder: (controller) => Scaffold(
        backgroundColor: newSurfaceColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _dashAppBar(controller, context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _profileCard(controller),
                      const SizedBox(height: 20),
                      _statsRow(controller),
                      const SizedBox(height: 24),
                      _sectionTitle('Revenue'),
                      const SizedBox(height: 12),
                      _revenueChart(controller),
                      const SizedBox(height: 24),
                      _sectionTitle('Users Visits'),
                      const SizedBox(height: 12),
                      _visitsChart(controller),
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
            ],
          ),
        ),
      ),
    );
  }

  //  App bar
  Widget _dashAppBar(DashboardController controller, BuildContext context) {
    final hasApproval = Get.isRegistered<HomeViewNewController>()
        ? Get.find<HomeViewNewController>().menuListData.any((m) => m.menuid == 2384)
        : false;

    return Container(
      color: Colors.white,
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
          // if (hasApproval)
          //   GestureDetector(
          //     onTap: () => Get.to(() => const ApprovalHubDashboard()),
          //     child: Padding(
          //       padding: const EdgeInsets.only(right: 16),
          //       child: Container(
          //         width: 38,
          //         height: 38,
          //         decoration: BoxDecoration(
          //           color: newBlueLightColor,
          //           borderRadius: BorderRadius.circular(10),
          //         ),
          //         child: const Icon(
          //           Icons.approval_outlined,
          //           size: 20,
          //           color: newBlueColor,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  //  Profile card
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

  //  Stats row
  Widget _statsRow(DashboardController controller) {
    return Row(
      children: [
        Expanded(
            child: _statCard('TOTAL ORDERS', '1200',
                Icons.shopping_bag_outlined, newBlueColor, newBlueLightColor,
                badge: '+5.2%')),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                'PENDING VISITS',
                '15',
                Icons.person_pin_circle_outlined,
                newOrangeColor,
                newOrangeLightColor)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                'PAYMENT DUE',
                '₹1.2L',
                Icons.account_balance_wallet_outlined,
                newRedColor,
                newRedLightColor)),
      ],
    );
  }

  Widget _statCard(
      String label,
      String value,
      IconData icon,
      Color color,
      Color bgColor, {
        String? badge,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: newGreenLightColor,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: newGreenColor)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  //  Section title
  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: newTextPrimary));

  //  Period tab pill
  Widget _periodTab(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? newBlueColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : newTextSecondary)),
    );
  }

  //  Revenue line chart
  Widget _revenueChart(DashboardController controller) {
    final spots = [
      const FlSpot(0, 20),
      const FlSpot(1, 30),
      const FlSpot(2, 35),
      const FlSpot(3, 28),
      const FlSpot(4, 50),
      const FlSpot(5, 18),
      const FlSpot(6, 25),
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Amount (left) | Tabs (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('₹11,642',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: newSurfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: newBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['D', 'W', 'M', 'Y']
                      .map((t) => _periodTab(t, t == 'W'))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Badge + subtitle (own line, no competition for space)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: newGreenLightColor,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('+4%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: newGreenColor)),
              ),
              const SizedBox(width: 6),
              const Text('from last period',
                  style: TextStyle(fontSize: 11, color: newTextSecondary)),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: newBorderColor.withValues(alpha: 0.5),
                        strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 50,
                          getTitlesWidget: (v, _) => Text('₹${v.toInt()}k',
                              style: const TextStyle(
                                  fontSize: 9, color: newTextSecondary)),
                          reservedSize: 36)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i >= 0 && i < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(days[i],
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: i == 4
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: i == 4
                                            ? newBlueColor
                                            : newTextSecondary)),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 22)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0A1628),
                    tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                      '₹${s.y.toInt()}k',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ))
                        .toList(),
                  ),
                  getTouchedSpotIndicator: (_, indices) => indices
                      .map((_) => TouchedSpotIndicatorData(
                    FlLine(
                      color: newBlueColor.withValues(alpha: 0.4),
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeColor: newBlueColor,
                            strokeWidth: 2.5,
                          ),
                    ),
                  ))
                      .toList(),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: newBlueColor,
                    barWidth: 2.5,
                    dotData: FlDotData(
                        show: true,
                        checkToShowDot: (spot, _) => spot.x == 4,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeColor: newBlueColor,
                            strokeWidth: 2)),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            newBlueColor.withValues(alpha: 0.15),
                            newBlueColor.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Visits bar chart
  Widget _visitsChart(DashboardController controller) {
    final vals = [1000.0, 3000, 10000, 1000, 10000, 700, 1500];
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: total visits value (left) | Tabs pill (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('10,700',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: newSurfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: newBorderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['D', 'W', 'M', 'Y']
                      .map((t) => _periodTab(t, t == 'W'))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: badge + subtitle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: newGreenLightColor,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('+3.4%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: newGreenColor)),
              ),
              const SizedBox(width: 6),
              const Text('from last period',
                  style: TextStyle(fontSize: 11, color: newTextSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: 12000,
                minY: 0,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                        color: newBorderColor.withValues(alpha: 0.5),
                        strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          interval: 4000,
                          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 9, color: newTextSecondary)),
                          reservedSize: 38)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i >= 0 && i < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(days[i],
                                    style: const TextStyle(
                                        fontSize: 11, color: newTextSecondary)),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 20)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0A1628),
                    tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          '${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),
                barGroups: List.generate(
                    vals.length,
                        (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: vals[i].toDouble(),
                          width: 16,
                          color: newBlueColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  Recent orders table (dynamic from API)
  Widget _recentOrdersTable(DashboardController controller) {
    final data = controller.dashboardDetailsData;

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
          //  Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: newSurfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 3,
                    child: Text('Doc No.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: newTextSecondary))),
                Expanded(
                    flex: 3,
                    child: Text('Description',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: newTextSecondary))),
                Expanded(
                    flex: 3,
                    child: Text('Executive',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: newTextSecondary))),
              ],
            ),
          ),

          //  Empty state
          if (data == null || data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 36,
                        color: newTextSecondary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    const Text('No recent data',
                        style:
                        TextStyle(fontSize: 13, color: newTextSecondary)),
                  ],
                ),
              ),
            )
          else
          //  Data rows
            ...data.take(5).map((item) => Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: newBorderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  // Doc number with badge style
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: newBlueLightColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.documentNumber?.toString() ?? '—',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: newBlueColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Description
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.description?.toString() ?? '—',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: newTextPrimary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Executive name
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.executiveName?.toString() ?? '—',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: newTextSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            )),

          //  View all button
          if (data != null && data.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                border:
                Border(top: BorderSide(color: newBorderColor, width: 0.5)),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: TextButton(
                onPressed: () {},
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

  Widget _attendanceTable(AttendanceController controller) {
    final summary = controller.attendanceSummaryData;
    // ✅ Guard: no data yet → show empty state immediately
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
          // ✅ Header
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

          // ✅ Empty state
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
                        // Date
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

                        // In Time
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

                        // Out Time
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

                        // Status — just a colored dot + text, no chip
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

          // ✅ View All button
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
