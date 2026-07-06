// Model for POST /api/dashboardnew/dashboardgraphs — chart data for the home
// dashboard: order trend (line), document mix (donut), orders by party (bar),
// and recent sale orders (list).

import 'dart:convert';

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _s(dynamic v) => v?.toString() ?? '';

class TrendPoint {
  final String date;
  final int count;
  final double amount;
  TrendPoint(this.date, this.count, this.amount);
  factory TrendPoint.fromJson(Map<String, dynamic> j) =>
      TrendPoint(_s(j['date']), _i(j['count']), _d(j['amount']));
}

class NameCount {
  final String name;
  final int count;
  NameCount(this.name, this.count);
  factory NameCount.fromJson(Map<String, dynamic> j) =>
      NameCount(_s(j['name']), _i(j['count']));
}

class RecentOrder {
  final int orderid;
  final String orderno;
  final String party;
  final String date;
  final double amount;
  final String stage;
  RecentOrder(this.orderid, this.orderno, this.party, this.date, this.amount,
      this.stage);
  factory RecentOrder.fromJson(Map<String, dynamic> j) => RecentOrder(
        _i(j['orderid']),
        _s(j['orderno']),
        _s(j['party']),
        _s(j['date']),
        _d(j['amount']),
        _s(j['stage']),
      );
}

class DashboardGraphsData {
  List<TrendPoint> orderTrend;
  List<NameCount> documentMix;
  List<NameCount> ordersByParty;
  List<RecentOrder> recentOrders;

  DashboardGraphsData({
    this.orderTrend = const [],
    this.documentMix = const [],
    this.ordersByParty = const [],
    this.recentOrders = const [],
  });

  static List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
      v == null ? <T>[] : List<T>.from((v as List).map((e) => f(e)));

  factory DashboardGraphsData.fromJson(Map<String, dynamic> d) =>
      DashboardGraphsData(
        orderTrend: _list(d['orderTrend'], TrendPoint.fromJson),
        documentMix: _list(d['documentMix'], NameCount.fromJson),
        ordersByParty: _list(d['ordersByParty'], NameCount.fromJson),
        recentOrders: _list(d['recentOrders'], RecentOrder.fromJson),
      );
}

class DashboardGraphsResponse {
  bool? success;
  DashboardGraphsData? data;
  String? message;
  int? status;

  DashboardGraphsResponse({this.success, this.data, this.message, this.status});

  factory DashboardGraphsResponse.fromJson(Map<String, dynamic> j) =>
      DashboardGraphsResponse(
        success: j['success'],
        data: j['data'] == null
            ? DashboardGraphsData()
            : DashboardGraphsData.fromJson(j['data']),
        message: j['message'],
        status: j['status'],
      );
}

DashboardGraphsResponse dashboardGraphsResponseFromJson(String s) =>
    DashboardGraphsResponse.fromJson(json.decode(s));
