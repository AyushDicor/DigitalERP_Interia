// Performa Invoice filter — searchable dropdowns whose options auto-populate
// from the loaded records (party / created by / currency / series). Selecting
// a value filters the list live; Reset clears all.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'sale_order_controller.dart';

const Color _kPrimary = purpleColor;
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kTextHint = Color(0xFF9CA3AF);

class PerformaInvoiceFilterView extends StatelessWidget {
  const PerformaInvoiceFilterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleOrderController>(
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
              const Text('Advanced Filters',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary)),
              Text(
                  c.activeFilterCount == 0
                      ? '${c.filteredCount} of ${c.totalRecords} records'
                      : '${c.activeFilterCount} filter(s) · ${c.filteredCount} of ${c.totalRecords}',
                  style: const TextStyle(fontSize: 11, color: _kTextSecondary)),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _dateRangeCard(context, c),
                  const SizedBox(height: 16),
                  _card('Filter Options', Icons.filter_list_rounded, [
                  _filterTile(context,
                      label: 'Party Name',
                      icon: Icons.business_outlined,
                      value: c.filterParty,
                      options: c.partyOptions,
                      onPicked: c.setFilterParty),
                  const SizedBox(height: 14),
                  _filterTile(context,
                      label: 'Created By',
                      icon: Icons.person_outline_rounded,
                      value: c.filterCreatedBy,
                      options: c.createdByOptions,
                      onPicked: c.setFilterCreatedBy),
                  const SizedBox(height: 14),
                  _filterTile(context,
                      label: 'Series',
                      icon: Icons.tag_rounded,
                      value: c.filterSeries,
                      options: c.seriesOptions,
                      onPicked: c.setFilterSeries),
                  const SizedBox(height: 14),
                  _filterTile(context,
                      label: 'Currency',
                      icon: Icons.currency_rupee_rounded,
                      value: c.filterCurrency,
                      options: c.currencyOptions,
                      onPicked: c.setFilterCurrency),
                  ]),
                ]),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: _kSurface,
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: (c.activeFilterCount == 0 &&
                              c.isDefaultDateRange)
                          ? null
                          : () async {
                              c.resetFilters();
                              if (!c.isDefaultDateRange) {
                                await c.resetDateRange();
                              }
                            },
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Reset',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kTextSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        side: const BorderSide(color: _kBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                        label: Text(
                          c.activeFilterCount == 0
                              ? 'Show All'
                              : 'Show ${c.filteredCount} Result(s)',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Server-side window. The list loads the last 30 days by default; widening the
  // range re-queries the API, so this is how you reach older records.
  Widget _dateRangeCard(BuildContext context, SaleOrderController c) =>
      _card('Date Range', Icons.event_outlined, [
        Row(children: [
          Expanded(
              child: _dateTile(context, c, 'From', c.fromDate, isFrom: true)),
          const SizedBox(width: 12),
          Expanded(
              child: _dateTile(context, c, 'To', c.toDate, isFrom: false)),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _preset(c, 'Last 30 Days', 30),
            _preset(c, 'Last 90 Days', 90),
            _preset(c, 'Last 6 Months', 182),
            _preset(c, 'Last 1 Year', 365),
            _preset(c, 'Last 2 Years', 730),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          if (c.isBusy)
            const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
          else
            const Icon(Icons.info_outline_rounded,
                size: 13, color: _kTextSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              c.isBusy
                  ? 'Loading ${c.dateRangeLabel}…'
                  : 'Showing ${c.totalRecords} record(s) for ${c.dateRangeLabel}',
              style: const TextStyle(fontSize: 11, color: _kTextSecondary),
            ),
          ),
        ]),
      ]);

  Widget _preset(SaleOrderController c, String label, int days) {
    final now = DateTime.now();
    final diff = c.toDate.difference(c.fromDate).inDays.abs();
    final selected = !c.isBusy && (diff - days).abs() <= 1;
    return GestureDetector(
      onTap: c.isBusy
          ? null
          : () => c.setDateRange(now.subtract(Duration(days: days)), now),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _kPrimary.withValues(alpha: 0.12) : _kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _kPrimary : _kBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: selected ? _kPrimary : _kTextSecondary)),
      ),
    );
  }

  Widget _dateTile(BuildContext context, SaleOrderController c, String label,
      DateTime value,
      {required bool isFrom}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2015),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme:
                    const ColorScheme.light(primary: _kPrimary)),
            child: child!,
          ),
        );
        if (picked == null) return;
        // Keep the range ordered no matter which end was edited.
        if (isFrom) {
          await c.setDateRange(picked, picked.isAfter(c.toDate) ? picked : c.toDate);
        } else {
          await c.setDateRange(picked.isBefore(c.fromDate) ? picked : c.fromDate, picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: _kTextSecondary)),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: _kTextSecondary),
            const SizedBox(width: 6),
            Text(
                '${value.day.toString().padLeft(2, '0')}/'
                '${value.month.toString().padLeft(2, '0')}/${value.year}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary)),
          ]),
        ]),
      ),
    );
  }

  Widget _filterTile(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onPicked,
  }) {
    final bool hasValue = value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 13, color: _kTextSecondary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                  letterSpacing: 0.4)),
          const Spacer(),
          Text('${options.length} option(s)',
              style: const TextStyle(fontSize: 10.5, color: _kTextHint)),
        ]),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: options.isEmpty
              ? null
              : () async {
                  final picked = await showModalBottomSheet<String>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _OptionPickerSheet(
                        title: label, options: options, selected: value),
                  );
                  if (picked != null) onPicked(picked);
                },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: hasValue ? _kPrimary.withValues(alpha: 0.06) : _kSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hasValue ? _kPrimary : _kBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Expanded(
                child: Text(
                  hasValue
                      ? value
                      : (options.isEmpty ? 'No values' : 'Select $label'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    color: hasValue ? _kTextPrimary : _kTextHint,
                  ),
                ),
              ),
              if (hasValue)
                GestureDetector(
                  onTap: () => onPicked(''),
                  child:
                      const Icon(Icons.close_rounded, size: 18, color: _kPrimary),
                )
              else
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _kTextSecondary, size: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: purpleLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kPrimary, size: 17),

              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary)),
            ]),
          ),
          const Divider(height: 1, color: _kBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(children: children),
          ),
        ]),
      );
}

class _OptionPickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String selected;
  const _OptionPickerSheet(
      {required this.title, required this.options, required this.selected});

  @override
  State<_OptionPickerSheet> createState() => _OptionPickerSheetState();
}

class _OptionPickerSheetState extends State<_OptionPickerSheet> {
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
        : widget.options.where((o) => o.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: _kBorder, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Text('Select ${widget.title}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context, ''),
              child: const Text('Clear',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary)),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search ${widget.title.toLowerCase()}…',
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
                maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No matches',
                        style: TextStyle(color: _kTextSecondary)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _kBorder),
                    itemBuilder: (_, i) {
                      final o = list[i];
                      final sel = o == widget.selected;
                      return ListTile(
                        dense: true,
                        title: Text(o,
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w500,
                                color: sel ? _kPrimary : _kTextPrimary)),
                        trailing: sel
                            ? const Icon(Icons.check_circle_rounded,
                                size: 18, color: _kPrimary)
                            : null,
                        onTap: () => Navigator.pop(context, o),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
