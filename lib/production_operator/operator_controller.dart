import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_models.dart';
import 'operator_repo.dart';
import 'operator_widgets.dart';

/// Drives the Production — Operator module:
///   shell (4 tabs)  Home · My Work · QC · Stoppages   ← all fed by [jobs]
///   job workspace   produce (+/- counter, % slider, photo), downtime /
///                   bottleneck sheets, issue → next stage
///   QC entry        pass qty, reject qty (+ reason/photo) → Rework / Scrap
///
/// One controller spans every screen so the loaded jobs, the selected job and
/// its trail survive navigation. Reads/writes go through [repo]; when the API
/// has no jobs for this login and [kOperatorDemoFallback] is on, the repo is
/// swapped to the in-memory mock and [demoMode] shows a banner.
class OperatorController extends GetxController {
  final HomeController _home = Get.find<HomeController>();

  OperatorRepo repo = ApiOperatorRepo();
  bool get demoMode => repo.isMock;

  // ── Session (same source every other module uses) ──
  OperatorSession get session {
    final u = _home.currentUserData;
    return OperatorSession(
      compid: int.tryParse('${u?.compId ?? ''}') ?? 0,
      branchid: int.tryParse('${u?.branchId ?? ''}') ?? 0,
      userid: int.tryParse('${u?.userid ?? ''}') ?? 0,
      yearid: _yearId(u?.yearId?.toString() ?? ''),
      name: (u?.name ?? '').toString(),
    );
  }

  /// The write endpoints want the financial-year label (e.g. `2026-27`), but
  /// the interia login answers with `yearid: ""` — fall back to the current
  /// Indian FY (April–March) so produce / qc / issue are not rejected.
  static String _yearId(String fromLogin) {
    if (fromLogin.contains('-')) return fromLogin;
    final now = DateTime.now();
    final start = now.month >= 4 ? now.year : now.year - 1;
    return '$start-${(start + 1) % 100}';
  }

  String get firstName {
    final n = session.name.trim();
    return n.isEmpty ? 'Operator' : n.split(RegExp(r'\s+')).first;
  }

  /// Stage the operator works at — the stage of the first job (all jobs
  /// issued to one operator sit at that operator's stage).
  String get myStageName => jobs.isEmpty ? '' : jobs.first.stagename;

  // ── Shell ──
  int tab = 0;

  /// Index of the Log tab (Home · My Work · Log).
  static const int logTab = 2;

  /// Index of the QC tab. It is drawn before Log in the nav bar but kept last
  /// in the stack so [logTab] keeps its number.
  static const int qcTab = 3;

  void setTab(int i) {
    tab = i;
    update();
    if (i == logTab && stoppages.isEmpty && !stoppagesLoading) loadStoppages();
    if (i == qcTab) {
      // Empty queue → open on the history, which is the only thing there is
      // to look at. Once the user picks a pane themselves, respect it.
      if (!_qcPaneTouched && qcDueJobs.isEmpty) qcPane = 1;
      if (qcPane == 1) loadQcHistory();
    }
  }

  // ── Jobs ──
  List<OperatorJob> jobs = [];
  bool jobsLoading = false;
  String jobsError = '';

  /// Production jobs only (QC assignments and in-transit consignments are
  /// listed separately).
  List<OperatorJob> get workJobs =>
      jobs.where((j) => !j.isQcJob && !j.isInTransit).toList();

  /// Pieces QC sent back to me to re-produce (status "Rework").
  List<OperatorJob> get reworkJobs =>
      workJobs.where((j) => j.isReworkJob).toList();
  List<OperatorJob> get pendingJobs => workJobs
      .where((j) => !j.isReworkJob && j.state == OperatorJobState.pending)
      .toList();
  List<OperatorJob> get runningJobs => workJobs
      .where((j) => !j.isReworkJob && j.state == OperatorJobState.running)
      .toList();
  List<OperatorJob> get doneJobs =>
      workJobs.where((j) => j.state == OperatorJobState.done).toList();

  // ── My Work filter chips: all · rework · todo · running · done ──
  String workFilter = 'all';
  void setWorkFilter(String f) {
    workFilter = f;
    update();
  }

  /// My Work list in display order, honouring [workFilter].
  List<OperatorJob> get myWorkList {
    switch (workFilter) {
      case 'rework':
        return reworkJobs;
      case 'todo':
        return pendingJobs;
      case 'running':
        return runningJobs;
      case 'done':
        return doneJobs;
      case 'qc':
        return qcDueJobs;
      default:
        return [
          ...qcDueJobs,
          ...reworkJobs,
          ...pendingJobs,
          ...runningJobs,
          ...doneJobs,
        ];
    }
  }

  /// Lots this login may QC: produced, not yet checked, and the backend
  /// flagged the job as QC-able for this user (`canqc`). The backend gives QC
  /// work only to QC people, so an operator sees his own lots as "With QC"
  /// status but gets no Do-QC button.
  List<OperatorJob> get qcDueJobs =>
      jobs.where((j) => j.qcPending > 0 && j.canqc).toList();

  /// Produced lots awaiting QC by anyone (status only).
  List<OperatorJob> get awaitingQcJobs =>
      jobs.where((j) => j.qcPending > 0).toList();

  /// Can I check lots right now? (Drives the "Do QC" buttons.)
  bool get hasQcAccess => jobs.any((j) => j.canqc);

  /// I have saved at least one check before. Kept separate from
  /// [hasQcAccess] because an empty queue must not hide my history.
  bool get qcHasHistory => (qcHistoryData?.summary.entries ?? 0) > 0;

  /// Show the QC tab at all — either there is work to check, or there is a
  /// history to look back at.
  bool get showQcTab => hasQcAccess || qcHasHistory;

  double get totalIssued => workJobs.fold(0, (a, j) => a + j.issuedqty);
  double get totalProduced => workJobs.fold(0, (a, j) => a + j.producedqty);
  double get totalQcPassed => jobs.fold(0, (a, j) => a + j.qcqty);
  double get totalRejected => jobs.fold(0, (a, j) => a + j.rejectqty);
  double get overallPct =>
      totalIssued <= 0 ? 0 : (totalProduced / totalIssued).clamp(0, 1) * 100;

  @override
  void onInit() {
    super.onInit();
    loadJobs();
  }

  @override
  void onClose() {
    issueQtyCtrl.dispose();
    batchNoCtrl.dispose();
    qcPassCtrl.dispose();
    qcRejectCtrl.dispose();
    qcRemarksCtrl.dispose();
    produceRemarksCtrl.dispose();
    reworkQtyCtrl.dispose();
    reworkNotesCtrl.dispose();
    qcSearchCtrl.dispose();
    _qcSearchTimer?.cancel();
    super.onClose();
  }

  /// Saved % / WIP per job key, so the job CARDS show partial work too —
  /// `myjobs` only carries produced/issued, so a piece at 60% would read 0.
  /// Filled from `progressget` (one call per unfinished job) after a load.
  Map<String, ({double pct, double wip})> jobProgress = {};

  /// Fraction 0..1 for a job card: finished pieces + the work inside the
  /// pieces in progress (10 pcs, 4 done, 2 at 50% = 5/10).
  double jobFraction(OperatorJob j) {
    if (j.issuedqty <= 0) return 0;
    final p = jobProgress[j.key];
    final balance = (j.issuedqty - j.producedqty).clamp(0, double.infinity);
    var wipWork = 0.0;
    if (p != null && p.pct > 0 && balance > 0) {
      final pieces = p.wip > 0 ? p.wip : 1.0;
      wipWork = (pieces > balance ? balance : pieces) * p.pct / 100;
    }
    return ((j.producedqty + wipWork) / j.issuedqty).clamp(0, 1).toDouble();
  }

  /// "1 pc at 60%" for the card subtitle, or '' when nothing is part-done.
  String wipNote(OperatorJob j) {
    final p = jobProgress[j.key];
    if (p == null || p.pct <= 0) return '';
    if ((j.issuedqty - j.producedqty) <= 0) return '';
    final pieces = (p.wip > 0 ? p.wip : 1).round();
    return '$pieces pc${pieces == 1 ? '' : 's'} at ${p.pct.round()}%';
  }

  /// Progress of every unfinished job, for the cards. `progressget` needs a
  /// challanid, so it is one call each — the operator has a handful of jobs.
  Future<void> _loadJobProgress() async {
    final open = jobs
        .where((j) => !j.isQcJob && !j.isInTransit && j.balanceqty > 0)
        .toList();
    if (open.isEmpty) return;
    final rows = await Future.wait(
      open.map(
        (j) => repo
            .progressGet(session, j.challanid, j.itemid, j.stageid)
            .catchError(
              (_) => OperatorResult<List<ProgressRow>>(ok: false, message: ''),
            ),
      ),
    );
    for (var i = 0; i < open.length; i++) {
      final j = open[i];
      // History rows come back newest first — the first match is the latest
      // state of my stage.
      final mine = (rows[i].data ?? []).where(
        (r) =>
            (r.stageid == 0 || r.stageid == j.stageid) &&
            (r.itemid == 0 || r.itemid == j.itemid),
      );
      if (mine.isEmpty) continue;
      final r = mine.first;
      if (r.progresspct > 0) {
        jobProgress[j.key] = (pct: r.progresspct, wip: r.wipqty);
      }
    }
    update();
  }

  Future<void> loadJobs() async {
    jobsLoading = true;
    jobsError = '';
    update();
    loadIncoming(); // consignments in transit to me, independent of jobs
    // One cheap call so the QC tab can appear for someone who has checks in
    // their past but nothing waiting right now — which is the normal state
    // for a QC hand at the start of a shift.
    loadQcHistory();
    try {
      var res = await repo.myJobs(session);
      // Demo fallback: the API answered but has nothing for this login.
      if (!repo.isMock &&
          kOperatorDemoFallback &&
          res.ok &&
          (res.data ?? []).isEmpty) {
        repo = MockOperatorRepo.instance;
        res = await repo.myJobs(session);
      }
      if (res.ok) {
        jobs = res.data ?? [];
        _mergeIncoming();
        _loadJobProgress(); // cards show part-done pieces; don't block the list
        if (jobs.isEmpty) {
          jobsError = res.message.isNotEmpty
              ? res.message
              : 'No jobs issued to you yet.';
        }
      } else {
        jobsError = res.message.isNotEmpty
            ? res.message
            : 'Could not load jobs.';
      }
    } catch (e) {
      jobsError = '$e';
    } finally {
      jobsLoading = false;
      if (tab == qcTab && !showQcTab) tab = 0;
      update();
    }
  }

  // ── Job workspace ──
  OperatorJob? job;
  List<JobStageRow> trail = [];
  NextStage? next;
  bool jobLoading = false;

  /// Qty already sent to the next stage — so "to issue" = QC passed − this.
  /// Best of three sources: the next stage's `issuedqty` on the trail
  /// ([issuedForwardTrail]), the next stage's own ledger rows
  /// ([_downstreamEvidence]) and what this device issued itself
  /// ([_localIssued]). The trail comes back empty since 2026-09-23, so the
  /// other two are what stop the same lot being issued twice.
  double issuedForward = 0;
  double issuedForwardTrail = 0;
  double get toIssue =>
      job == null ? 0 : (job!.qcqty - issuedForward).clamp(0, double.infinity);

  /// The lock is inferred (device memory / downstream ledger), not stated by
  /// the server trail — the operator may clear it if the lot came back.
  bool get issueLockIsLocal =>
      issuedForward > 0 && issuedForwardTrail < issuedForward;

  /// Jobs whose downstream evidence the operator overrode this session.
  final Set<String> _evidenceIgnored = {};

  static const _kIssuedFwd = 'op_issued_fwd';
  String _issuedKey(OperatorJob j) => '${session.userid}:${j.key}';

  Map<String, dynamic> _issuedMap() {
    try {
      final m = GetStorage().read(_kIssuedFwd);
      if (m is Map) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return {};
  }

  double _localIssued(OperatorJob j) =>
      (num.tryParse('${_issuedMap()[_issuedKey(j)] ?? 0}') ?? 0).toDouble();

  void _rememberIssued(OperatorJob j, double qty) {
    final m = _issuedMap();
    m[_issuedKey(j)] = _localIssued(j) + qty;
    try {
      GetStorage().write(_kIssuedFwd, m);
    } catch (_) {}
  }

  /// Recompute [issuedForward] for [j]: the server's own figure first
  /// (`issuedfwdqty` on the row, live since 2026-09-23), else what the trail
  /// shows the next stage holding, else inference.
  void _syncIssuedForward(OperatorJob j) {
    // The server states it → take it as the whole truth. It DROPS when the
    // next stage rejects a consignment, so blending it with the trail, the
    // downstream ledger or this phone's memory (all of which only ever grow)
    // would keep the Issue card locked on a lot that has come back.
    if (j.hasIssuedFwd) {
      issuedForwardTrail = j.issuedfwdqty;
      issuedForward = j.issuedfwdqty;
      return;
    }
    issuedForwardTrail = j.issuedfwdqty;
    if (next != null && !next!.isLast) {
      final row = trail.where((r) => r.stageid == next!.stageid).firstOrNull;
      // Only qty that truly reached the next stage counts. NOT `itemqty` —
      // that is the planned qty and is repeated on every unreached stage.
      for (final v in [row?.issuedqty ?? 0, row?.receivedqty ?? 0]) {
        if (v > issuedForwardTrail) issuedForwardTrail = v;
      }
    }
    final evidence = _evidenceIgnored.contains(_issuedKey(j))
        ? 0.0
        : _downstreamEvidence(j);
    final local = _localIssued(j);
    issuedForward = [
      issuedForwardTrail,
      evidence,
      local,
    ].reduce((a, b) => a > b ? a : b);
  }

  /// The route is per challan and its stages come with a `seq` — keep the
  /// rows in that order so the trail reads start → finish.
  static List<JobStageRow> _inRouteOrder(List<JobStageRow> rows) =>
      List<JobStageRow>.of(rows)..sort((a, b) => a.seq.compareTo(b.seq));

  /// Every stage's ledger rows for the open job (`entries` with stageid 0).
  List<LedgerEntry> _allEntries = [];

  /// Ledger evidence: the next stage can't have worked on pieces that never
  /// reached it, so its produced / QC'd qty is a floor for "issued forward".
  /// Only rows dated on/after my first QC pass count — on a route that
  /// revisits a stage (Carpantry → Paint → Carpantry) the earlier pass must
  /// not be mistaken for my issue.
  double _downstreamEvidence(OperatorJob j) {
    final n = next;
    if (n == null || n.isLast) return 0;
    final myQcDays = _allEntries
        .where(
          (e) =>
              (e.stageid == 0 || e.stageid == j.stageid) &&
              e.isQc &&
              !e.isLoaderEvent,
        )
        .map((e) => e.day)
        .toList();
    if (myQcDays.isEmpty) return 0; // nothing could have been issued yet
    final since = myQcDays.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    double produced = 0, qc = 0;
    for (final e in _allEntries.where(
      (e) =>
          e.stageid == n.stageid &&
          e.day.compareTo(since) >= 0 &&
          !e.isLoaderEvent,
    )) {
      if (e.isProduce) produced += e.qty;
      if (e.isQc || e.isReject) qc += e.qty;
    }
    return produced > qc ? produced : qc;
  }

  /// "Sent back to me / issued in error" — drop the device memory for the
  /// open job so it can be issued again.
  void forgetIssued() {
    final j = job;
    if (j == null) return;
    _evidenceIgnored.add(_issuedKey(j));
    final m = _issuedMap()..remove(_issuedKey(j));
    try {
      GetStorage().write(_kIssuedFwd, m);
    } catch (_) {}
    _syncIssuedForward(j);
    issueQtyCtrl.text = toIssue > 0 ? fmtQty(toIssue) : '';
    update();
  }

  // Production entry
  int producedDelta = 0; // new completed pieces since the last save
  double piecePct = 0; // % done on the pieces in progress (slider)
  double savedPct = 0; // what the server has

  /// Batch work: how many pieces the % applies to. 0 = "the next piece"
  /// (single-piece behaviour). Capped at the balance.
  int wipQty = 0;
  int savedWip = 0;
  List<PickedAttachment> producePhotos = [];

  /// Free-text note saved with the produce / progress entry ("2 pcs pending
  /// polish", "machine slow"). Goes to `remarks` on both calls.
  final TextEditingController produceRemarksCtrl = TextEditingController();

  /// Date the produce entry is booked on. Defaults to today; the operator
  /// can back-date it (yesterday's pieces entered this morning).
  DateTime entryDate = DateTime.now();

  /// Day-wise history of the open job (`interia/entries`).
  List<LedgerEntry> entries = [];

  /// Photos filed against each entry id (attachment/list per entry).
  Map<int, List<AttachmentItem>> entryPhotos = {};
  bool entriesLoading = false;
  bool saving = false;

  // Issue entry
  final TextEditingController issueQtyCtrl = TextEditingController();
  final TextEditingController batchNoCtrl = TextEditingController();

  Future<void> openJob(OperatorJob j) async {
    job = j;
    trail = [];
    next = null;
    issuedForward = 0;
    producedDelta = 0;
    piecePct = 0;
    savedPct = 0;
    wipQty = 0;
    savedWip = 0;
    producePhotos = [];
    produceRemarksCtrl.clear();
    gallery = [];
    entries = [];
    entryDate = DateTime.now();
    batchNoCtrl.clear();
    issueQtyCtrl.text = '';
    jobLoading = true;
    update();
    loadGallery(); // independent of the trail — don't hold the screen for it
    loadEntries();
    try {
      final s = session;
      final results = await Future.wait([
        repo.jobStages(s, j.challanid, j.itemid),
        repo.nextStage(s, j.stageid, j.challanid),
        repo.progressGet(s, j.challanid, j.itemid, j.stageid),
      ]);
      trail = _inRouteOrder(
        (results[0] as OperatorResult<List<JobStageRow>>).data ?? [],
      );
      next = (results[1] as OperatorResult<NextStage>).data;
      final rows = (results[2] as OperatorResult<List<ProgressRow>>).data ?? [];
      final mine = rows.where(
        (r) =>
            (r.stageid == 0 || r.stageid == j.stageid) &&
            (r.itemid == 0 || r.itemid == j.itemid),
      );
      savedPct = mine.isEmpty ? 0 : mine.first.progresspct.clamp(0, 100);
      piecePct = savedPct;
      savedWip = mine.isEmpty ? 0 : mine.first.wipqty.round();
      wipQty = savedWip.clamp(0, balanceNow.round());
      _syncIssuedForward(j);
      issueQtyCtrl.text = toIssue > 0 ? fmtQty(toIssue) : '';
    } finally {
      jobLoading = false;
      update();
    }
  }

  /// Pieces completed = server produced + local delta (not yet saved).
  double get producedNow => (job?.producedqty ?? 0) + producedDelta;
  double get balanceNow => (job?.issuedqty ?? 0) - producedNow;
  bool get allPiecesDone => job != null && balanceNow <= 0;

  /// Pieces the slider applies to: the WIP batch, or 1 (the next piece).
  int get wipPieces => wipQty > 0 ? wipQty : (balanceNow > 0 ? 1 : 0);

  /// Work done inside the unfinished pieces, in piece-equivalents
  /// (20 pcs at 30% = 6 pcs of work).
  double get wipWork => wipPieces * piecePct / 100;

  /// Pieces not yet touched at all.
  double get notStarted =>
      (balanceNow - wipPieces).clamp(0, double.infinity).toDouble();

  /// Overall job completion incl. partial work: (produced + wip work) / issued.
  double get jobPct {
    final issued = job?.issuedqty ?? 0;
    if (issued <= 0) return 0;
    return ((producedNow + wipWork) / issued * 100).clamp(0, 100);
  }

  void setWipQty(int n) {
    wipQty = n.clamp(0, balanceNow.round());
    update();
  }

  void incWip() => setWipQty(wipQty + 1);
  void decWip() => setWipQty(wipQty - 1);

  /// A piece counted as produced is no longer "in progress": drop it from the
  /// WIP batch, and once nothing is part-done reset the % to 0 so the next
  /// piece starts fresh. Without this the slider kept the old 60% after "+".
  void _consumeWip(int finished) {
    if (finished <= 0) return;
    if (wipQty > 0) {
      wipQty = (wipQty - finished).clamp(0, 1 << 30);
      if (wipQty == 0) piecePct = 0;
    } else {
      piecePct = 0;
    }
  }

  void incProduced() {
    if (balanceNow <= 0) return;
    producedDelta++;
    _consumeWip(1);
    if (wipQty > balanceNow) wipQty = balanceNow.round();
    update();
  }

  void decProduced() {
    if (producedDelta <= 0) return;
    producedDelta--;
    update();
  }

  /// Keyboard entry: set the new-pieces count directly (500-pc lots).
  /// Clamped to what is still open on the job.
  void setProducedDelta(int n) {
    final maxNew = ((job?.issuedqty ?? 0) - (job?.producedqty ?? 0)).round();
    final wanted = n.clamp(0, maxNew < 0 ? 0 : maxNew);
    _consumeWip(wanted - producedDelta);
    producedDelta = wanted;
    if (wipQty > balanceNow) wipQty = balanceNow.round();
    update();
  }

  /// Slider: % done on the WIP batch (or on the next piece when no batch is
  /// set). Hitting 100% completes those pieces (see [commitPiecePct]).
  void setPiecePct(double v) {
    piecePct = v.clamp(0, 100).roundToDouble();
    update();
  }

  /// Called when the drag ends — only then does 100% complete pieces, so a
  /// finger held at the right edge cannot tick Produced up more than once.
  /// Completes the whole WIP batch (20 pcs at 100% → Produced +20), or one
  /// piece when no batch is set; the batch then resets to 0.
  void commitPiecePct() {
    if (piecePct >= 100 && balanceNow > 0) {
      producedDelta += wipPieces;
      wipQty = 0;
      piecePct = balanceNow <= 0 ? 100 : 0;
      update();
    }
  }

  Future<void> pickProducePhotos() async {
    final picked = await pickAttachments(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked.isEmpty) return;
    producePhotos = [...producePhotos, ...picked];
    update();
  }

  void removeProducePhoto(PickedAttachment p) {
    producePhotos.remove(p);
    update();
  }

  /// "Save progress" / "Save production": produce(delta) when pieces were
  /// completed, then progress(pct) for the current piece. Photos go to the
  /// shared attachment store against the produce entry.
  Future<void> saveProduction() async {
    final j = job;
    if (j == null || saving) return;
    if (producedDelta <= 0 &&
        piecePct == savedPct &&
        wipQty == savedWip &&
        producePhotos.isEmpty) {
      opSnack('Nothing to save', 'Add a produced piece or move the progress.');
      return;
    }
    saving = true;
    update();
    try {
      final s = session;
      // Photos are filed against the entry they were saved with (the produce
      // row id), so the log can show them under that day. A progress-only
      // save files them against the progress update instead (`imagepath`).
      int recordid = j.challanid;
      final note = produceRemarksCtrl.text.trim();
      final progressOnly = producedDelta <= 0;
      // Progress photos go through interia/uploadimage → S3 keys, which the
      // progress call attaches to that one update.
      var progressKeys = <String>[];
      if (progressOnly && producePhotos.isNotEmpty) {
        progressKeys = await _uploadKeys(producePhotos);
      }
      if (producedDelta > 0) {
        final r = await repo.produce(
          s,
          j,
          producedDelta.toDouble(),
          entrydate: entryDate,
          remarks: note,
        );
        if (!r.ok) {
          opSnack('Not saved', r.message);
          return;
        }
        j.producedqty += producedDelta;
        j.balanceqty = j.issuedqty - j.producedqty;
        producedDelta = 0;
        if (r.id > 0) recordid = r.id;
      }
      // Every piece produced → the stage is 100% done, whatever the slider
      // was left at (the part-done piece became a whole one).
      final pctToSave = balanceNow <= 0 ? 100.0 : piecePct;
      // `produce` has no remarks field (checked against the server's own
      // Swagger) — `progress` does and returns it on progressget, so a typed
      // note is pushed there even when the % itself did not move. Each call
      // appends its own history row.
      if (pctToSave != savedPct ||
          wipQty != savedWip ||
          note.isNotEmpty ||
          progressKeys.isNotEmpty) {
        final r = await repo.progress(
          s,
          j,
          pctToSave,
          wipQty.toDouble(),
          remarks: note,
          imageKeys: progressKeys,
        );
        if (!r.ok) {
          opSnack('Progress not saved', r.message);
        } else {
          savedPct = pctToSave;
          savedWip = wipQty;
          // Keep the job list's bar in step with what was just saved.
          jobProgress[j.key] = (pct: pctToSave, wip: wipQty.toDouble());
        }
      }
      produceRemarksCtrl.clear();
      if (!progressOnly && producePhotos.isNotEmpty) {
        final failed = await _uploadAttachments(
          producePhotos,
          j,
          recordid: recordid,
        );
        if (failed.isNotEmpty) {
          opSnack('Photo upload', failed);
        }
      }
      producePhotos = [];
      opSnack(
        'Saved',
        j.balanceqty <= 0
            ? 'All ${fmtQty(j.issuedqty)} pcs produced. Next: QC.'
            : 'Produced ${fmtQty(j.producedqty)} / ${fmtQty(j.issuedqty)} · ${wipQty > 0 ? '$wipQty pcs' : 'next piece'} at ${piecePct.toStringAsFixed(0)}%.',
      );
      await _refreshJob();
    } finally {
      saving = false;
      update();
    }
  }

  /// Attachment key from the API doc ("e.g. StageProduction"). Photos are
  /// filed per CHALLAN so one gallery shows everything taken on the job
  /// (produce entries + QC), and the web ERP can read them under one record.
  static const String attachmentModule = 'StageProduction';

  /// Photo gallery of the open job (`attachment/list`).
  List<AttachmentItem> gallery = [];
  bool galleryLoading = false;

  /// Progress history of the open job's stage (`progressget`, newest first).
  List<ProgressRow> progressRows = [];

  Future<void> loadEntries() async {
    final j = job;
    if (j == null) return;
    entriesLoading = true;
    update();
    try {
      // All stages in one call: my stage feeds the log, the next stage's
      // rows prove what already reached it (see _syncIssuedForward). The
      // progress history is a second call — `entries` carries produce / QC
      // only, progress lives in its own table.
      final results = await Future.wait([
        repo.entries(session, j, stageid: 0),
        repo.progressGet(session, j.challanid, j.itemid, j.stageid),
      ]);
      final r = results[0] as OperatorResult<List<LedgerEntry>>;
      final prog = results[1] as OperatorResult<List<ProgressRow>>;
      _allEntries = r.data ?? [];
      progressRows = (prog.data ?? [])
          .where((p) => p.stageid == 0 || p.stageid == j.stageid)
          .toList();
      // Produce / QC rows + every progress update, so "60% done" sits in the
      // day-wise log next to them.
      entries = [
        ..._allEntries.where((e) => e.stageid == 0 || e.stageid == j.stageid),
        ...progressRows.map(
          (p) => LedgerEntry.fromProgress(p, userid: session.userid),
        ),
      ]..sort((a, b) => b.entrydate.compareTo(a.entrydate));
      _syncIssuedForward(j);
      issueQtyCtrl.text = toIssue > 0 ? fmtQty(toIssue) : '';
      final server = entries.where((e) => e.id > 0).toList();
      if (!repo.isMock && server.isNotEmpty) {
        // One list call per entry — entries per job are few (one per save).
        final compid = session.compid.toString();
        final lists = await Future.wait(
          server.map(
            (e) => AttachmentRepo.list(
              compid: compid,
              modulekey: attachmentModule,
              recordid: e.id,
            ),
          ),
        );
        entryPhotos = {
          for (var i = 0; i < server.length; i++)
            if (lists[i].isNotEmpty) server[i].id: lists[i],
        };
      } else {
        entryPhotos = {};
      }
    } finally {
      entriesLoading = false;
      update();
    }
  }

  /// Entries grouped by calendar day, newest day first.
  Map<String, List<LedgerEntry>> get entriesByDay {
    final m = <String, List<LedgerEntry>>{};
    for (final e in entries) {
      (m[e.day] ??= []).add(e);
    }
    return m;
  }

  void setEntryDate(DateTime d) {
    entryDate = DateTime(d.year, d.month, d.day);
    update();
  }

  Future<void> loadGallery() async {
    final j = job;
    if (j == null || repo.isMock) return;
    galleryLoading = true;
    update();
    try {
      // Progress photos no longer land here — they travel with their own
      // update (`imagepath` → `photos` on progressget), so this stays the
      // catch-all bucket for the challan.
      gallery = await AttachmentRepo.list(
        compid: session.compid.toString(),
        modulekey: attachmentModule,
        recordid: j.challanid,
      );
    } finally {
      galleryLoading = false;
      update();
    }
  }

  /// Upload against [recordid] — an entry id (produce / QC row) so the photo
  /// sits under that day in the log, or the challan id as the catch-all.
  Future<String> _uploadAttachments(
    List<PickedAttachment> files,
    OperatorJob j, {
    int? recordid,
  }) async {
    if (repo.isMock) return '';
    final s = session;
    final errors = <String>[];
    for (final f in files) {
      final err = await AttachmentRepo.upload(
        filePath: f.path,
        compid: s.compid.toString(),
        modulekey: attachmentModule,
        recordid: recordid ?? j.challanid,
        userid: s.userid.toString(),
      );
      if (err != null) errors.add('${f.name}: $err');
    }
    if (files.isNotEmpty && job?.challanid == j.challanid) {
      await loadGallery();
      await loadEntries();
    }
    return errors.join('\n');
  }

  /// Re-read jobs and re-point [job] at the fresh row (same key) so the
  /// workspace reflects the ledger after a write.
  Future<void> _refreshJob() async {
    final key = job?.key;
    await loadJobs();
    if (key == null) return;
    final fresh = jobs.where((x) => x.key == key).firstOrNull;
    if (fresh != null) {
      job = fresh;
      loadEntries();
      final r = await repo.jobStages(session, fresh.challanid, fresh.itemid);
      trail = r.data == null ? trail : _inRouteOrder(r.data!);
      _syncIssuedForward(fresh);
      issueQtyCtrl.text = toIssue > 0 ? fmtQty(toIssue) : '';
    }
    update();
  }

  // ── Re-produce (Rework job) ──
  //
  // A lot QC rejected with disposition Rework comes back as `status: "Rework"`
  // with `balanceqty` = pieces to redo. The operator re-produces them with a
  // plain `produce` call (producedqty = qty); the backend then closes the
  // rework (balance → 0, status Done).

  OperatorJob? reworkJob;
  final TextEditingController reworkQtyCtrl = TextEditingController();
  final TextEditingController reworkNotesCtrl = TextEditingController();
  DateTime reworkDate = DateTime.now();
  List<PickedAttachment> reworkPhotos = [];

  /// Who rejected / why — from the last Reject entry of the job when the
  /// myjobs row itself does not carry it.
  String reworkFlaggedBy = '';
  String reworkReason = '';

  double get reworkQtyEntered =>
      double.tryParse(reworkQtyCtrl.text.trim()) ?? 0;

  Future<void> openRework(OperatorJob j) async {
    reworkJob = j;
    reworkQtyCtrl.text = fmtQty(j.reworkQty);
    reworkNotesCtrl.clear();
    reworkDate = DateTime.now();
    reworkPhotos = [];
    reworkFlaggedBy = j.rejectedby;
    reworkReason = j.rejectreason;
    update();
    if (reworkFlaggedBy.isEmpty || reworkReason.isEmpty) {
      final r = await repo.entries(session, j);
      // Only a QC rejection explains a Rework job — a loader rejection is a
      // different event that also starts with "Rejected".
      final rejects =
          (r.data ?? []).where((e) => e.isReject && !e.isLoaderEvent).toList()
            ..sort((a, b) => b.entrydate.compareTo(a.entrydate));
      if (rejects.isNotEmpty) {
        if (reworkFlaggedBy.isEmpty) reworkFlaggedBy = rejects.first.username;
        if (reworkReason.isEmpty) {
          reworkReason = rejects.first.remarks.isNotEmpty
              ? rejects.first.remarks
              : rejects.first.disposition;
        }
      }
      update();
    }
  }

  void setReworkDate(DateTime d) {
    reworkDate = DateTime(d.year, d.month, d.day);
    update();
  }

  void reworkChanged() => update();

  void setReworkMax() {
    reworkQtyCtrl.text = fmtQty(reworkJob?.reworkQty ?? 0);
    update();
  }

  Future<void> pickReworkPhotos() async {
    final picked = await pickAttachments(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked.isEmpty) return;
    reworkPhotos = [...reworkPhotos, ...picked];
    update();
  }

  void removeReworkPhoto(PickedAttachment p) {
    reworkPhotos.remove(p);
    update();
  }

  /// Returns true when saved (caller pops the screen).
  Future<bool> saveRework() async {
    final j = reworkJob;
    if (j == null || saving) return false;
    final qty = reworkQtyEntered;
    if (qty <= 0) {
      opSnack('Check qty', 'Enter the quantity produced.');
      return false;
    }
    if (qty > j.reworkQty) {
      opSnack(
        'Check qty',
        'Only ${fmtQty(j.reworkQty)} pcs are due for rework.',
      );
      return false;
    }
    saving = true;
    update();
    try {
      final r = await repo.produce(
        session,
        j,
        qty,
        entrydate: reworkDate,
        remarks: reworkNotesCtrl.text.trim(),
      );
      if (!r.ok) {
        opSnack('Not saved', r.message);
        return false;
      }
      if (reworkPhotos.isNotEmpty) {
        final failed = await _uploadAttachments(
          reworkPhotos,
          j,
          recordid: r.id > 0 ? r.id : null,
        );
        reworkPhotos = [];
        if (failed.isNotEmpty) opSnack('Photo upload', failed);
      }
      final left = j.reworkQty - qty;
      opSnack(
        'Saved',
        left <= 0
            ? 'Rework complete — ${fmtQty(qty)} pcs re-produced.'
            : 'Re-produced ${fmtQty(qty)} · ${fmtQty(left)} still due.',
      );
      await loadJobs();
      return true;
    } finally {
      saving = false;
      update();
    }
  }

  // ── Issue to next stage ──
  bool get canIssue =>
      job != null && next != null && !next!.isLast && toIssue > 0;

  /// Loader handover is MANDATORY (2026-09-23): every issue goes through the
  /// gate-pass sheet (loader / date-time / receipt + item photos) and the
  /// next stage signs for it. Kept as a constant so [issueForward] without a
  /// gate pass stays unreachable from the UI.
  static const bool sendViaLoader = true;

  /// Qty the operator typed on the Issue card (validated).
  double? _issueQtyOrWarn() {
    final qty = double.tryParse(issueQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      opSnack('Check qty', 'Enter the qty to issue.');
      return null;
    }
    if (qty > toIssue) {
      opSnack(
        'Check qty',
        'Only QC-passed qty can be issued (max ${fmtQty(toIssue)}).',
      );
      return null;
    }
    return qty;
  }

  /// Plain issue (loader OFF) or the final step of the gate-pass sheet.
  /// Returns true when issued.
  Future<bool> issueForward({GatePass? gatePass}) async {
    final j = job;
    if (j == null || saving) return false;
    final qty = _issueQtyOrWarn();
    if (qty == null) return false;
    saving = true;
    update();
    try {
      final r = await repo.issue(
        session,
        j,
        qty,
        to: next,
        batchno: batchNoCtrl.text.trim(),
        gatePass: gatePass,
      );
      if (!r.ok) {
        opSnack('Not issued', r.message);
        return false;
      }
      opSnack(
        'Issued',
        r.message.isNotEmpty
            ? r.message
            : 'Issued ${fmtQty(qty)} to ${r.tostagename}.',
      );
      _rememberIssued(j, qty); // survives reload even with no server trail
      issuedForward += qty;
      await _refreshJob();
      return true;
    } finally {
      saving = false;
      update();
    }
  }

  /// Gate-pass sheet submit: upload the photos (S3 keys) then issue.
  Future<bool> issueViaLoader({
    required String loadername,
    required DateTime issuedAt,
    String remarks = '',
    List<PickedAttachment> receiptPhotos = const [],
    List<PickedAttachment> itemPhotos = const [],
  }) async {
    if (loadername.trim().isEmpty) {
      opSnack('Loader name', 'Enter the loader name.');
      return false;
    }
    if (_issueQtyOrWarn() == null) return false;
    _rememberLoader(loadername);
    saving = true;
    update();
    List<String> receiptKeys, itemKeys;
    try {
      receiptKeys = await _uploadKeys(receiptPhotos);
      itemKeys = await _uploadKeys(itemPhotos);
    } catch (e) {
      saving = false;
      update();
      opSnack('Photo upload failed', '$e');
      return false;
    }
    saving = false;
    return issueForward(
      gatePass: GatePass(
        loadername: loadername.trim(),
        issuedAt: issuedAt,
        remarks: remarks.trim(),
        receiptKeys: receiptKeys,
        itemKeys: itemKeys,
      ),
    );
  }

  /// `interia/uploadimage` for each file → S3 keys. Throws on the first
  /// failure so the caller can abort before writing the ledger.
  Future<List<String>> _uploadKeys(List<PickedAttachment> files) async {
    final keys = <String>[];
    for (final f in files) {
      final up = await repo.uploadImage(session, f.path);
      if (!up.ok || up.data == null) {
        throw Exception('${f.name}: ${up.message}');
      }
      keys.add(up.data!.filepath);
    }
    return keys;
  }

  // ── Incoming consignments (loader handover, receiving side) ──
  List<Consignment> incoming = [];

  /// Last loader name this user typed (gate pass or receive) — remembered
  /// on the device so the field can be pre-filled next time.
  static const _kLastLoader = 'op_last_loader';
  String get lastLoaderName {
    try {
      return (GetStorage().read<String>(_kLastLoader) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  void _rememberLoader(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    try {
      GetStorage().write(_kLastLoader, n);
    } catch (_) {}
  }

  /// Best guess for the loader on a consignment: its own name, else the most
  /// recent name on any other in-transit consignment, else the last one typed.
  String suggestedLoaderFor(Consignment cn) {
    if (cn.loadername.trim().isNotEmpty) return cn.loadername.trim();
    final others =
        incoming.where((o) => o.loadername.trim().isNotEmpty).toList()
          ..sort((a, b) => ' '.compareTo(' '));
    if (others.isNotEmpty) return others.first.loadername.trim();
    return lastLoaderName;
  }

  bool incomingLoading = false;

  /// In-transit consignments: from `interia/incoming` when it exists, plus
  /// any `myjobs` row the backend flags `status: "In Transit"` (lighter
  /// contract — same fields on the row).
  List<Consignment> _incomingFromApi = [];
  List<Consignment> get _incomingFromJobs =>
      jobs.where((j) => j.isInTransit).map((j) => j.toConsignment()).toList();

  void _mergeIncoming() {
    // Same consignment can appear in both lists (each with different fields
    // filled) — key by consignment id when present, else challan/item/stage.
    String key(Consignment c) => c.consignmentid > 0
        ? '#${c.consignmentid}'
        : '${c.challanid}/${c.itemid}/${c.tostageid}';
    final byKey = <String, Consignment>{};
    for (final c in [..._incomingFromApi, ..._incomingFromJobs]) {
      final k = key(c);
      byKey[k] = byKey.containsKey(k) ? byKey[k]!.merge(c) : c;
    }
    incoming = byKey.values.toList();
  }

  Future<void> loadIncoming() async {
    incomingLoading = true;
    update();
    try {
      final r = await repo.incoming(session);
      _incomingFromApi = (r.data ?? []).where((c) => c.inTransit).toList();
      _mergeIncoming();
    } finally {
      incomingLoading = false;
      update();
    }
  }

  /// Consignment still in transit for this job, if any. While one exists the
  /// job's production stays locked ("accept the consignment first").
  Consignment? pendingConsignmentFor(OperatorJob j) => incoming
      .where(
        (c) =>
            c.challanid == j.challanid &&
            (c.itemid == 0 || j.itemid == 0 || c.itemid == j.itemid) &&
            (c.tostageid == 0 || c.tostageid == j.stageid),
      )
      .firstOrNull;

  /// Accept / Reject a consignment. Uploads the signed receipt + item photos
  /// first (keys), then posts `receive`. Returns true when saved.
  /// Book a consignment in. The receipt may be split: [qtyaccepted] is taken
  /// in here and [qtyrejected] goes back to the sender to be produced again.
  /// The receiver cannot scrap anything — writing stock off stays with the
  /// sending stage's QC.
  Future<bool> receiveConsignment(
    Consignment cn, {
    required String loadername,
    required DateTime receivedAt,
    required double qtyaccepted,
    required double qtyrejected,
    String reason = '',
    List<PickedAttachment> signedReceipt = const [],
    List<PickedAttachment> itemPhotos = const [],
    String remarks = '',
  }) async {
    if (saving) return false;
    final accept = qtyaccepted > 0;
    if (qtyaccepted + qtyrejected != cn.qty) {
      opSnack(
        'Check qty',
        'Accepted + rejected must add up to the ${fmtQty(cn.qty)} sent.',
      );
      return false;
    }
    if (qtyaccepted <= 0 && qtyrejected <= 0) {
      opSnack('Check qty', 'Enter how much you are accepting or rejecting.');
      return false;
    }
    // Anything taken in has to be signed for; anything sent back needs a
    // reason so the sender knows what went wrong.
    if (accept && signedReceipt.isEmpty) {
      opSnack('Signed receipt', 'Upload the signed issue receipt to accept.');
      return false;
    }
    if (qtyrejected > 0 && reason.trim().isEmpty) {
      opSnack('Reason', 'Give a reason for rejecting.');
      return false;
    }
    saving = true;
    update();
    try {
      if (accept) _rememberLoader(loadername);
      final receiptKeys = await _uploadKeys(signedReceipt);
      final itemKeys = await _uploadKeys(itemPhotos);
      final r = await repo.receive(
        session,
        cn,
        loadername: loadername.trim(),
        receivedAt: receivedAt,
        qtyaccepted: qtyaccepted,
        qtyrejected: qtyrejected,
        reason: reason.trim(),
        signedReceiptKeys: receiptKeys,
        itemImageKeys: itemKeys,
        remarks: remarks.trim(),
      );
      if (!r.ok) {
        opSnack('Not saved', r.message);
        return false;
      }
      opSnack(
        qtyrejected <= 0
            ? 'Accepted'
            : (accept ? 'Partly accepted' : 'Rejected'),
        r.message.isNotEmpty
            ? r.message
            : (qtyrejected <= 0
                  ? 'Consignment received — production unlocked.'
                  : accept
                  ? 'Took in ${fmtQty(qtyaccepted)}; sent ${fmtQty(qtyrejected)} back to be produced again.'
                  : 'Sent back to ${cn.fromstagename} to be produced again.'),
      );
      await loadIncoming();
      await loadJobs();
      return true;
    } catch (e) {
      opSnack('Photo upload failed', '$e');
      return false;
    } finally {
      saving = false;
      update();
    }
  }

  // ── Downtime / Bottleneck ──
  Future<bool> logStoppage({
    required bool downtime,
    required String reason,
    OperatorJob? forJob,
    String remarks = '',
    DateTime? from,
    DateTime? to,
    DateTime? entrydate,
    PickedAttachment? photo,
  }) async {
    if (reason.trim().isEmpty) {
      opSnack('Reason required', 'Pick a reason.');
      return false;
    }
    if (from != null && to != null && !to.isAfter(from)) {
      opSnack('Check time', 'To time must be after From.');
      return false;
    }
    saving = true;
    update();
    try {
      String imagepath = '';
      if (photo != null) {
        final up = await repo.uploadImage(session, photo.path);
        if (!up.ok || up.data == null) {
          opSnack('Photo upload failed', up.message);
          return false;
        }
        imagepath = up.data!.filepath;
      }
      final mins = (from != null && to != null)
          ? to.difference(from).inMinutes
          : 0;
      final r = await repo.stoppage(
        session,
        downtime: downtime,
        reason: reason.trim(),
        job: forJob,
        remarks: remarks.trim(),
        from: from,
        to: to,
        durationmin: mins,
        entrydate: entrydate,
        imagepath: imagepath,
      );
      if (!r.ok) {
        opSnack('Not saved', r.message);
        return false;
      }
      opSnack(
        'Saved',
        r.message.isNotEmpty
            ? r.message
            : (downtime ? 'Downtime saved.' : 'Bottleneck saved.'),
      );
      stoppages = [];
      if (tab == logTab) loadStoppages();
      return true;
    } finally {
      saving = false;
      update();
    }
  }

  // ── Stoppages tab ──
  List<Stoppage> stoppages = [];
  bool stoppagesLoading = false;
  String stoppageFilter = ''; // '' | Downtime | Bottleneck

  void setStoppageFilter(String f) {
    stoppageFilter = f;
    update();
  }

  List<Stoppage> get visibleStoppages => stoppageFilter.isEmpty
      ? stoppages
      : stoppages
            .where((s) => s.type.toLowerCase() == stoppageFilter.toLowerCase())
            .toList();

  Future<void> loadStoppages() async {
    stoppagesLoading = true;
    update();
    try {
      final r = await repo.stoppages(session);
      stoppages = r.data ?? [];
    } finally {
      stoppagesLoading = false;
      update();
    }
  }

  // ── QC entry ──
  OperatorJob? qcJob;
  final TextEditingController qcPassCtrl = TextEditingController();
  final TextEditingController qcRejectCtrl = TextEditingController();
  final TextEditingController qcRemarksCtrl = TextEditingController();
  String qcReason = '';

  /// Rework (back to the operator) or Scrap — chosen inline on the QC screen.
  String qcDisposition = 'Rework';
  void setQcDisposition(String d) {
    qcDisposition = d;
    update();
  }

  PickedAttachment? qcPhoto;
  DateTime qcDate = DateTime.now();

  void setQcDate(DateTime d) {
    qcDate = DateTime(d.year, d.month, d.day);
    update();
  }

  double get qcPass => double.tryParse(qcPassCtrl.text.trim()) ?? 0;
  double get qcReject => double.tryParse(qcRejectCtrl.text.trim()) ?? 0;

  void openQc(OperatorJob j) {
    qcJob = j;
    qcPassCtrl.text = j.qcPending > 0 ? fmtQty(j.qcPending) : '';
    qcRejectCtrl.text = '';
    qcRemarksCtrl.clear();
    qcReason = '';
    qcDisposition = 'Rework';
    qcPhoto = null;
    qcDate = DateTime.now();
    update();
  }

  void qcChanged() => update();

  void setQcReason(String r) {
    qcReason = r;
    update();
  }

  Future<void> pickQcPhoto() async {
    final picked = await pickAttachments(
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (picked.isEmpty) return;
    qcPhoto = picked.first;
    update();
  }

  void clearQcPhoto() {
    qcPhoto = null;
    update();
  }

  /// Validates the QC form; returns the message to show, or null when OK.
  String? qcValidation() {
    final j = qcJob;
    if (j == null) return 'No lot selected.';
    final p = qcPass, r = qcReject;
    if (p <= 0 && r <= 0) return 'Enter passed and/or rejected qty.';
    if (p + r > j.qcPending) {
      return 'Passed + rejected (${fmtQty(p + r)}) cannot exceed the lot (${fmtQty(j.qcPending)}).';
    }
    if (r > 0 && qcReason.isEmpty) return 'Reject reason is required.';
    if (r > 0 && qcPhoto == null) return 'A photo of the defect is required.';
    return null;
  }

  /// Save the pass part now (interia/qc). The reject part is saved by
  /// [saveQcReject] once the operator picks Rework / Scrap — qcreject records
  /// the reject in the ledger itself, so it must NOT also go through /qc.
  /// Returns true when a reject still needs a disposition.
  Future<bool?> saveQcPass() async {
    final j = qcJob;
    if (j == null || saving) return null;
    final v = qcValidation();
    if (v != null) {
      opSnack('Check QC', v);
      return null;
    }
    final p = qcPass, r = qcReject;
    if (p <= 0) return true; // reject-only lot → straight to disposition
    saving = true;
    update();
    try {
      final res = await repo.qcPass(session, j, p, entrydate: qcDate);
      if (!res.ok) {
        opSnack('QC not saved', res.message);
        return null;
      }
      j.qcqty += p;
      if (qcPhoto != null && r <= 0) {
        // Pass-only lots keep their photo in the attachment store.
        final err = await _uploadAttachments(
          [qcPhoto!],
          j,
          recordid: res.id > 0 ? res.id : null,
        );
        if (err.isNotEmpty) opSnack('Photo upload', err);
      }
      if (r <= 0) {
        opSnack('QC saved', 'Passed ${fmtQty(p)}.');
        qcHistoryDirty = true;
        await loadJobs();
        return false;
      }
      return true;
    } finally {
      saving = false;
      update();
    }
  }

  Future<bool> saveQcReject(String disposition) async {
    final j = qcJob;
    if (j == null || saving) return false;
    final r = qcReject;
    saving = true;
    update();
    try {
      String imagepath = '';
      if (qcPhoto != null) {
        final up = await repo.uploadImage(session, qcPhoto!.path);
        if (!up.ok || up.data == null) {
          opSnack('Photo upload failed', up.message);
          return false;
        }
        imagepath = up.data!.filepath;
      }
      final res = await repo.qcReject(
        session,
        j,
        r,
        disposition: disposition,
        reason: qcReason,
        remarks: qcRemarksCtrl.text.trim(),
        imagepath: imagepath,
        entrydate: qcDate,
      );
      if (!res.ok) {
        opSnack('Reject not saved', res.message);
        return false;
      }
      qcHistoryDirty = true;
      opSnack(
        'QC saved',
        qcPass > 0
            ? 'Passed ${fmtQty(qcPass)} · rejected ${fmtQty(r)} ($disposition).'
            : 'Rejected ${fmtQty(r)} ($disposition).',
      );
      await loadJobs();
      return true;
    } finally {
      saving = false;
      update();
    }
  }

  // ── QC history (interia/qchistory) ─────────────────────────────────────────
  //
  // Everything this login has ever passed or rejected. The backend groups the
  // rows by day and recomputes `summary` for the date and stage filters — but
  // NOT for `result` or `search`, so those two are applied here instead. That
  // also keeps the chip counts instant and the KPI cards honest: the cards
  // describe the range you picked, the chips describe what is in the list.

  QcHistory? qcHistoryData;
  bool qcHistoryLoading = false;
  String qcHistoryError = '';

  /// A check was just saved — refetch the next time the pane is opened.
  bool qcHistoryDirty = false;

  /// Sub-tab of the QC screen: 0 = To QC, 1 = My history.
  int qcPane = 0;
  bool _qcPaneTouched = false;
  void setQcPane(int i) {
    qcPane = i;
    _qcPaneTouched = true;
    update();
    if (i == 1) loadQcHistory();
  }

  /// today · 7 · 30 · custom. 30 days is what the endpoint defaults to.
  String qcRange = '30';
  DateTime? qcFromDate;
  DateTime? qcToDate;
  int qcStageFilter = 0;
  String qcResultFilter = 'all'; // all | passed | rejected

  final TextEditingController qcSearchCtrl = TextEditingController();
  String qcSearch = '';
  Timer? _qcSearchTimer;

  /// Search runs over the loaded rows, so debounce only to keep the list from
  /// rebuilding on every keystroke.
  void setQcSearch(String v) {
    _qcSearchTimer?.cancel();
    _qcSearchTimer = Timer(const Duration(milliseconds: 250), () {
      qcSearch = v;
      update();
    });
  }

  void setQcResultFilter(String r) {
    qcResultFilter = r;
    update();
  }

  /// Quick-range chips. Custom keeps whatever the filter sheet set.
  void setQcRange(String r) {
    if (qcRange == r && r != 'custom') return;
    qcRange = r;
    final today = DateTime.now();
    switch (r) {
      case 'today':
        qcFromDate = DateTime(today.year, today.month, today.day);
        qcToDate = qcFromDate;
      case '7':
        qcToDate = DateTime(today.year, today.month, today.day);
        qcFromDate = qcToDate!.subtract(const Duration(days: 7));
      case '30':
        qcToDate = DateTime(today.year, today.month, today.day);
        qcFromDate = qcToDate!.subtract(const Duration(days: 30));
    }
    loadQcHistory(force: true);
  }

  /// Applied by the filter sheet. Only the dates and the stage need the
  /// server; changing just the result re-filters what is already loaded.
  void applyQcFilter({
    DateTime? from,
    DateTime? to,
    required int stageid,
    required String result,
  }) {
    final datesMoved = !_sameDay(from, qcFromDate) || !_sameDay(to, qcToDate);
    final stageMoved = stageid != qcStageFilter;
    qcFromDate = from;
    qcToDate = to;
    qcStageFilter = stageid;
    qcResultFilter = result;
    // Leave the quick-range chip alone unless the dates actually moved off it.
    if (datesMoved) qcRange = 'custom';
    if (datesMoved || stageMoved) {
      loadQcHistory(force: true);
    } else {
      update();
    }
  }

  static bool _sameDay(DateTime? a, DateTime? b) => a == null || b == null
      ? a == b
      : a.year == b.year && a.month == b.month && a.day == b.day;

  void resetQcFilter() {
    qcStageFilter = 0;
    qcResultFilter = 'all';
    qcSearch = '';
    qcSearchCtrl.clear();
    qcRange = '30';
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    qcToDate = today;
    qcFromDate = today.subtract(const Duration(days: 30));
    loadQcHistory(force: true);
  }

  /// True when anything beyond the default 30-day window is on — drives the
  /// dot on the filter button.
  bool get qcFilterActive =>
      qcStageFilter > 0 || qcResultFilter != 'all' || qcRange == 'custom';

  Future<void> loadQcHistory({bool force = false}) async {
    if (qcHistoryLoading) return;
    if (qcHistoryData != null && !force && !qcHistoryDirty) return;
    qcHistoryLoading = true;
    qcHistoryError = '';
    update();
    try {
      final r = await repo.qcHistory(
        session,
        from: qcFromDate,
        to: qcToDate,
        stageid: qcStageFilter,
      );
      if (r.ok && r.data != null) {
        qcHistoryData = r.data;
        qcHistoryDirty = false;
      } else {
        qcHistoryError = r.message.isEmpty
            ? 'Could not load your QC history.'
            : r.message;
      }
    } finally {
      qcHistoryLoading = false;
      update();
    }
  }

  QcSummary get qcSummary => qcHistoryData?.summary ?? const QcSummary();

  /// "27 Aug 2026 – 26 Sep 2026", echoing the window the server actually used.
  String get qcRangeLabel {
    String f(String iso) {
      final d = DateTime.tryParse(iso);
      return d == null ? iso : DateFormat('d MMM yyyy').format(d);
    }

    final s = qcSummary;
    if (s.fromdate.isEmpty || s.todate.isEmpty) return '';
    return s.fromdate == s.todate
        ? f(s.todate)
        : '${f(s.fromdate)} – ${f(s.todate)}';
  }

  /// Rows left after the search box (the result chips are counted on these,
  /// so "Passed 31" always matches what tapping the chip shows).
  List<QcEntry> get _qcSearched {
    final h = qcHistoryData;
    if (h == null) return const [];
    final q = qcSearch.trim().toLowerCase();
    final all = h.days.expand((d) => d.entries);
    return q.isEmpty
        ? all.toList()
        : all.where((e) => e.haystack.contains(q)).toList();
  }

  int get qcCountAll => _qcSearched.length;
  int get qcCountPassed => _qcSearched.where((e) => !e.hasReject).length;
  int get qcCountRejected => _qcSearched.where((e) => e.hasReject).length;

  /// The day-grouped list the screen draws, with empty days dropped.
  List<QcDay> get qcVisibleDays {
    final h = qcHistoryData;
    if (h == null) return const [];
    final q = qcSearch.trim().toLowerCase();
    final out = <QcDay>[];
    for (final d in h.days) {
      final keep = d.entries.where((e) {
        if (q.isNotEmpty && !e.haystack.contains(q)) return false;
        return switch (qcResultFilter) {
          'passed' => !e.hasReject,
          'rejected' => e.hasReject,
          _ => true,
        };
      }).toList();
      if (keep.isNotEmpty) out.add(d.withEntries(keep));
    }
    return out;
  }
}
