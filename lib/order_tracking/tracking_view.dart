// Order Production Tracking — the three tabs from the mockup:
//   Overview  KPI cards · order/item pickers · summary ring · stage pipeline
//   Activity  search + stage/person filters, timeline or table, photos
//   People    who did what · stage completion · export CSV
//
// Everything is read-only; nothing here writes to the ERP.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'tracking_controller.dart';
import 'tracking_models.dart';
import 'tracking_pickers.dart';
import 'tracking_widgets.dart';

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(TrackingController());
    return GetBuilder<TrackingController>(
      init: c,
      builder: (ctrl) => Scaffold(
        backgroundColor: trkBg,
        body: Column(
          children: [
            TrackHeader(
              title: switch (ctrl.tab) {
                1 => 'Activity trail',
                2 => 'People & stages',
                _ => 'Order Production Tracking',
              },
              subtitle: switch (ctrl.tab) {
                0 => 'Who did what, on which item, and when',
                _ =>
                  ctrl.item == null
                      ? 'Select an item'
                      : '${ctrl.item!.itemname} · ${ctrl.order?.orderno ?? ''}',
              },
              meta: ctrl.tab == 0 ? _headerMeta(ctrl) : null,
              action: ctrl.tab == 2 || ctrl.item == null
                  ? null
                  : _HeaderIcon(
                      icon: Icons.file_download_outlined,
                      busy: ctrl.exporting,
                      onTap: ctrl.exportCsv,
                    ),
            ),
            if (ctrl.tab == 1) _searchBar(ctrl),
            Expanded(
              child: RefreshIndicator(
                onRefresh: ctrl.load,
                child: _body(context, ctrl),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _bottomNav(ctrl),
      ),
    );
  }

  static String _headerMeta(TrackingController c) {
    final party = c.order?.partyname ?? '';
    return party.isEmpty
        ? 'UK INTERIA · Interia Factory'
        : '${c.order?.orderno ?? ''} · $party';
  }

  Widget _body(BuildContext context, TrackingController c) {
    if (c.loading && c.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.orders.isEmpty) {
      return ListView(
        children: [
          TrkEmpty(
            icon: Icons.inventory_2_outlined,
            title: c.error.isNotEmpty ? c.error : 'No orders in production.',
            subtitle:
                'Orders appear here once production challans are issued for them.',
          ),
        ],
      );
    }
    return switch (c.tab) {
      1 => _ActivityTab(c: c),
      2 => _PeopleTab(c: c),
      _ => _OverviewTab(c: c),
    };
  }

  // ── Activity search bar (sits under the dark header) ──
  Widget _searchBar(TrackingController c) => Container(
    color: trkHeader,
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: TextField(
      controller: c.searchCtrl,
      onChanged: c.onSearchChanged,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search stage, person, remark…',
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 19,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        suffixIcon: c.searchCtrl.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: c.clearSearch,
              ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _bottomNav(TrackingController c) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE8EAF4))),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _navItem(c, 0, Icons.show_chart_rounded, 'Overview'),
            _navItem(c, 1, Icons.schedule_rounded, 'Activity'),
            _navItem(c, 2, Icons.people_alt_outlined, 'People'),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(TrackingController c, int i, IconData icon, String label) {
    final on = c.tab == i;
    final color = on ? trkViolet : newTextHint;
    return Expanded(
      child: InkWell(
        onTap: () => c.setTab(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
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

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;
  const _HeaderIcon({
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(11),
    onTap: busy ? null : onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: trkViolet,
        borderRadius: BorderRadius.circular(11),
      ),
      child: busy
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Icon(icon, color: Colors.white, size: 19),
    ),
  );
}

// ── 1 · Overview ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final TrackingController c;
  const _OverviewTab({required this.c});

  @override
  Widget build(BuildContext context) {
    final k = c.kpis;
    final d = c.detail;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        // A line that is stopped right now outranks everything else on this
        // screen, so it sits above the KPI cards.
        if (c.ongoingStoppages.isNotEmpty) ...[
          _stoppageAlert(c),
          const SizedBox(height: 12),
        ],
        if (k != null) ...[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              KpiCard(
                icon: Icons.home_work_outlined,
                color: trkViolet,
                bg: trkVioletBg,
                title: 'Orders in production',
                value: '${k.ordersInProd}',
                caption: 'active across stages',
              ),
              KpiCard(
                icon: Icons.auto_awesome_outlined,
                color: trkAmber,
                bg: const Color(0xFFFDF1DD),
                title: 'Items in progress',
                value: '${k.itemsInProgress}',
                caption: 'being produced',
              ),
              KpiCard(
                icon: Icons.bar_chart_rounded,
                color: trkGreen,
                bg: trkGreenBg,
                title: 'Entries today',
                value: '${k.entriesToday}',
                caption: 'produce · QC · hand-off',
              ),
              KpiCard(
                icon: Icons.verified_outlined,
                color: trkBlue,
                bg: trkBlueBg,
                title: 'QC pass rate',
                value: k.qcPassRate == null ? '—' : '${k.qcPassRate!.round()}%',
                caption: 'passed vs rejected',
              ),
            ],
          ),
          const SizedBox(height: 10),
          KpiCard(
            icon: Icons.schedule_rounded,
            color: trkRed,
            bg: trkRedBg,
            title: 'Overdue orders',
            value: '${k.overdueOrders}',
            caption: 'past delivery date',
          ),
          const SizedBox(height: 14),
        ],
        _pickerRow(
          context,
          'Order',
          c.order == null
              ? 'Select order'
              : '${c.order!.orderno} — ${c.order!.partyname}',
        ),
        const SizedBox(height: 10),
        _pickerRow(context, 'Item', c.item?.itemname ?? 'Select item'),
        const SizedBox(height: 14),
        if (c.detailLoading && d == null)
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (d != null) ...[
          _summaryCard(d),
          const SizedBox(height: 14),
          _waitBanner(d),
          _pipelineCard(d),
          _subItemsCard(d),
          if (c.itemStoppages.isNotEmpty) ...[
            const SizedBox(height: 14),
            _itemStoppages(c),
          ],
        ],
      ],
    );
  }

  /// Red banner listing every line that is stopped at this moment.
  Widget _stoppageAlert(TrackingController c) {
    final list = c.ongoingStoppages;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 6),
      decoration: BoxDecoration(
        color: trkRedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: trkRed.withValues(alpha: 0.45), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_rounded, size: 18, color: trkRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  list.length == 1
                      ? 'Production stopped at 1 stage'
                      : 'Production stopped at ${list.length} stages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: trkRed,
                  ),
                ),
              ),
              const TrkPill('NOW', fg: Colors.white, bg: trkRed),
            ],
          ),
          const SizedBox(height: 4),
          ...list.map(
            (s) => InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => c.focusStoppage(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.stagename} · ${s.reason}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: trkInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.itemname}${s.startTime.isNotEmpty ? ' · since ${s.startTime}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: newTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: trkRed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Downtime / bottleneck history of the item being looked at.
  Widget _itemStoppages(TrackingController c) {
    final list = c.itemStoppages;
    final lost = c.itemLostMinutes;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: trkCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Downtime & bottlenecks',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                  ),
                ),
              ),
              if (lost > 0)
                TrkPill(
                  lost >= 60
                      ? '${lost ~/ 60}h ${lost % 60}m lost'
                      : '${lost}m lost',
                  fg: trkRed,
                  bg: trkRedBg,
                ),
            ],
          ),
          const SizedBox(height: 4),
          ...list.map(_stoppageRow),
        ],
      ),
    );
  }

  Widget _pickerRow(BuildContext context, String label, String value) =>
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showOrderPicker(context, c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: trkCard(radius: 14),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: newTextHint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                    height: 1.25,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: newTextSecondary,
              ),
            ],
          ),
        ),
      );

  Widget _summaryCard(TrackDetail d) => Container(
    padding: const EdgeInsets.all(14),
    decoration: trkCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${c.order?.orderno ?? ''} · ${c.order?.partyname ?? ''}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: trkInk,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ordered ${c.order?.orderdate ?? '—'} · Delivery '
          '${c.order?.deliverydate ?? '—'} · ${c.order?.items ?? 0} item(s)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: newTextSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            PctRing(pct: d.summary.completionpct),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stat(_n(d.summary.ordered), 'Ordered'),
                  _stat(_n(d.summary.output), 'Output'),
                  _stat(_n(d.summary.qc), 'QC'),
                  _stat('${d.summary.stages}', 'Stages'),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: trkInk,
          height: 1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: newTextSecondary,
        ),
      ),
    ],
  );

  Widget _pipelineCard(TrackDetail d) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
    decoration: trkCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Stage pipeline',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: trkInk,
                ),
              ),
            ),
            if (d.route.branched) ...[
              const TrkPill('Parallel route', fg: trkBlue, bg: trkBlueBg),
              const SizedBox(width: 6),
            ],
            TrkPill(
              '${d.summary.completionpct}%',
              fg: trkViolet,
              bg: trkVioletBg,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stages that run side by side cannot be drawn as a stepper — it
        // would imply an order the plan does not have.
        if (d.route.branched)
          _groupedPipeline(d)
        else
          for (var i = 0; i < d.pipeline.length; i++)
            _step(d.pipeline[i], last: i == d.pipeline.length - 1),
      ],
    ),
  );

  Widget _step(PipelineStage s, {required bool last}) {
    final tone = s.isDone
        ? (fg: trkGreen, bg: trkGreenBg)
        : s.isRework
        // Work sent back to be re-made — not done, not merely pending.
        ? (fg: trkOrangeText, bg: trkOrangeBg)
        : s.isActive
        ? (fg: trkViolet, bg: trkVioletBg)
        : (fg: trkGray, bg: trkGrayBg);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: s.isDone
                      ? const Color(0xFF16A34A)
                      : s.isRework
                      ? trkOrange
                      : tone.bg,
                  shape: BoxShape.circle,
                ),
                child: s.isDone
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : Text(
                        '${s.step}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          // White on the solid amber dot.
                          color: s.isRework ? Colors.white : tone.fg,
                        ),
                      ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: s.isDone
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE8EAF4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 10 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.stagename,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: trkInk,
                          ),
                        ),
                      ),
                      // "Rework 1" says how much has to be re-made, which is
                      // the number the supervisor is looking for.
                      _statePill(s, tone),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.operatorname.isEmpty ? '—' : s.operatorname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: newTextSecondary,
                          ),
                        ),
                      ),
                      // good / planned · QC n · Rej n — rejected work does
                      // not count towards the stage being finished.
                      Text(
                        s.qtyLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: s.reject > 0
                              ? trkOrangeText
                              : newTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Planned dates arrive on a routed challan even when it is
                  // not branched; they are simply absent on an old one.
                  if (s.startslabel.isNotEmpty || s.dueLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _startsAndDue(s, tight: false),
                  ],
                  if (s.parts.isNotEmpty) _partsBlock(s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Parallel route ────────────────────────────────────────────────────────

  /// One amber line per joining stage that is short of parts. The server
  /// writes the sentence, so nothing is assembled here.
  Widget _waitBanner(TrackDetail d) {
    if (d.waitnotes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          for (final note in d.waitnotes)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              decoration: BoxDecoration(
                color: trkOrangeBg,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: trkOrange.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: trkOrangeText,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: trkOrangeText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Stages grouped into steps. Everything in one column runs at the same
  /// time, so a step with two stages draws them side by side rather than one
  /// after the other — the stepper would otherwise imply an order that the
  /// plan does not have.
  Widget _groupedPipeline(TrackDetail d) {
    final byColumn = <int, List<PipelineStage>>{};
    for (final s in d.pipeline) {
      byColumn.putIfAbsent(s.column, () => []).add(s);
    }
    final columns = byColumn.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns.length; i++) ...[
          _stepHeader(i + 1, byColumn[columns[i]]!.length),
          const SizedBox(height: 8),
          _stepRow(byColumn[columns[i]]!),
          if (i < columns.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 9),
              child: Center(
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 17,
                  color: Color(0xFF9AA0BB),
                ),
              ),
            ),
        ],
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _stepHeader(int n, int count) => Text(
    count > 1 ? 'STEP $n · $count STAGES RUN TOGETHER' : 'STEP $n',
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.7,
      color: newTextSecondary,
    ),
  );

  /// One stage full width; two or more in pairs.
  Widget _stepRow(List<PipelineStage> stages) {
    if (stages.length == 1) return _stageCard(stages.first);
    final rows = <Widget>[];
    for (var i = 0; i < stages.length; i += 2) {
      final pair = stages.skip(i).take(2).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < stages.length ? 8 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _stageCard(pair.first, tight: true)),
              const SizedBox(width: 8),
              if (pair.length > 1)
                Expanded(child: _stageCard(pair[1], tight: true))
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  /// A stage as a card (used by the grouped layout). [tight] is the 2-up
  /// version, where the operator name and the qty stack instead of sitting
  /// on one line.
  Widget _stageCard(PipelineStage s, {bool tight = false}) {
    final tone = _stageTone(s);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tone.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: s.isWaiting
              ? trkOrange.withValues(alpha: 0.5)
              : tone.fg.withValues(alpha: 0.25),
          width: s.isWaiting ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.stagename,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                  ),
                ),
              ),
              if (!tight) ...[const SizedBox(width: 8), _statePill(s, tone)],
            ],
          ),
          if (tight) ...[const SizedBox(height: 5), _statePill(s, tone)],
          const SizedBox(height: 5),
          if (tight) ...[
            Text(
              s.operatorname.isEmpty ? '—' : s.operatorname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              s.qtyLabel,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: newTextSecondary,
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.operatorname.isEmpty ? '—' : s.operatorname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: newTextSecondary,
                    ),
                  ),
                ),
                Text(
                  s.qtyLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.reject > 0 ? trkOrangeText : newTextSecondary,
                  ),
                ),
              ],
            ),
          if (s.startslabel.isNotEmpty || s.dueLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            _startsAndDue(s, tight: tight),
          ],
          if (s.nextstages.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '→ ${s.nextstages}',
              maxLines: 2,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: tone.fg,
              ),
            ),
          ],
          if (s.parts.isNotEmpty) _partsBlock(s),
        ],
      ),
    );
  }

  Widget _startsAndDue(PipelineStage s, {required bool tight}) {
    final due = s.dueLabel;
    final dueStyle = TextStyle(
      fontSize: 10.5,
      fontWeight: s.overdue ? FontWeight.w800 : FontWeight.w600,
      color: s.overdue ? trkRed : newTextSecondary,
    );
    if (tight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.startslabel.isNotEmpty)
            Text(
              s.startslabel,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),
          if (due.isNotEmpty) Text(due, style: dueStyle),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            s.startslabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
            ),
          ),
        ),
        if (due.isNotEmpty) Text(due, style: dueStyle),
      ],
    );
  }

  /// What a joining stage can build now, and where each part has got to.
  Widget _partsBlock(PipelineStage s) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 9),
      Container(height: 1, color: trkOrange.withValues(alpha: 0.25)),
      const SizedBox(height: 8),
      Text(
        'Can make now: ${_n(s.canmake)}',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: trkInk,
        ),
      ),
      const SizedBox(height: 6),
      for (final p in s.parts) _partRow(p),
    ],
  );

  Widget _partRow(StagePart p) {
    final tone = _partTone(p.tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: tone.bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: tone.fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              p.stagename,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: trkInk,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                p.text,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: tone.fg,
                  height: 1.3,
                ),
              ),
            ),
            if (p.waitingfor) ...[
              const SizedBox(width: 6),
              Text(
                'WAITING',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: tone.fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statePill(PipelineStage s, ({Color bg, Color fg}) tone) => TrkPill(
    s.isRework && s.rework > 0
        ? '${s.statelabel} ${_n(s.rework)}'
        : s.statelabel,
    fg: tone.fg,
    bg: tone.bg,
    icon: s.isWaiting ? Icons.lock_outline_rounded : null,
  );

  ({Color bg, Color fg}) _stageTone(PipelineStage s) => s.isDone
      ? (fg: trkGreen, bg: trkGreenBg)
      : s.isWaiting
      ? (fg: trkOrangeText, bg: trkOrangeBg)
      : s.isRework
      ? (fg: trkOrangeText, bg: trkOrangeBg)
      : s.isActive
      ? (fg: trkViolet, bg: trkVioletBg)
      : (fg: trkGray, bg: trkGrayBg);

  /// The API's part tone. Amber uses the darker text colour, not [trkAmber],
  /// which is too light to read at this size.
  ({Color bg, Color fg}) _partTone(String tone) => switch (tone.toLowerCase()) {
    'green' => (fg: trkGreen, bg: trkGreenBg),
    'blue' => (fg: trkBlue, bg: trkBlueBg),
    'amber' => (fg: trkOrangeText, bg: trkOrangeBg),
    _ => (fg: trkGray, bg: trkGrayBg),
  };

  /// Parts card: one block per part, showing where it has got to along its
  /// own route. Only the stages a part actually passes through get a line —
  /// the wide grid in the mockup is a tablet layout; on a phone a row of
  /// five columns would be unreadable.
  Widget _subItemsCard(TrackDetail d) {
    if (d.subitemgrid.isEmpty) return const SizedBox.shrink();
    final stagenames = d.pipeline.map((p) => p.stagename).toList();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: trkCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parts'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                  ),
                ),
              ),
              TrkPill(
                '${d.subitemgrid.length} per piece',
                fg: trkViolet,
                bg: trkVioletBg,
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final row in d.subitemgrid) _subItemRow(row, stagenames),
        ],
      ),
    );
  }

  Widget _subItemRow(SubItemGridRow row, List<String> stagenames) {
    final steps = row.steps(stagenames);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  row.partname,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '×${_n(row.qtyperpiece)} per piece',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
          if (row.path.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              row.path,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: newTextHint,
              ),
            ),
          ],
          const SizedBox(height: 7),
          for (final (stagename, cell) in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      stagename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: newTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _partTone(cell.tone).bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cell.text,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _partTone(cell.tone).fg,
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
  }
}

// ── 2 · Activity ────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final TrackingController c;
  const _ActivityTab({required this.c});

  @override
  Widget build(BuildContext context) {
    final d = c.detail;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _dropdown(
                context,
                value: c.stage,
                hint: 'All stages',
                options: d?.stages ?? const [],
                onPick: c.setStage,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _dropdown(
                context,
                value: c.person,
                hint: 'Everyone',
                options: d?.persons ?? const [],
                onPick: c.setPerson,
              ),
            ),
            const SizedBox(width: 9),
            _viewToggle(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${d?.trailcount ?? 0} entries · newest first',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: newTextSecondary,
                ),
              ),
            ),
            if (c.hasFilters)
              InkWell(
                onTap: c.clearFilters,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: trkViolet,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // The trail comes from the produce / QC / hand-off ledger, which has
        // no stoppages in it — surface them here so "what happened on this
        // item" is complete.
        if (c.itemStoppages.isNotEmpty && !c.hasFilters) ...[
          ...c.itemStoppages.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              decoration: trkCard(
                radius: 14,
                border: toneColors(s.tone).fg.withValues(alpha: 0.4),
              ),
              child: _stoppageRow(s),
            ),
          ),
          const SizedBox(height: 2),
        ],
        if (c.detailLoading)
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (d == null || d.trailcount == 0)
          TrkEmpty(
            icon: Icons.history_rounded,
            title: c.hasFilters
                ? 'Nothing matches these filters.'
                : 'No activity recorded for this item yet.',
            subtitle: c.hasFilters
                ? 'Clear the stage, person or search filter to see everything.'
                : 'Produce, QC and hand-off events appear here as they happen.',
          )
        else if (c.tableView)
          _table(d)
        else
          ...d.trail.map(_day),
      ],
    );
  }

  Widget _viewToggle() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFE8EAF4)),
    ),
    child: Row(
      children: [
        _toggleBtn(
          Icons.view_list_rounded,
          !c.tableView,
          () => c.setTableView(false),
        ),
        _toggleBtn(
          Icons.grid_on_rounded,
          c.tableView,
          () => c.setTableView(true),
        ),
      ],
    ),
  );

  Widget _toggleBtn(IconData icon, bool on, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 40,
      decoration: BoxDecoration(
        color: on ? trkVioletBg : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 17, color: on ? trkViolet : newTextHint),
    ),
  );

  Widget _dropdown(
    BuildContext context, {
    required String value,
    required String hint,
    required List<String> options,
    required void Function(String) onPick,
  }) => InkWell(
    borderRadius: BorderRadius.circular(11),
    onTap: options.isEmpty
        ? null
        : () async {
            final picked = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        dense: true,
                        title: Text(
                          hint,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: value.isEmpty
                            ? const Icon(
                                Icons.check_rounded,
                                color: trkViolet,
                                size: 19,
                              )
                            : null,
                        onTap: () => Navigator.of(ctx).pop(''),
                      ),
                      const Divider(height: 1),
                      ...options.map(
                        (o) => ListTile(
                          dense: true,
                          title: Text(
                            o,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: value == o
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: trkViolet,
                                  size: 19,
                                )
                              : null,
                          onTap: () => Navigator.of(ctx).pop(o),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            if (picked != null) onPick(picked);
          },
    child: Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: value.isEmpty ? const Color(0xFFE8EAF4) : trkViolet,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? hint : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: value.isEmpty ? newTextSecondary : trkViolet,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: value.isEmpty ? newTextSecondary : trkViolet,
          ),
        ],
      ),
    ),
  );

  Widget _day(TrailDay day) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                day.daylabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: trkGray,
                ),
              ),
            ),
            Text(
              '${day.count} ${day.count == 1 ? 'entry' : 'entries'}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: newTextHint,
              ),
            ),
          ],
        ),
      ),
      ...day.entries.map(_entryCard),
    ],
  );

  Widget _entryCard(TrailEntry e) {
    final t = toneColors(e.tone);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: trkCard(radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(eventIcon(e.eventtype), size: 17, color: t.fg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: e.eventlabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: trkInk,
                              ),
                              children: [
                                TextSpan(
                                  text: e.flow.isNotEmpty
                                      ? '  · ${e.stagename} ${e.flow}'
                                      : '  · ${e.stagename}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: newTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.time,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: newTextHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        InitialsAvatar(e.initials, size: 22),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            e.operator,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: trkInk,
                            ),
                          ),
                        ),
                        if (e.qty > 0) TrkPill(e.qtyLabel, fg: t.fg, bg: t.bg),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (e.remarks.isNotEmpty || e.loadername.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              [
                if (e.remarks.isNotEmpty) e.remarks,
                if (e.loadername.isNotEmpty) 'Loader: ${e.loadername}',
              ].join(' · '),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (e.photos.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: e.photos.map(_thumb).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _thumb(String url) => Builder(
    builder: (ctx) => InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Get.to(() => _PhotoViewer(url)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 62,
          height: 62,
          color: trkGrayBg,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, color: newTextHint),
          ),
        ),
      ),
    ),
  );

  /// Table view — the same rows without the day grouping.
  Widget _table(TrackDetail d) => Container(
    decoration: trkCard(radius: 14),
    child: Column(
      children: [
        for (var i = 0; i < d.trailflat.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEDEEF7)),
          _tableRow(d.trailflat[i]),
        ],
      ],
    ),
  );

  Widget _tableRow(TrailEntry e) {
    final t = toneColors(e.tone);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.daydate.length >= 10 ? e.daydate.substring(5) : e.daydate,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                  ),
                ),
                Text(
                  e.time,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: newTextHint,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.eventlabel} · ${e.stagename}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: t.fg,
                  ),
                ),
                Text(
                  e.operator,
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
          if (e.qty > 0) TrkPill(e.qtyLabel, fg: t.fg, bg: t.bg, size: 9.5),
        ],
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String url;
  const _PhotoViewer(this.url);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text(
            'Could not load the photo.\nThe link may have expired — pull to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ),
    ),
  );
}

// ── 3 · People ──────────────────────────────────────────────────────────────

class _PeopleTab extends StatelessWidget {
  final TrackingController c;
  const _PeopleTab({required this.c});

  @override
  Widget build(BuildContext context) {
    final d = c.detail;
    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          decoration: trkCard(),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Who did what',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: trkInk,
                      ),
                    ),
                  ),
                  const Text(
                    'this item',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: newTextHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(child: _Th('Person')),
                  SizedBox(width: 44, child: _Th('Prod', end: true)),
                  SizedBox(width: 40, child: _Th('QC', end: true)),
                  SizedBox(width: 40, child: _Th('Rej', end: true)),
                ],
              ),
              const SizedBox(height: 4),
              if (d.whodidwhat.isEmpty)
                const TrkEmpty(
                  icon: Icons.people_outline_rounded,
                  title: 'Nobody has worked on this item yet.',
                ),
              ...d.whodidwhat.map(_personRow),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: trkCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stage completion',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: trkInk,
                ),
              ),
              const SizedBox(height: 12),
              ...d.stagecompletion.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          s.stagename,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: trkInk,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TrkBar(
                          pct: s.completionpct,
                          color: toneColors(s.tone).fg,
                        ),
                      ),
                      SizedBox(
                        width: 42,
                        child: Text(
                          '${s.completionpct}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: trkInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: c.exporting ? null : c.exportCsv,
            icon: c.exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.file_download_outlined, size: 19),
            label: const Text(
              'Export trail (CSV) & share',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: trkViolet,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Exports the trail with the current Stage / Person / search filters',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: newTextHint,
          ),
        ),
      ],
    );
  }

  Widget _personRow(PersonWork p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Expanded(
          child: Row(
            children: [
              InitialsAvatar(p.initials),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.person,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: trkInk,
                      ),
                    ),
                    Text(
                      p.stagename,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: newTextHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // A zero shows "—" for Prod and QC, but a real 0 for Rej (same as web).
        SizedBox(
          width: 44,
          child: _Num(p.produced <= 0 ? '—' : _n(p.produced), color: trkInk),
        ),
        SizedBox(
          width: 40,
          child: _Num(p.qc <= 0 ? '—' : _n(p.qc), color: trkGreen),
        ),
        SizedBox(width: 40, child: _Num(_n(p.rejected), color: trkRed)),
      ],
    ),
  );
}

class _Th extends StatelessWidget {
  final String text;
  final bool end;
  const _Th(this.text, {this.end = false});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    textAlign: end ? TextAlign.right : TextAlign.left,
    style: const TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: newTextHint,
    ),
  );
}

class _Num extends StatelessWidget {
  final String text;
  final Color color;
  const _Num(this.text, {required this.color});
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.right,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
  );
}

String _n(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

/// One downtime / bottleneck row — shared by the Overview and Activity
/// tabs, so the wording is identical in both places.

Widget _stoppageRow(TrackStoppage s) {
  final t = toneColors(s.tone);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            s.isDowntime
                ? Icons.power_off_rounded
                : Icons.warning_amber_rounded,
            size: 15,
            color: t.fg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${s.stype} · ${s.reason}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: t.fg,
                      ),
                    ),
                  ),
                  if (s.isOngoing)
                    const TrkPill('Ongoing', fg: Colors.white, bg: trkRed)
                  else if (s.durationLabel.isNotEmpty)
                    TrkPill(s.durationLabel, fg: t.fg, bg: t.bg),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                [
                  s.stagename,
                  if (s.fromtime.isNotEmpty) s.fromtime,
                  if (s.remarks.isNotEmpty) s.remarks,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
