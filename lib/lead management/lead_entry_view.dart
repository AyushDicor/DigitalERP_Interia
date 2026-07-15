// Lead Entry (create) form — mirrors the web ERP Lead Entry:
// Lead Information + Item Details + Company Details, with Company Type
// (Direct / Existing), auto-fill from an existing party, and "type or pick"
// dropdowns whose typed values become reusable options next time.

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/indian_number.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/lead%20management/lead%20management%20controller/lead_management_controller.dart';
import 'package:newdigitalerp/utils/date_widget.dart';
import 'lead_form_models.dart';

const Color _kPrimary = Color(0xFF4361EE);
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kHint = Color(0xFFB0B8C8);

class LeadEntryView extends StatefulWidget {
  const LeadEntryView({Key? key}) : super(key: key);
  @override
  State<LeadEntryView> createState() => _LeadEntryViewState();
}

class _LeadEntryViewState extends State<LeadEntryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = Get.find<LeadManagementController>();
      // Edit mode preloads dropdowns; only load here when not already loaded.
      if (c.itemMaster.isEmpty) c.loadFormData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeadManagementController>(
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
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.isEditing ? 'Edit Lead' : 'Lead Entry',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                Text(c.isEditing ? 'Update lead details' : 'Create a new lead',
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSecondary)),
              ]),
        ),
        body: c.formLoading
            ? const Center(
                child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5))
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                    left: 14,
                    right: 14,
                    top: 14,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 30),
                child: Column(children: [
                  _leadInfoSection(context, c),
                  const SizedBox(height: 14),
                  _companySection(context, c),
                  const SizedBox(height: 14),
                  _itemSection(context, c),
                  const SizedBox(height: 20),
                  _actions(c),
                  const SizedBox(height: 24),
                ]),
              ),
      ),
    );
  }

  // ── Lead Information ──
  Widget _leadInfoSection(BuildContext ctx, LeadManagementController c) {
    return _card('Lead Information', Icons.info_outline_rounded, [
      _label('Lead Date'),
      AppDateWidgetNew(value: c.selectDate, onSelectDate: c.setSelectedDate),
      _pick(ctx, c, 'Lead Source', 'leadSource', c.formData.leadSource),
      _pick(ctx, c, 'Lead Category', 'leadCategory', c.formData.leadCategory),
      _pick(ctx, c, 'Lead Priority', 'leadPriority', c.formData.leadPriority),
      _pick(ctx, c, 'Lead Status', 'leadStatus', c.formData.leadStatus),
      _pick(ctx, c, 'Assign To', 'assignTo', c.formData.assignTo,
          allowCustom: false),
      _text('Requirement / Specification', c.requirementController, maxLines: 2),
      _text('Project Name', c.projectNameController),
      Row(children: [
        Expanded(child: _text('Budget', c.budgetController, number: true)),
        const SizedBox(width: 10),
        Expanded(child: _text('Approx Amount', c.approxAmtController, number: true)),
      ]),
      Row(children: [
        Expanded(child: _text('Ref No', c.refNoController)),
        const SizedBox(width: 10),
        Expanded(child: _text('Reffer By', c.refferByController)),
      ]),
      _text('Other Remarks', c.otherRemarksController, maxLines: 2),
    ]);
  }

  // ── Company Details ──
  Widget _companySection(BuildContext ctx, LeadManagementController c) {
    final isExisting = c.companyTypeId == 2;
    return _card('Company Details', Icons.business_outlined, [
      _label('Company Type'),
      Row(children: [
        _typeChip('Direct', c.companyTypeId == 1, () => c.setCompanyType(1)),
        const SizedBox(width: 10),
        _typeChip('Existing', c.companyTypeId == 2, () => c.setCompanyType(2)),
      ]),
      const SizedBox(height: 4),
      if (isExisting)
        _pickField('Company Name *', c.companyNameController.text, () {
          _openPicker(ctx, 'Select Company', c.existingCompanies,
              allowCustom: false, onPick: (id, name) {
            c.onSelectExistingCompany(LeadOption(id, name));
          });
        })
      else
        _text('Company Name *', c.companyNameController),
      _text('Contact Person', c.contactPersonController),
      _pick(ctx, c, 'Designation', 'designation', c.formData.designation),
      _text('Owner Name', c.ownerNameController),
      Row(children: [
        Expanded(child: _text('Mobile No', c.mobileNumberController, number: true)),
        const SizedBox(width: 10),
        Expanded(
            child: _text('Alt. Mobile', c.alternateNumberController, number: true)),
      ]),
      Row(children: [
        Expanded(child: _text('Phone No', c.phoneNumberController, number: true)),
        const SizedBox(width: 10),
        Expanded(child: _text('WhatsApp No', c.whatsappController, number: true)),
      ]),
      _text('Email ID', c.emailController),
      _text('Website', c.websiteController),
      _text('Company Address', c.companyAddressController, maxLines: 2),
      Row(children: [
        Expanded(child: _text('Pincode', c.pincodeController, number: true)),
        const SizedBox(width: 10),
        Expanded(child: _text('GST No', c.gstController)),
      ]),
      _text('Area', c.areaController),
      _pick(ctx, c, 'Business Nature', 'businessNatureOpt', const [],
          controllerText: c.businessNatureController),
      _pick(ctx, c, 'Market Segment', 'marketSegment', c.formData.marketSegment),
      _pick(ctx, c, 'Industry Type', 'industryType', c.formData.industryType),
    ]);
  }

  // ── Item Details ──
  Widget _itemSection(BuildContext ctx, LeadManagementController c) {
    return _card('Item Details', Icons.inventory_2_outlined, [
      Row(children: [
        const Expanded(
          child: Text('Items added to this lead',
              style: TextStyle(fontSize: 12, color: _kTextSecondary)),
        ),
        GestureDetector(
          onTap: () => _openAddItem(ctx, c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
                color: _kPrimary, borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Add Item',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      if (c.itemLines.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text('No items added',
                style: TextStyle(fontSize: 12, color: _kTextSecondary)),
          ),
        )
      else ...[
        ...c.itemLines.asMap().entries.map((e) {
          final i = e.key;
          final it = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
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
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kTextPrimary)),
                      const SizedBox(height: 2),
                      Text(
                          'Qty ${_n(it.quantity)} ${it.billingunit}  ·  Rate ${_n(it.saleprice)}  ·  Amt ${_n(it.amount)}',
                          style: const TextStyle(
                              fontSize: 11, color: _kTextSecondary)),
                    ]),
              ),
              GestureDetector(
                onTap: () => c.removeItemLine(i),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444), size: 20),
              ),
            ]),
          );
        }),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('Total Qty ${_n(c.itemsTotalQty)}   ·   Total ${_n(c.itemsTotalAmount)}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
        ]),
      ],
    ]);
  }

  Widget _actions(LeadManagementController c) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: c.saving ? null : () => c.saveLeadEntry(),
        icon: c.saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline, size: 18),
        label: Text(
            c.saving
                ? 'Saving…'
                : (c.isEditing ? 'Update Lead' : 'Create Lead'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  // ══════════════ reusable widgets ══════════════
  Widget _card(String title, IconData icon, List<Widget> children) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
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
          const SizedBox(height: 6),
          ...children,
        ]),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary)),
      );

  Widget _text(String label, TextEditingController controller,
      {bool number = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        inputFormatters:
            number ? [FilteringTextInputFormatter.digitsOnly] : null,
        maxLines: maxLines,
        style: const TextStyle(
            fontSize: 14, color: _kTextPrimary, fontWeight: FontWeight.w500),
        decoration: _dec(label),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _kTextSecondary),
        floatingLabelStyle: const TextStyle(
            fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: _kBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kPrimary, width: 1.6)),
      );

  // A tappable field that shows a value and opens a picker.
  Widget _pickField(String label, String value, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder)),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 11, color: _kTextSecondary)),
                      const SizedBox(height: 2),
                      Text(value.isEmpty ? 'Select' : value,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: value.isEmpty ? _kHint : _kTextPrimary)),
                    ]),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: _kTextSecondary),
            ]),
          ),
        ),
      );

  // Type-or-pick dropdown: pick an option, or type a new value (id=0).
  // `controllerText` (optional) lets a plain text controller back it (Business Nature).
  Widget _pick(BuildContext ctx, LeadManagementController c, String label,
      String field, List<LeadOption> options,
      {bool allowCustom = true, TextEditingController? controllerText}) {
    final current = controllerText != null
        ? controllerText.text
        : (c.selName[field] ?? '');
    return _pickField(label, current, () {
      _openPicker(ctx, label, options, allowCustom: allowCustom,
          onPick: (id, name) {
        if (controllerText != null) {
          controllerText.text = name;
          c.update();
        } else {
          c.setOption(field, id, name);
        }
      });
    });
  }

  Widget _typeChip(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? _kPrimary : _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? _kPrimary : _kBorder),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _kTextSecondary)),
          ),
        ),
      );

  static String _n(double v) => inrNum(v);

  // ── modal pickers ──
  void _openPicker(BuildContext ctx, String title, List<LeadOption> options,
      {required bool allowCustom,
      required void Function(int id, String name) onPick}) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (c2, setSt) {
        final q = searchCtrl.text.toLowerCase();
        final filtered = q.isEmpty
            ? options
            : options
                .where((o) => o.name.toLowerCase().contains(q))
                .toList();
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(c2).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(c2).size.height * 0.7,
            child: Column(children: [
              const SizedBox(height: 10),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(c2),
                    child: const Icon(Icons.close, color: _kTextSecondary),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (_) => setSt(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintText: allowCustom
                        ? 'Search or type a new value…'
                        : 'Search…',
                    filled: true,
                    fillColor: _kBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(children: [
                  if (allowCustom && searchCtrl.text.trim().isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline,
                          color: _kPrimary),
                      title: Text('Add "${searchCtrl.text.trim()}"',
                          style: const TextStyle(
                              color: _kPrimary,
                              fontWeight: FontWeight.w600)),
                      onTap: () {
                        onPick(0, searchCtrl.text.trim());
                        Navigator.pop(c2);
                      },
                    ),
                  ...filtered.map((o) => ListTile(
                        title: Text(o.name,
                            style: const TextStyle(
                                fontSize: 14, color: _kTextPrimary)),
                        onTap: () {
                          onPick(o.id, o.name);
                          Navigator.pop(c2);
                        },
                      )),
                ]),
              ),
            ]),
          ),
        );
      }),
    );
  }

  void _openAddItem(BuildContext ctx, LeadManagementController c) {
    LeadOption? item;
    final qty = TextEditingController();
    final rate = TextEditingController();
    final unit = TextEditingController();
    final size = TextEditingController();
    final weight = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (c2, setSt) {
        Widget f(String l, TextEditingController ctl, {bool num = false}) =>
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: ctl,
                keyboardType: num ? TextInputType.number : TextInputType.text,
                decoration: _dec(l),
              ),
            );
        return Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(c2).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(
                child: Text('Add Item',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(c2),
                child: const Icon(Icons.close, color: _kTextSecondary),
              ),
            ]),
            _pickField('Item *', item?.name ?? '', () {
              _openPicker(c2, 'Select Item', c.itemMaster,
                  allowCustom: true, onPick: (id, name) {
                setSt(() => item = LeadOption(id, name));
              });
            }),
            Row(children: [
              Expanded(child: f('Qty *', qty, num: true)),
              const SizedBox(width: 10),
              Expanded(child: f('Rate', rate, num: true)),
            ]),
            Row(children: [
              Expanded(child: f('Unit', unit)),
              const SizedBox(width: 10),
              Expanded(child: f('Size', size)),
            ]),
            f('Weight', weight),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  if (item == null || qty.text.trim().isEmpty) {
                    Get.snackbar('Required', 'Pick an item and enter quantity',
                        snackPosition: SnackPosition.BOTTOM);
                    return;
                  }
                  c.addItemLine(LeadItemLine(
                    itemid: item!.id,
                    itemname: item!.name,
                    quantity: double.tryParse(qty.text.trim()) ?? 0,
                    saleprice: double.tryParse(rate.text.trim()) ?? 0,
                    mrp: double.tryParse(rate.text.trim()) ?? 0,
                    billingunit: unit.text.trim(),
                    sizename: size.text.trim(),
                    weightname: weight.text.trim(),
                  ));
                  Navigator.pop(c2);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Add',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        );
      }),
    );
  }
}
