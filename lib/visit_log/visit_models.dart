// Models for the Visit module (rebuilt to match the web ERP flow).
//
// Endpoints (all POST, X-Api-Key, envelope {success,data,message,status}):
//   visit/list       -> list of VisitListItem
//   visit/pending    -> {data:[PendingVisitItem]}  (nested under data.data)
//   visit/openleads  -> {data:[{value,text}]}       (nested under data.data)
//   visit/dropdowns  -> {purposeTypes,statuses,travelModes}
//   visit/detail     -> {visit, measurements, attachments, followups}
//   visit/save       -> {id, visitno}
//   visit/delete, visit/followups, visit/addfollowup
// Attachments use the shared AttachmentRepo (modulekey "Visit").

import 'package:newdigitalerp/repo/attachment_repo.dart';

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

int _int(dynamic v) => _num(v).toInt();
double _dbl(dynamic v) => _num(v).toDouble();
String _str(dynamic v) => (v ?? '').toString();

/// One row in the visit log list.
class VisitListItem {
  final int id;
  final String visitNo;
  final String visitDate; // "08 Sep 2026"
  final String visitedByName;
  final String visitTo;
  final String purposeType;
  final String location;
  final String contactPerson;
  final String status;
  // A "Planned" row can be a pending enquiry (Id 0, IsEnquiry 1) that carries a
  // LeadId — tapping it should start a NEW visit for that enquiry, not open a
  // (non-existent) detail.
  final int leadId;
  final bool isEnquiry;

  VisitListItem({
    required this.id,
    required this.visitNo,
    required this.visitDate,
    required this.visitedByName,
    required this.visitTo,
    required this.purposeType,
    required this.location,
    required this.contactPerson,
    required this.status,
    this.leadId = 0,
    this.isEnquiry = false,
  });

  factory VisitListItem.fromJson(Map j) => VisitListItem(
        id: _int(j['Id']),
        visitNo: _str(j['VisitNo']),
        visitDate: _str(j['VisitDate']),
        visitedByName: _str(j['VisitedByName']),
        visitTo: _str(j['VisitTo']),
        purposeType: _str(j['PurposeType']),
        location: _str(j['Location']),
        contactPerson: _str(j['ContactPerson']),
        status: _str(j['Status']),
        leadId: _int(j['LeadId']),
        isEnquiry: _int(j['IsEnquiry']) == 1 || _int(j['Id']) == 0,
      );
}

/// A pending enquiry that still needs a site visit. Id is 0; carries LeadId.
class PendingVisitItem {
  final int leadId;
  final String visitNo; // actually the enquiry no, e.g. ENQ/2026-27/12
  final String visitDate;
  final String visitedByName;
  final String visitTo;
  final String purposeType;
  final String contactPerson;
  final String status;

  PendingVisitItem({
    required this.leadId,
    required this.visitNo,
    required this.visitDate,
    required this.visitedByName,
    required this.visitTo,
    required this.purposeType,
    required this.contactPerson,
    required this.status,
  });

  factory PendingVisitItem.fromJson(Map j) => PendingVisitItem(
        leadId: _int(j['LeadId']),
        visitNo: _str(j['VisitNo']),
        visitDate: _str(j['VisitDate']),
        visitedByName: _str(j['VisitedByName']),
        visitTo: _str(j['VisitTo']),
        purposeType: _str(j['PurposeType']),
        contactPerson: _str(j['ContactPerson']),
        status: _str(j['Status']),
      );
}

/// "For Enquiry / Lead" picker option.
class OpenLead {
  final int value;
  final String text;
  OpenLead({required this.value, required this.text});
  factory OpenLead.fromJson(Map j) =>
      OpenLead(value: _int(j['value']), text: _str(j['text']));
}

class VisitDropdowns {
  final List<String> purposeTypes;
  final List<String> statuses;
  final List<String> travelModes;

  VisitDropdowns({
    required this.purposeTypes,
    required this.statuses,
    required this.travelModes,
  });

  factory VisitDropdowns.fromJson(Map j) => VisitDropdowns(
        purposeTypes: _strList(j['purposeTypes']),
        statuses: _strList(j['statuses']),
        travelModes: _strList(j['travelModes']),
      );

  static VisitDropdowns get fallback => VisitDropdowns(
        purposeTypes: const [
          'Sales', 'Service', 'Collection', 'Meeting', 'Delivery',
          'Follow-up', 'Other'
        ],
        statuses: const ['Completed', 'Planned', 'Cancelled'],
        travelModes: const [
          'Car', 'Bike', 'Cab', 'Bus', 'Train', 'Flight', 'Own Vehicle',
          'Walk', 'Other'
        ],
      );

  static List<String> _strList(dynamic v) =>
      (v is List) ? v.map((e) => e.toString()).toList() : <String>[];
}

/// One site-measurement line. Read keys are PascalCase; save keys lowercase.
class VisitMeasurement {
  String itemName;
  String description;
  double length;
  double width;
  double height;
  double qty;
  String unit;
  double area;
  String remarks;

  VisitMeasurement({
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

  factory VisitMeasurement.fromJson(Map j) => VisitMeasurement(
        itemName: _str(j['ItemName']),
        description: _str(j['Description']),
        length: _dbl(j['Length']),
        width: _dbl(j['Width']),
        height: _dbl(j['Height']),
        qty: _dbl(j['Qty']),
        unit: _str(j['Unit']),
        area: _dbl(j['Area']),
        remarks: _str(j['Remarks']),
      );

  // Lowercase keys, as visit/save expects inside the measurements JSON array.
  Map<String, dynamic> toSaveJson() => {
        'itemname': itemName,
        'description': description,
        'length': length,
        'width': width,
        'height': height,
        'qty': qty,
        'unit': unit,
        'area': area,
        'remarks': remarks,
      };

  bool get isEmpty =>
      itemName.trim().isEmpty &&
      description.trim().isEmpty &&
      length == 0 &&
      width == 0 &&
      height == 0 &&
      qty == 0;
}

class VisitFollowup {
  final int id;
  final String comment;
  final String createdByName;
  final String createdAt;

  VisitFollowup({
    required this.id,
    required this.comment,
    required this.createdByName,
    required this.createdAt,
  });

  factory VisitFollowup.fromJson(Map j) => VisitFollowup(
        id: _int(j['Id']),
        comment: _str(j['Comment']),
        createdByName: _str(j['CreatedByName']),
        createdAt: _str(j['CreatedAt']),
      );
}

/// The `visit` block of visit/detail — everything needed to render + edit.
class VisitRecord {
  final int id;
  final int compId;
  final int branchId;
  final String visitNo;
  final String visitDate; // ISO "2026-09-08T00:00:00"
  final int visitedById;
  final String visitedByName;
  final int partyId;
  final String visitTo;
  final String purposeType;
  final String purpose;
  final String location;
  final String contactPerson;
  final String contactNo;
  final String checkInTime;
  final String checkOutTime;
  final double distanceKm;
  final String travelMode;
  final String outcome;
  final String status;
  final double latitude;
  final double longitude;
  final int leadId;

  VisitRecord({
    required this.id,
    required this.compId,
    required this.branchId,
    required this.visitNo,
    required this.visitDate,
    required this.visitedById,
    required this.visitedByName,
    required this.partyId,
    required this.visitTo,
    required this.purposeType,
    required this.purpose,
    required this.location,
    required this.contactPerson,
    required this.contactNo,
    required this.checkInTime,
    required this.checkOutTime,
    required this.distanceKm,
    required this.travelMode,
    required this.outcome,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.leadId,
  });

  factory VisitRecord.fromJson(Map j) => VisitRecord(
        id: _int(j['Id']),
        compId: _int(j['CompId']),
        branchId: _int(j['BranchId']),
        visitNo: _str(j['VisitNo']),
        visitDate: _str(j['VisitDate']),
        visitedById: _int(j['VisitedById']),
        visitedByName: _str(j['VisitedByName']),
        partyId: _int(j['PartyId']),
        visitTo: _str(j['VisitTo']),
        purposeType: _str(j['PurposeType']),
        purpose: _str(j['Purpose']),
        location: _str(j['Location']),
        contactPerson: _str(j['ContactPerson']),
        contactNo: _str(j['ContactNo']),
        checkInTime: _str(j['CheckInTime']),
        checkOutTime: _str(j['CheckOutTime']),
        distanceKm: _dbl(j['DistanceKm']),
        travelMode: _str(j['TravelMode']),
        outcome: _str(j['Outcome']),
        status: _str(j['Status']),
        latitude: _dbl(j['Latitude']),
        longitude: _dbl(j['Longitude']),
        leadId: _int(j['LeadId']),
      );
}

class VisitDetail {
  final VisitRecord? visit;
  final List<VisitMeasurement> measurements;
  final List<AttachmentItem> attachments;
  final List<VisitFollowup> followups;

  VisitDetail({
    required this.visit,
    required this.measurements,
    required this.attachments,
    required this.followups,
  });

  factory VisitDetail.fromJson(Map j) {
    final v = j['visit'];
    return VisitDetail(
      visit: v is Map ? VisitRecord.fromJson(v) : null,
      measurements: _list(j['measurements'])
          .map((e) => VisitMeasurement.fromJson(e))
          .toList(),
      attachments:
          _list(j['attachments']).map((e) => AttachmentItem.fromJson(e)).toList(),
      followups:
          _list(j['followups']).map((e) => VisitFollowup.fromJson(e)).toList(),
    );
  }

  static List<Map> _list(dynamic v) =>
      (v is List) ? v.whereType<Map>().toList() : <Map>[];
}

/// Result of visit/save.
class SaveVisitResult {
  final bool success;
  final int status;
  final String message;
  final int id;
  final String visitNo;

  SaveVisitResult({
    required this.success,
    required this.status,
    required this.message,
    required this.id,
    required this.visitNo,
  });

  factory SaveVisitResult.fromJson(Map j) {
    final d = (j['data'] is Map) ? j['data'] as Map : const {};
    return SaveVisitResult(
      success: j['success'] == true,
      status: _int(j['status']),
      message: _str(j['message']),
      id: _int(d['id']),
      visitNo: _str(d['visitno']),
    );
  }
}
