import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/report_models.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/searchable_dropdown.dart';
import 'package:newdigitalerp/response/get_executive_dropdown_response.dart';
import 'package:newdigitalerp/response/customer_detail_response.dart';
import 'package:newdigitalerp/services/api_service/api.dart';

class ReportListController extends GetxController {
  final Api api = Api();
  final HomeController home = Get.find<HomeController>();

  String reportType = 'sales';
  String title = 'Report';
  List<ReportRow> rows = [];
  ReportSummary summary = ReportSummary();
  bool busy = false;
  late DateTime fromDate;
  late DateTime toDate;

  // ── Dynamic filters (all searchable dropdowns) ──
  List<ExecutiveDropdownData> executives = [];
  List<CustomerListData> parties = [];
  int filterExecId = 0;
  int filterPartyId = 0;
  String filterDocNo = '';

  bool get hasFilter =>
      filterExecId != 0 || filterPartyId != 0 || filterDocNo.isNotEmpty;

  // Document-number options derived from the currently loaded rows.
  List<String> get docOptions {
    final s = <String>{};
    for (final r in rows) {
      if ((r.no ?? '').isNotEmpty) s.add(r.no!);
    }
    final list = s.toList()..sort();
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      reportType = (args['type'] ?? 'sales').toString();
      title = (args['title'] ?? 'Report').toString();
    }
    final now = DateTime.now();
    // Default range = current financial year (Apr–Mar) so it shows everything,
    // matching the web. Narrow via the date pickers / filter as needed.
    final fyStartYear = now.month >= 4 ? now.year : now.year - 1;
    fromDate = DateTime(fyStartYear, 4, 1);
    toDate = now;
    fetchExecutives();
    fetchParties();
    load();
  }

  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  void setFrom(DateTime d) { fromDate = d; update(); }
  void setTo(DateTime d) { toDate = d; update(); }

  void setExecutive(int? id) { filterExecId = id ?? 0; update(); }
  void setParty(int? id) { filterPartyId = id ?? 0; update(); }
  void setDoc(String? no) { filterDocNo = no ?? ''; update(); }

  void clearFilters() {
    filterExecId = 0;
    filterPartyId = 0;
    filterDocNo = '';
    update();
  }

  Future<void> fetchExecutives() async {
    try {
      final res = await api.getExecutiveDropdown(<String, String>{
        'compid': home.currentUserData?.compId.toString() ?? '',
        'userid': home.currentUserData?.userid.toString() ?? '',
      });
      if (res.status == 200) executives = res.data ?? [];
      update();
    } catch (_) {}
  }

  Future<void> fetchParties() async {
    try {
      final res = await api.getPartyWithBranch(<String, String>{
        'userid': home.currentUserData?.userid.toString() ?? '',
        'compid': home.currentUserData?.compId.toString() ?? '',
        'branchid': home.currentUserData?.branchId.toString() ?? '',
        'executiveid': '0',
      });
      if (res.status == 200) parties = res.data ?? [];
      update();
    } catch (_) {}
  }

  Future<void> load() async {
    busy = true;
    update();
    try {
      final res = await api.getReportGeneric(<String, String>{
        'reporttype': reportType,
        'compid': home.currentUserData?.compId.toString() ?? '',
        'branchid': home.currentUserData?.branchId.toString() ?? '',
        'userid': home.currentUserData?.userid.toString() ?? '', // role-based access
        'executiveid': filterExecId.toString(),
        'partyid': filterPartyId.toString(),
        'docsearch': filterDocNo,
        'fromdate': fmt(fromDate),
        'todate': fmt(toDate),
      });
      if (res.status == 200 && res.data != null) {
        rows = res.data!.rows;
        summary = res.data!.summary;
      } else {
        rows = [];
        summary = ReportSummary();
      }
    } catch (_) {
      rows = [];
      summary = ReportSummary();
    } finally {
      busy = false;
      update();
    }
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReportListController>(
      init: ReportListController(),
      builder: (c) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: _text,
          title: Text(c.title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            Stack(alignment: Alignment.center, children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: () => _openFilter(context, c),
              ),
              if (c.hasFilter)
                Positioned(
                  right: 10,
                  top: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                        color: _primary, shape: BoxShape.circle),
                  ),
                ),
            ]),
          ],
        ),
        body: Column(
          children: [
            _filterBar(context, c),
            _summary(c),
            Expanded(
              child: c.busy
                  ? const Center(child: CircularProgressIndicator(color: _primary))
                  : c.rows.isEmpty
                      ? const Center(child: Text('No records in this range',
                          style: TextStyle(color: _sub)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: c.rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _row(c, c.rows[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterBar(BuildContext ctx, ReportListController c) => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          Expanded(child: _dateField(ctx, c, true)),
          const SizedBox(width: 10),
          Expanded(child: _dateField(ctx, c, false)),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: c.load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Apply'),
            ),
          ),
        ]),
      );

  Widget _dateField(BuildContext ctx, ReportListController c, bool isFrom) {
    final d = isFrom ? c.fromDate : c.toDate;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
            context: ctx,
            initialDate: d,
            firstDate: DateTime(2018),
            lastDate: DateTime(2100));
        if (picked != null) isFrom ? c.setFrom(picked) : c.setTo(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: _sub),
          const SizedBox(width: 6),
          Text(c.fmt(d), style: const TextStyle(fontSize: 13, color: _text)),
        ]),
      ),
    );
  }

  Widget _summary(ReportListController c) => Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF5B5BD6), Color(0xFF7C7CF0)]),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _sumItem('Total', '${c.summary.totalcount}'),
          Container(width: 1, height: 36, color: Colors.white24),
          _sumItem('Total Amount', '₹${_amt(c.summary.totalamount)}'),
        ]),
      );

  Widget _sumItem(String l, String v) => Column(children: [
        Text(v,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]);

  Widget _row(ReportListController c, ReportRow r) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(AppRoutes.reportDetail, arguments: {
          'id': r.id,
          'title': r.no ?? c.title,
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF0F4))),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.no ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _text, fontSize: 14)),
                const SizedBox(height: 3),
                Text(r.party?.isNotEmpty == true ? r.party! : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _sub, fontSize: 12)),
                const SizedBox(height: 3),
                Text('${r.date ?? ''}  •  ${r.executive ?? ''}',
                    style: const TextStyle(color: _sub, fontSize: 11)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${_amt(r.amount ?? 0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: _primary, fontSize: 14)),
              if ((r.quantity ?? 0) != 0) ...[
                const SizedBox(height: 2),
                Text('Qty: ${_amt(r.quantity ?? 0)}',
                    style: const TextStyle(color: _sub, fontSize: 11)),
              ],
              const SizedBox(height: 2),
              const Icon(Icons.chevron_right_rounded, color: _sub, size: 18),
            ]),
          ]),
        ),
      );

  static String _amt(num v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

  void _openFilter(BuildContext context, ReportListController c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18),
        child: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Filters',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: _text)),
                TextButton(
                  onPressed: () { c.clearFilters(); setSt(() {}); },
                  child: const Text('Clear'),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Executive',
                  style: TextStyle(fontSize: 12, color: _sub, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SearchableDropdown<int>(
                hint: 'All Executives',
                value: c.filterExecId == 0 ? null : c.filterExecId,
                options: c.executives
                    .where((e) => (e.executiveId ?? 0) != 0)
                    .map((e) => DdOption<int>(e.executiveId ?? 0, e.executiveName ?? ''))
                    .toList(),
                onChanged: (v) { c.setExecutive(v); setSt(() {}); },
              ),
              const SizedBox(height: 14),
              const Text('Party',
                  style: TextStyle(fontSize: 12, color: _sub, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SearchableDropdown<int>(
                hint: 'All Parties',
                value: c.filterPartyId == 0 ? null : c.filterPartyId,
                options: c.parties
                    .where((e) => (e.partyid ?? 0) != 0)
                    .map((e) => DdOption<int>(e.partyid ?? 0, e.partyname ?? ''))
                    .toList(),
                onChanged: (v) { c.setParty(v); setSt(() {}); },
              ),
              const SizedBox(height: 14),
              const Text('Document No',
                  style: TextStyle(fontSize: 12, color: _sub, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SearchableDropdown<String>(
                hint: 'All Documents',
                value: c.filterDocNo.isEmpty ? null : c.filterDocNo,
                options:
                    c.docOptions.map((d) => DdOption<String>(d, d)).toList(),
                onChanged: (v) { c.setDoc(v); setSt(() {}); },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); c.load(); },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _sub, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary)),
      );
}
