// Models for the Performa Invoice (Sale Order) CREATE form: {id,name} options,
// the dropdown bundle, item lines, other-expense lines, party auto-fill.

import 'dart:convert';

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';

class SaleOrderOption {
  final int id;
  final String name;
  SaleOrderOption({this.id = 0, this.name = ''});
  factory SaleOrderOption.fromJson(Map<String, dynamic> j) =>
      SaleOrderOption(id: _i(j['id']), name: _s(j['name']));
}

List<SaleOrderOption> _opts(dynamic list) => (list as List? ?? [])
    .map((e) => SaleOrderOption.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();

double _d(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

// Other-expense ledger ("Other Type") carrying its tax % (from partymaster.Valuepercent).
class SaleOrderLedger {
  final int id;
  final String name;
  final double taxper;
  SaleOrderLedger({this.id = 0, this.name = '', this.taxper = 0});
  factory SaleOrderLedger.fromJson(Map<String, dynamic> j) => SaleOrderLedger(
        id: _i(j['id']),
        name: _s(j['name']),
        taxper: _d(j['taxper']),
      );
}

List<SaleOrderLedger> _ledgers(dynamic list) => (list as List? ?? [])
    .map((e) => SaleOrderLedger.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();

class SaleOrderFormData {
  final List<SaleOrderOption> entrytype;
  final List<SaleOrderOption> series;
  final List<SaleOrderOption> priority;
  final List<SaleOrderOption> currency;
  final List<SaleOrderOption> deliverytype;
  final List<SaleOrderOption> ordertype;
  final List<SaleOrderOption> transportname;
  final List<SaleOrderOption> billingunit;
  final List<SaleOrderOption> othertype;
  final List<SaleOrderOption> itemsize;
  final List<SaleOrderOption> deliverystore;
  final List<SaleOrderOption> partycategory;
  final List<SaleOrderOption> godown;
  final List<SaleOrderLedger> otherledger;

  SaleOrderFormData({
    this.entrytype = const [],
    this.series = const [],
    this.priority = const [],
    this.currency = const [],
    this.deliverytype = const [],
    this.ordertype = const [],
    this.transportname = const [],
    this.billingunit = const [],
    this.othertype = const [],
    this.itemsize = const [],
    this.deliverystore = const [],
    this.partycategory = const [],
    this.godown = const [],
    this.otherledger = const [],
  });

  factory SaleOrderFormData.fromJson(Map<String, dynamic> j) => SaleOrderFormData(
        entrytype: _opts(j['entrytype']),
        series: _opts(j['series']),
        priority: _opts(j['priority']),
        currency: _opts(j['currency']),
        deliverytype: _opts(j['deliverytype']),
        ordertype: _opts(j['ordertype']),
        transportname: _opts(j['transportname']),
        billingunit: _opts(j['billingunit']),
        othertype: _opts(j['othertype']),
        itemsize: _opts(j['itemsize']),
        deliverystore: _opts(j['deliverystore']),
        partycategory: _opts(j['partycategory']),
        godown: _opts(j['godown']),
        otherledger: _ledgers(j['otherledger']),
      );
}

class SaleOrderFormResponse {
  final int status;
  final String message;
  final SaleOrderFormData data;
  SaleOrderFormResponse(
      {this.status = 0, this.message = '', SaleOrderFormData? data})
      : data = data ?? SaleOrderFormData();
  factory SaleOrderFormResponse.fromJson(Map<String, dynamic> j) =>
      SaleOrderFormResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: SaleOrderFormData.fromJson(
            Map<String, dynamic>.from((j['data'] as Map?) ?? {})),
      );
}

// Generic {data:[{id,name}]} list response used for party names / store contacts / items.
class SaleOrderOptionListResponse {
  final int status;
  final String message;
  final List<SaleOrderOption> data;
  SaleOrderOptionListResponse(
      {this.status = 0, this.message = '', this.data = const []});
  factory SaleOrderOptionListResponse.fromJson(Map<String, dynamic> j) =>
      SaleOrderOptionListResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: _opts(j['data']),
      );
}

class SaleOrderPartyDetail {
  final String billtoaddress;
  final String shiptoaddress;
  final String gstno;
  final String mobileno;
  SaleOrderPartyDetail(
      {this.billtoaddress = '',
      this.shiptoaddress = '',
      this.gstno = '',
      this.mobileno = ''});
  factory SaleOrderPartyDetail.fromJson(Map<String, dynamic> j) =>
      SaleOrderPartyDetail(
        billtoaddress: _s(j['billtoaddress']),
        shiptoaddress: _s(j['shiptoaddress']),
        gstno: _s(j['gstno']),
        mobileno: _s(j['mobileno']),
      );
}

class SaleOrderPartyDetailResponse {
  final int status;
  final SaleOrderPartyDetail? party;
  SaleOrderPartyDetailResponse({this.status = 0, this.party});
  factory SaleOrderPartyDetailResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map?) ?? {};
    final party = data['party'];
    return SaleOrderPartyDetailResponse(
      status: _i(j['status']),
      party: party == null
          ? null
          : SaleOrderPartyDetail.fromJson(Map<String, dynamic>.from(party as Map)),
    );
  }
}

// ── Editable form lines ──
class SaleOrderItemLine {
  int itemid;
  String itemname;
  int sizeid;
  String sizename;
  double quantity;
  double salerate;
  double gstpercent;
  int billingunitid;
  String billingunit;
  String itemdescription;
  int godownid;
  String godownname;
  double discountpercent;

  SaleOrderItemLine({
    this.itemid = 0,
    this.itemname = '',
    this.sizeid = 0,
    this.sizename = '',
    this.quantity = 0,
    this.salerate = 0,
    this.gstpercent = 0,
    this.billingunitid = 0,
    this.billingunit = '',
    this.itemdescription = '',
    this.godownid = 0,
    this.godownname = '',
    this.discountpercent = 0,
  });

  // ERP math (calculateTotals): discount reduces the base BEFORE GST, so
  // Amount = qty*rate − discount, and GST is charged on that net amount.
  double get baseAmount => quantity * salerate;
  double get discountAmount => baseAmount * discountpercent / 100;
  double get amount => baseAmount - discountAmount;
  double get gstAmount => amount * gstpercent / 100;

  Map<String, dynamic> toJson() => {
        'itemid': itemid,
        'itemname': itemname,
        'sizeid': sizeid,
        'sizename': sizename,
        'quantity': quantity,
        'mrp': salerate,
        'salerate': salerate,
        'gstpercent': gstpercent,
        'gstamount': gstAmount,
        'amount': amount,
        'billingunitid': billingunitid,
        'billingunit': billingunit,
        'itemdescription': itemdescription,
        'godownid': godownid,
        'godownname': godownname,
        'discountpercent': discountpercent,
        'discountamount': discountAmount,
      };
}

class SaleOrderOtherExpense {
  String nature; // "Add" or "Less"
  int accounttypeid; // ledger partyid (Other Type)
  String accounttype; // ledger name
  double taxpercent;
  double amount;
  int dependentid; // 0 = Total Amount / Grand Total (ERP saves both as 0)

  SaleOrderOtherExpense({
    this.nature = '',
    this.accounttypeid = 0,
    this.accounttype = '',
    this.taxpercent = 0,
    this.amount = 0,
    this.dependentid = 0,
  });

  // Signed effect on the grand total: Add = +amount, Less = −amount.
  double get signedAmount => nature.toLowerCase() == 'less' ? -amount : amount;

  Map<String, dynamic> toJson() => {
        'nature': nature,
        'accounttypeid': accounttypeid,
        'accounttype': accounttype,
        'taxpercent': taxpercent,
        'amount': amount,
        'dependentid': dependentid,
      };
}

String encodeItems(List<SaleOrderItemLine> items) =>
    jsonEncode(items.map((e) => e.toJson()).toList());
String encodeOthers(List<SaleOrderOtherExpense> others) =>
    jsonEncode(others.map((e) => e.toJson()).toList());
