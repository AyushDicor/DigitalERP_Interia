import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/report_models.dart';
import 'package:newdigitalerp/services/api_service/api.dart';

class ReportDetailController extends GetxController {
  final Api api = Api();
  final HomeController home = Get.find<HomeController>();

  int id = 0;
  String title = 'Detail';
  ReportHeader? header;
  List<ReportItem> items = [];
  bool busy = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      id = int.tryParse('${args['id']}') ?? 0;
      title = (args['title'] ?? 'Detail').toString();
    }
    load();
  }

  Future<void> load() async {
    busy = true;
    update();
    try {
      final res = await api.getReportDetailGeneric(<String, String>{
        'id': id.toString(),
        'compid': home.currentUserData?.compId.toString() ?? '',
      });
      if (res.status == 200 && res.data != null) {
        header = res.data!.header;
        items = res.data!.items;
      }
    } catch (_) {} finally {
      busy = false;
      update();
    }
  }
}

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReportDetailController>(
      init: ReportDetailController(),
      builder: (c) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: _text,
          title: Text(c.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: c.busy
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : c.header == null
                ? const Center(child: Text('Not found', style: TextStyle(color: _sub)))
                : ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _headerCard(c.header!),
                      const SizedBox(height: 12),
                      _itemsCard(c.items),
                    ],
                  ),
      ),
    );
  }

  Widget _headerCard(ReportHeader h) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF0F4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Text(h.no ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _text)),
            ),
            if ((h.status ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(h.status!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB7791F))),
              ),
          ]),
          const SizedBox(height: 6),
          Text(h.formtype ?? '', style: const TextStyle(color: _sub, fontSize: 12)),
          const Divider(height: 22),
          _kv('Party', h.party ?? '—'),
          _kv('Date', h.date ?? '—'),
          _kv('Executive', h.executive ?? '—'),
          _kv('Total Qty', '${h.totalqty ?? 0}'),
          _kv('Grand Total', '₹${_amt(h.grandtotal ?? 0)}', strong: true),
        ]),
      );

  Widget _kv(String k, String v, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(color: _sub, fontSize: 13)),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: strong ? _primary : _text,
                    fontSize: 13,
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w600)),
          ),
        ]),
      );

  Widget _itemsCard(List<ReportItem> items) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF0F4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Items (${items.length})',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _sub,
                  letterSpacing: .6)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No items', style: TextStyle(color: _sub, fontSize: 13)),
            )
          else
            ...items.map((it) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Color(0xFFEEF0F4)))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 22,
                          child: Text('${it.sno ?? ''}',
                              style: const TextStyle(color: _sub, fontSize: 12))),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.itemname ?? '',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _text)),
                              if ((it.quantity ?? 0) != 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('Qty: ${it.quantity}',
                                      style: const TextStyle(
                                          fontSize: 11, color: _sub)),
                                ),
                            ]),
                      ),
                      Text('₹${_amt(it.amount ?? 0)}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary)),
                    ],
                  ),
                )),
        ]),
      );

  static String _amt(num v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}
