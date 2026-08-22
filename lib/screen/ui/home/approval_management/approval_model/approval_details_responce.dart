// "ApprovalType": "Estimate",
// "DocumentId": 117,
// "DocumentNo": "72",
// "DocumentDate": "11-04-2026",
// "DueDate": "",
// "Status": "Pending",
// "Quantity": 0,
// "Amount": 0,
// "RequestedBy": "Neha Gautam",
// "SiteName": "",
// "PartyName": "",
// "Remarks": "",
// "SubType": "Add",
// "Priority": "",
// "AttachFile": ""
// },
// "approvalchain": [],
// "relateddocs": [
// {
// "Id": 288500,
// "RelatedType": "Estimate",
// "RelatedDocNo": "72",
// "RelatedDocId": 117,
// "RelatedDate": "11-04-2026",
// "RelatedStatus": "Pending",
// "RelatedAmt": 0,
// "NavigateType": "Estimate"
// }

import 'dart:convert';

ApprovalDetailsResponse approvalDetailsResponseFromJson(String str) =>
    ApprovalDetailsResponse.fromJson(json.decode(str) as Map<String, dynamic>);

String approvalDetailsResponseToJson(ApprovalDetailsResponse data) =>
    json.encode(data.toJson());

//  Response wrapper

class ApprovalDetailsResponse {
  final bool? success;
  final num? status;
  final String? message;
  final ApprovalDetailData? data; // ← single object, NOT a list

  const ApprovalDetailsResponse({
    this.success,
    this.status,
    this.message,
    this.data,
  });

  factory ApprovalDetailsResponse.fromJson(Map<String, dynamic> json) =>
      ApprovalDetailsResponse(
        success: json['success'] as bool?,
        status: json['status'] as num?,
        message: json['message'] as String?,
        // ✅ data is a single object {header, approvalchain, relateddocs}
        data: json['data'] != null && json['data'] is Map
            ? ApprovalDetailData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'status': status,
        'message': message,
        'data': data?.toJson(),
      };
}

//  data: { header, approvalchain, relateddocs }

class ApprovalDetailData {
  final ApprovalDetailHeader? header;
  final List<ApprovalChainStep> approvalChain;
  final List<RelatedDoc> relatedDocs;
  final List<ApprovalItemData> itemsList; // ✅ added
  // View-only: presigned URLs of the underlying document's attachment(s).
  final String attachments;

  const ApprovalDetailData({
    this.header,
    this.approvalChain = const [],
    this.relatedDocs = const [],
    this.itemsList = const [], // ✅ added
    this.attachments = '',
  });

  factory ApprovalDetailData.fromJson(Map<String, dynamic> json) =>
      ApprovalDetailData(
        header: json['header'] != null
            ? ApprovalDetailHeader.fromJson(
                json['header'] as Map<String, dynamic>)
            : null,
        approvalChain: (json['approvalchain'] as List<dynamic>?)
                ?.map((e) =>
                    ApprovalChainStep.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        relatedDocs: (json['relateddocs'] as List<dynamic>?)
                ?.map((e) => RelatedDoc.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        // ✅ 'itemslist' — all lowercase, matches exact API key
        itemsList: (json['itemslist'] as List<dynamic>?)
                ?.map(
                    (e) => ApprovalItemData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        attachments: json['attachments']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'header': header?.toJson(),
        'approvalchain': approvalChain.map((e) => e.toJson()).toList(),
        'relateddocs': relatedDocs.map((e) => e.toJson()).toList(),
        'itemslist': itemsList.map((e) => e.toJson()).toList(), // ✅ added
        'attachments': attachments,
      };
}

//  header

class ApprovalDetailHeader {
  final String? approvalType;
  final int? approvalId;
  final int? documentId;
  final String? documentNo;
  final String? documentDate;
  final String? dueDate;
  final String? status;
  final num? quantity;
  final num? amount;
  final String? requestedBy;
  final String? siteName;
  final String? partyName;
  final String? remarks;
  final String? subType;
  final String? priority;
  final String? attachFile;
  final String? pdfUrl;
  final String? requestType;
  final String? jobType;

  // ── Added by the backend (Aug 2026) — document header details ──
  final String? documentName;
  final int? branchId;
  final String? branchName;
  final String? seriesType;
  final String? entryType;
  final String? receiptDate;
  final String? deliveryDate;
  final String? deliveryType;
  final String? customerOrderNo;
  final String? transport;
  final String? headerRemark;
  final String? paymentTerms;
  final String? gstNo;
  final String? mobileNo;
  final String? contactPerson;
  final String? billToAddress;
  final String? shipToAddress;

  const ApprovalDetailHeader({
    this.approvalType,
    this.approvalId,
    this.documentId,
    this.documentNo,
    this.documentDate,
    this.dueDate,
    this.status,
    this.quantity,
    this.amount,
    this.requestedBy,
    this.siteName,
    this.partyName,
    this.remarks,
    this.subType,
    this.priority,
    this.attachFile,
    this.pdfUrl,
    this.requestType,
    this.jobType,
    this.documentName,
    this.branchId,
    this.branchName,
    this.seriesType,
    this.entryType,
    this.receiptDate,
    this.deliveryDate,
    this.deliveryType,
    this.customerOrderNo,
    this.transport,
    this.headerRemark,
    this.paymentTerms,
    this.gstNo,
    this.mobileNo,
    this.contactPerson,
    this.billToAddress,
    this.shipToAddress,
  });

  /// '--Select--' / '0' are placeholder values the ERP stores — treat as empty.
  static String? _clean(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isEmpty || s == '0' || s == '--Select--' || s.toLowerCase() == 'null') {
      return null;
    }
    return s;
  }

  factory ApprovalDetailHeader.fromJson(Map<String, dynamic> json) =>
      ApprovalDetailHeader(
        approvalType: json['ApprovalType'] as String?,
        approvalId: json['ApprovalId'] as int?,
        documentId: json['DocumentId'] as int?,
        documentNo: json['DocumentNo'] as String?,
        documentDate: json['DocumentDate'] as String?,
        dueDate: json['DueDate'] as String?,
        status: json['Status'] as String?,
        quantity: json['Quantity'] as num?,
        amount: json['Amount'] as num?,
        requestedBy: json['RequestedBy'] as String?,
        siteName: json['SiteName'] as String?,
        partyName: json['PartyName'] as String?,
        remarks: json['Remarks'] as String?,
        subType: json['SubType'] as String?,
        priority: json['Priority'] as String?,
        attachFile: json['AttachFile'] as String?,
        pdfUrl: json['pdfurl'] as String?,
        requestType: json['RequestType'] as String?,
        jobType: (json['Jobtype'] ?? json['JobType']) as String?,
        documentName: _clean(json['DocumentName']),
        branchId: (json['BranchId'] as num?)?.toInt(),
        branchName: _clean(json['BranchName']),
        seriesType: _clean(json['SeriesType']),
        entryType: _clean(json['EntryType']),
        receiptDate: _clean(json['ReceiptDate']),
        deliveryDate: _clean(json['DeliveryDate']),
        deliveryType: _clean(json['DeliveryType']),
        customerOrderNo: _clean(json['CustomerOrderNo']),
        transport: _clean(json['Transport']),
        headerRemark: _clean(json['HeaderRemark']),
        paymentTerms: _clean(json['PaymentTerms']),
        gstNo: _clean(json['GSTNo']),
        mobileNo: _clean(json['MobileNo']),
        contactPerson: _clean(json['ContactPerson']),
        billToAddress: _clean(json['BillToAddress']),
        shipToAddress: _clean(json['ShipToAddress']),
      );

  Map<String, dynamic> toJson() => {
        'ApprovalType': approvalType,
        'ApprovalId': approvalId,
        'DocumentId': documentId,
        'DocumentNo': documentNo,
        'DocumentDate': documentDate,
        'DueDate': dueDate,
        'Status': status,
        'Quantity': quantity,
        'Amount': amount,
        'RequestedBy': requestedBy,
        'SiteName': siteName,
        'PartyName': partyName,
        'Remarks': remarks,
        'SubType': subType,
        'Priority': priority,
        'AttachFile': attachFile,
        'pdfurl': pdfUrl,
        'RequestType': requestType,
        'JobType': jobType,
        'DocumentName': documentName,
        'BranchId': branchId,
        'BranchName': branchName,
        'SeriesType': seriesType,
        'EntryType': entryType,
        'ReceiptDate': receiptDate,
        'DeliveryDate': deliveryDate,
        'DeliveryType': deliveryType,
        'CustomerOrderNo': customerOrderNo,
        'Transport': transport,
        'HeaderRemark': headerRemark,
        'PaymentTerms': paymentTerms,
        'GSTNo': gstNo,
        'MobileNo': mobileNo,
        'ContactPerson': contactPerson,
        'BillToAddress': billToAddress,
        'ShipToAddress': shipToAddress,
      };
}

//  approvalchain

class ApprovalChainStep {
  final String? date;
  final String? remarks;
  final String? user;
  final String? status;

  const ApprovalChainStep({
    this.date,
    this.remarks,
    this.user,
    this.status,
  });

  factory ApprovalChainStep.fromJson(Map<String, dynamic> json) =>
      ApprovalChainStep(
        date: json['StepDate'] ?? json['Date'] as String?, // ✅
        remarks: json['StepRemarks'] ?? json['remarks'] as String?, // ✅
        user: json['ActionBy'] ?? json['user'] as String?, // ✅
        status: json['StepStatus'] ?? json['status'] as String?, // ✅
      );

  Map<String, dynamic> toJson() => {
        'StepDate': date,
        'StepRemarks': remarks,
        'ActionBy': user,
        'StepStatus': status,
      };
}

//  relateddocs

class RelatedDoc {
  final int? id;
  final String? relatedType;
  final String? relatedDocNo;
  final int? relatedDocId;
  final String? relatedDate;
  final String? relatedStatus;
  final num? relatedAmt;
  final String? navigateType;

  const RelatedDoc({
    this.id,
    this.relatedType,
    this.relatedDocNo,
    this.relatedDocId,
    this.relatedDate,
    this.relatedStatus,
    this.relatedAmt,
    this.navigateType,
  });

  factory RelatedDoc.fromJson(Map<String, dynamic> json) => RelatedDoc(
        id: json['Id'] as int?,
        relatedType: json['RelatedType'] as String?,
        relatedDocNo: json['RelatedDocNo'] as String?,
        relatedDocId: json['RelatedDocId'] as int?,
        relatedDate: json['RelatedDate'] as String?,
        relatedStatus: json['RelatedStatus'] as String?,
        relatedAmt: json['RelatedAmt'] as num?,
        navigateType: json['NavigateType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'Id': id,
        'RelatedType': relatedType,
        'RelatedDocNo': relatedDocNo,
        'RelatedDocId': relatedDocId,
        'RelatedDate': relatedDate,
        'RelatedStatus': relatedStatus,
        'RelatedAmt': relatedAmt,
        'NavigateType': navigateType,
      };
}

// AFTER
class ApprovalItemData {
  final int? detailId;
  final int? expenseId;
  final int? parentId;
  final int? ledgerId;
  final int sno;
  final String expenseGroup;
  final String expenseLedger;
  final String description;
  final double amount;
  final double quantity;
  final double approvedAmt;
  final String status;
  final String? referenceFile;
  final String? receiptFile;
  final int? transId;

  // ── Added by the backend (Aug 2026) — real document line details ──
  final int? itemId;
  final String itemName;
  final String size;
  final String unit;
  final double rate;
  final double taxPercent;
  final double taxAmount;

  const ApprovalItemData({
    this.detailId,
    this.expenseId,
    this.parentId,
    this.ledgerId,
    this.sno = 0,
    this.expenseGroup = '',
    this.expenseLedger = '',
    this.description = '',
    this.amount = 0.0,
    this.quantity = 0.0,
    this.approvedAmt = 0.0,
    this.status = 'Pending',
    this.referenceFile,
    this.receiptFile,
    this.transId,
    this.itemId,
    this.itemName = '',
    this.size = '',
    this.unit = '',
    this.rate = 0.0,
    this.taxPercent = 0.0,
    this.taxAmount = 0.0,
  });

  /// Line total before tax (the API's Amount is the taxable value).
  double get taxableAmount => amount;

  /// Line total including tax.
  double get totalAmount => amount + taxAmount;

  factory ApprovalItemData.fromJson(Map<String, dynamic> json) =>
      ApprovalItemData(
        detailId: json['DetailId'] as int?,
        expenseId: json['ExpenseId'] as int?,
        parentId: json['ParentId'] as int?,
        ledgerId: json['LedgerId'] as int?,
        sno: (json['SNo'] as num?)?.toInt() ?? 0,
        expenseGroup: json['ExpenseGroup'] as String? ?? '',
        expenseLedger: json['ExpenseLedger'] as String? ?? '',
        description: json['Description'] as String? ?? '',
        amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['Quantity'] as num?)?.toDouble() ?? 0.0,
        approvedAmt: (json['ApprovedAmt'] as num?)?.toDouble() ?? 0.0,
        status: json['Status'] as String? ?? 'Pending',
        referenceFile: json['ReferenceFile'] as String?,
        receiptFile: json['ReceiptFile'] as String?,
        transId: json['TransId'] as int?,
        itemId: (json['ItemId'] as num?)?.toInt(),
        itemName: json['ItemName'] as String? ?? '',
        size: json['Size'] as String? ?? '',
        unit: json['Unit'] as String? ?? '',
        rate: (json['Rate'] as num?)?.toDouble() ?? 0.0,
        taxPercent: (json['TaxPercent'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (json['TaxAmount'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'DetailId': detailId,
        'ExpenseId': expenseId,
        'ParentId': parentId,
        'LedgerId': ledgerId,
        'SNo': sno,
        'ExpenseGroup': expenseGroup,
        'ExpenseLedger': expenseLedger,
        'Description': description,
        'Amount': amount,
        'ApprovedAmt': approvedAmt,
        'Status': status,
        'ReferenceFile': referenceFile,
        'ReceiptFile': receiptFile,
        'TransId': transId, // ← added
        'ItemId': itemId,
        'ItemName': itemName,
        'Size': size,
        'Unit': unit,
        'Rate': rate,
        'TaxPercent': taxPercent,
        'TaxAmount': taxAmount,
      };
}
