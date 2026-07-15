import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/response/stcok_category_data_response.dart';
import 'package:newdigitalerp/response/stock_enquiry_item_resp.dart';
import 'package:newdigitalerp/utils/indian_number.dart';
import 'stock_enquiry_controller.dart';
import 'stock_enquiry_detail_view.dart';

//  Design tokens
const Color _kBg = Color(0xFFF4F5F9);
const Color _kWhite = Colors.white;
const Color _kText = Color(0xFF0F172A);
const Color _kSub = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE4E7EF);
const Color _kPrimary = Color(0xFF5B6CF6);

/// Item-first stock lookup: search / filter items, see total stock, tap for
/// a godown-wise breakdown.
class StockEnquiryView extends StatelessWidget {
  const StockEnquiryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StockEnquiryController>(
      init: StockEnquiryController(),
      builder: (c) => Scaffold(
        backgroundColor: _kBg,
        appBar: _appBar('Stock / Item Enquiry'),
        body: Column(
          children: [
            _filterBar(c),
            Expanded(
              child: c.isBusy
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary))
                  : (c.items.isEmpty
                      ? _empty(c.hasSearched)
                      : _resultList(c)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(StockEnquiryController c) => Container(
        color: _kWhite,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: c.searchCtr,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => c.getItems(),
              decoration: InputDecoration(
                hintText: 'Search item name or code',
                hintStyle: const TextStyle(fontSize: 14, color: _kSub),
                prefixIcon: const Icon(Icons.search_rounded, color: _kSub),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: _kPrimary),
                  tooltip: 'Search',
                  onPressed: c.getItems,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: _kBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _categoryDropdown(c)),
                if (c.selectedCategory != null || c.searchCtr.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                      onPressed: c.clearFilters,
                      style: TextButton.styleFrom(
                        foregroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _categoryDropdown(StockEnquiryController c) => Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<StockCategoryList>(
            isExpanded: true,
            value: c.selectedCategory,
            hint: const Text('All Categories',
                style: TextStyle(fontSize: 14, color: _kSub)),
            iconStyleData: const IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: _kSub),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 320,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), color: _kWhite),
            ),
            items: c.categoryList
                .map((cat) => DropdownMenuItem<StockCategoryList>(
                      value: cat,
                      child: Text(cat.categoryname ?? '',
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 14, color: _kText)),
                    ))
                .toList(),
            onChanged: c.setCategory,
          ),
        ),
      );

  Widget _resultList(StockEnquiryController c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('${c.items.length} item(s) in stock',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _kSub)),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
              itemCount: c.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _itemCard(c.items[i]),
            ),
          ),
        ],
      );

  Widget _itemCard(StockEnquiryItem item) {
    final qty = item.quantity ?? 0;
    final low = qty <= 0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Get.to(() => StockEnquiryDetailView(
            itemId: item.itemid ?? 0,
            itemTitle: item.itemname ?? '',
          )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemname ?? '',
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  if ((item.category ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.category!,
                        style: const TextStyle(fontSize: 12, color: _kSub)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(qty),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: low ? const Color(0xFFDC2626) : _kPrimary)),
                Text(item.unit ?? '',
                    style: const TextStyle(fontSize: 11.5, color: _kSub)),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSub),
          ],
        ),
      ),
    );
  }

  Widget _empty(bool searched) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: _kSub),
            const SizedBox(height: 12),
            Text(searched ? 'No items with stock found' : 'Loading…',
                style: const TextStyle(fontSize: 14, color: _kSub)),
          ],
        ),
      );
}

//  shared
AppBar _appBar(String title) => AppBar(
      backgroundColor: _kWhite,
      elevation: 0.5,
      surfaceTintColor: _kWhite,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _kText, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w700, color: _kText)),
    );

String _fmt(double v) => inrNum(v);
