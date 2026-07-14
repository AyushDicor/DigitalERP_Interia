// Response for POST /api/stockenquiry/items — item list with total current stock.
// To parse: final resp = stockEnquiryItemRespFromJson(jsonString);

import 'dart:convert';

StockEnquiryItemResp stockEnquiryItemRespFromJson(String str) =>
    StockEnquiryItemResp.fromJson(json.decode(str));

String stockEnquiryItemRespToJson(StockEnquiryItemResp data) =>
    json.encode(data.toJson());

class StockEnquiryItemResp {
  bool? success;
  List<StockEnquiryItem>? data;
  String? message;
  int? status;

  StockEnquiryItemResp({this.success, this.data, this.message, this.status});

  factory StockEnquiryItemResp.fromJson(Map<String, dynamic> json) =>
      StockEnquiryItemResp(
        success: json["success"],
        data: json["data"] == null
            ? null
            : List<StockEnquiryItem>.from(
                json["data"].map((x) => StockEnquiryItem.fromJson(x))),
        message: json["message"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data == null
            ? null
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "message": message,
        "status": status,
      };
}

class StockEnquiryItem {
  int? itemid;
  String? itemname;
  String? category;
  double? rate;
  String? unit;
  double? quantity;

  StockEnquiryItem({
    this.itemid,
    this.itemname,
    this.category,
    this.rate,
    this.unit,
    this.quantity,
  });

  factory StockEnquiryItem.fromJson(Map<String, dynamic> json) =>
      StockEnquiryItem(
        itemid: json["itemid"],
        itemname: json["itemname"],
        category: json["category"],
        rate: (json["rate"] ?? 0).toDouble(),
        unit: json["unit"],
        quantity: (json["quantity"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "itemid": itemid,
        "itemname": itemname,
        "category": category,
        "rate": rate,
        "unit": unit,
        "quantity": quantity,
      };
}
