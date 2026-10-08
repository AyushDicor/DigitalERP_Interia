import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

/// Gate pass for "Issue via Loader": loader name, issue date/time, issue
/// receipt photo(s), item photo(s), remarks → uploads the photos, then issues
/// the QC-passed qty with the gate-pass fields. Pops with `true` on success.
/// Flutter's own modal sheet, not `Get.bottomSheet`: GetX does not reposition
/// its sheet correctly once the keyboard is up (the sheet ended up pinned
/// under the status bar). `useSafeArea` also keeps it clear of the notch.
Future<bool> showGatePassSheet(
  BuildContext context,
  OperatorController c,
) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GatePassSheet(),
  );
  return r == true;
}

class _GatePassSheet extends StatefulWidget {
  const _GatePassSheet();
  @override
  State<_GatePassSheet> createState() => _GatePassSheetState();
}

class _GatePassSheetState extends State<_GatePassSheet> {
  late final loaderCtrl = TextEditingController(
    text: Get.find<OperatorController>().lastLoaderName,
  );
  final remarksCtrl = TextEditingController();
  DateTime issuedAt = DateTime.now();
  List<PickedAttachment> receipt = [];
  List<PickedAttachment> items = [];

  @override
  void dispose() {
    loaderCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: issuedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(
        () => issuedAt = DateTime(
          d.year,
          d.month,
          d.day,
          issuedAt.hour,
          issuedAt.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(issuedAt),
    );
    if (t != null) {
      setState(
        () => issuedAt = DateTime(
          issuedAt.year,
          issuedAt.month,
          issuedAt.day,
          t.hour,
          t.minute,
        ),
      );
    }
  }

  Future<void> _pick(bool forReceipt) async {
    final picked = await pickAttachments(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked.isEmpty) return;
    setState(() {
      if (forReceipt) {
        receipt = [...receipt, ...picked];
      } else {
        items = [...items, ...picked];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OperatorController>();
    final j = c.job;
    // The card's qty field is the source of truth; fall back to what is
    // still issuable so the header never reads "0 PCS".
    final shared = c.isSharedSplit && c.sharedQty.isNotEmpty;
    final typed = double.tryParse(c.issueQtyCtrl.text.trim()) ?? 0;
    final qty = shared ? c.sharedEntered : (typed > 0 ? typed : c.toIssue);
    // On a full-qty split the header names the stage whose Issue button was
    // tapped, not the API's "most owed" default.
    final to = shared
        ? '${c.nextOptions.length} stages'
        : (c.issueTarget?.stagename ?? c.next?.stagename ?? 'next stage');
    final media = MediaQuery.of(context);
    // Height must come off what is LEFT once the keyboard is up, otherwise
    // the sheet keeps its full height, gets pushed up and runs off the top
    // of the screen under the status bar.
    final maxHeight =
        media.size.height - media.viewInsets.bottom - media.padding.top - 12;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight < 260 ? 260 : maxHeight,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          // Keep the focused field clear of the keyboard as it opens.
          padding: EdgeInsets.fromLTRB(
            14,
            12,
            14,
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: opGreenBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 16,
                      color: opGreen,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issue via Loader',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: newTextPrimary,
                          ),
                        ),
                        Text(
                          '${j?.itemname ?? ''} · ${fmtQty(qty)} PCS · ${_t(j?.stagename ?? '')} → ${_t(to)}',
                          maxLines: 2,
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
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: opBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: newTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Shared split: one box per destination. The stages divide the
              // QC-passed qty, so the TOTAL is what is capped.
              if (shared) ...[
                const FieldLabel('Qty per stage'),
                for (final o in c.nextOptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: stageColor(o.stagename),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t(o.stagename),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: newTextPrimary,
                                ),
                              ),
                              Text(
                                'Plan ${fmtQty(o.planqty)} · sent ${fmtQty(o.sentqty)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: newTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 78,
                          child: TextField(
                            controller: c.sharedQty[o.stageid],
                            onChanged: (_) => c.sharedQtyChanged(),
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              MaxQtyFormatter(c.sharedRemaining),
                            ],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: opInput(hint: '0'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: c.sharedEntered > c.sharedRemaining
                        ? opRedBg
                        : opGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Total ${fmtQty(c.sharedEntered)} of ${fmtQty(c.sharedRemaining)} left'
                    '${c.sharedEntered > c.sharedRemaining ? ' — too many' : ''}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: c.sharedEntered > c.sharedRemaining
                          ? opRed
                          : opGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One hand-off is created per stage, all with the loader '
                  'details below.',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: newTextHint,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 13),
              ],
              FieldLabel('Loader name'.tr),
              TextField(
                controller: loaderCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
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
                        ValueBox(
                          DateFormat('yyyy-MM-dd').format(issuedAt),
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel('Issue time'.tr),
                        ValueBox(
                          DateFormat('hh:mm a').format(issuedAt),
                          icon: Icons.schedule_rounded,
                          onTap: _pickTime,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              FieldLabel('Issue receipt photo(s) — required'.tr),
              PhotoStrip(
                photos: receipt,
                onAdd: () => _pick(true),
                onRemove: (p) => setState(() => receipt.remove(p)),
                hint: 'Upload / take a photo',
                accent: opGreen,
              ),
              const SizedBox(height: 11),
              FieldLabel('Item photo(s)'.tr),
              PhotoStrip(
                photos: items,
                onAdd: () => _pick(false),
                onRemove: (p) => setState(() => items.remove(p)),
                hint: 'Upload / take a photo',
                accent: opGreen,
              ),
              const SizedBox(height: 11),
              FieldLabel('Remarks (optional)'.tr),
              TextField(
                controller: remarksCtrl,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(fontSize: 12.5),
                decoration: opInput(hint: 'e.g. 2 cartons, handle with care'),
              ),
              const SizedBox(height: 14),
              GetBuilder<OperatorController>(
                builder: (ctrl) => Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: OutlinedButton(
                        onPressed: ctrl.saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: newTextSecondary,
                          side: const BorderSide(color: newBorderColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          'Cancel'.tr,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigButton(
                        shared
                            ? 'Issue ${fmtQty(c.sharedEntered)} to ${c.nextOptions.length} stages'
                            : 'Issue to ${_t(to)}',
                        icon: Icons.send_rounded,
                        busy: ctrl.saving,
                        gradient: opGreenGradient,
                        onTap: () async {
                          final ok = shared
                              ? await c.issueSharedViaLoader(
                                  loadername: loaderCtrl.text,
                                  issuedAt: issuedAt,
                                  remarks: remarksCtrl.text,
                                  receiptPhotos: receipt,
                                  itemPhotos: items,
                                )
                              : await c.issueViaLoader(
                                  loadername: loaderCtrl.text,
                                  issuedAt: issuedAt,
                                  remarks: remarksCtrl.text,
                                  receiptPhotos: receipt,
                                  itemPhotos: items,
                                );
                          if (ok && context.mounted) {
                            Navigator.of(context).pop(true);
                            c.backToJobsHome();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _t(String s) => s.isEmpty
      ? s
      : s
            .toLowerCase()
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
}
