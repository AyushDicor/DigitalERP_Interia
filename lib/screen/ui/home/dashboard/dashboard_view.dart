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
        backgroundColor: newSurfaceColor,
        body: SafeArea(
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
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────────────────────
  Widget _dashAppBar(DashboardController controller, BuildContext context) {
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
