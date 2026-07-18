// Purchase Order CREATE controller — loads the dropdown bundle, holds all form
// state (Main / Other / Party / Items / Other Expense / Terms), dependent
// lookups (party names by category, store contacts by store, party auto-fill),
// computes totals, and submits to /api/purchaseorder/save.

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/reimbursement_repo.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'purchase_order_form_models.dart';

class PurchaseOrderCreateController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  bool loadingForm = false;
  bool submitting = false;
  PoFormData form = PoFormData();

  // > 0 => editing an existing purchase order (its order number is preserved).
  int entryid = 0;
  bool get isEdit => entryid > 0;
  String editingOrderNo = '';

  // > 0 => this PO is being generated FROM a pending indent (Pending Indent for PO).
  // Sent as `refid` on save so the ERP links the PO to the indent and bumps the
  // indent's completeqty (closing it once fully converted).
  int refid = 0;
  String seededFromIndentNo = '';
  bool get isFromIndent => refid > 0;

  // Selected dropdown values (id + name).
  final Map<String, int> selId = {};
  final Map<String, String> selName = {};

  // Dependent lookups.
  List<PoOption> partyNames = [];
  List<PoOption> storeContacts = [];
  List<PoOption> itemMaster = [];

  // Dates.
  String orderDate = '';
  String deliveryDate = '';

  // Text fields.
  final orderRemarks = TextEditingController();
  final itemRemarks = TextEditingController();
  final stamp = TextEditingController();
  final supplierAddress = TextEditingController();
  final billToAddress = TextEditingController();
  final gstNo = TextEditingController();
  final mobileNo = TextEditingController();
  final terms = TextEditingController();

  // Grids.
  List<PoItemLine> items = [];
  List<PoOtherExpense> otherExpenses = [];

  // Attachments (ERP S3). `attachmentKeys` persisted on save; `attachmentPreviews`
  // are presigned URLs for display; names for the chips.
  final List<String> attachmentKeys = [];
  final List<String> attachmentNames = [];
  final List<String> attachmentPreviews = [];
  bool uploadingAttachment = false;

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

  List<TextEditingController> get _all => [
        orderRemarks, itemRemarks, stamp, supplierAddress,
        billToAddress, gstNo, mobileNo, terms,
      ];

  @override
  void onClose() {
    for (final c in _all) {
      c.dispose();
    }
    super.onClose();
  }

  // `preloadParties` is off when editing — the record's own category is loaded
  // afterwards, and a stray default preload would race and clobber it.
  void resetForm({bool preloadParties = true}) {
    entryid = 0;
    editingOrderNo = '';
    refid = 0;
    seededFromIndentNo = '';
    selId.clear();
    selName.clear();
    partyNames = [];
    storeContacts = [];
    orderDate = '';
    deliveryDate = '';
    for (final c in _all) {
      c.clear();
    }
    items = [];
    otherExpenses = [];
    roundOff = 0;
    _applyDefaults(preloadParties);
    update();
  }

  // ERP defaults: Entry Type "Direct", series "B", Indian Rupee, Sundry Creditors.
  void _applyDefaults(bool preloadParties) {
    PoOption? pick(List<PoOption> list, bool Function(PoOption) test) {
      if (list.isEmpty) return null;
      return list.firstWhereOrNull(test) ?? list.first;
    }

    final entry = pick(form.entrytype, (e) => e.name.toLowerCase() == 'direct');
    if (entry != null) _setDefault('entrytype', entry);

    final series = pick(form.series, (e) => e.name.trim() == 'B');
    if (series != null) _setDefault('series', series);

    final cur = pick(form.currency,
        (e) => e.name.toLowerCase().contains('indian rupee'));
    if (cur != null) _setDefault('currency', cur);

    final cat = pick(form.partycategory,
        (e) => e.name.toLowerCase().contains('creditor'));
    if (cat != null) {
      _setDefault('partycategory', cat);
      // Preload the creditor party list so Party Name is immediately usable.
      if (preloadParties) _loadPartyNames(cat.id);
    }
  }

  void _setDefault(String key, PoOption o) {
    selId[key] = o.id;
    selName[key] = o.name;
  }

  // `editId` > 0 loads that purchase order into the form for editing.
  // `seedIndentId` > 0 pre-fills a NEW PO from a pending indent (entry type Indent,
  // items/qty/rate + item remarks from the indent) and carries the indent id as refid.
  Future<void> loadForm({int editId = 0, int seedIndentId = 0}) async {
    loadingForm = true;
    update();
    try {
      final res = await api.getPurchaseOrderFormDropdowns(
          {'compid': _compId, 'branchid': _branchId});
      if (res.status == 200) {
        form = res.data;
        final itm = await api.getPurchaseOrderItemMaster({'compid': _compId});
        if (itm.status == 200) itemMaster = itm.data;
        resetForm(preloadParties: editId == 0);
        if (editId > 0) await _prefillFromRecord(editId);
        if (seedIndentId > 0) await _seedFromIndent(seedIndentId);
      } else {
        ShowMessage.showSnackBar('Purchase Order', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      loadingForm = false;
      update();
    }
  }

  // Pull a pending indent and pre-fill the form as the ERP's
  // /Home/CreateSaleOrder?id=<indent>&type=NEW does: entry type Indent, item lines
  // from the indent, item remarks from its Narration. Party is left for the user.
  Future<void> _seedFromIndent(int indentId) async {
    final res =
        await api.getIndentForPo({'compid': _compId, 'indentid': '$indentId'});
    final h = res.header;
    if (res.status != 200 || h == null) {
      ShowMessage.showSnackBar('Pending Indent', 'Could not load indent to convert');
      return;
    }
    refid = h.indentid;
    seededFromIndentNo = h.indentno;

    // Entry Type = Indent (overrides the "Direct" default).
    final indentEntry = form.entrytype
        .firstWhereOrNull((e) => e.name.toLowerCase() == 'indent');
    if (indentEntry != null) _setDefault('entrytype', indentEntry);

    if (h.deliverydate.isNotEmpty) deliveryDate = h.deliverydate;
    if (h.itemremarks.isNotEmpty) itemRemarks.text = h.itemremarks;

    items = res.items
        .map((i) => PoItemLine(
              itemid: i.itemid,
              itemname: i.itemname,
              quantity: i.quantity,
              fixedrate: i.fixedrate,
              rate: i.rate,
              discountpercent: i.discountpercent,
              gstpercent: i.gstpercent,
              billingunitid: i.billingunitid,
              billingunit: i.billingunit,
              itemdescription: i.itemdescription,
            ))
        .toList();
    update();
  }

  // Pull an existing PO and populate every dropdown/text/grid field.
  Future<void> _prefillFromRecord(int id) async {
    final res = await api.getPurchaseOrderDetail(
        {'id': '$id', 'compid': _compId});
    final h = res.header;
    if (res.status != 200 || h == null) {
      ShowMessage.showSnackBar('Purchase Order', 'Could not load record to edit');
      return;
    }
    entryid = h.mainid;
    editingOrderNo = h.orderno;

    // Load existing attachments: keep raw keys for re-save, presigned URLs for display.
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
    set('transportname', h.transportid, h.transportname);
    set('deliverystore', h.deliverystoreid, h.deliverystore);
    set('storecontact', h.storecontactpersonid, h.storecontactperson);
    set('freightmode', h.freightmodeid, h.freightmode);
    set('paymentmode', h.paymentmodeid, h.paymentmode);
    set('transactiontype', h.transactiontypeid, h.transactiontype);
    set('transportmode', h.transportmodeid, h.transportmode);
    set('partycategory', h.partycategoryid, _categoryName(h.partycategoryid));
    set('party', h.partyid, h.partyname);

    orderDate = h.orderdate;
    deliveryDate = h.deliverydate;
    orderRemarks.text = h.orderremarks;
    itemRemarks.text = h.itemremarks;
    stamp.text = h.stamp;
    supplierAddress.text = h.supplieraddress;
    billToAddress.text = h.billtoaddress;
    gstNo.text = h.gstno;
    mobileNo.text = h.mobileno;
    terms.text = h.terms;
    roundOff = h.roundoff;

    items = res.items
        .map((i) => PoItemLine(
              itemid: i.itemid,
              itemname: i.itemname,
              sizeid: i.itemsizeid,
              sizename: i.itemsize,
              quantity: i.quantity,
              fixedrate: i.fixedrate,
              rate: i.rate,
              discountpercent: i.discountpercent,
              gstpercent: i.gstpercent,
              billingunitid: i.billingunitid,
              billingunit: i.unit,
              itemdescription: i.itemdescription,
            ))
        .toList();

    // Party dropdown must list the record's own category so the party shows.
    if (h.partycategoryid > 0) await _loadPartyNames(h.partycategoryid);
    // Delivery store's contact list, so the saved contact is selectable.
    if (h.deliverystoreid > 0) {
      final sc = await api.getPurchaseOrderStoreContacts(
          {'compid': _compId, 'deliverystoreid': '${h.deliverystoreid}'});
      if (sc.status == 200) storeContacts = sc.data;
    }
    update();
  }

  String _categoryName(int id) =>
      form.partycategory.firstWhereOrNull((c) => c.id == id)?.name ?? '';

  void pickOption(String key, PoOption o) {
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

  Future<void> _loadPartyNames(int categoryid) async {
    final res = await api.getPurchaseOrderPartyNames(
        {'compid': _compId, 'categoryid': '$categoryid'});
    if (res.status == 200) partyNames = res.data;
    update();
  }

  // Party category → load its party names.
  Future<void> onCategoryPicked(PoOption cat) async {
    pickOption('partycategory', cat);
    selId.remove('party');
    selName.remove('party');
    partyNames = [];
    update();
    await _loadPartyNames(cat.id);
  }

  // Party selected → auto-fill supplier/bill-to/gst/mobile.
  Future<void> onPartyPicked(PoOption party) async {
    pickOption('party', party);
    final res = await api.getPurchaseOrderPartyDetail(
        {'compid': _compId, 'partyid': '${party.id}'});
    final p = res.party;
    if (p != null) {
      if (supplierAddress.text.isEmpty) supplierAddress.text = p.billtoaddress;
      if (billToAddress.text.isEmpty) billToAddress.text = p.billtoaddress;
      if (gstNo.text.isEmpty) gstNo.text = p.gstno;
      if (mobileNo.text.isEmpty) mobileNo.text = p.mobileno;
    }
    update();
  }

  // Delivery store → load its store contacts.
  Future<void> onStorePicked(PoOption store) async {
    pickOption('deliverystore', store);
    selId.remove('storecontact');
    selName.remove('storecontact');
    storeContacts = [];
    update();
    final res = await api.getPurchaseOrderStoreContacts(
        {'compid': _compId, 'deliverystoreid': '${store.id}'});
    if (res.status == 200) storeContacts = res.data;
    update();
  }

  // Create a brand-new item in the master (ERP ItemMaster), then make it
  // immediately selectable by prepending it to the picker list.
  Future<PoOption?> createNewItem(
      {required String name, String size = '', int unitid = 0}) async {
    final opt = await api.createPurchaseOrderItem({
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

  // ParentId of each inline-addable dropdown in the shared ERPMasterDB `parameter`
  // table. These are constants baked into the ERP's read procs (getdelieverytype
  // filters ParentId=7, gettransportname 8, ...), not configuration. The server
  // whitelists the same five.
  static const Map<String, int> parameterParentIds = {
    'deliverytype': 7,
    'transportname': 8,
    'freightmode': 63,
    'transactiontype': 65,
    'transportmode': 67,
  };

  // Add a missing dropdown master inline — the app-side of the ERP's "+ Add X"
  // option. On success the whole dropdown bundle is re-read (as the ERP's
  // reload*Dropdown() does) so the list matches the server rather than being
  // patched locally. Returns the option to select, or null on failure.
  Future<PoOption?> createParameter(
      {required String key, required String name}) async {
    final parentid = parameterParentIds[key];
    if (parentid == null) return null;

    final res = await api.addMasterParameter({
      'compid': _compId,
      'parentid': '$parentid',
      'detail': name,
    });
    if (res == null || res.id <= 0) {
      ShowMessage.showSnackBar('Add', 'Could not add "$name"');
      return null;
    }

    // A duplicate is not a failure: the server hands back the existing row (with
    // the ERP's stored casing) so the user can carry on with it.
    if (res.duplicate) ShowMessage.showSnackBar('Add', res.message);

    final refreshed = await api.getPurchaseOrderFormDropdowns(
        {'compid': _compId, 'branchid': _branchId});
    if (refreshed.status == 200) form = refreshed.data;

    update();
    // Selection is left to the caller: the picker applies whatever the sheet
    // returns, so selecting here too would just double up.
    return PoOption(id: res.id, name: res.name);
  }

  void addItem(PoItemLine line) {
    items.add(line);
    update();
  }

  void removeItem(int i) {
    if (i >= 0 && i < items.length) {
      items.removeAt(i);
      update();
    }
  }

  void addOther(PoOtherExpense o) {
    otherExpenses.add(o);
    update();
  }

  void removeOther(int i) {
    if (i >= 0 && i < otherExpenses.length) {
      otherExpenses.removeAt(i);
      update();
    }
  }

  double roundOff = 0;
  void setRoundOff(double v) {
    roundOff = v;
    update();
  }

  double get totalQty => items.fold(0.0, (a, b) => a + b.quantity);
  double get totalAmount => items.fold(0.0, (a, b) => a + b.amount);
  double get totalGst => items.fold(0.0, (a, b) => a + b.gstAmount);
  double get grandTotal => totalAmount + totalGst + roundOff;

  Future<bool> submit() async {
    if ((selName['party'] ?? '').isEmpty) {
      ShowMessage.showSnackBar('Required', 'Select a party');
      return false;
    }
    if ((selName['series'] ?? '').isEmpty) {
      ShowMessage.showSnackBar('Required', 'Select a series type');
      return false;
    }
    if ((selName['transportname'] ?? '').isEmpty) {
      ShowMessage.showSnackBar('Required', 'Select a transport name');
      return false;
    }
    if ((selName['transportmode'] ?? '').isEmpty) {
      ShowMessage.showSnackBar('Required', 'Select a transport mode');
      return false;
    }
    if (items.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Add at least one item');
      return false;
    }
    submitting = true;
    update();
    try {
      final res = await api.savePurchaseOrder({
        'entryid': '$entryid',
        // > 0 links this PO to the source indent and closes it (completeqty bump).
        'refid': '$refid',
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
        'orderremarks': orderRemarks.text.trim(),
        'itemremarks': itemRemarks.text.trim(),
        'deliverytypeid': '${selId['deliverytype'] ?? 0}',
        'deliverytype': selName['deliverytype'] ?? '',
        'transportid': '${selId['transportname'] ?? 0}',
        'transportname': selName['transportname'] ?? '',
        'deliverystoreid': '${selId['deliverystore'] ?? 0}',
        'deliverystore': selName['deliverystore'] ?? '',
        'storecontactpersonid': '${selId['storecontact'] ?? 0}',
        'storecontactperson': selName['storecontact'] ?? '',
        'freightmodeid': '${selId['freightmode'] ?? 0}',
        'freightmode': selName['freightmode'] ?? '',
        'paymentmodeid': '${selId['paymentmode'] ?? 0}',
        'paymentmode': selName['paymentmode'] ?? '',
        'transactiontypeid': '${selId['transactiontype'] ?? 0}',
        'transactiontype': selName['transactiontype'] ?? '',
        'transportmodeid': '${selId['transportmode'] ?? 0}',
        'transportmode': selName['transportmode'] ?? '',
        'currencyid': '${selId['currency'] ?? 0}',
        'currency': selName['currency'] ?? '',
        'supplieraddress': supplierAddress.text.trim(),
        'shiptoaddress': billToAddress.text.trim(),
        'gstno': gstNo.text.trim(),
        'mobileno': mobileNo.text.trim(),
        'scopofwork': stamp.text.trim(),
        'roundoff': '$roundOff',
        'terms': terms.text.trim(),
        'items': encodePoItems(items),
        'otherexpenses': encodePoOthers(otherExpenses),
        // CSV of S3 keys → stored in TransMaster.Files (round-trips to the ERP).
        'attachments': attachmentKeys.join(','),
      });
      if (res.status == 200) {
        // Success message is shown by the caller AFTER Get.back, so it lands on
        // the list page rather than being dismissed together with this page.
        return true;
      }
      ShowMessage.showSnackBar('Purchase Order', res.message.toString());
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
