// Models for the Lead Entry (create/edit) form:
//  - /api/lead/formdropdowns  -> LeadFormData (all the pick-lists)
//  - /api/lead/companies      -> [LeadOption] (Existing companies)
//  - /api/lead/itemmaster     -> [LeadOption] (item master)
//  - /api/lead/partydetail    -> LeadPartyDetail (auto-fill)
// Plus LeadItemLine — an item row the user adds, serialised into the save body.

import 'dart:convert';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// A generic id+name dropdown option. Tolerant of the various key names the ERP
/// procs emit (leadstatusid/assigntoid/companynameid/itemnamecode + matching name).
class LeadOption {
  final int id;
  final String name;
  LeadOption(this.id, this.name);

  factory LeadOption.fromJson(Map<String, dynamic> j) {
    final id = j['id'] ??
        j['leadstatusid'] ??
        j['assigntoid'] ??
        j['companynameid'] ??
        j['itemnamecode'] ??
        j['contactpersonid'] ??
        0;
    final name = j['name'] ??
        j['leadstatus'] ??
        j['assignto'] ??
        j['companyname'] ??
        j['itemnamecodetext'] ??
        j['contactperson'] ??
        '';
    return LeadOption(_toInt(id), (name ?? '').toString());
  }

  static List<LeadOption> list(dynamic v) => v == null
      ? <LeadOption>[]
      : List<LeadOption>.from((v as List).map((e) => LeadOption.fromJson(e)));
}

class LeadFormData {
  List<LeadOption> companyType;
  List<LeadOption> leadStatus;
  List<LeadOption> assignTo;
  List<LeadOption> leadSource;
  List<LeadOption> leadCategory;
  List<LeadOption> leadPriority;
  List<LeadOption> designation;
  List<LeadOption> marketSegment;
  List<LeadOption> industryType;
  List<LeadOption> units;

  LeadFormData({
    this.companyType = const [],
    this.leadStatus = const [],
    this.assignTo = const [],
    this.leadSource = const [],
    this.leadCategory = const [],
    this.leadPriority = const [],
    this.designation = const [],
    this.marketSegment = const [],
    this.industryType = const [],
    this.units = const [],
  });

  factory LeadFormData.fromJson(Map<String, dynamic> d) => LeadFormData(
        companyType: LeadOption.list(d['companyType']),
        leadStatus: LeadOption.list(d['leadStatus']),
        assignTo: LeadOption.list(d['assignTo']),
        leadSource: LeadOption.list(d['leadSource']),
        leadCategory: LeadOption.list(d['leadCategory']),
        leadPriority: LeadOption.list(d['leadPriority']),
        designation: LeadOption.list(d['designation']),
        marketSegment: LeadOption.list(d['marketSegment']),
        industryType: LeadOption.list(d['industryType']),
        units: LeadOption.list(d['units']),
      );
}

class LeadFormResponse {
  bool? success;
  LeadFormData? data;
  String? message;
  int? status;
  LeadFormResponse({this.success, this.data, this.message, this.status});

  factory LeadFormResponse.fromJson(Map<String, dynamic> j) => LeadFormResponse(
        success: j['success'],
        data: j['data'] == null ? LeadFormData() : LeadFormData.fromJson(j['data']),
        message: j['message'],
        status: j['status'],
      );
}

LeadFormResponse leadFormResponseFromJson(String s) =>
    LeadFormResponse.fromJson(json.decode(s));

/// A simple list-of-options response (companies / item master).
class LeadOptionsResponse {
  bool? success;
  List<LeadOption> data;
  String? message;
  int? status;
  LeadOptionsResponse({this.success, this.data = const [], this.message, this.status});

  factory LeadOptionsResponse.fromJson(Map<String, dynamic> j) => LeadOptionsResponse(
        success: j['success'],
        data: LeadOption.list(j['data']),
        message: j['message'],
        status: j['status'],
      );
}

LeadOptionsResponse leadOptionsResponseFromJson(String s) =>
    LeadOptionsResponse.fromJson(json.decode(s));

/// Party auto-fill payload.
class LeadPartyDetail {
  int partyid;
  String companyname;
  String address;
  String contactperson;
  String mobileno;
  String emailid;
  String ownername;
  String phoneno;
  String pincode;
  String gstno;
  int stateid;
  String state;
  int cityid;
  String city;
  List<LeadOption> contacts;

  LeadPartyDetail({
    this.partyid = 0,
    this.companyname = '',
    this.address = '',
    this.contactperson = '',
    this.mobileno = '',
    this.emailid = '',
    this.ownername = '',
    this.phoneno = '',
    this.pincode = '',
    this.gstno = '',
    this.stateid = 0,
    this.state = '',
    this.cityid = 0,
    this.city = '',
    this.contacts = const [],
  });

  factory LeadPartyDetail.fromResponse(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>?;
    final party = (data?['party'] as Map<String, dynamic>?) ?? {};
    return LeadPartyDetail(
      partyid: _toInt(party['partyid']),
      companyname: (party['companyname'] ?? '').toString(),
      address: (party['address'] ?? '').toString(),
      contactperson: (party['contactperson'] ?? '').toString(),
      mobileno: (party['mobileno'] ?? '').toString(),
      emailid: (party['emailid'] ?? '').toString(),
      ownername: (party['ownername'] ?? '').toString(),
      phoneno: (party['phoneno'] ?? '').toString(),
      pincode: (party['pincode'] ?? '').toString(),
      gstno: (party['gstno'] ?? '').toString(),
      stateid: _toInt(party['stateid']),
      state: (party['state'] ?? '').toString(),
      cityid: _toInt(party['cityid']),
      city: (party['city'] ?? '').toString(),
      contacts: LeadOption.list(data?['contacts']),
    );
  }
}

class LeadPartyResponse {
  int? status;
  String? message;
  LeadPartyDetail? detail;
  LeadPartyResponse({this.status, this.message, this.detail});

  factory LeadPartyResponse.fromJson(Map<String, dynamic> j) => LeadPartyResponse(
        status: j['status'],
        message: j['message'],
        detail: LeadPartyDetail.fromResponse(j),
      );
}

LeadPartyResponse leadPartyResponseFromJson(String s) =>
    LeadPartyResponse.fromJson(json.decode(s));

/// An item line the user adds in the form.
class LeadItemLine {
  int itemid;
  String itemname;
  double quantity;
  double saleprice;
  double mrp;
  int billingunitid;
  String billingunit;
  String sizename;
  String weightname;

  LeadItemLine({
    this.itemid = 0,
    this.itemname = '',
    this.quantity = 0,
    this.saleprice = 0,
    this.mrp = 0,
    this.billingunitid = 0,
    this.billingunit = '',
    this.sizename = '',
    this.weightname = '',
  });

  double get amount => quantity * saleprice;

  Map<String, dynamic> toJson() => {
        'itemid': itemid,
        'itemname': itemname,
        'quantity': quantity,
        'saleprice': saleprice,
        'mrp': mrp,
        'amount': amount,
        'billingunitid': billingunitid,
        'billingunit': billingunit,
        'sizename': sizename,
        'weightname': weightname,
      };
}
