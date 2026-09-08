import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/production/production_batches_view.dart';
import 'package:newdigitalerp/production/production_models.dart';
import 'package:newdigitalerp/screen/auth/base/base_contoller.dart';
import 'package:newdigitalerp/utils/show_message.dart';

/// Drives the two Production screens:
///   1. stage picker  — loadStages() on init, tap a chip -> openStage()
///   2. batch entry    — loadBatches() fills the cards; each card has a Produced
///                        and a QC OK field; Save All -> saveAll().
///
/// One controller spans both screens (put by the picker, found by the batch
/// screen) so the batches payload — including the substage/tostage ids that
/// saveentry must echo back — survives the navigation.
class ProductionController extends AppBaseController {
  final HomeController homeController = Get.find<HomeController>();

  // ── Session context (same source every other module uses) ──
  int get _compid =>
      int.tryParse('${homeController.currentUserData?.compId ?? ''}') ?? 0;
  int get _branchid =>
      int.tryParse('${homeController.currentUserData?.branchId ?? ''}') ?? 0;
  int get _userid =>
      int.tryParse('${homeController.currentUserData?.userid ?? ''}') ?? 0;
  String get _yearid =>
      homeController.currentUserData?.yearId?.toString() ?? '';

  // ── Stage picker state ──
  List<ProductionStage> stages = [];
  bool stagesLoading = false;
  String stagesError = '';

  // ── Batch entry state ──
  ProductionStage? selectedStage;
  ProductionBatchesData? batches;
  bool batchesLoading = false;
  bool saving = false;
  String batchesError = '';

  // Per-batch inputs, keyed by challanid (unique per batch card).
  final Map<int, TextEditingController> producedCtrls = {};
  final Map<int, TextEditingController> qcCtrls = {};
  final Map<int, TextEditingController> issueCtrls = {};

  // Search over the loaded batches (filters the cards; entered values persist).
  final TextEditingController searchCtrl = TextEditingController();
  String search = '';

  // Clean number for messages: trims a trailing ".0".
  String _n(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void onInit() {
    super.onInit();
    loadStages();
  }

  @override
  void onClose() {
    _disposeRowControllers();
    searchCtrl.dispose();
    super.onClose();
  }

  /// Filter the loaded batches by batch no or item name. Never touches the
  /// per-row input controllers, so typed Produced/QC/Issue values survive.
  void setSearch(String q) {
    search = q.trim().toLowerCase();
    update();
  }

  List<ProductionBatchRow> get visibleRows {
    final all = batches?.rows ?? [];
    if (search.isEmpty) return all;
    return all
        .where((r) =>
            r.batchno.toLowerCase().contains(search) ||
            r.itemname.toLowerCase().contains(search))
        .toList();
  }

  void _disposeRowControllers() {
    for (final c in producedCtrls.values) {
      c.dispose();
    }
    for (final c in qcCtrls.values) {
      c.dispose();
    }
    for (final c in issueCtrls.values) {
      c.dispose();
    }
    producedCtrls.clear();
    qcCtrls.clear();
    issueCtrls.clear();
  }

  Future<void> loadStages() async {
    stagesLoading = true;
    stagesError = '';
    update();
    try {
      final res = await api.getProductionStages({'compid': _compid});
      if (res.status == 200 && res.success) {
        stages = res.data;
        if (stages.isEmpty) stagesError = 'No stages configured.';
      } else {
        stagesError = res.message.isNotEmpty ? res.message : 'Could not load stages.';
      }
    } catch (e) {
      stagesError = '$e';
    } finally {
      stagesLoading = false;
      update();
    }
  }

  /// Tapped a stage chip → load its batches, then open the entry screen.
  Future<void> openStage(ProductionStage stage) async {
    selectedStage = stage;
    await loadBatches();
    Get.to(() => const ProductionBatchesView());
  }

  Future<void> loadBatches() async {
    final stage = selectedStage;
    if (stage == null) return;
    batchesLoading = true;
    batchesError = '';
    _disposeRowControllers();
    batches = null;
    search = '';
    searchCtrl.clear();
    update();
    try {
      final res = await api.getProductionBatches({
        'compid': _compid,
        'branchid': _branchid,
        'stageid': stage.stageid,
        'stagename': stage.stagename,
      });
      if (res.status == 200 && res.success && res.data != null) {
        batches = res.data;
        for (final row in res.data!.rows) {
          producedCtrls[row.challanid] = TextEditingController();
          qcCtrls[row.challanid] = TextEditingController();
          issueCtrls[row.challanid] = TextEditingController();
        }
        if (res.data!.rows.isEmpty) {
          batchesError = 'No batches at this stage.';
        }
      } else {
        batchesError =
            res.message.isNotEmpty ? res.message : 'Could not load batches.';
      }
    } catch (e) {
      batchesError = '$e';
    } finally {
      batchesLoading = false;
      update();
    }
  }

  double _val(Map<int, TextEditingController> map, int id) =>
      double.tryParse(map[id]?.text.trim() ?? '') ?? 0;

  /// Only batches the user actually touched (Produced or QC entered) are sent —
  /// keeps empty cards out of the payload.
  List<ProductionBatchRow> get _editedRows {
    final data = batches;
    if (data == null) return [];
    return data.rows.where((r) {
      final p = _val(producedCtrls, r.challanid);
      final q = _val(qcCtrls, r.challanid);
      final i = _val(issueCtrls, r.challanid);
      return p > 0 || q > 0 || i > 0;
    }).toList();
  }

  int get editedCount => _editedRows.length;

  Future<void> saveAll() async {
    final data = batches;
    final stage = selectedStage;
    if (data == null || stage == null) return;

    final edited = _editedRows;
    if (edited.isEmpty) {
      ShowMessage.showSnackBar(
          'Nothing to save', 'Enter Produced / QC on at least one batch.');
      return;
    }

    // Client guards so the user gets obvious mistakes before a round trip.
    // The server is still the final authority (it also checks cumulative qty).
    for (final r in edited) {
      final p = _val(producedCtrls, r.challanid);
      final q = _val(qcCtrls, r.challanid);
      final i = _val(issueCtrls, r.challanid);
      // Produced cannot exceed the batch balance (available at this stage).
      if (p > r.availableqty) {
        ShowMessage.showSnackBar('Check ${r.batchno}',
            'Produced (${_n(p)}) cannot exceed balance (${_n(r.availableqty)}).');
        return;
      }
      if (q > p) {
        ShowMessage.showSnackBar('Check ${r.batchno}',
            'QC OK (${_n(q)}) cannot exceed Produced (${_n(p)}).');
        return;
      }
      if (i > p) {
        ShowMessage.showSnackBar('Check ${r.batchno}',
            'Issue (${_n(i)}) cannot exceed Produced (${_n(p)}).');
        return;
      }
    }

    saving = true;
    update();
    try {
      final rows = edited
          .map((r) => {
                'challanid': r.challanid,
                'batchno': r.batchno,
                'orderrefid': r.orderrefid,
                'itemid': r.itemid,
                'itemname': r.itemname,
                'producedqty': _val(producedCtrls, r.challanid),
                'qcqty': _val(qcCtrls, r.challanid),
                'issueqty': _val(issueCtrls, r.challanid),
                'shiftid': 0,
                'operatorname': '',
                'supervisor': '',
              })
          .toList();

      final body = {
        'compid': _compid,
        'branchid': _branchid,
        'userid': _userid,
        'yearid': _yearid,
        'stageid': stage.stageid,
        'stagename': stage.stagename,
        'substageid': data.substageid,
        'substagename': data.substagename,
        'tostageid': data.tostageid,
        'tostagename': data.tostagename,
        'rows': rows,
      };

      final res = await api.saveProductionEntry(body);

      if (res.status == 200 && res.success && res.failed == 0) {
        ShowMessage.showSnackBar(
            'Saved', '${res.saved} batch(es) saved to ${stage.stagename}.');
        // Refresh so balances / produced-so-far reflect the save.
        await loadBatches();
      } else if (res.saved > 0) {
        // Partial: some saved, some rejected — surface the reasons per batch.
        final detail = res.errors
            .map((e) => '• ${e.batchno}: ${e.reason}')
            .join('\n');
        ShowMessage.showSnackBar('Saved ${res.saved}, ${res.failed} failed',
            detail.isEmpty ? res.message : detail);
        await loadBatches();
      } else {
        final detail = res.errors
            .map((e) => '• ${e.batchno}: ${e.reason}')
            .join('\n');
        ShowMessage.showSnackBar('Not saved',
            detail.isNotEmpty ? detail : (res.message.isNotEmpty ? res.message : 'Save failed.'));
      }
    } catch (e) {
      ShowMessage.showSnackBar('Not saved', '$e');
    } finally {
      saving = false;
      update();
    }
  }
}
