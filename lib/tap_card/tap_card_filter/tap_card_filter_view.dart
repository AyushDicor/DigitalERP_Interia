// Tap Card — filter page. Category, company and a saved-on date range.
// Follows the same shape as the Performa Invoice / PO filter screens: the
// dropdown options are derived from the loaded rows, so there's no extra call.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_constant_new.dart';
import '../tap_card_controller.dart';
import '../tap_card_models.dart';
import '../tap_card_utils/tap_card_widgets.dart';

class TapCardFilterView extends StatelessWidget {
  const TapCardFilterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TapCardController>(
      builder: (c) => Scaffold(
        backgroundColor: kTapBg,
        appBar: AppBar(
          backgroundColor: kTapSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: kTapBorder,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: newTextPrimary,
              size: 20,
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: kTapTextPrimary,
                ),
              ),
              Text(
                'Narrow down your cards',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: kTapTextSecondary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                c.resetFilters();
                c.clearDateRange();
              },
              child: const Text(
                'Reset',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTapPrimary,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
          children: [
            _card('Category', Icons.sell_outlined, _categoryChips(c)),
            _card('Company', Icons.business_outlined, _companyChips(c)),
            _card('Saved On', Icons.event_outlined, _dateRange(context, c)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: kTapPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Show ${c.filteredCount} '
                  '${c.filteredCount == 1 ? 'card' : 'cards'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kTapSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kTapBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: kTapPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTapTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _categoryChips(TapCardController c) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: ['', ...TapCardCategory.all].map((opt) {
      final active = c.filterCategory == opt;
      return _chip(
        label: opt.isEmpty ? 'All' : opt,
        active: active,
        color: opt.isEmpty ? kTapPrimary : tapCategoryColor(opt),
        onTap: () => c.setFilterCategory(opt),
      );
    }).toList(),
  );

  Widget _companyChips(TapCardController c) {
    final options = c.companyOptions;
    if (options.isEmpty) {
      return const Text(
        'No companies on your cards yet',
        style: TextStyle(fontSize: 12, color: kTapTextHint),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['', ...options].map((opt) {
        return _chip(
          label: opt.isEmpty ? 'All' : opt,
          active: c.filterCompany == opt,
          color: kTapPrimary,
          onTap: () => c.setFilterCompany(opt),
        );
      }).toList(),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : kTapBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? color : kTapBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? color : kTapTextSecondary,
        ),
      ),
    ),
  );

  Widget _dateRange(BuildContext context, TapCardController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              label: 'All time',
              active: !c.hasDateRange,
              color: kTapPrimary,
              onTap: () => c.clearDateRange(),
            ),
            ...[7, 30, 90, 365].map(
              (days) => _chip(
                label: days == 365 ? 'Last year' : 'Last $days days',
                active: false,
                color: kTapPrimary,
                onTap: () => c.setDateRange(
                  DateTime.now().subtract(Duration(days: days)),
                  DateTime.now(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _dateField(context, 'From', c.fromDate, (d) {
                c.setDateRange(d, c.toDate ?? DateTime.now());
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateField(context, 'To', c.toDate, (d) {
                c.setDateRange(
                  c.fromDate ?? d.subtract(const Duration(days: 30)),
                  d,
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Showing: ${c.dateRangeLabel}',
          style: const TextStyle(fontSize: 11.5, color: kTapTextSecondary),
        ),
      ],
    );
  }

  Widget _dateField(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime(2015),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      );
      if (picked != null) onPicked(picked);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kTapBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kTapBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, size: 15, color: kTapTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value == null
                  ? label
                  : '${value.day.toString().padLeft(2, '0')}/'
                        '${value.month.toString().padLeft(2, '0')}/${value.year}',
              style: TextStyle(
                fontSize: 12.5,
                color: value == null ? kTapTextHint : kTapTextPrimary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
