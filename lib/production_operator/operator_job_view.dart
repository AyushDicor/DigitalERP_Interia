import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/repo/attachment_repo.dart' show AttachmentItem;
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'operator_controller.dart';
import 'operator_design_view.dart';
import 'operator_parts_view.dart';
import 'operator_models.dart';
import 'operator_pack_view.dart';
import 'operator_sendback_form.dart';
import 'operator_qc_view.dart';
import 'operator_gatepass_sheet.dart';
import 'operator_incoming_view.dart';
import 'operator_stoppage_sheet.dart';
import 'operator_widgets.dart';

/// Job workspace: summary (issued / produced / balance + piece tracker),
/// production entry (completed-pieces counter + current-piece % slider +
/// photo), downtime / bottleneck shortcuts, the day-wise production log and —
/// once QC has passed something — "Issue to next stage". The job's route
/// (stage trail) is deliberately NOT shown: an operator sees only his stage.
class OperatorJobView extends StatelessWidget {
  const OperatorJobView({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      final j = c.job;
      if (j == null) return const Scaffold(body: SizedBox());
      return Scaffold(
        backgroundColor: opBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: newTextPrimary,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job · ${j.challanno.isNotEmpty ? j.challanno : 'Challan ${j.challanid}'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                // The QC user's row comes back without a boqno, so the
                // separator is dropped rather than left dangling.
                [
                  _title(j.stagename),
                  if (j.boqno.isNotEmpty) j.boqno,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ),
        body: c.jobLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 30),
                children: [
                  if (c.demoMode) const DemoBanner(),
                  _summary(c, j),
                  // This is not forward work: say so before anything else,
                  // or the operator reads the numbers as their own job's.
                  if (j.isSendBack) _sendBackBanner(j),
                  // Found a fault in what arrived? Send it back to whichever
                  // earlier stage caused it. Hidden on a send back leg —
                  // pieces already going back cannot be sent back again —
                  // and hidden from a QC login, whose route is the reject
                  // fork on the QC screen: that records the rejection in the
                  // same call, which this one does not.
                  if (!j.isSendBack && !j.canqc) _sendBackButton(context, c, j),
                  // Where this stage sits in the challan's route — only
                  // drawn when the challan actually has one.
                  _routeLine(c, j),
                  // The read-only chips, for a stage that shows parts but
                  // does not record them (the assembling stage).
                  if (!j.isPartMode) _partsCard(j),
                  // Approved drawings, client materials and BOM files —
                  // above Produce/QC because they are what the operator
                  // needs before touching the piece.
                  const JobDesignSection(),
                  // A stage planned with parts records each one separately —
                  // the item's own produce and issue cards would double-count.
                  // Packing is checked FIRST. The server states it outright
                  // with `packstage`, and if the stage ever also carried
                  // parts, an earlier branch would swallow it and the Pack
                  // button would silently never appear.
                  if (j.isPackStage) ...[
                    const _Label('Packing'),
                    _packCard(context, c, j),
                  ] else if (j.isPartMode) ...[
                    const _Label('Parts'),
                    const JobPartsSection(),
                  ] else if (c.pendingConsignmentFor(j) != null) ...[
                    const _Label('Add production'),
                    _lockedByConsignment(c, c.pendingConsignmentFor(j)!),
                  ] else if (j.isWaitingForParts) ...[
                    const _Label('Add production'),
                    _waitingForParts(j),
                  ] else if (j.balanceqty > 0 || c.producedDelta > 0) ...[
                    // On a send back leg the same entry IS the rework —
                    // calling it "Add production" would read as new work.
                    _Label(j.isSendBack ? 'Rework here' : 'Add production'),
                    _entry(context, c, j),
                  ] else ...[
                    const _Label('Production'),
                    _completeCard(c, j),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _quickBtn(
                          Icons.error_outline_rounded,
                          'Downtime',
                          opRed,
                          opRedBg,
                          () => showStoppageSheet(
                            context,
                            c,
                            downtime: true,
                            job: j,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _quickBtn(
                          Icons.warning_amber_rounded,
                          'Bottleneck',
                          opAmber,
                          opAmberBg,
                          () => showStoppageSheet(
                            context,
                            c,
                            downtime: false,
                            job: j,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // In part mode the check is per part, on the cards
                  // above — the item-level card would offer a QC the server
                  // refuses without a partid.
                  if (j.qcPending > 0 && !j.isPartMode) ...[
                    const _Label('Quality check'),
                    _qcCard(c, j),
                  ],
                  if (!j.isPartMode) ...[
                    _Label(
                      c.isSplit
                          ? 'Issue to next stages'
                          : 'Issue to next stage',
                    ),
                    _issueCard(context, c, j),
                  ],
                  // No stage trail: an operator sees only his own stage, not
                  // the whole route of the job (client rule, 2026-09-23).
                  // The trail is still fetched — it backs the issue lock.
                  if (c.entries.isNotEmpty || c.entriesLoading) ...[
                    const _Label('Production log'),
                    _log(c, j),
                  ],
                  if (!c.demoMode &&
                      (c.gallery.isNotEmpty || c.galleryLoading)) ...[
                    const _Label('Other photos'),
                    _gallery(c),
                  ],
                ],
              ),
      );
    },
  );

  static String _title(String s) => s.isEmpty
      ? s
      : s
            .toLowerCase()
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');

  // ── Summary ──

  Widget _summary(OperatorController c, OperatorJob j) {
    final issued = j.issuedqty;
    final produced = c.producedNow;
    final balance = c.balanceNow;
    final allDone = balance <= 0 && issued > 0;
    final pieces = issued.round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: opCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.itemname,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: newTextPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${j.boqno} · ${j.partyname}',
                      style: const TextStyle(
                        fontSize: 10.5,
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
                  StagePill(j.stagename),
                  if (j.isRework) ...[
                    const SizedBox(height: 5),
                    const SoftPill('Rework', color: opRed, bg: opRedBg),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: newBorderColor),
          const SizedBox(height: 10),
          Row(
            children: [
              _tri(fmtQty(issued), 'Issued'),
              _tri(
                fmtQty(produced),
                'Produced',
                color: produced > 0 ? opGreen : null,
              ),
              _tri(
                fmtQty(balance),
                'Balance',
                color: allDone ? opGreen : opAmber,
              ),
            ],
          ),
          const SizedBox(height: 11),
          // Pieces: done · in progress (batch @ %) · not started, plus the
          // overall job % which counts partial work (20 pcs at 30% = 6 pcs).
          Row(
            children: [
              Expanded(
                child: Text(
                  allDone
                      ? 'ALL ${fmtQty(issued)} PIECES DONE'
                      : (pieces > 1
                            ? 'PIECES · ${fmtQty(produced)} DONE · ${c.wipPieces} IN PROGRESS · ${fmtQty(c.notStarted)} NOT STARTED'
                            : 'CURRENT PIECE'),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: newTextSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                allDone
                    ? '100% · Complete'
                    : 'Job ${c.jobPct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: allDone ? opGreen : opPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (pieces > 1 && pieces <= 24)
            Row(
              children: List.generate(pieces, (i) {
                final doneN = produced.round();
                final done = i < doneN;
                final inWip = !allDone && i >= doneN && i < doneN + c.wipPieces;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == pieces - 1 ? 0 : 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 11,
                        child: Stack(
                          children: [
                            Container(color: done ? opGreen : newBorderColor),
                            if (inWip)
                              FractionallySizedBox(
                                widthFactor: (c.piecePct / 100).clamp(0, 1),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: opGradient,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            )
          else
            // Stacked bar: green = finished pieces, blue = partial work.
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(color: newBorderColor),
                    FractionallySizedBox(
                      widthFactor: issued <= 0
                          ? 0
                          : ((produced + c.wipWork) / issued).clamp(0, 1),
                      child: Container(
                        decoration: const BoxDecoration(gradient: opGradient),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: issued <= 0
                          ? 0
                          : (produced / issued).clamp(0, 1),
                      child: Container(color: opGreen),
                    ),
                  ],
                ),
              ),
            ),
          if (!allDone && c.wipPieces > 0 && c.piecePct > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${c.wipPieces} pcs at ${c.piecePct.toStringAsFixed(0)}% ≈ ${_n1(c.wipWork)} pcs of work done',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: newTextHint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _n1(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _tri(String v, String k, {Color? color}) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color ?? newTextPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          k.toUpperCase(),
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: newTextSecondary,
          ),
        ),
      ],
    ),
  );

  // ── Production entry ──

  Widget _entry(BuildContext context, OperatorController c, OperatorJob j) {
    final issued = j.issuedqty;
    final multi = issued > 1;
    final pieceNo = (c.producedNow + 1).round();
    final willComplete = c.balanceNow <= 0;
    final accent = willComplete ? opGreen : opPrimary;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: opCard(border: accent.withValues(alpha: 0.45), radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_arrow_rounded, size: 16, color: accent),
              const SizedBox(width: 7),
              const Text(
                'Production entry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              const Spacer(),
              if (willComplete)
                const SoftPill('Complete', color: opGreen, bg: opGreenBg),
            ],
          ),
          const SizedBox(height: 11),
          FieldLabel(
            multi
                ? 'Produced (pcs) — completed of ${fmtQty(issued)}'
                : 'Produced (pcs)',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: newSurfaceColor,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: accent.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                _stepBtn(
                  Icons.remove_rounded,
                  enabled: c.producedDelta > 0,
                  filled: false,
                  onTap: c.decProduced,
                ),
                // Tap the number to type it — 500-pc lots aren't tapped out.
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _typeProduced(context, c),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: fmtQty(c.producedNow),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: willComplete ? opGreen : newTextPrimary,
                          ),
                          children: [
                            TextSpan(
                              text: '  / ${fmtQty(issued)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: newTextSecondary,
                              ),
                            ),
                            if (c.producedDelta > 0)
                              TextSpan(
                                text: '   +${c.producedDelta} new',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: opPrimary,
                                ),
                              ),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.keyboard_alt_outlined,
                                  size: 15,
                                  color: newTextHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _stepBtn(
                  Icons.add_rounded,
                  enabled: c.balanceNow > 0,
                  filled: true,
                  onTap: c.incProduced,
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const FieldLabel('Entry date'),
          // Tappable: pieces finished yesterday can be booked on yesterday.
          ValueBox(
            _dateLabel(c.entryDate),
            icon: Icons.edit_calendar_outlined,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: c.entryDate,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now(),
                helpText: 'Entry date (back-date allowed)',
              );
              if (d != null) c.setEntryDate(d);
            },
          ),
          if (!_isToday(c.entryDate)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 12, color: opAmber),
                const SizedBox(width: 5),
                Text(
                  'Back-dated — will be booked on ${_dateLabel(c.entryDate)}.',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: opAmber,
                  ),
                ),
              ],
            ),
          ],
          if (multi && !willComplete) ...[
            const SizedBox(height: 12),
            // Batch work: "20 pcs in progress" — the slider % then applies to
            // all of them (30% on 20 pcs = 6 pcs of work, 0 finished).
            FieldLabel(
              'Pieces in progress — of ${fmtQty(c.balanceNow)} remaining',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: newSurfaceColor,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: newBorderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  _stepBtn(
                    Icons.remove_rounded,
                    enabled: c.wipQty > 0,
                    filled: false,
                    onTap: c.decWip,
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _typeWip(context, c),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            text: c.wipQty > 0 ? '${c.wipQty}' : '—',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: newTextPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: c.wipQty > 0
                                    ? '  pcs being worked on'
                                    : '  next piece only',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: newTextSecondary,
                                ),
                              ),
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.keyboard_alt_outlined,
                                    size: 14,
                                    color: newTextHint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _stepBtn(
                    Icons.add_rounded,
                    enabled: c.wipQty < c.balanceNow.round(),
                    filled: true,
                    onTap: c.incWip,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                (c.wipQty > 0
                        ? 'Work progress · ${c.wipQty} pcs in progress'
                        : multi
                        ? 'Work progress · piece $pieceNo of ${fmtQty(issued)}'
                        : 'Work progress · current piece')
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: newTextSecondary,
                ),
              ),
              const Spacer(),
              Text(
                // Same value the slider shows: all pieces counted = 100%.
                '${(willComplete ? 100 : c.piecePct).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: accent,
              inactiveTrackColor: newBorderColor,
              thumbColor: Colors.white,
              overlayColor: accent.withValues(alpha: 0.15),
              thumbShape: _RingThumb(accent),
            ),
            child: Slider(
              value: willComplete ? 100 : c.piecePct,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: willComplete ? null : c.setPiecePct,
              onChangeEnd: (_) => c.commitPiecePct(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Tick('0%'),
                _Tick('25%'),
                _Tick('50%'),
                _Tick('75%'),
                _Tick('100%'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: newTextHint,
                height: 1.45,
              ),
              children: willComplete
                  ? [
                      const TextSpan(text: '100% — '),
                      TextSpan(
                        text: 'Produced = ${fmtQty(c.producedNow)}',
                        style: const TextStyle(color: newTextSecondary),
                      ),
                      const TextSpan(text: '. Next: '),
                      const TextSpan(
                        text: 'QC',
                        style: TextStyle(color: newTextSecondary),
                      ),
                      const TextSpan(text: '.'),
                    ]
                  : c.wipQty > 0
                  ? [
                      TextSpan(
                        text:
                            '${c.wipQty} pcs at ${c.piecePct.toStringAsFixed(0)}% ≈ ${_n1(c.wipWork)} pcs of work',
                        style: const TextStyle(color: newTextSecondary),
                      ),
                      const TextSpan(text: ' — none finished yet. At '),
                      const TextSpan(
                        text: '100%',
                        style: TextStyle(color: newTextSecondary),
                      ),
                      TextSpan(text: ' all ${c.wipQty} count as '),
                      const TextSpan(
                        text: 'produced',
                        style: TextStyle(color: newTextSecondary),
                      ),
                      const TextSpan(text: '.'),
                    ]
                  : [
                      const TextSpan(text: 'At '),
                      const TextSpan(
                        text: '100%',
                        style: TextStyle(color: newTextSecondary),
                      ),
                      const TextSpan(text: ' the piece counts as '),
                      const TextSpan(
                        text: '1 pc produced',
                        style: TextStyle(color: newTextSecondary),
                      ),
                      TextSpan(
                        text: multi
                            ? ', then piece ${pieceNo + 1} starts. Working on several at once? Set "Pieces in progress" above.'
                            : '.',
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 11),
          const FieldLabel('Remarks (optional)'),
          // Saved on both the produce row and the progress row, so the note
          // shows against this entry in the day-wise log.
          TextField(
            controller: c.produceRemarksCtrl,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(fontSize: 12.5),
            decoration: opInput(hint: 'e.g. 2 pcs left for polish'),
          ),
          const SizedBox(height: 10),
          PhotoStrip(
            photos: c.producePhotos,
            onAdd: c.pickProducePhotos,
            onRemove: c.removeProducePhoto,
          ),
          const SizedBox(height: 11),
          BigButton(
            willComplete ? 'Save production' : 'Save progress',
            icon: willComplete
                ? Icons.check_circle_outline_rounded
                : Icons.check_rounded,
            busy: c.saving,
            gradient: willComplete ? opGreenGradient : opGradient,
            onTap: c.saveProduction,
          ),
        ],
      ),
    );
  }

  /// Keyboard entry for the produced counter (big lots).
  Future<void> _typeProduced(BuildContext context, OperatorController c) async {
    final j = c.job;
    if (j == null) return;
    final maxNew = (j.issuedqty - j.producedqty).round();
    if (maxNew <= 0) return;
    final n = await askQtyDialog(
      context,
      title: 'Pieces produced',
      subtitle:
          'New pieces finished in this entry. ${fmtQty(j.producedqty)} already recorded, $maxNew still open.',
      current: c.producedDelta,
      max: maxNew,
    );
    if (n != null) c.setProducedDelta(n);
  }

  /// Keyboard entry for the pieces-in-progress batch.
  Future<void> _typeWip(BuildContext context, OperatorController c) async {
    final maxWip = c.balanceNow.round();
    if (maxWip <= 0) return;
    final n = await askQtyDialog(
      context,
      title: 'Pieces in progress',
      subtitle: 'How many pieces the % below applies to.',
      current: c.wipQty,
      max: maxWip,
    );
    if (n != null) c.setWipQty(n);
  }

  Widget _stepBtn(
    IconData icon, {
    required bool enabled,
    required bool filled,
    required VoidCallback onTap,
  }) => Opacity(
    opacity: enabled ? 1 : 0.4,
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? opPrimary : newBlueLightColor,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: filled ? Colors.white : opPrimary, size: 22),
      ),
    ),
  );

  Widget _completeCard(OperatorController c, OperatorJob j) => Container(
    padding: const EdgeInsets.all(13),
    decoration: opCard(border: opGreen.withValues(alpha: 0.4), radius: 14),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: opGreenBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_rounded, color: opGreen, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All ${fmtQty(j.issuedqty)} pcs produced',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              Text(
                j.qcPending > 0
                    ? '${fmtQty(j.qcPending)} awaiting QC'
                    : 'QC passed ${fmtQty(j.qcqty)} · rejected ${fmtQty(j.rejectqty)}',
                style: const TextStyle(fontSize: 11, color: newTextSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _quickBtn(
    IconData icon,
    String label,
    Color color,
    Color bg,
    VoidCallback onTap,
  ) => InkWell(
    borderRadius: BorderRadius.circular(11),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  // ── QC status (read-only for the operator) ──

  Widget _qcCard(OperatorController c, OperatorJob j) => Container(
    padding: const EdgeInsets.all(12),
    decoration: opCard(radius: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${fmtQty(j.qcPending)} pc awaiting QC',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Passed ${fmtQty(j.qcqty)} · rejected ${fmtQty(j.rejectqty)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ),
        // Do QC only when the backend flagged this job as QC-able for me.
        if (j.canqc)
          SmallButton(
            'Do QC',
            color: opPurple,
            icon: Icons.verified_outlined,
            onTap: () {
              c.openQc(j);
              Get.to(() => const OperatorQcView());
            },
          )
        else
          const SoftPill('With QC', color: opPurple, bg: opPurpleBg),
      ],
    ),
  );

  // ── Issue forward ──

  /// Opens the send back form. Whether anything can actually go back is the
  /// server's call (`sendback/options`), so the button always shows and the
  /// form says "nothing here can be sent back" when the answer is empty —
  /// better than a button that silently is not there.
  Widget _sendBackButton(
    BuildContext context,
    OperatorController c,
    OperatorJob j,
  ) {
    // Only what is still in this stage's hands can go back. Once a part has
    // been handed on it belongs to the next stage, which is the one that can
    // return it — so a stage that has sent everything on sees why, rather
    // than a button leading to an empty form.
    final nothing = c.sbNothingToSend;
    final n = c.sbAvailableCount;
    final accent = nothing ? newTextHint : const Color(0xFFC2410C);
    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: nothing
            ? null
            : () {
                c.resetSendBackForm();
                c.loadSendBackOptions();
                Get.to(() => const OperatorSendBackForm());
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: nothing ? newSurfaceColor : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: nothing ? newBorderColor : opAmber.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.keyboard_return_rounded, size: 16, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nothing
                          ? 'Nothing here to send back'
                          : n > 1
                          ? 'Send back · $n to choose from'
                          : 'Send back',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      nothing
                          ? 'Only what is still at ${_title(j.stagename)} can go back. '
                                'Anything handed on is sent back by the stage that has it.'
                          : 'Found a fault? Send it to any earlier stage it came through.',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: newTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!nothing)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: newTextHint,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The way into the Pack screen. Packing replaces production here, so the
  /// card carries the same figures Produce would have shown.
  Widget _packCard(BuildContext context, OperatorController c, OperatorJob j) =>
      Container(
        padding: const EdgeInsets.all(13),
        decoration: opCard(border: opGreen.withValues(alpha: 0.4), radius: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, size: 16, color: opGreen),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Pack this item',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                    ),
                  ),
                ),
                SoftPill(
                  '${fmtQty(j.balanceqty)} left',
                  color: opGreen,
                  bg: opGreenBg,
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Say how many pieces are packed and what is inside each box. '
              'Saving records them as made at Packing — there is no separate '
              'production entry here.',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 11),
            BigButton(
              'Pack',
              icon: Icons.inventory_2_outlined,
              busy: c.saving,
              gradient: opGreenGradient,
              onTap: () async {
                await c.loadPackJob(j);
                Get.to(() => const OperatorPackView());
              },
            ),
          ],
        ),
      );

  /// Says plainly that these pieces came back to be fixed, who sent them and
  /// why, and where they go afterwards.
  Widget _sendBackBanner(OperatorJob j) => Container(
    margin: const EdgeInsets.only(top: 11),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: opAmberBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: opAmber.withValues(alpha: 0.45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.keyboard_return_rounded,
          size: 16,
          color: Color(0xFF8A4B06),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                j.returnfromstage.isEmpty
                    ? 'Sent back to be fixed here'
                    : 'Sent back by ${_title(j.returnfromstage)} to be fixed here',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A4B06),
                ),
              ),
              if (j.rejectreason.isNotEmpty || j.faultstage.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  [
                    if (j.rejectreason.isNotEmpty) j.rejectreason,
                    if (j.faultstage.isNotEmpty) 'Fault: ${j.faultstage}',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A4B06),
                  ),
                ),
              ],
              if (j.returnway.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  j.returnway,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A4B06),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  /// Send a fixed send back leg on its way. The destination is the ticket's,
  /// not the plan's, and part of a leg may go now with the rest following.
  Widget _sendOnCard(
    BuildContext context,
    OperatorController c,
    OperatorJob j,
  ) {
    final max = j.cansendqty;
    final where = j.returnnextstage.isEmpty
        ? j.returnfromstage
        : j.returnnextstage;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: opCard(border: opGreen.withValues(alpha: 0.4), radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.keyboard_return_rounded,
                size: 16,
                color: opGreen,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Send on → ${where.isEmpty ? 'back' : _title(where)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
              ),
              SoftPill('${fmtQty(max)} ready', color: opGreen, bg: opGreenBg),
            ],
          ),
          const SizedBox(height: 10),
          const FieldLabel('Qty to send on'),
          TextField(
            controller: c.issueQtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [MaxQtyFormatter(max)],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            decoration: opInput(hint: '0').copyWith(
              suffixText: 'max ${fmtQty(max)}',
              suffixStyle: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: newTextHint,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: newTextHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  j.returnway.isEmpty
                      ? 'Part of it can go now; the rest follows when it is ready.'
                      : '${j.returnway} · part of it can go now, the rest follows.',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: newTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          BigButton(
            'Send on',
            icon: Icons.local_shipping_outlined,
            busy: c.saving,
            gradient: opGreenGradient,
            onTap: () => showGatePassSheet(context, c),
          ),
        ],
      ),
    );
  }

  Widget _issueCard(BuildContext context, OperatorController c, OperatorJob j) {
    final next = c.next;
    // A send back leg goes where the ticket says, not where the plan says,
    // and only the server's cansendqty may move. Everything below this
    // (last stage, QC lock, split) is forward-flow reasoning.
    if (j.isSendBack) {
      if (j.cansendqty <= 0) {
        return _lockedCard(
          Icons.lock_outline_rounded,
          j.canqcqty > 0
              ? 'Reworked — waiting for QC. It can go on once QC passes it.'
              : 'Nothing QC-passed to send on yet. Rework it, then QC.',
        );
      }
      return _sendOnCard(context, c, j);
    }
    if (next != null && next.isLast) {
      return _lockedCard(
        Icons.flag_outlined,
        '${_title(j.stagename)} is the last stage — nothing to issue forward.',
      );
    }
    if (j.qcqty <= 0) {
      return _lockedCard(
        Icons.lock_outline_rounded,
        'Locked until QC passes at least one piece. Only QC-passed qty can move to the next stage.',
      );
    }
    // Two or more destinations need their own card — each with its own
    // sent / left and its own button.
    if (c.isSplit) return _splitIssueCard(context, c, j);
    final max = c.toIssue;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: opCard(border: opGreen.withValues(alpha: 0.4), radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_forward_rounded, size: 16, color: opGreen),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Issue → ${next == null ? 'next stage' : _title(next.stagename)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
              ),
              const SoftPill('QC passed', color: opGreen, bg: opGreenBg),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tri(fmtQty(j.producedqty), 'Produced'),
              _tri(fmtQty(j.qcqty), 'QC passed', color: opGreen),
              _tri(fmtQty(max), 'To issue', color: max > 0 ? opGreen : null),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Next stage'),
                    ValueBox(
                      next == null ? '—' : _title(next.stagename),
                      color: next == null ? null : stageColor(next.stagename),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Qty to issue'),
                    TextField(
                      controller: c.issueQtyCtrl,
                      enabled: max > 0,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      // Can never exceed the QC-passed qty still available.
                      inputFormatters: [MaxQtyFormatter(max)],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: opInput(hint: '0').copyWith(
                        suffixText: max > 0 ? 'max ${fmtQty(max)}' : null,
                        suffixStyle: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: newTextHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const FieldLabel('Batch no (optional)'),
          TextField(
            controller: c.batchNoCtrl,
            enabled: max > 0,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: opInput(hint: 'e.g. B2-03'),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: newTextHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  max > 0
                      ? 'Only QC-passed qty can be issued (max ${fmtQty(max)}).'
                      : 'All ${fmtQty(c.issuedForward)} QC-passed pcs already issued → ${next == null ? 'next stage' : _title(next.stagename)}.',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: newTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          // The lock is this phone's own record of the issue (server sends no
          // trail) — let the operator clear it when the lot came back to him.
          if (max <= 0 && c.issueLockIsLocal)
            Align(
              alignment: Alignment.centerRight,
              child: Builder(
                builder: (ctx0) => TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: ctx0,
                      builder: (ctx) => AlertDialog(
                        title: const Text(
                          'Issue again?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        content: const Text(
                          'Only if the next stage rejected this lot back to you, or the earlier issue was a mistake. Issuing the same pieces twice will double-count them.',
                          style: TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('Cancel'.tr),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: opAmber,
                            ),
                            child: const Text('Yes, unlock'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) c.forgetIssued();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Sent back to you? Issue again',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          // Loader handover is mandatory: every issue travels with a gate
          // pass and the next stage signs for it — no way to skip it.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: opGreenBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: opGreen.withValues(alpha: 0.35)),
            ),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 16, color: opGreen),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sent via Loader',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: newTextPrimary,
                        ),
                      ),
                      Text(
                        'Gate pass: loader, receipt & item photos; next stage signs on receipt.',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: newTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SoftPill('Required', color: opGreen, bg: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 11),
          BigButton(
            'Issue to ${next == null ? 'next stage' : _title(next.stagename)}',
            icon: Icons.local_shipping_outlined,
            busy: c.saving,
            gradient: opGreenGradient,
            onTap: max <= 0 ? null : () => showGatePassSheet(context, c),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap Issue → gate-pass sheet opens for this issue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: newTextHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedCard(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: newBorderColor),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: newTextHint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  static String _dateLabel(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  // ── Production log: entries grouped by day, newest day first ──
  // "5 pcs yesterday, 5 today" shows as two day blocks, each with its own
  // made / passed / rejected totals, instead of only the running total.

  Widget _log(OperatorController c, OperatorJob j) {
    final byDay = c.entriesByDay;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: opCard(radius: 14),
      child: c.entriesLoading && c.entries.isEmpty
          ? const SizedBox(
              height: 50,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final day in byDay.keys) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dayLabel(day),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: newTextPrimary,
                            ),
                          ),
                        ),
                        _dayTotals(byDay[day]!),
                      ],
                    ),
                  ),
                  ...byDay[day]!.map((e) => _logRow(c, e)),
                  const Divider(height: 10, color: newBorderColor),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Total produced ${fmtQty(j.producedqty)} / ${fmtQty(j.issuedqty)} · '
                    'QC passed ${fmtQty(j.qcqty)} · rejected ${fmtQty(j.rejectqty)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: newTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  static String _dayLabel(String day) {
    final d = DateTime.tryParse(day);
    if (d == null) return day;
    final n = DateTime.now();
    final diff = DateTime(
      n.year,
      n.month,
      n.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    final f = DateFormat('d MMM yyyy').format(d);
    if (diff == 0) return 'Today · $f';
    if (diff == 1) return 'Yesterday · $f';
    return f;
  }

  Widget _dayTotals(List<LedgerEntry> rows) {
    double p = 0, q = 0, r = 0;
    for (final e in rows) {
      // A hand-off is movement, not output — "Rejected by next stage" must
      // not land in the day's rejected count.
      if (e.isLoaderEvent) continue;
      if (e.isProduce) p += e.qty;
      if (e.isQc) q += e.qty;
      if (e.isReject) r += e.qty;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (p > 0) SoftPill('+${fmtQty(p)} made', color: opBlue, bg: opBlueBg),
        if (q > 0) ...[
          const SizedBox(width: 4),
          SoftPill('${fmtQty(q)} passed', color: opGreen, bg: opGreenBg),
        ],
        if (r > 0) ...[
          const SizedBox(width: 4),
          SoftPill('${fmtQty(r)} rejected', color: opRed, bg: opRedBg),
        ],
      ],
    );
  }

  Widget _logRow(OperatorController c, LedgerEntry e) {
    final photos = c.entryPhotos[e.id] ?? const <AttachmentItem>[];
    final Color color;
    final IconData icon;
    final String what;
    // Loader hand-offs first — they are the only rows with a "from" stage,
    // and "Rejected (loader)" must not read like a QC rejection.
    if (e.isIssuedLoader) {
      color = opGreen;
      icon = Icons.local_shipping_outlined;
      what = 'Issued via loader ${fmtQty(e.qty)} ${e.flow}';
    } else if (e.isReceivedLoader) {
      color = opBlue;
      icon = Icons.call_received_rounded;
      what = 'Received via loader ${fmtQty(e.qty)} ${e.flow}';
    } else if (e.isRejectedLoader) {
      color = opRed;
      icon = Icons.assignment_return_outlined;
      what = 'Rejected by next stage ${fmtQty(e.qty)} ${e.flow}';
    } else if (e.isProduce) {
      color = opBlue;
      icon = Icons.play_arrow_rounded;
      what = 'Produced ${fmtQty(e.qty)} pc';
    } else if (e.isQc) {
      color = opGreen;
      icon = Icons.verified_outlined;
      what = 'QC passed ${fmtQty(e.qty)}';
    } else if (e.isProgress) {
      color = opPrimary;
      icon = Icons.timelapse_rounded;
      what = e.qty > 0
          ? 'Work progress ${e.pct.toStringAsFixed(0)}% · ${fmtQty(e.qty)} pcs in progress'
          : 'Work progress ${e.pct.toStringAsFixed(0)}%';
    } else if (e.isReject) {
      color = opRed;
      icon = Icons.block_rounded;
      what =
          'Rejected ${fmtQty(e.qty)}${e.disposition.isNotEmpty ? ' · ${e.disposition}' : ''}';
    } else {
      color = opPurple;
      icon = Icons.send_rounded;
      what = 'Issued ${fmtQty(e.qty)} forward';
    }
    // Name the part when the entry was recorded against one — otherwise
    // "Produced 1" says nothing about which of the five things it was.
    final label = e.partname.isEmpty ? what : '$what · ${e.partname}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: newTextPrimary,
                  ),
                ),
              ),
              Text(
                [
                  if (e.username.isNotEmpty) e.username,
                  if (e.time.isNotEmpty) e.time,
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: newTextHint,
                ),
              ),
            ],
          ),
          // The operator's own note (the backend's "Produced (mobile)"
          // boilerplate is filtered out), plus the loader on a hand-off.
          if (e.note.isNotEmpty || e.loadername.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 3),
              child: Text(
                [
                  if (e.note.isNotEmpty) e.note,
                  if (e.loadername.isNotEmpty) 'Loader: ${e.loadername}',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                  height: 1.35,
                ),
              ),
            ),
          // Photos saved with this entry — so a 19-Sep photo sits under 19 Sep.
          // Produce / QC rows keep theirs in the attachment store; a progress
          // update brings its own presigned URLs.
          if (photos.isNotEmpty || e.photoUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 6, bottom: 2),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...photos.map((a) => _thumb(a, 56)),
                  ...e.photoUrls.map((u) => _urlThumb(u, 56)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Photo gallery (attachment/list, one record per challan) ──

  Widget _gallery(OperatorController c) => Container(
    padding: const EdgeInsets.all(10),
    decoration: opCard(radius: 14),
    child: c.galleryLoading && c.gallery.isEmpty
        ? const SizedBox(
            height: 60,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: c.gallery.map((a) => _thumb(a, 72)).toList(),
          ),
  );

  /// One tappable thumbnail (image, or a file icon for PDFs etc.).
  /// Thumbnail for a plain URL — progress updates return presigned S3 links
  /// rather than attachment records.
  Widget _urlThumb(String url, double size) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: () => Get.to(() => _PhotoViewer(url, 'Photo')),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: size,
        height: size,
        color: newSurfaceColor,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.broken_image_outlined, color: newTextHint),
        ),
      ),
    ),
  );

  Widget _thumb(AttachmentItem a, double size) {
    final isImage = RegExp(
      r'.(jpe?g|png|webp|gif)$',
      caseSensitive: false,
    ).hasMatch(a.fileName.isNotEmpty ? a.fileName : a.objectKey);
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () => Get.to(() => _PhotoViewer(a.url, a.fileName)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: size,
          height: size,
          color: newSurfaceColor,
          child: isImage
              ? Image.network(
                  a.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: newTextHint,
                  ),
                )
              : const Icon(
                  Icons.insert_drive_file_outlined,
                  color: newTextHint,
                ),
        ),
      ),
    );
  }

  // ── Locked until the incoming consignment is accepted ──

  Widget _lockedByConsignment(
    OperatorController c,
    Consignment cn,
  ) => Container(
    padding: const EdgeInsets.all(13),
    decoration: opCard(border: opAmber.withValues(alpha: 0.5), radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 18, color: opAmber),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${_title(cn.tostagename)} production stays locked until you accept this consignment.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8A5A00),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${fmtQty(cn.qty)} pcs in transit from ${_title(cn.fromstagename)}'
          '${cn.loadername.isNotEmpty ? ' · ${cn.loadername}' : ''}',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: newTextSecondary,
          ),
        ),
        const SizedBox(height: 10),
        BigButton(
          'Receive consignment',
          icon: Icons.local_shipping_outlined,
          gradient: opGreenGradient,
          onTap: () => Get.to(() => OperatorReceiveView(cn: cn)),
        ),
      ],
    ),
  );

  /// Issue card for a stage whose work goes to two or more stages.
  ///
  /// Full qty: every destination owes its own full qty, so each gets its own
  /// row and its own Issue button, and sending to one does not reduce the
  /// others. Shared qty: the destinations divide the QC-passed qty, so one
  /// button opens a sheet with a box per stage.
  Widget _splitIssueCard(
    BuildContext context,
    OperatorController c,
    OperatorJob j,
  ) {
    final opts = c.nextOptions;
    final shared = c.isSharedSplit;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: opCard(border: opGreen.withValues(alpha: 0.4), radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split_rounded, size: 16, color: opGreen),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Work splits into ${opts.length} stages',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
              ),
              SoftPill(
                shared ? 'Shared qty' : 'Full qty each',
                color: opPrimary,
                bg: opPurpleBg,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tri(fmtQty(j.producedqty), 'Produced'),
              _tri(fmtQty(j.qcqty), 'QC passed', color: opGreen),
              _tri(
                fmtQty(shared ? c.sharedRemaining : c.toIssue),
                'To issue',
                color: opGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final o in opts) ...[
            _splitRow(context, c, o, shared: shared),
            const SizedBox(height: 8),
          ],
          if (shared) ...[
            const SizedBox(height: 2),
            BigButton(
              'Issue to stages',
              icon: Icons.send_rounded,
              gradient: opGreenGradient,
              onTap: c.sharedRemaining <= 0
                  ? null
                  : () {
                      c.prepareSharedQty();
                      showGatePassSheet(context, c);
                    },
            ),
          ],
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: newTextHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shared
                      ? 'Each piece takes one route, so the stages share the '
                            '${fmtQty(j.qcqty)} QC-passed pcs between them.'
                      : 'Each next stage needs its own ${fmtQty(j.qcqty)}. '
                            'Sending to one does not reduce the others.',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: newTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _splitRow(
    BuildContext context,
    OperatorController c,
    NextStageOption o, {
    required bool shared,
  }) {
    final tone = stageColor(o.stagename);
    final done = o.allSent || c.maxIssuableTo(o) <= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
      decoration: BoxDecoration(
        color: done ? opGreenBg.withValues(alpha: 0.45) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? opGreen.withValues(alpha: 0.35) : newBorderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: tone,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title(o.stagename),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  o.sentLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: done ? opGreen : newTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Shared mode issues every stage together, so no per-row button.
          if (done)
            const SoftPill('All sent', color: opGreen, bg: opGreenBg)
          else if (!shared)
            SmallButton(
              'Issue',
              color: opGreen,
              icon: Icons.arrow_forward_rounded,
              onTap: () {
                c.beginIssueTo(o);
                showGatePassSheet(context, c);
              },
            ),
        ],
      ),
    );
  }

  /// The route line: what this stage waits for and what it feeds.
  Widget _routeLine(OperatorController c, OperatorJob j) {
    final here = c.trail.where((r) => r.stageid == j.stageid).firstOrNull;
    final waits = here?.waitsfor ?? j.waitsfor;
    final next = here?.nextstages ?? j.nextstages;
    if (waits.isEmpty && next.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: opCard(radius: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROUTE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: newTextSecondary,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (waits.isNotEmpty) ...[
                for (final s in waits.split('+').map((s) => s.trim()))
                  _routeChip(s, faded: true),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: newTextHint,
                ),
              ],
              _routeChip(j.stagename, here: true),
              if (next.isNotEmpty) ...[
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: newTextHint,
                ),
                for (final s in next.split('+').map((s) => s.trim()))
                  _routeChip(s),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeChip(String name, {bool here = false, bool faded = false}) {
    final tone = stageColor(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: here ? tone : tone.withValues(alpha: faded ? 0.08 : 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _title(name),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: here ? Colors.white : tone,
        ),
      ),
    );
  }

  /// A joining stage that has made everything it can: the missing parts are
  /// named so the operator knows who to chase, not just that it is locked.
  Widget _waitingForParts(OperatorJob j) {
    final missing = j.parts.where((p) => !p.arrived).toList();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: opCard(border: opAmber.withValues(alpha: 0.45), radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: opAmber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Waiting for parts'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
              ),
              if (j.waitsfor.isNotEmpty)
                SoftPill(j.waitsfor, color: opAmber, bg: opAmberBg),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            missing.isEmpty
                ? 'Everything that can be made from the parts received is '
                      'done. Production opens again when more arrive.'
                : 'Still to come: ${missing.map((p) => _title(p.stagename)).join(', ')}. '
                      'Production opens again as soon as they hand over.',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
              height: 1.4,
            ),
          ),
          if (j.parts.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final p in j.parts)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: p.arrived ? opGreenBg : opBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: p.arrived ? opGreenBg : newBorderColor,
                      ),
                    ),
                    child: Text(
                      '${_title(p.stagename)} ${fmtQty(p.qty)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: p.arrived ? opGreen : newTextHint,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Parts at this stage. Display only — the operator still records the whole
  /// item, so there is deliberately no qty box or button per part.
  Widget _partsCard(OperatorJob j) {
    if (j.subitems.isEmpty) return const SizedBox.shrink();
    final made = j.madeHere, incoming = j.comesIn;
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: opCard(radius: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: opPurpleBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.category_outlined,
                  size: 15,
                  color: opPrimary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Parts'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
              ),
              if (j.buildsFinishedItem)
                const SoftPill(
                  '→ finished item',
                  color: opGreen,
                  bg: opGreenBg,
                ),
            ],
          ),
          if (incoming.isNotEmpty) ...[
            const SizedBox(height: 11),
            const FieldLabel('Comes in'),
            _partChips(incoming, made: false),
          ],
          if (made.isNotEmpty) ...[
            SizedBox(height: incoming.isEmpty ? 11 : 10),
            const FieldLabel('Make here'),
            _partChips(made, made: true),
          ],
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: newTextHint,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Quantities are per finished piece. Record production for '
                  'the whole item as usual — parts are not counted separately.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _partChips(List<JobSubItem> parts, {required bool made}) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: [
      for (final p in parts)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: made ? opPrimary : newSurfaceColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: made ? opPrimary : newBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: made ? Colors.white : newTextPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                made
                    ? '${fmtQty(p.totalqty)} for this job'
                    // A vendor part has no origin stage — "Vendor" is the
                    // whole answer, and its stage id is 0.
                    : p.isVendor
                    ? 'from Vendor'
                    : 'from ${_title(p.originLabel)}',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: made
                      ? Colors.white.withValues(alpha: 0.85)
                      : newTextSecondary,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: newTextSecondary,
      ),
    ),
  );
}

class _Tick extends StatelessWidget {
  final String t;
  const _Tick(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
    style: const TextStyle(
      fontSize: 8.5,
      fontWeight: FontWeight.w700,
      color: newTextHint,
    ),
  );
}

/// White knob with a coloured ring, like the mockup slider.
class _RingThumb extends SliderComponentShape {
  final Color ring;
  const _RingThumb(this.ring);

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center.translate(0, 2),
      9,
      Paint()
        ..color = ring.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

/// Full-screen, pinch-zoomable view of one gallery photo.
class _PhotoViewer extends StatelessWidget {
  final String url;
  final String name;
  const _PhotoViewer(this.url, this.name);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: Text(name, style: const TextStyle(fontSize: 13)),
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
