// To parse this JSON data, do
//
//     final partyDropdownListResponse = partyDropdownListResponseFromJson(jsonString);

import 'dart:convert';

PartyDropdownListResponse partyDropdownListResponseFromJson(String str) =>
    PartyDropdownListResponse.fromJson(json.decode(str));

String partyDropdownListResponseToJson(PartyDropdownListResponse data) =>
    json.encode(data.toJson());

class PartyDropdownListResponse {
  PartyDropdownListResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  List<PartyDropdownData>? data;
  String? message;
  int? status;

  factory PartyDropdownListResponse.fromJson(Map<String, dynamic> json) =>
      PartyDropdownListResponse(
        success: json['success'],
        data: json['data'] == null
            ? null
            : List<PartyDropdownData>.from(json['data'].map((x) => PartyDropdownData.fromJson(x))),
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

class PartyDropdownData {
  PartyDropdownData({
    this.partyid,
    this.partyname,
    this.mobileno,
    this.address,
    this.location,
    this.executive,
    this.outstanding,
    this.remarks,
  });

  int? partyid;
  String? partyname;
  // Enriched fields from the widened agentparty/getagentpartyname endpoint.
  // Absent on the legacy response shape → null; consumers must null-check.
  String? mobileno;
  String? address;
  String? location; // "lat,lng"
  String? executive;
  String? outstanding;
  String? remarks;

  factory PartyDropdownData.fromJson(Map<String, dynamic> json) => PartyDropdownData(
        partyid: json['partyid'],
        partyname: json['partyname'],
        mobileno: json['mobileno']?.toString(),
        address: json['address']?.toString(),
        location: json['location']?.toString(),
        executive: json['executive']?.toString(),
        outstanding: json['outstanding']?.toString(),
        remarks: json['remarks']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'partyid': partyid,
        'partyname': partyname,
        'mobileno': mobileno,
        'address': address,
        'location': location,
        'executive': executive,
        'outstanding': outstanding,
        'remarks': remarks,
      };

  @override
  String toString() {
    return 'PartyDropdownData{partyid: $partyid, partyname: $partyname}';
  }
}
