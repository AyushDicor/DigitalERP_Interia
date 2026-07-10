// Lead Management dashboard — mirrors the web ERP Lead Management screen:
// KPI cards (Total / Open / Closed-Won / Lead Sources), three charts
// (Leads by Status donut, Leads by Source bar, Leads Trend line) and a
// searchable lead list. Data comes from the single /api/lead/dashboard call.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/lead%20management/lead%20management%20controller/lead_management_controller.dart';
import 'package:newdigitalerp/lead%20management/lead_detail_view.dart';
import 'package:newdigitalerp/lead%20management/lead_entry_view.dart';
import 'package:newdigitalerp/lead%20management/lead_filtter_view.dart';
import '../utils/app_constant_new.dart';
import 'lead_list_response.dart';

//  Design tokens
const Color _kPrimary = Color(0xFF4361EE);
const Color _kPrimaryLight = Color(0xFFEEF1FF);
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kCardShadow = Color(0x0A000000);

// Status → colour (matches the web donut legend).
Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'open':
      return const Color(0xFF6366F1); // indigo
    case 'pending':
      return const Color(0xFFF59E0B); // amber
    case 'confirmed':
      return const Color(0xFF10B981); // green
    case 'close':
    case 'closed':
      return const Color(0xFFEF4444); // red
    case 'done':
    case 'won':
      return const Color(0xFF06B6D4); // cyan
    default:
      return const Color(0xFF94A3B8); // slate
  }
}

class LeadManagementView extends StatelessWidget {
  const LeadManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeadManagementController>(
      init: LeadManagementController(),
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
            child: Container(
              margin: const EdgeInsets.all(10),
              // decoration: BoxDecoration(
              //     color: _kBg,
              //     borderRadius: BorderRadius.circular(10),
              //     border: Border.all(color: _kBorder)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kTextPrimary, size: 20),
            ),
          ),
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Lead Management',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                Text('Manage and track your leads',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _kTextSecondary)),
              ]),
          actions: [
            GestureDetector(
              onTap: () => Get.to(() => const LeadFilterScreen()),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            c.startNewLead();
            Get.to(const LeadEntryView());
          },
          backgroundColor: purpleColor,
          elevation: 3,
          shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 2.5)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
        body: RefreshIndicator(
          color: _kPrimary,
          onRefresh: () => c.loadDashboard(),
          child: c.isBusy && c.allLeads.isEmpty
              ? const Center(
                  child:
                      CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  children: [
                    _dateFilter(context, c),
                    const SizedBox(height: 14),
                    _kpiGrid(c),
                    const SizedBox(height: 14),
                    _statusChartCard(c),
                    const SizedBox(height: 14),
                    _sourceChartCard(c),
                    const SizedBox(height: 14),
                    _trendChartCard(c),
                    const SizedBox(height: 18),
                    _searchField(c),
                    const SizedBox(height: 12),
                    _leadListSection(c),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Date range filter ──
  Widget _dateFilter(BuildContext context, LeadManagementController c) {
    Future<void> pick(bool isFrom) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: DateTime(2018),
        lastDate: DateTime(now.year + 2),
      );
      if (picked != null) {
        final s =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        if (isFrom) {
          c.setDateRange(s, c.toDate);
        } else {
          c.setDateRange(c.fromDate, s);
        }
      }
    }

    return _card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.filter_alt_outlined, size: 16, color: _kPrimary),
          SizedBox(width: 6),
          Text('Search Leads',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _dateBox(
                  'From', c.fromDate.isEmpty ? 'dd-mm-yyyy' : c.fromDate,
                  () => pick(true))),
          const SizedBox(width: 10),
          Expanded(
              child: _dateBox('To', c.toDate.isEmpty ? 'dd-mm-yyyy' : c.toDate,
                  () => pick(false))),
        ]),
        if (c.fromDate.isNotEmpty || c.toDate.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: c.clearDateRange,
              icon: const Icon(Icons.clear, size: 14, color: _kTextSecondary),
              label: const Text('Clear',
                  style: TextStyle(fontSize: 12, color: _kTextSecondary)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _dateBox(String label, String value, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder)),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: _kTextSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 9, color: _kTextSecondary)),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary),
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ]),
        ),
      );

  // ── KPI cards (2×2) ──
  Widget _kpiGrid(LeadManagementController c) {
    final kpis = [
      _Kpi('Total Leads', c.totalLeads, Icons.groups_outlined, _kPrimary),
      _Kpi('Open Leads', c.openLeads, Icons.folder_open_outlined,
          const Color(0xFFF59E0B)),
      _Kpi('Closed / Won', c.closedWonLeads, Icons.verified_outlined,
          const Color(0xFF10B981)),
      _Kpi('Lead Sources', c.leadSourceCount, Icons.shuffle_rounded,
          const Color(0xFF8B5CF6)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: kpis.map(_kpiCard).toList(),
    );
  }

  Widget _kpiCard(_Kpi k) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: _kCardShadow, blurRadius: 10, offset: Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(k.label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: _kTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${k.value}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _kTextPrimary)),
                ]),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: k.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(k.icon, color: k.color, size: 20),
          ),
        ]),
      );

  // ── Leads by Status (donut) ──
  Widget _statusChartCard(LeadManagementController c) {
    final data = c.statusCounts;
    final total = data.values.fold<int>(0, (a, b) => a + b);
    return _chartCard(
      title: 'Leads by Status',
      icon: Icons.donut_large_rounded,
      child: data.isEmpty
          ? _noData()
          : Row(children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(alignment: Alignment.center, children: [
                  PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: data.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value.toDouble(),
                        color: _statusColor(e.key),
                        radius: 24,
                        showTitle: false,
                      );
                    }).toList(),
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$total',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kTextPrimary)),
                    const Text('Leads',
                        style:
                            TextStyle(fontSize: 10, color: _kTextSecondary)),
                  ]),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: data.entries
                      .map((e) => _legendRow(
                          _statusColor(e.key), e.key, e.value, total))
                      .toList(),
                ),
              ),
            ]),
    );
  }

  Widget _legendRow(Color color, String label, int value, int total) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _kTextPrimary))),
        Text('$value ($pct%)',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kTextSecondary)),
      ]),
    );
  }

  // ── Leads by Source (bar) ──
  Widget _sourceChartCard(LeadManagementController c) {
    final data = c.sourceCounts.entries.toList();
    final maxV = data.isEmpty
        ? 1.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    return _chartCard(
      title: 'Leads by Source',
      icon: Icons.bar_chart_rounded,
      child: data.isEmpty
          ? _noData()
          : SizedBox(
              height: 180,
              child: BarChart(BarChartData(
                maxY: maxV * 1.25,
                minY: 0,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: _kBorder.withValues(alpha: 0.6), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 9, color: _kTextSecondary)))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: SizedBox(
                                width: 70,
                                child: Text(data[i].key,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: _kTextSecondary)),
                              ),
                            );
                          })),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: data[i].value.toDouble(),
                      width: 26,
                      color: _kPrimary,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]);
                }),
              )),
            ),
    );
  }

  // ── Leads Trend (line) ──
  Widget _trendChartCard(LeadManagementController c) {
    final data = c.trendByDate;
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].value.toDouble())
    ];
    final maxV = data.isEmpty
        ? 1.0
        : data.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();
    return _chartCard(
      title: 'Leads Trend',
      icon: Icons.show_chart_rounded,
      child: data.isEmpty
          ? _noData()
          : SizedBox(
              height: 170,
              child: LineChart(LineChartData(
                minY: 0,
                maxY: maxV * 1.3,
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: _kBorder.withValues(alpha: 0.6), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 9, color: _kTextSecondary)))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval:
                              (data.length / 4).ceil().clamp(1, 999).toDouble(),
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= data.length) {
                              return const SizedBox();
                            }
                            // show short dd-MM
                            final parts = data[i].key.split(RegExp(r'[-/]'));
                            final label = parts.length >= 2
                                ? '${parts[0]}-${parts[1]}'
                                : data[i].key;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(label,
                                  style: const TextStyle(
                                      fontSize: 8, color: _kTextSecondary)),
                            );
                          })),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981).withValues(alpha: 0.18),
                            const Color(0xFF10B981).withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                    ),
                  ),
                ],
              )),
            ),
    );
  }

  // ── Search field ──
  Widget _searchField(LeadManagementController c) => Container(
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder)),
        child: TextField(
          onChanged: c.onSearch,
          style: const TextStyle(fontSize: 14, color: _kTextPrimary),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: _kTextSecondary, size: 20),
            hintText: 'Search leads…',
            hintStyle: TextStyle(color: _kTextSecondary, fontSize: 14),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );

  // ── Lead list ──
  Widget _leadListSection(LeadManagementController c) {
    final leads = c.leadList;
    if (leads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(children: const [
          Icon(Icons.leaderboard_outlined, size: 40, color: Color(0xFFB0B8C8)),
          SizedBox(height: 10),
          Text('No leads found',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary)),
        ]),
      );
    }
    return Column(children: [
      Row(children: [
        Text('Lead Details  (${leads.length})',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary)),
      ]),
      const SizedBox(height: 10),
      ...leads.map((l) => _LeadListCard(item: l, controller: c)),
    ]);
  }

  // ── shared card shells ──
  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: _kCardShadow, blurRadius: 10, offset: Offset(0, 3))
          ],
        ),
        child: child,
      );

  Widget _chartCard(
          {required String title,
          required IconData icon,
          required Widget child}) =>
      _card(
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
          const SizedBox(height: 14),
          child,
        ]),
      );

  Widget _noData() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No data for this range',
              style: TextStyle(fontSize: 12, color: _kTextSecondary)),
        ),
      );
}

class _Kpi {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _Kpi(this.label, this.value, this.icon, this.color);
}

//  Lead list card (compact, mirrors the web "All Leads" list)
class _LeadListCard extends StatelessWidget {
  final LeadData item;
  final LeadManagementController controller;
  const _LeadListCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status ?? '');
    return GestureDetector(
      onTap: () {
        controller.setSelectedLead(item);
        Get.to(() => const LeadDetailView());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(item.companyname ?? 'N/A',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(item.status ?? '-',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ]),
          const SizedBox(height: 10),
          _iconLine(Icons.badge_outlined,
              'Lead #${item.leadnumber ?? '-'}   •   ${item.contactperson ?? '-'}'),
          const SizedBox(height: 5),
          _iconLine(Icons.phone_outlined, item.mobilenumber ?? '-'),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(
                child: _iconLine(Icons.calendar_today_outlined,
                    item.leaddate ?? '-')),
            if ((item.leadsource ?? '').isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _kPrimaryLight,
                    borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.sell_outlined, size: 11, color: _kPrimary),
                  const SizedBox(width: 4),
                  Text(item.leadsource!,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                ]),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _iconLine(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: _kTextSecondary),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12.5, color: _kTextSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ]);
}
