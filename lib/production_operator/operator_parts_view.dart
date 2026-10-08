// Recording one part at a time.
//
// A stage planned with parts (`partmode == 1`) does not record the whole item:
// METAL makes a frame and four legs, and each is produced, checked and handed
// on by itself. This file is that screen section — a card per part with the
// four figures the operator cares about (Need / Made / QC / Sent) and the
// actions the server says are currently possible.
//
// Every limit comes from the API (`canproduceqty`, `canqcqty`, `canissueqty`).
// Nothing is recomputed here, so a greyed-out button and a server refusal can
// never tell the operator different things.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_qc_view.dart' show qcRejectReasons;
import 'operator_sendback_form.dart';
import 'operator_widgets.dart';

/// The parts section of the job screen, used instead of the item-level
/// production card when the stage records parts.
class JobPartsSection extends StatelessWidget {
  const JobPartsSection({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      final j = c.job;
      if (j == null || !j.isPartMode) return const SizedBox.shrink();
      final incoming = j.comesIn, made = j.madeHere;
      final batch = c.batchIssueGroup;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Several parts finished and all bound for the same stage: it is
          // one consignment on one loader, so offer one hand-over rather
          // than making the operator type the loader and shoot the receipt
          // once per part.
          // Hand-over is the maker's job, never the QC login's.
          if (batch != null && !(j.canqc))
            _batchIssueCard(context, c, batch.value),
          if (incoming.isNotEmpty) ...[
            _Label('Coming in'.tr),
            ...incoming.map((p) => _PartCard(part: p)),
          ],
          if (made.isNotEmpty) ...[
            _Label(incoming.isEmpty ? 'Make here' : 'Make here as well'),
            ...made.map((p) => _PartCard(part: p)),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(3, 2, 3, 10),
            child: Row(
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
                    'Each part is recorded on its own. The item moves forward '
                    'by itself once a full set is done.',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: newTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(3, 4, 3, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: newTextSecondary,
      ),
    ),
  );
}

/// One part: the four figures, then whatever the operator can do next.
class _PartCard extends StatelessWidget {
  final JobSubItem part;
  const _PartCard({required this.part});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      final p = part;
      final tone = _statusTone(p);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: opCard(
          border: _hasAction(c, p) ? tone.fg.withValues(alpha: 0.4) : null,
          radius: 14,
        ),
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
                        p.partname,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: newTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Bought in, not made: say so plainly. Its origin
                          // stage id is 0, so a stage name would be wrong
                          // and "0" would be meaningless.
                          if (p.isVendor) ...[
                            const SoftPill(
                              'VENDOR',
                              color: opBlue,
                              bg: opBlueBg,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              p.isMadeHere
                                  ? '×${fmtQty(p.qtyperpiece)} per piece'
                                  : p.isVendor
                                  ? 'bought in · ×${fmtQty(p.qtyperpiece)} per piece'
                                  : 'from ${_t(p.originLabel)} · ×${fmtQty(p.qtyperpiece)} per piece',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: newTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (p.status.isNotEmpty)
                  SoftPill(p.status, color: tone.fg, bg: tone.bg),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _fig('Need'.tr, p.needqty),
                _fig(
                  p.isMadeHere ? 'Made' : 'Done'.tr,
                  p.isMadeHere ? p.madeqty : p.goodqty,
                  color: opPrimary,
                ),
                _fig('QC'.tr, p.qcqty, color: opGreen),
                _fig('Sent'.tr, p.sentqty, color: opBlue),
              ],
            ),
            // What has arrived, for a part this stage only works on.
            if (!p.isMadeHere && (p.receivedqty > 0 || p.intransitqty > 0)) ...[
              const SizedBox(height: 9),
              _strip(
                p.intransitqty > 0
                    ? 'Received ${fmtQty(p.receivedqty)} · '
                          '${fmtQty(p.intransitqty)} still on the loader'
                    : 'Received ${fmtQty(p.receivedqty)} of ${fmtQty(p.needqty)}',
                p.intransitqty > 0 ? opBlue : opGreen,
                p.intransitqty > 0 ? opBlueBg : opGreenBg,
              ),
            ],
            if (p.rejectqty > 0) ...[
              const SizedBox(height: 9),
              _strip(
                '${fmtQty(p.rejectqty)} rejected — to make again',
                opAmber,
                opAmberBg,
              ),
            ],
            if (p.sendingqty > 0) ...[
              const SizedBox(height: 9),
              _strip(
                '${fmtQty(p.sendingqty)} on the loader to ${_t(p.nextstage)}',
                opBlue,
                opBlueBg,
              ),
            ],
            // QC is somebody else's job: the same rule as the item-level
            // flow, where only a login the backend flags (`canqc`) gets a
            // check button. A maker never passes their own work.
            if (!p.isfinal &&
                p.canQc &&
                _mayWork(c) &&
                !p.canProduce &&
                !p.canIssue) ...[
              const SizedBox(height: 9),
              _strip(
                '${fmtQty(p.canqcqty)} waiting for QC — quality check it on '
                'their own login.',
                opPurple,
                opPurpleBg,
              ),
            ],
            if (p.isfinal) ...[
              const SizedBox(height: 9),
              _strip(
                'Fitted into the item here — record the item, not the part.',
                newTextSecondary,
                newSurfaceColor,
              ),
            ] else if (_hasAction(c, p)) ...[
              const SizedBox(height: 12),
              _actions(context, c, p),
            ],
          ],
        ),
      );
    },
  );

  /// Who is looking at this job. The server sends the raw capability
  /// numbers to everyone — `canproduceqty` is "how many could still be
  /// made", not "you may make them" — so the role gate lives here:
  /// a QC login checks, the stage's own operator makes and hands over.
  bool _mayQc(OperatorController c) => c.job?.canqc ?? false;
  bool _mayWork(OperatorController c) => !(c.job?.canqc ?? false);

  bool _hasAction(OperatorController c, JobSubItem p) =>
      !p.isfinal &&
      ((p.canProduce && _mayWork(c)) ||
          (p.canQc && _mayQc(c)) ||
          (p.canIssue && _mayWork(c)));

  Widget _actions(BuildContext context, OperatorController c, JobSubItem p) {
    final buttons = <Widget>[
      if (p.canProduce && _mayWork(c))
        SmallButton(
          '${p.produceVerb} ${fmtQty(p.canproduceqty)}',
          color: opPrimary,
          icon: Icons.add_rounded,
          onTap: () => openPartProduceSheet(context, c, p),
        ),
      if (p.canQc && _mayQc(c))
        SmallButton(
          'QC ${fmtQty(p.canqcqty)}',
          color: opPurple,
          icon: Icons.verified_outlined,
          onTap: () => openPartQcSheet(context, c, p),
        ),
      if (p.canIssue && _mayWork(c))
        SmallButton(
          'Hand over ${fmtQty(p.canissueqty)} → ${_t(p.nextstage)}',
          color: opGreen,
          icon: Icons.arrow_forward_rounded,
          onTap: () => openPartIssueSheet(context, c, p),
        ),
    ];
    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  Widget _fig(String label, double value, {Color? color}) => Expanded(
    child: Column(
      children: [
        Text(
          fmtQty(value),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: value > 0 ? (color ?? newTextPrimary) : newTextHint,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: newTextSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _strip(String text, Color fg, Color bg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: fg,
        height: 1.35,
      ),
    ),
  );
}

// ── Sheets ───────────────────────────────────────────────────────────────────

/// Produce / work on some of one part.
void openPartProduceSheet(
  BuildContext context,
  OperatorController c,
  JobSubItem part,
) {
  final qtyCtrl = TextEditingController(text: fmtQty(part.canproduceqty));
  final remarksCtrl = TextEditingController();
  var photos = <PickedAttachment>[];
  _sheet(
    context,
    title: '${part.produceVerb} ${part.partname}',
    subtitle: '${fmtQty(part.canproduceqty)} left of ${fmtQty(part.needqty)}',
    accent: opPrimary,
    builder: (sheetContext, setSheet) => [
      _qtyField(qtyCtrl, part.canproduceqty, 'Qty'.tr),
      const SizedBox(height: 11),
      FieldLabel('Remarks (optional)'.tr),
      TextField(
        controller: remarksCtrl,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: opInput(hint: 'e.g. 1 leg left to weld'),
      ),
      const SizedBox(height: 12),
      FieldLabel('Photo'.tr),
      PhotoStrip(
        photos: photos,
        hint: 'Photo of the finished part (optional)',
        onAdd: () async {
          final picked = await pickAttachments(
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
          );
          if (picked.isNotEmpty)
            setSheet(() => photos = [...photos, ...picked]);
        },
        onRemove: (x) => setSheet(() => photos = [...photos]..remove(x)),
      ),
    ],
    action: 'Save'.tr,
    onAction: (sheetContext) async {
      final ok = await c.producePart(
        part,
        double.tryParse(qtyCtrl.text.trim()) ?? 0,
        remarks: remarksCtrl.text,
        photos: photos,
      );
      if (ok && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
        // Freshly loaded My Jobs: the figures behind this screen have just been
        // recalculated on the server.
        c.backToJobsHome();
      }
    },
  );
}

/// QC one part: passed, or rejected with a reason.
void openPartQcSheet(
  BuildContext context,
  OperatorController c,
  JobSubItem part,
) {
  final passCtrl = TextEditingController(text: fmtQty(part.canqcqty));
  final rejectCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  String reason = '';
  PickedAttachment? photo;
  // false = remake it here (as before), true = send it to an earlier stage.
  bool sendBack = false;
  _sheet(
    context,
    title: 'QC ${part.partname}',
    subtitle: '${fmtQty(part.canqcqty)} waiting for a check',
    accent: opPurple,
    builder: (sheetContext, setSheet) {
      final rej = double.tryParse(rejectCtrl.text.trim()) ?? 0;
      return [
        Row(
          children: [
            Expanded(
              child: _qtyField(
                passCtrl,
                part.canqcqty,
                'Passed'.tr,
                onChanged: setSheet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _qtyField(
                rejectCtrl,
                part.canqcqty,
                'Rejected'.tr,
                onChanged: setSheet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FieldLabel('Remarks (optional)'.tr),
        TextField(
          controller: remarksCtrl,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: opInput(
            hint: rej > 0 ? 'What is wrong with it?' : 'e.g. finish & edges OK',
          ),
        ),
        const SizedBox(height: 12),
        FieldLabel(rej > 0 ? 'Photo of the defect' : 'Photo'.tr),
        PhotoStrip(
          photos: photo == null ? const [] : [photo!],
          accent: rej > 0 ? opRed : opPurple,
          hint: rej > 0
              ? 'Show what is wrong (optional)'
              : 'Photo of the checked part (optional)',
          onAdd: () async {
            final picked = await pickAttachments(
              allowedExtensions: const ['jpg', 'jpeg', 'png'],
            );
            if (picked.isNotEmpty) setSheet(() => photo = picked.first);
          },
          onRemove: (_) => setSheet(() => photo = null),
        ),
        if (rej > 0) ...[
          const SizedBox(height: 12),
          FieldLabel('Reject reason (required)'.tr),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final r in qcRejectReasons)
                InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => setSheet(() => reason = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: reason == r ? opRed : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: reason == r ? opRed : newBorderColor,
                      ),
                    ),
                    child: Text(
                      r,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: reason == r ? Colors.white : newTextSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // A rejected part does not have to be remade here. If the fault
          // came from an earlier stage, it goes back there and returns —
          // the same choice the item-level QC screen offers.
          FieldLabel('The rejected pieces: what now?'.tr),
          _qcRoute(
            'Fix it here'.tr,
            'Made again at this stage. Nothing moves.',
            Icons.build_rounded,
            !sendBack,
            () => setSheet(() => sendBack = false),
          ),
          const SizedBox(height: 7),
          _qcRoute(
            'Send it back'.tr,
            'To any earlier stage it came through, then back here.',
            Icons.keyboard_return_rounded,
            sendBack,
            () => setSheet(() => sendBack = true),
          ),
          const SizedBox(height: 8),
          Text(
            sendBack
                ? 'Next you pick the stage that fixes it. Nothing is saved until then.'
                : 'Rejected parts go back to be made again.',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: newTextHint,
              height: 1.35,
            ),
          ),
        ],
      ];
    },
    action: 'Save QC'.tr,
    actionLabel: () =>
        (double.tryParse(rejectCtrl.text.trim()) ?? 0) > 0 && sendBack
        ? 'Next: where to send it'
        : 'Save QC'.tr,
    onAction: (sheetContext) async {
      final rej = double.tryParse(rejectCtrl.text.trim()) ?? 0;
      // Reject-and-send-back is ONE call, so nothing is written here: the
      // form does both. Backing out of it must leave no half-record.
      if (rej > 0 && sendBack) {
        if (reason.trim().isEmpty) {
          opSnack('Reason'.tr, 'Pick why it is rejected.');
          return;
        }
        Navigator.of(sheetContext).pop();
        await c.openPartQcSendBack(
          part,
          rejectQty: rej,
          reason: reason,
          remarks: remarksCtrl.text,
        );
        Get.to(() => const OperatorSendBackForm());
        return;
      }
      final ok = await c.qcPart(
        part,
        pass: double.tryParse(passCtrl.text.trim()) ?? 0,
        reject: rej,
        reason: reason,
        remarks: remarksCtrl.text,
        photo: photo,
      );
      if (ok && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
        // Freshly loaded My Jobs: the figures behind this screen have just been
        // recalculated on the server.
        c.backToJobsHome();
      }
    },
  );
}

/// One of the two outcomes for a rejected part.
Widget _qcRoute(
  String title,
  String sub,
  IconData icon,
  bool on,
  VoidCallback onTap,
) => InkWell(
  borderRadius: BorderRadius.circular(11),
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: on ? opAmberBg : newSurfaceColor,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(
        color: on ? opAmber : newBorderColor,
        width: on ? 1.5 : 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: on ? opAmber : newTextHint,
              width: on ? 4.5 : 1.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 14, color: on ? opAmber : newTextSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

/// Hand a part to the stage the plan sends it to. The destination is fixed,
/// so it is shown, not chosen.
void openPartIssueSheet(
  BuildContext context,
  OperatorController c,
  JobSubItem part,
) {
  final qtyCtrl = TextEditingController(text: fmtQty(part.canissueqty));
  final loaderCtrl = TextEditingController(text: c.lastLoaderName);
  final remarksCtrl = TextEditingController();
  var issuedAt = DateTime.now();
  var receipt = <PickedAttachment>[];
  var photos = <PickedAttachment>[];
  _sheet(
    context,
    title: 'Hand over ${part.partname}',
    subtitle: 'to ${_t(part.nextstage)} · ${fmtQty(part.canissueqty)} ready',
    accent: opGreen,
    builder: (sheetContext, setSheet) => [
      _qtyField(qtyCtrl, part.canissueqty, 'Qty to hand over'),
      const SizedBox(height: 11),
      FieldLabel('Loader name'.tr),
      TextField(
        controller: loaderCtrl,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: opInput(hint: 'e.g. Ramesh Transport'),
      ),
      const SizedBox(height: 11),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel('Issue date'.tr),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: sheetContext,
                      initialDate: issuedAt,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 60),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setSheet(
                        () => issuedAt = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          issuedAt.hour,
                          issuedAt.minute,
                        ),
                      );
                    }
                  },
                  child: ValueBox(
                    DateFormat('dd-MM-yyyy').format(issuedAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel('Issue time'.tr),
                InkWell(
                  onTap: () async {
                    final x = await showTimePicker(
                      context: sheetContext,
                      initialTime: TimeOfDay.fromDateTime(issuedAt),
                    );
                    if (x != null) {
                      setSheet(
                        () => issuedAt = DateTime(
                          issuedAt.year,
                          issuedAt.month,
                          issuedAt.day,
                          x.hour,
                          x.minute,
                        ),
                      );
                    }
                  },
                  child: ValueBox(
                    DateFormat('hh:mm a').format(issuedAt),
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 11),
      // The gate pass does not leave without its receipt — same rule as the
      // item-level hand-off.
      FieldLabel('Issue receipt photo(s) — required'.tr),
      PhotoStrip(
        photos: receipt,
        accent: opGreen,
        hint: 'Signed gate pass / receipt',
        onAdd: () async {
          final picked = await pickAttachments(
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
          );
          if (picked.isNotEmpty) {
            setSheet(() => receipt = [...receipt, ...picked]);
          }
        },
        onRemove: (x) => setSheet(() => receipt = [...receipt]..remove(x)),
      ),
      const SizedBox(height: 11),
      FieldLabel('Item photo(s)'.tr),
      PhotoStrip(
        photos: photos,
        accent: opGreen,
        hint: 'Photo of what is going out (optional)',
        onAdd: () async {
          final picked = await pickAttachments(
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
          );
          if (picked.isNotEmpty)
            setSheet(() => photos = [...photos, ...picked]);
        },
        onRemove: (x) => setSheet(() => photos = [...photos]..remove(x)),
      ),
      const SizedBox(height: 11),
      FieldLabel('Remarks (optional)'.tr),
      TextField(
        controller: remarksCtrl,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: opInput(hint: 'Anything the next stage should know'),
      ),
      const SizedBox(height: 9),
      Text(
        '${_t(part.nextstage)} signs for it before it counts as received.',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: newTextHint,
          height: 1.4,
        ),
      ),
    ],
    action: 'Hand over'.tr,
    onAction: (sheetContext) async {
      final ok = await c.issuePartViaLoader(
        part,
        double.tryParse(qtyCtrl.text.trim()) ?? 0,
        loadername: loaderCtrl.text,
        issuedAt: issuedAt,
        remarks: remarksCtrl.text,
        receiptPhotos: receipt,
        itemPhotos: photos,
      );
      if (ok && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
        // Freshly loaded My Jobs: the figures behind this screen have just been
        // recalculated on the server.
        c.backToJobsHome();
      }
    },
  );
}

// ── Shared sheet chrome ──────────────────────────────────────────────────────

Widget _qtyField(
  TextEditingController ctrl,
  double max,
  String label, {
  void Function(VoidCallback)? onChanged,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    FieldLabel(label),
    TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [MaxQtyFormatter(max)],
      onChanged: onChanged == null ? null : (_) => onChanged(() {}),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      decoration: opInput(hint: '0').copyWith(
        suffixText: 'max ${fmtQty(max)}',
        suffixStyle: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: newTextHint,
        ),
      ),
    ),
  ],
);

/// One sheet shape for all three actions — keyboard-safe, like the loader
/// sheet: the height comes off what is LEFT once the keyboard is up.
void _sheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Color accent,
  required List<Widget> Function(BuildContext, void Function(VoidCallback))
  builder,
  required String action,

  /// Overrides [action] when the label depends on what the sheet is showing
  /// (the QC sheet's button changes once "send it back" is chosen).
  String Function()? actionLabel,
  required Future<void> Function(BuildContext) onAction,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) {
        final media = MediaQuery.of(sheetContext);
        final maxHeight =
            media.size.height -
            media.viewInsets.bottom -
            media.padding.top -
            12;
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight < 260 ? 260 : maxHeight,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                15,
                12,
                15,
                16 + (media.viewInsets.bottom > 0 ? 0 : media.padding.bottom),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: newBorderColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: newTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
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
                  ...builder(sheetContext, setSheet),
                  const SizedBox(height: 16),
                  GetBuilder<OperatorController>(
                    builder: (c) => BigButton(
                      actionLabel?.call() ?? action,
                      icon: Icons.check_rounded,
                      busy: c.saving,
                      color: accent,
                      onTap: () => onAction(sheetContext),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

({Color bg, Color fg}) _statusTone(JobSubItem p) {
  final s = p.status.toLowerCase();
  if (s.contains('rework')) return (fg: opAmber, bg: opAmberBg);
  if (s.contains('transit') || s.contains('loader')) {
    return (fg: opBlue, bg: opBlueBg);
  }
  if (s.contains('ready')) return (fg: opGreen, bg: opGreenBg);
  if (s.contains('awaiting') || s.contains('progress')) {
    return (fg: opPurple, bg: opPurpleBg);
  }
  if (s.contains('done') ||
      s.contains('sent') ||
      s.contains('received') ||
      s.contains('made with')) {
    return (fg: opGreen, bg: opGreenBg);
  }
  return (fg: newTextSecondary, bg: newSurfaceColor);
}

String _t(String s) => s.isEmpty
    ? s
    : s
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

/// "Hand over all 8 → Carpentry Assembly" — one gate pass for every part
/// that is ready and bound for the same stage.
Widget _batchIssueCard(
  BuildContext context,
  OperatorController c,
  List<JobSubItem> parts,
) {
  final total = parts.fold<double>(0, (a, p) => a + p.canissueqty);
  final where = parts.first.nextstage;
  return Container(
    margin: const EdgeInsets.only(bottom: 11),
    padding: const EdgeInsets.all(12),
    decoration: opCard(border: opGreen.withValues(alpha: 0.45), radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping_rounded, size: 16, color: opGreen),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${parts.length} parts ready for ${_t(where)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
            ),
            SoftPill('${fmtQty(total)} pcs', color: opGreen, bg: opGreenBg),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          parts
              .map((p) => '${p.partname} ${fmtQty(p.canissueqty)}')
              .join(' · '),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: newTextSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        BigButton(
          'Hand over all → ${_t(where)}',
          icon: Icons.local_shipping_outlined,
          busy: c.saving,
          gradient: opGreenGradient,
          onTap: () => openBatchIssueSheet(context, c, parts),
        ),
        const SizedBox(height: 5),
        const Text(
          'One loader, one receipt — each part is still recorded separately.',
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

/// Hand several parts over together: a qty per part, then the one gate pass
/// they all travel under.
void openBatchIssueSheet(
  BuildContext context,
  OperatorController c,
  List<JobSubItem> parts,
) {
  final qtyCtrls = {
    for (final p in parts)
      p.partid: TextEditingController(text: fmtQty(p.canissueqty)),
  };
  final loaderCtrl = TextEditingController(text: c.lastLoaderName);
  final remarksCtrl = TextEditingController();
  var issuedAt = DateTime.now();
  var receipt = <PickedAttachment>[];
  var photos = <PickedAttachment>[];
  _sheet(
    context,
    title: 'Hand over ${parts.length} parts',
    subtitle: 'to ${_t(parts.first.nextstage)} · one loader',
    accent: opGreen,
    builder: (sheetContext, setSheet) => [
      for (final p in parts) ...[
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.partname,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                    ),
                  ),
                  Text(
                    '${fmtQty(p.canissueqty)} QC-passed, not sent',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: newTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: TextField(
                controller: qtyCtrls[p.partid],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [MaxQtyFormatter(p.canissueqty)],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                decoration: opInput(hint: '0').copyWith(
                  suffixText: 'max ${fmtQty(p.canissueqty)}',
                  suffixStyle: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: newTextHint,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
      ],
      const Divider(height: 1),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel('Issue date'.tr),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: sheetContext,
                      initialDate: issuedAt,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 60),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setSheet(
                        () => issuedAt = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          issuedAt.hour,
                          issuedAt.minute,
                        ),
                      );
                    }
                  },
                  child: ValueBox(
                    DateFormat('dd-MM-yyyy').format(issuedAt),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FieldLabel('Issue time'.tr),
                InkWell(
                  onTap: () async {
                    final x = await showTimePicker(
                      context: sheetContext,
                      initialTime: TimeOfDay.fromDateTime(issuedAt),
                    );
                    if (x != null) {
                      setSheet(
                        () => issuedAt = DateTime(
                          issuedAt.year,
                          issuedAt.month,
                          issuedAt.day,
                          x.hour,
                          x.minute,
                        ),
                      );
                    }
                  },
                  child: ValueBox(
                    DateFormat('hh:mm a').format(issuedAt),
                    icon: Icons.schedule_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 11),
      FieldLabel('Loader name'.tr),
      TextField(
        controller: loaderCtrl,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        decoration: opInput(hint: 'Who is carrying it'),
      ),
      const SizedBox(height: 11),
      FieldLabel('Issue receipt photo(s) — required'.tr),
      PhotoStrip(
        photos: receipt,
        accent: opGreen,
        hint: 'One signed gate pass for the whole load',
        onAdd: () async {
          final picked = await pickAttachments(
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
          );
          if (picked.isNotEmpty) {
            setSheet(() => receipt = [...receipt, ...picked]);
          }
        },
        onRemove: (x) => setSheet(() => receipt = [...receipt]..remove(x)),
      ),
      const SizedBox(height: 11),
      FieldLabel('Item photo(s)'.tr),
      PhotoStrip(
        photos: photos,
        accent: opGreen,
        hint: 'Photo of what is going out (optional)',
        onAdd: () async {
          final picked = await pickAttachments(
            allowedExtensions: const ['jpg', 'jpeg', 'png'],
          );
          if (picked.isNotEmpty)
            setSheet(() => photos = [...photos, ...picked]);
        },
        onRemove: (x) => setSheet(() => photos = [...photos]..remove(x)),
      ),
      const SizedBox(height: 11),
      FieldLabel('Remarks (optional)'.tr),
      TextField(
        controller: remarksCtrl,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: opInput(hint: 'Anything the next stage should know'),
      ),
      const SizedBox(height: 9),
      const Text(
        'The parts are recorded one by one, so if the server refuses one the '
        'earlier ones have already gone — the message says which.',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: newTextHint,
          height: 1.35,
        ),
      ),
    ],
    action: 'Hand over'.tr,
    onAction: (sheetContext) async {
      final ok = await c.issuePartsTogether(
        {
          for (final p in parts)
            p: double.tryParse(qtyCtrls[p.partid]?.text.trim() ?? '') ?? 0,
        },
        loadername: loaderCtrl.text,
        issuedAt: issuedAt,
        remarks: remarksCtrl.text,
        receiptPhotos: receipt,
        itemPhotos: photos,
      );
      if (ok && sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
        c.backToJobsHome();
      }
    },
  );
}
