import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/screen/ui/home/visit_plan/visit_plan_detail/visit_plan_detail_controller.dart';
import 'package:newdigitalerp/utils/all_screens_dialog_box/dialog_bg_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class VisitPlanDetailView extends StatelessWidget {
  const VisitPlanDetailView({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);
  static const _line = Color(0xFFEEF0F4);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VisitPlanDetailController>(
      init: VisitPlanDetailController(),
      builder: (controller) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: _text,
          title: const Text('Visit Plan Detail',
              style: TextStyle(fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => controller.backTap(),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (v) {
                if (v == 'delete') _confirmDeleteVisit(controller);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: Color(0xFFDC2626)),
                    SizedBox(width: 10),
                    Text('Delete visit'),
                  ]),
                ),
              ],
            ),
          ],
        ),
        body: controller.isBusy
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : controller.visitPlanDetailList.isEmpty
                ? _emptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    children: [
                      ...List.generate(
                        controller.visitPlanDetailList.length,
                        (i) => _card(controller, i, context),
                      ),
                      _attachmentsCard(controller),
                      const SizedBox(height: 12),
                      _followupsCard(controller),
                    ],
                  ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded,
                  size: 34, color: _primary),
            ),
            const SizedBox(height: 14),
            const Text('No visits in this plan',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _text)),
            const SizedBox(height: 4),
            const Text('Nothing has been planned for this date.',
                style: TextStyle(fontSize: 13, color: _sub)),
          ],
        ),
      );

  /// The check state shown on the button. Reads the row's own status and only
  /// consults the check-in / check-out lists when they actually have an entry
  /// at this index — the previous version indexed those lists by this list's
  /// index guarding only for empty, which threw RangeError whenever their
  /// lengths differed.
  String _checkStatus(VisitPlanDetailController c, int index) {
    final own = c.visitPlanDetailList[index].checkstatus ?? '';
    if (index < c.visitCheckOutList.length) {
      final s = c.visitCheckOutList[index].checkstatus ?? '';
      if (s.isNotEmpty) return s;
    }
    if (index < c.visitCheckInList.length) {
      final s = c.visitCheckInList[index].checkstatus ?? '';
      if (s.isNotEmpty) return s;
    }
    return own;
  }

  /// Order / Stock / Collection only make sense once the visit is under way.
  bool _actionsEnabled(String status) =>
      status.isNotEmpty && status != 'Check In';

  Color _statusColor(String s) {
    switch (s) {
      case 'Check In':
        return const Color(0xFFD97706);
      case 'Check Out':
        return const Color(0xFF16A34A);
      case 'Checked Out':
        return const Color(0xFFDC2626);
      default:
        return _sub;
    }
  }

  Widget _card(
      VisitPlanDetailController controller, int index, BuildContext context) {
    final item = controller.visitPlanDetailList[index];
    final status = _checkStatus(controller, index);
    final enabled = _actionsEnabled(status);
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
                          const Text('CUSTOMER',
                              style: TextStyle(
                                  fontSize: 9.5,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .6)),
                          const SizedBox(height: 3),
                          Text(
                            item.customername ?? 'N/A',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Check In / Check Out
                    if (status.isNotEmpty)
                      ElevatedButton(
                        onPressed: () {
                          if (status == 'Check In') {
                            controller.tapOnCheckIn(index);
                          } else if (status == 'Check Out') {
                            _showRemarkDialog(controller, index);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(status,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Date', item.visitdate)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Timing', item.visittime)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Status', item.visitstatus)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(
                            'Executive', controller.argument?.executive)),
                  ],
                ),

                // ── Visit details, same layout as the web ERP's detail pane ──
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Purpose Type', item.purposeType)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Location', item.location)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _field('Contact Person', item.contactPerson)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Contact No', item.contactNo)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Distance (km)', item.distance)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Travel Mode', item.travelMode)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _field('Check-in', item.checkInTime)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Check-out', item.checkOutTime)),
                  ],
                ),
                const SizedBox(height: 12),
                _field('Purpose / Details', item.purpose),
                const SizedBox(height: 12),
                _field('Outcome', item.outcome),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Order',
                    color: const Color(0xFFF97316),
                    enabled: enabled,
                    onTap: () => controller.tapOnOrder(index),
                  ),
                ),
                _divider(),
                Expanded(
                  child: _action(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    color: _primary,
                    enabled: enabled,
                    onTap: () => controller.tapOnStock(item),
                  ),
                ),
                _divider(),
                Expanded(
                  child: _action(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Collection',
                    color: const Color(0xFFDC2626),
                    enabled: enabled,
                    onTap: () => controller.tapOnPayment(item.partyid),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //  Attachments — from /api/visit/detail. The presigned URLs expire after an
  //  hour, so the list is re-fetched on every load rather than cached.

  Widget _attachmentsCard(VisitPlanDetailController c) {
    return _cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.attach_file_rounded, size: 17, color: _sub),
            const SizedBox(width: 8),
            Text(
              c.attachments.isEmpty
                  ? 'Attachments'
                  : 'Attachments (${c.attachments.length})',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _text),
            ),
            const Spacer(),
            if (c.uploadingAttachment)
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              TextButton.icon(
                onPressed: c.addAttachment,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    visualDensity: VisualDensity.compact),
              ),
          ]),
          if (c.attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('No files attached',
                  style: TextStyle(fontSize: 12.5, color: _sub)),
            )
          else
            ...c.attachments.map((a) => _attachmentTile(c, a)),
        ],
      ),
    );
  }

  Widget _attachmentTile(VisitPlanDetailController c, AttachmentItem a) {
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
          if (a.url.isEmpty) return;
          final uri = Uri.tryParse(a.url);
          if (uri == null) return;
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
            onPressed: () => _confirmDeleteFile(c, a),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 19, color: _sub),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }

  Widget _followupsCard(VisitPlanDetailController c) {
    return _cardBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.forum_outlined, size: 17, color: _sub),
            const SizedBox(width: 8),
            Text(
              c.followups.isEmpty
                  ? 'Followups'
                  : 'Followups (${c.followups.length})',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _text),
            ),
          ]),
          const SizedBox(height: 6),
          if (c.followups.isEmpty)
            const Text('No followups yet.',
                style: TextStyle(fontSize: 12.5, color: _sub))
          else
            ...c.followups.map((f) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.comment,
                          style:
                              const TextStyle(fontSize: 13, color: _text)),
                      const SizedBox(height: 2),
                      Text(
                        [f.byName, f.date]
                            .where((e) => e.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(fontSize: 11, color: _sub),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: c.followupCtrl,
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
              onPressed: c.addFollowup,
              icon: const Icon(Icons.send_rounded, color: _primary),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _cardBox({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  void _confirmDeleteFile(VisitPlanDetailController c, AttachmentItem a) {
    Get.dialog(AlertDialog(
      title: const Text('Remove file?'),
      content: Text('${a.fileName} will be deleted from this visit.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            c.removeAttachment(a.id);
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          child: const Text('Remove'),
        ),
      ],
    ));
  }

  void _confirmDeleteVisit(VisitPlanDetailController c) {
    Get.dialog(AlertDialog(
      title: const Text('Delete visit?'),
      content: const Text('This visit will be removed. It cannot be undone.'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            c.deleteVisit();
          },
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  Widget _divider() =>
      Container(width: 1, height: 22, color: _line);

  Widget _field(String label, String? value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: .6)),
          const SizedBox(height: 3),
          Text(
            (value == null || value.trim().isEmpty) ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: (value == null || value.trim().isEmpty)
                  ? const Color(0xFF94A3B8)
                  : _text,
            ),
          ),
        ],
      );

  Widget _action({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final c = enabled ? color : const Color(0xFFCBD5E1);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: c),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ],
        ),
      ),
    );
  }

  void _showRemarkDialog(VisitPlanDetailController controller, int index) {
    Get.dialog(
      DialogNewWidget(
        onApplyOrDoneButtonTap: () {
          controller.tapOnCheckOut(index);
          Get.back();
        },
        isEdit: true,
        text: 'Remark :',
        buttonName: 'Check Out',
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextFormField(
              controller: controller.remarkController,
              maxLines: 5,
              style: const TextStyle(fontSize: 13.5, color: _text),
              decoration: const InputDecoration(
                hintText: 'Enter remark…',
                hintStyle: TextStyle(fontSize: 13.5, color: _sub),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
