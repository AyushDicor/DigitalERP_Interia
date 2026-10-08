import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

const downtimeReasons = [
  'Machine breakdown',
  'Power cut',
  'No operator',
  'Tool / blade change',
  'Maintenance',
  'Other',
];

const bottleneckReasons = [
  'Waiting for material',
  'Waiting for previous stage',
  'Waiting for QC',
  'Machine capacity',
  'Manpower shortage',
  'Other',
];

/// Bottom-sheet form for a downtime (red) or bottleneck (amber) event:
/// reason, date, from → to time (auto duration), remarks, photo. Pass [job]
/// to log it against a challan; omit for a general shop-floor entry.
/// Flutter's own modal sheet — see the note in operator_gatepass_sheet.dart:
/// `Get.bottomSheet` misplaces the sheet once the keyboard opens.
Future<void> showStoppageSheet(
  BuildContext context,
  OperatorController c, {
  required bool downtime,
  OperatorJob? job,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StoppageSheet(downtime: downtime, job: job),
  );
}

class _StoppageSheet extends StatefulWidget {
  final bool downtime;
  final OperatorJob? job;
  const _StoppageSheet({required this.downtime, this.job});

  @override
  State<_StoppageSheet> createState() => _StoppageSheetState();
}

class _StoppageSheetState extends State<_StoppageSheet> {
  late final List<String> reasons = widget.downtime
      ? downtimeReasons
      : bottleneckReasons;
  String reason = '';
  final otherCtrl = TextEditingController();
  final remarksCtrl = TextEditingController();
  DateTime date = DateTime.now();
  TimeOfDay? from;
  TimeOfDay? to;
  PickedAttachment? photo;

  Color get color => widget.downtime ? opRed : opAmber;
  Color get bg => widget.downtime ? opRedBg : opAmberBg;

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    to = now;
    final f = DateTime.now().subtract(const Duration(minutes: 30));
    from = TimeOfDay(hour: f.hour, minute: f.minute);
  }

  @override
  void dispose() {
    otherCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }

  DateTime? _at(TimeOfDay? t) => t == null
      ? null
      : DateTime(date.year, date.month, date.day, t.hour, t.minute);

  int get minutes {
    final a = _at(from), b = _at(to);
    if (a == null || b == null) return 0;
    return b.difference(a).inMinutes;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> _pickTime(bool isFrom) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (isFrom ? from : to) ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        if (isFrom) {
          from = t;
        } else {
          to = t;
        }
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await pickAttachments(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked.isNotEmpty) setState(() => photo = picked.first);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OperatorController>();
    final j = widget.job;
    final title = widget.downtime ? 'Log downtime' : 'Flag bottleneck';
    final media = MediaQuery.of(context);
    // Size against the space left once the keyboard is up — a full-height
    // sheet pushed up by the keyboard would run under the status bar.
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
          padding: EdgeInsets.fromLTRB(
            14,
            12,
            14,
            // The home-indicator inset is already covered by the keyboard.
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
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.downtime
                          ? Icons.error_outline_rounded
                          : Icons.warning_amber_rounded,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: newTextPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
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
              if (j != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: newSurfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: newBorderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          j.itemname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: newTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StagePill(j.stagename),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 13),
              FieldLabel('Reason'.tr),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: newSurfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: newBorderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: reason.isEmpty ? null : reason,
                    hint: const Text(
                      'Pick a reason',
                      style: TextStyle(fontSize: 12.5, color: newTextHint),
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
                    items: reasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => reason = v ?? ''),
                  ),
                ),
              ),
              if (reason == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherCtrl,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: opInput(hint: 'Describe the reason'),
                ),
              ],
              const SizedBox(height: 11),
              const FieldLabel('Date'),
              ValueBox(
                DateFormat('dd-MM-yyyy').format(date),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('From'),
                        ValueBox(
                          from == null ? '--:--' : _fmt(from!),
                          icon: Icons.schedule_rounded,
                          onTap: () => _pickTime(true),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 16, 8, 0),
                    child: Text(
                      '→',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: newTextHint,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('To'),
                        ValueBox(
                          to == null ? '--:--' : _fmt(to!),
                          icon: Icons.schedule_rounded,
                          onTap: () => _pickTime(false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: minutes < 0 ? opRedBg : bg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: minutes < 0 ? opRed : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      minutes < 0
                          ? 'To must be after From'
                          : 'Duration · $minutes min',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: minutes < 0 ? opRed : color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              const FieldLabel('Remarks'),
              TextField(
                controller: remarksCtrl,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(fontSize: 12.5),
                decoration: opInput(
                  hint: widget.downtime
                      ? 'e.g. Blade motor tripped…'
                      : 'e.g. Ply 18mm not received from store…',
                ),
              ),
              const SizedBox(height: 11),
              FieldLabel('Photo'.tr),
              PhotoStrip(
                photos: photo == null ? const [] : [photo!],
                onAdd: _pickPhoto,
                onRemove: (_) => setState(() => photo = null),
                hint: 'Upload / take a photo',
                accent: color,
              ),
              const SizedBox(height: 14),
              GetBuilder<OperatorController>(
                builder: (ctrl) => Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: OutlinedButton(
                        onPressed: ctrl.saving
                            ? null
                            : () => Navigator.of(context).pop(),
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
                        widget.downtime ? 'Save downtime' : 'Flag bottleneck',
                        icon: Icons.check_rounded,
                        busy: ctrl.saving,
                        color: color,
                        onTap: () async {
                          final r = reason == 'Other'
                              ? otherCtrl.text.trim()
                              : reason;
                          final ok = await c.logStoppage(
                            downtime: widget.downtime,
                            reason: r,
                            forJob: j,
                            remarks: remarksCtrl.text,
                            from: _at(from),
                            to: _at(to),
                            entrydate: date,
                            photo: photo,
                          );
                          if (ok && context.mounted) {
                            Navigator.of(context).pop();
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

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
