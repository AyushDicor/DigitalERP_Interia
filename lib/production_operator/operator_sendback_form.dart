// The send back form: a fault found here goes back to ANY stage the piece
// actually passed through, is fixed there, and comes home — optionally with
// stages on the way redoing their work.
//
// Nothing about the route is worked out in the app. The server answers
// `sendback/options` with what can go back and which stages it may go to,
// each with its own note, and this screen only draws that.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

class OperatorSendBackForm extends StatelessWidget {
  const OperatorSendBackForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OperatorController>(
      builder: (c) {
        final j = c.job;
        final good = c.sbGood;
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
                  'Send back'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                Text(
                  j == null ? '' : 'from ${_t(j.stagename)} · ${j.itemname}',
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
          body: c.sbLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : good == null
              ? _nothing(c)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(13, 13, 13, 28),
                  children: [
                    _whatCard(c),
                    const SizedBox(height: 12),
                    _fixAtCard(c),
                    const SizedBox(height: 12),
                    _wayBackCard(c, j),
                    const SizedBox(height: 12),
                    _qtyAndHow(c, good),
                    const SizedBox(height: 12),
                    _reasonCard(c),
                    const SizedBox(height: 12),
                    _faultCard(c),
                    const SizedBox(height: 12),
                    _photoCard(c),
                    const SizedBox(height: 16),
                    BigButton(
                      _sendLabel(c, good),
                      icon: Icons.keyboard_return_rounded,
                      busy: c.saving,
                      gradient: opAmberGradient,
                      // From QC the reject and the send back are ONE call, so
                      // the QC screen wrote nothing — this submit does both.
                      // Two screens are popped: the form and the QC screen.
                      onTap: () async {
                        if (c.sbFromQc) {
                          if (await c.submitQcSendBack()) {
                            Get.back();
                            Get.back();
                            c.backToJobsHome();
                          }
                          return;
                        }
                        if (await c.submitSendBack()) {
                          Get.back();
                          c.backToJobsHome();
                        }
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _sendLabel(OperatorController c, SendBackGood g) {
    final qty = c.sbQtyCtrl.text.trim();
    final where = c.sbFixStage?.stagename ?? '';
    final to = where.isEmpty ? '' : ' to ${_t(where)}';
    // From QC the button also records the rejection, and saying so is the
    // only warning the checker gets that this is not just a transfer.
    if (c.sbFromQc) return 'Reject and send back$to';
    return 'Send ${qty.isEmpty ? '' : '$qty '}${g.name} back$to';
  }

  Widget _nothing(OperatorController c) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 34, color: newTextHint),
          const SizedBox(height: 10),
          Text(
            c.sbError.isNotEmpty
                ? c.sbError
                : 'Nothing at this stage can be sent back yet. '
                      'Pieces can go back once they have arrived here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );

  // ── What goes back ──

  Widget _whatCard(OperatorController c) {
    final goods = c.sbOptions?.goods ?? const <SendBackGood>[];
    final good = c.sbGood!;
    final heldInside = c.sbOptions?.heldInside ?? '';
    return _card(
      'What goes back?',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parts that have been built in are not listed — the assembled
          // thing goes back whole. Say which one, or the operator looks for
          // a part that has quietly vanished from the list.
          if (heldInside.isNotEmpty) ...[
            _Hint(
              'Parts already built into the $heldInside are not sent back on '
              'their own — the whole $heldInside goes back.',
            ),
            const SizedBox(height: 9),
          ],
          if (goods.length > 1)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in goods)
                  _chip(
                    '${g.name}${g.kind.isEmpty ? '' : ' · ${g.kind}'}',
                    g.partid == c.sbPartId,
                    () => c.setSendBackGood(g.partid),
                  ),
              ],
            )
          else
            Text(
              '${good.name}${good.kind.isEmpty ? '' : ' · ${good.kind}'}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: newTextPrimary,
              ),
            ),
          // From QC there is no such question: the pieces were just checked
          // here, so they are worked on by definition, and `qcreject` takes
          // no `worked` flag.
          if (c.sbFromQc) ...[
            const SizedBox(height: 9),
            const _Hint(
              'These pieces were just rejected at this stage. The rejection '
              'is recorded when you send them back.',
            ),
          ] else ...[
            const SizedBox(height: 11),
            // Two different quantities with two different caps — the server
            // refuses a worked piece sent as untouched, and says so.
            const FieldLabel('Already worked on here?'),
            Row(
              children: [
                Expanded(
                  child: _seg(
                    'Not worked yet',
                    '${fmtQty(good.stageqty)} here',
                    !c.sbWorked,
                    good.canUnworked ? () => c.setSendBackWorked(false) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _seg(
                    'Already worked',
                    '${fmtQty(good.qcqty)} here',
                    c.sbWorked,
                    good.canWorked ? () => c.setSendBackWorked(true) : null,
                  ),
                ),
              ],
            ),
            if (c.sbWorked) ...[
              const SizedBox(height: 7),
              const _Hint(
                'These are rejected at this stage first, like a QC reject. '
                'They are made again here when they come back.',
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Fix at: any stage the piece passed through ──

  Widget _fixAtCard(OperatorController c) {
    final stages = c.sbOptions?.fixstages ?? const <SendBackFixStage>[];
    return _card(
      'Fix at',
      stages.isEmpty
          ? const _Hint('No earlier stage to send this back to.')
          : Column(
              children: [
                for (final f in stages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _stageOption(
                      f.stagename,
                      f.note,
                      f.stageid == c.sbFixStageId,
                      () => c.setSendBackFixStage(f.stageid),
                    ),
                  ),
              ],
            ),
    );
  }

  // ── The way home, and who redoes their work on it ──

  Widget _wayBackCard(OperatorController c, OperatorJob? j) {
    final home = _t(j?.stagename ?? '');
    final between = c.sbBetween;
    return _card(
      'Way back',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            between.isEmpty
                ? 'After the fix it comes straight back to $home.'
                : 'After the fix it comes back to $home.',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: newTextPrimary,
              height: 1.4,
            ),
          ),
          if (between.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _Hint(
              'Redo a stage on the way only if the fix undoes its work.',
            ),
            const SizedBox(height: 6),
            for (final b in between)
              InkWell(
                onTap: () => c.toggleSendBackRedo(b.stageid),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      _tick(c.sbRedoIds.contains(b.stageid)),
                      const SizedBox(width: 10),
                      Text(
                        'Redo ${_t(b.stagename)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: newTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (c.sbWayLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: opAmberBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: opAmber.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.sbWayLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A4B06),
                    ),
                  ),
                  if (c.sbSkipped.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Not redone: ${c.sbSkipped.join(', ')}. '
                      'Their work stays as it is.',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A4B06),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Qty, and whether it travels with a loader ──

  Widget _qtyAndHow(OperatorController c, SendBackGood good) => _card(
    'How many, and how',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Qty'),
                  TextField(
                    controller: c.sbQtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [MaxQtyFormatter(c.sbMaxQty)],
                    onChanged: (_) => c.update(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: opInput(hint: '0').copyWith(
                      suffixText: 'of ${fmtQty(c.sbMaxQty)}',
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('How'),
                  Row(
                    children: [
                      Expanded(
                        child: _seg(
                          'Direct',
                          '',
                          !c.sbViaLoader,
                          () => c.setSendBackViaLoader(false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _seg(
                          'Loader',
                          '',
                          c.sbViaLoader,
                          () => c.setSendBackViaLoader(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (c.sbViaLoader) ...[
          const SizedBox(height: 11),
          const FieldLabel('Loader name'),
          TextField(
            controller: c.sbLoaderCtrl,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            decoration: opInput(hint: 'Who is carrying it'),
          ),
          const SizedBox(height: 6),
          const _Hint(
            'The fix stage accepts it first, and may refuse part of it.',
          ),
        ],
      ],
    ),
  );

  Widget _reasonCard(OperatorController c) => _card(
    'Reason',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in kSendBackReasons)
              _chip(r, c.sbReasonCtrl.text.trim() == r, () {
                c.sbReasonCtrl.text = r;
                c.update();
              }),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: c.sbReasonCtrl,
          onChanged: (_) => c.update(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          decoration: opInput(hint: 'What is wrong with it'),
        ),
        const SizedBox(height: 6),
        const _Hint('The fix stage sees only this, so be specific.'),
      ],
    ),
  );

  /// Whose work was faulty — not necessarily the stage doing the fix. It is
  /// what the rework report counts against.
  Widget _faultCard(OperatorController c) {
    final stages = c.sbOptions?.fixstages ?? const <SendBackFixStage>[];
    if (stages.isEmpty) return const SizedBox.shrink();
    return _card(
      'Whose work is faulty?',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in stages)
                _chip(
                  _t(f.stagename),
                  f.stageid == c.sbFaultStageId,
                  () => c.setSendBackFault(f.stageid),
                ),
            ],
          ),
          const SizedBox(height: 7),
          const _Hint(
            'Counted on that stage\'s rework report, wherever it is fixed.',
          ),
        ],
      ),
    );
  }

  Widget _photoCard(OperatorController c) => _card(
    'Photo',
    PhotoStrip(
      photos: c.sbPhotos,
      accent: opAmber,
      hint: 'A photo of the fault helps the stage that gets it back',
      onAdd: () async {
        final picked = await pickAttachments(
          allowedExtensions: const ['jpg', 'jpeg', 'png'],
        );
        if (picked.isNotEmpty) c.addSendBackPhotos(picked);
      },
      onRemove: c.removeSendBackPhoto,
    ),
  );

  // ── small pieces ──

  Widget _card(String title, Widget child) => Container(
    padding: const EdgeInsets.all(13),
    decoration: opCard(radius: 14),
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
        const SizedBox(height: 10),
        child,
      ],
    ),
  );

  Widget _chip(String text, bool on, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(999),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: on ? newTextPrimary : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? newTextPrimary : newBorderColor),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: on ? Colors.white : newTextPrimary,
        ),
      ),
    ),
  );

  /// A two-state button that also carries the qty it is capped at, so the
  /// operator can see which side actually has pieces before tapping.
  Widget _seg(String text, String sub, bool on, VoidCallback? onTap) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: onTap == null
            ? const Color(0xFFF1F2F8)
            : (on ? newTextPrimary : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: on ? newTextPrimary : newBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: onTap == null
                  ? newTextHint
                  : (on ? Colors.white : newTextPrimary),
            ),
          ),
          if (sub.isNotEmpty)
            Text(
              sub,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: onTap == null
                    ? newTextHint
                    : (on ? Colors.white70 : newTextSecondary),
              ),
            ),
        ],
      ),
    ),
  );

  /// One destination, with the server's own note under it ("Came from here",
  /// "On its route") so the choice is obvious without knowing the plan.
  Widget _stageOption(String name, String note, bool on, VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: on ? opAmberBg : Colors.white,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(name),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: newTextPrimary,
                      ),
                    ),
                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: newTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _tick(bool on) => Container(
    width: 21,
    height: 21,
    decoration: BoxDecoration(
      color: on ? opAmber : Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: on ? opAmber : newTextHint, width: 1.8),
    ),
    child: on
        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
        : null,
  );
}

/// Quick-pick reasons. The operator can still type anything.
const kSendBackReasons = [
  'Paint scratch',
  'Paint peeling',
  'Shade mismatch',
  'Joint loose',
  'Damaged in transit',
  'Wrong size',
];

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: newTextSecondary,
      height: 1.4,
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
