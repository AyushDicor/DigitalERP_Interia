// Response models for the Lead Management module.
// Maps the mobile API /api/lead/list and /api/lead/followups payloads.

import 'dart:convert';

LeadListResponse leadListResponseFromJson(String str) =>
    LeadListResponse.fromJson(json.decode(str));

class LeadListResponse {
  bool? success;
  List<LeadData>? data;
  String? message;
  int? status;

  LeadListResponse({this.success, this.data, this.message, this.status});

  factory LeadListResponse.fromJson(Map<String, dynamic> json) =>
      LeadListResponse(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<LeadData>.from(
                json["data"].map((x) => LeadData.fromJson(x))),
        message: json["message"],
        status: json["status"],
      );
}

class LeadData {
  int? mainid;
  String? leadnumber; // <- API key: leadno
  String? companyname;
  String? ownername;
  String? contactperson;
  String? mobilenumber; // <- API key: mobileno
  String? email;
  String? requirement;
  String? businessnature;
  String? leadsource;
  String? status; // <- API key: leadstatus
  String? leaddate;
  String? handler; // mapped from ownername (no separate handler yet)
  String? nextfollowupdate;

  LeadData({
    this.mainid,
    this.leadnumber,
    this.companyname,
    this.ownername,
    this.contactperson,
    this.mobilenumber,
    this.email,
    this.requirement,
    this.businessnature,
    this.leadsource,
    this.status,
    this.leaddate,
    this.handler,
    this.nextfollowupdate,
  });

  factory LeadData.fromJson(Map<String, dynamic> json) => LeadData(
        mainid: json["mainid"],
        leadnumber: json["leadno"]?.toString(),
        companyname: json["companyname"]?.toString(),
        ownername: json["ownername"]?.toString(),
        contactperson: json["contactperson"]?.toString(),
        mobilenumber: json["mobileno"]?.toString(),
        email: json["email"]?.toString(),
        requirement: json["requirement"]?.toString(),
        businessnature: json["businessnature"]?.toString(),
        leadsource: json["leadsource"]?.toString(),
        status: json["leadstatus"]?.toString(),
        leaddate: json["leaddate"]?.toString(),
        handler: json["ownername"]?.toString(),
        nextfollowupdate: json["nextfollowupdate"]?.toString(),
      );
}

// ── Followup history ──
LeadFollowupResponse leadFollowupResponseFromJson(String str) =>
    LeadFollowupResponse.fromJson(json.decode(str));

class LeadFollowupResponse {
  bool? success;
  List<LeadFollowupData>? data;
  String? message;
  int? status;

  LeadFollowupResponse({this.success, this.data, this.message, this.status});

  factory LeadFollowupResponse.fromJson(Map<String, dynamic> json) =>
      LeadFollowupResponse(
        success: json["success"],
        data: json["data"] == null
            ? []
            : List<LeadFollowupData>.from(
                json["data"].map((x) => LeadFollowupData.fromJson(x))),
        message: json["message"],
        status: json["status"],
      );
}

class LeadFollowupData {
  int? id;
  int? followupno;
  String? entrydate;
  String? remarks;
  String? followupdate;
  String? followuptime;
  String? purpose;
  String? status;

  LeadFollowupData({
    this.id,
    this.followupno,
    this.entrydate,
    this.remarks,
    this.followupdate,
    this.followuptime,
    this.purpose,
    this.status,
  });

  factory LeadFollowupData.fromJson(Map<String, dynamic> json) =>
      LeadFollowupData(
        id: json["id"],
        followupno: json["followupno"],
        entrydate: json["entrydate"]?.toString(),
        remarks: json["remarks"]?.toString(),
        followupdate: json["followupdate"]?.toString(),
        followuptime: json["followuptime"]?.toString(),
        purpose: json["purpose"]?.toString(),
        status: json["status"]?.toString(),
      );
}
