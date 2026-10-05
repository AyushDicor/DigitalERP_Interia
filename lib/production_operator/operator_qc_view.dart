import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_sendback_form.dart';
import 'operator_widgets.dart';

const qcRejectReasons = [
  'Finish defect',
  'Dimension out of tolerance',
  'Damage / crack',
  'Wrong material',
  'Missing component',
  'Other',
];

/// QC entry for one produced lot: passed / rejected qty (pass + reject ≤ lot),
/// QC date, reject reason + defect photo (required when rejecting), remarks.
/// Rejecting also picks a disposition inline — Rework (back to the operator
/// as a Rework job) or Scrap (write-off) — and posts it with `qcreject`.
class OperatorQcView extends StatelessWidget {
  /// `tag` selects the controller: null = operator module, [OperatorController.qcTag]
  /// = Quality Check module.
  const OperatorQcView({super.key, this.tag});
  final String? tag;

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    tag: tag,
    builder: (c) {
      final j = c.qcJob;
      if (j == null) return const Scaffold(body: SizedBox());
      final pass = c.qcPass, rej = c.qcReject;
      final lot = j.qcPending;
      final over = pass + rej > lot;
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
                'Quality Check'.tr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                '${_title(j.stagename)} · ${j.challanno.isNotEmpty ? j.challanno : 'Challan ${j.challanid}'}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 30),
          children: [
            if (c.demoMode) const DemoBanner(),
            _summary(j),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: opCard(
                border: (rej > 0 ? opRed : opGreen).withValues(alpha: 0.45),
                radius: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: rej > 0 ? opRed : opGreen,
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Check the lot',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: newTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const FieldLabel('QC date'),
                  // Tappable — a lot checked yesterday can be booked on it.
                  ValueBox(
                    DateFormat('dd-MM-yyyy').format(c.qcDate),
                    icon: Icons.edit_calendar_outlined,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: c.qcDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 60),
                        ),
                        lastDate: DateTime.now(),
                        helpText: 'QC date (back-date allowed)',
                      );
                      if (d != null) c.setQcDate(d);
                    },
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: _qtyField(
                          'Passed',
                          c.qcPassCtrl,
                          opGreen,
                          c.qcChanged,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _qtyField(
                          'Rejected',
                          c.qcRejectCtrl,
                          opRed,
                          c.qcChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _resultChip(
                          '${fmtQty(pass)} Passed',
                          opGreen,
                          pass > 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _resultChip(
                          '${fmtQty(rej)} Rejected',
                          opRed,
                          rej > 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: over ? opRedBg : newSurfaceColor,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: over ? opRed : newBorderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          over
                              ? Icons.error_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 12,
                          color: over ? opRed : newTextHint,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: over ? opRed : newTextSecondary,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'pass + reject ≤ produced (',
                                ),
                                TextSpan(
                                  text: fmtQty(lot),
                                  style: TextStyle(
                                    color: over ? opRed : newTextPrimary,
                                  ),
                                ),
                                const TextSpan(text: ')'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // A rejection no longer has one outcome: it can be fixed
                  // at this stage, or go back to whichever earlier stage
                  // caused it. The choice comes before everything else,
                  // because "send back" hands the rest of the form over.
                  if (rej > 0) ...[
                    const SizedBox(height: 12),
                    const FieldLabel('The rejected pieces: what now?'),
                    _rejectRoute(
                      c,
                      'here',
                      'Fix it here',
                      'Touch-up or repair at ${_title(j.stagename)}. Nothing moves.',
                      Icons.build_rounded,
                    ),
                    const SizedBox(height: 8),
                    _rejectRoute(
                      c,
                      'back',
                      'Send it back',
                      'To any earlier stage it came through, then back here.',
                      Icons.keyboard_return_rounded,
                    ),
                  ],
                  // Every rejection is a Rework while [kAllowScrap] is off —
                  // nothing to choose, so nothing is asked.
                  if (rej > 0 && kAllowScrap && !c.qcSendsBack) ...[
                    const SizedBox(height: 12),
                    // Disposition inline (per backend's UI): Rework sends the
                    // pieces back to the operator as a Rework job; Scrap
                    // writes them off.
                    const FieldLabel('Disposition'),
                    Row(
                      children: [
                        Expanded(
                          child: _dispChip(
                            c,
                            'Rework',
                            Icons.replay_rounded,
                            opAmber,
                            opAmberBg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _dispChip(
                            c,
                            'Scrap',
                            Icons.delete_outline_rounded,
                            opRed,
                            opRedBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const FieldLabel('Reject reason (required)'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: newSurfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: c.qcReason.isEmpty
                              ? opRed.withValues(alpha: 0.5)
                              : newBorderColor,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: c.qcReason.isEmpty ? null : c.qcReason,
                          hint: const Text(
                            'Pick a reason',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: newTextHint,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: newTextPrimary,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: newTextSecondary,
                          ),
                          items: qcRejectReasons
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList(),
                          onChanged: (v) => c.setQcReason(v ?? ''),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 11),
                  const FieldLabel('Remarks'),
                  TextField(
                    controller: c.qcRemarksCtrl,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: opInput(
                      hint: rej > 0
                          ? 'e.g. 2 pcs — laminate bubble on door…'
                          : 'e.g. Finish & edges OK…',
                    ),
                  ),
                  const SizedBox(height: 11),
                  FieldLabel(rej > 0 ? 'Photo of defect (required)' : 'Photo'),
                  PhotoStrip(
                    photos: c.qcPhoto == null ? const [] : [c.qcPhoto!],
                    onAdd: c.pickQcPhoto,
                    onRemove: (_) => c.clearQcPhoto(),
                    hint: 'Upload / take a photo',
                    accent: rej > 0 ? opRed : opGreen,
                  ),
                  const SizedBox(height: 13),
                  BigButton(
                    rej <= 0
                        ? 'Save QC'
                        : c.qcSendsBack
                        ? 'Next: where to send it'
                        : (kAllowScrap
                              ? 'Record Reject → ${c.qcDisposition}'
                              : 'Record Reject → Rework'),
                    icon: rej > 0
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    busy: c.saving,
                    gradient: rej > 0
                        ? (c.qcSendsBack ? opAmberGradient : null)
                        : opGreenGradient,
                    color: rej > 0 && !c.qcSendsBack
                        ? (c.qcDisposition == 'Scrap' ? opRed : opAmber)
                        : null,
                    // Sending back is one call with the rejection, so nothing
                    // is written until the next screen is submitted.
                    onTap: c.qcSendsBack && rej > 0
                        ? () async {
                            await c.openQcSendBack();
                            Get.to(() => const OperatorSendBackForm());
                          }
                        : () => _save(context, c),
                  ),
                  if (rej > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      c.qcSendsBack
                          ? 'Next you pick the stage that fixes it and how it comes back. Nothing is saved until then.'
                          : c.qcDisposition == 'Rework'
                          ? '${fmtQty(rej)} pcs go back to the operator as a Rework job; passed pcs move on.'
                          : '${fmtQty(rej)} pcs are written off; passed pcs move on.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: newTextHint,
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
    },
  );

  // Navigator, not Get.back(): with a snackbar open, Get.back() only closes the
  // snackbar and returns (GetX 4.7) — the screen would stay put after saving.
  Future<void> _save(BuildContext context, OperatorController c) async {
    final needsReject = await c.saveQcPass();
    if (needsReject == null) return; // validation / API failure shown
    if (!needsReject) {
      if (context.mounted) Navigator.of(context).pop();
      c.backToJobsHome();
      return;
    }
    final ok = await c.saveQcReject(c.qcDisposition);
    if (ok && context.mounted) Navigator.of(context).pop();
    if (ok) c.backToJobsHome();
  }

  /// One of the two outcomes for a rejected piece. Drawn as a radio row
  /// rather than a chip: they are not interchangeable — one keeps the piece
  /// here, the other moves it to another department.
  Widget _rejectRoute(
    OperatorController c,
    String value,
    String title,
    String sub,
    IconData icon,
  ) {
    final on = c.qcRejectAction == value;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => c.setQcRejectAction(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: on ? opAmberBg : newSurfaceColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: on ? opAmber : newBorderColor,
            width: on ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: on ? opAmber : newTextHint,
                  width: on ? 5 : 1.6,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Icon(icon, size: 15, color: on ? opAmber : newTextSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                    ),
                  ),
                  Text(
                    sub,
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
          ],
        ),
      ),
    );
  }

  Widget _dispChip(
    OperatorController c,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    final on = c.qcDisposition == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => c.setQcDisposition(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: on ? bg : newSurfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: on ? color : newBorderColor,
            width: on ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: on ? color : newTextSecondary),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: on ? color : newTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _title(String s) => s.isEmpty
      ? s
      : s
            .toLowerCase()
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');

  Widget _summary(OperatorJob j) => Container(
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
            StagePill(j.stagename),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, color: newBorderColor),
        const SizedBox(height: 10),
        Row(
          children: [
            _tri(fmtQty(j.producedqty), 'Produced'),
            _tri(
              fmtQty(j.qcqty),
              'Passed',
              color: j.qcqty > 0 ? opGreen : null,
            ),
            _tri(
              fmtQty(j.qcPending),
              'Pending',
              color: j.qcPending > 0 ? opAmber : null,
            ),
          ],
        ),
      ],
    ),
  );

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

  Widget _qtyField(
    String label,
    TextEditingController ctrl,
    Color color,
    VoidCallback onChanged,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: (double.tryParse(ctrl.text) ?? 0) > 0 ? color : newBorderColor,
        width: 1.5,
      ),
    ),
    child: Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: color,
          ),
        ),
        TextField(
          controller: ctrl,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: newTextPrimary,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: '0',
            hintStyle: TextStyle(color: newTextHint),
            contentPadding: EdgeInsets.symmetric(vertical: 4),
          ),
        ),
      ],
    ),
  );

  Widget _resultChip(String text, Color color, bool on) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: on ? color.withValues(alpha: 0.1) : newSurfaceColor,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: on ? color : newBorderColor, width: 1.5),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: on ? color : newTextSecondary,
      ),
    ),
  );
}
