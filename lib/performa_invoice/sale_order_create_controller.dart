// Performa Invoice (Sale Order) CREATE controller — loads the dropdown bundle,
// holds all form state (Main / Other / Party / Items / Other Expense / Terms),
// dependent lookups (party names by category, store contacts by store, party
// auto-fill), computes totals, and submits to /api/saleorder/save.

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/reimbursement_repo.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'sale_order_form_models.dart';

class SaleOrderCreateController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  bool loadingForm = false;
  bool submitting = false;
  SaleOrderFormData form = SaleOrderFormData();

  // > 0 => editing an existing performa invoice (its order number is preserved).
  int entryid = 0;
  bool get isEdit => entryid > 0;
  String editingOrderNo = '';

  // Selected dropdown values (id + name).
  final Map<String, int> selId = {};
  final Map<String, String> selName = {};

  // Dependent lookups.
  List<SaleOrderOption> partyNames = [];
  List<SaleOrderOption> storeContacts = [];
  List<SaleOrderOption> itemMaster = [];

  // Dates.
  String orderDate = '';
  String deliveryDate = '';

  // Text fields.
  final customerOrderNo = TextEditingController();
  final internalRemarks = TextEditingController();
  final remark = TextEditingController();
  final destination = TextEditingController();
  final dlNo = TextEditingController();
  final billToAddress = TextEditingController();
  final shipToAddress = TextEditingController();
  final gstNo = TextEditingController();
  final mobileNo = TextEditingController();
  final projectName = TextEditingController();
  final terms = TextEditingController();

  // Grids.
  List<SaleOrderItemLine> items = [];
  List<SaleOrderOtherExpense> otherExpenses = [];

  // Attachments (ERP S3). `attachmentKeys` are the S3 object keys persisted on save;
  // `attachmentPreviews` are presigned URLs for on-screen display; names for the chips.
  final List<String> attachmentKeys = [];
  final List<String> attachmentNames = [];
  final List<String> attachmentPreviews = [];
  bool uploadingAttachment = false;

  // Pick one or more files and upload them to the ERP's S3 bucket (storage=s3), keeping
  // the returned key to persist on the document and the presigned url to preview.
  Future<void> pickAndUploadAttachment() async {
    final result = await pickAttachments();
    if (result.isEmpty) return;
    uploadingAttachment = true;
    update();
    try {
      for (final pf in result) {
        final res = await ReimbursementRepo.uploadReimbursementFile(
          pf.path,
          storage: 's3',
          compid: _compId,
          userid: _userId,
        );
        if (res.status == true && res.statusCode == 200) {
          final data =
              (res.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
          final key = data?['key']?.toString() ?? '';
          final url = data?['url']?.toString() ?? '';
          if (key.isNotEmpty) {
            attachmentKeys.add(key);
            attachmentNames.add(pf.name);
            attachmentPreviews.add(url);
          }
        } else {
          ShowMessage.showSnackBar('Attachment', res.message ?? 'Upload failed');
        }
      }
    } catch (e) {
      ShowMessage.showSnackBar('Attachment', '$e');
    } finally {
      uploadingAttachment = false;
      update();
    }
  }

  void removeAttachmentAt(int i) {
    if (i < 0 || i >= attachmentKeys.length) return;
    attachmentKeys.removeAt(i);
    if (i < attachmentNames.length) attachmentNames.removeAt(i);
    if (i < attachmentPreviews.length) attachmentPreviews.removeAt(i);
    update();
  }

  String get _compId =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';
  String get _userId => homeController.currentUserData?.userid?.toString() ?? '0';
  String get _yearId => homeController.currentUserData?.yearId?.toString() ?? '';

  @override
  void onClose() {
    for (final c in [
      customerOrderNo, internalRemarks, remark, destination, dlNo,
      billToAddress, shipToAddress, gstNo, mobileNo, projectName, terms,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  void resetForm() {
    entryid = 0;
    editingOrderNo = '';
    selId.clear();
    selName.clear();
    partyNames = [];
    storeContacts = [];
    orderDate = '';
    deliveryDate = '';
    for (final c in [
      customerOrderNo, internalRemarks, remark, destination, dlNo,
      billToAddress, shipToAddress, gstNo, mobileNo, projectName, terms,
    ]) {
      c.clear();
    }
    items = [];
    otherExpenses = [];
    // Sensible defaults from the loaded lists.
    if (form.series.isNotEmpty) _setDefault('series', form.series.first);
    if (form.entrytype.isNotEmpty) {
      final direct = form.entrytype.firstWhere((e) => e.name == 'Direct',
          orElse: () => form.entrytype.first);
      _setDefault('entrytype', direct);
    }
    update();
  }

  void _setDefault(String key, SaleOrderOption o) {
    selId[key] = o.id;
    selName[key] = o.name;
  }

  // `editId` > 0 loads that performa invoice into the form for editing.
  Future<void> loadForm({int editId = 0}) async {
    loadingForm = true;
    update();
    try {
      final res = await api.getSaleOrderFormDropdowns(
          {'compid': _compId, 'branchid': _branchId});
      if (res.status == 200) {
        form = res.data;
        final itm = await api.getSaleOrderItemMaster({'compid': _compId});
        if (itm.status == 200) itemMaster = itm.data;
        resetForm();
        if (editId > 0) await _prefillFromRecord(editId);
      } else {
        ShowMessage.showSnackBar('Performa Invoice', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      loadingForm = false;
      update();
    }
  }

  // Pull an existing performa invoice and populate every dropdown/text/grid field.
  Future<void> _prefillFromRecord(int id) async {
    final res =
        await api.getSaleOrderDetail({'id': '$id', 'compid': _compId});
    final h = res.header;
    if (res.status != 200 || h == null) {
      ShowMessage.showSnackBar(
          'Performa Invoice', 'Could not load record to edit');
      return;
    }
    entryid = h.mainid;
    editingOrderNo = h.orderno;

    // Load existing attachments: keep the raw keys for re-save, presigned URLs for display.
    attachmentKeys
      ..clear()
      ..addAll(h.attachmentkeys.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    attachmentPreviews
      ..clear()
      ..addAll(h.attachments.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    attachmentNames
      ..clear()
      ..addAll(attachmentKeys
          .map((k) => k.contains('/') ? k.substring(k.lastIndexOf('/') + 1) : k));

    void set(String key, int id, String name) {
      if (id > 0 || name.isNotEmpty) {
        selId[key] = id;
        selName[key] = name;
      }
    }

    set('entrytype', h.entrytypeid, h.entrytype);
    set('series', h.seriestypeid, h.series);
    set('currency', h.currencyid, h.currency);
    set('deliverytype', h.deliverytypeid, h.deliverytype);
    set('ordertype', h.ordertypeid, h.ordertype);
    set('priority', h.orderpriorityid, h.orderpriority);
    set('transportname', h.transportid, h.dispatchthrough);
    set('deliverystore', h.deliverystoreid, h.deliveryplace);
    set('storecontact', h.storecontactpersonid, h.storecontactperson);
    set('partycategory', h.partycategoryid, _categoryName(h.partycategoryid));
    set('party', h.partyid, h.partyname);

    orderDate = h.orderdate;
    deliveryDate = h.deliverydate;
    customerOrderNo.text = h.buyerorderno;
    internalRemarks.text = h.orderremarks;
    remark.text = h.remark;
    destination.text = h.destination;
    billToAddress.text = h.billtoaddress;
    shipToAddress.text = h.shiptoaddress;
    gstNo.text = h.gstno;
    mobileNo.text = h.mobileno;
    projectName.text = h.projectname;
    terms.text = h.terms;

    items = res.items
        .map((i) => SaleOrderItemLine(
              itemid: i.itemid,
              itemname: i.itemname,
              sizeid: i.itemsizeid,
              sizename: i.itemsize,
              quantity: i.quantity,
              salerate: i.salerate,
              gstpercent: i.gstpercent,
              billingunitid: i.billingunitid,
              billingunit: i.unit,
              itemdescription: i.itemdescription,
            ))
        .toList();

    // Party dropdown must list the record's own category so the party shows.
    if (h.partycategoryid > 0) {
      final pn = await api.getSaleOrderPartyNames(
          {'compid': _compId, 'categoryid': '${h.partycategoryid}'});
      if (pn.status == 200) partyNames = pn.data;
    }
    // Delivery store's contact list, so the saved contact is selectable.
    if (h.deliverystoreid > 0) {
      final sc = await api.getSaleOrderStoreContacts(
          {'compid': _compId, 'deliverystoreid': '${h.deliverystoreid}'});
      if (sc.status == 200) storeContacts = sc.data;
    }
    update();
  }

  String _categoryName(int id) =>
      form.partycategory.firstWhereOrNull((c) => c.id == id)?.name ?? '';

  void pickOption(String key, SaleOrderOption o) {
    selId[key] = o.id;
    selName[key] = o.name;
    update();
  }

  void setDate(String value, bool isOrder) {
    if (isOrder) {
      orderDate = value;
    } else {
      deliveryDate = value;
    }
    update();
  }

  // Party category → load its party names.
  Future<void> onCategoryPicked(SaleOrderOption cat) async {
    pickOption('partycategory', cat);
    selId.remove('party');
    selName.remove('party');
    partyNames = [];
    update();
    final res = await api
        .getSaleOrderPartyNames({'compid': _compId, 'categoryid': '${cat.id}'});
    if (res.status == 200) partyNames = res.data;
    update();
  }

  // Party selected → auto-fill bill/ship/gst/mobile.
  Future<void> onPartyPicked(SaleOrderOption party) async {
    pickOption('party', party);
    final res = await api
        .getSaleOrderPartyDetail({'compid': _compId, 'partyid': '${party.id}'});
    final p = res.party;
    if (p != null) {
      if (billToAddress.text.isEmpty) billToAddress.text = p.billtoaddress;
      if (shipToAddress.text.isEmpty) shipToAddress.text = p.shiptoaddress;
      if (gstNo.text.isEmpty) gstNo.text = p.gstno;
      if (mobileNo.text.isEmpty) mobileNo.text = p.mobileno;
    }
    update();
  }

  // Delivery store → load its store contacts.
  Future<void> onStorePicked(SaleOrderOption store) async {
    pickOption('deliverystore', store);
    selId.remove('storecontact');
    selName.remove('storecontact');
    storeContacts = [];
    update();
    final res = await api.getSaleOrderStoreContacts(
        {'compid': _compId, 'deliverystoreid': '${store.id}'});
    if (res.status == 200) storeContacts = res.data;
    update();
  }

  void addItem(SaleOrderItemLine line) {
    items.add(line);
    update();
  }

  // Create a brand-new item in the master (ERP ItemMaster), then make it
  // immediately selectable by prepending it to the picker list.
  Future<SaleOrderOption?> createNewItem(
      {required String name, String size = '', int unitid = 0}) async {
    final opt = await api.createSaleOrderItem({
      'compid': _compId,
      'branchid': _branchId,
      'userid': _userId,
      'yearid': _yearId,
      'itemname': name,
      'size': size,
      'unitid': '$unitid',
    });
    if (opt != null && opt.id > 0) {
      itemMaster = [opt, ...itemMaster];
      update();
      return opt;
    }
    ShowMessage.showSnackBar('Add Item', 'Could not create item');
    return null;
  }

  void removeItem(int i) {
    if (i >= 0 && i < items.length) {
      items.removeAt(i);
      update();
    }
  }

  void addOther(SaleOrderOtherExpense o) {
    otherExpenses.add(o);
    update();
  }

  void removeOther(int i) {
    if (i >= 0 && i < otherExpenses.length) {
      otherExpenses.removeAt(i);
      update();
    }
  }

  double get totalQty => items.fold(0.0, (a, b) => a + b.quantity);
  double get totalAmount => items.fold(0.0, (a, b) => a + b.amount);
  double get totalGst => items.fold(0.0, (a, b) => a + b.gstAmount);
  // Other-expense net: Add adds, Less subtracts (ERP nature Add/Less).
  double get otherNet =>
      otherExpenses.fold(0.0, (a, b) => a + b.signedAmount);
  // Round Off is AUTO (mirrors ERP calculateTotals): grand total = round(items+gst
  // +other net); round-off = that rounding difference (can be negative).
  double get _preRoundTotal => totalAmount + totalGst + otherNet;
  double get grandTotal => _preRoundTotal.roundToDouble();
  double get roundOff => grandTotal - _preRoundTotal;

  Future<bool> submit() async {
    if ((selName['party'] ?? '').isEmpty) {
      ShowMessage.showSnackBar('Required', 'Select a party');
      return false;
    }
    if (items.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Add at least one item');
      return false;
    }
    submitting = true;
    update();
    try {
      final res = await api.saveSaleOrder({
        'entryid': '$entryid',
        'compid': _compId,
        'branchid': _branchId,
        'userid': _userId,
        'yearid': _yearId,
        'entrytypeid': '${selId['entrytype'] ?? 0}',
        'entrytype': selName['entrytype'] ?? '',
        'seriestypeid': '${selId['series'] ?? 0}',
        'seriestype': selName['series'] ?? '',
        'orderdate': orderDate,
        'deliverydate': deliveryDate,
        'partyid': '${selId['party'] ?? 0}',
        'partyname': selName['party'] ?? '',
        'customerorderno': customerOrderNo.text.trim(),
        'internalremarks': internalRemarks.text.trim(),
        'remark': remark.text.trim(),
        'deliverytypeid': '${selId['deliverytype'] ?? 0}',
        'deliverytype': selName['deliverytype'] ?? '',
        'ordertypeid': '${selId['ordertype'] ?? 0}',
        'ordertype': selName['ordertype'] ?? '',
        'orderpriorityid': '${selId['priority'] ?? 0}',
        'orderpriority': selName['priority'] ?? '',
        'deliverystoreid': '${selId['deliverystore'] ?? 0}',
        'deliverystore': selName['deliverystore'] ?? '',
        'storecontactpersonid': '${selId['storecontact'] ?? 0}',
        'storecontactperson': selName['storecontact'] ?? '',
        'transportid': '${selId['transportname'] ?? 0}',
        'transportname': selName['transportname'] ?? '',
        'destination': destination.text.trim(),
        'currencyid': '${selId['currency'] ?? 0}',
        'currency': selName['currency'] ?? '',
        'billtoaddress': billToAddress.text.trim(),
        'shiptoaddress': shipToAddress.text.trim(),
        'gstno': gstNo.text.trim(),
        'mobileno': mobileNo.text.trim(),
        'projectname': projectName.text.trim(),
        'roundoff': '$roundOff',
        'terms': terms.text.trim(),
        'items': encodeItems(items),
        'otherexpenses': encodeOthers(otherExpenses),
        // CSV of S3 keys → stored in TransMaster.Files (round-trips to the ERP).
        'attachments': attachmentKeys.join(','),
      });
      if (res.status == 200) {
        ShowMessage.showSnackBar('Performa Invoice',
            isEdit ? 'Updated successfully' : 'Created successfully');
        return true;
      }
      ShowMessage.showSnackBar('Performa Invoice', res.message.toString());
      return false;
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
      return false;
    } finally {
      submitting = false;
      update();
    }
  }
}
