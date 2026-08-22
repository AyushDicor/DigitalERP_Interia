// To parse this JSON data, do
//
//     final customerDataResponse = customerDataResponseFromJson(jsonString);

import 'dart:convert';

CustomerDataResponse customerDataResponseFromJson(String str) => CustomerDataResponse.fromJson(json.decode(str));

String customerDataResponseToJson(CustomerDataResponse data) => json.encode(data.toJson());

class CustomerDataResponse {
  CustomerDataResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<VisitCustomerListData>? data;
  String? message;
  int? status;

  factory CustomerDataResponse.fromJson(Map<String, dynamic> json) => CustomerDataResponse(
    success: json["success"],
    data: json["data"] == null ? [] : List<VisitCustomerListData>.from(json["data"]!.map((x) => VisitCustomerListData.fromJson(x))),
    message: json["message"],
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "message": message,
    "status": status,
  };
}

class VisitCustomerListData {
  VisitCustomerListData({
    this.customername,
    this.partyid,
    this.area,
    this.areaid,
    this.distance,
    this.isChecked
  });

  String? customername;
  int? partyid;
  String? area;
  int? areaid;
  String? distance;
  bool? isChecked;

  // Parsed defensively: the API sends "Distance": 0.00 (a number), and a plain
  // cast to String? threw `type 'double' is not a subtype of type 'String?'`.
  // One bad row aborted the whole list, so the screen showed "No Customers
  // Found" even though hundreds of customers had been returned.
  factory VisitCustomerListData.fromJson(Map<String, dynamic> json) => VisitCustomerListData(
    customername: json["Customername"]?.toString(),
    partyid: _asInt(json["partyid"]),
    area: json["area"]?.toString(),
    areaid: _asInt(json["areaid"]),
    distance: json["Distance"]?.toString(),
    isChecked: false
  );

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  Map<String, dynamic> toJson() => {
    "Customername": customername,
    "partyid": partyid,
    "area": area,
    "areaid": areaid,
    "Distance": distance,
  };
}
