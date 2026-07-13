// Performa Invoice (Sale Order) — list page. Stat header + search + dynamic
// filter (auto-populated dropdowns) + record cards. Tapping a card opens the
// read-only detail. Read-only module (Phase 1).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_constant_new.dart';
import '../utils/summary_cards.dart';
import 'sale_order_controller.dart';
import 'sale_order_models.dart';
import 'performa_invoice_filter_view.dart';
import 'performa_invoice_detail_view.dart';
import 'performa_invoice_create_view.dart';

const Color _kPrimary = purpleColor;
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kTextHint = Color(0xFF9CA3AF);

class PerformaInvoiceListView extends StatelessWidget {
  const PerformaInvoiceListView({Key? key}) : super(key: key);

  String _money(double v) {
    final s = v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
    // simple thousands grouping
    final parts = s.split('.');
    final intp = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intp.length; i++) {
      if (i > 0 && (intp.length - i) % 3 == 0) buf.write(',');
      buf.write(intp[i]);
    }
    return buf.toString() + (parts.length > 1 ? '.${parts[1]}' : '');
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SaleOrderController>(
      init: SaleOrderController(),
      builder: (c) => Scaffold(
        backgroundColor: _kBg,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final created = await Get.to(() => const PerformaInvoiceCreateView());
            if (created == true) c.loadList();
          },
          backgroundColor: purpleColor,
          elevation: 3,
          shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 2)),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        appBar: AppBar(
          backgroundColor: _kSurface,
          elevation: 0  ,
          scrolledUnderElevation: 1,
          shadowColor: _kBorder,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: newTextPrimary, size: 20),
          ),
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Performa Invoice',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                Text('Manage and analyze your data',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _kTextSecondary)),
              ]),
          actions: [
            GestureDetector(
              onTap: () => Get.to(() => const PerformaInvoiceFilterView()),
              child: Container(
                margin: const EdgeInsets.only(right: 18),
                width: 40,
                height: 40,
               // padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: purpleLightest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                  Center(
                    child: Icon(Icons.filter_list_sharp,
                        size: 20,
                        color: purpleColor),
                  ),
                  if (c.activeFilterCount > 0) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text('${c.activeFilterCount}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary)),
                  ],
                ]),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          color: _kPrimary,
          onRefresh: () => c.loadList(),
          child: c.isBusy && c.allOrders.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 2.5))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                  children: [
                    _statsRow(c),
                    const SizedBox(height: 14),
                    _searchField(c),
                    const SizedBox(height: 12),
                    if (c.orderList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(children: const [
                            Icon(Icons.receipt_long_outlined,
                                size: 46, color: _kTextHint),
                            SizedBox(height: 10),
                            Text('No records found',
                                style: TextStyle(
                                    fontSize: 13.5, color: _kTextSecondary)),
                          ]),
                        ),
                      )
                    else
                      ...c.orderList.map((o) => _orderCard(c, o)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _statsRow(SaleOrderController c) {
    return SummaryCards([
      SummaryStat('${c.totalRecords}', 'Total', newBlueColor, newBlueLightColor),
      SummaryStat(
          '${c.filteredCount}', 'Filtered', newGreenColor, newGreenLightColor),
    ], padding: EdgeInsets.zero);
  }

  Widget _searchField(SaleOrderController c) => Container(
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder)),
        child: TextField(
          onChanged: c.onSearch,
          style: const TextStyle(fontSize: 14, color: _kTextPrimary),
          decoration: const InputDecoration(
            hintText: 'Search order no, party, buyer…',
            hintStyle: TextStyle(fontSize: 13.5, color: _kTextHint),
            prefixIcon: Icon(Icons.search, size: 20, color: _kTextSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          ),
        ),
      );

  Widget _orderCard(SaleOrderController c, SaleOrderListItem o) {
    return GestureDetector(
      onTap: () {
        c.loadDetail(o.mainid);
        Get.to(() => const PerformaInvoiceDetailView());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(o.orderno.isEmpty ? '(no order no)' : o.orderno,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _kBg, borderRadius: BorderRadius.circular(6)),
              child: Text('#${o.mainid}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kTextSecondary)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(o.partyname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary)),
          const SizedBox(height: 10),
          Row(children: [
            _meta(Icons.person_outline_rounded, o.createdby),
            const SizedBox(width: 14),
            _meta(Icons.event_outlined, o.createdate),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GRAND TOTAL',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text('${_money(o.grandtotal)}  ',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Qty ${o.totalqty.toStringAsFixed(o.totalqty == o.totalqty.roundToDouble() ? 0 : 2)}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTextSecondary)),
              const SizedBox(height: 3),
              Text(o.currency,
                  style: const TextStyle(fontSize: 11, color: _kTextHint)),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Expanded(
        child: Row(children: [
          Icon(icon, size: 13, color: _kTextSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Text(text.isEmpty ? '-' : text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: _kTextSecondary)),
          ),
        ]),
      );
}
