// Response models for the ERP-native Lead Management module.
//
// The mobile API wraps the web ERP's own procs, so the JSON keys are the exact
// (PascalCase) column names the procs emit:
//   /api/lead/dashboard -> leaddetailsdetestnew (7 result sets)
//   /api/lead/items     -> EditLeadEntry (lead header + item lines)
//
// Every parser is null-tolerant and reads a lowercase fallback key too, so a
// future proc tweak (or the old standalone endpoint) won't crash the app.

import 'dart:convert';

// ── small dynamic helpers ────────────────────────────────────────────────────
String? _s(Map j, List<String> keys) {
  for (final k in keys) {
    if (j.containsKey(k) && j[k] != null) return j[k].toString();
  }
  return null;
}

int? _i(Map j, List<String> keys) {
  final v = _s(j, keys);
  if (v == null) return null;
  return int.tryParse(v) ?? double.tryParse(v)?.toInt();
}

double _d(Map j, List<String> keys) {
  final v = _s(j, keys);
  if (v == null) return 0;
  return double.tryParse(v) ?? 0;
}

// ═════════════════════════════════ Lead row ═════════════════════════════════
class LeadData {
  int? mainid;
  String? leadnumber; // LeadNo
  String? companyname;
  String? ownername;
  String? contactperson;
  String? mobilenumber; // MobileNo
  String? email;
  String? requirement; // == Specification
  String? businessnature;
  String? leadsource;
  String? status; // LeadStatus
  String? leaddate;
  String? handler; // AssigneeName
  String? address;
  String? specification;
  String? otherremarks;
  int? assigneeId;
  String? nextfollowupdate; // filled client-side from follow-ups

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
    this.address,
    this.specification,
    this.otherremarks,
    this.assigneeId,
    this.nextfollowupdate,
  });

  factory LeadData.fromJson(Map<String, dynamic> j) => LeadData(
        mainid: _i(j, ['MainId', 'mainid']),
        leadnumber: _s(j, ['LeadNo', 'leadno']),
        companyname: _s(j, ['CompanyName', 'companyname']),
        ownername: _s(j, ['OwnerName', 'ownername']),
        contactperson: _s(j, ['ContactPerson', 'contactperson']),
        mobilenumber: _s(j, ['MobileNo', 'mobileno']),
        email: _s(j, ['Email', 'emailid', 'email']),
        requirement: _s(j, ['Specification', 'requirement', 'Requirement']),
        businessnature: _s(j, ['BusinessNature', 'businessnature']),
        leadsource: _s(j, ['LeadSource', 'leadsource']),
        status: _s(j, ['LeadStatus', 'leadstatus']),
        leaddate: _s(j, ['LeadDate', 'leaddate']),
        handler: _s(j, ['AssigneeName', 'assignto', 'ownername']),
        address: _s(j, ['Address', 'address']),
        specification: _s(j, ['Specification', 'specification']),
        otherremarks: _s(j, ['otherremarks', 'OtherRemarks']),
        assigneeId: _i(j, ['AssigneeId', 'assigntoid']),
      );
}

// ══════════════════════════════ Follow-up row ═══════════════════════════════
class LeadFollowupData {
  int? id; // FollowUpId
  int? leadId; // LeadEntryId
  int? followupno;
  String? entrydate;
  String? remarks;
  String? followupdate;
  String? followuptime;
  String? purpose; // FollowUpRemark
  String? followupremark;
  String? status;

  LeadFollowupData({
    this.id,
    this.leadId,
    this.followupno,
    this.entrydate,
    this.remarks,
    this.followupdate,
    this.followuptime,
    this.purpose,
    this.followupremark,
    this.status,
  });

  factory LeadFollowupData.fromJson(Map<String, dynamic> j) => LeadFollowupData(
        id: _i(j, ['FollowUpId', 'id']),
        leadId: _i(j, ['LeadEntryId', 'leadid']),
        followupno: _i(j, ['FollowUpno', 'followupno']),
        entrydate: _s(j, ['EntryDate', 'entrydate']),
        remarks: _s(j, ['Remarks', 'remarks']),
        followupdate: _s(j, ['FollowUpDate', 'followupdate']),
        followuptime: _s(j, ['FollowUpTime', 'followuptime']),
        purpose: _s(j, ['FollowUpRemark', 'purpose']),
        followupremark: _s(j, ['FollowUpRemark', 'followupremark']),
        status: _s(j, ['Status', 'status']),
      );
}

// ════════════════════════════════ Task row ══════════════════════════════════
class LeadTaskData {
  int? taskId;
  int? leadId;
  String? title;
  String? description;
  String? assigneeName;
  String? dueDate;
  String? priority;
  String? tags;
  String? status;
  String? createdDate;
  String? clientReference;

  LeadTaskData({
    this.taskId,
    this.leadId,
    this.title,
    this.description,
    this.assigneeName,
    this.dueDate,
    this.priority,
    this.tags,
    this.status,
    this.createdDate,
    this.clientReference,
  });

  factory LeadTaskData.fromJson(Map<String, dynamic> j) => LeadTaskData(
        taskId: _i(j, ['TaskId', 'taskid']),
        leadId: _i(j, ['LeadId', 'leadid']),
        title: _s(j, ['TaskTitle', 'tasktitle', 'title']),
        description: _s(j, ['Description', 'description']),
        assigneeName: _s(j, ['AssigneeName', 'assigneename']),
        dueDate: _s(j, ['DueDate', 'duedate']),
        priority: _s(j, ['Priority', 'priority']),
        tags: _s(j, ['Tags', 'tags']),
        status: _s(j, ['Status', 'status']),
        createdDate: _s(j, ['CreatedDate', 'createddate']),
        clientReference: _s(j, ['ClientReference', 'clientreference']),
      );
}

// ════════════════════════════════ Note row ══════════════════════════════════
class LeadNoteData {
  int? noteId;
  int? leadId;
  String? title;
  String? content;
  String? createdOn;

  LeadNoteData({
    this.noteId,
    this.leadId,
    this.title,
    this.content,
    this.createdOn,
  });

  factory LeadNoteData.fromJson(Map<String, dynamic> j) => LeadNoteData(
        noteId: _i(j, ['NoteId', 'noteid']),
        leadId: _i(j, ['LeadId', 'leadid']),
        title: _s(j, ['Title', 'title']),
        content: _s(j, ['Content', 'content']),
        createdOn: _s(j, ['CreatedOn', 'createdon']),
      );
}

// ═══════════════════════════ Estimate / Quotation ═══════════════════════════
class LeadDocData {
  int? leadId;
  int? docId;
  String? docNo;
  String? series;
  String? docDate;
  String? partyName;
  String? remarks;
  double totalQty;
  double totalAmount;
  double totalGst;
  double grandTotal;

  LeadDocData({
    this.leadId,
    this.docId,
    this.docNo,
    this.series,
    this.docDate,
    this.partyName,
    this.remarks,
    this.totalQty = 0,
    this.totalAmount = 0,
    this.totalGst = 0,
    this.grandTotal = 0,
  });

  factory LeadDocData.estimate(Map<String, dynamic> j) => LeadDocData(
        leadId: _i(j, ['LeadId', 'leadid']),
        docId: _i(j, ['EstimateId', 'estimateid']),
        docNo: _s(j, ['EstimateNo', 'estimateno']),
        series: _s(j, ['Series', 'series']),
        docDate: _s(j, ['EstimateDate', 'estimatedate']),
        partyName: _s(j, ['PartyName', 'partyname']),
        remarks: _s(j, ['Remarks', 'remarks']),
        totalQty: _d(j, ['TotalQty']),
        totalAmount: _d(j, ['TotalAmount']),
        totalGst: _d(j, ['TotalGST']),
        grandTotal: _d(j, ['GrandTotal']),
      );

  factory LeadDocData.quotation(Map<String, dynamic> j) => LeadDocData(
        leadId: _i(j, ['LeadId', 'leadid']),
        docId: _i(j, ['quotaionid', 'quotationid']),
        docNo: _s(j, ['quotationno', 'QuotationNo']),
        series: _s(j, ['Series', 'series']),
        docDate: _s(j, ['quotationdate', 'QuotationDate']),
        partyName: _s(j, ['PartyName', 'partyname']),
        remarks: _s(j, ['Remarks', 'remarks']),
        totalQty: _d(j, ['TotalQty']),
        totalAmount: _d(j, ['TotalAmount']),
        totalGst: _d(j, ['TotalGST']),
        grandTotal: _d(j, ['GrandTotal']),
      );
}

// ═══════════════════════════════ Lead item line ═════════════════════════════
class LeadItemData {
  int? transDetailId;
  int? itemId; // itemnamecode
  String? itemName; // itemnamecodetext
  double mrp;
  double amount; // itemamt
  double salePrice;
  double quantity;
  int? billingUnitId; // billingunitid
  String? unit; // billingunit
  String? size; // itemsizename
  String? weight; // itemweightname

  LeadItemData({
    this.transDetailId,
    this.itemId,
    this.itemName,
    this.mrp = 0,
    this.amount = 0,
    this.salePrice = 0,
    this.quantity = 0,
    this.billingUnitId,
    this.unit,
    this.size,
    this.weight,
  });

  factory LeadItemData.fromJson(Map<String, dynamic> j) => LeadItemData(
        transDetailId: _i(j, ['transdetailsid']),
        itemId: _i(j, ['itemnamecode', 'itemid']),
        itemName: _s(j, ['itemnamecodetext', 'itemname']),
        mrp: _d(j, ['Mrp']),
        amount: _d(j, ['itemamt', 'Amount']),
        salePrice: _d(j, ['saleprice']),
        quantity: _d(j, ['Quantity']),
        billingUnitId: _i(j, ['billingunitid']),
        unit: _s(j, ['billingunit']),
        size: _s(j, ['itemsizename']),
        weight: _s(j, ['itemweightname']),
      );
}

// ═════════════════════════════ Dashboard bundle ═════════════════════════════
class LeadBundle {
  List<LeadData> leads;
  List<LeadFollowupData> followups;
  List<LeadTaskData> tasks;
  List<LeadNoteData> notes;
  List<LeadDocData> estimates;
  List<LeadDocData> quotations;

  LeadBundle({
    this.leads = const [],
    this.followups = const [],
    this.tasks = const [],
    this.notes = const [],
    this.estimates = const [],
    this.quotations = const [],
  });

  static List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
      v == null ? <T>[] : List<T>.from((v as List).map((e) => f(e)));

  factory LeadBundle.fromJson(Map<String, dynamic> j) => LeadBundle(
        leads: _list(j['leads'], LeadData.fromJson),
        followups: _list(j['followups'], LeadFollowupData.fromJson),
        tasks: _list(j['tasks'], LeadTaskData.fromJson),
        notes: _list(j['notes'], LeadNoteData.fromJson),
        estimates: _list(j['estimates'], LeadDocData.estimate),
        quotations: _list(j['quotations'], LeadDocData.quotation),
      );
}

class LeadBundleResponse {
  bool? success;
  LeadBundle? data;
  String? message;
  int? status;

  LeadBundleResponse({this.success, this.data, this.message, this.status});

  factory LeadBundleResponse.fromJson(Map<String, dynamic> j) =>
      LeadBundleResponse(
        success: j['success'],
        data: j['data'] == null ? LeadBundle() : LeadBundle.fromJson(j['data']),
        message: j['message'],
        status: j['status'],
      );
}

LeadBundleResponse leadBundleResponseFromJson(String str) =>
    LeadBundleResponse.fromJson(json.decode(str));

// ══════════════════════════════ Lead items response ═════════════════════════
class LeadItemsResponse {
  bool? success;
  LeadData? header;
  Map<String, dynamic>? headerMap; // raw EditLeadEntry header (all fields, for edit prefill)
  List<LeadItemData> items;
  String? message;
  int? status;

  LeadItemsResponse({
    this.success,
    this.header,
    this.headerMap,
    this.items = const [],
    this.message,
    this.status,
  });

  factory LeadItemsResponse.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>?;
    final rawHeader = (data != null && data['header'] is Map)
        ? Map<String, dynamic>.from(data['header'])
        : null;
    return LeadItemsResponse(
      success: j['success'],
      header: rawHeader != null ? LeadData.fromJson(rawHeader) : null,
      headerMap: rawHeader,
      items: (data != null && data['items'] != null)
          ? List<LeadItemData>.from(
              (data['items'] as List).map((e) => LeadItemData.fromJson(e)))
          : <LeadItemData>[],
      message: j['message'],
      status: j['status'],
    );
  }
}

LeadItemsResponse leadItemsResponseFromJson(String str) =>
    LeadItemsResponse.fromJson(json.decode(str));

// ═══════════════════════════ Site Visit (lead) ══════════════════════════════
// /api/lead/visit → the lead's latest site visit + measurements + images,
// mirroring the web Lead Detail "Site Visit" section. visit is null when none.
class LeadVisitInfo {
  final int visitId;
  final String visitNo;
  final String visitDate;
  final String visitedBy;
  final String purposeType;
  final String purpose;
  final String location;
  final String contactPerson;
  final String contactNo;
  final String outcome;
  final String status;
  final String checkIn;
  final String checkOut;

  LeadVisitInfo({
    this.visitId = 0,
    this.visitNo = '',
    this.visitDate = '',
    this.visitedBy = '',
    this.purposeType = '',
    this.purpose = '',
    this.location = '',
    this.contactPerson = '',
    this.contactNo = '',
    this.outcome = '',
    this.status = '',
    this.checkIn = '',
    this.checkOut = '',
  });

  factory LeadVisitInfo.fromJson(Map j) => LeadVisitInfo(
        visitId: _i(j.cast<String, dynamic>(), ['visitId', 'VisitId']) ?? 0,
        visitNo: _s(j.cast<String, dynamic>(), ['visitNo', 'VisitNo']) ?? '',
        visitDate:
            _s(j.cast<String, dynamic>(), ['visitDate', 'VisitDate']) ?? '',
        visitedBy: _s(j.cast<String, dynamic>(),
                ['visitedBy', 'VisitedByName', 'visitedByName']) ??
            '',
        purposeType:
            _s(j.cast<String, dynamic>(), ['purposeType', 'PurposeType']) ?? '',
        purpose: _s(j.cast<String, dynamic>(), ['purpose', 'Purpose']) ?? '',
        location: _s(j.cast<String, dynamic>(), ['location', 'Location']) ?? '',
        contactPerson: _s(j.cast<String, dynamic>(),
                ['contactPerson', 'ContactPerson']) ??
            '',
        contactNo:
            _s(j.cast<String, dynamic>(), ['contactNo', 'ContactNo']) ?? '',
        outcome: _s(j.cast<String, dynamic>(), ['outcome', 'Outcome']) ?? '',
        status: _s(j.cast<String, dynamic>(), ['status', 'Status']) ?? '',
        checkIn: _s(j.cast<String, dynamic>(),
                ['checkIn', 'CheckInText', 'CheckIn']) ??
            '',
        checkOut: _s(j.cast<String, dynamic>(),
                ['checkOut', 'CheckOutText', 'CheckOut']) ??
            '',
      );
}

class LeadVisitMeasure {
  final String itemName;
  final String description;
  final double length;
  final double width;
  final double height;
  final double qty;
  final String unit;
  final double area;
  final String remarks;

  LeadVisitMeasure({
    this.itemName = '',
    this.description = '',
    this.length = 0,
    this.width = 0,
    this.height = 0,
    this.qty = 0,
    this.unit = '',
    this.area = 0,
    this.remarks = '',
  });

  factory LeadVisitMeasure.fromJson(Map j) => LeadVisitMeasure(
        itemName: _s(j.cast<String, dynamic>(), ['ItemName', 'itemName']) ?? '',
        description:
            _s(j.cast<String, dynamic>(), ['Description', 'description']) ?? '',
        length: _d(j.cast<String, dynamic>(), ['Length', 'length']),
        width: _d(j.cast<String, dynamic>(), ['Width', 'width']),
        height: _d(j.cast<String, dynamic>(), ['Height', 'height']),
        qty: _d(j.cast<String, dynamic>(), ['Qty', 'qty']),
        unit: _s(j.cast<String, dynamic>(), ['Unit', 'unit']) ?? '',
        area: _d(j.cast<String, dynamic>(), ['Area', 'area']),
        remarks: _s(j.cast<String, dynamic>(), ['Remarks', 'remarks']) ?? '',
      );
}

class LeadVisitAttachment {
  final String fileName;
  final String fileExt;
  final String url; // presigned; empty when storage not configured

  LeadVisitAttachment({this.fileName = '', this.fileExt = '', this.url = ''});

  factory LeadVisitAttachment.fromJson(Map j) => LeadVisitAttachment(
        fileName: _s(j.cast<String, dynamic>(), ['FileName', 'filename']) ?? '',
        fileExt: _s(j.cast<String, dynamic>(), ['FileExt', 'fileext']) ?? '',
        url: _s(j.cast<String, dynamic>(), ['Url', 'url']) ?? '',
      );

  bool get isImage => const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp']
      .contains(fileExt.toLowerCase());
  bool get openable => url.startsWith('http');
}

class LeadVisitResponse {
  final LeadVisitInfo? visit;
  final List<LeadVisitMeasure> measurements;
  final List<LeadVisitAttachment> attachments;
  final String? message;
  final int? status;

  LeadVisitResponse({
    this.visit,
    this.measurements = const [],
    this.attachments = const [],
    this.message,
    this.status,
  });

  factory LeadVisitResponse.fromJson(Map<String, dynamic> j) {
    final data = j['data'] as Map<String, dynamic>?;
    final v = (data != null && data['visit'] is Map)
        ? LeadVisitInfo.fromJson(Map<String, dynamic>.from(data['visit']))
        : null;
    List<T> lst<T>(dynamic v, T Function(Map) f) =>
        v is List ? v.whereType<Map>().map(f).toList() : <T>[];
    return LeadVisitResponse(
      visit: v,
      measurements:
          lst(data?['measurements'], (m) => LeadVisitMeasure.fromJson(m)),
      attachments:
          lst(data?['attachments'], (a) => LeadVisitAttachment.fromJson(a)),
      message: j['message'],
      status: j['status'],
    );
  }
}

LeadVisitResponse leadVisitResponseFromJson(String str) =>
    LeadVisitResponse.fromJson(json.decode(str));

// ── Legacy aliases kept so older screens still compile ──
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
