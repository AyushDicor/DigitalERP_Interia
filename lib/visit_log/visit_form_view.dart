import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/visit_log/visit_controller.dart';

/// Screen 3 — New / Edit Visit. Enquiry link, party/place, purpose, contact,
/// check-in/out, distance, travel mode, GPS capture, a site-measurements grid,
/// and file attachments. Save → visit/save (+ upload files against the id).
class VisitFormView extends StatelessWidget {
  const VisitFormView({super.key});

  static const _bg = Color(0xFFF6F7F9);
  static const _purple = Color(0xFF5B6CF6);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final dtf = DateFormat('dd-MM-yyyy HH:mm');
    final df = DateFormat('dd-MM-yyyy');
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _ink,
        title: GetBuilder<VisitController>(
          builder: (ctrl) => Text(ctrl.editingId > 0 ? 'Edit Visit' : 'New Visit',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      body: GetBuilder<VisitController>(builder: (ctrl) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            _leadDropdown(ctrl),
            Row(children: [
              Expanded(
                  child: _tapField('Visit Date *',
                      ctrl.visitDate == null ? '' : df.format(ctrl.visitDate!),
                      ctrl.pickFormDate)),
              const SizedBox(width: 10),
              Expanded(
                  child: _dd('Status', ctrl.formStatus, ctrl.dd.statuses,
                      (v) => ctrl
                        ..formStatus = v ?? 'Completed'
                        ..update())),
            ]),
            const SizedBox(height: 12),
            _partyField(ctrl),
            const SizedBox(height: 12),
            _field('Visited (party / place / person) *', ctrl.visitToCtrl,
                hint: 'e.g. City Hospital'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _dd('Purpose Type', ctrl.formPurposeType,
                      ctrl.dd.purposeTypes, (v) => ctrl
                        ..formPurposeType = v ?? ''
                        ..update())),
              const SizedBox(width: 10),
              Expanded(child: _field('Location / City', ctrl.locationCtrl)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('Contact Person', ctrl.contactPersonCtrl)),
              const SizedBox(width: 10),
              Expanded(
                  child: _field('Contact No', ctrl.contactNoCtrl,
                      keyboard: TextInputType.phone)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _tapField('Check-in',
                      ctrl.checkIn == null ? '' : dtf.format(ctrl.checkIn!),
                      ctrl.pickCheckIn)),
              const SizedBox(width: 10),
              Expanded(
                  child: _tapField('Check-out',
                      ctrl.checkOut == null ? '' : dtf.format(ctrl.checkOut!),
                      ctrl.pickCheckOut)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _field('Distance (km)', ctrl.distanceCtrl,
                      keyboard: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 10),
              Expanded(
                  child: _dd('Travel Mode', ctrl.formTravelMode,
                      ctrl.dd.travelModes, (v) => ctrl
                        ..formTravelMode = v ?? ''
                        ..update())),
            ]),
            const SizedBox(height: 12),
            _field('Purpose / Details', ctrl.purposeCtrl, lines: 2),
            const SizedBox(height: 12),
            _field('Outcome / Remarks', ctrl.outcomeCtrl, lines: 2),
            const SizedBox(height: 16),
            _gps(ctrl),
            const SizedBox(height: 16),
            _measurements(ctrl),
            const SizedBox(height: 16),
            _attachments(ctrl),
          ],
        );
      }),
      bottomNavigationBar: GetBuilder<VisitController>(
        builder: (ctrl) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: ctrl.saving ? null : ctrl.saveVisit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  disabledBackgroundColor: _purple.withValues(alpha: .5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: ctrl.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 19),
                label: Text(ctrl.saving ? 'Saving…' : 'Save Visit',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Enquiry / Lead ──
  Widget _leadDropdown(VisitController ctrl) {
    // Preserve the current lead even when it isn't in the open-leads list yet:
    // the list loads async (form builds first), and an already-converted
    // enquiry can drop off the list entirely. Without a matching item the
    // DropdownButton asserts, so inject a placeholder so `value` always maps
    // to exactly one item.
    final inList = ctrl.leadId != 0 &&
        ctrl.openLeads.any((l) => l.value == ctrl.leadId);
    final missing = ctrl.leadId != 0 && !inList;
    final missingLabel = ctrl.visitToCtrl.text.trim().isEmpty
        ? 'Enquiry #${ctrl.leadId}'
        : ctrl.visitToCtrl.text.trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('For Enquiry / Lead'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
          color: Colors.white,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            isExpanded: true,
            value: ctrl.leadId == 0 ? null : ctrl.leadId,
            hint: const Text('— Select enquiry —',
                style: TextStyle(fontSize: 13.5, color: _muted)),
            style: const TextStyle(fontSize: 13.5, color: _ink),
            items: [
              const DropdownMenuItem(value: 0, child: Text('— None —')),
              if (missing)
                DropdownMenuItem(value: ctrl.leadId, child: Text(missingLabel)),
              ...ctrl.openLeads.map((l) =>
                  DropdownMenuItem(value: l.value, child: Text(l.text))),
            ],
            onChanged: (v) => ctrl
              ..leadId = v ?? 0
              ..update(),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // ── Party (optional) — searchable picker ──
  Widget _partyField(VisitController ctrl) {
    final has = ctrl.selectedPartyId > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Party (optional)'),
      InkWell(
        onTap: () => _openPartyPicker(ctrl),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Expanded(
              child: Text(has ? ctrl.selectedPartyName : '— Select party —',
                  style: TextStyle(fontSize: 14, color: has ? _ink : _muted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (has)
              InkWell(
                onTap: ctrl.clearParty,
                child: const Icon(Icons.close, size: 18, color: _muted),
              )
            else
              const Icon(Icons.arrow_drop_down, color: _muted),
          ]),
        ),
      ),
    ]);
  }

  void _openPartyPicker(VisitController ctrl) {
    String q = '';
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        final all = ctrl.parties;
        final results = q.isEmpty
            ? all
            : all
                .where((p) => (p.partyname ?? '')
                    .toLowerCase()
                    .contains(q.toLowerCase()))
                .toList();
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(children: [
              const SizedBox(height: 10),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(4))),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setSheet(() => q = v),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search party…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
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
              if (all.isEmpty)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: _border),
                    itemBuilder: (_, i) {
                      final p = results[i];
                      return ListTile(
                        dense: true,
                        title: Text((p.partyname ?? '').trim(),
                            style: const TextStyle(fontSize: 14, color: _ink)),
                        onTap: () {
                          ctrl.selectParty(p);
                          Get.back();
                        },
                      );
                    },
                  ),
                ),
            ]),
          ),
        );
      }),
    );
  }

  // ── GPS ──
  Widget _gps(VisitController ctrl) {
    final has = ctrl.latCtrl.text.isNotEmpty || ctrl.lngCtrl.text.isNotEmpty;
    return Row(children: [
      OutlinedButton.icon(
        onPressed: ctrl.captureGps,
        icon: const Icon(Icons.my_location, size: 18),
        label: const Text('Capture GPS'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _purple,
          side: const BorderSide(color: _border),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          has ? '${ctrl.latCtrl.text}, ${ctrl.lngCtrl.text}' : 'latitude, longitude',
          style: TextStyle(fontSize: 13, color: has ? _ink : _muted),
        ),
      ),
    ]);
  }

  // ── Measurements grid ──
  Widget _measurements(VisitController ctrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.straighten, size: 17, color: _purple),
          const SizedBox(width: 7),
          const Expanded(
            child: Text('Site Measurements',
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
          ),
          TextButton.icon(
            onPressed: ctrl.addMeasurementRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Row'),
            style: TextButton.styleFrom(foregroundColor: _purple),
          ),
        ]),
        if (ctrl.measurements.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('No measurement rows.',
                style: TextStyle(fontSize: 12.5, color: _muted)),
          ),
        for (int i = 0; i < ctrl.measurements.length; i++)
          _measurementRow(ctrl, i),
      ]),
    );
  }

  Widget _measurementRow(VisitController ctrl, int i) {
    final m = ctrl.measurements[i];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Text('Row ${i + 1}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _muted)),
          ),
          InkWell(
            onTap: () => ctrl.removeMeasurementRow(i),
            child: const Icon(Icons.close, size: 18, color: Color(0xFFDC2626)),
          ),
        ]),
        const SizedBox(height: 6),
        _mText('Item', m.itemName, (v) => m.itemName = v),
        const SizedBox(height: 8),
        _mText('Description', m.description, (v) => m.description = v),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _mNum('L', m.length, (v) => m.length = v)),
          const SizedBox(width: 8),
          Expanded(child: _mNum('W', m.width, (v) => m.width = v)),
          const SizedBox(width: 8),
          Expanded(child: _mNum('H', m.height, (v) => m.height = v)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _mNum('Qty', m.qty, (v) => m.qty = v)),
          const SizedBox(width: 8),
          Expanded(child: _mText('Unit', m.unit, (v) => m.unit = v)),
          const SizedBox(width: 8),
          Expanded(child: _mNum('Area', m.area, (v) => m.area = v)),
        ]),
        const SizedBox(height: 8),
        _mText('Remarks', m.remarks, (v) => m.remarks = v),
      ]),
    );
  }

  Widget _mText(String label, String initial, ValueChanged<String> onCh) =>
      TextFormField(
        initialValue: initial,
        onChanged: onCh,
        style: const TextStyle(fontSize: 13.5, color: _ink),
        decoration: _mDecoration(label),
      );

  Widget _mNum(String label, double initial, ValueChanged<double> onCh) =>
      TextFormField(
        initialValue: initial == 0 ? '' : _trim(initial),
        onChanged: (v) => onCh(double.tryParse(v.trim()) ?? 0),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: const TextStyle(fontSize: 13.5, color: _ink),
        decoration: _mDecoration(label),
      );

  InputDecoration _mDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: _muted),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _purple, width: 1.2),
        ),
      );

  // ── Attachments ──
  Widget _attachments(VisitController ctrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.attach_file, size: 17, color: _purple),
          const SizedBox(width: 7),
          const Expanded(
            child: Text('Attachments (optional)',
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink)),
          ),
          TextButton.icon(
            onPressed: ctrl.pickFiles,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Choose files'),
            style: TextButton.styleFrom(foregroundColor: _purple),
          ),
        ]),
        if (ctrl.pickedFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('You can select multiple. Uploaded after save.',
                style: TextStyle(fontSize: 12, color: _muted)),
          ),
        for (int i = 0; i < ctrl.pickedFiles.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Icon(Icons.insert_drive_file_outlined,
                  size: 18, color: _purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(ctrl.pickedFiles[i].name,
                    style: const TextStyle(fontSize: 13, color: _ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              InkWell(
                onTap: () => ctrl.removePickedFile(i),
                child:
                    const Icon(Icons.close, size: 17, color: Color(0xFFDC2626)),
              ),
            ]),
          ),
      ]),
    );
  }

  // ── shared field widgets ──
  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 5),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: _muted)),
      );

  Widget _field(String label, TextEditingController ctrl,
          {String? hint, int lines = 1, TextInputType? keyboard}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        TextField(
          controller: ctrl,
          minLines: lines,
          maxLines: lines,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14, color: _ink),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _muted),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      ]);

  Widget _tapField(String label, String value, VoidCallback onTap) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(children: [
              Expanded(
                child: Text(value.isEmpty ? 'Select' : value,
                    style: TextStyle(
                        fontSize: 14, color: value.isEmpty ? _muted : _ink)),
              ),
              const Icon(Icons.calendar_today_outlined, size: 15, color: _muted),
            ]),
          ),
        ),
      ]);

  Widget _dd(String label, String value, List<String> items,
          ValueChanged<String?> onCh) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value.isEmpty ? null : value,
              hint: const Text('Select',
                  style: TextStyle(fontSize: 13.5, color: _muted)),
              style: const TextStyle(fontSize: 13.5, color: _ink),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onCh,
            ),
          ),
        ),
      ]);

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
