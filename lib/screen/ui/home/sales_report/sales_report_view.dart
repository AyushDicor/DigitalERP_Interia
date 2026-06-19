import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/sales_report_controller.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/order_report_response.dart';

class SalesReportView extends StatelessWidget {
  const SalesReportView({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesReportController>(
      init: SalesReportController(),
      builder: (c) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: _text,
          title: const Text('Sales Report',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            _filterBar(context, c),
            _summaryCard(c),
            Expanded(
              child: c.isBusy
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary))
                  : c.orders.isEmpty
                      ? const Center(
                          child: Text('No orders in this range',
                              style: TextStyle(color: _sub)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: c.orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _orderTile(c.orders[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(BuildContext context, SalesReportController c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(child: _dateField(context, c, true)),
          const SizedBox(width: 10),
          Expanded(child: _dateField(context, c, false)),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: c.loadReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
      BuildContext context, SalesReportController c, bool isFrom) {
    final d = isFrom ? c.fromDate : c.toDate;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: d,
          firstDate: DateTime(2018),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          isFrom ? c.setFromDate(picked) : c.setToDate(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: _sub),
            const SizedBox(width: 6),
            Text(c.fmt(d),
                style: const TextStyle(fontSize: 13, color: _text)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(SalesReportController c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF5B5BD6), Color(0xFF7C7CF0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total Orders', '${c.summary.totalorders}'),
          Container(width: 1, height: 36, color: Colors.white24),
          _summaryItem('Total Amount',
              '₹${_fmtAmount(c.summary.totalamount)}'),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );

  Widget _orderTile(OrderReportItem o) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF0F4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.orderno ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _text, fontSize: 14)),
                const SizedBox(height: 3),
                Text(o.partyname?.isNotEmpty == true ? o.partyname! : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _sub, fontSize: 12)),
                const SizedBox(height: 3),
                Text('${o.orderdate ?? ''}  •  ${o.executivename ?? ''}',
                    style: const TextStyle(color: _sub, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${_fmtAmount(o.amount ?? 0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _primary,
                      fontSize: 14)),
              const SizedBox(height: 4),
              if ((o.orderstatus ?? '').isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(o.orderstatus!,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFB7791F))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtAmount(num v) {
    final s = v.toStringAsFixed(0);
    // simple Indian-ish grouping fallback
    return s.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  }
}
