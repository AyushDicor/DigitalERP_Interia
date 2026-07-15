import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/response/stock_enquiry_godown_resp.dart';
import 'package:newdigitalerp/utils/indian_number.dart';
import 'stock_enquiry_controller.dart';

//  Design tokens
const Color _kBg = Color(0xFFF4F5F9);
const Color _kWhite = Colors.white;
const Color _kText = Color(0xFF0F172A);
const Color _kSub = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE4E7EF);
const Color _kPrimary = Color(0xFF5B6CF6);

/// Godown-wise breakdown for a single item.
class StockEnquiryDetailView extends StatelessWidget {
  final int itemId;
  final String itemTitle;
  const StockEnquiryDetailView(
      {Key? key, required this.itemId, required this.itemTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StockEnquiryDetailController>(
      // unique tag so re-entering a different item builds a fresh controller
      init: StockEnquiryDetailController(itemId, itemTitle),
      tag: 'stock_enq_$itemId',
      builder: (c) => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kWhite,
          elevation: 0.5,
          surfaceTintColor: _kWhite,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _kText, size: 20),
          ),
          title: const Text('Item Stock',
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w700, color: _kText)),
        ),
        body: c.isBusy
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : (c.data == null
                ? const Center(
                    child: Text('No stock details',
                        style: TextStyle(color: _kSub)))
                : _content(c.data!)),
      ),
    );
  }

  Widget _content(StockEnquiryGodownData d) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(d),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Godown-wise Stock',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
            ),
            if ((d.godowns ?? []).isEmpty)
              _emptyGodowns()
            else
              ...d.godowns!.map(_godownRow),
          ],
        ),
      );

  Widget _headerCard(StockEnquiryGodownData d) {
    final total = d.totalstock ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CF6), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.itemname ?? itemTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat('Total Stock',
                  '${_fmt(total)} ${d.unit ?? ''}'.trim()),
              _divider(),
              _headerStat('Rate', _fmt(d.rate ?? 0)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _headerStat('Reorder Level', _fmt(d.reorderlevel ?? 0)),
              _divider(),
              _headerStat('MOQ', _fmt(d.moq ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11.5, color: Colors.white.withValues(alpha: 0.8))),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: Colors.white.withValues(alpha: 0.25),
      );

  Widget _godownRow(GodownStock g) {
    final qty = g.quantity ?? 0;
    final low = qty <= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warehouse_outlined,
                color: _kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(g.godownname ?? '',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
          ),
          Text(_fmt(qty),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: low ? const Color(0xFFDC2626) : _kText)),
        ],
      ),
    );
  }

  Widget _emptyGodowns() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: const Center(
          child: Text('No godown-wise stock',
              style: TextStyle(fontSize: 13, color: _kSub)),
        ),
      );
}

String _fmt(double v) => inrNum(v);
