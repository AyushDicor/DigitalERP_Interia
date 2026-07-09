// Models for the Performa Invoice (Sale Order) module. The mobile API returns
// camelCase keys inside the standard {success,data,message,status} envelope.

double _d(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';

// ── List row (grid) ──
class SaleOrderListItem {
  final int mainid;
  final String createdby;
  final String createdate;
  final String orderno;
  final String partyname;
  final String buyerorderno;
  final double totalqty;
  final double grandtotal;
  final String currency;
  final String series;

  SaleOrderListItem({
    this.mainid = 0,
    this.createdby = '',
    this.createdate = '',
    this.orderno = '',
    this.partyname = '',
    this.buyerorderno = '',
    this.totalqty = 0,
    this.grandtotal = 0,
    this.currency = '',
    this.series = '',
  });

  factory SaleOrderListItem.fromJson(Map<String, dynamic> j) => SaleOrderListItem(
        mainid: _i(j['mainid']),
        createdby: _s(j['createdby']),
        createdate: _s(j['createdate']),
        orderno: _s(j['orderno']),
        partyname: _s(j['partyname']),
        buyerorderno: _s(j['buyerorderno']),
        totalqty: _d(j['totalqty']),
        grandtotal: _d(j['grandtotal']),
        currency: _s(j['currency']),
        series: _s(j['series']),
      );
}

class SaleOrderListResponse {
  final int status;
  final String message;
  final List<SaleOrderListItem> data;
  SaleOrderListResponse(
      {this.status = 0, this.message = '', this.data = const []});

  factory SaleOrderListResponse.fromJson(Map<String, dynamic> j) =>
      SaleOrderListResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: (j['data'] as List? ?? [])
            .map((e) => SaleOrderListItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

// ── Detail (header + items) ──
class SaleOrderItem {
  final String itemcode;
  final String itemname;
  final String itemsize;
  final double quantity;
  final double salerate;
  final double gstpercent;
  final double gstamount;
  final double amount;
  final String unit;

  SaleOrderItem({
    this.itemcode = '',
    this.itemname = '',
    this.itemsize = '',
    this.quantity = 0,
    this.salerate = 0,
    this.gstpercent = 0,
    this.gstamount = 0,
    this.amount = 0,
    this.unit = '',
  });

  factory SaleOrderItem.fromJson(Map<String, dynamic> j) => SaleOrderItem(
        itemcode: _s(j['itemcode']),
        itemname: _s(j['itemname']),
        itemsize: _s(j['itemsize']),
        quantity: _d(j['quantity']),
        salerate: _d(j['salerate']),
        gstpercent: _d(j['gstpercent']),
        gstamount: _d(j['gstamount']),
        amount: _d(j['amount']),
        unit: _s(j['unit']),
      );
}

class SaleOrderHeader {
  final int mainid;
  final String createdby;
  final String createdate;
  final String orderno;
  final String entrytype;
  final String series;
  final String orderdate;
  final String deliverydate;
  final String partyname;
  final String buyerorderno;
  final String deliverytype;
  final String ordertype;
  final String orderpriority;
  final String orderremarks;
  final String deliveryplace;
  final String dispatchthrough;
  final String destination;
  final String currency;
  final String billtoaddress;
  final String shiptoaddress;
  final String gstno;
  final String mobileno;
  final double totalqty;
  final double totalamount;
  final double totalgst;
  final double roundoff;
  final double grandtotal;
  final String terms;

  SaleOrderHeader({
    this.mainid = 0,
    this.createdby = '',
    this.createdate = '',
    this.orderno = '',
    this.entrytype = '',
    this.series = '',
    this.orderdate = '',
    this.deliverydate = '',
    this.partyname = '',
    this.buyerorderno = '',
    this.deliverytype = '',
    this.ordertype = '',
    this.orderpriority = '',
    this.orderremarks = '',
    this.deliveryplace = '',
    this.dispatchthrough = '',
    this.destination = '',
    this.currency = '',
    this.billtoaddress = '',
    this.shiptoaddress = '',
    this.gstno = '',
    this.mobileno = '',
    this.totalqty = 0,
    this.totalamount = 0,
    this.totalgst = 0,
    this.roundoff = 0,
    this.grandtotal = 0,
    this.terms = '',
  });

  factory SaleOrderHeader.fromJson(Map<String, dynamic> j) => SaleOrderHeader(
        mainid: _i(j['mainid']),
        createdby: _s(j['createdby']),
        createdate: _s(j['createdate']),
        orderno: _s(j['orderno']),
        entrytype: _s(j['entrytype']),
        series: _s(j['series']),
        orderdate: _s(j['orderdate']),
        deliverydate: _s(j['deliverydate']),
        partyname: _s(j['partyname']),
        buyerorderno: _s(j['buyerorderno']),
        deliverytype: _s(j['deliverytype']),
        ordertype: _s(j['ordertype']),
        orderpriority: _s(j['orderpriority']),
        orderremarks: _s(j['orderremarks']),
        deliveryplace: _s(j['deliveryplace']),
        dispatchthrough: _s(j['dispatchthrough']),
        destination: _s(j['destination']),
        currency: _s(j['currency']),
        billtoaddress: _s(j['billtoaddress']),
        shiptoaddress: _s(j['shiptoaddress']),
        gstno: _s(j['gstno']),
        mobileno: _s(j['mobileno']),
        totalqty: _d(j['totalqty']),
        totalamount: _d(j['totalamount']),
        totalgst: _d(j['totalgst']),
        roundoff: _d(j['roundoff']),
        grandtotal: _d(j['grandtotal']),
        terms: _s(j['terms']),
      );
}

class SaleOrderDetailResponse {
  final int status;
  final String message;
  final SaleOrderHeader? header;
  final List<SaleOrderItem> items;
  SaleOrderDetailResponse(
      {this.status = 0, this.message = '', this.header, this.items = const []});

  factory SaleOrderDetailResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map?) ?? {};
    final h = data['header'];
    return SaleOrderDetailResponse(
      status: _i(j['status']),
      message: _s(j['message']),
      header: h == null
          ? null
          : SaleOrderHeader.fromJson(Map<String, dynamic>.from(h as Map)),
      items: (data['items'] as List? ?? [])
          .map((e) =>
              SaleOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
