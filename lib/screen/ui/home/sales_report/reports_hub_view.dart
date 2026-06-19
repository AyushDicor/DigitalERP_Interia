import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';

/// MIS / Reports hub — lists all available reports. Add new reports to [_reports].
class ReportsHubView extends StatelessWidget {
  const ReportsHubView({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  // Registry of reports. To add a new report, just add an entry here — it opens the
  // generic ReportScreen with the given `type` (maps to a TransMaster FormType on the API).
  static final List<_Report> _reports = [
    _Report('Sales Report', 'Order-wise sales with date filter & total',
        Icons.bar_chart_rounded, Color(0xFF5B5BD6), 'sales'),
    _Report('Purchase Order Report', 'PO-wise totals with date filter',
        Icons.shopping_cart_outlined, Color(0xFF0EA5E9), 'po'),
    _Report('MRN Report', 'Material receipts with date filter',
        Icons.inventory_2_outlined, Color(0xFF16A34A), 'mrn'),
    _Report('Indent Report', 'Indent-wise list with date filter',
        Icons.assignment_outlined, Color(0xFFF59E0B), 'indent'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _text,
        title: const Text('MIS / Reports',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _reports.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = _reports[i];
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Get.toNamed(AppRoutes.reportScreen,
                arguments: {'type': r.type, 'title': r.title}),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEF0F4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: r.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(r.icon, color: r.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _text)),
                        const SizedBox(height: 3),
                        Text(r.subtitle,
                            style: const TextStyle(fontSize: 12, color: _sub)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _sub),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Report {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String type; // report type -> generic ReportScreen
  const _Report(this.title, this.subtitle, this.icon, this.color, this.type);
}
