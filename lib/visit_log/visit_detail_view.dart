import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/visit_log/visit_controller.dart';
import 'package:newdigitalerp/visit_log/visit_list_view.dart';
import 'package:newdigitalerp/visit_log/visit_models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen 2 — one visit: header, field grid, measurements, attachments
/// (open / add / delete) and follow-ups (thread + add). Edit opens the form.
class VisitDetailView extends StatelessWidget {
  const VisitDetailView({super.key});

  static const _bg = Color(0xFFF6F7F9);
  static const _purple = Color(0xFF5B6CF6);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _ink,
        title: const Text('Visit', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          GetBuilder<VisitController>(builder: (ctrl) {
            if (ctrl.detail?.visit == null) return const SizedBox.shrink();
            return Row(children: [
              TextButton.icon(
                onPressed: ctrl.startEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
                style: TextButton.styleFrom(foregroundColor: _purple),
              ),
              IconButton(
                onPressed: () => _confirmDelete(ctrl),
                icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              ),
            ]);
          }),
        ],
      ),
      body: GetBuilder<VisitController>(builder: (ctrl) {
        if (ctrl.detailLoading && ctrl.detail == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final v = ctrl.detail?.visit;
        if (v == null) {
          return const Center(child: Text('Could not load visit.'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
          children: [
            _headerCard(v),
            const SizedBox(height: 12),
            _fieldsCard(v),
            if (ctrl.detail!.measurements.isNotEmpty) ...[
              const SizedBox(height: 12),
              _measurementsCard(ctrl.detail!.measurements),
            ],
            const SizedBox(height: 12),
            _attachmentsCard(ctrl),
            const SizedBox(height: 12),
            _followupsCard(ctrl),
          ],
        );
      }),
    );
  }

  // ── Header ──
  Widget _headerCard(VisitRecord v) {
    final sc = VisitListView.statusColor(v.status);
    final date = _fmtDate(v.visitDate);
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(v.visitTo.isEmpty ? '—' : v.visitTo,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _ink)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text(v.status,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700, color: sc)),
        ),
      ]),
      const SizedBox(height: 4),
      Text('${v.visitNo}${date.isNotEmpty ? '  ·  $date' : ''}',
          style: const TextStyle(fontSize: 12.5, color: _muted)),
    ]));
  }

  // ── Field grid ──
  Widget _fieldsCard(VisitRecord v) {
    final pairs = <List<String>>[
      ['Visited By', v.visitedByName],
      ['Purpose Type', v.purposeType],
      ['Location', v.location],
      ['Contact Person', v.contactPerson],
      ['Contact No', v.contactNo],
      ['Distance (km)', v.distanceKm == 0 ? '' : _trim(v.distanceKm)],
      ['Travel Mode', v.travelMode],
      ['Check-in', _fmtDateTime(v.checkInTime)],
      ['Check-out', _fmtDateTime(v.checkOutTime)],
    ].where((p) => p[1].trim().isNotEmpty).toList();

    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
        runSpacing: 14,
        children: [
          for (final p in pairs)
            SizedBox(
              width: (Get.width - 28 - 28) / 2,
              child: _kv(p[0], p[1]),
            ),
        ],
      ),
      if (v.purpose.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _kv('Purpose / Details', v.purpose),
      ],
      if (v.outcome.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        _kv('Outcome', v.outcome),
      ],
      if (v.latitude != 0 || v.longitude != 0) ...[
        const SizedBox(height: 14),
        InkWell(
          onTap: () => _open(
              'https://www.google.com/maps/search/?api=1&query=${v.latitude},${v.longitude}'),
          child: Row(children: const [
            Icon(Icons.map_outlined, size: 16, color: _purple),
            SizedBox(width: 6),
            Text('View on map',
                style: TextStyle(
                    color: _purple, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      ],
    ]));
  }

  Widget _kv(String k, String v) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
                color: _muted)),
        const SizedBox(height: 3),
        Text(v, style: const TextStyle(fontSize: 14, color: _ink)),
      ]);

  // ── Measurements ──
  Widget _measurementsCard(List<VisitMeasurement> ms) {
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.straighten, 'Site Measurements'),
      const SizedBox(height: 6),
      for (final m in ms)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.itemName.isEmpty ? '—' : m.itemName,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: _ink)),
            if (m.description.isNotEmpty)
              Text(m.description,
                  style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 2),
            Text(
              'L ${_trim(m.length)} · W ${_trim(m.width)} · H ${_trim(m.height)} · '
              'Qty ${_trim(m.qty)} ${m.unit} · Area ${_trim(m.area)}'
              '${m.remarks.isNotEmpty ? ' · ${m.remarks}' : ''}',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
            const Divider(height: 14, color: _border),
          ]),
        ),
    ]));
  }

  // ── Attachments ──
  Widget _attachmentsCard(VisitController ctrl) {
    final atts = ctrl.detail!.attachments;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _sectionTitle(Icons.attach_file, 'Attachments')),
        TextButton.icon(
          onPressed: ctrl.addAttachmentsToCurrentVisit,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          style: TextButton.styleFrom(foregroundColor: _purple),
        ),
      ]),
      if (atts.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text('No attachments.',
              style: TextStyle(fontSize: 12.5, color: _muted)),
        ),
      for (final a in atts) _attachmentRow(ctrl, a),
    ]));
  }

  Widget _attachmentRow(VisitController ctrl, AttachmentItem a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(a.isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
            size: 20, color: _purple),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.fileName,
                style: const TextStyle(fontSize: 13, color: _ink),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
                '${a.sizeLabel}${a.uploadedBy.isNotEmpty ? ' · ${a.uploadedBy}' : ''}'
                '${a.uploadedDate.isNotEmpty ? ' · ${a.uploadedDate}' : ''}',
                style: const TextStyle(fontSize: 11, color: _muted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.open_in_new, size: 18, color: _purple),
          onPressed: a.url.isEmpty ? null : () => _open(a.url),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
          onPressed: () => ctrl.deleteAttachment(a.id),
        ),
      ]),
    );
  }

  // ── Follow-ups ──
  Widget _followupsCard(VisitController ctrl) {
    final fs = ctrl.detail!.followups;
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.forum_outlined, 'Follow-ups'),
      const SizedBox(height: 6),
      if (fs.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child:
              Text('No follow-ups yet.', style: TextStyle(fontSize: 12.5, color: _muted)),
        ),
      for (final f in fs)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.comment, style: const TextStyle(fontSize: 13.5, color: _ink)),
            const SizedBox(height: 2),
            Text('${f.createdByName} · ${f.createdAt}',
                style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl.followupCtrl,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Add a follow-up…',
              hintStyle: const TextStyle(fontSize: 13.5, color: _muted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _purple, width: 1.3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: ctrl.postingFollowup ? null : ctrl.addFollowup,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: ctrl.postingFollowup
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: Colors.white))
                : const Text('Send'),
          ),
        ),
      ]),
    ]));
  }

  // ── helpers ──
  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: child,
      );

  Widget _sectionTitle(IconData ic, String t) => Row(children: [
        Icon(ic, size: 17, color: _purple),
        const SizedBox(width: 7),
        Text(t,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
      ]);

  void _confirmDelete(VisitController ctrl) {
    final id = ctrl.detail?.visit?.id ?? 0;
    if (id <= 0) return;
    Get.dialog(AlertDialog(
      title: const Text('Delete visit?'),
      content: const Text('This visit will be removed.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.deleteVisit(id);
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? '' : DateFormat('dd MMM yyyy').format(d);
  }

  String _fmtDateTime(String iso) {
    if (iso.trim().isEmpty) return '';
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('dd MMM yyyy, HH:mm').format(d);
  }
}
