import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/visit_log/visit_controller.dart';
import 'package:newdigitalerp/visit_log/visit_models.dart';

/// Screen 1 — the visit log. Date-range + status + purpose filters, search, and
/// a card per visit. Tap a card → detail; the FAB opens the New Visit form.
class VisitListView extends StatelessWidget {
  const VisitListView({super.key});

  static const _bg = Color(0xFFF6F7F9);
  static const _purple = Color(0xFF5B6CF6);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  static Color statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'planned':
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(VisitController());
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _ink,
        title: const Text('Visits',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => c.startNew(),
        backgroundColor: _purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Visit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: GetBuilder<VisitController>(
        init: c,
        builder: (ctrl) => Column(
          children: [
            _filters(ctrl),
            Expanded(child: _list(ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _filters(VisitController ctrl) {
    final df = DateFormat('dd-MM-yyyy');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: _dateBox('From', ctrl.fromDate, df, ctrl.pickFromDate)),
            const SizedBox(width: 8),
            Expanded(child: _dateBox('To', ctrl.toDate, df, ctrl.pickToDate)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _dropdown(
                value: ctrl.statusFilter,
                hint: 'All Status',
                items: ctrl.dd.statuses,
                onChanged: (v) => ctrl.setStatusFilter(v ?? ''),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown(
                value: ctrl.purposeFilter,
                hint: 'All Purpose',
                items: ctrl.dd.purposeTypes,
                onChanged: (v) => ctrl.setPurposeFilter(v ?? ''),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl.searchCtrl,
            onSubmitted: (_) => ctrl.loadList(),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search place / contact / no…',
              hintStyle: const TextStyle(fontSize: 13.5, color: _muted),
              prefixIcon: const Icon(Icons.search, size: 20, color: _muted),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, size: 18, color: _purple),
                onPressed: ctrl.loadList,
              ),
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
        ],
      ),
    );
  }

  Widget _dateBox(
      String label, DateTime? d, DateFormat df, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: _muted),
          const SizedBox(width: 8),
          Text(d == null ? label : df.format(d),
              style: const TextStyle(fontSize: 13, color: _ink)),
        ]),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: value.isEmpty ? null : value,
          hint: Text(hint,
              style: const TextStyle(fontSize: 13, color: _muted)),
          style: const TextStyle(fontSize: 13, color: _ink),
          items: [
            DropdownMenuItem(value: '', child: Text(hint)),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _list(VisitController ctrl) {
    if (ctrl.listLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ctrl.visits.isEmpty) {
      return RefreshIndicator(
        onRefresh: ctrl.loadList,
        child: ListView(children: [
          const SizedBox(height: 120),
          Icon(Icons.place_outlined, size: 44, color: _muted.withValues(alpha: .6)),
          const SizedBox(height: 12),
          Center(
            child: Text(ctrl.listError.isEmpty ? 'No visits.' : ctrl.listError,
                style: const TextStyle(color: _muted)),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: ctrl.loadList,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: ctrl.visits.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _card(ctrl, ctrl.visits[i]),
      ),
    );
  }

  Widget _card(VisitController ctrl, VisitListItem v) {
    final sc = statusColor(v.status);
    return InkWell(
      onTap: () => ctrl.openDetail(v.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(v.visitTo.isEmpty ? '—' : v.visitTo,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(v.status,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
            ),
          ]),
          const SizedBox(height: 8),
          _line(Icons.confirmation_number_outlined,
              '${v.visitNo}   •   ${v.visitDate}'),
          const SizedBox(height: 4),
          _line(Icons.person_outline,
              '${v.visitedByName}${v.contactPerson.isNotEmpty ? '   •   ${v.contactPerson}' : ''}'),
          const SizedBox(height: 4),
          _line(Icons.place_outlined,
              '${v.purposeType}${v.location.isNotEmpty ? '   •   ${v.location}' : ''}'),
        ]),
      ),
    );
  }

  Widget _line(IconData ic, String t) => Row(children: [
        Icon(ic, size: 13, color: _muted),
        const SizedBox(width: 6),
        Expanded(
            child: Text(t,
                style: const TextStyle(fontSize: 12.5, color: _muted),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);
}
