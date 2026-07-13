// Models for "Pending Indent for PO": the pending-indent grid rows and the seed
// payload (indent header + item lines) used to pre-fill the PO create form.
// The mobile API returns camelCase keys inside {success,data,message,status}.

double _d(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';

// ── Pending indent grid row ──
class PendingIndentItem {
  final int indentid;
  final String indentno;
  final String createdate;
  final String seriestype;
  final String reqby;
  final String requestto;
  final String plant;
  final double totalqty;

  PendingIndentItem({
    this.indentid = 0,
    this.indentno = '',
    this.createdate = '',
    this.seriestype = '',
    this.reqby = '',
    this.requestto = '',
    this.plant = '',
    this.totalqty = 0,
  });

  factory PendingIndentItem.fromJson(Map<String, dynamic> j) =>
      PendingIndentItem(
        indentid: _i(j['indentid']),
        indentno: _s(j['indentno']),
        createdate: _s(j['createdate']),
        seriestype: _s(j['seriestype']),
        reqby: _s(j['reqby']),
        requestto: _s(j['requestto']),
        plant: _s(j['plant']),
        totalqty: _d(j['totalqty']),
      );
}

class PendingIndentListResponse {
  final int status;
  final String message;
  final List<PendingIndentItem> data;
  PendingIndentListResponse(
      {this.status = 0, this.message = '', this.data = const []});

  factory PendingIndentListResponse.fromJson(Map<String, dynamic> j) =>
      PendingIndentListResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: (j['data'] as List? ?? [])
            .map((e) =>
                PendingIndentItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

// ── Seed (indent → PO form) ──
class IndentSeedHeader {
  final int indentid;
  final String indentno;
  final String indentdate;
  final String deliverydate;
  final String itemremarks;
  final String reqby;
  final String requestto;
  final int deliverystoreid;
  final int branchid;
  final double totalqty;

  IndentSeedHeader({
    this.indentid = 0,
    this.indentno = '',
    this.indentdate = '',
    this.deliverydate = '',
    this.itemremarks = '',
    this.reqby = '',
    this.requestto = '',
    this.deliverystoreid = 0,
    this.branchid = 0,
    this.totalqty = 0,
  });

  factory IndentSeedHeader.fromJson(Map<String, dynamic> j) => IndentSeedHeader(
        indentid: _i(j['indentid']),
        indentno: _s(j['indentno']),
        indentdate: _s(j['indentdate']),
        deliverydate: _s(j['deliverydate']),
        itemremarks: _s(j['itemremarks']),
        reqby: _s(j['reqby']),
        requestto: _s(j['requestto']),
        deliverystoreid: _i(j['deliverystoreid']),
        branchid: _i(j['branchid']),
        totalqty: _d(j['totalqty']),
      );
}

class IndentSeedItem {
  final int itemid;
  final String itemname;
  final double quantity;
  final double rate;
  final double fixedrate;
  final double gstpercent;
  final double discountpercent;
  final int billingunitid;
  final String billingunit;
  final String itemdescription;

  IndentSeedItem({
    this.itemid = 0,
    this.itemname = '',
    this.quantity = 0,
    this.rate = 0,
    this.fixedrate = 0,
    this.gstpercent = 0,
    this.discountpercent = 0,
    this.billingunitid = 0,
    this.billingunit = '',
    this.itemdescription = '',
  });

  factory IndentSeedItem.fromJson(Map<String, dynamic> j) => IndentSeedItem(
        itemid: _i(j['itemid']),
        itemname: _s(j['itemname']),
        quantity: _d(j['quantity']),
        rate: _d(j['rate']),
        fixedrate: _d(j['fixedrate']),
        gstpercent: _d(j['gstpercent']),
        discountpercent: _d(j['discountpercent']),
        billingunitid: _i(j['billingunitid']),
        billingunit: _s(j['billingunit']),
        itemdescription: _s(j['itemdescription']),
      );
}

class IndentSeedResponse {
  final int status;
  final String message;
  final IndentSeedHeader? header;
  final List<IndentSeedItem> items;
  IndentSeedResponse(
      {this.status = 0, this.message = '', this.header, this.items = const []});

  factory IndentSeedResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map?) ?? {};
    final h = data['header'];
    return IndentSeedResponse(
      status: _i(j['status']),
      message: _s(j['message']),
      header: h == null
          ? null
          : IndentSeedHeader.fromJson(Map<String, dynamic>.from(h as Map)),
      items: (data['items'] as List? ?? [])
          .map((e) =>
              IndentSeedItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
