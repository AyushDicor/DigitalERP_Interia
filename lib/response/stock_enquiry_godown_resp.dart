// Response for POST /api/stockenquiry/godownwise — one item's stock broken down per godown.
// To parse: final resp = stockEnquiryGodownRespFromJson(jsonString);

import 'dart:convert';

StockEnquiryGodownResp stockEnquiryGodownRespFromJson(String str) =>
    StockEnquiryGodownResp.fromJson(json.decode(str));

String stockEnquiryGodownRespToJson(StockEnquiryGodownResp data) =>
    json.encode(data.toJson());

class StockEnquiryGodownResp {
  bool? success;
  StockEnquiryGodownData? data;
  String? message;
  int? status;

  StockEnquiryGodownResp({this.success, this.data, this.message, this.status});

  factory StockEnquiryGodownResp.fromJson(Map<String, dynamic> json) =>
      StockEnquiryGodownResp(
        success: json["success"],
        data: json["data"] == null
            ? null
            : StockEnquiryGodownData.fromJson(json["data"]),
        message: json["message"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data?.toJson(),
        "message": message,
        "status": status,
      };
}

class StockEnquiryGodownData {
  int? itemid;
  String? itemname;
  String? unit;
  double? rate;
  double? moq;
  double? reorderlevel;
  double? totalstock;
  List<GodownStock>? godowns;

  StockEnquiryGodownData({
    this.itemid,
    this.itemname,
    this.unit,
    this.rate,
    this.moq,
    this.reorderlevel,
    this.totalstock,
    this.godowns,
  });

  factory StockEnquiryGodownData.fromJson(Map<String, dynamic> json) =>
      StockEnquiryGodownData(
        itemid: json["itemid"],
        itemname: json["itemname"],
        unit: json["unit"],
        rate: (json["rate"] ?? 0).toDouble(),
        moq: (json["moq"] ?? 0).toDouble(),
        reorderlevel: (json["reorderlevel"] ?? 0).toDouble(),
        totalstock: (json["totalstock"] ?? 0).toDouble(),
        godowns: json["godowns"] == null
            ? []
            : List<GodownStock>.from(
                json["godowns"].map((x) => GodownStock.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "itemid": itemid,
        "itemname": itemname,
        "unit": unit,
        "rate": rate,
        "moq": moq,
        "reorderlevel": reorderlevel,
        "totalstock": totalstock,
        "godowns": godowns == null
            ? null
            : List<dynamic>.from(godowns!.map((x) => x.toJson())),
      };
}

class GodownStock {
  int? godownid;
  String? godownname;
  double? quantity;

  GodownStock({this.godownid, this.godownname, this.quantity});

  factory GodownStock.fromJson(Map<String, dynamic> json) => GodownStock(
        godownid: json["godownid"],
        godownname: json["godownname"],
        quantity: (json["quantity"] ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "godownid": godownid,
        "godownname": godownname,
        "quantity": quantity,
      };
}
