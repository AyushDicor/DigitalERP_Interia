// Quotation from a lead — a mobile-friendly form: party (from the lead),
// customer order no / remarks / date, an item grid (item + qty + rate + GST),
// and computed totals. Saves via /api/lead/savequotation →
// ProcCreateentrypagewithapprovalnew_v3 (@refid = lead id, 7 TVPs).

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/indian_number.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/lead%20management/lead%20management%20controller/lead_management_controller.dart';
import 'lead_form_models.dart';

const Color _kPrimary = Color(0xFF6366F1); // quotation accent (indigo)
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);

class LeadQuotationView extends StatefulWidget {
  const LeadQuotationView({Key? key}) : super(key: key);

  @override
  State<LeadQuotationView> createState() => _LeadQuotationViewState();
}

class _LeadQuotationViewState extends State<LeadQuotationView> {
  final _coNo = TextEditingController();
  final _remarks = TextEditingController();
  String _date = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<LeadManagementController>();
      if (c.itemMaster.isEmpty) c.loadFormData();
    });
  }

  @override
  void dispose() {
    _coNo.dispose();
    _remarks.dispose();
    super.dispose();
  }

  String _n(double v) => inrNum(v);

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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kTextPrimary, size: 18),
            ),
            title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Quotation',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary)),
                  Text(lead?.companyname ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary)),
                ]),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
                left: 14,
                right: 14,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 30),
            child: Column(children: [
              _headerCard(context, lead?.companyname ?? '-'),
              const SizedBox(height: 14),
              _itemsCard(c),
              const SizedBox(height: 14),
              _totalsCard(c),
              const SizedBox(height: 18),
              _saveButton(c),
              const SizedBox(height: 24),
            ]),
          ),
        );
      },
    );
  }

  Widget _headerCard(BuildContext ctx, String party) {
    return _card('Quotation Details', Icons.description_outlined, [
      _readonly('Party', party),
      const SizedBox(height: 12),
      _dateField(ctx),
      const SizedBox(height: 12),
      _field('Customer Order No', _coNo),
      const SizedBox(height: 12),
      _field('Remarks', _remarks, maxLines: 2),
    ]);
  }

  Widget _itemsCard(LeadManagementController c) {
    return _card('Items', Icons.inventory_2_outlined, [
      if (c.quotationItems.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text('No items added',
                style: TextStyle(fontSize: 12.5, color: _kTextSecondary)),
          ),
        )
      else
        ...List.generate(c.quotationItems.length, (i) {
          final it = c.quotationItems[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder)),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.itemname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kTextPrimary)),
                      const SizedBox(height: 2),
                      Text(
                          'Qty ${_n(it.quantity)} × ₹${_n(it.saleprice)}  ·  GST ${_n(it.gstPercent)}%',
                          style: const TextStyle(
                              fontSize: 11, color: _kTextSecondary)),
                    ]),
              ),
              Text('₹${_n(it.amount + it.gstAmount)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => c.removeQuotationItem(i),
                child: const Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFFEF4444)),
              ),
            ]),
          );
        }),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final line = await showDialog<LeadItemLine>(
              context: context,
              builder: (_) => _AddQuotationItemDialog(itemMaster: c.itemMaster),
            );
            if (line != null) c.addQuotationItem(line);
          },
          icon: const Icon(Icons.add, size: 18, color: _kPrimary),
          label: const Text('Add Item',
              style: TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
      ),
    ]);
  }

  Widget _totalsCard(LeadManagementController c) {
    Widget row(String l, String v, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l,
                    style: TextStyle(
                        fontSize: bold ? 14 : 12.5,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                        color: bold ? _kTextPrimary : _kTextSecondary)),
                Text(v,
                    style: TextStyle(
                        fontSize: bold ? 15 : 13,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                        color: _kTextPrimary)),
              ]),
        );
    return _card('Totals', Icons.summarize_outlined, [
      row('Total Qty', _n(c.quoTotalQty)),
      row('Total Amount', '₹${_n(c.quoTotalAmount)}'),
      row('Total GST', '₹${_n(c.quoTotalGst)}'),
      const Divider(height: 16),
      row('Grand Total', '₹${_n(c.quoGrand)}', bold: true),
    ]);
  }

  Widget _saveButton(LeadManagementController c) => SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: c.saving
              ? null
              : () async {
                  final ok = await c.submitQuotation(
                    customerOrderNo: _coNo.text.trim(),
                    remarks: _remarks.text.trim(),
                    date: _date,
                  );
                  if (ok) Get.back();
                },
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Create Quotation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      );

  // ── small ui helpers ──
  Widget _card(String title, IconData icon, List<Widget> children) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: _kPrimary),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _readonly(String label, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
        ]),
      );

  Widget _dateField(BuildContext ctx) => GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final d = await showDatePicker(
              context: ctx,
              initialDate: now,
              firstDate: DateTime(2018),
              lastDate: DateTime(now.year + 3));
          if (d != null) {
            setState(() => _date =
                '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder)),
          child: Row(children: [
            const Icon(Icons.event, size: 16, color: _kTextSecondary),
            const SizedBox(width: 10),
            Text(_date.isEmpty ? 'Quotation Date (today)' : _date,
                style: TextStyle(
                    fontSize: 14,
                    color: _date.isEmpty ? _kTextSecondary : _kTextPrimary)),
          ]),
        ),
      );

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: _kTextPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: _kTextSecondary),
          filled: true,
          fillColor: _kBg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        ),
      );
}

// ─────────────────── Add-item dialog (owns its own controllers) ─────────────
class _AddQuotationItemDialog extends StatefulWidget {
  final List<LeadOption> itemMaster;
  const _AddQuotationItemDialog({required this.itemMaster});

  @override
  State<_AddQuotationItemDialog> createState() =>
      _AddQuotationItemDialogState();
}

class _AddQuotationItemDialogState extends State<_AddQuotationItemDialog> {
  final _search = TextEditingController();
  final _qty = TextEditingController();
  final _rate = TextEditingController();
  final _gst = TextEditingController(text: '18');
  LeadOption? _picked;

  @override
  void dispose() {
    _search.dispose();
    _qty.dispose();
    _rate.dispose();
    _gst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.itemMaster.take(30).toList()
        : widget.itemMaster
            .where((o) => o.name.toLowerCase().contains(q))
            .take(30)
            .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Add Item',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary)),
          ),
          const SizedBox(height: 12),
          if (_picked == null) ...[
            _tf(_search, 'Search item…',
                onChanged: (_) => setState(() {}), prefix: Icons.search),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: list.isEmpty
                  ? const Center(
                      child: Text('No items',
                          style: TextStyle(color: _kTextSecondary)))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: _kBorder),
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(list[i].name,
                            style: const TextStyle(fontSize: 13.5)),
                        onTap: () => setState(() => _picked = list[i]),
                      ),
                    ),
            ),
          ] else ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
              child: Row(children: [
                Expanded(
                  child: Text(_picked!.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _picked = null),
                  child: const Icon(Icons.edit, size: 16, color: _kPrimary),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _tf(_qty, 'Qty', number: true)),
              const SizedBox(width: 8),
              Expanded(child: _tf(_rate, 'Rate', number: true)),
              const SizedBox(width: 8),
              Expanded(child: _tf(_gst, 'GST %', number: true)),
            ]),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white),
                onPressed: _picked == null
                    ? null
                    : () {
                        final qty = double.tryParse(_qty.text.trim()) ?? 0;
                        final rate = double.tryParse(_rate.text.trim()) ?? 0;
                        final gst = double.tryParse(_gst.text.trim()) ?? 0;
                        if (qty <= 0 || rate <= 0) return;
                        Navigator.pop(
                          context,
                          LeadItemLine(
                            itemid: _picked!.id,
                            itemname: _picked!.name,
                            quantity: qty,
                            saleprice: rate,
                            mrp: rate,
                            gstPercent: gst,
                          ),
                        );
                      },
                child: const Text('Add'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _tf(TextEditingController c, String hint,
          {bool number = false,
          IconData? prefix,
          ValueChanged<String>? onChanged}) =>
      TextField(
        controller: c,
        onChanged: onChanged,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix == null ? null : Icon(prefix, size: 18),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
        ),
      );
}
