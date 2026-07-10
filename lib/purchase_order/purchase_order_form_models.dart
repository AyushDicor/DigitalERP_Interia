// Models for the Purchase Order CREATE form: {id,name} options, the dropdown
// bundle, item lines (with fixed rate + line discount), other-expense lines,
// and the party auto-fill payload.

import 'dart:convert';

int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';

class PoOption {
  final int id;
  final String name;
  PoOption({this.id = 0, this.name = ''});
  factory PoOption.fromJson(Map<String, dynamic> j) =>
      PoOption(id: _i(j['id']), name: _s(j['name']));
}

List<PoOption> _opts(dynamic list) => (list as List? ?? [])
    .map((e) => PoOption.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();

class PoFormData {
  final List<PoOption> entrytype;
  final List<PoOption> series;
  final List<PoOption> currency;
  final List<PoOption> deliverytype;
  final List<PoOption> transportname;
  final List<PoOption> billingunit;
  final List<PoOption> othertype;
  final List<PoOption> itemsize;
  final List<PoOption> freightmode;
  final List<PoOption> paymentmode;
  final List<PoOption> transactiontype;
  final List<PoOption> transportmode;
  final List<PoOption> deliverystore;
  final List<PoOption> partycategory;

  PoFormData({
    this.entrytype = const [],
    this.series = const [],
    this.currency = const [],
    this.deliverytype = const [],
    this.transportname = const [],
    this.billingunit = const [],
    this.othertype = const [],
    this.itemsize = const [],
    this.freightmode = const [],
    this.paymentmode = const [],
    this.transactiontype = const [],
    this.transportmode = const [],
    this.deliverystore = const [],
    this.partycategory = const [],
  });

  factory PoFormData.fromJson(Map<String, dynamic> j) => PoFormData(
        entrytype: _opts(j['entrytype']),
        series: _opts(j['series']),
        currency: _opts(j['currency']),
        deliverytype: _opts(j['deliverytype']),
        transportname: _opts(j['transportname']),
        billingunit: _opts(j['billingunit']),
        othertype: _opts(j['othertype']),
        itemsize: _opts(j['itemsize']),
        freightmode: _opts(j['freightmode']),
        paymentmode: _opts(j['paymentmode']),
        transactiontype: _opts(j['transactiontype']),
        transportmode: _opts(j['transportmode']),
        deliverystore: _opts(j['deliverystore']),
        partycategory: _opts(j['partycategory']),
      );
}

class PoFormResponse {
  final int status;
  final String message;
  final PoFormData data;
  PoFormResponse({this.status = 0, this.message = '', PoFormData? data})
      : data = data ?? PoFormData();
  factory PoFormResponse.fromJson(Map<String, dynamic> j) => PoFormResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: PoFormData.fromJson(
            Map<String, dynamic>.from((j['data'] as Map?) ?? {})),
      );
}

// Generic {data:[{id,name}]} list response — party names / store contacts / items.
class PoOptionListResponse {
  final int status;
  final String message;
  final List<PoOption> data;
  PoOptionListResponse({this.status = 0, this.message = '', this.data = const []});
  factory PoOptionListResponse.fromJson(Map<String, dynamic> j) =>
      PoOptionListResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: _opts(j['data']),
      );
}

class PoPartyDetail {
  final String billtoaddress;
  final String shiptoaddress;
  final String gstno;
  final String mobileno;
  PoPartyDetail(
      {this.billtoaddress = '',
      this.shiptoaddress = '',
      this.gstno = '',
      this.mobileno = ''});
  factory PoPartyDetail.fromJson(Map<String, dynamic> j) => PoPartyDetail(
        billtoaddress: _s(j['billtoaddress']),
        shiptoaddress: _s(j['shiptoaddress']),
        gstno: _s(j['gstno']),
        mobileno: _s(j['mobileno']),
      );
}

class PoPartyDetailResponse {
  final int status;
  final PoPartyDetail? party;
  PoPartyDetailResponse({this.status = 0, this.party});
  factory PoPartyDetailResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map?) ?? {};
    final party = data['party'];
    return PoPartyDetailResponse(
      status: _i(j['status']),
      party: party == null
          ? null
          : PoPartyDetail.fromJson(Map<String, dynamic>.from(party as Map)),
    );
  }
}

// ── Editable form lines ──
class PoItemLine {
  int itemid;
  String itemname;
  int sizeid;
  String sizename;
  double quantity;
  double fixedrate;
  double rate;
  double discountpercent;
  double gstpercent;
  int billingunitid;
  String billingunit;
  String itemdescription;

  PoItemLine({
    this.itemid = 0,
    this.itemname = '',
    this.sizeid = 0,
    this.sizename = '',
    this.quantity = 0,
    this.fixedrate = 0,
    this.rate = 0,
    this.discountpercent = 0,
    this.gstpercent = 0,
    this.billingunitid = 0,
    this.billingunit = '',
    this.itemdescription = '',
  });

  double get grossAmount => quantity * rate;
  double get discountAmount => grossAmount * discountpercent / 100;
  double get amount => grossAmount - discountAmount;
  double get gstAmount => amount * gstpercent / 100;

  Map<String, dynamic> toJson() => {
        'itemid': itemid,
        'itemname': itemname,
        'sizeid': sizeid,
        'sizename': sizename,
        'quantity': quantity,
        'fixedrate': fixedrate,
        'mrp': fixedrate,
        'rate': rate,
        'salerate': rate,
        'discountpercent': discountpercent,
        'discountamount': discountAmount,
        'gstpercent': gstpercent,
        'gstamount': gstAmount,
        'amount': amount,
        'billingunitid': billingunitid,
        'billingunit': billingunit,
        'itemdescription': itemdescription,
      };
}

class PoOtherExpense {
  String nature;
  int accounttypeid;
  String accounttype;
  double taxpercent;
  double amount;

  PoOtherExpense({
    this.nature = '',
    this.accounttypeid = 0,
    this.accounttype = '',
    this.taxpercent = 0,
    this.amount = 0,
  });

  Map<String, dynamic> toJson() => {
        'nature': nature,
        'accounttypeid': accounttypeid,
        'accounttype': accounttype,
        'taxpercent': taxpercent,
        'amount': amount,
      };
}

String encodePoItems(List<PoItemLine> items) =>
    jsonEncode(items.map((e) => e.toJson()).toList());
String encodePoOthers(List<PoOtherExpense> others) =>
    jsonEncode(others.map((e) => e.toJson()).toList());
