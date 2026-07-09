// Performa Invoice (Sale Order) — full-parity CREATE form. Sections mirror the
// ERP: Main Details, Other Details, Party Details, Item Details, Other Expense,
// Totals, Terms & Condition. Saves via /api/saleorder/save.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'sale_order_create_controller.dart';
import 'sale_order_form_models.dart';

const Color _kPrimary = Color(0xFF7C3AED);
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kTextHint = Color(0xFF9CA3AF);

String _n(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

class PerformaInvoiceCreateView extends StatelessWidget {
  const PerformaInvoiceCreateView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleOrderCreateController>(
      init: SaleOrderCreateController()..loadForm(),
      builder: (c) => Scaffold(
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
          title: const Text('New Performa Invoice',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
        ),
        body: c.loadingForm
            ? const Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 2.5))
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 30),
                child: Column(children: [
                  _mainCard(context, c),
                  const SizedBox(height: 14),
                  _otherCard(context, c),
                  const SizedBox(height: 14),
                  _partyCard(c),
                  const SizedBox(height: 14),
                  _itemsCard(context, c),
                  const SizedBox(height: 14),
                  _otherExpenseCard(context, c),
                  const SizedBox(height: 14),
                  _totalsCard(c),
                  const SizedBox(height: 14),
                  _termsCard(c),
                  const SizedBox(height: 18),
                  _saveButton(c),
                  const SizedBox(height: 24),
                ]),
              ),
      ),
    );
  }

  // ── Main Details ──
  Widget _mainCard(BuildContext ctx, SaleOrderCreateController c) =>
      _card('Main Details', Icons.article_outlined, [
        _picker(ctx, c, 'Entry Type *', 'entrytype', c.form.entrytype),
        _picker(ctx, c, 'Series Type *', 'series', c.form.series),
        _dateTile(ctx, c, 'Order Date', true),
        _dateTile(ctx, c, 'Delivery Date', false),
        _picker(ctx, c, 'Party Category', 'partycategory', c.form.partycategory,
            onPick: (o) => c.onCategoryPicked(o)),
        _picker(ctx, c, 'Party Name *', 'party', c.partyNames,
            onPick: (o) => c.onPartyPicked(o),
            emptyHint: 'Select category first'),
        _field('Customer Order No', c.customerOrderNo),
        _picker(ctx, c, 'Delivery Type', 'deliverytype', c.form.deliverytype),
        _picker(ctx, c, 'Order Type', 'ordertype', c.form.ordertype),
        _picker(ctx, c, 'Order Priority', 'priority', c.form.priority),
        _field('Internal Remarks', c.internalRemarks),
        _field('Remark', c.remark, maxLines: 2, last: true),
      ]);

  // ── Other Details ──
  Widget _otherCard(BuildContext ctx, SaleOrderCreateController c) =>
      _card('Other Details', Icons.local_shipping_outlined, [
        _picker(ctx, c, 'Delivery Place', 'deliverystore', c.form.deliverystore,
            onPick: (o) => c.onStorePicked(o)),
        _picker(ctx, c, 'Store Contact Person', 'storecontact', c.storeContacts,
            emptyHint: 'Select delivery place first'),
        _picker(ctx, c, 'Dispatch Through', 'transportname',
            c.form.transportname),
        _field('DL No', c.dlNo),
        _picker(ctx, c, 'Currency *', 'currency', c.form.currency),
        _field('Destination', c.destination, last: true),
      ]);

  // ── Party Details (auto-filled on party select, still editable) ──
  Widget _partyCard(SaleOrderCreateController c) =>
      _card('Party Details', Icons.contact_page_outlined, [
        _field('Bill To Address', c.billToAddress, maxLines: 2),
        _field('Ship To Address', c.shipToAddress, maxLines: 2),
        _field('GST No', c.gstNo),
        _field('Mobile No', c.mobileNo, number: true, last: true),
      ]);

  // ── Item Details ──
  Widget _itemsCard(BuildContext ctx, SaleOrderCreateController c) =>
      _card('Item Details', Icons.inventory_2_outlined, [
        if (c.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: Text('No items added',
                    style: TextStyle(fontSize: 12.5, color: _kTextSecondary))),
          )
        else
          ...List.generate(c.items.length, (i) {
            final it = c.items[i];
            return _lineCard(
              title: it.itemname,
              subtitle:
                  'Qty ${_n(it.quantity)} ${it.billingunit} × ₹${_n(it.salerate)} · GST ${_n(it.gstpercent)}%'
                  '${it.sizename.isNotEmpty ? ' · ${it.sizename}' : ''}',
              amount: it.amount + it.gstAmount,
              onRemove: () => c.removeItem(i),
            );
          }),
        const SizedBox(height: 6),
        _addButton('Add Item', () async {
          final line = await showModalBottomSheet<SaleOrderItemLine>(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddItemSheet(
                itemMaster: c.itemMaster,
                sizes: c.form.itemsize,
                units: c.form.billingunit),
          );
          if (line != null) c.addItem(line);
        }),
      ]);

  // ── Other Expense ──
  Widget _otherExpenseCard(BuildContext ctx, SaleOrderCreateController c) =>
      _card('Other Expense', Icons.receipt_long_outlined, [
        if (c.otherExpenses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
                child: Text('No other expenses',
                    style: TextStyle(fontSize: 12.5, color: _kTextSecondary))),
          )
        else
          ...List.generate(c.otherExpenses.length, (i) {
            final o = c.otherExpenses[i];
            return _lineCard(
              title: o.accounttype.isEmpty ? o.nature : o.accounttype,
              subtitle:
                  '${o.nature}${o.taxpercent > 0 ? ' · Tax ${_n(o.taxpercent)}%' : ''}',
              amount: o.amount,
              onRemove: () => c.removeOther(i),
            );
          }),
        const SizedBox(height: 6),
        _addButton('Add Expense', () async {
          final o = await showModalBottomSheet<SaleOrderOtherExpense>(
            context: ctx,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AddExpenseSheet(othertypes: c.form.othertype),
          );
          if (o != null) c.addOther(o);
        }),
      ]);

  // ── Totals ──
  Widget _totalsCard(SaleOrderCreateController c) {
    Widget r(String l, String v, {bool bold = false}) => Padding(
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
      r('Total Qty', _n(c.totalQty)),
      r('Total Amount', '₹${_n(c.totalAmount)}'),
      r('Total GST', '₹${_n(c.totalGst)}'),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          const Expanded(
            child: Text('Round Off',
                style: TextStyle(fontSize: 12.5, color: _kTextSecondary)),
          ),
          SizedBox(
            width: 90,
            child: TextFormField(
              initialValue: c.roundOff == 0 ? '' : _n(c.roundOff),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))
              ],
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => c.setRoundOff(double.tryParse(v) ?? 0),
            ),
          ),
        ]),
      ),
      const Divider(height: 16, color: _kBorder),
      r('Grand Total', '₹${_n(c.grandTotal)}', bold: true),
    ]);
  }

  Widget _termsCard(SaleOrderCreateController c) =>
      _card('Terms & Condition', Icons.description_outlined, [
        _field('Description', c.terms, maxLines: 4, last: true),
      ]);

  Widget _saveButton(SaleOrderCreateController c) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: c.submitting
              ? null
              : () async {
                  final ok = await c.submit();
                  if (ok) Get.back(result: true);
                },
          icon: c.submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_circle_outline, size: 18),
          label: Text(c.submitting ? 'Creating…' : 'Create',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      );

  // ── shared building blocks ──
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

  Widget _picker(BuildContext ctx, SaleOrderCreateController c, String label,
      String key, List<SaleOrderOption> options,
      {Future<void> Function(SaleOrderOption)? onPick,
      String emptyHint = 'No options'}) {
    final val = c.selName[key] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: _kTextSecondary)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () async {
            final picked = await showModalBottomSheet<SaleOrderOption>(
              context: ctx,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _OptionSheet(
                  title: label, options: options, emptyHint: emptyHint),
            );
            if (picked != null) {
              if (onPick != null) {
                await onPick(picked);
              } else {
                c.pickOption(key, picked);
              }
            }
          },
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: val.isEmpty ? _kBorder : _kPrimary.withValues(alpha: 0.5))),
            child: Row(children: [
              Expanded(
                child: Text(val.isEmpty ? 'Select' : val,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            val.isEmpty ? FontWeight.w400 : FontWeight.w600,
                        color: val.isEmpty ? _kTextHint : _kTextPrimary)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: _kTextSecondary),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _dateTile(BuildContext ctx, SaleOrderCreateController c, String label,
          bool isOrder) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: _kTextSecondary)),
          const SizedBox(height: 5),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final d = await showDatePicker(
                  context: ctx,
                  initialDate: now,
                  firstDate: DateTime(2018),
                  lastDate: DateTime(now.year + 3));
              if (d != null) {
                c.setDate(
                    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                    isOrder);
              }
            },
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
              child: Row(children: [
                const Icon(Icons.event, size: 16, color: _kTextSecondary),
                const SizedBox(width: 10),
                Text(
                    (isOrder ? c.orderDate : c.deliveryDate).isEmpty
                        ? 'Select date'
                        : (isOrder ? c.orderDate : c.deliveryDate),
                    style: TextStyle(
                        fontSize: 14,
                        color: (isOrder ? c.orderDate : c.deliveryDate).isEmpty
                            ? _kTextHint
                            : _kTextPrimary)),
              ]),
            ),
          ),
        ]),
      );

  Widget _field(String label, TextEditingController ctrl,
          {int maxLines = 1, bool number = false, bool last = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 12),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
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
        ),
      );

  Widget _lineCard(
          {required String title,
          required String subtitle,
          required double amount,
          required VoidCallback onRemove}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.isEmpty ? '-' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: _kTextSecondary)),
            ]),
          ),
          Text('₹${_n(amount)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFFEF4444)),
          ),
        ]),
      );

  Widget _addButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 18, color: _kPrimary),
          label: Text(label,
              style: const TextStyle(
                  color: _kPrimary, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
      );
}

// ── Generic searchable option sheet ──
class _OptionSheet extends StatefulWidget {
  final String title;
  final List<SaleOrderOption> options;
  final String emptyHint;
  const _OptionSheet(
      {required this.title, required this.options, required this.emptyHint});
  @override
  State<_OptionSheet> createState() => _OptionSheetState();
}

class _OptionSheetState extends State<_OptionSheet> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final list = q.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.name.toLowerCase().contains(q))
            .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Select ${widget.title.replaceAll(' *', '')}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary)),
          ),
          const SizedBox(height: 12),
          if (widget.options.length > 6)
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: const TextStyle(fontSize: 14, color: _kTextHint),
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: _kTextSecondary),
                isDense: true,
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
            ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(widget.emptyHint,
                        style: const TextStyle(color: _kTextSecondary)))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _kBorder),
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      title: Text(list[i].name,
                          style: const TextStyle(fontSize: 13.5)),
                      onTap: () => Navigator.pop(context, list[i]),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Add-item sheet ──
class _AddItemSheet extends StatefulWidget {
  final List<SaleOrderOption> itemMaster;
  final List<SaleOrderOption> sizes;
  final List<SaleOrderOption> units;
  const _AddItemSheet(
      {required this.itemMaster, required this.sizes, required this.units});
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _search = TextEditingController();
  final _qty = TextEditingController();
  final _rate = TextEditingController();
  final _gst = TextEditingController(text: '18');
  SaleOrderOption? _item;
  SaleOrderOption? _size;
  SaleOrderOption? _unit;

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
        ? widget.itemMaster.take(40).toList()
        : widget.itemMaster
            .where((o) => o.name.toLowerCase().contains(q))
            .take(40)
            .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Add Item',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary))),
          const SizedBox(height: 12),
          if (_item == null) ...[
            _sheetField(_search, 'Search item…',
                prefix: Icons.search, onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
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
                        onTap: () => setState(() => _item = list[i]),
                      ),
                    ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
              child: Row(children: [
                Expanded(
                    child: Text(_item!.name,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600))),
                GestureDetector(
                    onTap: () => setState(() => _item = null),
                    child:
                        const Icon(Icons.edit, size: 16, color: _kPrimary)),
              ]),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _sheetField(_qty, 'Qty', number: true)),
              const SizedBox(width: 8),
              Expanded(child: _sheetField(_rate, 'Sales Rate', number: true)),
              const SizedBox(width: 8),
              Expanded(child: _sheetField(_gst, 'GST %', number: true)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _miniPicker('Size', _size?.name, widget.sizes,
                      (o) => setState(() => _size = o))),
              const SizedBox(width: 8),
              Expanded(
                  child: _miniPicker('Unit', _unit?.name, widget.units,
                      (o) => setState(() => _unit = o))),
            ]),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white),
                onPressed: _item == null
                    ? null
                    : () {
                        final qty = double.tryParse(_qty.text.trim()) ?? 0;
                        final rate = double.tryParse(_rate.text.trim()) ?? 0;
                        final gst = double.tryParse(_gst.text.trim()) ?? 0;
                        if (qty <= 0 || rate <= 0) return;
                        Navigator.pop(
                          context,
                          SaleOrderItemLine(
                            itemid: _item!.id,
                            itemname: _item!.name,
                            quantity: qty,
                            salerate: rate,
                            gstpercent: gst,
                            sizeid: _size?.id ?? 0,
                            sizename: _size?.name ?? '',
                            billingunitid: _unit?.id ?? 0,
                            billingunit: _unit?.name ?? '',
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

  Widget _miniPicker(String label, String? value, List<SaleOrderOption> options,
          ValueChanged<SaleOrderOption> onPick) =>
      GestureDetector(
        onTap: () async {
          final picked = await showModalBottomSheet<SaleOrderOption>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) =>
                _OptionSheet(title: label, options: options, emptyHint: 'None'),
          );
          if (picked != null) onPick(picked);
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder)),
          child: Row(children: [
            Expanded(
                child: Text(value == null || value.isEmpty ? label : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: value == null || value.isEmpty
                            ? _kTextHint
                            : _kTextPrimary))),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _kTextSecondary),
          ]),
        ),
      );
}

// ── Add other-expense sheet ──
class _AddExpenseSheet extends StatefulWidget {
  final List<SaleOrderOption> othertypes;
  const _AddExpenseSheet({required this.othertypes});
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _nature = TextEditingController();
  final _tax = TextEditingController();
  final _amount = TextEditingController();
  SaleOrderOption? _type;

  @override
  void dispose() {
    _nature.dispose();
    _tax.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _kBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Add Other Expense',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary))),
          const SizedBox(height: 12),
          _sheetField(_nature, 'Nature'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showModalBottomSheet<SaleOrderOption>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _OptionSheet(
                    title: 'Other Type',
                    options: widget.othertypes,
                    emptyHint: 'None'),
              );
              if (picked != null) setState(() => _type = picked);
            },
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
              child: Row(children: [
                Expanded(
                    child: Text(_type?.name ?? 'Other Type',
                        style: TextStyle(
                            fontSize: 14,
                            color:
                                _type == null ? _kTextHint : _kTextPrimary))),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: _kTextSecondary),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _sheetField(_tax, 'Tax %', number: true)),
            const SizedBox(width: 8),
            Expanded(child: _sheetField(_amount, 'Amount', number: true)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary, foregroundColor: Colors.white),
                onPressed: () {
                  final amt = double.tryParse(_amount.text.trim()) ?? 0;
                  if (amt <= 0 && (_type == null && _nature.text.trim().isEmpty)) {
                    return;
                  }
                  Navigator.pop(
                    context,
                    SaleOrderOtherExpense(
                      nature: _nature.text.trim(),
                      accounttypeid: _type?.id ?? 0,
                      accounttype: _type?.name ?? '',
                      taxpercent: double.tryParse(_tax.text.trim()) ?? 0,
                      amount: amt,
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
}

// shared sheet text field
Widget _sheetField(TextEditingController c, String hint,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
