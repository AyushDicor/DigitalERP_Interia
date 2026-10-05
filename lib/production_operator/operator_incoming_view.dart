import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

String _t(String s) => s.isEmpty
    ? s
    : s
          .toLowerCase()
          .split(' ')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

/// Consignment card (Home "Awaiting receipt" + Incoming list): IN TRANSIT
/// badge, from → to, qty, loader · ref · issued when · by whom, photo
/// thumbnails and a Receive button.
class ConsignmentCard extends StatelessWidget {
  final Consignment cn;
  final VoidCallback onReceive;
  final VoidCallback? onReject;
  const ConsignmentCard({
    super.key,
    required this.cn,
    required this.onReceive,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final photos = [...cn.receiptimages, ...cn.itemimages];

    /// Work coming BACK to be fixed reads differently from new work
    /// arriving, so the whole card switches to amber and says so.
    final back = cn.isSendBack;
    final accent = back ? opAmber : opGreen;
    final accentBg = back ? opAmberBg : opGreenBg;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: opCard(border: accent.withValues(alpha: 0.45)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // A part consignment carries one part, and two of them can
                  // be in transit for the same item — name the part or the
                  // cards read identically.
                  '${cn.challanno.isNotEmpty ? '${cn.challanno} · ' : ''}${cn.itemname}${cn.partname.isEmpty ? '' : ' · ${cn.partname}'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SoftPill(
                back ? 'SENT BACK' : 'IN TRANSIT',
                color: accent,
                bg: accentBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StagePill(cn.fromstagename),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: newTextHint,
                ),
              ),
              StagePill(cn.tostagename),
              const Spacer(),
              Text(
                '${fmtQty(cn.qty)} PCS',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
            ],
          ),

          /// Why it is here. On a send back this is the fault the sending
          /// stage wrote down, and it is the whole point of the card — the
          /// operator cannot fix what they cannot see. On a forward issue it
          /// is the gate-pass note, shown the same way when there is one.
          if (back || cn.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    back ? Icons.undo_rounded : Icons.sticky_note_2_outlined,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          back
                              ? 'Sent back by ${_t(cn.sentBackFrom)} to be fixed'
                              : 'Note from ${_t(cn.fromstagename)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                        if (cn.remarks.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cn.remarks,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: newTextPrimary,
                              height: 1.3,
                            ),
                          ),
                        ] else
                          const Text(
                            'No reason recorded',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: newTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: opGreenBg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: opGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: opGreen,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cn.loadername.isEmpty && cn.loaderref.isEmpty
                            ? 'Loader not recorded'
                            : [
                                if (cn.loadername.isNotEmpty) cn.loadername,
                                if (cn.loaderref.isNotEmpty) cn.loaderref,
                              ].join(' · '),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0E6B3A),
                        ),
                      ),
                      Text(
                        'Issued ${_when(cn.issuedate, cn.issuetime)}'
                        '${cn.issuedby.isNotEmpty ? ' · by ${cn.issuedby} (${_t(cn.fromstagename)})' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0E6B3A),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Issue receipt & item photos',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: newTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: photos
                    .map(
                      (u) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => Get.to(() => _Viewer(u)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              u,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 52,
                                height: 52,
                                color: newSurfaceColor,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: newTextHint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (onReject != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'Reject'.tr,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: opRed,
                      side: BorderSide(color: opRed.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: onReject != null ? 2 : 1,
                child: BigButton(
                  'Receive',
                  icon: Icons.check_rounded,
                  gradient: opGreenGradient,
                  onTap: onReceive,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _when(String d, String t) {
    final dt = DateTime.tryParse(d);
    final ds = dt == null ? d : DateFormat('d MMM yyyy').format(dt);
    if (t.isEmpty) return ds;
    final parts = t.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]), m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        return '$ds · ${DateFormat('hh:mm a').format(DateTime(2000, 1, 1, h, m))}';
      }
    }
    return '$ds · $t';
  }
}

class _Viewer extends StatelessWidget {
  final String url;
  const _Viewer(this.url);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: InteractiveViewer(
        maxScale: 5,
        child: Image.network(url, fit: BoxFit.contain),
      ),
    ),
  );
}

/// Incoming list — every consignment in transit to this login.
class OperatorIncomingView extends StatelessWidget {
  const OperatorIncomingView({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) => Scaffold(
      backgroundColor: opBg,
      body: Column(
        children: [
          OperatorHeader(
            title: 'Incoming',
            subtitle:
                '${c.firstName} · ${c.myStageName.isEmpty ? 'Shop floor' : '${_t(c.myStageName)} stage'}',
            avatarLetter: c.firstName.substring(0, 1).toUpperCase(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: c.loadIncoming,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 24),
                children: [
                  if (c.incoming.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: opAmberBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: opAmber.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        '${_t(c.myStageName)} production stays locked until you accept the consignment.',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A5A00),
                        ),
                      ),
                    ),
                  SectionHeader('Awaiting receipt', count: c.incoming.length),
                  if (c.incomingLoading && c.incoming.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (c.incoming.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: EmptyState(
                        icon: Icons.local_shipping_outlined,
                        title: 'Nothing in transit',
                        subtitle:
                            'Consignments issued to your stage via loader appear here until you accept them.',
                      ),
                    ),
                  ...c.incoming.map(
                    (cn) => ConsignmentCard(
                      cn: cn,
                      onReceive: () =>
                          Get.to(() => OperatorReceiveView(cn: cn)),
                      onReject: () => rejectConsignment(context, c, cn),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Quick-pick reasons for sending a consignment back to the issuing stage.
const kConsignmentRejectReasons = [
  'Defective / damaged items',
  'Short quantity',
  'Wrong item / batch',
  'Damaged in transit',
  'Not signed off by loader',
];

/// Reason dialog for rejecting a whole consignment: quick-pick reasons and
/// free text. Returns null when cancelled.
///
/// The receiver never decides what happens to the pieces — rejected qty
/// always goes back to the issuing stage as rework. (Writing stock off was
/// the sending stage's QC call; scrap is switched off entirely now — see
/// [kAllowScrap].)
Future<String?> askRejectReason(BuildContext context) async {
  final ctrl = TextEditingController();
  String? picked;
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text(
          'Reject consignment',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The whole consignment goes back to the issuing stage to be '
              'produced again.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: kConsignmentRejectReasons
                  .map(
                    (s) => ChoiceChip(
                      label: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      selected: picked == s,
                      selectedColor: opRedBg,
                      onSelected: (_) => setD(() {
                        picked = s;
                        ctrl.text = s;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(fontSize: 12.5),
              decoration: opInput(
                hint: 'Reason / details (missing, defective…)',
              ),
              onChanged: (_) => setD(() => picked = null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            style: TextButton.styleFrom(foregroundColor: opRed),
            child: Text('Reject'.tr),
          ),
        ],
      ),
    ),
  );
  return (r == null || r.isEmpty) ? null : r;
}

/// Reject the WHOLE consignment straight from the card (no receipt needed).
/// A partial receipt is done on the Receive screen instead.
Future<void> rejectConsignment(
  BuildContext context,
  OperatorController c,
  Consignment cn,
) async {
  final reason = await askRejectReason(context);
  if (reason == null) return;
  final ok = await c.receiveConsignment(
    cn,
    loadername: cn.loadername,
    receivedAt: DateTime.now(),
    qtyaccepted: 0,
    qtyrejected: cn.qty,
    reason: reason,
  );
  if (ok) c.backToJobsHome();
}

/// Receive from Loader — gate pass on the receiving side: loader name,
/// receive date/time, SIGNED issue receipt photo (required to accept),
/// received-item photos, qty received, Reject / Accept.
class OperatorReceiveView extends StatefulWidget {
  final Consignment cn;
  const OperatorReceiveView({super.key, required this.cn});

  @override
  State<OperatorReceiveView> createState() => _OperatorReceiveViewState();
}

class _OperatorReceiveViewState extends State<OperatorReceiveView> {
  late final loaderCtrl = TextEditingController(
    text: Get.find<OperatorController>().suggestedLoaderFor(widget.cn),
  );
  late final qtyCtrl = TextEditingController(text: fmtQty(widget.cn.qty));
  final rejectQtyCtrl = TextEditingController(text: '0');
  final remarksCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();

  DateTime receivedAt = DateTime.now();
  List<PickedAttachment> signed = [];
  List<PickedAttachment> items = [];

  double get accQty => double.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get rejQty => double.tryParse(rejectQtyCtrl.text.trim()) ?? 0;
  bool get balanced => accQty + rejQty == widget.cn.qty;

  @override
  void dispose() {
    loaderCtrl.dispose();
    qtyCtrl.dispose();
    rejectQtyCtrl.dispose();
    remarksCtrl.dispose();
    reasonCtrl.dispose();
    super.dispose();
  }

  /// One of the two qty boxes; editing either keeps the pair adding up.
  Widget _qtyField(
    TextEditingController ctrl,
    Color accent,
    void Function(double) onEdited,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: newSurfaceColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: balanced ? newBorderColor : opRed, width: 1.3),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) =>
          setState(() => onEdited(double.tryParse(v.trim()) ?? 0)),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: accent,
      ),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 11),
      ),
    ),
  );

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: receivedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(
        () => receivedAt = DateTime(
          d.year,
          d.month,
          d.day,
          receivedAt.hour,
          receivedAt.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(receivedAt),
    );
    if (t != null) {
      setState(
        () => receivedAt = DateTime(
          receivedAt.year,
          receivedAt.month,
          receivedAt.day,
          t.hour,
          t.minute,
        ),
      );
    }
  }

  Future<void> _pick(bool forSigned) async {
    final picked = await pickAttachments(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked.isEmpty) return;
    setState(() {
      if (forSigned) {
        signed = [...signed, ...picked];
      } else {
        items = [...items, ...picked];
      }
    });
  }

  Future<void> _submit(OperatorController c) async {
    final ok = await c.receiveConsignment(
      widget.cn,
      loadername: loaderCtrl.text,
      receivedAt: receivedAt,
      qtyaccepted: accQty,
      qtyrejected: rejQty,
      reason: reasonCtrl.text,
      signedReceipt: signed,
      itemPhotos: items,
      remarks: remarksCtrl.text,
    );
    if (ok && mounted) Navigator.of(context).pop();
    if (ok) c.backToJobsHome();
  }

  /// Reject the whole consignment straight from this screen.
  void _rejectAll() => setState(() {
    qtyCtrl.text = '0';
    rejectQtyCtrl.text = fmtQty(widget.cn.qty);
  });

  @override
  Widget build(BuildContext context) {
    final cn = widget.cn;
    return GetBuilder<OperatorController>(
      builder: (c) => Scaffold(
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
                'Incoming · ${_t(cn.tostagename)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${c.firstName} · ${_t(cn.tostagename)} stage',
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
            Container(
              padding: const EdgeInsets.all(13),
              decoration: opCard(
                border: opGreen.withValues(alpha: 0.45),
                radius: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          Icons.check_circle_outline_rounded,
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
                              'Receive from Loader',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: newTextPrimary,
                              ),
                            ),
                            Text(
                              '${cn.partname.isEmpty ? cn.itemname : '${cn.itemname} · ${cn.partname}'} · ${fmtQty(cn.qty)} PCS · from ${_t(cn.fromstagename)}',
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
                    ],
                  ),
                  const SizedBox(height: 14),
                  const FieldLabel('Loader name'),
                  TextField(
                    controller: loaderCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: opInput(hint: 'Loader name'),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Receive date'),
                            ValueBox(
                              DateFormat('yyyy-MM-dd').format(receivedAt),
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
                            const FieldLabel('Receive time'),
                            ValueBox(
                              DateFormat('hh:mm a').format(receivedAt),
                              icon: Icons.schedule_rounded,
                              onTap: _pickTime,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const FieldLabel(
                    'Issue receipt — signed (required to accept)',
                  ),
                  PhotoStrip(
                    photos: signed,
                    onAdd: () => _pick(true),
                    onRemove: (p) => setState(() => signed.remove(p)),
                    hint: 'Upload / take a photo of the signed receipt',
                    accent: opGreen,
                  ),
                  const SizedBox(height: 11),
                  const FieldLabel('Received item photo(s)'),
                  PhotoStrip(
                    photos: items,
                    onAdd: () => _pick(false),
                    onRemove: (p) => setState(() => items.remove(p)),
                    hint: 'Upload / take a photo',
                    accent: opGreen,
                  ),
                  const SizedBox(height: 11),
                  // Split receipt: what is taken in here, and what goes back.
                  // The two always add up to the qty that was sent.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Qty accepted'),
                            _qtyField(qtyCtrl, opGreen, (v) {
                              final a = v.clamp(0, cn.qty);
                              rejectQtyCtrl.text = fmtQty(cn.qty - a);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Qty rejected'),
                            _qtyField(rejectQtyCtrl, opRed, (v) {
                              final r = v.clamp(0, cn.qty);
                              qtyCtrl.text = fmtQty(cn.qty - r);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    balanced
                        ? '${fmtQty(cn.qty)} sent — accounted for.'
                        : 'Accepted + rejected must add up to ${fmtQty(cn.qty)}.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: balanced ? newTextHint : opRed,
                    ),
                  ),
                  // Rejected pieces always go back to the sender to be made
                  // again — writing stock off is their QC's call, not the
                  // receiver's.
                  if (rejQty > 0) ...[
                    const SizedBox(height: 11),
                    const FieldLabel('Reason for rejecting'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kConsignmentRejectReasons
                          .map(
                            (s) => ChoiceChip(
                              label: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              selected: reasonCtrl.text == s,
                              selectedColor: opRedBg,
                              onSelected: (_) =>
                                  setState(() => reasonCtrl.text = s),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 12.5),
                      decoration: opInput(hint: 'Reason / details'),
                    ),
                  ],
                  const SizedBox(height: 11),
                  const FieldLabel('Remarks (optional)'),
                  TextField(
                    controller: remarksCtrl,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: opInput(hint: 'Anything short / damaged?'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (rejQty < cn.qty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: c.saving ? null : _rejectAll,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        'Reject all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: opRed,
                        side: BorderSide(color: opRed.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: BigButton(
                    // One action: it books what was accepted and sends the
                    // rest back in the same call.
                    accQty <= 0
                        ? 'Send ${fmtQty(rejQty)} back'
                        : rejQty <= 0
                        ? 'Accept ${fmtQty(accQty)}'
                        : 'Accept ${fmtQty(accQty)} · reject ${fmtQty(rejQty)}',
                    icon: accQty <= 0
                        ? Icons.undo_rounded
                        : Icons.check_rounded,
                    busy: c.saving,
                    gradient: accQty <= 0 ? null : opGreenGradient,
                    color: accQty <= 0 ? opRed : null,
                    onTap: balanced ? () => _submit(c) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rejQty <= 0
                  ? 'Accepted qty is booked at your stage and production can start.'
                  : 'Rejected qty goes back to ${_t(cn.fromstagename)} to be produced again — QC checks it there before it can be re-issued.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: newTextHint,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
