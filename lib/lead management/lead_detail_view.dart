// Lead Detail — mirrors the web ERP /Home/LeadDetail screen:
// header + action bar (Add Follow-up / Create Task / Estimation / Quotation /
// Notes), Lead Information card, Lead Items table, Latest Estimate, Latest
// Quotation, and Follow-up / Task / Notes history. All data comes from the
// dashboard bundle already loaded in the controller; item lines are fetched on
// open via /api/lead/items.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/lead%20management/lead%20management%20controller/lead_management_controller.dart';
import 'lead_list_response.dart';

const Color _kPrimary = Color(0xFF4361EE);
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kDivider = Color(0xFFEFF2F7);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kCardShadow = Color(0x0A000000);

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'open':
      return const Color(0xFF6366F1);
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'confirmed':
      return const Color(0xFF10B981);
    case 'close':
    case 'closed':
      return const Color(0xFFEF4444);
    case 'done':
    case 'won':
      return const Color(0xFF06B6D4);
    default:
      return const Color(0xFF94A3B8);
  }
}

class LeadDetailView extends StatefulWidget {
  const LeadDetailView({Key? key}) : super(key: key);

  @override
  State<LeadDetailView> createState() => _LeadDetailViewState();
}

class _LeadDetailViewState extends State<LeadDetailView> {
  @override
  void initState() {
    super.initState();
    // Load item lines for the opened lead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<LeadManagementController>().loadSelectedItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeadManagementController>(
      builder: (c) {
        final lead = c.selectedLead;
        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            backgroundColor: _kSurface,
            elevation: 0,
            scrolledUnderElevation: 1,
            shadowColor: _kBorder,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _kTextPrimary, size: 16),
              ),
            ),
            title: Text(lead?.companyname ?? 'Lead Detail',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          body: lead == null
              ? const Center(child: Text('No lead selected'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                  children: [
                    _header(lead),
                    const SizedBox(height: 14),
                    _actionBar(),
                    const SizedBox(height: 14),
                    _infoCard(lead),
                    const SizedBox(height: 14),
                    _itemsCard(c),
                    const SizedBox(height: 14),
                    _docCard(
                      title: 'Latest Estimate',
                      icon: Icons.calculate_outlined,
                      color: const Color(0xFFF59E0B),
                      doc: c.latestEstimate,
                      emptyText: 'No estimate created yet',
                    ),
                    const SizedBox(height: 14),
                    _docCard(
                      title: 'Latest Quotation',
                      icon: Icons.description_outlined,
                      color: _kPrimary,
                      doc: c.latestQuotation,
                      emptyText: 'No quotation created yet',
                    ),
                    const SizedBox(height: 14),
                    _followupCard(c),
                    const SizedBox(height: 14),
                    _taskCard(c),
                    const SizedBox(height: 14),
                    _notesCard(c),
                  ],
                ),
        );
      },
    );
  }

  // ── Header ──
  Widget _header(LeadData lead) {
    final statusColor = _statusColor(lead.status ?? '');
    return _shell(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(lead.companyname ?? 'N/A',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text(lead.status ?? '-',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          _chip(Icons.person_outline, lead.contactperson ?? '-'),
          _chip(Icons.phone_outlined, lead.mobilenumber ?? '-'),
          _chip(Icons.calendar_today_outlined, lead.leaddate ?? '-'),
        ]),
      ]),
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kTextSecondary),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(fontSize: 12.5, color: _kTextSecondary)),
        ],
      );

  // ── Action bar ──
  Widget _actionBar() {
    Widget btn(String label, IconData icon, Color color) => Expanded(
          child: GestureDetector(
            onTap: () => _comingSoon(label),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ]),
            ),
          ),
        );
    return Row(children: [
      btn('Follow-up', Icons.add_call, const Color(0xFF3B82F6)),
      btn('Task', Icons.checklist_rounded, const Color(0xFF10B981)),
      btn('Estimation', Icons.calculate_outlined, const Color(0xFFF59E0B)),
      btn('Quotation', Icons.description_outlined, _kPrimary),
      btn('Notes', Icons.sticky_note_2_outlined, const Color(0xFF8B5CF6)),
    ]);
  }

  void _comingSoon(String label) {
    Get.snackbar(label, 'This action is part of the next (write) phase.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
        backgroundColor: Colors.black87,
        colorText: Colors.white);
  }

  // ── Lead Information card ──
  Widget _infoCard(LeadData lead) {
    return _titledCard(
      title: 'Lead Information',
      icon: Icons.info_outline_rounded,
      child: Column(children: [
        Row(children: [
          _kv('Lead No', lead.leadnumber ?? '-'),
          _kv('Company Name', lead.companyname ?? '-'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _kv('Contact Person', lead.contactperson ?? '-'),
          _kv('Mobile No', lead.mobilenumber ?? '-'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _kv('Lead Source', lead.leadsource ?? '-'),
          _kv('Status', lead.status ?? '-'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _kv('Assigned To', lead.handler ?? '-'),
          _kv('Address', lead.address ?? '-'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _kv('Requirement / Specification', lead.specification ?? '-'),
        ]),
        if ((lead.otherremarks ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(children: [_kv('Remarks', lead.otherremarks ?? '-')]),
        ],
      ]),
    );
  }

  Widget _kv(String label, String value) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: _kTextSecondary)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
        ]),
      );

  // ── Lead Items ──
  Widget _itemsCard(LeadManagementController c) {
    return _titledCard(
      title: 'Lead Items',
      icon: Icons.inventory_2_outlined,
      child: c.itemsBusy
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 2)),
            )
          : c.selectedItems.isEmpty
              ? _emptyLine('No items on this lead')
              : Column(children: [
                  // header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 8),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: _kDivider))),
                    child: Row(children: const [
                      Expanded(flex: 4, child: _Th('ITEM')),
                      Expanded(flex: 2, child: _Th('QTY')),
                      Expanded(flex: 2, child: _Th('UNIT')),
                      Expanded(flex: 2, child: _Th('RATE')),
                    ]),
                  ),
                  ...c.selectedItems.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        child: Row(children: [
                          Expanded(
                              flex: 4,
                              child: Text(it.itemName ?? '-',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _kTextPrimary))),
                          Expanded(
                              flex: 2,
                              child: Text(_num(it.quantity),
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: _kTextSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text(it.unit ?? '-',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: _kTextSecondary))),
                          Expanded(
                              flex: 2,
                              child: Text(_num(it.salePrice),
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: _kTextSecondary))),
                        ]),
                      )),
                ]),
    );
  }

  // ── Estimate / Quotation card ──
  Widget _docCard({
    required String title,
    required IconData icon,
    required Color color,
    required LeadDocData? doc,
    required String emptyText,
  }) {
    return _titledCard(
      title: title,
      icon: icon,
      iconColor: color,
      child: doc == null
          ? _emptyLine(emptyText)
          : Column(children: [
              Row(children: [
                _kv('No', doc.docNo ?? '-'),
                _kv('Date', doc.docDate ?? '-'),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _kv('Party', doc.partyName ?? '-'),
                _kv('Grand Total', _num(doc.grandTotal)),
              ]),
            ]),
    );
  }

  // ── Follow-up history ──
  Widget _followupCard(LeadManagementController c) {
    final list = c.followupList;
    return _titledCard(
      title: 'Follow-up History (${list.length})',
      icon: Icons.history_rounded,
      child: list.isEmpty
          ? _emptyLine('No follow-up history yet')
          : Column(
              children: list
                  .map((f) => _timelineRow(
                        top: f.followupdate ?? f.entrydate ?? '-',
                        title: (f.status ?? 'Follow-up'),
                        body: [
                          if ((f.remarks ?? '').isNotEmpty) f.remarks!,
                          if ((f.purpose ?? '').isNotEmpty) f.purpose!,
                        ].join('  •  '),
                        color: _statusColor(f.status ?? ''),
                      ))
                  .toList(),
            ),
    );
  }

  // ── Task history ──
  Widget _taskCard(LeadManagementController c) {
    final list = c.selectedTasks;
    return _titledCard(
      title: 'Task History (${list.length})',
      icon: Icons.checklist_rounded,
      iconColor: const Color(0xFF10B981),
      child: list.isEmpty
          ? _emptyLine('No tasks created yet')
          : Column(
              children: list
                  .map((t) => _timelineRow(
                        top: t.dueDate ?? t.createdDate ?? '-',
                        title: t.title ?? 'Task',
                        body: [
                          if ((t.priority ?? '').isNotEmpty)
                            'Priority: ${t.priority}',
                          if ((t.status ?? '').isNotEmpty) t.status!,
                          if ((t.description ?? '').isNotEmpty) t.description!,
                        ].join('  •  '),
                        color: const Color(0xFF10B981),
                      ))
                  .toList(),
            ),
    );
  }

  // ── Notes history ──
  Widget _notesCard(LeadManagementController c) {
    final list = c.selectedNotes;
    return _titledCard(
      title: 'Notes History (${list.length})',
      icon: Icons.sticky_note_2_outlined,
      iconColor: const Color(0xFF8B5CF6),
      child: list.isEmpty
          ? _emptyLine('No notes added yet')
          : Column(
              children: list
                  .map((n) => _timelineRow(
                        top: n.createdOn ?? '-',
                        title: n.title ?? 'Note',
                        body: n.content ?? '',
                        color: const Color(0xFF8B5CF6),
                      ))
                  .toList(),
            ),
    );
  }

  Widget _timelineRow({
    required String top,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary)),
          ),
          Text(top,
              style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
        ]),
        if (body.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
        ],
      ]),
    );
  }

  // ── shells & helpers ──
  Widget _shell({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: _kCardShadow, blurRadius: 10, offset: Offset(0, 3))
          ],
        ),
        child: child,
      );

  Widget _titledCard({
    required String title,
    required IconData icon,
    Color iconColor = _kPrimary,
    required Widget child,
  }) =>
      _shell(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary)),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _emptyLine(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
        ),
      );

  static String _num(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: _kTextSecondary));
}
