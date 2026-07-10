// Models for the Purchase Order module. The mobile API returns camelCase keys
// inside the standard {success,data,message,status} envelope.

double _d(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _i(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : '$v';

// ── List row (grid) ──
class PurchaseOrderListItem {
  final int mainid;
  final String createdby;
  final String createdate;
  final String orderno;
  final String partyname;
  final String entrytype;
  final double totalqty;
  final double grandtotal;
  final String currency;
  final String series;

  PurchaseOrderListItem({
    this.mainid = 0,
    this.createdby = '',
    this.createdate = '',
    this.orderno = '',
    this.partyname = '',
    this.entrytype = '',
    this.totalqty = 0,
    this.grandtotal = 0,
    this.currency = '',
    this.series = '',
  });

  factory PurchaseOrderListItem.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderListItem(
        mainid: _i(j['mainid']),
        createdby: _s(j['createdby']),
        createdate: _s(j['createdate']),
        orderno: _s(j['orderno']),
        partyname: _s(j['partyname']),
        entrytype: _s(j['entrytype']),
        totalqty: _d(j['totalqty']),
        grandtotal: _d(j['grandtotal']),
        currency: _s(j['currency']),
        series: _s(j['series']),
      );
}

class PurchaseOrderListResponse {
  final int status;
  final String message;
  final List<PurchaseOrderListItem> data;
  PurchaseOrderListResponse(
      {this.status = 0, this.message = '', this.data = const []});

  factory PurchaseOrderListResponse.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderListResponse(
        status: _i(j['status']),
        message: _s(j['message']),
        data: (j['data'] as List? ?? [])
            .map((e) => PurchaseOrderListItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

// ── Detail (header + items) ──
class PurchaseOrderItem {
  final String itemcode;
  final String itemname;
  final String itemsize;
  final double quantity;
  final double fixedrate;
  final double rate;
  final double discountpercent;
  final double gstpercent;
  final double gstamount;
  final double amount;
  final String unit;
  // Ids — used to rebuild editable item lines when editing.
  final int itemid;
  final int billingunitid;
  final int itemsizeid;
  final String itemdescription;

  PurchaseOrderItem({
    this.itemcode = '',
    this.itemname = '',
    this.itemsize = '',
    this.quantity = 0,
    this.fixedrate = 0,
    this.rate = 0,
    this.discountpercent = 0,
    this.gstpercent = 0,
    this.gstamount = 0,
    this.amount = 0,
    this.unit = '',
    this.itemid = 0,
    this.billingunitid = 0,
    this.itemsizeid = 0,
    this.itemdescription = '',
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderItem(
        itemcode: _s(j['itemcode']),
        itemname: _s(j['itemname']),
        itemsize: _s(j['itemsize']),
        quantity: _d(j['quantity']),
        fixedrate: _d(j['fixedrate']),
        rate: _d(j['rate']),
        discountpercent: _d(j['discountpercent']),
        gstpercent: _d(j['gstpercent']),
        gstamount: _d(j['gstamount']),
        amount: _d(j['amount']),
        unit: _s(j['unit']),
        itemid: _i(j['itemid']),
        billingunitid: _i(j['billingunitid']),
        itemsizeid: _i(j['itemsizeid']),
        itemdescription: _s(j['itemdescription']),
      );
}

class PurchaseOrderHeader {
  final int mainid;
  final String createdby;
  final String createdate;
  final String orderno;
  final String entrytype;
  final String series;
  final String orderdate;
  final String deliverydate;
  final String partyname;
  final String orderremarks;
  final String itemremarks;
  final String deliverytype;
  final String deliverystore;
  final String transportname;
  final String freightmode;
  final String paymentmode;
  final String transactiontype;
  final String transportmode;
  final String currency;
  final String supplieraddress;
  final String billtoaddress;
  final String gstno;
  final String mobileno;
  final double totalqty;
  final double totalamount;
  final double totalgst;
  final double roundoff;
  final double grandtotal;
  final String terms;
  final String stamp;
  // Ids — used to prefill the edit form's dropdowns.
  final int entrytypeid;
  final int seriestypeid;
  final int partyid;
  final int partycategoryid;
  final int deliverytypeid;
  final int transportid;
  final int deliverystoreid;
  final int storecontactpersonid;
  final String storecontactperson;
  final int freightmodeid;
  final int paymentmodeid;
  final int transactiontypeid;
  final int transportmodeid;
  final int currencyid;

  PurchaseOrderHeader({
    this.mainid = 0,
    this.createdby = '',
    this.createdate = '',
    this.orderno = '',
    this.entrytype = '',
    this.series = '',
    this.orderdate = '',
    this.deliverydate = '',
    this.partyname = '',
    this.orderremarks = '',
    this.itemremarks = '',
    this.deliverytype = '',
    this.deliverystore = '',
    this.transportname = '',
    this.freightmode = '',
    this.paymentmode = '',
    this.transactiontype = '',
    this.transportmode = '',
    this.currency = '',
    this.supplieraddress = '',
    this.billtoaddress = '',
    this.gstno = '',
    this.mobileno = '',
    this.totalqty = 0,
    this.totalamount = 0,
    this.totalgst = 0,
    this.roundoff = 0,
    this.grandtotal = 0,
    this.terms = '',
    this.stamp = '',
    this.entrytypeid = 0,
    this.seriestypeid = 0,
    this.partyid = 0,
    this.partycategoryid = 0,
    this.deliverytypeid = 0,
    this.transportid = 0,
    this.deliverystoreid = 0,
    this.storecontactpersonid = 0,
    this.storecontactperson = '',
    this.freightmodeid = 0,
    this.paymentmodeid = 0,
    this.transactiontypeid = 0,
    this.transportmodeid = 0,
    this.currencyid = 0,
  });

  factory PurchaseOrderHeader.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderHeader(
        mainid: _i(j['mainid']),
        createdby: _s(j['createdby']),
        createdate: _s(j['createdate']),
        orderno: _s(j['orderno']),
        entrytype: _s(j['entrytype']),
        series: _s(j['series']),
        orderdate: _s(j['orderdate']),
        deliverydate: _s(j['deliverydate']),
        partyname: _s(j['partyname']),
        orderremarks: _s(j['orderremarks']),
        itemremarks: _s(j['itemremarks']),
        deliverytype: _s(j['deliverytype']),
        deliverystore: _s(j['deliverystore']),
        transportname: _s(j['transportname']),
        freightmode: _s(j['freightmode']),
        paymentmode: _s(j['paymentmode']),
        transactiontype: _s(j['transactiontype']),
        transportmode: _s(j['transportmode']),
        currency: _s(j['currency']),
        supplieraddress: _s(j['supplieraddress']),
        billtoaddress: _s(j['billtoaddress']),
        gstno: _s(j['gstno']),
        mobileno: _s(j['mobileno']),
        totalqty: _d(j['totalqty']),
        totalamount: _d(j['totalamount']),
        totalgst: _d(j['totalgst']),
        roundoff: _d(j['roundoff']),
        grandtotal: _d(j['grandtotal']),
        terms: _s(j['terms']),
        stamp: _s(j['stamp']),
        entrytypeid: _i(j['entrytypeid']),
        seriestypeid: _i(j['seriestypeid']),
        partyid: _i(j['partyid']),
        partycategoryid: _i(j['partycategoryid']),
        deliverytypeid: _i(j['deliverytypeid']),
        transportid: _i(j['transportid']),
        deliverystoreid: _i(j['deliverystoreid']),
        storecontactpersonid: _i(j['storecontactpersonid']),
        storecontactperson: _s(j['storecontactperson']),
        freightmodeid: _i(j['freightmodeid']),
        paymentmodeid: _i(j['paymentmodeid']),
        transactiontypeid: _i(j['transactiontypeid']),
        transportmodeid: _i(j['transportmodeid']),
        currencyid: _i(j['currencyid']),
      );
}

class PurchaseOrderDetailResponse {
  final int status;
  final String message;
  final PurchaseOrderHeader? header;
  final List<PurchaseOrderItem> items;
  PurchaseOrderDetailResponse(
      {this.status = 0, this.message = '', this.header, this.items = const []});

  factory PurchaseOrderDetailResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] as Map?) ?? {};
    final h = data['header'];
    return PurchaseOrderDetailResponse(
      status: _i(j['status']),
      message: _s(j['message']),
      header: h == null
          ? null
          : PurchaseOrderHeader.fromJson(Map<String, dynamic>.from(h as Map)),
      items: (data['items'] as List? ?? [])
          .map((e) =>
              PurchaseOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
