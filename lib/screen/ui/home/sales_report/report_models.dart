import 'dart:convert';

ReportResponse reportResponseFromJson(String s) =>
    ReportResponse.fromJson(json.decode(s));
ReportDetailResponse reportDetailResponseFromJson(String s) =>
    ReportDetailResponse.fromJson(json.decode(s));

// ── List ─────────────────────────────────────────────────────────────────────
class ReportResponse {
  bool? success;
  ReportData? data;
  String? message;
  int? status;
  ReportResponse({this.success, this.data, this.message, this.status});
  factory ReportResponse.fromJson(Map<String, dynamic> j) => ReportResponse(
        success: j['success'],
        data: j['data'] == null ? null : ReportData.fromJson(j['data']),
        message: j['message'],
        status: j['status'],
      );
}

class ReportData {
  List<ReportRow> rows;
  ReportSummary summary;
  ReportData({this.rows = const [], ReportSummary? summary})
      : summary = summary ?? ReportSummary();
  factory ReportData.fromJson(Map<String, dynamic> j) => ReportData(
        rows: (j['rows'] as List<dynamic>?)
                ?.map((e) => ReportRow.fromJson(e))
                .toList() ??
            [],
        summary: j['summary'] == null
            ? ReportSummary()
            : ReportSummary.fromJson(j['summary']),
      );
}

class ReportRow {
  int? id;
  String? no;
  String? date;
  String? party;
  int? partyid;
  num? amount;
  num? quantity;
  String? executive;
  String? status;
  ReportRow({this.id, this.no, this.date, this.party, this.partyid,
      this.amount, this.quantity, this.executive, this.status});
  factory ReportRow.fromJson(Map<String, dynamic> j) => ReportRow(
        id: j['id'],
        no: j['no'],
        date: j['date'],
        party: j['party'],
        partyid: j['partyid'],
        amount: j['amount'],
        quantity: j['quantity'],
        executive: j['executive'],
        status: j['status'],
      );
}

class ReportSummary {
  num totalcount;
  num totalamount;
  ReportSummary({this.totalcount = 0, this.totalamount = 0});
  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
        totalcount: j['totalcount'] ?? 0,
        totalamount: j['totalamount'] ?? 0,
      );
}

// ── Detail ───────────────────────────────────────────────────────────────────
class ReportDetailResponse {
  bool? success;
  ReportDetailData? data;
  String? message;
  int? status;
  ReportDetailResponse({this.success, this.data, this.message, this.status});
  factory ReportDetailResponse.fromJson(Map<String, dynamic> j) =>
      ReportDetailResponse(
        success: j['success'],
        data: j['data'] == null ? null : ReportDetailData.fromJson(j['data']),
        message: j['message'],
        status: j['status'],
      );
}

class ReportDetailData {
  ReportHeader? header;
  List<ReportItem> items;
  ReportDetailData({this.header, this.items = const []});
  factory ReportDetailData.fromJson(Map<String, dynamic> j) => ReportDetailData(
        header: j['header'] == null ? null : ReportHeader.fromJson(j['header']),
        items: (j['items'] as List<dynamic>?)
                ?.map((e) => ReportItem.fromJson(e))
                .toList() ??
            [],
      );
}

class ReportHeader {
  int? id;
  String? no;
  String? date;
  String? party;
  num? grandtotal;
  num? totalamount;
  num? totalqty;
  String? formtype;
  String? status;
  String? executive;
  ReportHeader({this.id, this.no, this.date, this.party, this.grandtotal,
      this.totalamount, this.totalqty, this.formtype, this.status, this.executive});
  factory ReportHeader.fromJson(Map<String, dynamic> j) => ReportHeader(
        id: j['id'],
        no: j['no'],
        date: j['date'],
        party: j['party'],
        grandtotal: j['grandtotal'],
        totalamount: j['totalamount'],
        totalqty: j['totalqty'],
        formtype: j['formtype'],
        status: j['status'],
        executive: j['executive'],
      );
}

class ReportItem {
  int? sno;
  String? itemname;
  num? quantity;
  num? rate;
  num? amount;
  ReportItem({this.sno, this.itemname, this.quantity, this.rate, this.amount});
  factory ReportItem.fromJson(Map<String, dynamic> j) => ReportItem(
        sno: j['sno'],
        itemname: j['itemname'],
        quantity: j['quantity'],
        rate: j['rate'],
        amount: j['amount'],
      );
}
