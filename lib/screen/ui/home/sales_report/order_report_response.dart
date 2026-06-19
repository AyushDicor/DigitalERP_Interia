import 'dart:convert';

OrderReportResponse orderReportResponseFromJson(String str) =>
    OrderReportResponse.fromJson(json.decode(str));

class OrderReportResponse {
  bool? success;
  OrderReportData? data;
  String? message;
  int? status;

  OrderReportResponse({this.success, this.data, this.message, this.status});

  factory OrderReportResponse.fromJson(Map<String, dynamic> json) =>
      OrderReportResponse(
        success: json['success'],
        data: json['data'] == null
            ? null
            : OrderReportData.fromJson(json['data']),
        message: json['message'],
        status: json['status'],
      );
}

class OrderReportData {
  List<OrderReportItem> data;
  OrderReportSummary summary;

  OrderReportData({this.data = const [], OrderReportSummary? summary})
      : summary = summary ?? OrderReportSummary();

  factory OrderReportData.fromJson(Map<String, dynamic> json) =>
      OrderReportData(
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => OrderReportItem.fromJson(e))
                .toList() ??
            [],
        summary: json['summary'] == null
            ? OrderReportSummary()
            : OrderReportSummary.fromJson(json['summary']),
      );
}

class OrderReportItem {
  int? orderid;
  String? orderno;
  String? orderdate;
  String? partyname;
  num? amount;
  String? executivename;
  String? orderstatus;

  OrderReportItem({
    this.orderid,
    this.orderno,
    this.orderdate,
    this.partyname,
    this.amount,
    this.executivename,
    this.orderstatus,
  });

  factory OrderReportItem.fromJson(Map<String, dynamic> json) => OrderReportItem(
        orderid: json['orderid'],
        orderno: json['orderno'],
        orderdate: json['orderdate'],
        partyname: json['partyname'],
        amount: json['amount'],
        executivename: json['executivename'],
        orderstatus: json['orderstatus'],
      );
}

class OrderReportSummary {
  num totalorders;
  num totalamount;

  OrderReportSummary({this.totalorders = 0, this.totalamount = 0});

  factory OrderReportSummary.fromJson(Map<String, dynamic> json) =>
      OrderReportSummary(
        totalorders: json['totalorders'] ?? 0,
        totalamount: json['totalamount'] ?? 0,
      );
}
