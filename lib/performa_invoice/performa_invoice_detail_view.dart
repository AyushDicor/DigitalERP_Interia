// Performa Invoice (Sale Order) — read-only detail. Mirrors the ERP form
// sections: Main Details, Other Details, Party Details, Item Details, Totals,
// and Terms & Condition.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sale_order_controller.dart';
import 'sale_order_models.dart';

const Color _kPrimary = Color(0xFF7C3AED);
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kTextHint = Color(0xFF9CA3AF);

class PerformaInvoiceDetailView extends StatelessWidget {
  const PerformaInvoiceDetailView({Key? key}) : super(key: key);

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleOrderController>(
      builder: (c) {
        final h = c.selectedHeader;
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
                  const Text('Performa Invoice',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary)),
                  Text(h?.orderno ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: _kTextSecondary)),
                ]),
          ),
          body: c.detailBusy
              ? const Center(
                  child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 2.5))
              : h == null
                  ? const Center(
                      child: Text('No detail available',
                          style: TextStyle(color: _kTextSecondary)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                      child: Column(children: [
                        _summaryCard(h),
                        const SizedBox(height: 14),
                        _mainCard(h),
                        const SizedBox(height: 14),
                        _otherCard(h),
                        const SizedBox(height: 14),
                        _partyCard(h),
                        const SizedBox(height: 14),
                        _itemsCard(c.selectedItems),
                        const SizedBox(height: 14),
                        _totalsCard(h),
                        if (h.terms.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _termsCard(h),
                        ],
                        const SizedBox(height: 20),
                      ]),
                    ),
        );
      },
    );
  }

  Widget _summaryCard(SaleOrderHeader h) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [_kPrimary, _kPrimary.withValues(alpha: 0.82)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(h.orderno,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(h.partyname,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.92))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _summaryMetric('GRAND TOTAL', _num(h.grandtotal))),
            Container(width: 1, height: 30, color: Colors.white24),
            Expanded(child: _summaryMetric('TOTAL QTY', _num(h.totalqty))),
            Container(width: 1, height: 30, color: Colors.white24),
            Expanded(child: _summaryMetric('SERIES', h.series)),
          ]),
        ]),
      );

  Widget _summaryMetric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(label,
                style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.4)),
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ],
      );

  Widget _mainCard(SaleOrderHeader h) =>
      _card('Main Details', Icons.article_outlined, [
        _row('Entry Type', h.entrytype),
        _row('Series', h.series),
        _row('Order No', h.orderno),
        _row('Order Date', h.orderdate),
        _row('Delivery Date', h.deliverydate),
        _row('Party Name', h.partyname),
        _row('Customer Order No', h.buyerorderno),
        _row('Order Type', h.ordertype),
        _row('Order Priority', h.orderpriority),
        _row('Created By', h.createdby),
        _row('Created On', h.createdate),
        _row('Remark', h.orderremarks, last: true),
      ]);

  Widget _otherCard(SaleOrderHeader h) =>
      _card('Other Details', Icons.local_shipping_outlined, [
        _row('Delivery Place', h.deliveryplace),
        _row('Delivery Type', h.deliverytype),
        _row('Dispatch Through', h.dispatchthrough),
        _row('Destination', h.destination),
        _row('Currency', h.currency, last: true),
      ]);

  Widget _partyCard(SaleOrderHeader h) =>
      _card('Party Details', Icons.contact_page_outlined, [
        _row('Bill To Address', h.billtoaddress),
        _row('Ship To Address', h.shiptoaddress),
        _row('GST No', h.gstno),
        _row('Mobile No', h.mobileno, last: true),
      ]);

  Widget _itemsCard(List<SaleOrderItem> items) =>
      _card('Item Details', Icons.inventory_2_outlined, [
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No items',
                style: TextStyle(fontSize: 12.5, color: _kTextSecondary)),
          )
        else
          ...items.asMap().entries.map((e) {
            final it = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: _kPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: _kPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(it.itemname,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _kTextPrimary)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _chip('Qty ${_num(it.quantity)} ${it.unit}'),
                      _chip('Rate ${_num(it.salerate)}'),
                      if (it.itemsize.isNotEmpty) _chip('Size ${it.itemsize}'),
                    ]),
                    const SizedBox(height: 6),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GST ${_num(it.gstpercent)}%  ·  ${_num(it.gstamount)}',
                              style: const TextStyle(
                                  fontSize: 11, color: _kTextSecondary)),
                          Text(_num(it.amount),
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextPrimary)),
                        ]),
                  ]),
            );
          }),
      ]);

  Widget _totalsCard(SaleOrderHeader h) {
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
      r('Total Qty', _num(h.totalqty)),
      r('Total Amount', _num(h.totalamount)),
      r('Total GST', _num(h.totalgst)),
      r('Round Off', _num(h.roundoff)),
      const Divider(height: 16, color: _kBorder),
      r('Grand Total', '${_num(h.grandtotal)}  ${h.currency}', bold: true),
    ]);
  }

  Widget _termsCard(SaleOrderHeader h) =>
      _card('Terms & Condition', Icons.description_outlined, [
        Text(h.terms.trim(),
            style: const TextStyle(
                fontSize: 12.5, height: 1.5, color: _kTextSecondary)),
      ]);

  // ── helpers ──
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

  Widget _row(String label, String value, {bool last = false}) {
    final v = value.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(v.isEmpty ? '-' : v,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: v.isEmpty ? _kTextHint : _kTextPrimary)),
        ),
      ]),
    );
  }

  Widget _chip(String text) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kBorder)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary)),
      );
}
