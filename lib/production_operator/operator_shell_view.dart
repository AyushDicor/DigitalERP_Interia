import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'operator_controller.dart';
import 'operator_job_view.dart';
import 'operator_qc_history_view.dart';
import 'operator_qc_view.dart';
import 'operator_rework_view.dart';
import 'operator_incoming_view.dart';
import 'operator_models.dart';
import 'operator_sendback_view.dart';
import 'operator_stoppage_sheet.dart';
import 'operator_widgets.dart';

/// Entry point of the Production — Operator module (menu tile):
///   Home      running / pending / QC-due counts + today's progress + lists
///   My Work   everything issued to me, newest first
///   QC        lots to check + my QC history (only for QC logins)
///   Log       downtime & bottleneck history
class OperatorShellView extends StatelessWidget {
  const OperatorShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OperatorController());
    return GetBuilder<OperatorController>(
      init: c,
      builder: (ctrl) => Scaffold(
        backgroundColor: opBg,
        body: IndexedStack(
          index: ctrl.tab,
          // Index order is fixed so [OperatorController.logTab] stays valid;
          // the nav bar below shows QC before Log, which is where a QC hand
          // expects it.
          children: const [_HomeTab(), _MyWorkTab(), _LogTab(), _QcTab()],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: newBorderColor)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  _navItem(ctrl, 0, Icons.home_outlined, 'Home'.tr),
                  _navItem(ctrl, 1, Icons.assignment_outlined, 'My Work'.tr),
                  // Only logins the backend flags can check lots, so nobody
                  // else gets a QC tab.
                  if (ctrl.showQcTab)
                    _navItem(
                      ctrl,
                      OperatorController.qcTab,
                      Icons.verified_outlined,
                      'QC'.tr,
                      badge: ctrl.qcDueJobs.length,
                    ),
                  _navItem(ctrl, 2, Icons.report_problem_outlined, 'Log'.tr),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    OperatorController c,
    int i,
    IconData icon,
    String label, {
    int badge = 0,
  }) {
    final on = c.tab == i;
    final color = on ? opPrimary : newTextHint;
    return Expanded(
      child: InkWell(
        onTap: () => c.setTab(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: color),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: opPurple,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _stageLine(OperatorController c) {
  final st = c.myStageName;
  return st.isEmpty ? 'Shop floor' : '${_titleCase(st)} · Shop floor';
}

String _titleCase(String s) => s.isEmpty
    ? s
    : s
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

Widget _loadingOrError(OperatorController c, {required Widget child}) {
  if (c.jobsLoading && c.jobs.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  if (c.jobs.isEmpty) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: c.jobsError.isNotEmpty
          ? c.jobsError
          : 'No jobs issued to you yet.'.tr,
      subtitle:
          'Jobs appear here once the ERP issues a production challan to your employee account.',
      action: 'Refresh'.tr,
      onAction: c.loadJobs,
    );
  }
  return child;
}

// ── 1 · Home ─────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) => Column(
      children: [
        OperatorHeader(
          title: 'Hi, ${c.firstName}',
          subtitle: _stageLine(c),
          avatarLetter: c.firstName.substring(0, 1).toUpperCase(),
          showDate: true,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.loadJobs,
            child: _loadingOrError(
              c,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 24),
                children: [
                  if (c.demoMode) const DemoBanner(),
                  // Type-of-list chips (All · Rework · To do …) — a filter
                  // other than All replaces the dashboard with that list.
                  _workChips(c),
                  const SizedBox(height: 12),
                  if (c.workFilter == 'incoming') ...[
                    if (c.incoming.isEmpty) const _NothingHere(),
                    ...c.incoming.map((cn) => _consignmentCard(c, cn)),
                  ] else if (c.workFilter != 'all') ...[
                    if (c.myWorkList.isEmpty) const _NothingHere(),
                    ...c.myWorkList.map((j) => _workCard(c, j)),
                  ] else ...[
                    // Consignments in transit to me — production at my stage
                    // stays locked until each is accepted.
                    if (c.incoming.isNotEmpty) ...[
                      SectionHeader(
                        'Awaiting receipt'.tr,
                        count: c.incoming.length,
                        trailing: 'See all'.tr,
                        onTrailing: () =>
                            Get.to(() => const OperatorIncomingView()),
                      ),
                      ...c.incoming.map((cn) => _consignmentCard(c, cn)),
                    ],
                    // Work sent BACK to this stage to be fixed. It sits
                    // above the tiles: it blocks another stage's job, so it
                    // is the most urgent thing on the screen.
                    if (c.sendBackJobs.isNotEmpty) ...[
                      SectionHeader(
                        'Sent back to fix'.tr,
                        count: c.sendBackJobs.length,
                      ),
                      ...c.sendBackJobs.map((j) => _sendBackCard(c, j)),
                    ],
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 9,
                      crossAxisSpacing: 9,
                      childAspectRatio: 2.55,
                      children: [
                        KpiTile(
                          icon: Icons.schedule_rounded,
                          color: opAmber,
                          bg: opAmberBg,
                          value: '${c.pendingJobs.length}',
                          label: 'Pending'.tr,
                          onTap: () => c.setTab(1),
                        ),
                        KpiTile(
                          icon: Icons.play_arrow_rounded,
                          color: opBlue,
                          bg: opBlueBg,
                          value: '${c.runningJobs.length}',
                          label: 'Running'.tr,
                          onTap: () => c.setTab(1),
                        ),
                        KpiTile(
                          icon: Icons.verified_outlined,
                          color: opPurple,
                          bg: opPurpleBg,
                          value: '${c.awaitingQcJobs.length}',
                          label: c.hasQcAccess ? 'QC due' : 'Awaiting QC'.tr,
                          onTap: () => c.setTab(1),
                        ),
                        KpiTile(
                          icon: Icons.check_rounded,
                          color: opGreen,
                          bg: opGreenBg,
                          value: '${c.doneJobs.length}',
                          label: 'Done'.tr,
                          onTap: () => c.setTab(1),
                        ),
                      ],
                    ),
                    if (c.workJobs.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      _progressCard(c),
                    ],
                    if (c.runningJobs.isNotEmpty) ...[
                      SectionHeader(
                        'Running now',
                        count: c.runningJobs.length,
                        trailing: 'See all'.tr,
                        onTrailing: () => c.setTab(1),
                      ),
                      ...c.runningJobs
                          .take(3)
                          .map(
                            (j) => JobCard(
                              job: j,
                              onTap: () => _openJob(c, j),
                              fraction: c.jobFraction(j),
                              wipNote: c.wipNote(j),
                              ctaLabel: 'Continue'.tr,
                              onCta: () => _openJob(c, j),
                            ),
                          ),
                    ],
                    // Finished and QC-passed, still waiting to be handed to
                    // the next stage — otherwise invisible under Done.
                    if (c.toIssueJobs.isNotEmpty) ...[
                      SectionHeader(
                        'Ready to issue',
                        count: c.toIssueJobs.length,
                        trailing: '${fmtQty(c.toIssueQty)} pcs',
                      ),
                      ...c.toIssueJobs
                          .take(3)
                          .map(
                            (j) => JobCard(
                              job: j,
                              onTap: () => _openJob(c, j),
                              ctaLabel:
                                  'Issue ${fmtQty(c.pendingIssueQty(j))} →',
                              ctaColor: opGreen,
                              onCta: () => _openJob(c, j),
                              showParty: false,
                            ),
                          ),
                    ],
                    // Lots awaiting QC. "Do QC" only when the backend flagged the
                    // job as QC-able for this login; otherwise status only.
                    if (c.awaitingQcJobs.isNotEmpty) ...[
                      SectionHeader(
                        c.hasQcAccess ? 'Needs QC' : 'Awaiting QC'.tr,
                        count: c.awaitingQcJobs.length,
                      ),
                      ...c.awaitingQcJobs
                          .take(2)
                          .map(
                            (j) => JobCard(
                              job: j,
                              onTap: () => _openJob(c, j),
                              ctaLabel: j.canqc ? 'Do QC' : null,
                              ctaColor: opPurple,
                              onCta: j.canqc ? () => _openQc(c, j) : null,
                              showParty: false,
                            ),
                          ),
                    ],
                    if (c.reworkJobs.isNotEmpty) ...[
                      SectionHeader('Rework'.tr, count: c.reworkJobs.length),
                      ...c.reworkJobs.map(
                        (j) => ReworkJobCard(
                          job: j,
                          onTap: () => _openRework(c, j),
                        ),
                      ),
                    ],
                    if (c.pendingJobs.isNotEmpty) ...[
                      SectionHeader('Pending'.tr, count: c.pendingJobs.length),
                      ...c.pendingJobs
                          .take(3)
                          .map(
                            (j) => JobCard(
                              job: j,
                              onTap: () => _openJob(c, j),
                              fraction: c.jobFraction(j),
                              wipNote: c.wipNote(j),
                              ctaLabel: 'Start'.tr,
                              ctaColor: null,
                              onCta: () => _openJob(c, j),
                            ),
                          ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _progressCard(OperatorController c) => Container(
    padding: const EdgeInsets.all(13),
    decoration: opCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Overall progress",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: newTextPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${c.overallPct.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: opPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ThinBar(c.overallPct / 100, height: 9, gradient: opGradient),
        const SizedBox(height: 10),
        Row(
          children: [
            _legend(opPrimary, 'Produced'.tr, fmtQty(c.totalProduced)),
            const SizedBox(width: 14),
            _legend(newBorderColor, 'Issued'.tr, fmtQty(c.totalIssued)),
            const SizedBox(width: 14),
            _legend(opGreen, 'QC passed'.tr, fmtQty(c.totalQcPassed)),
          ],
        ),
      ],
    ),
  );

  Widget _legend(Color dot, String label, String v) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        '$label ',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: newTextSecondary,
        ),
      ),
      Text(
        v,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: newTextPrimary,
        ),
      ),
    ],
  );
}

void _openJob(OperatorController c, OperatorJob j) {
  // A QC assignment has nothing to produce — go straight to the QC screen.
  // Except when the stage records parts: there the check is per part, and
  // the server refuses an item-level QC without a partid. Those open the
  // workspace, where the part cards carry their own QC buttons.
  if (j.isQcJob && !j.isPartMode) {
    _openQc(c, j);
    return;
  }
  // Rework: the dedicated re-produce screen, not the full workspace.
  if (j.isReworkJob) {
    _openRework(c, j);
    return;
  }
  c.openJob(j);
  Get.to(() => const OperatorJobView());
}

void _openRework(OperatorController c, OperatorJob j) {
  c.openRework(j);
  Get.to(() => const OperatorReworkView());
}

/// One card for any job in a filtered list: rework card, QC lot (Do QC) or
/// production job (Start / Continue).
Widget _workCard(OperatorController c, OperatorJob j) {
  if (j.isSendBack) return _sendBackCard(c, j);
  if (j.isReworkJob) {
    return ReworkJobCard(job: j, onTap: () => _openRework(c, j));
  }
  // QC-passed and still here: the useful action is the hand-off, not
  // "Continue" on a job whose balance is already 0.
  if (c.readyToIssue(j) && !j.canqc) {
    return JobCard(
      job: j,
      onTap: () => _openJob(c, j),
      ctaLabel: 'Issue ${fmtQty(c.pendingIssueQty(j))} →',
      ctaColor: opGreen,
      onCta: () => _openJob(c, j),
    );
  }
  // A packing job never says "Start production" — the operator packs.
  // A packing job ALWAYS offers Pack, whatever its produced/balance figures
  // say. Pieces made here with the old Produce button still have to be given
  // boxes: every live PACKING row reads "Done, balance 0" while `topack` is
  // 1 or 2. Only `pack/job` knows what is left, and that is a per-item call —
  // so the button opens the screen and the screen states the truth.
  if (j.isPackStage) {
    final left = c.packLeftFor(j);
    return JobCard(
      job: j,
      onTap: () => _openJob(c, j),
      // Once the background probe answers, say how many are still to box —
      // the card's own numbers cannot show it.
      wipNote: left == null ? '' : '${fmtQty(left)} to pack',
      ctaLabel: left == null ? 'Pack' : 'Pack ${fmtQty(left)}',
      ctaColor: opGreen,
      onCta: () => _openJob(c, j),
    );
  }
  final qc = j.canqc && j.qcPending > 0;
  // Nothing to start on a joining stage that is short of parts — the card
  // still opens, so the operator can see which stage they are waiting on.
  if (j.isWaitingForParts) {
    return JobCard(job: j, onTap: () => _openJob(c, j));
  }
  return JobCard(
    job: j,
    onTap: () => _openJob(c, j),
    fraction: qc ? null : c.jobFraction(j),
    wipNote: qc ? '' : c.wipNote(j),
    highlight: j.isPending && !j.isRework,
    ctaLabel: qc
        ? 'Do QC'
        : j.isDone
        ? null
        : (j.isPending ? 'Start production' : 'Continue'.tr),
    ctaColor: qc ? opPurple : null,
    onCta: qc ? () => _openQc(c, j) : () => _openJob(c, j),
  );
}

/// A send back leg. Each button is offered only when the server says there
/// is qty for it, and QC only on a login the server flagged `canqc` — the
/// operator must never check the piece they just reworked.
Widget _sendBackCard(OperatorController c, OperatorJob j) => SendBackJobCard(
  job: j,
  onTap: () => _openJob(c, j),
  onRework: j.canReworkHere ? () => _openJob(c, j) : null,
  onQc: j.canQcHere ? () => _openQc(c, j) : null,
  onSendOn: j.canSendOn ? () => _openJob(c, j) : null,
);

Widget _consignmentCard(OperatorController c, Consignment cn) => Builder(
  builder: (ctx) => ConsignmentCard(
    cn: cn,
    onReceive: () => Get.to(() => OperatorReceiveView(cn: cn)),
    onReject: () => rejectConsignment(ctx, c, cn),
  ),
);

class _NothingHere extends StatelessWidget {
  const _NothingHere();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        'Nothing here.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: newTextHint,
        ),
      ),
    ),
  );
}

/// Filter chips (Home + My Work). Only chips with something behind them are
/// shown (plus All), each with its count.
Widget _workChips(OperatorController c) {
  final chips = <(String, String, int, Color)>[
    ('all', 'All'.tr, c.workJobs.length + c.qcDueJobs.length, opPrimary),
    if (c.qcDueJobs.isNotEmpty) ('qc', 'QC'.tr, c.qcDueJobs.length, opPurple),
    if (c.toIssueJobs.isNotEmpty)
      ('toissue', 'To issue'.tr, c.toIssueJobs.length, opGreen),
    if (c.incoming.isNotEmpty)
      ('incoming', 'Incoming'.tr, c.incoming.length, opGreen),
    if (c.reworkJobs.isNotEmpty)
      ('rework', 'Rework'.tr, c.reworkJobs.length, opAmber),
    if (c.pendingJobs.isNotEmpty)
      ('todo', 'To do'.tr, c.pendingJobs.length, opPrimary),
    if (c.runningJobs.isNotEmpty)
      ('running', 'Running'.tr, c.runningJobs.length, opBlue),
    if (c.doneJobs.isNotEmpty) ('done', 'Done'.tr, c.doneJobs.length, opGreen),
  ];
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (key, label, n, color) in chips) ...[
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () => c.setWorkFilter(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: c.workFilter == key ? color : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: c.workFilter == key ? color : newBorderColor,
                ),
              ),
              child: Text(
                '$label · $n',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: c.workFilter == key ? Colors.white : newTextSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
        ],
      ],
    ),
  );
}

void _openQc(OperatorController c, OperatorJob j) {
  // A stage that records its parts is QC'd part by part: the server refuses
  // an item-level QC there ("QC each part (send partid)"). Every Do-QC entry
  // point comes through here, so the redirect lives here rather than at each
  // button.
  if (j.isPartMode) {
    c.openJob(j);
    Get.to(() => const OperatorJobView());
    return;
  }
  c.openQc(j);
  Get.to(() => const OperatorQcView());
}

// ── 2 · My Work ──────────────────────────────────────────────────────────────

class _MyWorkTab extends StatelessWidget {
  const _MyWorkTab();

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) => Column(
      children: [
        OperatorHeader(
          title: 'My Work'.tr,
          subtitle: _stageLine(c),
          avatarLetter: c.firstName.substring(0, 1).toUpperCase(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.loadJobs,
            child: _loadingOrError(
              c,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 24),
                children: [
                  if (c.demoMode) const DemoBanner(),
                  Row(
                    children: [
                      Expanded(
                        child: StatBox(
                          value: '${c.pendingJobs.length}',
                          label: 'To do'.tr,
                          color: opPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatBox(
                          value: '${c.runningJobs.length}',
                          label: 'Running'.tr,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatBox(
                          value: '${c.doneJobs.length}',
                          label: 'Done'.tr,
                        ),
                      ),
                    ],
                  ),
                  SectionHeader(
                    'Issued to me',
                    trailing: DateFormat('d MMM').format(DateTime.now()),
                  ),
                  // Filter chips (per backend UI): All · Rework · To do · …
                  _workChips(c),
                  const SizedBox(height: 10),
                  if (c.workFilter == 'incoming') ...[
                    if (c.incoming.isEmpty) const _NothingHere(),
                    ...c.incoming.map((cn) => _consignmentCard(c, cn)),
                  ] else ...[
                    if (c.workFilter == 'all')
                      ...c.incoming.map((cn) => _consignmentCard(c, cn)),
                    if (c.myWorkList.isEmpty && c.incoming.isEmpty)
                      const _NothingHere(),
                    ...c.myWorkList.map((j) => _workCard(c, j)),
                  ],
                  if (c.myStageName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    HintBox([
                      const TextSpan(text: 'You see '),
                      TextSpan(
                        text: 'only ${_titleCase(c.myStageName)}',
                        style: hintBold,
                      ),
                      const TextSpan(
                        text:
                            ' of each item. Other stages go to their own operators.',
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── 3 · Quality Check ────────────────────────────────────────────────────────

/// Two panes for the QC hand: the lots waiting to be checked, and every check
/// they have already saved. Shown when [OperatorController.showQcTab].
class _QcTab extends StatelessWidget {
  const _QcTab();

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) => Column(
      children: [
        OperatorHeader(
          title: 'Quality Check'.tr,
          subtitle: c.session.name.trim().isEmpty
              ? 'QC'
              : '${c.session.name.trim()} · QC',
          avatarLetter: c.firstName.substring(0, 1).toUpperCase(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 2),
          child: _qcPaneSwitch(c),
        ),
        Expanded(
          child: c.qcPane == 0 ? const _ToQcPane() : const QcHistoryPane(),
        ),
      ],
    ),
  );

  Widget _qcPaneSwitch(OperatorController c) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: newBorderColor),
    ),
    child: Row(
      children: [
        for (final (i, label) in [
          (0, 'To QC · ${c.qcDueJobs.length}'),
          (1, 'My history'),
        ])
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => c.setQcPane(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: c.qcPane == i ? opPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.qcPane == i ? Colors.white : newTextSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Lots produced and waiting for this QC hand to check them.
class _ToQcPane extends StatelessWidget {
  const _ToQcPane();

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      if (c.jobsLoading && c.jobs.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final lots = c.qcDueJobs;
      return RefreshIndicator(
        onRefresh: c.loadJobs,
        child: lots.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Nothing waiting for QC',
                    subtitle:
                        'Lots appear here as soon as an operator records what '
                        'they produced.',
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 24),
                children: [
                  if (c.demoMode) const DemoBanner(),
                  SectionHeader('Waiting for you', count: lots.length),
                  ...lots.map(
                    (j) => JobCard(
                      job: j,
                      onTap: () => _openQc(c, j),
                      ctaLabel: 'Do QC'.tr,
                      ctaColor: opPurple,
                      onCta: () => _openQc(c, j),
                      showParty: false,
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

// ── 4 · Downtime / bottleneck log ────────────────────────────────────────────

class _LogTab extends StatelessWidget {
  const _LogTab();

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) => Scaffold(
      backgroundColor: opBg,
      body: Column(
        children: [
          OperatorHeader(
            title: 'Downtime & Bottlenecks',
            subtitle: _stageLine(c),
            avatarLetter: '!',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 0),
            child: Row(
              children: [
                _chip(c, '', 'All'.tr),
                const SizedBox(width: 8),
                _chip(c, 'Downtime'.tr, 'Downtime'.tr, color: opRed),
                const SizedBox(width: 8),
                _chip(c, 'Bottleneck'.tr, 'Bottleneck'.tr, color: opAmber),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.loadStoppages,
              child: c.stoppagesLoading && c.stoppages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : c.visibleStoppages.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.report_problem_outlined,
                          title: 'No stoppages logged',
                          subtitle:
                              'Log downtime or a bottleneck from a job, or with the + button.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(13, 12, 13, 90),
                      children: [
                        if (c.demoMode) const DemoBanner(),
                        ...c.visibleStoppages.map(_row),
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: opPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Log'.tr, style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: () => _pickType(context, c),
      ),
    ),
  );

  void _pickType(BuildContext context, OperatorController c) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: newBorderColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 14),
            _typeRow(
              Icons.error_outline_rounded,
              opRed,
              opRedBg,
              'Log downtime',
              'Machine breakdown, power cut, no operator…',
              () {
                Get.back();
                showStoppageSheet(context, c, downtime: true);
              },
            ),
            const SizedBox(height: 10),
            _typeRow(
              Icons.warning_amber_rounded,
              opAmber,
              opAmberBg,
              'Flag bottleneck',
              'Waiting for material, previous stage, QC…',
              () {
                Get.back();
                showStoppageSheet(context, c, downtime: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeRow(
    IconData icon,
    Color color,
    Color bg,
    String title,
    String sub,
    VoidCallback onTap,
  ) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11, color: newTextSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color),
        ],
      ),
    ),
  );

  Widget _chip(
    OperatorController c,
    String value,
    String label, {
    Color color = opPrimary,
  }) {
    final on = c.stoppageFilter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => c.setStoppageFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: on ? color : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: on ? color : newBorderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : newTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _row(Stoppage s) {
    final dt = s.isDowntime;
    final color = dt ? opRed : opAmber;
    final bg = dt ? opRedBg : opAmberBg;
    final time = [
      if (s.fromtime.isNotEmpty) _hm(s.fromtime),
      if (s.totime.isNotEmpty) _hm(s.totime),
    ].join(' → ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: opCard(radius: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              dt ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.reason,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: newTextPrimary,
                        ),
                      ),
                    ),
                    if (s.durationmin > 0)
                      SoftPill('${s.durationmin} min', color: color, bg: bg),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    s.type,
                    if (s.stagename.isNotEmpty) _titleCase(s.stagename),
                    if (time.isNotEmpty) time,
                    if (s.fromtime.isNotEmpty)
                      _date(s.fromtime)
                    else if (s.createdon.isNotEmpty)
                      _date(s.createdon),
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
                if (s.itemname.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    s.itemname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: newTextHint,
                    ),
                  ),
                ],
                if (s.remarks.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    s.remarks,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: newTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _hm(String s) {
    final d = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    return d == null ? s : DateFormat('HH:mm').format(d);
  }

  static String _date(String s) {
    final d = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    return d == null ? '' : DateFormat('d MMM').format(d);
  }
}
