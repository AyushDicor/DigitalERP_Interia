import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/attachment_repo.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
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

  /// Index of the Home tab.
  static const int homeTab = 0;

  /// Index of the Log tab (Home · My Work · Log).
  static const int logTab = 2;

  /// Index of the QC tab. It is drawn before Log in the nav bar but kept last
  /// in the stack so [logTab] keeps its number.
  static const int qcTab = 3;

  /// After anything is saved — produced, QC'd, issued, received, sent back —
  /// land the operator back on the My Jobs home with a freshly loaded list.
  ///
  /// The detail screens hold figures the server has just recalculated, so
  /// staying on them shows numbers that are already out of date. Popping
  /// back to the shell is also the only place that reloads every list at
  /// once (jobs, incoming, and the counts the tiles read).
  ///
  /// Call it AFTER any sheet has closed: it pops every route above the
  /// module, so a `Navigator.pop()` running afterwards would take the shell
  /// with it.
  Future<void> backToJobsHome() async {
    // Never pop past the module itself, even if it was opened some other
    // way than its named route.
    Get.until(
      (r) => r.settings.name == AppRoutes.productionOperator || r.isFirst,
    );
    setTab(homeTab);
    await loadJobs();
    await loadIncoming();
  }

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

  /// Production jobs only (QC assignments, in-transit consignments and send
  /// back legs are listed separately).
  ///
  /// A send back leg arrives in the very same `myjobs` list as forward work,
  /// but its numbers mean different things — `balanceqty` is "to rework
  /// here", not "to produce" — so it must never be blended in.
  List<OperatorJob> get workJobs =>
      jobs.where((j) => !j.isQcJob && !j.isInTransit && !j.isSendBack).toList();

  // ── Send back (pieces that came BACK here to be fixed) ──

  /// Every send back leg standing at this login's stage.
  List<OperatorJob> get sendBackJobs =>
      jobs.where((j) => j.isSendBack && !j.isInTransit).toList();

  /// The legs with something to do right now. The actions come from the
  /// numbers, not from `status`: one leg can have pieces to rework AND
  /// pieces ready to send on at the same time.
  List<OperatorJob> get sendBackTodo => sendBackJobs
      .where((j) => j.canReworkHere || j.canSendOn || j.canQcHere)
      .toList();

  /// My own jobs that have pieces away at another stage being fixed.
  List<OperatorJob> get awayJobs =>
      workJobs.where((j) => j.hasSentBack).toList();

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
      case 'toissue':
        return toIssueJobs;
      default:
        // Ready-to-issue sits high: it is finished work that still needs a
        // hand-off, and it would otherwise hide at the bottom under Done.
        final issuing = toIssueJobs.map((j) => j.key).toSet();
        // A send back leg holds up whichever stage is waiting for the
        // pieces, so it outranks this stage's own forward work. qcDueJobs
        // already carries the legs waiting for a QC login — don't list twice.
        final qcKeys = qcDueJobs.map((j) => j.key).toSet();
        // A packing job reads "Done" while it still needs boxes, so it
        // would otherwise sort to the very bottom.
        final packKeys = packJobs.map((j) => j.key).toSet();
        return [
          ...qcDueJobs,
          ...packJobs,
          ...sendBackJobs.where((j) => !qcKeys.contains(j.key)),
          ...toIssueJobs,
          ...reworkJobs.where(
            (j) => !issuing.contains(j.key) && !packKeys.contains(j.key),
          ),
          ...pendingJobs.where(
            (j) => !issuing.contains(j.key) && !packKeys.contains(j.key),
          ),
          ...runningJobs.where(
            (j) => !issuing.contains(j.key) && !packKeys.contains(j.key),
          ),
          ...doneJobs.where(
            (j) => !issuing.contains(j.key) && !packKeys.contains(j.key),
          ),
        ];
    }
  }

  /// Lots this login may QC: produced, not yet checked, and the backend
  /// flagged the job as QC-able for this user (`canqc`). The backend gives QC
  /// work only to QC people, so an operator sees his own lots as "With QC"
  /// status but gets no Do-QC button.
  /// A send back leg states its own waiting qty in `canqcqty`; a normal row
  /// has none, so produced-minus-checked still decides there.
  List<OperatorJob> get qcDueJobs => jobs
      .where(
        (j) => j.canqc && (j.isSendBack ? j.canqcqty > 0 : j.qcPending > 0),
      )
      .toList();

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
    for (final c in sharedQty.values) {
      c.dispose();
    }
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
        _loadIssuable(); // which finished lots still have somewhere to go
        _loadPackLeft(); // which packing jobs still need boxes
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

  /// On a send back leg the server states the cap outright (`cansendqty`);
  /// the forward arithmetic does not apply, because what was QC-passed on
  /// this leg has nothing to do with the job's own qcqty.
  double get toIssue => job == null
      ? 0
      : job!.isSendBack
      ? job!.cansendqty
      : (job!.qcqty - issuedForward).clamp(0, double.infinity);

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
    issueTarget = null;
    jobLoading = true;
    update();
    // The gallery, the day-wise log and the design pack are all independent
    // of the spinner — they are kicked off AFTER the three calls below, so
    // the screen is not waiting behind six connections on a weak link.
    try {
      final s = session;
      final results = await Future.wait([
        repo.jobStages(s, j.challanid, j.itemid),
        repo.nextStage(s, j.stageid, j.challanid, itemid: j.itemid),
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
      loadGallery();
      loadEntries();
      loadJobDesign();
      // So the Send back card can say what is actually available here
      // instead of opening onto an empty form. A stage that has handed
      // everything on has nothing to send back, and should say so.
      if (!j.isSendBack) loadSendBackOptions();
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
          returnid: j.returnid,
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
      // Straight back to a freshly loaded My Jobs, like every other save.
      // Nothing is popped between here and the shell, so this is safe to
      // call from the controller rather than the view.
      await backToJobsHome();
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

  /// Why QC sent it back. `myjobs` carries all of this since 2026-09-26;
  /// the entries fallback below stays for a row that predates that.
  String reworkFlaggedBy = '';
  String reworkReason = '';
  String reworkRemarks = '';
  String reworkWhen = '';

  /// Photos of the defect, taken by QC. Presigned and short-lived — shown
  /// straight from the job row, never cached.
  List<String> reworkRejectImages = const [];

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
    reworkRemarks = j.rejectremarks;
    reworkWhen = j.rejectedon;
    reworkRejectImages = j.rejectimages;
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
          // `note`, not `remarks`: the backend stamps its own rows
          // "QC (mobile)", and showing that where the reject reason belongs
          // reads like the reason was "QC (mobile)". `entries` still returns
          // only that boilerplate, so this fallback usually yields nothing —
          // which is right. The real reason now comes from myjobs above.
          reworkReason = rejects.first.note.isNotEmpty
              ? rejects.first.note
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
        returnid: j.returnid,
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
      job != null &&
      next != null &&
      !next!.isLast &&
      (isSplit ? nextOptions.any((o) => maxIssuableTo(o) > 0) : toIssue > 0);

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
    // On a split the cap belongs to the destination, not the card total.
    final cap = issueTarget != null ? maxIssuableTo(issueTarget!) : toIssue;
    if (qty > cap) {
      opSnack(
        'Check qty',
        'Only QC-passed qty can be issued (max ${fmtQty(cap)}${issueTarget != null ? ' to ${issueTarget!.stagename}' : ''}).',
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
        returnid: j.returnid,
        qty,
        to: _issueTo,
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
    // Nothing leaves the stage without its signed gate pass.
    if (receiptPhotos.isEmpty) {
      opSnack('Issue receipt', 'Attach the signed issue receipt photo.');
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

  /// Shared split: the same gate pass for every destination. The photos
  /// are uploaded ONCE and their keys reused, so two hand-offs of the same
  /// lot carry the same receipt rather than two half-sets.
  Future<bool> issueSharedViaLoader({
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
    final total = sharedEntered;
    if (total <= 0) {
      opSnack('Check qty', 'Enter the qty for at least one stage.');
      return false;
    }
    if (total > sharedRemaining) {
      opSnack(
        'Check qty',
        'Total is ${fmtQty(total)} but only ${fmtQty(sharedRemaining)} is '
            'left to share between the next stages.',
      );
      return false;
    }
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
    return issueSharedForward(
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
    // In part mode one job can have several consignments in transit at once
    // (one per part), so the fallback key has to name the part too.
    String key(Consignment c) => c.consignmentid > 0
        ? '#${c.consignmentid}'
        : '${c.challanid}/${c.itemid}/${c.tostageid}/${c.partid}';
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
        // Part consignments are looked up by part on the server, and a send
        // back leg by its ticket — leave either out and it is "not found".
        partid: cn.partid,
        returnid: cn.returnid,
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
    if (!kAllowScrap && d != 'Rework') return;
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
      final res = await repo.qcPass(
        session,
        j,
        returnid: j.returnid,
        p,
        entrydate: qcDate,
        remarks: qcRemarksCtrl.text.trim(),
      );
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
        returnid: j.returnid,
        // Whose work was faulty, when the checker pointed at a stage. It is
        // counted there even though the fix happens at this stage.
        faultstageid: qcFaultStageId,
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

  // ── Drawings & details (interia/jobdesign) ────────────────────────────────
  //
  // The approved technical drawings, the client's custom materials and the
  // BOM design files for the open job. The urls are presigned and expire, so
  // this is re-read every time the job screen opens or is refreshed — never
  // held over from a previous visit.

  JobDesign? design;
  bool designLoading = false;
  String designError = '';

  /// True when the job's own counts promise a pack, so the section can show a
  /// shimmer of the right shape before the call lands.
  bool get designExpected => job?.hasdesign ?? false;

  Future<void> loadJobDesign() async {
    final j = job;
    if (j == null) return;
    // Both ids are required by the endpoint; without them it answers 400.
    // An in-transit row carries them just like a normal job does.
    // `hasdesign` comes from myjobs, so a job with no pack costs no call at
    // all — that is most of them.
    if (!j.hasdesign || j.orderrefid <= 0 || j.itemid <= 0) {
      design = JobDesign.empty;
      update();
      return;
    }
    design = null;
    designError = '';
    designLoading = true;
    update();
    try {
      final r = await repo.jobDesign(session, j.orderrefid, j.itemid);
      if (r.ok && r.data != null) {
        design = r.data;
      } else {
        designError = r.message.isEmpty
            ? 'Could not load the drawings.'
            : r.message;
      }
    } catch (e) {
      designError = '$e';
    } finally {
      designLoading = false;
      update();
    }
  }

  /// Collapsed / expanded state of the section, remembered for the session so
  /// an operator who works from the drawings is not re-opening it every time.
  bool designOpen = true;
  void toggleDesign() {
    designOpen = !designOpen;
    update();
  }

  // ── Parallel routes: where this stage's work goes next ────────────────────
  //
  // One destination behaves exactly as before. Two or more is a split, and
  // the split mode decides the arithmetic:
  //   Full  — each stage owes its own full qty, so the cap is PER stage and
  //           sending to PAINT does not reduce what UPHOLSTRY still needs.
  //   Share — the stages divide the QC-passed qty, so the cap is the TOTAL.

  /// The destination the operator tapped Issue on. Null = single next stage.
  NextStageOption? issueTarget;

  /// Shared split: one qty box per destination, keyed by stage id.
  final Map<int, TextEditingController> sharedQty = {};

  /// Every destination of this stage. An API build without the list still
  /// yields one entry, so the rest of the code never special-cases it.
  List<NextStageOption> get nextOptions {
    final n = next;
    if (n == null || n.isLast) return const [];
    if (n.stages.isNotEmpty) return n.stages;
    return [
      NextStageOption(
        stageid: n.stageid,
        stagename: n.stagename,
        planqty: job?.qcqty ?? 0,
        remainingqty: toIssue,
      ),
    ];
  }

  bool get isSplit => nextOptions.length > 1;
  bool get isSharedSplit => isSplit && (next?.isShared ?? false);

  /// Cap for one destination. Per stage on a full-qty split; the shared
  /// remainder on a shared one.
  double maxIssuableTo(NextStageOption o) {
    final qc = job?.qcqty ?? 0;
    if (isSharedSplit) return sharedRemaining;
    return (qc - o.sentqty).clamp(0, double.infinity).toDouble();
  }

  /// Shared split: QC-passed minus everything already sent anywhere.
  double get sharedRemaining {
    final qc = job?.qcqty ?? 0;
    final sent = nextOptions.fold<double>(0, (a, s) => a + s.sentqty);
    return (qc - sent).clamp(0, double.infinity).toDouble();
  }

  /// What the operator has typed across the shared boxes.
  double get sharedEntered => sharedQty.values.fold<double>(
    0,
    (a, c) => a + (double.tryParse(c.text.trim()) ?? 0),
  );

  /// Fill one box per destination, defaulted to what that stage is still
  /// owed and then capped so the boxes cannot add up past the remainder.
  void prepareSharedQty() {
    for (final c in sharedQty.values) {
      c.dispose();
    }
    sharedQty.clear();
    var left = sharedRemaining;
    for (final o in nextOptions) {
      final want = o.remainingqty.clamp(0, left).toDouble();
      left -= want;
      sharedQty[o.stageid] = TextEditingController(
        text: want > 0 ? fmtQty(want) : '',
      );
    }
    update();
  }

  void sharedQtyChanged() => update();

  /// Start an issue to one destination (full-qty split, or the single next
  /// stage). Seeds the qty box with what that stage is still owed.
  void beginIssueTo(NextStageOption o) {
    issueTarget = o;
    final cap = maxIssuableTo(o);
    final want = o.remainingqty > 0
        ? o.remainingqty.clamp(0, cap).toDouble()
        : cap;
    issueQtyCtrl.text = want > 0 ? fmtQty(want) : '';
    update();
  }

  /// The destination an issue will go to, as the repo wants it.
  ///
  /// A send back leg has no say in this: the ticket's own way decides where
  /// it goes next, and `nextstage` would answer with the FORWARD plan, which
  /// the server would refuse. Send no destination and let it route.
  NextStage? get _issueTo {
    if (job?.isSendBack ?? false) return null;
    final o = issueTarget;
    if (o != null) return NextStage(stageid: o.stageid, stagename: o.stagename);
    return next;
  }

  /// Shared split: one hand-off per destination with a qty, all carrying the
  /// same loader details. The API has no multi-stage call, so this is not
  /// atomic — it stops at the first refusal and reloads, leaving whatever
  /// already went through in place rather than guessing at a rollback.
  Future<bool> issueSharedForward({GatePass? gatePass}) async {
    final j = job;
    if (j == null || saving) return false;
    final total = sharedEntered;
    if (total <= 0) {
      opSnack('Check qty', 'Enter the qty for at least one stage.');
      return false;
    }
    if (total > sharedRemaining) {
      opSnack(
        'Check qty',
        'Total is ${fmtQty(total)} but only ${fmtQty(sharedRemaining)} is '
            'left to share between the next stages.',
      );
      return false;
    }
    saving = true;
    update();
    var sent = 0.0;
    final done = <String>[];
    try {
      for (final o in nextOptions) {
        final qty =
            double.tryParse(sharedQty[o.stageid]?.text.trim() ?? '') ?? 0;
        if (qty <= 0) continue;
        final r = await repo.issue(
          session,
          j,
          returnid: j.returnid,
          qty,
          to: NextStage(stageid: o.stageid, stagename: o.stagename),
          batchno: batchNoCtrl.text.trim(),
          gatePass: gatePass,
        );
        if (!r.ok) {
          opSnack(
            done.isEmpty ? 'Not issued' : 'Stopped part-way',
            done.isEmpty
                ? r.message
                : '${done.join(', ')} went out; ${o.stagename} was refused — '
                      '${r.message}',
          );
          return false;
        }
        sent += qty;
        done.add('${o.stagename} ${fmtQty(qty)}');
        _rememberIssued(j, qty);
        issuedForward += qty;
      }
      opSnack('Issued', '${fmtQty(sent)} sent — ${done.join(' · ')}.');
      return true;
    } finally {
      saving = false;
      await _refreshJob();
    }
  }

  // ── Ready to issue ────────────────────────────────────────────────────────
  //
  // A lot that QC has passed still has to be handed to the next stage, but
  // the job's balance is already 0 by then, so it reads as "Done" and sinks
  // to the bottom of the list. Operators were hunting through Done to find
  // work that was actually outstanding.
  //
  // The catch: qcqty > issuedfwdqty is ALSO true at the last stage, where
  // there is nothing to issue and never will be. Flagging on that alone gave
  // the assembly operator nine permanent false alarms. So each candidate is
  // checked against `nextstage` once — cheap, because only a handful of jobs
  // are ever candidates — and only jobs with somewhere to send are flagged.

  /// job.key → does this stage feed another one? Absent = not asked yet.
  final Map<String, bool> _hasNextStage = {};

  /// QC-passed qty still sitting at this stage.
  double pendingIssueQty(OperatorJob j) =>
      (j.qcqty - j.issuedfwdqty).clamp(0, double.infinity).toDouble();

  /// Worth asking the server about.
  bool _issueCandidate(OperatorJob j) =>
      pendingIssueQty(j) > 0 && !j.isInTransit && !j.isQcJob;

  /// QC-passed and confirmed to have a next stage: real outstanding work.
  bool readyToIssue(OperatorJob j) =>
      _issueCandidate(j) && (_hasNextStage[j.key] ?? false);

  List<OperatorJob> get toIssueJobs =>
      jobs.where(readyToIssue).toList()
        ..sort((a, b) => pendingIssueQty(b).compareTo(pendingIssueQty(a)));

  /// Total pcs waiting to go forward — the number on the chip.
  double get toIssueQty =>
      toIssueJobs.fold<double>(0, (a, j) => a + pendingIssueQty(j));

  /// Ask `nextstage` about each candidate we have not resolved yet. Runs
  /// after the list is drawn and never blocks it; a failure just leaves the
  /// job unflagged rather than guessing.
  Future<void> _loadIssuable() async {
    final todo = jobs
        .where((j) => _issueCandidate(j) && !_hasNextStage.containsKey(j.key))
        .toList();
    if (todo.isEmpty) return;
    final s = session;
    await Future.wait(
      todo.map((j) async {
        try {
          final r = await repo.nextStage(
            s,
            j.stageid,
            j.challanid,
            itemid: j.itemid,
          );
          final n = r.data;
          _hasNextStage[j.key] = n != null && !n.isLast;
        } catch (_) {
          // Leave it unknown; the next load asks again.
        }
      }),
    );
    update();
  }

  // ── Recording one part at a time ───────────────────────────────────────────
  //
  // A stage with `partmode == 1` records its parts separately: METAL makes a
  // frame and four legs, and each can be produced, checked and handed on by
  // itself. The server works out every limit (`canproduceqty`, `canqcqty`,
  // `canissueqty`) and rolls complete sets up into the item's own figures, so
  // nothing here recomputes them — a disabled button and a refusal can never
  // disagree.

  /// The part a sheet is currently working on.
  JobSubItem? partInAction;

  /// Latest copy of that part after a reload, so an open sheet keeps up.
  JobSubItem? get livePart {
    final p = partInAction;
    if (p == null) return null;
    return job?.subitems.where((s) => s.partid == p.partid).firstOrNull ?? p;
  }

  void setPartInAction(JobSubItem? p) {
    partInAction = p;
    update();
  }

  /// Produce (or work on) some of one part. Photos attach to the entry that
  /// is written, the same way item-level production does, so they show up
  /// against that day's row in the log.
  Future<bool> producePart(
    JobSubItem part,
    double qty, {
    String remarks = '',
    List<PickedAttachment> photos = const [],
  }) async {
    final j = job;
    if (j == null || saving) return false;
    if (qty <= 0) {
      opSnack('Check qty', 'Enter how many ${part.partname} to record.');
      return false;
    }
    if (qty > part.canproduceqty) {
      opSnack(
        'Check qty',
        'Only ${fmtQty(part.canproduceqty)} ${part.partname} left to '
            '${part.produceVerb.toLowerCase()}.',
      );
      return false;
    }
    saving = true;
    update();
    try {
      final r = await repo.produce(
        session,
        j,
        returnid: j.returnid,
        qty,
        partid: part.partid,
        entrydate: entryDate,
        remarks: remarks.trim(),
      );
      if (!r.ok) {
        opSnack('Not saved', r.message);
        return false;
      }
      if (photos.isNotEmpty) {
        final failed = await _uploadAttachments(
          photos,
          j,
          recordid: r.id > 0 ? r.id : null,
        );
        if (failed.isNotEmpty) opSnack('Photo upload', failed);
      }
      opSnack('Saved', '${fmtQty(qty)} × ${part.partname}.');
      return true;
    } finally {
      saving = false;
      await _refreshJob();
    }
  }

  /// QC one part. A reject also needs a disposition and a reason, exactly as
  /// the item-level flow does.
  Future<bool> qcPart(
    JobSubItem part, {
    double pass = 0,
    double reject = 0,
    String disposition = 'Rework',
    String reason = '',
    String remarks = '',
    PickedAttachment? photo,
  }) async {
    final j = job;
    if (j == null || saving) return false;
    if (pass <= 0 && reject <= 0) {
      opSnack('Check qty', 'Enter a passed or rejected qty.');
      return false;
    }
    if (pass + reject > part.canqcqty) {
      opSnack(
        'Check qty',
        'Only ${fmtQty(part.canqcqty)} ${part.partname} are waiting for QC.',
      );
      return false;
    }
    if (reject > 0 && reason.isEmpty) {
      opSnack('Check QC', 'Reject reason is required.');
      return false;
    }
    saving = true;
    update();
    try {
      if (pass > 0) {
        final r = await repo.qcPass(
          session,
          j,
          pass,
          partid: part.partid,
          entrydate: entryDate,
          remarks: remarks.trim(),
        );
        if (!r.ok) {
          opSnack('QC not saved', r.message);
          return false;
        }
        // A pass has no `imagepath` to ride on, so its photo goes to the
        // attachment store against the QC entry — the same route the
        // item-level pass uses. Without this the photo was picked and
        // thrown away.
        if (photo != null && reject <= 0) {
          final err = await _uploadAttachments(
            [photo],
            j,
            recordid: r.id > 0 ? r.id : null,
          );
          if (err.isNotEmpty) opSnack('Photo upload', err);
        }
      }
      if (reject > 0) {
        // The defect photo rides on the reject itself (imagepath), the same
        // as the item-level flow, so QC history shows it.
        String imagepath = '';
        if (photo != null) {
          final up = await repo.uploadImage(session, photo.path);
          if (!up.ok || up.data == null) {
            opSnack('Photo upload failed', up.message);
            return false;
          }
          imagepath = up.data!.filepath;
        }
        final r = await repo.qcReject(
          session,
          j,
          reject,
          disposition: disposition,
          reason: reason,
          partid: part.partid,
          remarks: remarks.trim(),
          imagepath: imagepath,
          entrydate: entryDate,
        );
        if (!r.ok) {
          opSnack('Reject not saved', r.message);
          return false;
        }
      }
      opSnack(
        'QC saved',
        reject > 0
            ? '${part.partname} — passed ${fmtQty(pass)}, rejected ${fmtQty(reject)}.'
            : '${part.partname} — passed ${fmtQty(pass)}.',
      );
      return true;
    } finally {
      saving = false;
      await _refreshJob();
    }
  }

  /// Hand one part to the stage the plan sends it to. The destination is not
  /// the operator's to choose, so it is taken straight from the part.
  Future<bool> issuePart(
    JobSubItem part,
    double qty, {
    GatePass? gatePass,
  }) async {
    final j = job;
    if (j == null || saving) return false;
    if (qty <= 0) {
      opSnack('Check qty', 'Enter how many ${part.partname} to hand over.');
      return false;
    }
    if (qty > part.canissueqty) {
      opSnack(
        'Check qty',
        'Only ${fmtQty(part.canissueqty)} ${part.partname} are QC-passed and '
            'still here.',
      );
      return false;
    }
    saving = true;
    update();
    try {
      final r = await repo.issue(
        session,
        j,
        returnid: j.returnid,
        qty,
        to: NextStage(stageid: part.nextstageid, stagename: part.nextstage),
        partid: part.partid,
        gatePass: gatePass,
      );
      if (!r.ok) {
        opSnack('Not issued', r.message);
        return false;
      }
      opSnack(
        'Handed over',
        '${fmtQty(qty)} × ${part.partname} → ${part.nextstage}.',
      );
      return true;
    } finally {
      saving = false;
      await _refreshJob();
    }
  }

  /// Hand a part over on a loader: upload the photos once, then issue.
  Future<bool> issuePartViaLoader(
    JobSubItem part,
    double qty, {
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
    // Nothing leaves the stage without its signed gate pass.
    if (receiptPhotos.isEmpty) {
      opSnack('Issue receipt', 'Attach the signed issue receipt photo.');
      return false;
    }
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
    return issuePart(
      part,
      qty,
      gatePass: GatePass(
        loadername: loadername.trim(),
        issuedAt: issuedAt,
        remarks: remarks.trim(),
        receiptKeys: receiptKeys,
        itemKeys: itemKeys,
      ),
    );
  }

  // ── Send back form ────────────────────────────────────────────────────
  //
  // A fault found at this stage can go back to ANY stage the piece actually
  // passed through, not only the previous one. The server works that list
  // out per good (`fixstages`), so the app never reasons about the route —
  // it shows what it is given.

  SendBackOptions? sbOptions;
  bool sbLoading = false;
  String sbError = '';

  /// Which job [sbOptions] was fetched for. The job screen preloads them so
  /// the Send back card can say what is actually available, and without this
  /// the previous job's answer would label the next one.
  int sbForChallan = 0;
  int sbForStage = 0;

  /// True when [sbOptions] describes the job now open.
  bool get sbOptionsAreForOpenJob =>
      job != null &&
      sbForChallan == job!.challanid &&
      sbForStage == job!.stageid;

  /// Nothing at this stage can go back — everything has either not arrived
  /// yet or has already been handed on.
  bool get sbNothingToSend =>
      sbOptionsAreForOpenJob && !sbLoading && (sbOptions?.isEmpty ?? false);

  /// How many separate things could be sent back from here.
  int get sbAvailableCount =>
      sbOptionsAreForOpenJob ? (sbOptions?.goods.length ?? 0) : 0;

  /// The good being sent back, the "already worked on here" side, where it
  /// is fixed, and which stages redo their work on the way home.
  int sbPartId = 0;
  bool sbWorked = false;
  int sbFixStageId = 0;
  final Set<int> sbRedoIds = {};
  int sbFaultStageId = 0;
  final sbQtyCtrl = TextEditingController();
  final sbReasonCtrl = TextEditingController();
  final sbLoaderCtrl = TextEditingController();
  bool sbViaLoader = false;
  List<PickedAttachment> sbPhotos = [];

  SendBackGood? get sbGood => sbOptions?.goodFor(sbPartId);

  /// The stage the piece goes back to, as the server described it.
  SendBackFixStage? get sbFixStage {
    for (final f in sbOptions?.fixstages ?? const <SendBackFixStage>[]) {
      if (f.stageid == sbFixStageId) return f;
    }
    return null;
  }

  /// Stages between the fix stage and home — each may be ticked to redo its
  /// work on the way back. Empty means it comes straight back.
  List<SendBackFixStage> get sbBetween => sbFixStage?.between ?? const [];

  /// The cap for the qty box: what is here untouched, or what this stage
  /// already worked on and can take back.
  double get sbMaxQty => sbGood?.maxFor(worked: sbWorked) ?? 0;

  /// "ASSEMBLY → PAINT → STONE → ASSEMBLY" — the way this send back takes,
  /// built from what the operator has ticked.
  String get sbWayLabel {
    final j = job;
    final home = j?.stagename ?? '';
    final fix = sbFixStage?.stagename ?? '';
    if (fix.isEmpty) return '';
    final via = sbBetween
        .where((b) => sbRedoIds.contains(b.stageid))
        .map((b) => b.stagename);
    return [home, fix, ...via, home].join(' → ');
  }

  /// The stages on the way that were NOT ticked — their work stays as it is.
  List<String> get sbSkipped => sbBetween
      .where((b) => !sbRedoIds.contains(b.stageid))
      .map((b) => b.stagename)
      .toList();

  /// Open the form for the current job. Asks the server what can go back.
  Future<void> loadSendBackOptions({int partid = 0}) async {
    final j = job;
    if (j == null) return;
    sbLoading = true;
    sbError = '';
    update();
    try {
      final r = await repo.sendBackOptions(
        session,
        challanid: j.challanid,
        stageid: j.stageid,
        partid: partid,
      );
      sbOptions = r.data;
      sbForChallan = j.challanid;
      sbForStage = j.stageid;
      if (!r.ok) sbError = r.message;
      final g = sbOptions?.goods.isNotEmpty == true
          ? sbOptions!.goods.first
          : null;
      // Keep the operator's pick when they are only refreshing one good's
      // routes; otherwise start on the first thing that can go back.
      if (partid > 0) {
        sbPartId = partid;
      } else if (g != null) {
        sbPartId = g.partid;
      }
      // Default to whichever side actually has pieces.
      final good = sbGood;
      if (good != null) sbWorked = !good.canUnworked && good.canWorked;
      _sbResetRoute();
    } finally {
      sbLoading = false;
      update();
    }
  }

  /// Pick a different good. Its route differs, so the server is asked again.
  Future<void> setSendBackGood(int partid) async {
    if (partid == sbPartId) return;
    sbPartId = partid;
    await loadSendBackOptions(partid: partid);
  }

  void setSendBackWorked(bool v) {
    sbWorked = v;
    sbQtyCtrl.text = '';
    update();
  }

  void setSendBackFixStage(int stageid) {
    sbFixStageId = stageid;
    // The stages on the way belong to the chosen fix stage, so any earlier
    // ticks are meaningless now.
    sbRedoIds.clear();
    // Whoever is at fault defaults to the stage doing the fix, which is the
    // common case; the operator can point at a different one.
    if (sbFaultStageId == 0) sbFaultStageId = stageid;
    update();
  }

  void toggleSendBackRedo(int stageid) {
    if (!sbRedoIds.remove(stageid)) sbRedoIds.add(stageid);
    update();
  }

  void setSendBackFault(int stageid) {
    sbFaultStageId = stageid;
    update();
  }

  void setSendBackViaLoader(bool v) {
    sbViaLoader = v;
    update();
  }

  void addSendBackPhotos(List<PickedAttachment> p) {
    sbPhotos = [...sbPhotos, ...p];
    update();
  }

  void removeSendBackPhoto(PickedAttachment p) {
    sbPhotos = [...sbPhotos]..remove(p);
    update();
  }

  void _sbResetRoute() {
    final first = sbOptions?.fixstages.isNotEmpty == true
        ? sbOptions!.fixstages.first
        : null;
    sbFixStageId = first?.stageid ?? 0;
    sbFaultStageId = sbFixStageId;
    sbRedoIds.clear();
    sbQtyCtrl.text = '';
  }

  void resetSendBackForm() {
    sbOptions = null;
    sbError = '';
    sbPartId = 0;
    sbWorked = false;
    sbFixStageId = 0;
    sbFaultStageId = 0;
    sbRedoIds.clear();
    sbQtyCtrl.text = '';
    sbReasonCtrl.clear();
    sbLoaderCtrl.text = lastLoaderName;
    sbViaLoader = false;
    sbPhotos = [];
  }

  /// Send it back. Every limit below is also enforced by the server, which
  /// answers with the live figure — those messages are shown as they come.
  Future<bool> submitSendBack() async {
    final j = job;
    final good = sbGood;
    if (j == null || good == null || saving) return false;
    final qty = double.tryParse(sbQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      opSnack('Check qty', 'Enter how many ${good.name} go back.');
      return false;
    }
    if (qty > sbMaxQty) {
      opSnack(
        'Check qty',
        sbWorked
            ? 'Only ${fmtQty(good.qcqty)} ${good.name} worked here can be taken back.'
            : 'Only ${fmtQty(good.stageqty)} ${good.name} here have not been worked on. '
                  'Send worked pieces back as already worked.',
      );
      return false;
    }
    if (sbFixStageId <= 0) {
      opSnack('Where to', 'Pick the stage that fixes it.');
      return false;
    }
    if (sbReasonCtrl.text.trim().isEmpty) {
      opSnack('Reason', 'Say what is wrong — the fix stage only sees this.');
      return false;
    }
    if (sbViaLoader && sbLoaderCtrl.text.trim().isEmpty) {
      opSnack('Loader', 'Enter the loader name.');
      return false;
    }
    saving = true;
    update();
    try {
      final keys = await _uploadKeys(sbPhotos);
      if (sbViaLoader) _rememberLoader(sbLoaderCtrl.text);
      final r = await repo.sendBack(
        session,
        challanid: j.challanid,
        stageid: j.stageid,
        partid: sbPartId,
        qty: qty,
        worked: sbWorked ? 1 : 0,
        fixstageid: sbFixStageId,
        redostageids: sbRedoIds.toList(),
        faultstageid: sbFaultStageId,
        reason: sbReasonCtrl.text.trim(),
        imageKeys: keys,
        gatePass: sbViaLoader
            ? GatePass(
                loadername: sbLoaderCtrl.text.trim(),
                issuedAt: DateTime.now(),
                remarks: sbReasonCtrl.text.trim(),
                receiptKeys: const [],
                itemKeys: keys,
              )
            : null,
      );
      if (!r.ok) {
        opSnack('Not sent back', r.message);
        return false;
      }
      opSnack('Sent back', r.message);
      resetSendBackForm();
      await loadJobs();
      await openJob(j);
      return true;
    } catch (e) {
      opSnack('Photo upload failed', '$e');
      return false;
    } finally {
      saving = false;
      update();
    }
  }

  // ── QC: fix here, or send it back ─────────────────────────────────────
  //
  // A QC reject used to mean one thing — rework at this stage. It can now
  // also go back to any stage the piece passed through. Both are the same
  // endpoint; `action: sendback` is the fork.

  /// 'here' = rework at this stage (as before) · 'back' = send it to an
  /// earlier stage, then it returns here.
  String qcRejectAction = 'here';

  /// The stage whose work was faulty, for either route. 0 = not stated.
  int qcFaultStageId = 0;

  bool get qcSendsBack => qcRejectAction == 'back';

  void setQcRejectAction(String a) {
    qcRejectAction = a;
    update();
  }

  void setQcFaultStage(int stageid) {
    qcFaultStageId = stageid == qcFaultStageId ? 0 : stageid;
    update();
  }

  /// True when the send back form is being filled for a QC rejection rather
  /// than by the stage operator. The form is the same; the call is not.
  bool sbFromQc = false;

  /// How many pieces QC rejected — the qty that travels.
  double sbRejectQty = 0;

  /// Open the send back form from the QC screen, carrying the rejection
  /// across. Nothing is recorded until the form is submitted: the reject and
  /// the send back are one call, so a half-finished form must leave no trace.
  Future<void> openQcSendBack() async {
    final j = qcJob;
    if (j == null) return;
    sbFromQc = true;
    sbRejectQty = qcReject;
    // The form works against the job being checked.
    await openJob(j);
    resetSendBackForm();
    sbFromQc = true;
    // The item-level QC screen checks the item, never a part.
    sbQcPartId = 0;
    sbRejectQty = qcReject;
    sbReasonCtrl.text = qcReason;
    // loadSendBackOptions resets the route and clears the qty box, so the
    // rejected qty is seeded after it, not before.
    await loadSendBackOptions();
    sbQtyCtrl.text = fmtQty(qcReject);
    update();
  }

  /// What QC checked, when the check was on a part rather than the item.
  /// 0 = the item. It is NOT the same as [sbPartId]: a faulty Carcass can be
  /// taken out of a rejected Body, so what was checked and what travels
  /// differ.
  int sbQcPartId = 0;

  /// Open the send back form from the PART QC sheet. Same form, same call —
  /// only the part that was checked differs.
  Future<void> openPartQcSendBack(
    JobSubItem part, {
    required double rejectQty,
    required String reason,
    String remarks = '',
  }) async {
    final j = job;
    if (j == null) return;
    resetSendBackForm();
    sbFromQc = true;
    sbQcPartId = part.partid;
    sbRejectQty = rejectQty;
    sbReasonCtrl.text = reason;
    qcRemarksCtrl.text = remarks;
    // The part that was checked is the obvious default for what goes back,
    // but the form lets the checker pick a different one — the fault may be
    // in a part fitted inside it.
    await loadSendBackOptions(partid: part.partid);
    sbQtyCtrl.text = fmtQty(rejectQty);
    update();
  }

  /// The QC route: reject and send back in one call. The rejection is
  /// recorded now; the rework here opens only as the pieces come home.
  Future<bool> submitQcSendBack() async {
    final j = job ?? qcJob;
    if (j == null || saving) return false;
    final qty = double.tryParse(sbQtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      opSnack('Check qty', 'Enter how many pieces go back.');
      return false;
    }
    if (sbFixStageId <= 0) {
      opSnack('Where to', 'Pick the stage that fixes it.');
      return false;
    }
    if (sbReasonCtrl.text.trim().isEmpty) {
      opSnack('Reason', 'Say what is wrong — the fix stage only sees this.');
      return false;
    }
    if (sbViaLoader && sbLoaderCtrl.text.trim().isEmpty) {
      opSnack('Loader', 'Enter the loader name.');
      return false;
    }
    saving = true;
    update();
    try {
      final keys = await _uploadKeys(sbPhotos);
      if (sbViaLoader) _rememberLoader(sbLoaderCtrl.text);
      final r = await repo.qcRejectSendBack(
        session,
        j,
        // What QC checked, and what actually travels — a faulty part can be
        // taken out of a rejected item, so the two differ.
        partid: sbQcPartId,
        sendbackpartid: sbPartId,
        rejectqty: sbRejectQty > 0 ? sbRejectQty : qty,
        sendbackqty: qty,
        fixstageid: sbFixStageId,
        redostageids: sbRedoIds.toList(),
        faultstageid: sbFaultStageId,
        reason: sbReasonCtrl.text.trim(),
        remarks: qcRemarksCtrl.text.trim(),
        imageKeys: keys,
        gatePass: sbViaLoader
            ? GatePass(
                loadername: sbLoaderCtrl.text.trim(),
                issuedAt: DateTime.now(),
                remarks: sbReasonCtrl.text.trim(),
                receiptKeys: const [],
                itemKeys: keys,
              )
            : null,
      );
      if (!r.ok) {
        opSnack('Not sent back', r.message);
        return false;
      }
      qcHistoryDirty = true;
      opSnack('Rejected and sent back', r.message);
      resetSendBackForm();
      sbFromQc = false;
      sbQcPartId = 0;
      qcRejectAction = 'here';
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

  // ── Hand several parts over in one go ─────────────────────────────────
  //
  // A stage often finishes three or four parts that all travel to the same
  // next stage on the same loader. Issuing them one at a time means typing
  // the loader, the date and the receipt photo three or four times for what
  // is physically one consignment.

  /// Parts ready to go, grouped by where they go. The plan fixes each part's
  /// destination, so parts bound for different stages can never share a
  /// hand-over however convenient it would look.
  Map<int, List<JobSubItem>> get partsReadyByDestination {
    final j = job;
    final out = <int, List<JobSubItem>>{};
    if (j == null) return out;
    for (final p in j.subitems) {
      if (p.canissueqty <= 0) continue;
      out.putIfAbsent(p.nextstageid, () => []).add(p);
    }
    return out;
  }

  /// The one destination that has 2+ parts waiting, if there is exactly one
  /// such group — the only case where "send them together" is unambiguous.
  /// Null when nothing qualifies, and the per-part buttons stand alone.
  MapEntry<int, List<JobSubItem>>? get batchIssueGroup {
    final groups = partsReadyByDestination.entries
        .where((e) => e.value.length > 1)
        .toList();
    return groups.length == 1 ? groups.first : null;
  }

  /// Hand several parts to the same next stage under ONE gate pass.
  ///
  /// The API has no multi-part call, so this is one `issue` per part with
  /// the same loader, time and photos — the same approach as a shared split
  /// (`issueSharedForward`). That makes it **not atomic**: it stops at the
  /// first refusal and reloads, leaving whatever already went through in
  /// place rather than guessing at a rollback. The server's own message for
  /// the part that failed is shown, so the operator can see which one.
  Future<bool> issuePartsTogether(
    Map<JobSubItem, double> qtyByPart, {
    required String loadername,
    required DateTime issuedAt,
    String remarks = '',
    List<PickedAttachment> receiptPhotos = const [],
    List<PickedAttachment> itemPhotos = const [],
  }) async {
    final j = job;
    if (j == null || saving) return false;
    final wanted = qtyByPart.entries.where((e) => e.value > 0).toList();
    if (wanted.isEmpty) {
      opSnack('Check qty', 'Enter a qty for at least one part.');
      return false;
    }
    for (final e in wanted) {
      if (e.value > e.key.canissueqty) {
        opSnack(
          'Check qty',
          'Only ${fmtQty(e.key.canissueqty)} ${e.key.partname} are QC-passed '
              'and not sent yet.',
        );
        return false;
      }
    }
    if (loadername.trim().isEmpty) {
      opSnack('Loader name', 'Enter the loader name.');
      return false;
    }
    if (receiptPhotos.isEmpty) {
      opSnack('Issue receipt', 'Attach the signed issue receipt photo.');
      return false;
    }
    _rememberLoader(loadername);
    saving = true;
    update();
    List<String> receiptKeys, itemKeys;
    try {
      // Uploaded ONCE and attached to every part's entry — it is one
      // physical consignment with one signed receipt.
      receiptKeys = await _uploadKeys(receiptPhotos);
      itemKeys = await _uploadKeys(itemPhotos);
    } catch (e) {
      saving = false;
      update();
      opSnack('Photo upload failed', '$e');
      return false;
    }
    final pass = GatePass(
      loadername: loadername.trim(),
      issuedAt: issuedAt,
      remarks: remarks.trim(),
      receiptKeys: receiptKeys,
      itemKeys: itemKeys,
    );
    final done = <String>[];
    try {
      for (final e in wanted) {
        final r = await repo.issue(
          session,
          j,
          e.value,
          partid: e.key.partid,
          returnid: j.returnid,
          to: NextStage(stageid: e.key.nextstageid, stagename: e.key.nextstage),
          gatePass: pass,
        );
        if (!r.ok) {
          opSnack(
            done.isEmpty ? 'Not handed over' : 'Stopped part-way',
            done.isEmpty
                ? r.message
                : '${done.join(', ')} went. ${e.key.partname}: ${r.message}',
          );
          return false;
        }
        done.add('${fmtQty(e.value)} ${e.key.partname}');
      }
      opSnack(
        'Handed over',
        '${done.join(' · ')} → ${_titleCase(wanted.first.key.nextstage)}.',
      );
      return true;
    } finally {
      saving = false;
      update();
      await loadJobs();
      final fresh = jobs.where((x) => x.key == j.key).firstOrNull;
      if (fresh != null) await openJob(fresh);
    }
  }

  String _titleCase(String s) => s.isEmpty
      ? s
      : s
            .split(' ')
            .map(
              (w) => w.isEmpty
                  ? w
                  : w[0].toUpperCase() + w.substring(1).toLowerCase(),
            )
            .join(' ');

  // ── Packing ───────────────────────────────────────────────────────────
  //
  // At PACKING there is no Produce: the operator says how many pieces went
  // into boxes and what is in each one. The save is what records them as
  // made at PACKING, so QC and dispatch work exactly as before.

  PackJob? packJob;
  bool packLoading = false;
  String packError = '';

  /// Boxes typed but not saved yet.
  List<PackBoxDraft> packDrafts = [];

  final packQtyCtrl = TextEditingController();

  /// One id per Save tap, reused on a retry so a timeout cannot pack the
  /// same pieces twice. Cleared only once the server has accepted.
  String _packToken = '';

  PackItem get packItem => packJob?.item ?? const PackItem();

  /// The most pieces this save may pack.
  double get packMax => packItem.topack;

  double get packQty => double.tryParse(packQtyCtrl.text.trim()) ?? 0;

  /// Boxes that are complete enough to send.
  List<PackBoxDraft> get packReadyDrafts =>
      packDrafts.where((b) => b.isValid).toList();

  Future<void> loadPackJob(OperatorJob j) async {
    packLoading = true;
    packError = '';
    packDrafts = [];
    _packToken = '';
    update();
    try {
      final r = await repo.packJob(
        session,
        challanid: j.challanid,
        itemid: j.itemid,
      );
      packJob = r.data;
      if (!r.ok) packError = r.message;
      // Default to everything that can still be packed — the common case is
      // one save for the whole lot.
      packQtyCtrl.text = packMax > 0 ? fmtQty(packMax) : '';
    } finally {
      packLoading = false;
      update();
    }
  }

  void addPackBox(PackBoxDraft b) {
    packDrafts = [...packDrafts, b];
    update();
  }

  void replacePackBox(int index, PackBoxDraft b) {
    if (index < 0 || index >= packDrafts.length) return;
    final l = [...packDrafts];
    l[index] = b;
    packDrafts = l;
    update();
  }

  void removePackBox(int index) {
    if (index < 0 || index >= packDrafts.length) return;
    packDrafts = [...packDrafts]..removeAt(index);
    update();
  }

  void setPackQty(double q) {
    packQtyCtrl.text = fmtQty(q.clamp(0, packMax));
    update();
  }

  /// Save the pieces and their boxes. Every limit here is also enforced by
  /// the server, whose message is shown as it comes.
  Future<bool> savePacking() async {
    final j = job;
    if (j == null || saving) return false;
    final qty = packQty;
    if (qty <= 0) {
      opSnack('Pieces packed', 'Enter how many pieces are packed.');
      return false;
    }
    if (qty > packMax) {
      opSnack(
        'Pieces packed',
        'Only ${fmtQty(packMax)} left to pack at ${j.stagename}.',
      );
      return false;
    }
    final boxes = packReadyDrafts;
    if (boxes.isEmpty) {
      opSnack('Boxes', 'Add at least one box — what is inside and how many.');
      return false;
    }
    saving = true;
    update();
    try {
      // The same tap keeps its token, so a retry after a timeout is matched
      // to the first attempt instead of packing twice.
      if (_packToken.isEmpty) _packToken = _newToken();
      final wire = <Map<String, dynamic>>[];
      for (final b in boxes) {
        // Each box's photos are uploaded first; the server wants the
        // returned filepaths, not the files.
        final keys = b.photos.isEmpty
            ? <String>[]
            : await _uploadKeys(b.photos);
        wire.add(b.toJson(keys));
      }
      final r = await repo.packSave(
        session,
        challanid: j.challanid,
        itemid: j.itemid,
        qty: qty,
        boxes: wire,
        clienttoken: _packToken,
      );
      if (!r.ok) {
        opSnack('Not saved', r.message);
        return false;
      }
      _packToken = '';
      packDrafts = [];
      opSnack('Packed', r.message);
      await loadPackJob(j);
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

  /// Undo a whole save. Its boxes go; the pieces stay made at PACKING and
  /// can be packed again.
  Future<bool> removePack(int packid) async {
    final j = job;
    if (j == null || saving) return false;
    saving = true;
    update();
    try {
      final r = await repo.packRemove(session, packid: packid);
      if (!r.ok) {
        opSnack('Not removed', r.message);
        return false;
      }
      opSnack('Removed', r.message);
      await loadPackJob(j);
      await loadJobs();
      return true;
    } finally {
      saving = false;
      update();
    }
  }

  /// A unique-enough token for one Save tap. No uuid package in this app,
  /// and the server only needs it to recognise a retry of the same tap.
  String _newToken() {
    final r = Random();
    final hex = List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '${session.userid}-${DateTime.now().microsecondsSinceEpoch}-$hex';
  }

  // ── How much is still to pack ─────────────────────────────────────────
  //
  // A PACKING row's own figures say nothing about packing: every live one
  // reads "Done, balance 0" because the pieces were produced here, while
  // `topack` is still 1 or 2 — they have been made but not boxed. Only
  // `pack/job` knows, and it is per item, so the answer is fetched in the
  // background after the list is drawn (same as `_loadIssuable`).

  /// job.key → pieces still to pack. Missing = not asked yet.
  final Map<String, double> _packLeft = {};

  /// Pieces still to pack, or null while unknown.
  double? packLeftFor(OperatorJob j) => _packLeft[j.key];

  /// Packing jobs worth showing: everything still to pack, plus the ones we
  /// have not resolved yet — never hide work because an answer is pending.
  List<OperatorJob> get packJobs =>
      jobs.where((j) => j.isPackStage && (packLeftFor(j) ?? 1) > 0).toList();

  /// Total pieces waiting to be boxed — the number on the Home tile.
  double get packQtyLeft =>
      packJobs.fold<double>(0, (a, j) => a + (packLeftFor(j) ?? 0));

  Future<void> _loadPackLeft() async {
    final todo = jobs
        .where((j) => j.isPackStage && !_packLeft.containsKey(j.key))
        .toList();
    if (todo.isEmpty) return;
    final s = session;
    await Future.wait(
      todo.map((j) async {
        try {
          final r = await repo.packJob(
            s,
            challanid: j.challanid,
            itemid: j.itemid,
          );
          _packLeft[j.key] = r.data?.item.topack ?? 0;
        } catch (_) {
          // Leave it unknown; the next load asks again.
        }
      }),
    );
    update();
  }
}

/// A box the operator is filling in but has not saved yet.
///
/// It lives here rather than in the models file because it holds picked
/// FILES — the model layer describes what the server sends, not what the
/// camera produced.
class PackBoxDraft {
  String contents;
  double count;
  List<PickedAttachment> photos;

  PackBoxDraft({this.contents = '', this.count = 0, List<PickedAttachment>? p})
    : photos = p ?? [];

  bool get isValid => contents.trim().isNotEmpty && count > 0;

  /// The wire shape `pack/save` wants. [keys] are the uploaded filepaths,
  /// resolved by the controller before this is called.
  Map<String, dynamic> toJson(List<String> keys) => {
    'contents': contents.trim(),
    'count': count,
    if (keys.isNotEmpty) 'photos': keys,
  };
}
