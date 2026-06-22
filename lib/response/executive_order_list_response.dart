// To parse this JSON data, do
//
//     final executiveOrderListResponse = executiveOrderListResponseFromJson(jsonString);

import 'dart:convert';

ExecutiveOrderListResponse executiveOrderListResponseFromJson(String str) =>
    ExecutiveOrderListResponse.fromJson(json.decode(str));

String executiveOrderListResponseToJson(ExecutiveOrderListResponse data) =>
    json.encode(data.toJson());

class ExecutiveOrderListResponse {
  ExecutiveOrderListResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<ExecutiveOrderData>? data;
  String? message;
  int? status;

  factory ExecutiveOrderListResponse.fromJson(Map<String, dynamic> json) =>
      ExecutiveOrderListResponse(
        success: json['success'],
        data: json['data'] == null
            ? null
            : List<ExecutiveOrderData>.from(
                json['data'].map((x) => ExecutiveOrderData.fromJson(x))),
        message: json['message'],
        status: json['status'],
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': List<dynamic>.from(data!.map((x) => x.toJson())),
        'message': message,
        'status': status,
      };
}

class ExecutiveOrderData {
  ExecutiveOrderData({
    this.orderid,
    this.orderno,
    this.orderdate,
    this.partyname,
    this.partyid,
    this.amount,
    this.executivename,
    this.orderstatus,
  });

  int? orderid;
  String? orderno;
  String? orderdate;
  String? partyname;
  int? partyid;
  double? amount;
  String? executivename;
  String? orderstatus;

  factory ExecutiveOrderData.fromJson(Map<String, dynamic> json) => ExecutiveOrderData(
        orderid: (json['orderid'] as num?)?.toInt(),
        orderno: json['orderno']?.toString(),
        orderdate: json['orderdate']?.toString(),
        partyname: json['partyname']?.toString(),
        partyid: (json['partyid'] as num?)?.toInt(),
        // API returns amount as a JSON number that may be int (e.g. 0, 650) or
        // double; cast via num so int values don't throw "int is not a subtype of double?".
        amount: (json['amount'] as num?)?.toDouble(),
        executivename: json['executivename']?.toString(),
        orderstatus: json['orderstatus']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'orderid': orderid,
        'orderno': orderno,
        'orderdate': orderdate,
        'partyname': partyname,
        'partyid': partyid,
        'amount': amount,
        'executivename': executivename,
        'orderstatus': orderstatus,
      };
}
