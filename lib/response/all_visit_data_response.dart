// To parse this JSON data, do
//
//     final allVisitDataResponse = allVisitDataResponseFromJson(jsonString);

import 'dart:convert';

AllVisitDataResponse allVisitDataResponseFromJson(String str) => AllVisitDataResponse.fromJson(json.decode(str));

String allVisitDataResponseToJson(AllVisitDataResponse data) => json.encode(data.toJson());

class AllVisitDataResponse {
  AllVisitDataResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<VisitListData>? data;
  String? message;
  int? status;

  factory AllVisitDataResponse.fromJson(Map<String, dynamic> json) => AllVisitDataResponse(
    success: json["success"],
    data: json["data"] == null ? [] : List<VisitListData>.from(json["data"]!.map((x) => VisitListData.fromJson(x))),
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

class VisitListData {
  VisitListData({
    this.vistarea,
    this.visitdate,
    this.visittime,
    this.visitstatus,
    this.executive,
    this.planid,
    this.visitid,
    this.party
  });

  String? vistarea;
  String? visitdate;
  String? visittime;
  String? visitstatus;
  String? executive;
  int? planid;
  int? visitid;
  String ? party;

  // ── /api/visit/list (new) ──
  String? visitNo;
  String? purposeType;
  String? contactPerson;

  static String? _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  static int? _int(dynamic v) => v == null
      ? null
      : (v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString())));

  /// Reads both shapes: the old allvisitlistwithbranch response and the new
  /// /api/visit/list one (Id, VisitNo, VisitDate, VisitedByName, VisitTo,
  /// PurposeType, Location, ContactPerson, Status).
  factory VisitListData.fromJson(Map<String, dynamic> json) => VisitListData(
    vistarea: _pick(json, ["Vistarea", "Location", "location"]),
    visitdate: _pick(json, ["visitdate", "VisitDate", "VisitDateText"]),
    visittime: _pick(json, ["visittime", "CheckInText"]),
    visitstatus: _pick(json, ["visitstatus", "Status"]),
    executive: _pick(json, ["Executive", "VisitedByName"]),
    planid: _int(json["Planid"] ?? json["PlanId"]),
    // The new API's row id is `Id`; the old one used `visitid`.
    visitid: _int(json["visitid"] ?? json["Id"]),
    party: _pick(json, ["party", "VisitTo"]),
  )
    ..visitNo = _pick(json, ["VisitNo", "visitno"])
    ..purposeType = _pick(json, ["PurposeType", "purposetype"])
    ..contactPerson = _pick(json, ["ContactPerson", "contactperson"]);

  Map<String, dynamic> toJson() => {
    "Vistarea": vistarea,
    "visitdate": visitdate,
    "visittime": visittime,
    "visitstatus": visitstatus,
    "Executive": executive,
    "Planid": planid,
    "visitid": visitid,
    "party":party
  };
}
