// Packing: at PACKING the operator does not record production, they pack.
// They say how many pieces went into boxes and, per box, what is inside and
// how many. Saving is what records those pieces as made at PACKING, so QC
// and dispatch carry on unchanged.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

class OperatorPackView extends StatelessWidget {
  const OperatorPackView({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      final j = c.job;
      final it = c.packItem;
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
                'Pack item'.tr,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                j == null
                    ? ''
                    : 'Challan ${j.challanno.isEmpty ? j.challanid : j.challanno} · ${_t(j.stagename)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ),
        body: c.packLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ListView(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 28),
                children: [
                  _itemCard(it),
                  const SizedBox(height: 12),
                  _qtyCard(c, it),
                  const SizedBox(height: 12),
                  _draftBoxes(context, c),
                  const SizedBox(height: 12),
                  _addBoxButton(context, c),
                  const SizedBox(height: 16),
                  _saveBar(c, it),
                  if ((c.packJob?.packed ?? []).isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const _Head('Already packed'),
                    const SizedBox(height: 8),
                    ..._savedPacks(context, c),
                  ],
                ],
              ),
      );
    },
  );

  Widget _itemCard(PackItem it) => Container(
    padding: const EdgeInsets.all(13),
    decoration: opCard(radius: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          it.description.isNotEmpty ? it.description : it.itemname,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: newTextPrimary,
            height: 1.3,
          ),
        ),
        if (it.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            it.subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
            ),
          ),
        ],
        if (it.size.isNotEmpty) ...[
          const SizedBox(height: 6),
          SoftPill(it.size, color: opBlue, bg: opBlueBg),
        ],
      ],
    ),
  );

  /// Pieces packed, with the same −/+ stepper the mockup uses. Capped at
  /// `topack`, which already counts anything produced here the old way.
  Widget _qtyCard(OperatorController c, PackItem it) => Container(
    padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
    decoration: opCard(radius: 14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pieces packed'.tr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              Text(
                it.topack <= 0
                    ? 'Nothing left to pack'
                    : '${fmtQty(it.topack)} left to pack',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ),
        _step(
          Icons.remove_rounded,
          c.packQty > 0 ? () => c.setPackQty(c.packQty - 1) : null,
        ),
        SizedBox(
          width: 54,
          child: TextField(
            controller: c.packQtyCtrl,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [MaxQtyFormatter(it.topack)],
            onChanged: (_) => c.update(),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '0',
            ),
          ),
        ),
        _step(
          Icons.add_rounded,
          c.packQty < it.topack ? () => c.setPackQty(c.packQty + 1) : null,
        ),
      ],
    ),
  );

  Widget _step(IconData icon, VoidCallback? onTap) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: newBorderColor),
        color: onTap == null ? newSurfaceColor : Colors.white,
      ),
      child: Icon(
        icon,
        size: 18,
        color: onTap == null ? newTextHint : newTextPrimary,
      ),
    ),
  );

  Widget _draftBoxes(BuildContext context, OperatorController c) {
    if (c.packDrafts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: opCard(radius: 14),
        child: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 16, color: newTextHint),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'No boxes yet. Add one for each box you fill — what is inside '
                'and how many.',
                style: TextStyle(
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
    }
    return Column(
      children: [
        for (var i = 0; i < c.packDrafts.length; i++)
          _draftRow(context, c, i, c.packDrafts[i]),
      ],
    );
  }

  Widget _draftRow(
    BuildContext context,
    OperatorController c,
    int i,
    PackBoxDraft b,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: opCard(radius: 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: newTextPrimary,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${i + 1}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.contents.isEmpty ? '—' : b.contents,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
              Text(
                'How many: ${fmtQty(b.count)}'
                '${b.photos.isEmpty ? '' : ' · ${b.photos.length} photo'}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 17),
          color: newTextSecondary,
          onPressed: () => openAddBoxSheet(context, c, index: i, existing: b),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 18),
          color: newTextHint,
          onPressed: () => c.removePackBox(i),
        ),
      ],
    ),
  );

  Widget _addBoxButton(BuildContext context, OperatorController c) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => openAddBoxSheet(context, c),
    child: Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: opPrimary.withValues(alpha: 0.6),
          width: 1.6,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 18, color: opPrimary),
          SizedBox(width: 7),
          Text(
            'Add box'.tr,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: opPrimary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _saveBar(OperatorController c, PackItem it) {
    final n = c.packReadyDrafts.length;
    return Column(
      children: [
        Text(
          n == 0
              ? 'Add at least one box to save.'
              : '${fmtQty(c.packQty)} × ${it.itemname.isEmpty ? 'item' : it.itemname} '
                    'in $n box${n == 1 ? '' : 'es'}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: newTextSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 9),
        BigButton(
          'Save packing',
          icon: Icons.inventory_2_rounded,
          busy: c.saving,
          gradient: opGreenGradient,
          onTap: (n == 0 || c.packQty <= 0)
              ? null
              : () async {
                  if (await c.savePacking()) c.backToJobsHome();
                },
        ),
        const SizedBox(height: 6),
        const Text(
          'Saved boxes get their numbers (B01, B02 …). QC at Packing as usual.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: newTextHint,
          ),
        ),
      ],
    );
  }

  /// Saves already made against this item, newest first, each undoable as a
  /// whole — a box cannot be removed on its own.
  List<Widget> _savedPacks(BuildContext context, OperatorController c) {
    final groups = (c.packJob?.byPack ?? {}).entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return [
      for (final g in groups)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: opCard(radius: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${fmtQty(g.value.first.packqty)} pcs · '
                      '${g.value.length} box${g.value.length == 1 ? '' : 'es'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: newTextPrimary,
                      ),
                    ),
                  ),
                  // Once it is on a dispatch challan it has left the factory.
                  if (g.value.any((b) => b.isDispatched))
                    SoftPill(
                      'Sent · ${g.value.first.dcno}',
                      color: opGreen,
                      bg: opGreenBg,
                    )
                  else
                    TextButton(
                      onPressed: c.saving
                          ? null
                          : () => _confirmUndo(context, c, g.key),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Undo'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: opRed,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              for (final b in g.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          b.boxno,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: opPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${b.contents} · ${fmtQty(b.count)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: newTextSecondary,
                          ),
                        ),
                      ),
                      if (b.photos.isNotEmpty)
                        const Icon(
                          Icons.photo_outlined,
                          size: 13,
                          color: newTextHint,
                        ),
                    ],
                  ),
                ),
              if (g.value.first.packedby.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  'by ${g.value.first.packedby}'
                  '${g.value.first.packedon.isEmpty ? '' : ' · ${g.value.first.packedon}'}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: newTextHint,
                  ),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  Future<void> _confirmUndo(
    BuildContext context,
    OperatorController c,
    int packid,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Undo this pack?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Its boxes and their numbers are removed. The pieces stay made at '
          'Packing and can be packed again.',
          style: TextStyle(fontSize: 12.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: opRed),
            child: Text('Undo'.tr),
          ),
        ],
      ),
    );
    if (ok == true) await c.removePack(packid);
  }
}

/// Add or edit one box: what is inside, how many, and an optional photo.
void openAddBoxSheet(
  BuildContext context,
  OperatorController c, {
  int? index,
  PackBoxDraft? existing,
}) {
  final contentsCtrl = TextEditingController(text: existing?.contents ?? '');
  final countCtrl = TextEditingController(
    text: (existing?.count ?? 0) > 0 ? fmtQty(existing!.count) : '',
  );
  var photos = <PickedAttachment>[...(existing?.photos ?? const [])];
  final boxNo = (index ?? c.packDrafts.length) + 1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheet) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: newBorderColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: opPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: opPrimary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Box $boxNo',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: newTextPrimary,
                            ),
                          ),
                          Text(
                            c.packItem.itemname,
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
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: newTextSecondary,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const FieldLabel('What is inside'),
                TextField(
                  controller: contentsCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: opInput(hint: 'e.g. Drawers'),
                ),
                const SizedBox(height: 12),
                const FieldLabel('How many'),
                TextField(
                  controller: countCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: opInput(hint: 'e.g. 4'),
                ),
                const SizedBox(height: 12),
                const FieldLabel('Photo of the box (optional)'),
                PhotoStrip(
                  photos: photos,
                  accent: opPrimary,
                  hint: 'Helps the site team find what is inside',
                  onAdd: () async {
                    final picked = await pickAttachments(
                      allowedExtensions: const ['jpg', 'jpeg', 'png'],
                    );
                    if (picked.isNotEmpty) {
                      setSheet(() => photos = [...photos, ...picked]);
                    }
                  },
                  onRemove: (x) =>
                      setSheet(() => photos = [...photos]..remove(x)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: const BorderSide(color: newBorderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: newTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final draft = PackBoxDraft(
                            contents: contentsCtrl.text,
                            count: double.tryParse(countCtrl.text.trim()) ?? 0,
                            p: photos,
                          );
                          // The server refuses either of these, but saying so
                          // here keeps the operator in the sheet they are in.
                          if (draft.contents.trim().isEmpty) {
                            opSnack('Box $boxNo', 'Write what is inside.');
                            return;
                          }
                          if (draft.count <= 0) {
                            opSnack('Box $boxNo', 'Enter how many are inside.');
                            return;
                          }
                          if (index == null) {
                            c.addPackBox(draft);
                          } else {
                            c.replacePackBox(index, draft);
                          }
                          Navigator.of(sheetContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: opGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save box'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Head extends StatelessWidget {
  final String text;
  const _Head(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: newTextSecondary,
    ),
  );
}

String _t(String s) => s.isEmpty
    ? s
    : s
          .split(' ')
          .map(
            (w) => w.isEmpty
                ? w
                : w[0].toUpperCase() + w.substring(1).toLowerCase(),
          )
          .join(' ');
