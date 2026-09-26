// Shop-floor cards on the dashboard: a summary of My Jobs (menu 9404) and
// Order Production Tracking (menu 9405) so the two INTERIA modules surface
// their pending work on the landing screen instead of only inside the module.
//
// Each card is gated on a STRICT menu grant. A user who was never given Order
// Tracking sees nothing about orders here — not an empty card, not a zero.
// The calls behind a card are only made when that card is going to be shown.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/order_tracking/tracking_models.dart';
import 'package:newdigitalerp/order_tracking/tracking_repo.dart';
import 'package:newdigitalerp/production_operator/operator_models.dart';
import 'package:newdigitalerp/production_operator/operator_repo.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/menu_ids.dart';

class ShopFloorController extends GetxController {
  final OperatorRepo _ops = ApiOperatorRepo();
  final TrackingRepo _track = TrackingRepo();

  HomeViewNewController? get _menu => Get.isRegistered<HomeViewNewController>()
      ? Get.find<HomeViewNewController>()
      : null;

  /// Read live, not cached: the menu refreshes while the user is signed in, so
  /// a grant the backend removes takes the card away on the next rebuild, and
  /// one it adds brings the card in without a restart.
  bool get hasJobs => _menu?.hasMenuStrict(kMenuMyJobs) ?? false;
  bool get hasTracking => _menu?.hasMenuStrict(kMenuOrderTracking) ?? false;

  List<OperatorJob> jobs = [];
  List<Consignment> incoming = [];
  bool jobsLoading = false;

  TrackKpis? kpis;
  List<TrackStoppage> stoppages = [];
  bool trackLoading = false;

  bool get anyCard => hasJobs || hasTracking;

  /// The menu often lands after the first build, so the fetch is kicked off
  /// from [ensureLoaded] once a grant actually appears — never during build.
  bool _kickedOff = false;

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  void ensureLoaded() {
    if (_kickedOff || !anyCard) return;
    _kickedOff = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  OperatorSession get _session {
    final u = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>().currentUserData
        : null;
    return OperatorSession(
      compid: int.tryParse('${u?.compId ?? ''}') ?? 0,
      branchid: int.tryParse('${u?.branchId ?? ''}') ?? 0,
      userid: int.tryParse('${u?.userid ?? ''}') ?? 0,
      // Reads only — none of these endpoints look at the financial year.
      yearid: '',
      name: (u?.name ?? '').toString(),
    );
  }

  Future<void> load() async {
    _kickedOff = true;
    if (!anyCard) {
      update();
      return;
    }
    await Future.wait([
      if (hasJobs) _loadJobs(),
      if (hasTracking) _loadTracking(),
    ]);
  }

  Future<void> _loadJobs() async {
    jobsLoading = true;
    update();
    try {
      final s = _session;
      final res = await _ops.myJobs(s);
      if (res.ok) jobs = res.data ?? [];
      final inc = await _ops.incoming(s);
      if (inc.ok) incoming = inc.data ?? [];
    } catch (_) {
      // A dashboard card must never break the dashboard; it just stays empty.
    } finally {
      jobsLoading = false;
      update();
    }
  }

  Future<void> _loadTracking() async {
    trackLoading = true;
    update();
    try {
      final compid = _session.compid;
      final k = await _track.kpis(compid);
      if (k.ok && k.data != null) kpis = k.data;
      final st = await _track.stoppages(compid);
      if (st.ok) stoppages = st.data ?? [];
    } catch (_) {
      // Same here — leave the card blank rather than take the screen down.
    } finally {
      trackLoading = false;
      update();
    }
  }

  // ── My Jobs counts (same rules the module itself uses) ──

  List<OperatorJob> get _work =>
      jobs.where((j) => !j.isQcJob && !j.isInTransit).toList();

  int get toDo => _work
      .where((j) => !j.isReworkJob && j.state == OperatorJobState.pending)
      .length;
  int get running => _work
      .where((j) => !j.isReworkJob && j.state == OperatorJobState.running)
      .length;
  int get rework => _work.where((j) => j.isReworkJob).length;

  /// Lots this login may check — the backend flags them with `canqc`, so an
  /// operator never sees a QC number here.
  int get qcDue => jobs.where((j) => j.qcPending > 0 && j.canqc).length;
  bool get canQc => jobs.any((j) => j.canqc);

  int get incomingCount => incoming.length;

  /// Nothing at all waiting for this person.
  bool get jobsAllClear =>
      toDo == 0 && running == 0 && rework == 0 && qcDue == 0 &&
      incomingCount == 0;

  /// The jobs actually worth naming on the dashboard, in the order they
  /// deserve attention: rework first (QC sent it back), then work not
  /// started, then work in progress. Finished jobs are left out — the Done
  /// count above already says how many there were.
  List<OperatorJob> get actionableJobs => [
    ..._work.where((j) => j.isReworkJob),
    ..._work.where(
      (j) => !j.isReworkJob && j.state == OperatorJobState.pending,
    ),
    ..._work.where(
      (j) => !j.isReworkJob && j.state == OperatorJobState.running,
    ),
  ];

  /// Lots waiting for this login to check them.
  List<OperatorJob> get qcQueue =>
      jobs.where((j) => j.qcPending > 0 && j.canqc).toList();

  // ── Tracking ──

  /// Lines stopped right now — no end time recorded.
  List<TrackStoppage> get ongoing =>
      stoppages.where((s) => s.isOngoing).toList()
        ..sort((a, b) => b.fromtime.compareTo(a.fromtime));

  /// What the supervisor should see: anything still running, then whatever
  /// was logged in the last week. Without the window a stoppage closed months
  /// ago would sit on the dashboard for good.
  List<TrackStoppage> get recentStoppages {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final closed =
        stoppages.where((s) {
            if (s.isOngoing) return false;
            final d = DateTime.tryParse(s.fromtime.replaceFirst(' ', 'T'));
            return d == null || d.isAfter(cutoff);
          }).toList()
          ..sort((a, b) => b.fromtime.compareTo(a.fromtime));
    return [...ongoing, ...closed];
  }
}

/// The dashboard section. Renders nothing at all when neither module is
/// granted, so the rest of the dashboard closes up around it.
class ShopFloorSummary extends StatelessWidget {
  const ShopFloorSummary({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<ShopFloorController>(
    init: ShopFloorController(),
    builder: (c) {
      if (!c.anyCard) return const SizedBox.shrink();
      // A grant that arrived after the first build starts the fetch here.
      c.ensureLoaded();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Shop Floor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              const Spacer(),
              if (c.jobsLoading || c.trackLoading)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: purpleColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (c.hasJobs) _myJobsCard(c),
          if (c.hasJobs && c.hasTracking) const SizedBox(height: 11),
          if (c.hasTracking) _trackingCard(c),
          const SizedBox(height: 24),
        ],
      );
    },
  );

  // ── My Jobs ──

  Widget _myJobsCard(ShopFloorController c) => _card(
    onTap: () => Get.toNamed(AppRoutes.productionOperator),
    icon: Icons.precision_manufacturing_outlined,
    tint: purpleColor,
    title: 'My Jobs',
    subtitle: c.jobsLoading && c.jobs.isEmpty
        ? 'Loading your work…'
        : (c.jobsAllClear
              ? 'Nothing pending right now'
              : 'What is waiting for you'),
    child: Column(
      children: [
        Row(
          children: [
            _stat('To do', c.toDo, const Color(0xFF5B6CF6)),
            _stat('Running', c.running, const Color(0xFF2F6FED)),
            // Only QC logins get a QC number — for everyone else the slot goes
            // to rework, which is what they actually act on.
            if (c.canQc)
              _stat('To QC', c.qcDue, const Color(0xFF7C5CFF))
            else
              _stat('Rework', c.rework, const Color(0xFFE5890A)),
            _stat(
              c.canQc ? 'Rework' : 'Done',
              c.canQc
                  ? c.rework
                  : c._work
                        .where((j) => j.state == OperatorJobState.done)
                        .length,
              c.canQc ? const Color(0xFFE5890A) : const Color(0xFF12A150),
            ),
          ],
        ),
        if (c.incomingCount > 0) ...[
          const SizedBox(height: 11),
          _strip(
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF12A150),
            text:
                '${c.incomingCount} ${c.incomingCount == 1 ? 'consignment' : 'consignments'} '
                'to receive',
          ),
        ],
        // The counts say how much; these say what. Three rows at most —
        // the module itself is one tap away for the rest.
        if (c.qcQueue.isNotEmpty) ...[
          const SizedBox(height: 12),
          _listHead('Waiting for your QC', c.qcQueue.length),
          ...c.qcQueue.take(3).map((j) => _jobRow(j, isQc: true)),
          if (c.qcQueue.length > 3) _more(c.qcQueue.length - 3),
        ],
        if (c.actionableJobs.isNotEmpty) ...[
          const SizedBox(height: 12),
          _listHead('Your work', c.actionableJobs.length),
          ...c.actionableJobs.take(3).map((j) => _jobRow(j)),
          if (c.actionableJobs.length > 3) _more(c.actionableJobs.length - 3),
        ],
      ],
    ),
  );

  // ── Order Tracking ──

  Widget _trackingCard(ShopFloorController c) {
    final k = c.kpis;
    final rate = k?.qcPassRate;
    return _card(
      onTap: () => Get.toNamed(AppRoutes.orderTracking),
      icon: Icons.insights_outlined,
      tint: const Color(0xFF0EA5E9),
      title: 'Order Tracking',
      subtitle: c.trackLoading && k == null
          ? 'Loading production…'
          : 'Orders on the floor',
      child: Column(
        children: [
          Row(
            children: [
              _stat('In production', k?.ordersInProd ?? 0, const Color(0xFF0EA5E9)),
              _stat('Items', k?.itemsInProgress ?? 0, const Color(0xFF5B6CF6)),
              _statText(
                'Pass rate',
                rate == null ? '—' : '${rate.round()}%',
                rate == null
                    ? newTextSecondary
                    : (rate >= 95
                          ? const Color(0xFF12A150)
                          : const Color(0xFFE5890A)),
              ),
              _stat(
                'Overdue',
                k?.overdueOrders ?? 0,
                (k?.overdueOrders ?? 0) > 0
                    ? const Color(0xFFE5484D)
                    : newTextSecondary,
              ),
            ],
          ),
          // A line stopped right now outranks every number above it.
          if (c.ongoing.isNotEmpty) ...[
            const SizedBox(height: 11),
            _strip(
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFE5484D),
              text: c.ongoing.length == 1
                  ? '${c.ongoing.first.stagename} stopped — ${c.ongoing.first.reason}'
                  : '${c.ongoing.length} lines stopped right now',
            ),
          ],
          // Every downtime / bottleneck the floor logged, not only the live
          // ones — a shift that lost two hours this morning still matters
          // after the line restarts.
          if (c.recentStoppages.isNotEmpty) ...[
            const SizedBox(height: 12),
            _listHead('Downtime & bottleneck', c.recentStoppages.length,
                note: 'last 7 days'),
            ...c.recentStoppages.take(3).map(_stoppageRow),
            if (c.recentStoppages.length > 3)
              _more(c.recentStoppages.length - 3),
          ],
        ],
      ),
    );
  }

  // ── List rows ──

  Widget _listHead(String title, int count, {String? note}) => Padding(
    padding: const EdgeInsets.only(bottom: 2, top: 2),
    child: Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: newTextSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: newTextHint,
          ),
        ),
        const Spacer(),
        if (note != null)
          Text(
            note,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: newTextHint,
            ),
          ),
      ],
    ),
  );

  Widget _more(int n) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      '+$n more',
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: purpleColor,
      ),
    ),
  );

  /// One job: what it is, where it is, and how much of it is left.
  Widget _jobRow(OperatorJob j, {bool isQc = false}) {
    final (label, tone) = isQc
        ? ('${fmtQty(j.qcPending)} to check', const Color(0xFF7C5CFF))
        : j.isReworkJob
        ? ('${fmtQty(j.balanceqty)} rework', const Color(0xFFE5890A))
        : j.state == OperatorJobState.running
        ? ('${fmtQty(j.balanceqty)} left', const Color(0xFF2F6FED))
        : ('${fmtQty(j.balanceqty)} to make', const Color(0xFF5B6CF6));
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 26,
            margin: const EdgeInsets.only(top: 1, right: 9),
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  j.itemname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: newTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    if (j.stagename.isNotEmpty) j.stagename,
                    if (j.boqno.isNotEmpty) j.boqno,
                    if (j.challanno.isNotEmpty) 'Challan ${j.challanno}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }

  /// One downtime / bottleneck entry. Still running reads "Ongoing" in red;
  /// a closed one shows how long the floor lost.
  Widget _stoppageRow(TrackStoppage s) {
    final down = s.stype.toLowerCase().startsWith('down');
    final tone = s.isOngoing
        ? const Color(0xFFE5484D)
        : (down ? const Color(0xFFE5890A) : const Color(0xFF7C5CFF));
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 26,
            margin: const EdgeInsets.only(top: 1, right: 9),
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      down ? 'Downtime' : 'Bottleneck',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                    ),
                    if (s.reason.isNotEmpty) ...[
                      const Text(
                        '  ·  ',
                        style: TextStyle(fontSize: 9.5, color: newTextHint),
                      ),
                      Expanded(
                        child: Text(
                          s.reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: newTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  [
                    if (s.stagename.isNotEmpty) s.stagename,
                    if (s.itemname.isNotEmpty) s.itemname,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                s.isOngoing ? 'Ongoing' : _mins(s.durationmin),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: s.isOngoing ? const Color(0xFFE5484D) : newTextPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                _when(s.fromtime),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: newTextHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 358 → "5h 58m".
  static String _mins(int m) {
    if (m <= 0) return '—';
    final h = m ~/ 60, r = m % 60;
    return h == 0 ? '${r}m' : (r == 0 ? '${h}h' : '${h}h ${r}m');
  }

  /// "2026-09-21 12:02" → "21 Sep, 12:02", or just the time when it is today.
  static String _when(String ts) {
    final d = DateTime.tryParse(ts.replaceFirst(' ', 'T'));
    if (d == null) return ts;
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay
        ? DateFormat('HH:mm').format(d)
        : DateFormat('d MMM, HH:mm').format(d);
  }

  // ── Shared chrome ──

  Widget _card({
    required VoidCallback onTap,
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
    required Widget child,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: tint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: newTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: newTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: newTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );

  Widget _stat(String label, int value, Color color) =>
      _statText(label, '$value', value > 0 ? color : newTextSecondary);

  Widget _statText(String label, String value, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: newTextSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _strip({
    required IconData icon,
    required Color color,
    required String text,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.25,
            ),
          ),
        ),
      ],
    ),
  );
}
