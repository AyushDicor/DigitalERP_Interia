import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/repo/visit_entry_repo.dart';
import 'package:url_launcher/url_launcher.dart';

import 'visit_entry_controller.dart';

/// Visit detail — same information as the web ERP's right-hand pane:
/// the field grid, the attachments list, and followups.
class VisitEntryDetailScreen extends StatefulWidget {
  const VisitEntryDetailScreen({Key? key}) : super(key: key);

  @override
  State<VisitEntryDetailScreen> createState() => _VisitEntryDetailScreenState();
}

class _VisitEntryDetailScreenState extends State<VisitEntryDetailScreen> {
  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  late final VisitEntryController c;
  late final int visitId;

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<VisitEntryController>()
        ? Get.find<VisitEntryController>()
        : Get.put(VisitEntryController());
    final args = Get.arguments;
    visitId = (args is Map) ? int.tryParse('${args['id'] ?? 0}') ?? 0 : 0;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => c.loadDetail(visitId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _text,
        title: const Text('Visit Detail',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GetBuilder<VisitEntryController>(
        init: c,
        builder: (ctrl) {
          if (ctrl.detailLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _primary));
          }
          final d = ctrl.detail;
          if (d == null) {
            return const Center(
                child: Text('Visit not found', style: TextStyle(color: _sub)));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              _headerCard(d),
              const SizedBox(height: 12),
              _attachmentsCard(ctrl, d),
              const SizedBox(height: 12),
              _followupsCard(ctrl, d),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCard(VisitDetailData d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(d.visitTo.isEmpty ? 'Visit' : d.visitTo,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _text)),
            ),
            if (d.status.isNotEmpty) _statusChip(d.status),
          ]),
          const SizedBox(height: 4),
          Text(
            [d.visitNo, d.visitDate].where((e) => e.isNotEmpty).join(' · '),
            style: const TextStyle(fontSize: 12, color: _sub),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFEEF0F4)),
          ),

          // Same grid the web pane shows, two per row.
          _pair(_field('Visited By', d.visitedBy),
              _field('Purpose Type', d.purposeType)),
          _pair(_field('Location', d.location),
              _field('Contact Person', d.contactPerson)),
          _pair(_field('Contact No', d.contactNo),
              _field('Distance (km)',
                  d.distanceKm == 0 ? '' : d.distanceKm.toStringAsFixed(2))),
          _pair(_field('Travel Mode', d.travelMode),
              _field('Area', d.areaName)),
          _pair(_field('Check-in', d.checkIn),
              _field('Check-out', d.checkOut)),
          _field('Purpose / Details', d.purpose, full: true),
          _field('Outcome', d.outcome, full: true),
          if (d.createdBy.isNotEmpty)
            _field('Created By', d.createdBy, full: true),
        ],
      ),
    );
  }

  Widget _attachmentsCard(VisitEntryController ctrl, VisitDetailData d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.attach_file_rounded, size: 17, color: _sub),
            const SizedBox(width: 8),
            Text(
              d.attachments.isEmpty
                  ? 'Attachments'
                  : 'Attachments (${d.attachments.length})',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _text),
            ),
            const Spacer(),
            if (ctrl.uploadingAttachment)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextButton.icon(
                onPressed: () => ctrl.addAttachmentToVisit(d.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    visualDensity: VisualDensity.compact),
              ),
          ]),
          if (d.attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No files attached',
                  style: TextStyle(fontSize: 12.5, color: _sub)),
            )
          else
            ...d.attachments.map((a) => _attachmentTile(ctrl, a, d.id)),
        ],
      ),
    );
  }

  Widget _attachmentTile(
      VisitEntryController ctrl, AttachmentItem a, int visitId) {
    final meta = [
      if (a.sizeLabel.isNotEmpty) a.sizeLabel,
      if (a.uploadedBy.isNotEmpty) a.uploadedBy,
      if (a.uploadedDate.isNotEmpty) a.uploadedDate,
    ].join(' · ');

    final color = a.isPdf
        ? const Color(0xFFDC2626)
        : a.isImage
            ? const Color(0xFF16A34A)
            : _primary;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final uri = Uri.tryParse(a.url);
          if (uri == null || a.url.isEmpty) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
                a.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : a.isImage
                        ? Icons.image_outlined
                        : Icons.insert_drive_file_outlined,
                size: 19,
                color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text)),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _sub)),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(ctrl, a, visitId),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 19, color: _sub),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }

  Widget _followupsCard(VisitEntryController ctrl, VisitDetailData d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.forum_outlined, size: 17, color: _sub),
            const SizedBox(width: 8),
            Text(
              d.followups.isEmpty
                  ? 'Followups'
                  : 'Followups (${d.followups.length})',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _text),
            ),
          ]),
          const SizedBox(height: 6),
          if (d.followups.isEmpty)
            const Text('No followups yet.',
                style: TextStyle(fontSize: 12.5, color: _sub))
          else
            ...d.followups.map((f) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.comment,
                          style: const TextStyle(fontSize: 13, color: _text)),
                      const SizedBox(height: 2),
                      Text(
                        [f.byName, f.date].where((e) => e.isNotEmpty).join(' · '),
                        style: const TextStyle(fontSize: 11, color: _sub),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl.followupCtrl,
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Add a followup…',
                  hintStyle: const TextStyle(fontSize: 13.5, color: _sub),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => ctrl.addFollowup(d.id),
              icon: const Icon(Icons.send_rounded, color: _primary),
            ),
          ]),
        ],
      ),
    );
  }

  void _confirmDelete(
      VisitEntryController ctrl, AttachmentItem a, int visitId) {
    Get.dialog(AlertDialog(
      title: const Text('Remove file?'),
      content: Text('${a.fileName} will be deleted from this visit.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            ctrl.deleteAttachment(a.id, visitId);
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          child: const Text('Remove'),
        ),
      ],
    ));
  }

  // ── small shared bits ──

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF0F4)),
        ),
        child: child,
      );

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    final color = s == 'completed'
        ? const Color(0xFF16A34A)
        : s == 'cancelled'
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  /// Label over value, matching the web pane. Empty values show "-" so the
  /// grid keeps its shape instead of fields silently vanishing.
  Widget _field(String label, String value, {bool full = false}) {
    final empty = value.trim().isEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: full ? 14 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: .6)),
          const SizedBox(height: 3),
          Text(empty ? '-' : value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  color: empty ? const Color(0xFF94A3B8) : _text)),
        ],
      ),
    );
  }

  Widget _pair(Widget left, Widget right) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        ),
      );
}
