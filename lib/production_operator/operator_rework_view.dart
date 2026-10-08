import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'operator_controller.dart';
import 'operator_design_view.dart' show DesignGalleryView;
import 'operator_models.dart';
import 'operator_widgets.dart';

/// Re-produce screen for a Rework job (QC rejected → disposition Rework).
/// Mirrors the backend's UI: amber "N pcs returned for rework" banner, item
/// card, quantity (max = pieces due), entry date, notes, photo, and a note on
/// what happens after save. Posts a plain `produce` for the qty.
class OperatorReworkView extends StatelessWidget {
  const OperatorReworkView({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      final j = c.reworkJob;
      if (j == null) return const Scaffold(body: SizedBox());
      final due = j.reworkQty;
      final qty = c.reworkQtyEntered;
      final left = (due - qty).clamp(0, double.infinity);
      final over = qty > due;
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
              const Text(
                'Re-produce',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                '${_title(j.stagename)} · Rework',
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
            // ── Returned-for-rework banner ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: opAmberBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: opAmber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: opAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${fmtQty(due)} pcs returned for rework',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8A5A00),
                          ),
                        ),
                        const SizedBox(height: 3),
                        // The reason gets its own line and the heavier
                        // weight: it is the one thing on this screen that
                        // tells the operator what to actually do differently.
                        if (c.reworkReason.isNotEmpty)
                          Text(
                            c.reworkReason,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8A5A00),
                              height: 1.3,
                            ),
                          ),
                        if (c.reworkRemarks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              c.reworkRemarks,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B4A0B),
                                height: 1.35,
                              ),
                            ),
                          ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (c.reworkFlaggedBy.isNotEmpty)
                              'flagged by QC (${c.reworkFlaggedBy})'
                            else
                              'flagged by QC',
                            if (c.reworkWhen.isNotEmpty) c.reworkWhen,
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A5A00),
                            height: 1.35,
                          ),
                        ),
                        // What QC photographed. Seeing the defect beats any
                        // description of it.
                        if (c.reworkRejectImages.isNotEmpty) ...[
                          const SizedBox(height: 9),
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: c.reworkRejectImages.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 7),
                              itemBuilder: (_, i) =>
                                  _rejectThumb(c.reworkRejectImages, i),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Item card ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: opCard(radius: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${j.challanno.isNotEmpty ? '${j.challanno} · ' : ''}${j.itemname}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (j.boqno.isNotEmpty)
                        SoftPill(j.boqno, color: opBlue, bg: opBlueBg),
                      StagePill(j.stagename),
                      if (j.partyname.isNotEmpty)
                        SoftPill(
                          j.partyname,
                          color: newTextSecondary,
                          bg: lightGreyColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: newBorderColor),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _tri(fmtQty(j.issuedqty), 'Issued'.tr),
                      _tri(fmtQty(j.producedqty), 'Produced'.tr),
                      _tri(
                        fmtQty(j.qcqty),
                        'Passed'.tr,
                        color: j.qcqty > 0 ? opGreen : null,
                      ),
                      _tri(fmtQty(due), 'Rework'.tr, color: opAmber),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Entry ──
            Container(
              padding: const EdgeInsets.all(13),
              decoration: opCard(
                border: opAmber.withValues(alpha: 0.45),
                radius: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Quantity to produce'),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                    decoration: BoxDecoration(
                      color: newSurfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: over ? opRed : opPrimary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: c.reworkQtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => c.reworkChanged(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: newTextPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: '0',
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        Text(
                          '/ ${fmtQty(due)}\ndue',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: newTextSecondary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SmallButton(
                          'MAX',
                          color: opPrimary,
                          filled: false,
                          onTap: c.setReworkMax,
                        ),
                      ],
                    ),
                  ),
                  if (over) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Only ${fmtQty(due)} pcs are due for rework.',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: opRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const FieldLabel('Entry date'),
                  ValueBox(
                    DateFormat('yyyy-MM-dd').format(c.reworkDate),
                    icon: Icons.edit_calendar_outlined,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: c.reworkDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 60),
                        ),
                        lastDate: DateTime.now(),
                        helpText: 'Entry date (back-date allowed)',
                      );
                      if (d != null) c.setReworkDate(d);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Notes'),
                            TextField(
                              controller: c.reworkNotesCtrl,
                              minLines: 2,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 12.5),
                              decoration: opInput(
                                hint: 'Pin re-aligned & re-checked',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FieldLabel('Photo'.tr),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: c.pickReworkPhotos,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: newSurfaceColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: newBorderColor),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.photo_camera_outlined,
                                    color: newTextSecondary,
                                    size: 20,
                                  ),
                                  if (c.reworkPhotos.isNotEmpty)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: opPrimary,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          '${c.reworkPhotos.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (c.reworkPhotos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    PhotoStrip(
                      photos: c.reworkPhotos,
                      onAdd: c.pickReworkPhotos,
                      onRemove: c.removeReworkPhoto,
                      accent: opAmber,
                    ),
                  ],
                  const SizedBox(height: 12),
                  // ── After-save note ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: opGreenBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: opGreen.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: opGreen,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            qty <= 0
                                ? 'Enter the quantity re-produced.'
                                : left <= 0
                                ? 'After save: balance ${fmtQty(due)} → 0, status becomes Done.'
                                : 'After save: balance ${fmtQty(due)} → ${fmtQty(left)}, still in Rework.',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0E6B3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BigButton(
              'Save Production',
              icon: Icons.check_rounded,
              busy: c.saving,
              onTap: over || qty <= 0
                  ? null
                  : () async {
                      final ok = await c.saveRework();
                      if (ok && context.mounted) {
                        Navigator.of(context).pop();
                        c.backToJobsHome();
                      }
                    },
            ),
          ],
        ),
      );
    },
  );

  /// One QC defect photo. Opens the same swipeable viewer the drawings use.
  Widget _rejectThumb(List<String> urls, int i) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: () => Get.to(
      () => DesignGalleryView(
        files: [
          for (final u in urls)
            DesignFile(name: 'QC reject photo', url: u, isimage: true),
        ],
        index: i,
        title: 'Why it came back',
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.white,
        child: Image.network(
          urls[i],
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

  static String _title(String s) => s.isEmpty
      ? s
      : s
            .toLowerCase()
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
}
