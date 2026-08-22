import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/repo/mis_repo.dart';
import 'package:newdigitalerp/utils/app_assets.dart';
import 'package:newdigitalerp/utils/indian_number.dart';

import 'mis_report_controller.dart';

/// Renders ANY MIS report. Nothing here knows what a sale order or an indent
/// is — the server sends the KPI cards, the charts and the grid columns, and
/// this screen draws whatever arrives. A report added on the web shows up here
/// with no app change.
class MisReportView extends StatelessWidget {
  const MisReportView({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);
  static const _line = Color(0xFFEEF0F4);
  /// Excel's own green, so the export action is recognisable at a glance.
  static const _excel = Color(0xFF1D6F42);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MisReportController>(
      init: MisReportController(),
      builder: (c) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          foregroundColor: _text,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.report.reportName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (c.report.formName.isNotEmpty)
                Text(c.report.formName,
                    style: const TextStyle(fontSize: 11, color: _sub)),
            ],
          ),
          actions: [
            if ((c.data?.rows.isNotEmpty ?? false))
              IconButton(
                tooltip: 'Export to Excel',
                onPressed: c.exporting ? null : c.exportToExcel,
                icon: c.exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _excel))
                    : Image.asset(
                        AppAssets.excelIcon,
                        width: 22,
                        height: 22,
                        // If the asset ever goes missing, fall back rather
                        // than showing a broken-image box in the app bar.
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.grid_on_rounded, size: 20, color: _excel),
                      ),
              ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: c.loading ? null : c.load,
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ],
        ),
        body: Column(
          children: [
            _filterBar(c, context),
            Expanded(
              child: c.loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary))
                  : _body(c, context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  Widget _filterBar(MisReportController c, BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(children: [
        Expanded(
          child: _chip(
            icon: Icons.account_tree_outlined,
            label: c.branchLabel,
            onTap: () => _pickBranch(c, context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            icon: Icons.date_range_rounded,
            label: c.dateLabel,
            sub: c.datePreset == 'Custom' ? null : c.dateRangeLabel,
            onTap: () => _pickDate(c, context),
          ),
        ),
      ]),
    );
  }

  /// Period picker: each option shows the dates it resolves to, so there is no
  /// guessing what "This Quarter" actually covers. The calendar is a separate
  /// row at the bottom for anything the presets don't cover.
  void _pickDate(MisReportController c, BuildContext context) {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              _sheetHeader('Select Period'),
              const Divider(height: 1, color: _line),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (final p in MisReportController.datePresets)
                      _optionRow(
                        label: p,
                        trailing: c.presetRangeLabel(p),
                        selected: c.datePreset == p,
                        onTap: () {
                          Get.back();
                          c.applyPreset(p);
                        },
                      ),
                    const Divider(height: 1, color: _line),
                    _optionRow(
                      label: 'Custom range',
                      trailing: c.datePreset == 'Custom'
                          ? c.labelForRange(c.fromDate, c.toDate)
                          : 'Pick dates',
                      selected: c.datePreset == 'Custom',
                      icon: Icons.calendar_month_rounded,
                      showChevron: true,
                      onTap: () {
                        Get.back();
                        c.pickDateRange(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() => Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD8DCE6),
          borderRadius: BorderRadius.circular(4),
        ),
      );

  Widget _sheetHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 8, 12),
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _text)),
          ),
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.close_rounded, size: 20, color: _sub),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      );

  /// One selectable row: name on the left, what it resolves to on the right.
  Widget _optionRow({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? trailing,
    IconData? icon,
    bool showChevron = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        color: selected ? _primary.withValues(alpha: 0.06) : null,
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: selected ? _primary : _sub),
            const SizedBox(width: 12),
          ] else ...[
            SizedBox(
              width: 18,
              child: selected
                  ? const Icon(Icons.check_rounded, size: 17, color: _primary)
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _primary : _text)),
          ),
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(fontSize: 11.5, color: _sub)),
          if (showChevron) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _sub),
          ],
        ]),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? sub,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _line),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _text)),
                // The exact range stays visible even when a preset is showing.
                if (sub != null)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5, color: _sub)),
              ],
            ),
          ),
          const Icon(Icons.expand_more_rounded, size: 16, color: _sub),
        ]),
      ),
    );
  }

  void _pickBranch(MisReportController c, BuildContext context) {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            _sheetHeader('Select Branch'),
            const Divider(height: 1, color: _line),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  _optionRow(
                    label: 'All Branches',
                    trailing: 'Company-wide',
                    selected: c.branchId == '0',
                    onTap: () {
                      Get.back();
                      c.setBranch('0');
                    },
                  ),
                  const Divider(height: 1, color: _line),
                  ...c.branches.map((b) => _optionRow(
                        label: b.name,
                        selected: c.branchId == b.id.toString(),
                        onTap: () {
                          Get.back();
                          c.setBranch(b.id.toString());
                        },
                      )),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _body(MisReportController c, BuildContext context) {
    final d = c.data;
    if (d == null) {
      return _empty('Could not load this report', 'Pull to refresh or try again.');
    }
    final hasAnything =
        d.widgets.isNotEmpty || d.graphs.isNotEmpty || d.rows.isNotEmpty;
    if (!hasAnything) {
      return _empty('No data for this period',
          'Try a wider date range, or switch to All Branches.');
    }

    // Widgets can come back all-zero for a period with no activity. Say so,
    // rather than leaving a wall of ₹0 cards that looks like a failure.
    final noActivity = d.rows.isEmpty && d.graphs.isEmpty;

    return RefreshIndicator(
      color: _primary,
      onRefresh: c.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        children: [
          if (noActivity) _noActivityBanner(c),
          if (d.widgets.isNotEmpty) _widgetGrid(d.widgets),
          if (d.graphs.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...d.graphs.map((g) => _graphCard(g)),
          ],
          if (d.rows.isNotEmpty) _gridCard(c, d, context),
        ],
      ),
    );
  }

  Widget _noActivityBanner(MisReportController c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 18, color: Color(0xFFB45309)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'No records for ${c.dateRangeLabel}'
            '${c.branchId == '0' ? '' : ' in ${c.branchLabel}'}. '
            'Try a wider period.',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF9A3412)),
          ),
        ),
      ]),
    );
  }

  Widget _empty(String title, String sub) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                child: const Icon(Icons.insights_rounded,
                    size: 34, color: _primary),
              ),
              const SizedBox(height: 14),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _text)),
              const SizedBox(height: 4),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: _sub)),
            ],
          ),
        ),
      );

  // ── KPI cards ─────────────────────────────────────────────────────────────

  Widget _widgetGrid(List<MisWidget> widgets) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: widgets.map(_widgetCard).toList(),
    );
  }

  Widget _widgetCard(MisWidget w) {
    final color = _colorOf(w.color);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_iconOf(w.icon), size: 17, color: color),
            ),
          ]),
          const Spacer(),
          Text(
            _formatValue(w),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(w.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: _sub)),
        ],
      ),
    );
  }

  String _formatValue(MisWidget w) {
    final v = w.value;
    String core;
    switch (w.format) {
      case 'currency':
        core = '₹${inrNum(v, decimals: v % 1 == 0 ? 0 : 2)}';
        break;
      case 'percent':
        core = '${inrNum(v, decimals: 1)}%';
        break;
      default:
        core = inrNum(v, decimals: v % 1 == 0 ? 0 : 2);
    }
    return '${w.prefix}$core${w.suffix}';
  }

  /// The web sends font-awesome names; map the ones in use to Material icons.
  IconData _iconOf(String fa) {
    switch (fa.replaceAll('fa-', '')) {
      case 'rupee-sign':
        return Icons.currency_rupee_rounded;
      case 'clipboard-list':
        return Icons.assignment_outlined;
      case 'users':
      case 'user':
        return Icons.people_alt_outlined;
      case 'boxes':
      case 'box':
      case 'cubes':
        return Icons.inventory_2_outlined;
      case 'chart-line':
      case 'chart-area':
        return Icons.show_chart_rounded;
      case 'chart-pie':
        return Icons.pie_chart_outline_rounded;
      case 'calculator':
        return Icons.calculate_outlined;
      case 'file-invoice':
      case 'file-invoice-dollar':
        return Icons.receipt_long_outlined;
      case 'truck':
        return Icons.local_shipping_outlined;
      case 'industry':
        return Icons.factory_outlined;
      case 'check-circle':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.insights_rounded;
    }
  }

  Color _colorOf(String name) {
    switch (name.toLowerCase()) {
      case 'green':
        return const Color(0xFF16A34A);
      case 'orange':
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'red':
      case 'danger':
        return const Color(0xFFDC2626);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'teal':
      case 'cyan':
        return const Color(0xFF0EA5E9);
      case 'blue':
      case 'primary':
      default:
        return _primary;
    }
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  Widget _graphCard(MisGraph g) {
    if (g.points.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _text)),
          const SizedBox(height: 14),
          SizedBox(
            height: g.isCircular ? 190 : 176,
            child: g.isCircular ? _pie(g) : _cartesian(g),
          ),
          if (g.isCircular) _legend(g),
        ],
      ),
    );
  }

  static const List<Color> _series = [
    Color(0xFF5B5BD6), Color(0xFF16A34A), Color(0xFFF59E0B),
    Color(0xFF0EA5E9), Color(0xFF8B5CF6), Color(0xFFDC2626),
    Color(0xFF14B8A6), Color(0xFFEC4899), Color(0xFF64748B),
    Color(0xFFA16207),
  ];

  Widget _cartesian(MisGraph g) {
    final maxY = g.points.fold<double>(0, (m, p) => p.value > m ? p.value : m);
    final safeMax = maxY <= 0 ? 1.0 : maxY * 1.2;

    final labelStep = (g.points.length / 5).ceil().clamp(1, 9999);

    Widget bottomTitle(double value, TitleMeta meta) {
      if (value != value.roundToDouble()) return const SizedBox.shrink();
      final i = value.toInt();
      if (i < 0 || i >= g.points.length) return const SizedBox.shrink();
      if (i % labelStep != 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          _shortLabel(g.points[i].label),
          style: const TextStyle(fontSize: 9, color: _sub),
        ),
      );
    }

    // Four gridlines regardless of scale, so values never collide.
    final yInterval = safeMax / 4;

    final titles = FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          interval: yInterval,
          getTitlesWidget: (v, meta) {
            if (v > safeMax - (yInterval * 0.1)) return const SizedBox.shrink();
            return Text(_compact(v),
                style: const TextStyle(fontSize: 9, color: _sub));
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          interval: 1,
          getTitlesWidget: bottomTitle,
        ),
      ),
    );

    final grid = FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: yInterval,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: _line, strokeWidth: 1),
    );

    if (g.type == 'bar') {
      return BarChart(BarChartData(
        maxY: safeMax,
        titlesData: titles,
        gridData: grid,
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < g.points.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: g.points[i].value,
                width: 14,
                color: _series[i % _series.length],
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              )
            ]),
        ],
      ));
    }

    // area + line
    final isArea = g.type == 'area';
    return LineChart(LineChartData(
      maxY: safeMax,
      minY: 0,
      titlesData: titles,
      gridData: grid,
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (var i = 0; i < g.points.length; i++)
              FlSpot(i.toDouble(), g.points[i].value),
          ],
          isCurved: true,
          barWidth: 2.5,
          color: _primary,
          dotData: FlDotData(show: g.points.length <= 12),
          belowBarData: BarAreaData(
            show: isArea,
            color: _primary.withValues(alpha: 0.14),
          ),
        ),
      ],
    ));
  }

  Widget _pie(MisGraph g) {
    final total = g.points.fold<double>(0, (s, p) => s + p.value);
    return PieChart(PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: g.type == 'donut' ? 44 : 0,
      sections: [
        for (var i = 0; i < g.points.length; i++)
          PieChartSectionData(
            value: g.points[i].value,
            color: _series[i % _series.length],
            radius: 52,
            title: total <= 0
                ? ''
                : '${((g.points[i].value / total) * 100).toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
      ],
    ));
  }

  Widget _legend(MisGraph g) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < g.points.length; i++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: _series[i % _series.length],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(_shortLabel(g.points[i].label, max: 22),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: _sub)),
                ),
              ]),
          ],
        ),
      );

  String _shortLabel(String raw, {int max = 10}) {
    var s = raw.trim();
    // Dates arrive as "Apr  1 2026 12:00AM" for raw dimensions.
    if (s.contains(':') && s.length > 14) s = s.split(RegExp(r'\s+\d+:')).first;
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  String _compact(double v) {
    if (v.abs() >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v.abs() >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  /// Records as cards rather than a wide table — a spreadsheet grid squeezed
  /// onto a phone is unreadable, and reports have 10+ columns.
  Widget _gridCard(MisReportController c, MisData d, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Row(children: [
            const Icon(Icons.receipt_long_outlined, size: 16, color: _sub),
            const SizedBox(width: 8),
            Text('Records (${d.rows.length})',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: _text)),
            const Spacer(),
            if (c.canDrill)
              const Text('tap for detail',
                  style: TextStyle(fontSize: 10.5, color: _sub)),
          ]),
        ),
        ...d.rows.map((row) => _recordCard(c, d, row, context)),
      ],
    );
  }

  Widget _recordCard(MisReportController c, MisData d,
      Map<String, dynamic> row, BuildContext context) {
    final cols = d.visibleColumns;
    if (cols.isEmpty) return const SizedBox.shrink();

    // First column is the record's identity (order no, challan no …).
    final titleCol = cols.first;
    // The money column, if there is one, gets pulled out to the right.
    final amountCol = cols.firstWhere(
      (col) {
        final l = col.toLowerCase();
        return l.contains('amount') || l.contains('amt') || l.contains('value');
      },
      orElse: () => '',
    );
    // A date column reads better as the subtitle than buried in the body.
    final dateCol = cols.firstWhere(
      (col) => col.toLowerCase().contains('date'),
      orElse: () => '',
    );

    final bodyCols = cols
        .where((col) => col != titleCol && col != amountCol && col != dateCol)
        .toList();

    final drillId = c.mainIdOf(row);
    final tappable = c.canDrill && drillId > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: tappable ? () => _openDrilldown(c, drillId, context) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cell(row[titleCol]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: _text),
                        ),
                        if (dateCol.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(_cell(row[dateCol]),
                                style: const TextStyle(
                                    fontSize: 11.5, color: _sub)),
                          ),
                      ],
                    ),
                  ),
                  if (amountCol.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${_cell(row[amountCol])}',
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: _primary)),
                        Text(_pretty(amountCol),
                            style:
                                const TextStyle(fontSize: 9.5, color: _sub)),
                      ],
                    ),
                  ],
                  if (tappable)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 18, color: _sub),
                    ),
                ],
              ),
              if (bodyCols.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: _line),
                ),
                // Two per row so a 10-column report stays compact.
                for (var i = 0; i < bodyCols.length; i += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _field(bodyCols[i], row[bodyCols[i]])),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < bodyCols.length
                              ? _field(bodyCols[i + 1], row[bodyCols[i + 1]])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String col, dynamic value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_pretty(col).toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5)),
          const SizedBox(height: 2),
          Text(_cell(value),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: _text)),
        ],
      );

  /// order_No -> Order No, Totalamount -> Totalamount
  String _pretty(String col) {
    final spaced = col.replaceAll('_', ' ').trim();
    if (spaced.isEmpty) return col;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String _cell(dynamic v) {
    if (v == null) return '-';
    final s = v.toString();
    if (s.isEmpty) return '-';
    // ISO timestamps read badly in a narrow cell.
    final dt = DateTime.tryParse(s);
    if (dt != null && s.contains('T')) {
      return '${dt.day.toString().padLeft(2, '0')}-'
          '${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    }
    if (v is num) return inrNum(v, decimals: v % 1 == 0 ? 0 : 2);
    return s;
  }

  void _openDrilldown(MisReportController c, int mainId, BuildContext context) {
    c.loadDrilldown(mainId);
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: GetBuilder<MisReportController>(
            builder: (ctrl) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text('Details',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _text)),
                ),
                if (ctrl.drillLoading)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                        child: CircularProgressIndicator(color: _primary)),
                  )
                else if (ctrl.drillRows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Text('No detail rows for this record.',
                        style: TextStyle(fontSize: 13, color: _sub)),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: ctrl.drillRows.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 18, color: _line),
                      itemBuilder: (_, i) {
                        final r = ctrl.drillRows[i];
                        final keys = r.keys
                            .where((k) => !MisData.hiddenColumns
                                .contains(k.toLowerCase()))
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final k in keys)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(_pretty(k),
                                          style: const TextStyle(
                                              fontSize: 11, color: _sub)),
                                    ),
                                    Expanded(
                                      child: Text(_cell(r[k]),
                                          style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: _text)),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
