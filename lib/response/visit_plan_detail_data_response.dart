// To parse this JSON data, do
//
//     final visitPlanDetailDataResponse = visitPlanDetailDataResponseFromJson(jsonString);

import 'dart:convert';

VisitPlanDetailDataResponse visitPlanDetailDataResponseFromJson(String str) => VisitPlanDetailDataResponse.fromJson(json.decode(str));

String visitPlanDetailDataResponseToJson(VisitPlanDetailDataResponse data) => json.encode(data.toJson());

class VisitPlanDetailDataResponse {
  VisitPlanDetailDataResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<VisitPlanDetailsDataList>? data;
  String? message;
  int? status;

  factory VisitPlanDetailDataResponse.fromJson(Map<String, dynamic> json) => VisitPlanDetailDataResponse(
    success: json["success"],
    data: json["data"] == null ? [] : List<VisitPlanDetailsDataList>.from(json["data"]!.map((x) => VisitPlanDetailsDataList.fromJson(x))),
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

class VisitPlanDetailsDataList {
  VisitPlanDetailsDataList({
    this.customername,
    this.partyid,
    this.visitdate,
    this.visittime,
    this.visitstatus,
    this.distance,
    this.checkstatus,
    this.isCheckIn
  });

  String? customername;
  int? partyid;
  String? visitdate;
  String? visittime;
  String? visitstatus;
  String? distance;
  String? checkstatus;
  bool ? isCheckIn;

  // ── Visit details (web-ERP parity). Populated when the detail endpoint
  // returns them; blank otherwise. Keys are matched loosely so either the
  // PascalCase columns or lowercase params work.
  String? purposeType;
  String? purpose;
  String? location;
  String? contactPerson;
  String? contactNo;
  String? travelMode;
  String? outcome;
  String? checkInTime;
  String? checkOutTime;
  String? visitNo;

  static String? _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  factory VisitPlanDetailsDataList.fromJson(Map<String, dynamic> json) => VisitPlanDetailsDataList(
    customername: _pick(json, ["Customername", "VisitTo", "customername"]),
    partyid: json["partyid"] ?? json["PartyId"],
    visitdate: _pick(json, ["visitdate", "VisitDateText", "VisitDate"]),
    visittime: json["visittime"],
    visitstatus: _pick(json, ["visitstatus", "Status"]),
    distance: (json["Distance"] ?? json["DistanceKm"])?.toString(),   // API can send a number
    checkstatus: json["checkstatus"],
    isCheckIn: true,
  )
    ..purposeType = _pick(json, ["PurposeType", "purposetype"])
    ..purpose = _pick(json, ["Purpose", "purpose"])
    ..location = _pick(json, ["Location", "location"])
    ..contactPerson = _pick(json, ["ContactPerson", "contactperson"])
    ..contactNo = _pick(json, ["ContactNo", "contactno"])
    ..travelMode = _pick(json, ["TravelMode", "travelmode"])
    ..outcome = _pick(json, ["Outcome", "outcome"])
    ..checkInTime = _pick(json, ["CheckInText", "CheckInTime", "checkintime"])
    ..checkOutTime = _pick(json, ["CheckOutText", "CheckOutTime", "checkouttime"])
    ..visitNo = _pick(json, ["VisitNo", "visitno"]);

  Map<String, dynamic> toJson() => {
    "Customername": customername,
    "partyid": partyid,
    "visitdate": visitdate,
    "visittime": visittime,
    "visitstatus": visitstatus,
    "Distance": distance,
    "checkstatus": checkstatus,
  };
}
