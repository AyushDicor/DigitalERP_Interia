// Pending Indent for PO — lists approved indents not yet fully converted to a PO
// (the ERP "Pending Indent for Po" grid, menu 97). Tapping a row opens the PO
// create form pre-seeded from that indent. No default date window: a pending
// indent must stay visible however old it is.

import 'package:get/get.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';
import 'pending_indent_po_models.dart';

class PendingIndentPoController extends AppBaseController {
  HomeController homeController = Get.find<HomeController>();

  List<PendingIndentItem> allIndents = [];
  String searchText = '';

  String get _compId =>
      homeController.currentUserData?.compId?.toString() ?? '';
  String get _branchId =>
      homeController.currentUserData?.branchId?.toString() ?? '0';

  @override
  void onInit() {
    super.onInit();
    loadList();
  }

  List<PendingIndentItem> get indentList {
    final q = searchText.trim().toLowerCase();
    if (q.isEmpty) return allIndents;
    return allIndents
        .where((o) =>
            o.indentno.toLowerCase().contains(q) ||
            o.reqby.toLowerCase().contains(q) ||
            o.requestto.toLowerCase().contains(q) ||
            o.plant.toLowerCase().contains(q) ||
            o.indentid.toString().contains(q))
        .toList();
  }

  int get totalRecords => allIndents.length;
  int get filteredCount => indentList.length;

  void onSearch(String v) {
    searchText = v;
    update();
  }

  Future<void> loadList() async {
    setBusy(true);
    try {
      final res = await api.getPendingIndentsForPo({
        'compid': _compId,
        'branchid': _branchId,
      });
      if (res.status == 200) {
        allIndents = res.data;
      } else {
        allIndents = [];
        ShowMessage.showSnackBar('Pending Indent for PO', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      setBusy(false);
    }
  }
}
