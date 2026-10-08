// QC history — every check the signed-in user saved (interia/qchistory).
//
// Lives inside the QC tab of My Jobs as the "My history" pane: until now a QC
// person saved a pass or a reject and it vanished, with no way to look back at
// what they had already checked.
//
// Filtering is split on purpose. Dates and stage go to the server, which
// recomputes the KPI cards for them. Result and search are applied here,
// because the server leaves `summary` untouched for those two — sending them
// would leave the cards reading "34 entries" above a list of 3.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/homeview_new_controller.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/menu_ids.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

/// The "My history" pane. Scrolls on its own; the QC tab supplies the header.
class QcHistoryPane extends StatelessWidget {
  const QcHistoryPane({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      if (c.qcHistoryLoading && c.qcHistoryData == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.qcHistoryData == null) {
        return EmptyState(
          icon: Icons.fact_check_outlined,
          title: c.qcHistoryError.isNotEmpty
              ? c.qcHistoryError
              : 'No QC history yet.',
          subtitle: 'Checks you save appear here, newest first.',
          action: 'Retry'.tr,
          onAction: () => c.loadQcHistory(force: true),
        );
      }
      final days = c.qcVisibleDays;
      return RefreshIndicator(
        onRefresh: () => c.loadQcHistory(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 28),
          children: [
            _rangeChips(context, c),
            const SizedBox(height: 9),
            if (c.qcRangeLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 3, bottom: 10),
                child: Text(
                  c.qcRangeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: newTextSecondary,
                  ),
                ),
              ),
            _kpis(c),
            const SizedBox(height: 13),
            _resultChips(c),
            const SizedBox(height: 11),
            _search(c),
            const SizedBox(height: 4),
            if (days.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nothing matches',
                  subtitle: c.qcSummary.entries == 0
                      ? 'You saved no QC checks in this range.'
                      : 'Try another result, stage or date range.',
                  action: 'Reset filters',
                  onAction: c.resetQcFilter,
                ),
              )
            else
              ...days.map((d) => _QcDaySection(day: d)),
          ],
        ),
      );
    },
  );

  // ── Quick ranges + the filter button ──

  Widget _rangeChips(BuildContext context, OperatorController c) => Row(
    children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (key, label) in const [
                ('today', 'Today'),
                ('7', '7 days'),
                ('30', '30 days'),
                ('custom', 'Custom'),
              ]) ...[
                _Chip(
                  label: label,
                  on: c.qcRange == key,
                  color: opPrimary,
                  onTap: key == 'custom'
                      ? () => openQcFilterSheet(context, c)
                      : () => c.setQcRange(key),
                ),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(width: 4),
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => openQcFilterSheet(context, c),
        child: Container(
          width: 34,
          height: 32,
          decoration: BoxDecoration(
            color: c.qcFilterActive ? opPrimary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: c.qcFilterActive ? opPrimary : newBorderColor,
            ),
          ),
          child: Icon(
            Icons.tune_rounded,
            size: 16,
            color: c.qcFilterActive ? Colors.white : newTextSecondary,
          ),
        ),
      ),
    ],
  );

  // ── The four cards ──

  Widget _kpis(OperatorController c) {
    final s = c.qcSummary;
    final rate = s.passrate;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: KpiTile(
                icon: Icons.fact_check_outlined,
                color: opPrimary,
                bg: opPurpleBg,
                value: '${s.entries}',
                label: '${s.lots} lots checked',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: KpiTile(
                icon: Icons.percent_rounded,
                color: rate == null
                    ? newTextSecondary
                    : (rate >= 95 ? opGreen : (rate >= 80 ? opAmber : opRed)),
                bg: opBlueBg,
                // Null = no checks at all in this range — a dash, not "0%".
                value: rate == null ? '—' : '$rate%',
                label: 'pass rate',
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: KpiTile(
                icon: Icons.check_circle_outline_rounded,
                color: opGreen,
                bg: opGreenBg,
                value: fmtQty(s.passedqty),
                label: 'pcs passed',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: KpiTile(
                icon: Icons.cancel_outlined,
                color: s.rejectedqty > 0 ? opRed : newTextSecondary,
                bg: opRedBg,
                value: fmtQty(s.rejectedqty),
                // Scrap is only named when some exists — it cannot be
                // recorded any more, so "0 scrap" on every screen is noise.
                label: s.scrapqty > 0
                    ? 'pcs · ${fmtQty(s.reworkqty)} rework · ${fmtQty(s.scrapqty)} scrap'
                    : 'pcs · ${fmtQty(s.reworkqty)} rework',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _resultChips(OperatorController c) => Row(
    children: [
      for (final (key, label, n, color) in [
        ('all', 'All'.tr, c.qcCountAll, opPrimary),
        ('passed', 'Passed'.tr, c.qcCountPassed, opGreen),
        ('rejected', 'Rejected'.tr, c.qcCountRejected, opRed),
      ]) ...[
        _Chip(
          label: '$label $n',
          on: c.qcResultFilter == key,
          color: color,
          onTap: () => c.setQcResultFilter(key),
        ),
        const SizedBox(width: 7),
      ],
    ],
  );

  Widget _search(OperatorController c) => Container(
    decoration: opCard(radius: 12),
    padding: const EdgeInsets.symmetric(horizontal: 11),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, size: 17, color: newTextHint),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: c.qcSearchCtrl,
            onChanged: c.setQcSearch,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: newTextPrimary,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Search item, BOQ, stage, operator…',
              hintStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: newTextHint,
              ),
            ),
          ),
        ),
        if (c.qcSearch.isNotEmpty)
          InkWell(
            onTap: () {
              c.qcSearchCtrl.clear();
              c.setQcSearch('');
            },
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: newTextHint,
            ),
          ),
      ],
    ),
  );
}

/// One day of checks. Long days collapse to three rows with a "Show N more".
class _QcDaySection extends StatefulWidget {
  final QcDay day;
  const _QcDaySection({required this.day});

  @override
  State<_QcDaySection> createState() => _QcDaySectionState();
}

class _QcDaySectionState extends State<_QcDaySection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.day;
    final shown = expanded ? d.entries : d.entries.take(3).toList();
    final more = d.entries.length - shown.length;
    final passed = d.entries.where((e) => !e.hasReject).length;
    final rejected = d.entries.length - passed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(3, 17, 3, 9),
          child: Row(
            children: [
              Text(
                d.daylabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: newTextSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Divider(color: newBorderColor, height: 1)),
              const SizedBox(width: 8),
              Text(
                [
                  '${d.entries.length} ${d.entries.length == 1 ? 'entry' : 'entries'}',
                  if (passed > 0) '$passed passed',
                  if (rejected > 0) '$rejected rejected',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: newTextHint,
                ),
              ),
            ],
          ),
        ),
        ...shown.map((e) => _QcEntryCard(entry: e)),
        if (more > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => expanded = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: newBorderColor),
                ),
                child: Text(
                  'Show $more more',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: opPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QcEntryCard extends StatelessWidget {
  final QcEntry entry;
  const _QcEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final tone = _tone(e);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => openQcEntrySheet(context, e),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: opCard(),
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
                      color: tone.bg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(tone.icon, size: 17, color: tone.fg),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.itemname,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: newTextPrimary,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 8),
              Text(
                _subtitle(e),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: newTextSecondary,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  SoftPill(e.resultLabel, color: tone.fg, bg: tone.bg),
                  const SizedBox(width: 9),
                  if (e.producedby.isNotEmpty)
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Made by '),
                            TextSpan(
                              text: e.producedby,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: newTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: newTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              if (e.hasReject && (e.reason.isNotEmpty || e.remarks.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: _reasonBanner(e),
                ),
              if (e.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: e.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (_, i) => _thumb(e.photos[i], 52),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────

void openQcEntrySheet(BuildContext context, QcEntry e) {
  final tone = _tone(e);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 9),
          Container(
            height: 4,
            width: 42,
            decoration: BoxDecoration(
              color: newBorderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tone.bg,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(tone.icon, color: tone.fg, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.resultLabel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: newTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_dayLabel(e.qcdate)} · ${e.time} · by you',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: newTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: newTextHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  e.itemname,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                    height: 1.25,
                  ),
                ),
                if (e.stagename.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '${e.stagename} stage',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: stageColor(e.stagename),
                      ),
                    ),
                  ),
                if (e.hasReject &&
                    (e.reason.isNotEmpty ||
                        e.remarks.isNotEmpty ||
                        e.disposition.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 13),
                    child: _reasonBanner(e),
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: opCard(radius: 13),
                  child: Column(
                    children: [
                      _pair('BOQ', e.boqno, 'PARTY', e.partyname),
                      const SizedBox(height: 13),
                      _pair(
                        'CHALLAN',
                        e.challanno.isNotEmpty ? e.challanno : '${e.challanid}',
                        'MADE BY',
                        e.producedby,
                      ),
                      const SizedBox(height: 13),
                      _pair(
                        'QC PASSED',
                        '${fmtQty(e.qcqty)} pcs',
                        'REJECTED',
                        '${fmtQty(e.rejectqty)} pcs',
                      ),
                    ],
                  ),
                ),
                if (e.photos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'PHOTOS · ${e.photos.length}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: newTextSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: e.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (_, i) => _thumb(e.photos[i], 92),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              12 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: SmallButton(
                      'Close'.tr,
                      color: newTextSecondary,
                      filled: false,
                      onTap: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                ),
                if (_canTrack(e)) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Center(
                      child: SmallButton(
                        'Track order',
                        color: opPrimary,
                        icon: Icons.insights_outlined,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Get.toNamed(AppRoutes.orderTracking);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Track order is only offered to someone who actually has the Order Tracking
/// module — a QC hand without that grant would land on a screen they cannot
/// use.
bool _canTrack(QcEntry e) {
  if (e.orderrefid <= 0) return false;
  if (!Get.isRegistered<HomeViewNewController>()) return false;
  return Get.find<HomeViewNewController>().hasMenu(kMenuOrderTracking);
}

// ── Filter sheet ─────────────────────────────────────────────────────────────

void openQcFilterSheet(BuildContext context, OperatorController c) {
  DateTime? from = c.qcFromDate;
  DateTime? to = c.qcToDate;
  int stage = c.qcStageFilter;
  String result = c.qcResultFilter;
  final stages = c.qcHistoryData?.stages ?? const <QcStageOption>[];
  final fmt = DateFormat('dd-MM-yyyy');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (rootContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        Future<void> pick(bool isFrom) async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: sheetContext,
            initialDate: (isFrom ? from : to) ?? now,
            firstDate: DateTime(now.year - 3),
            lastDate: now,
          );
          if (picked == null) return;
          setSheet(() {
            if (isFrom) {
              from = picked;
              if (to != null && to!.isBefore(picked)) to = picked;
            } else {
              to = picked;
              if (from != null && from!.isAfter(picked)) from = picked;
            }
          });
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 9),
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: newBorderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: opPurpleBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 17,
                            color: opPrimary,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Text(
                            'Filter QC history',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: newTextPrimary,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(sheetContext).pop(),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: newTextHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('QC date'),
                    Row(
                      children: [
                        Expanded(
                          child: _dateBox(
                            'From',
                            from == null ? '—' : fmt.format(from!),
                            () => pick(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateBox(
                            'To',
                            to == null ? '—' : fmt.format(to!),
                            () => pick(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Stage'),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _Chip(
                          label: 'All stages',
                          on: stage == 0,
                          color: opPrimary,
                          onTap: () => setSheet(() => stage = 0),
                        ),
                        for (final s in stages)
                          _Chip(
                            label: s.stagename,
                            on: stage == s.stageid,
                            color: stageColor(s.stagename),
                            onTap: () => setSheet(() => stage = s.stageid),
                          ),
                      ],
                    ),
                    SizedBox(height: 18),
                    FieldLabel('Result'),
                    Row(
                      children: [
                        for (final (key, label, color) in [
                          ('all', 'All'.tr, opPrimary),
                          ('passed', 'Passed'.tr, opGreen),
                          ('rejected', 'Rejected'.tr, opRed),
                        ]) ...[
                          _Chip(
                            label: label,
                            on: result == key,
                            color: color,
                            onTap: () => setSheet(() => result = key),
                          ),
                          const SizedBox(width: 7),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  12 + MediaQuery.of(sheetContext).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: SmallButton(
                          'Reset',
                          color: newTextSecondary,
                          filled: false,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            c.resetQcFilter();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Center(
                        child: SmallButton(
                          'Apply',
                          color: opPrimary,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            c.applyQcFilter(
                              from: from,
                              to: to,
                              stageid: stage,
                              result: result,
                            );
                          },
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
    ),
  );
}

Widget _dateBox(String label, String value, VoidCallback onTap) => InkWell(
  borderRadius: BorderRadius.circular(11),
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: newSurfaceColor,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: newBorderColor),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: newTextHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: newTextSecondary,
        ),
      ],
    ),
  ),
);

// ── Small shared pieces ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final Color color;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.on,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(100),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: on ? color : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: on ? color : newBorderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: on ? Colors.white : newTextSecondary,
        ),
      ),
    ),
  );
}

typedef _Tone = ({Color fg, Color bg, IconData icon});

/// Green pass, red reject, amber when one lot was part-passed and part-rejected.
_Tone _tone(QcEntry e) => e.isPartial
    ? (fg: opAmber, bg: opAmberBg, icon: Icons.rule_rounded)
    : e.hasReject
    ? (fg: opRed, bg: opRedBg, icon: Icons.close_rounded)
    : (fg: opGreen, bg: opGreenBg, icon: Icons.check_rounded);

String _subtitle(QcEntry e) => [
  if (e.stagename.isNotEmpty) e.stagename,
  if (e.boqno.isNotEmpty) e.boqno,
  if (e.challanno.isNotEmpty) 'Challan ${e.challanno}',
].join(' · ');

String _dayLabel(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('d MMM yyyy').format(d);
}

Widget _reasonBanner(QcEntry e) => Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
  decoration: BoxDecoration(
    color: opAmberBg,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (e.disposition.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                e.disposition,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A5A00),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (e.reason.isNotEmpty)
            Expanded(
              child: Text(
                e.reason,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A5A00),
                ),
              ),
            ),
        ],
      ),
      if (e.remarks.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            e.remarks,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4A0B),
              height: 1.3,
            ),
          ),
        ),
    ],
  ),
);

Widget _pair(String k1, String v1, String k2, String v2) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(child: _kv(k1, v1)),
    const SizedBox(width: 12),
    Expanded(child: _kv(k2, v2)),
  ],
);

Widget _kv(String k, String v) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      k,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: newTextHint,
        letterSpacing: 0.3,
      ),
    ),
    const SizedBox(height: 3),
    Text(
      v.isEmpty ? '—' : v,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: newTextPrimary,
        height: 1.25,
      ),
    ),
  ],
);

/// Presigned S3 thumbnails — the links expire in an hour, so a broken image
/// here means "stale link", not "missing photo": pull to refresh.
Widget _thumb(String url, double size) => InkWell(
  borderRadius: BorderRadius.circular(10),
  onTap: () => Get.to(() => _QcPhotoViewer(url)),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: size,
      height: size,
      color: newSurfaceColor,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          size: 18,
          color: newTextHint,
        ),
      ),
    ),
  ),
);

class _QcPhotoViewer extends StatelessWidget {
  final String url;
  const _QcPhotoViewer(this.url);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('QC photo', style: TextStyle(fontSize: 13)),
    ),
    body: Center(
      child: InteractiveViewer(
        maxScale: 5,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : const CircularProgressIndicator(color: Colors.white),
          errorBuilder: (_, _, _) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 48,
          ),
        ),
      ),
    ),
  );
}
