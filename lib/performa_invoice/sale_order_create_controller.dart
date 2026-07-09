// Performa Invoice (Sale Order) CREATE controller — loads the dropdown bundle,
// holds all form state (Main / Other / Party / Items / Other Expense / Terms),
// dependent lookups (party names by category, store contacts by store, party
// auto-fill), computes totals, and submits to /api/saleorder/save.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'sale_order_form_models.dart';

class SaleOrderCreateController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  bool loadingForm = false;
  bool submitting = false;
  SaleOrderFormData form = SaleOrderFormData();

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

  Future<void> loadForm() async {
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
    if (items.isEmpty) {
      ShowMessage.showSnackBar('Required', 'Add at least one item');
      return false;
    }
    submitting = true;
    update();
    try {
      final res = await api.saveSaleOrder({
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
      });
      if (res.status == 200) {
        ShowMessage.showSnackBar('Performa Invoice', 'Created successfully');
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
