import 'dart:convert';
import 'dart:developer';

import 'package:newdigitalerp/repo/base_api_helper.dart';
import 'package:newdigitalerp/repo/base_url.dart';

/// Config-driven MIS. The server decides which reports exist and what each one
/// shows — the app just renders whatever comes back, so a report added on the
/// web appears here with no app change.
///
///   POST /api/mis/reports    {compid, userid}
///        -> the reports this user may see (admin = all, others = granted)
///   POST /api/mis/data       {reportid, compid, branchid, userid, fromdate?, todate?}
///        -> widgets (KPI cards) + graphs + columns/rows (grid) + drillEnabled
///   POST /api/mis/drilldown  {reportid, mainid, compid, branchid, userid}
///        -> the detail behind one grid row
class MisRepo {
  static Future<List<MisReport>> reports({
    required String compid,
    required String userid,
  }) async {
    try {
      final res = await BaseApiHelper.postRequest(
          AppUrls.baseUrl + 'mis/reports', {'compid': compid, 'userid': userid});
      final data = (res.data as Map<String, dynamic>?)?['data'];
      if (data is! List) return [];
      return data.whereType<Map>().map(MisReport.fromJson).toList();
    } catch (e) {
      log('mis/reports failed: $e');
      return [];
    }
  }

  static Future<MisData?> data({
    required int reportid,
    required String compid,
    required String branchid,
    required String userid,
    String? fromdate,
    String? todate,
  }) async {
    try {
      final body = <String, dynamic>{
        'reportid': reportid,
        'compid': compid,
        'branchid': branchid,
        'userid': userid,
        if (fromdate != null) 'fromdate': fromdate,
        if (todate != null) 'todate': todate,
      };
      log('mis/data REQ => ${jsonEncode(body)}');
      final res =
          await BaseApiHelper.postRequest(AppUrls.baseUrl + 'mis/data', body);
      final d = (res.data as Map<String, dynamic>?)?['data'];
      if (d is! Map) return null;
      // The filter range is handed down so date-dimension charts can resolve
      // year-less labels ("25 Jul") and order themselves chronologically.
      return MisData.fromJson(
        Map<String, dynamic>.from(d),
        rangeStart: fromdate == null ? null : DateTime.tryParse(fromdate),
        rangeEnd: todate == null ? null : DateTime.tryParse(todate),
      );
    } catch (e) {
      log('mis/data failed: $e');
      return null;
    }
  }

  /// Detail rows behind one grid row. Returns the raw maps — the shape varies
  /// per report, so the screen renders them generically.
  static Future<List<Map<String, dynamic>>> drilldown({
    required int reportid,
    required int mainid,
    required String compid,
    required String branchid,
    required String userid,
  }) async {
    try {
      final res = await BaseApiHelper
          .postRequest(AppUrls.baseUrl + 'mis/drilldown', {
        'reportid': reportid,
        'mainid': mainid,
        'compid': compid,
        'branchid': branchid,
        'userid': userid,
      });
      final d = (res.data as Map<String, dynamic>?)?['data'];
      if (d is List) {
        return d.whereType<Map>().map(Map<String, dynamic>.from).toList();
      }
      // Some reports may wrap the rows — take the first list we find.
      if (d is Map) {
        for (final v in d.values) {
          if (v is List) {
            return v.whereType<Map>().map(Map<String, dynamic>.from).toList();
          }
        }
      }
      return [];
    } catch (e) {
      log('mis/drilldown failed: $e');
      return [];
    }
  }
}

String _s(dynamic v) => v?.toString() ?? '';
double _d(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(_s(v)) ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;

class MisReport {
  final int id;
  final String reportName;
  final String reportType; // Summary | Details
  final String formName; // the module, e.g. CreateSaleOrder
  final bool drillEnabled;

  const MisReport({
    required this.id,
    required this.reportName,
    required this.reportType,
    required this.formName,
    required this.drillEnabled,
  });

  factory MisReport.fromJson(Map j) => MisReport(
        id: _i(j['id']),
        reportName: _s(j['reportName']),
        reportType: _s(j['reportType']),
        formName: _s(j['formName']),
        drillEnabled: j['drillEnabled'] == true,
      );
}

class MisData {
  final List<MisWidget> widgets;
  final List<MisGraph> graphs;
  final List<String> columns;
  final List<Map<String, dynamic>> rows;
  final bool drillEnabled;

  const MisData({
    this.widgets = const [],
    this.graphs = const [],
    this.columns = const [],
    this.rows = const [],
    this.drillEnabled = false,
  });

  /// Columns that exist for the web UI's action links or as internal keys —
  /// never shown as data in a mobile grid.
  static const Set<String> hiddenColumns = {
    'editpageurl', 'reporturl', 'deletepageurl', 'newpage', 'qfrmname',
    'mainid',
  };

  List<String> get visibleColumns => columns
      .where((c) => !hiddenColumns.contains(c.toLowerCase()))
      .toList();

  factory MisData.fromJson(Map<String, dynamic> j,
      {DateTime? rangeStart, DateTime? rangeEnd}) {
    final rawRows = (j['rows'] is List) ? j['rows'] as List : const [];
    return MisData(
      widgets: ((j['widgets'] is List) ? j['widgets'] as List : const [])
          .whereType<Map>()
          .map(MisWidget.fromJson)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      graphs: MisGraph.groupPoints(
          (j['graphs'] is List) ? j['graphs'] as List : const [],
          rangeStart: rangeStart,
          rangeEnd: rangeEnd),
      columns: ((j['columns'] is List) ? j['columns'] as List : const [])
          .map((e) => e.toString())
          .toList(),
      rows: rawRows.whereType<Map>().map(Map<String, dynamic>.from).toList(),
      drillEnabled: j['drillEnabled'] == true,
    );
  }
}

/// A KPI card.
class MisWidget {
  final int sortOrder;
  final String title;
  final String icon; // font-awesome name from the web, e.g. fa-rupee-sign
  final String color; // blue | green | orange | red | purple …
  final String format; // number | currency | percent
  final String prefix;
  final String suffix;
  final double value;

  const MisWidget({
    required this.sortOrder,
    required this.title,
    required this.icon,
    required this.color,
    required this.format,
    required this.prefix,
    required this.suffix,
    required this.value,
  });

  factory MisWidget.fromJson(Map j) => MisWidget(
        sortOrder: _i(j['SortOrder']),
        title: _s(j['Title']),
        icon: _s(j['Icon']),
        color: _s(j['Color']),
        format: _s(j['Format']).toLowerCase(),
        prefix: _s(j['Prefix']),
        suffix: _s(j['Suffix']),
        value: _d(j['Value']),
      );
}

/// One chart. The API sends a FLAT list of points; [groupPoints] rebuilds them
/// into charts keyed by GraphOrdinal.
class MisGraph {
  final int ordinal;
  final String title;
  final String type; // area | line | bar | donut | pie
  final String dimFormat; // raw | monthYear | dayMonth
  final int sortOrder;
  final List<MisPoint> points;

  const MisGraph({
    required this.ordinal,
    required this.title,
    required this.type,
    required this.dimFormat,
    required this.sortOrder,
    required this.points,
  });

  bool get isCircular => type == 'donut' || type == 'pie';

  static List<MisGraph> groupPoints(List raw,
      {DateTime? rangeStart, DateTime? rangeEnd}) {
    final byOrdinal = <int, List<Map>>{};
    for (final p in raw.whereType<Map>()) {
      (byOrdinal[_i(p['GraphOrdinal'])] ??= []).add(p);
    }
    final out = <MisGraph>[];
    byOrdinal.forEach((ordinal, pts) {
      pts.sort((a, b) => _i(a['PointOrder']).compareTo(_i(b['PointOrder'])));
      final first = pts.first;
      final dimFormat = _s(first['DimFormat']);

      var points = pts
          .map((p) => MisPoint(label: _s(p['Label']), value: _d(p['Value'])))
          .toList();

      // A time-series must run left-to-right in date order. The server's
      // PointOrder does NOT guarantee that — "Daily Orders" comes back ordered
      // by value (2,2,2,3,3,4…), which drew a meaningless ever-rising line with
      // shuffled dates on the axis. Whenever the dimension is a date, order by
      // the date the label carries and ignore PointOrder.
      if (dimFormat == 'dayMonth' || dimFormat == 'monthYear') {
        points = _sortChronologically(points, dimFormat, rangeStart, rangeEnd);
      }

      out.add(MisGraph(
        ordinal: ordinal,
        title: _s(first['Title']),
        type: _s(first['Type']).toLowerCase(),
        dimFormat: dimFormat,
        sortOrder: _i(first['SortOrder']),
        points: points,
      ));
    });
    out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return out;
  }

  static const Map<String, int> _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Sorts date-dimension points by the date their label carries. Points whose
  /// label can't be read keep their original position rather than being
  /// dropped, so a format we haven't seen degrades to today's behaviour.
  static List<MisPoint> _sortChronologically(List<MisPoint> points,
      String dimFormat, DateTime? rangeStart, DateTime? rangeEnd) {
    final dated = <({MisPoint point, DateTime? date, int index})>[];
    for (var i = 0; i < points.length; i++) {
      dated.add((
        point: points[i],
        date: _labelDate(points[i].label, dimFormat, rangeStart, rangeEnd),
        index: i,
      ));
    }
    // Nothing parsed → leave the server's order alone.
    if (dated.every((e) => e.date == null)) return points;

    dated.sort((a, b) {
      if (a.date == null || b.date == null) return a.index.compareTo(b.index);
      final c = a.date!.compareTo(b.date!);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
    return dated.map((e) => e.point).toList();
  }

  /// "25 Jul" (dayMonth — no year!) or "Jul 26" (monthYear, 2-digit year).
  ///
  /// dayMonth labels carry no year, so the year is taken from the filter range:
  /// whichever of its start/end year puts the date inside the range wins. That
  /// keeps a range spanning a year boundary (Dec → Jan) in the right order.
  static DateTime? _labelDate(
      String label, String dimFormat, DateTime? rangeStart, DateTime? rangeEnd) {
    final s = label.trim();
    if (s.isEmpty) return null;

    if (dimFormat == 'monthYear') {
      final m = RegExp(r'^([A-Za-z]{3,})\s+(\d{2,4})$').firstMatch(s);
      if (m == null) return null;
      final month = _months[m.group(1)!.substring(0, 3).toLowerCase()];
      if (month == null) return null;
      var year = int.parse(m.group(2)!);
      if (year < 100) year += 2000;
      return DateTime(year, month, 1);
    }

    final m = RegExp(r'^(\d{1,2})\s+([A-Za-z]{3,})$').firstMatch(s);
    if (m == null) return null;
    final month = _months[m.group(2)!.substring(0, 3).toLowerCase()];
    if (month == null) return null;
    final day = int.parse(m.group(1)!);

    final years = <int>{
      if (rangeStart != null) rangeStart.year,
      if (rangeEnd != null) rangeEnd.year,
      DateTime.now().year,
    };
    for (final y in years) {
      final d = DateTime(y, month, day);
      final afterStart = rangeStart == null ||
          !d.isBefore(DateTime(rangeStart.year, rangeStart.month, rangeStart.day));
      final beforeEnd = rangeEnd == null ||
          !d.isAfter(DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day));
      if (afterStart && beforeEnd) return d;
    }
    // Outside the range (or no range given) — still needs a stable date.
    return DateTime(years.first, month, day);
  }
}

class MisPoint {
  final String label;
  final double value;
  const MisPoint({required this.label, required this.value});
}
