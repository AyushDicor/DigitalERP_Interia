// Models for the Production — Operator module (shop-floor flow).
//
// Backed by the INTERIA operator endpoints on the mobile API (all POST,
// JSON body, X-Api-Key; failures also come back HTTP 200 with success=false):
//   interia/myjobs      -> jobs issued to the logged-in operator
//   interia/jobstages   -> per-stage trail of one challan
//   interia/nextstage   -> stage after a given stage
//   interia/produce     -> record produced qty at my stage
//   interia/qc          -> QC pass qty (reject goes through qcreject)
//   interia/qcreject    -> reject qty + Rework/Scrap disposition
//   interia/qchistory   -> QC checks this user saved, grouped by day
//   interia/jobdesign   -> approved drawings + client materials + BOM designs
//   interia/issue       -> issue QC-passed qty to the next stage
//   interia/downtime    -> log downtime      (same fields as bottleneck)
//   interia/bottleneck  -> log bottleneck
//   interia/stoppages   -> downtime + bottleneck history
//   interia/progress    -> upsert % progress of the current piece
//   interia/progressget -> read it back
//   interia/uploadimage -> multipart image -> S3 key for imagepath

num _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

int _int(dynamic v) => _num(v).toInt();
double _dbl(dynamic v) => _num(v).toDouble();
String _str(dynamic v) => (v ?? '').toString();

/// Absent / null → false; otherwise true/1/"Y"/"yes".
bool _canQc(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'y' || s == 'yes';
}

/// Clean number for labels: trims a trailing ".0".
String fmtQty(num v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// One production job (challan-item at my stage) from `myjobs`.
class OperatorJob {
  final int challanid;
  final String challanno;
  final String challandate;
  final int stageid;
  final String stagename;
  final int itemid;
  final String itemname;
  final String boqno;
  final String partyname;
  final int orderrefid;
  final double issuedqty;

  /// Qty already issued from this stage to the next (`issuedfwdqty`, live
  /// 2026-09-23). Authoritative "already forwarded" — the Issue card locks
  /// on it instead of guessing from the trail. It goes back DOWN when the
  /// next stage rejects a consignment, so it must never be blended with the
  /// app's own guesses (see [hasIssuedFwd]).
  final double issuedfwdqty;

  /// Did the row actually carry `issuedfwdqty`? Without this a genuine 0
  /// ("nothing forwarded", or "the next stage sent it back") is
  /// indistinguishable from an older backend that omits the field.
  final bool hasIssuedFwd;
  double producedqty;
  double qcqty;
  double rejectqty;
  double balanceqty;
  final String issuedate;
  final int markerid;
  String status;

  /// Who produced the lot — only on `qcpending` rows (QC module); blank on
  /// `myjobs`, where the operator is the logged-in user.
  final int operatorid;
  final String operatorname;

  /// May the logged-in user QC this lot? The backend gives QC work only to
  /// QC people and marks those rows `canqc: true` on myjobs. Absent / false
  /// = no QC actions (operators must never QC their own pieces), so nothing
  /// shows until the backend explicitly grants it.
  final bool canqc;

  /// Why QC rejected (Rework rows). Read from `rejectreason` / `reason` /
  /// `remarks` when the backend sends it; blank otherwise.
  final String rejectreason;

  /// Who rejected (Rework rows) — `rejectedby` / `qcby` when sent.
  final String rejectedby;

  /// The rest of the QC rejection, live 2026-09-26: the checker's own note,
  /// Rework / Scrap, when it happened, and photos of the defect. The photo
  /// urls are presigned and expire, so they are never cached.
  final String rejectremarks;
  final String disposition;
  final String rejectedon;
  final List<String> rejectimages;

  /// Loader handover fields when the row is a consignment in transit
  /// (`status: "In Transit"`): the receiver must Accept before producing.
  final int consignmentid;
  final String loadername;
  final String loaderref;
  final String issuetime;
  final String issuedby;
  final int fromstageid;
  final String fromstagename;
  final List<String> receiptimages;
  final List<String> itemimages;

  /// Parallel routing (live 2026-09-28). `partsinfo` is only set on a
  /// joining stage and lists what each earlier stage has handed over;
  /// `waitsfor` / `nextstages` are display strings for the route line.
  /// All three are empty on a plain linear challan.
  final String partsinfo;
  final String waitsfor;
  final String nextstages;

  /// Parts made at or arriving into this stage, and the server's one-line
  /// summary of them. Empty on a challan planned without parts.
  final List<JobSubItem> subitems;
  final String subitemstext;

  /// 1 = this stage records its parts one by one; production and hand-off
  /// happen per part, not for the item. The stage that assembles the item is
  /// always 0 — it only receives parts and produces the item itself.
  final int partmode;

  /// Only set on an **In Transit** row: the one part that consignment holds.
  final int partid;
  final String partname;

  /// Design pack counts (live 2026-09-26). The drawings are APPROVED ones
  /// only — the backend drops anything under review — so these are safe to
  /// show as-is. The pack itself comes from `jobdesign`.
  final int drawingcount;
  final int materialcount;
  final int bomdesigncount;
  final bool hasdesign;

  // ── Send back (live 2026-09-30) ──
  //
  // Pieces can go back to ANY earlier stage they passed through, be fixed
  // there and come home. `returnid` > 0 turns this row from a job into one
  // leg of a send back; on a normal job row it is 0 and [sentbackqty] counts
  // what this stage has sent back and not got returned (balanceqty already
  // leaves those out).
  final int returnid;
  final double sentbackqty;

  /// 1 = this is a PACKING job: the operator packs boxes instead of
  /// producing. Set only on the packing operator's own rows — never on an
  /// In Transit row and never for a QC login.
  final int packstage;

  /// Item · Part · Unit — what is travelling.
  final String returnkind;

  /// `Stage` = the pieces were never worked on here, `QC` = they were worked
  /// on and rejected here first.
  final String returnsource;

  /// Operator · QC — who sent it back.
  final String returnsentby;

  /// The whole send back, how much is home, how much is still out.
  final double returnqty;
  final double returnbackqty;
  final double returnopenqty;

  /// Server-written: "CARPENTRY 1, on a loader to PAINT 1, back 1".
  final String returnwherenow;

  /// Where the fault was found (and so where it returns to), where it is
  /// being fixed, and the whole way as "PAINT > STONE > ASSEMBLY".
  final String returnfromstage;
  final String returnfixstage;
  final String returnway;

  /// Where "Send on" sends it from this row.
  final String returnnextstage;

  /// Whose work was faulty — not necessarily where it is fixed.
  final String faultstage;

  /// Reworked on this leg and waiting for QC, and QC-passed but not sent on
  /// yet. The server owns both; the app never recomputes them (see the three
  /// `can*` caps on [JobSubItem]).
  final double canqcqty;
  final double cansendqty;

  OperatorJob({
    required this.challanid,
    required this.challanno,
    required this.challandate,
    required this.stageid,
    required this.stagename,
    required this.itemid,
    required this.itemname,
    required this.boqno,
    required this.partyname,
    required this.orderrefid,
    required this.issuedqty,
    this.issuedfwdqty = 0,
    this.hasIssuedFwd = false,
    required this.producedqty,
    required this.qcqty,
    required this.rejectqty,
    required this.balanceqty,
    required this.issuedate,
    required this.markerid,
    required this.status,
    this.operatorid = 0,
    this.operatorname = '',
    this.canqc = false,
    this.rejectreason = '',
    this.rejectedby = '',
    this.rejectremarks = '',
    this.disposition = '',
    this.rejectedon = '',
    this.rejectimages = const [],
    this.consignmentid = 0,
    this.loadername = '',
    this.loaderref = '',
    this.issuetime = '',
    this.issuedby = '',
    this.fromstageid = 0,
    this.fromstagename = '',
    this.receiptimages = const [],
    this.itemimages = const [],
    this.subitems = const [],
    this.subitemstext = '',
    this.partmode = 0,
    this.partid = 0,
    this.partname = '',
    this.partsinfo = '',
    this.waitsfor = '',
    this.nextstages = '',
    this.drawingcount = 0,
    this.materialcount = 0,
    this.bomdesigncount = 0,
    this.hasdesign = false,
    this.returnid = 0,
    this.sentbackqty = 0,
    this.packstage = 0,
    this.returnkind = '',
    this.returnsource = '',
    this.returnsentby = '',
    this.returnqty = 0,
    this.returnbackqty = 0,
    this.returnopenqty = 0,
    this.returnwherenow = '',
    this.returnfromstage = '',
    this.returnfixstage = '',
    this.returnway = '',
    this.returnnextstage = '',
    this.faultstage = '',
    this.canqcqty = 0,
    this.cansendqty = 0,
  });

  factory OperatorJob.fromJson(Map<String, dynamic> j) => OperatorJob(
    challanid: _int(j['challanid']),
    challanno: _str(j['challanno']),
    challandate: _str(j['challandate']),
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    boqno: _str(j['boqno']),
    partyname: _str(j['partyname']),
    orderrefid: _int(j['orderrefid']),
    issuedqty: _dbl(j['issuedqty']),
    issuedfwdqty: _dbl(j['issuedfwdqty'] ?? j['issuedforwardqty']),
    hasIssuedFwd:
        j.containsKey('issuedfwdqty') || j.containsKey('issuedforwardqty'),
    producedqty: _dbl(j['producedqty']),
    qcqty: _dbl(j['qcqty']),
    rejectqty: _dbl(j['rejectqty']),
    balanceqty: _dbl(j['balanceqty']),
    issuedate: _str(j['issuedate']),
    markerid: _int(j['markerid']),
    status: _str(j['status']),
    operatorid: _int(j['operatorid'] ?? j['userid']),
    operatorname: _str(j['operatorname'] ?? j['username']),
    // ONLY the server's own flag. There used to be a fallback here that read
    // status "Awaiting QC" as a QC grant, from a September build that did not
    // always send `canqc`. Since 1 Oct 2026 the server refuses QC from anyone
    // outside the QC department ("Only the QC department can record QC."), and
    // "Awaiting QC" appears on the MAKER's row too — so that fallback handed
    // the maker a button whose call now fails, and (because `_mayWork` is
    // `!canqc`) hid their own Produce and Hand over at the same time.
    // Never infer the grant from a status or from `canqcqty`, which is only
    // how many pieces are waiting.
    canqc: _canQc(j['canqc'] ?? j['qcallowed'] ?? j['isqc']),
    rejectreason: _str(j['rejectreason'] ?? j['reason'] ?? ''),
    rejectedby: _str(j['rejectedby'] ?? j['qcby'] ?? j['qcname'] ?? ''),
    rejectremarks: _str(j['rejectremarks'] ?? j['rejectnote'] ?? ''),
    disposition: _str(j['disposition']),
    rejectedon: _str(j['rejectedon']),
    rejectimages: Consignment._urls(j['rejectimages'] ?? j['rejectphotos']),
    consignmentid: _int(j['consignmentid'] ?? j['issueid']),
    loadername: _str(j['loadername']),
    loaderref: _str(j['loaderref'] ?? j['loaderno']),
    issuetime: _str(j['issuetime']),
    issuedby: _str(j['issuedby'] ?? j['issuedbyname']),
    fromstageid: _int(j['fromstageid']),
    fromstagename: _str(j['fromstagename']),
    receiptimages: Consignment._urls(j['receiptimages'] ?? j['receiptphotos']),
    itemimages: Consignment._urls(j['itemimages'] ?? j['itemphotos']),
    subitems: JobSubItem.listFrom(j['subitems']),
    subitemstext: _str(j['subitemstext']),
    partmode: _int(j['partmode']),
    partid: _int(j['partid']),
    partname: _str(j['partname']),
    partsinfo: _str(j['partsinfo']),
    waitsfor: _str(j['waitsfor']),
    nextstages: _str(j['nextstages']),
    drawingcount: _int(j['drawingcount']),
    materialcount: _int(j['materialcount']),
    bomdesigncount: _int(j['bomdesigncount']),
    // Trust the flag, but fall back to the counts for an older API build.
    hasdesign:
        _canQc(j['hasdesign']) ||
        _int(j['drawingcount']) +
                _int(j['materialcount']) +
                _int(j['bomdesigncount']) >
            0,
    returnid: _int(j['returnid']),
    sentbackqty: _dbl(j['sentbackqty']),
    packstage: _int(j['packstage']),
    returnkind: _str(j['returnkind']),
    returnsource: _str(j['returnsource']),
    returnsentby: _str(j['returnsentby']),
    returnqty: _dbl(j['returnqty']),
    returnbackqty: _dbl(j['returnbackqty']),
    returnopenqty: _dbl(j['returnopenqty']),
    returnwherenow: _str(j['returnwherenow']),
    returnfromstage: _str(j['returnfromstage']),
    returnfixstage: _str(j['returnfixstage']),
    returnway: _str(j['returnway']),
    returnnextstage: _str(j['returnnextstage']),
    faultstage: _str(j['faultstage']),
    canqcqty: _dbl(j['canqcqty']),
    cansendqty: _dbl(j['cansendqty']),
  );

  /// Same job on the same (challan, item, stage) — the key `progress` upserts on.
  /// A send back is its own row, and one send back can sit at two stages at
  /// once, so its id has to be part of the key or the rows collapse.
  String get key => returnid > 0
      ? 'r$returnid/$stageid/$partid'
      : '$challanid/$itemid/$stageid';

  // ── Send back helpers ──

  /// Pack boxes here instead of recording production.
  bool get isPackStage => packstage == 1;

  /// This row is one leg of a send back, not a job.
  bool get isSendBack => returnid > 0;

  /// This stage has pieces away being fixed somewhere else.
  bool get hasSentBack => sentbackqty > 0;

  /// The four actions on a send back row come from the NUMBERS, never from
  /// [status]: one leg can have pieces to rework AND pieces ready to send at
  /// the same time, which no single status word can say.
  bool get canReworkHere => isSendBack && balanceqty > 0;
  bool get canQcHere => isSendBack && canqcqty > 0 && canqc;
  bool get canSendOn => isSendBack && cansendqty > 0;

  /// Reworked on this leg and waiting for QC. Shown read-only to the
  /// operator ("Awaiting QC"); only a `canqc` login gets the button.
  bool get awaitingQcHere => isSendBack && canqcqty > 0 && !canqc;

  /// "1 drawing · 3 materials" for the card chip; zero parts are left out.
  String get designChipLabel => [
    if (drawingcount > 0)
      '$drawingcount ${drawingcount == 1 ? 'drawing' : 'drawings'}',
    if (kShowClientMaterials && materialcount > 0)
      '$materialcount ${materialcount == 1 ? 'material' : 'materials'}',
    if (bomdesigncount > 0)
      '$bomdesigncount BOM ${bomdesigncount == 1 ? 'design' : 'designs'}',
  ].join(' · ');

  /// Produced but not yet QC'd (pass or reject) — what the QC screen works on.
  double get qcPending =>
      (producedqty - qcqty - rejectqty).clamp(0, double.infinity).toDouble();

  bool get isRework => status.toLowerCase().contains('rework');

  /// A QC assignment (lot to check) rather than a production job. Such rows
  /// never count as pending / running / done and open the QC screen directly.
  bool get isQcJob => canqc;

  /// Rejected-by-QC pieces sent back to me: `status: "Rework"`, with
  /// `balanceqty` = pieces to re-produce (backend contract 2026-09-22).
  bool get isReworkJob => isRework && !isQcJob && balanceqty > 0;

  /// Sent via loader and not yet accepted here (`status: "In Transit"`).
  bool get isInTransit => status.toLowerCase().contains('transit');

  /// A joining stage that has made everything it can and is short of parts
  /// (`status: "Waiting for parts"`). Production is locked until the missing
  /// stages hand over.
  bool get isWaitingForParts => status.toLowerCase().contains('waiting');

  /// What each earlier stage has handed over, for the chips on the card.
  List<JobPart> get parts => JobPart.parse(partsinfo);

  /// This stage records each part separately instead of the whole item.
  bool get isPartMode => partmode == 1 && subitems.isNotEmpty;

  /// Parts made at this stage, and parts arriving from an earlier one.
  List<JobSubItem> get madeHere => subitems.where((s) => s.isMadeHere).toList();
  List<JobSubItem> get comesIn => subitems.where((s) => !s.isMadeHere).toList();

  /// Every part stops here — this stage assembles the finished item.
  bool get buildsFinishedItem =>
      subitems.isNotEmpty && subitems.every((s) => s.nextstage.isEmpty);

  /// Production cannot be recorded right now.
  bool get productionLocked => isInTransit || isWaitingForParts;

  /// The myjobs row viewed as a consignment (when the backend flags it in
  /// transit on the row itself instead of a separate `incoming` list).
  Consignment toConsignment() => Consignment(
    consignmentid: consignmentid,
    issueid: consignmentid,
    partid: partid,
    partname: partname,
    returnid: returnid,
    challanid: challanid,
    challanno: challanno,
    itemid: itemid,
    itemname: itemname,
    boqno: boqno,
    qty: issuedqty,
    fromstageid: fromstageid,
    fromstagename: fromstagename,
    tostageid: stageid,
    tostagename: stagename,
    loadername: loadername,
    loaderref: loaderref,
    issuedate: issuedate,
    issuetime: issuetime,
    issuedby: issuedby,
    status: status,
    remarks: '',
    receiptimages: receiptimages,
    itemimages: itemimages,
  );
  double get reworkQty => isReworkJob ? balanceqty : 0;
  bool get isDone => balanceqty <= 0 && producedqty > 0;
  bool get isRunning => producedqty > 0 && balanceqty > 0;
  bool get isPending => producedqty <= 0;

  /// Bucket used by the dashboard / My Work counters.
  OperatorJobState get state {
    if (isDone) return OperatorJobState.done;
    if (isRunning) return OperatorJobState.running;
    return OperatorJobState.pending;
  }
}

enum OperatorJobState { pending, running, done }

/// One row of the stage trail (`jobstages`) — the route of this challan-item
/// in order. Live shape since 2026-09-23:
///   { stageid, stagename, seq, itemqty, produced, received, qcd, reject,
///     status "green"|"red" }
/// The older names (issuedqty / producedqty / qcqty / rejectqty) are still
/// accepted so the app works against either build.
class JobStageRow {
  final int stageid;
  final String stagename;

  /// Route of this stage within the challan (live 2026-09-28): the stages it
  /// waits for and the ones it feeds, as display names, plus the ids it
  /// depends on. Empty on a linear challan.
  final String waitsfor;
  final String nextstages;
  final String dependson;

  /// Position of this stage in the challan's own route (1-based).
  final int seq;

  /// The job qty planned for this stage (`itemqty`) — the SAME number on
  /// every stage of the route, so it is only a denominator. It does NOT
  /// mean the stage has received anything.
  final double itemqty;

  /// Qty actually issued INTO this stage. Only the old trail shape carried
  /// it; the 2026-09-23 shape does not, so it is 0 there — never fall back
  /// to [itemqty] here or the Issue card locks before anything is sent.
  final double issuedqty;
  final double producedqty;

  /// Qty this stage has taken in from the previous one (gate-pass receive).
  final double receivedqty;
  final double qcqty;
  final double rejectqty;
  final double balanceqty;

  /// Backend's own verdict: "green" = this stage is through, "red" = not yet.
  final String status;

  JobStageRow({
    required this.stageid,
    required this.stagename,
    required this.issuedqty,
    required this.producedqty,
    required this.qcqty,
    required this.rejectqty,
    required this.balanceqty,
    this.seq = 0,
    this.itemqty = 0,
    this.receivedqty = 0,
    this.status = '',
    this.waitsfor = '',
    this.nextstages = '',
    this.dependson = '',
  });

  factory JobStageRow.fromJson(Map<String, dynamic> j) {
    final planned = _dbl(j['itemqty'] ?? j['issuedqty']);
    final produced = _dbl(j['producedqty'] ?? j['produced']);
    return JobStageRow(
      stageid: _int(j['stageid']),
      stagename: _str(j['stagename']),
      seq: _int(j['seq'] ?? j['routestep']),
      itemqty: planned,
      issuedqty: _dbl(j['issuedqty']),
      producedqty: produced,
      receivedqty: _dbl(j['received'] ?? j['receivedqty']),
      qcqty: _dbl(j['qcqty'] ?? j['qcd']),
      rejectqty: _dbl(j['rejectqty'] ?? j['reject']),
      // Not sent any more — derive it so the pills stay right.
      balanceqty: j['balanceqty'] != null
          ? _dbl(j['balanceqty'])
          : (planned - produced).clamp(0, double.infinity).toDouble(),
      status: _str(j['status']),
      waitsfor: _str(j['waitsfor']),
      nextstages: _str(j['nextstages']),
      dependson: _str(j['dependson']),
    );
  }

  /// Has anything actually reached this stage?
  bool get hasArrived => issuedqty > 0 || receivedqty > 0 || producedqty > 0;

  bool get isDone =>
      status.toLowerCase() == 'green' || (producedqty > 0 && balanceqty <= 0);
  bool get isInProgress => !isDone && producedqty > 0;
}

class NextStage {
  final int stageid;
  final String stagename;

  /// Every destination this stage feeds. One entry = the plain single-next
  /// flow; two or more = a split. Empty on an API build without the list.
  final List<NextStageOption> stages;

  const NextStage({
    required this.stageid,
    required this.stagename,
    this.stages = const [],
  });

  /// `0 / ""` from the API means "this is the last stage".
  bool get isLast => stageid <= 0;

  /// The work goes to more than one stage from here.
  bool get isSplit => stages.length > 1;

  /// "Full" | "Share" | "" — the API sets it the same on every entry.
  String get splitmode => stages.isEmpty ? '' : stages.first.splitmode;

  /// Each piece takes ONE route, so the stages share the QC-passed qty.
  bool get isShared => splitmode.toLowerCase().startsWith('shar');

  /// Still owed something.
  List<NextStageOption> get open =>
      stages.where((s) => s.remainingqty > 0).toList();

  NextStageOption? get first => stages.isEmpty ? null : stages.first;

  factory NextStage.fromJson(Map<String, dynamic> j) => NextStage(
    stageid: _int(j['nextstageid']),
    stagename: _str(j['nextstagename']),
    stages: j['nextstages'] is List
        ? (j['nextstages'] as List)
              .whereType<Map>()
              .map(
                (e) => NextStageOption.fromJson(Map<String, dynamic>.from(e)),
              )
              .where((e) => e.stageid > 0)
              .toList()
        : const [],
  );
}

/// `stoppages` row — one downtime or bottleneck event.
class Stoppage {
  final int id;
  final String type; // Downtime | Bottleneck
  final String reason;
  final String remarks;
  final String fromtime;
  final String totime;
  final int durationmin;
  final int challanid;
  final String itemname;
  final String stagename;
  final String imagepath;
  final String createdon;

  Stoppage({
    required this.id,
    required this.type,
    required this.reason,
    required this.remarks,
    required this.fromtime,
    required this.totime,
    required this.durationmin,
    required this.challanid,
    required this.itemname,
    required this.stagename,
    required this.imagepath,
    required this.createdon,
  });

  factory Stoppage.fromJson(Map<String, dynamic> j) => Stoppage(
    id: _int(j['Id'] ?? j['id']),
    type: _str(j['stype'] ?? j['type']),
    reason: _str(j['reason']),
    remarks: _str(j['remarks']),
    fromtime: _str(j['fromtime']),
    totime: _str(j['totime']),
    durationmin: _int(j['durationmin']),
    challanid: _int(j['challanid']),
    itemname: _str(j['itemname']),
    stagename: _str(j['stagename']),
    imagepath: _str(j['imagepath']),
    createdon: _str(j['createdon']),
  );

  bool get isDowntime => type.toLowerCase() == 'downtime';
}

/// `progressget` row.
/// One progress update (`progressget`). Since 2026-09-23 the backend keeps
/// every save as its own history row — shape: { id, stageid, stagename,
/// progresspct, remarks, updatedbyname, updatedon "yyyy-MM-dd HH:mm",
/// daydate "yyyy-MM-dd", photos (comma-separated presigned URLs), photokeys }.
class ProgressRow {
  final int id;
  final int itemid;
  final int stageid;
  final String stagename;
  final double progresspct;
  final String remarks;
  final String updatedon;

  /// Who saved this update, and the day to group it under in the log.
  final String updatedbyname;
  final String daydate;

  /// Presigned URLs of the photos saved with THIS update.
  final List<String> photos;

  /// Pieces the % applies to (batch work: "20 pcs at 30%"). From `wipqty`
  /// when the backend stores it, else parsed from remarks "wip=20".
  final double wipqty;

  ProgressRow({
    required this.itemid,
    required this.stageid,
    required this.stagename,
    required this.progresspct,
    required this.remarks,
    required this.updatedon,
    this.id = 0,
    this.updatedbyname = '',
    this.daydate = '',
    this.photos = const [],
    this.wipqty = 0,
  });

  factory ProgressRow.fromJson(Map<String, dynamic> j) => ProgressRow(
    id: _int(j['id']),
    itemid: _int(j['itemid']),
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    progresspct: _dbl(j['progresspct']),
    remarks: _str(j['remarks']),
    updatedon: _str(j['updatedon']),
    updatedbyname: _str(j['updatedbyname'] ?? j['operator']),
    daydate: _str(j['daydate']),
    photos: _csvUrls(j['photos']),
    wipqty: j['wipqty'] != null
        ? _dbl(j['wipqty'])
        : parseWipFromRemarks(_str(j['remarks'])),
  );

  /// `photos` arrives as one comma-separated string of presigned URLs (a
  /// list is accepted too). Commas inside a URL are escaped by the signer.
  static List<String> _csvUrls(dynamic v) {
    if (v is List) {
      return v.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList();
    }
    return '${v ?? ''}'
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.startsWith('http'))
        .toList();
  }

  /// The operator's own note, without the "wip=… · N pcs at X%" prefix the
  /// app writes in front of it.
  String get note {
    final parts = remarks.split('·').map((s) => s.trim()).toList();
    final rest = parts
        .where(
          (s) =>
              s.isNotEmpty &&
              !s.toLowerCase().startsWith('wip=') &&
              !RegExp(r'^[\d.]+\s*pcs at').hasMatch(s.toLowerCase()),
        )
        .toList();
    return rest.join(' · ');
  }

  /// "wip=20" anywhere in remarks → 20. Written by [wipRemarks].
  static double parseWipFromRemarks(String remarks) {
    final m = RegExp(
      r'wip\s*=\s*(\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(remarks);
    return m == null ? 0 : (double.tryParse(m.group(1)!) ?? 0);
  }

  /// Remarks the app writes with a progress save, e.g. "wip=20 · 20 pcs at 30%".
  static String wipRemarks(double wipqty, double pct) =>
      'wip=${fmtQty(wipqty)} · ${fmtQty(wipqty)} pcs at ${pct.toStringAsFixed(0)}%';
}

/// `uploadimage` result: the S3 key goes into `imagepath` on the next call.
class UploadedImage {
  final String filepath;
  final String filename;
  final String url;
  const UploadedImage({
    required this.filepath,
    required this.filename,
    required this.url,
  });

  factory UploadedImage.fromJson(Map<String, dynamic> j) => UploadedImage(
    filepath: _str(j['filepath']),
    filename: _str(j['filename']),
    url: _str(j['url']),
  );
}

/// Every write returns `{ id, message }` (plus `tostageid/tostagename` on
/// issue). `ok` is false when the envelope failed OR the ledger rejected the
/// entry (id <= 0 with the reason in `message`).
class OperatorWriteResult {
  final bool ok;
  final int id;
  final String message;
  final int tostageid;
  final String tostagename;

  const OperatorWriteResult({
    required this.ok,
    required this.id,
    required this.message,
    this.tostageid = 0,
    this.tostagename = '',
  });

  factory OperatorWriteResult.fail(String message) =>
      OperatorWriteResult(ok: false, id: 0, message: message);

  factory OperatorWriteResult.fromEnvelope(Map<String, dynamic> env) {
    final ok = env['success'] == true;
    final d = env['data'] is Map
        ? Map<String, dynamic>.from(env['data'] as Map)
        : <String, dynamic>{};
    final id = _int(d['id']);
    final msg = _str(d['message']).isNotEmpty
        ? _str(d['message'])
        : _str(env['message']);
    return OperatorWriteResult(
      ok: ok && (d.containsKey('id') ? id > 0 : true),
      id: id,
      message: msg,
      tostageid: _int(d['tostageid']),
      tostagename: _str(d['tostagename']),
    );
  }
}

/// Generic list/object envelope so the repo can hand back the message when a
/// read fails (e.g. "compid and challanid are required.").
class OperatorResult<T> {
  final bool ok;
  final String message;
  final T? data;
  const OperatorResult({required this.ok, required this.message, this.data});
}

/// One row of the job's day-wise history (`interia/entries`): a produce, QC
/// pass, reject or issue event with its own date, so "5 pcs yesterday, 5
/// today" can be shown separately instead of only the running total.
class LedgerEntry {
  final int id;
  final String entrytype; // Produce | QC | Reject | Issue

  /// The part this entry was recorded against, when the stage records parts.
  /// 0 / "" on an item-level row.
  final int partid;
  final String partname; // ledger
  final String entrydate; // "yyyy-MM-dd HH:mm" or "yyyy-MM-dd"
  final double qty;
  final int userid;
  final String username;
  final String remarks;
  final String disposition;

  /// Stage the entry belongs to (0 when the backend omits it). Lets one
  /// all-stages query feed both the job log and the downstream check.
  final int stageid;

  /// Only on Progress entries: % the batch was at.
  final double pct;

  /// Photos that came with the row itself (progress updates return presigned
  /// URLs). Produce / QC rows use the attachment store instead.
  final List<String> photoUrls;

  /// Loader hand-off rows only (`IssuedLoader` / `ReceivedLoader` /
  /// `RejectedLoader`, live 2026-09-25): the stage at the other end and who
  /// carried it. Those rows arrive with a NEGATIVE [id].
  final String fromstage;
  final String loadername;

  LedgerEntry({
    required this.id,
    required this.entrytype,
    required this.entrydate,
    required this.qty,
    required this.userid,
    required this.username,
    required this.remarks,
    required this.disposition,
    this.stageid = 0,
    this.pct = 0,
    this.photoUrls = const [],
    this.partid = 0,
    this.partname = '',
    this.fromstage = '',
    this.loadername = '',
  });

  /// A progress update rendered as a log row.
  factory LedgerEntry.fromProgress(ProgressRow r, {int userid = 0}) =>
      LedgerEntry(
        // Progress ids are their own sequence. Server rows are positive and
        // loader hand-offs are negative, so sit far below both.
        id: -1000000 - r.id,
        entrytype: 'Progress',
        entrydate: r.updatedon.isNotEmpty ? r.updatedon : r.daydate,
        qty: r.wipqty,
        userid: userid,
        username: r.updatedbyname,
        remarks: r.note,
        disposition: '',
        stageid: r.stageid,
        pct: r.progresspct,
        photoUrls: r.photos,
      );

  /// Live shape (2026-09-21): { id, entrydate "yyyy-MM-dd", stageid, stagename,
  /// producedqty, qcqty, rejectqty, issuedqty, operator, entrytype "Produced" }
  /// — one qty column per kind, so pick the one matching entrytype; a flat
  /// `qty` is accepted too.
  factory LedgerEntry.fromJson(Map<String, dynamic> j) {
    final type = _str(j['entrytype'] ?? j['type']);
    final t = type.toLowerCase();
    final double qty = j['qty'] != null
        ? _dbl(j['qty'])
        : t.startsWith('qc') || t.startsWith('pass')
        ? _dbl(j['qcqty'])
        : t.startsWith('rej')
        ? _dbl(j['rejectqty'])
        : t.startsWith('iss')
        ? _dbl(j['issuedqty'] ?? j['issueqty'])
        : t.startsWith('prog')
        ? (j['wipqty'] != null
              ? _dbl(j['wipqty'])
              : ProgressRow.parseWipFromRemarks(_str(j['remarks'])))
        : _dbl(j['producedqty']);
    return LedgerEntry(
      id: _int(j['id'] ?? j['Id']),
      entrytype: type,
      // `ts` ("2026-09-24T17:59:46") carries the time; `entrydate` is the
      // day only. Keep "yyyy-MM-dd HH:mm" so day grouping and the time
      // column both work off one field.
      entrydate: _tsOrDate(j),
      qty: qty,
      userid: _int(j['userid']),
      username: _str(j['username'] ?? j['operatorname'] ?? j['operator']),
      remarks: _str(j['remarks']),
      disposition: _str(j['disposition']),
      stageid: _int(j['stageid']),
      pct: _dbl(j['progresspct'] ?? j['pct']),
      photoUrls: ProgressRow._csvUrls(j['photos']),
      partid: _int(j['partid']),
      partname: _str(j['partname']),
      fromstage: _str(j['fromstage']),
      loadername: _str(j['loadername']),
    );
  }

  /// Calendar day for grouping (first 10 chars of the timestamp).
  String get day =>
      entrydate.length >= 10 ? entrydate.substring(0, 10) : entrydate;
  String get time => entrydate.length >= 16 ? entrydate.substring(11, 16) : '';

  /// Loader hand-off rows (negative ids on the server).
  bool get isIssuedLoader => entrytype == 'IssuedLoader';
  bool get isReceivedLoader => entrytype == 'ReceivedLoader';
  bool get isRejectedLoader => entrytype == 'RejectedLoader';
  bool get isLoaderEvent =>
      isIssuedLoader || isReceivedLoader || isRejectedLoader;

  /// "→ METAL" when sending, "← METAL" when something arrives or comes back.
  String get flow => fromstage.isEmpty
      ? ''
      : (isIssuedLoader ? '→ $fromstage' : '← $fromstage');

  /// The backend stamps its own rows "Produced (mobile)" / "QC (mobile)";
  /// that is not an operator note, so it is not worth a line in the log.
  static const _boilerplate = {
    'produced (mobile)',
    'qc (mobile)',
    'reject (mobile)',
    'issue (mobile)',
  };
  String get note =>
      _boilerplate.contains(remarks.trim().toLowerCase()) ? '' : remarks.trim();
  bool get isProduce => entrytype.toLowerCase().startsWith('prod');
  bool get isQc =>
      entrytype.toLowerCase().startsWith('qc') ||
      entrytype.toLowerCase().startsWith('pass');
  bool get isReject => entrytype.toLowerCase().startsWith('rej');
  bool get isIssue => entrytype.toLowerCase().startsWith('iss');
  bool get isProgress => entrytype.toLowerCase().startsWith('prog');
}

/// Loader handover ("gate pass"): one consignment issued from a stage to the
/// next, travelling with a loader. Lives in `interia/incoming` for the
/// receiving operator until they Accept / Reject it.
///
/// Backend contract (proposed 2026-09-22):
///   POST interia/incoming { compid, userid, branchid } ->
///   [{ consignmentid, issueid, challanid, challanno, itemid, itemname, boqno,
///      qty, fromstageid, fromstagename, tostageid, tostagename, loadername,
///      loaderref, issuedate "yyyy-MM-dd", issuetime "HH:mm", issuedby,
///      status "In Transit"|"Received"|"Rejected", remarks,
///      receiptimages [url], itemimages [url] }]
class Consignment {
  final int consignmentid;
  final int issueid;

  /// Set when the consignment holds ONE part of the item (part mode). The
  /// receive endpoint looks the row up by part — without it the server
  /// answers "Consignment not found."
  final int partid;
  final String partname;

  /// > 0 when this lot is a leg of a send back rather than forward work.
  /// `receive` needs it for the same reason it needs [partid].
  final int returnid;

  /// Stage that sent it back, from `returnfromstage`. A send-back row can
  /// come with `fromstageid: 0`, so this is the reliable name for "who
  /// returned this" when [fromstagename] is blank.
  final String returnfromstage;
  final int challanid;
  final String challanno;
  final int itemid;
  final String itemname;
  final String boqno;
  final double qty;
  final int fromstageid;
  final String fromstagename;
  final int tostageid;
  final String tostagename;
  final String loadername;
  final String loaderref;
  final String issuedate;
  final String issuetime;
  final String issuedby;
  final String status;
  final String remarks;
  final List<String> receiptimages;
  final List<String> itemimages;

  Consignment({
    required this.consignmentid,
    required this.issueid,
    this.partid = 0,
    this.partname = '',
    this.returnid = 0,
    this.returnfromstage = '',
    required this.challanid,
    required this.challanno,
    required this.itemid,
    required this.itemname,
    required this.boqno,
    required this.qty,
    required this.fromstageid,
    required this.fromstagename,
    required this.tostageid,
    required this.tostagename,
    required this.loadername,
    required this.loaderref,
    required this.issuedate,
    required this.issuetime,
    required this.issuedby,
    required this.status,
    required this.remarks,
    required this.receiptimages,
    required this.itemimages,
  });

  static List<String> _urls(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v
          .map((e) => e is Map ? _str(e['url'] ?? e['Url']) : _str(e))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return v
        .toString()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  factory Consignment.fromJson(Map<String, dynamic> j) => Consignment(
    consignmentid: _int(j['consignmentid'] ?? j['id']),
    issueid: _int(j['issueid']),
    partid: _int(j['partid']),
    partname: _str(j['partname']),
    returnid: _int(j['returnid']),
    returnfromstage: _str(j['returnfromstage']),
    challanid: _int(j['challanid']),
    challanno: _str(j['challanno']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    boqno: _str(j['boqno']),
    qty: _dbl(j['qty'] ?? j['issueqty']),
    fromstageid: _int(j['fromstageid']),
    fromstagename: _str(j['fromstagename']),
    tostageid: _int(j['tostageid']),
    tostagename: _str(j['tostagename']),
    loadername: _str(j['loadername']),
    loaderref: _str(j['loaderref'] ?? j['loaderno']),
    issuedate: _str(j['issuedate']),
    // Live `incoming` (2026-09-22) has issuetime + issuedon "yyyy-MM-dd HH:mm".
    issuetime: _str(j['issuetime']).isNotEmpty
        ? _str(j['issuetime'])
        : (_str(j['issuedon']).length >= 16
              ? _str(j['issuedon']).substring(11, 16)
              : ''),
    issuedby: _str(j['issuedby'] ?? j['issuedbyname']),
    status: _str(j['status']).isEmpty ? 'In Transit' : _str(j['status']),
    remarks: _str(j['remarks'] ?? j['issueremarks']),
    receiptimages: _urls(
      j['receiptimages'] ?? j['issuereceipturls'] ?? j['receiptphotos'],
    ),
    itemimages: _urls(j['itemimages'] ?? j['itemphotourls'] ?? j['itemphotos']),
  );

  bool get inTransit => status.toLowerCase().contains('transit');

  /// This lot is coming BACK to be fixed, not arriving as new work. The card
  /// says so, because the two need handling differently on the floor.
  bool get isSendBack => returnid > 0;

  /// Who returned it: `returnfromstage` when the row carries one (a send-back
  /// can arrive with `fromstageid: 0`), otherwise the ordinary from-stage.
  String get sentBackFrom =>
      returnfromstage.isNotEmpty ? returnfromstage : fromstagename;

  /// Same consignment with blanks filled from [other] (e.g. `issuedby` only
  /// comes on the myjobs row, photos only on the incoming list).
  Consignment merge(Consignment other) => Consignment(
    consignmentid: consignmentid > 0 ? consignmentid : other.consignmentid,
    issueid: issueid > 0 ? issueid : other.issueid,
    partid: partid > 0 ? partid : other.partid,
    partname: partname.isNotEmpty ? partname : other.partname,
    returnid: returnid > 0 ? returnid : other.returnid,
    returnfromstage: returnfromstage.isNotEmpty
        ? returnfromstage
        : other.returnfromstage,
    challanid: challanid,
    challanno: challanno.isNotEmpty ? challanno : other.challanno,
    itemid: itemid,
    itemname: itemname.isNotEmpty ? itemname : other.itemname,
    boqno: boqno.isNotEmpty ? boqno : other.boqno,
    qty: qty > 0 ? qty : other.qty,
    fromstageid: fromstageid > 0 ? fromstageid : other.fromstageid,
    fromstagename: fromstagename.isNotEmpty
        ? fromstagename
        : other.fromstagename,
    tostageid: tostageid > 0 ? tostageid : other.tostageid,
    tostagename: tostagename.isNotEmpty ? tostagename : other.tostagename,
    loadername: loadername.isNotEmpty ? loadername : other.loadername,
    loaderref: loaderref.isNotEmpty ? loaderref : other.loaderref,
    issuedate: issuedate.isNotEmpty ? issuedate : other.issuedate,
    issuetime: issuetime.isNotEmpty ? issuetime : other.issuetime,
    issuedby: issuedby.isNotEmpty ? issuedby : other.issuedby,
    status: status,
    remarks: remarks.isNotEmpty ? remarks : other.remarks,
    receiptimages: receiptimages.isNotEmpty
        ? receiptimages
        : other.receiptimages,
    itemimages: itemimages.isNotEmpty ? itemimages : other.itemimages,
  );
}

/// Gate-pass details captured when a consignment is sent via loader.
/// Photo keys come from `interia/uploadimage`.
class GatePass {
  final String loadername;
  final DateTime issuedAt;
  final String remarks;
  final List<String> receiptKeys;
  final List<String> itemKeys;
  const GatePass({
    required this.loadername,
    required this.issuedAt,
    this.remarks = '',
    this.receiptKeys = const [],
    this.itemKeys = const [],
  });
}

/// Prefer the row's timestamp over its date-only `entrydate`, normalised to
/// "yyyy-MM-dd HH:mm".
String _tsOrDate(Map<String, dynamic> j) {
  final ts = _str(j['ts']);
  if (ts.length >= 16) return '${ts.substring(0, 10)} ${ts.substring(11, 16)}';
  return _str(j['entrydate'] ?? j['createdon']);
}

// ── QC history (interia/qchistory) ───────────────────────────────────────────
//
// Every QC pass / reject the signed-in user saved, newest first, already
// grouped into days by the backend. Not QC-department-only: anyone who has
// ever saved a check sees their own rows.

/// One QC check the user saved.
class QcEntry {
  final int id;
  final String qcdate; // yyyy-MM-dd
  final String time; // "05:53 PM"
  final String ts;
  final int challanid;
  final String challanno;
  final int orderrefid;
  final String boqno;
  final String partyname;
  final int itemid;
  final String itemname;
  final int stageid;
  final String stagename;
  final double qcqty;
  final double rejectqty;
  final String result; // Passed | Rejected | Partial
  final String tone; // green | red | amber
  final String disposition; // Rework | Scrap | ''
  final String reason;
  final String remarks;
  final String producedby;

  /// Presigned S3 links — they expire in an hour, so never cache them.
  final List<String> photos;

  QcEntry({
    required this.id,
    required this.qcdate,
    required this.time,
    required this.ts,
    required this.challanid,
    required this.challanno,
    required this.orderrefid,
    required this.boqno,
    required this.partyname,
    required this.itemid,
    required this.itemname,
    required this.stageid,
    required this.stagename,
    required this.qcqty,
    required this.rejectqty,
    required this.result,
    required this.tone,
    required this.disposition,
    required this.reason,
    required this.remarks,
    required this.producedby,
    required this.photos,
  });

  factory QcEntry.fromJson(Map<String, dynamic> j) => QcEntry(
    id: _int(j['id']),
    qcdate: _str(j['qcdate']),
    time: _str(j['time']),
    ts: _str(j['ts']),
    challanid: _int(j['challanid']),
    challanno: _str(j['challanno']),
    orderrefid: _int(j['orderrefid']),
    boqno: _str(j['boqno']),
    partyname: _str(j['partyname']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    qcqty: _dbl(j['qcqty']),
    rejectqty: _dbl(j['rejectqty']),
    result: _str(j['result']),
    tone: _str(j['tone']),
    disposition: _str(j['disposition']),
    reason: _str(j['reason']),
    remarks: _str(j['remarks']),
    producedby: _str(j['producedby']),
    photos: Consignment._urls(j['photos']),
  );

  bool get hasReject => rejectqty > 0;
  bool get isPartial => qcqty > 0 && rejectqty > 0;
  bool get isPassed => !hasReject;

  /// Headline on the card / detail sheet: "Passed 5", "Rejected 1",
  /// "5 passed · 1 rejected".
  String get resultLabel => isPartial
      ? '${fmtQty(qcqty)} passed · ${fmtQty(rejectqty)} rejected'
      : hasReject
      ? 'Rejected ${fmtQty(rejectqty)}'
      : 'Passed ${fmtQty(qcqty)}';

  /// Everything the in-app search box looks through, lower-cased once.
  late final String haystack = [
    itemname,
    boqno,
    partyname,
    stagename,
    producedby,
    challanno,
    reason,
    remarks,
    disposition,
  ].join(' ').toLowerCase();
}

/// One QC day, as grouped by the backend.
class QcDay {
  final String qcdate;
  final String daylabel; // "Yesterday · 25 Sep 2026"
  final double passedqty;
  final double rejectedqty;
  final List<QcEntry> entries;

  QcDay({
    required this.qcdate,
    required this.daylabel,
    required this.passedqty,
    required this.rejectedqty,
    required this.entries,
  });

  factory QcDay.fromJson(Map<String, dynamic> j) => QcDay(
    qcdate: _str(j['qcdate']),
    daylabel: _str(j['daylabel']),
    passedqty: _dbl(j['passedqty']),
    rejectedqty: _dbl(j['rejectedqty']),
    entries: (j['entries'] is List)
        ? (j['entries'] as List)
              .whereType<Map>()
              .map((e) => QcEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );

  /// Same day with only [keep] — used by the in-app result / search filters.
  QcDay withEntries(List<QcEntry> keep) => QcDay(
    qcdate: qcdate,
    daylabel: daylabel,
    passedqty: keep.where((e) => !e.hasReject).fold(0, (a, e) => a + e.qcqty),
    rejectedqty: keep.fold(0, (a, e) => a + e.rejectqty),
    entries: keep,
  );
}

/// The four KPI cards. Recomputed by the backend for the date and stage
/// filters only — `result` and `search` leave it untouched, which is why
/// those two are applied in the app (see [OperatorController.qcVisibleDays]).
class QcSummary {
  final String fromdate;
  final String todate;
  final int entries;
  final int lots;
  final double passedqty;
  final double rejectedqty;
  final double reworkqty;
  final double scrapqty;

  /// Null when the range holds no checks at all — show a dash, not "0%".
  final int? passrate;

  const QcSummary({
    this.fromdate = '',
    this.todate = '',
    this.entries = 0,
    this.lots = 0,
    this.passedqty = 0,
    this.rejectedqty = 0,
    this.reworkqty = 0,
    this.scrapqty = 0,
    this.passrate,
  });

  factory QcSummary.fromJson(Map<String, dynamic> j) => QcSummary(
    fromdate: _str(j['fromdate']),
    todate: _str(j['todate']),
    entries: _int(j['entries']),
    lots: _int(j['lots']),
    passedqty: _dbl(j['passedqty']),
    rejectedqty: _dbl(j['rejectedqty']),
    reworkqty: _dbl(j['reworkqty']),
    scrapqty: _dbl(j['scrapqty']),
    passrate: j['passrate'] == null ? null : _int(j['passrate']),
  );
}

/// A stage the user has actually checked at — the filter sheet's chips come
/// from the server so they match the data, not the full stage master.
class QcStageOption {
  final int stageid;
  final String stagename;
  const QcStageOption(this.stageid, this.stagename);
}

/// Whole `qchistory` payload.
class QcHistory {
  final QcSummary summary;
  final List<QcStageOption> stages;
  final List<QcDay> days;

  const QcHistory({
    required this.summary,
    required this.stages,
    required this.days,
  });

  factory QcHistory.fromJson(Map<String, dynamic> j) {
    final f = j['filters'];
    final st = (f is Map ? f['stages'] : null);
    return QcHistory(
      summary: j['summary'] is Map
          ? QcSummary.fromJson(Map<String, dynamic>.from(j['summary']))
          : const QcSummary(),
      stages: st is List
          ? st
                .whereType<Map>()
                .map(
                  (e) =>
                      QcStageOption(_int(e['stageid']), _str(e['stagename'])),
                )
                .where((e) => e.stageid > 0)
                .toList()
          : const [],
      // `days[]` and the top-level `entries[]` carry the same rows; the
      // grouped one is the only one we read.
      days: j['days'] is List
          ? (j['days'] as List)
                .whereType<Map>()
                .map((e) => QcDay.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }

  static const empty = QcHistory(summary: QcSummary(), stages: [], days: []);
}

// ── Design pack (interia/jobdesign) ──────────────────────────────────────────
//
// What the operator needs in front of them to build the item right: the
// approved technical drawings, the materials the client specified, and the
// order's BOM design files.
//
// The backend already returns only APPROVED drawings (latest revision per
// drawing no) — never filter these again in the app, or a legitimately
// approved revision could be hidden.

/// Let QC write a rejected piece off as Scrap.
///
/// OFF at the client's request (2026-09-26). Scrap closed the challan short:
/// the operator's row went to `status: "Done"` with balance 0 and no reason
/// on it, so nobody was told the piece had been written off and nothing
/// replaced it — the order silently ran one short. Every rejection is a
/// Rework until that is sorted out. Flip to true to bring the picker back;
/// `qcreject` still accepts either disposition.
const bool kAllowScrap = false;

/// Show the client's custom materials on the job screen.
///
/// OFF at the client's request (2026-09-26): the operator is meant to work
/// from the approved technical drawings, and the material list — client
/// pricing lines, brand names, supplier codes — is not theirs to read. Flip
/// this to true to bring the whole section back; nothing else needs changing,
/// the card chip and the empty state follow it.
const bool kShowClientMaterials = false;

/// One attachment on a drawing / material / BOM design.
class DesignFile {
  final String name;

  /// Presigned S3 link. It expires, so it is never cached — the screen
  /// re-reads the pack when it opens or is pulled to refresh.
  final String url;
  final bool isimage;

  const DesignFile({
    required this.name,
    required this.url,
    required this.isimage,
  });

  factory DesignFile.fromJson(Map<String, dynamic> j) => DesignFile(
    name: _str(j['name']),
    url: _str(j['url']),
    // Fall back to the extension if the backend ever omits the flag.
    isimage:
        _canQc(j['isimage']) ||
        RegExp(
          r'\.(jpe?g|png|webp|gif|bmp)$',
          caseSensitive: false,
        ).hasMatch(_str(j['name'])),
  );

  static List<DesignFile> listFrom(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => DesignFile.fromJson(Map<String, dynamic>.from(e)))
            .where((f) => f.url.isNotEmpty)
            .toList()
      : const [];

  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}

/// One approved technical drawing.
class Drawing {
  final int id;
  final String drawingno;
  final String type; // "Working Drawing - Rev R0"
  final String status; // always "Approved" from this endpoint
  final String remarks;
  final String docno;
  final List<DesignFile> files;

  const Drawing({
    required this.id,
    required this.drawingno,
    required this.type,
    required this.status,
    required this.remarks,
    required this.docno,
    required this.files,
  });

  factory Drawing.fromJson(Map<String, dynamic> j) => Drawing(
    id: _int(j['id']),
    drawingno: _str(j['drawingno']),
    type: _str(j['type']),
    status: _str(j['status']),
    remarks: _str(j['remarks']),
    docno: _str(j['docno']),
    files: DesignFile.listFrom(j['files']),
  );

  List<DesignFile> get images => files.where((f) => f.isimage).toList();
  List<DesignFile> get docs => files.where((f) => !f.isimage).toList();
}

/// A material the client specified for this item (Material Requirement).
class DesignMaterial {
  final int id;
  final String name;
  final String category;
  final double qty;
  final String unit;
  final String remarks;
  final List<DesignFile> photos;

  const DesignMaterial({
    required this.id,
    required this.name,
    required this.category,
    required this.qty,
    required this.unit,
    required this.remarks,
    required this.photos,
  });

  factory DesignMaterial.fromJson(Map<String, dynamic> j) => DesignMaterial(
    id: _int(j['id']),
    name: _str(j['name']),
    category: _str(j['category']),
    qty: _dbl(j['qty']),
    unit: _str(j['unit']),
    remarks: _str(j['remarks']),
    photos: DesignFile.listFrom(j['photos']),
  );

  /// "12 SQFT", or just "SQFT" when no quantity was set — qty is often 0 on
  /// a client-specified finish, where only the material matters.
  String get qtyLabel => qty > 0 ? '${fmtQty(qty)} $unit'.trim() : unit.trim();
}

/// BOM design files, grouped by design number.
class BomDesign {
  final String designno;
  final List<DesignFile> files;

  const BomDesign({required this.designno, required this.files});

  factory BomDesign.fromJson(Map<String, dynamic> j) => BomDesign(
    designno: _str(j['designno']),
    files: DesignFile.listFrom(j['files']),
  );
}

/// Everything `jobdesign` returns for one (order, item).
class JobDesign {
  final List<Drawing> drawings;
  final List<DesignMaterial> materials;
  final List<BomDesign> bomdesigns;

  const JobDesign({
    this.drawings = const [],
    this.materials = const [],
    this.bomdesigns = const [],
  });

  factory JobDesign.fromJson(Map<String, dynamic> j) => JobDesign(
    drawings: j['drawings'] is List
        ? (j['drawings'] as List)
              .whereType<Map>()
              .map((e) => Drawing.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
    materials: j['materials'] is List
        ? (j['materials'] as List)
              .whereType<Map>()
              .map((e) => DesignMaterial.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
    bomdesigns: j['bomdesigns'] is List
        ? (j['bomdesigns'] as List)
              .whereType<Map>()
              .map((e) => BomDesign.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );

  /// The materials the screen may actually draw — empty while
  /// [kShowClientMaterials] is off.
  List<DesignMaterial> get visibleMaterials =>
      kShowClientMaterials ? materials : const [];

  /// Empty as far as the operator is concerned: hidden materials do not keep
  /// the empty state away.
  bool get isEmpty =>
      drawings.isEmpty && visibleMaterials.isEmpty && bomdesigns.isEmpty;

  /// Every image across the pack, in the order they are shown — the viewer
  /// swipes through one section's images, so each section builds its own.
  static const empty = JobDesign();
}

// ── Parallel routes (live 2026-09-28) ────────────────────────────────────────
//
// A challan's stages can split and join: after one stage the work may go to
// two or more stages at once, and a later stage may wait for several of them.
//
//   Full qty  (splitmode "Full")  different parts of the same piece go to
//                                 different stages — each next stage needs
//                                 the FULL qty, so sending to PAINT does not
//                                 reduce what UPHOLSTRY still needs.
//   Shared qty (splitmode "Share") each piece takes one route — the total
//                                 across all next stages cannot pass the
//                                 QC-passed qty.
//
// Old challans come back with one next stage and no qty fields, which reads
// as the single-destination flow the app has always had.

/// One destination a stage can issue to (`nextstage.nextstages[]`).
class NextStageOption {
  final int stageid;
  final String stagename;

  /// What the plan says this stage should get.
  final double planqty;

  /// Already issued + in transit to it from here.
  final double sentqty;

  /// What is still owed to it. The API sorts the list by this, highest first.
  final double remainingqty;

  /// "Full" | "Share" — the same on every entry of one list.
  final String splitmode;

  const NextStageOption({
    required this.stageid,
    required this.stagename,
    this.planqty = 0,
    this.sentqty = 0,
    this.remainingqty = 0,
    this.splitmode = '',
  });

  factory NextStageOption.fromJson(Map<String, dynamic> j) => NextStageOption(
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    planqty: _dbl(j['planqty']),
    sentqty: _dbl(j['sentqty']),
    remainingqty: _dbl(j['remainingqty']),
    splitmode: _str(j['splitmode']),
  );

  /// Nothing left owed to this stage.
  bool get allSent => remainingqty <= 0 && sentqty > 0;

  /// "Sent 0 of 10 · 10 left" / "Sent 10 of 10".
  String get sentLabel {
    final plan = planqty > 0 ? planqty : sentqty + remainingqty;
    final head = 'Sent ${fmtQty(sentqty)} of ${fmtQty(plan)}';
    return remainingqty > 0 ? '$head · ${fmtQty(remainingqty)} left' : head;
  }
}

/// One JOINING stage's view of a part it is waiting on, parsed out of
/// `myjobs.partsinfo` ("PAINT 1 · GLASS 0").
class JobPart {
  final String stagename;
  final double qty;
  const JobPart(this.stagename, this.qty);

  /// Something has actually been handed over.
  bool get arrived => qty > 0;

  /// The backend hands this over as one pre-joined string rather than a list,
  /// so it is split here. A stage name holding " · " would break the chips —
  /// stage names are single words in the master, so it holds.
  static List<JobPart> parse(String s) {
    if (s.trim().isEmpty) return const [];
    return s.split('·').map((p) => p.trim()).where((p) => p.isNotEmpty).map((
      p,
    ) {
      final at = p.lastIndexOf(' ');
      if (at <= 0) return JobPart(p, 0);
      return JobPart(
        p.substring(0, at).trim(),
        _dbl(p.substring(at + 1).trim()),
      );
    }).toList();
  }
}

// ── Parts / sub-items (live 2026-09-29) ──────────────────────────────────────
//
// The planner lists, on each stage, the parts made there — a name and the qty
// for ONE piece of the item. A part then travels to the stage that waits for
// it: METAL makes "MS frame" x1 and "MS leg" x4, both go to PAINT and on to
// ASSEBMLY.
//
// Phase 1 is DISPLAY ONLY. There is no per-part produce / QC / issue call, so
// nothing here gets a qty box or a button — the operator still records the
// whole item at their stage, as always.

/// One part at a job's stage (`myjobs.subitems[]`, `jobparts`).
class JobSubItem {
  /// `made` = made at this stage. `in` = arrives from [fromstage].
  final String kind;
  final String partname;

  /// How many of this part one finished piece needs.
  final double qtyperpiece;

  /// qtyperpiece × the job's planned qty.
  final double totalqty;

  /// Where it comes from (`in` only) and where it goes next ("" = the part
  /// stops here, i.e. the last stage).
  final String fromstage;
  final String nextstage;

  /// "METAL > PAINT > ASSEMBLY".
  final String path;

  // ── Live figures (live 2026-09-29, part recording) ──

  /// Identifies the part on every write call.
  final int partid;
  final int fromstageid;

  /// Where this part goes next — send it as `tostageid`. The plan fixes it,
  /// so the operator never chooses.
  final int nextstageid;

  /// The part is fitted into the item at this stage: nothing is recorded
  /// against it here, it only has to arrive.
  final bool isfinal;

  /// Total needed here = qtyperpiece × the job's plan qty.
  final double needqty;

  /// For an incoming part: arrived / still on a loader.
  final double receivedqty;
  final double intransitqty;

  final double madeqty;
  final double qcqty;
  final double rejectqty;

  /// made − rejected.
  final double goodqty;

  /// Handed on to [nextstage], of which [sendingqty] is still on a loader.
  final double sentqty;
  final double sendingqty;

  /// The three caps the buttons obey. The server works them out; the app
  /// never recomputes them, so a refusal and a disabled button always agree.
  final double canproduceqty;
  final double canqcqty;
  final double canissueqty;

  /// "To make" · "In progress" · "Awaiting QC" · "Ready to send" · "Rework" ·
  /// "Waiting" · "In transit" · "Sent" · "Done" · "To join" · "Joined" ·
  /// "Sent back" … — written by the server.
  final String status;

  // ── Parts joining into a unit (live 2026-09-30) ──
  //
  // A stage can be marked "parts join here": 1 Carcass + 4 Metal legs become
  // 1 Body, and the Body then travels as a part in its own right.

  /// This row IS the unit — made at the join stage, arriving after it.
  final bool isunit;

  /// Unit at its join stage: how many can be joined in all, i.e. complete
  /// sets of its parts that are here. `canproduceqty` already accounts for
  /// it, so the button still reads that.
  final double joinableqty;

  /// This row is a part that gets fitted into [joinunitname] here. It is
  /// received only — no produce, no QC, no hand-over against it.
  final bool isjoin;
  final int joinunitid;
  final String joinunitname;

  /// How many of this part are already inside joined units.
  final double joinedqty;

  /// Sent back from this stage to an earlier one and not returned yet.
  final double awayqty;

  /// Where the part really originates. For a part BOUGHT FROM A VENDOR the
  /// server sends the name "Vendor" and an id of 0 — it is not made at any
  /// stage; it arrives through Job Work Order → Indent → PO → MRN → QC and
  /// then lands on the stage that needs it.
  final String originstagename;
  final int originstageid;

  const JobSubItem({
    this.kind = '',
    this.partname = '',
    this.qtyperpiece = 0,
    this.totalqty = 0,
    this.fromstage = '',
    this.nextstage = '',
    this.path = '',
    this.partid = 0,
    this.fromstageid = 0,
    this.nextstageid = 0,
    this.isfinal = false,
    this.needqty = 0,
    this.receivedqty = 0,
    this.intransitqty = 0,
    this.madeqty = 0,
    this.qcqty = 0,
    this.rejectqty = 0,
    this.goodqty = 0,
    this.sentqty = 0,
    this.sendingqty = 0,
    this.canproduceqty = 0,
    this.canqcqty = 0,
    this.canissueqty = 0,
    this.status = '',
    this.isunit = false,
    this.joinableqty = 0,
    this.isjoin = false,
    this.joinunitid = 0,
    this.joinunitname = '',
    this.joinedqty = 0,
    this.awayqty = 0,
    this.originstagename = '',
    this.originstageid = 0,
  });

  factory JobSubItem.fromJson(Map<String, dynamic> j) => JobSubItem(
    kind: _str(j['kind']),
    partname: _str(j['partname']),
    qtyperpiece: _dbl(j['qtyperpiece']),
    totalqty: _dbl(j['totalqty']),
    fromstage: _str(j['fromstage']),
    nextstage: _str(j['nextstage']),
    path: _str(j['path']),
    partid: _int(j['partid']),
    fromstageid: _int(j['fromstageid']),
    nextstageid: _int(j['nextstageid']),
    isfinal: j['isfinal'] == true,
    // `needqty` is the new name; `totalqty` carries the same number.
    needqty: j['needqty'] != null ? _dbl(j['needqty']) : _dbl(j['totalqty']),
    receivedqty: _dbl(j['receivedqty']),
    intransitqty: _dbl(j['intransitqty']),
    madeqty: _dbl(j['madeqty']),
    qcqty: _dbl(j['qcqty']),
    rejectqty: _dbl(j['rejectqty']),
    goodqty: _dbl(j['goodqty']),
    sentqty: _dbl(j['sentqty']),
    sendingqty: _dbl(j['sendingqty']),
    canproduceqty: _dbl(j['canproduceqty']),
    canqcqty: _dbl(j['canqcqty']),
    canissueqty: _dbl(j['canissueqty']),
    status: _str(j['status']),
    isunit: j['isunit'] == true,
    joinableqty: _dbl(j['joinableqty']),
    isjoin: j['isjoin'] == true,
    joinunitid: _int(j['joinunitid']),
    joinunitname: _str(j['joinunitname']),
    joinedqty: _dbl(j['joinedqty']),
    awayqty: _dbl(j['awayqty']),
    // The server may name the origin on either field; "Vendor" on both.
    originstagename: _str(j['originstagename']).isNotEmpty
        ? _str(j['originstagename'])
        : _str(j['fromstage'] ?? j['fromstagename']),
    originstageid: _int(j['originstageid']),
  );

  bool get isMadeHere => kind.toLowerCase() == 'made';

  /// Bought from a vendor rather than made in the factory. It arrives via
  /// MRN QC, so no stage ever produces it — the origin is the word "Vendor",
  /// which is also why `originstageid` is 0 and must never be shown.
  bool get isVendor =>
      originstagename.trim().toLowerCase() == 'vendor' ||
      fromstage.trim().toLowerCase() == 'vendor';

  /// Where this part comes from, ready to show: a stage name, or "Vendor".
  String get originLabel =>
      originstagename.isNotEmpty ? originstagename : fromstage;

  /// Anything the operator can act on right now — **straight from the
  /// server's own caps, never re-derived here.**
  ///
  /// The server already sends 0 where an entry would be refused: a part
  /// fitted into a unit at this stage, or a vendor part at the stage that
  /// only receives it. Adding our own conditions on top broke exactly that
  /// (2026-10-01): a bought-in Sofa Leg arrived at Metal Paint to be
  /// painted with `canproduceqty: 8`, and an `!isVendor` guard hid the
  /// button — "bought in" says where it came from, not that nobody works
  /// on it. [isVendor] and [isjoin] are for LABELS only.
  bool get canProduce => canproduceqty > 0;
  bool get canQc => canqcqty > 0;
  bool get canIssue => canissueqty > 0;
  bool get hasAction => !isfinal && (canProduce || canQc || canIssue);

  /// "Joined 3 / 4 into Body" for a part that feeds a unit here.
  String get joinedLabel =>
      'Joined ${fmtQty(joinedqty)} / ${fmtQty(needqty)}'
      '${joinunitname.isEmpty ? '' : ' into $joinunitname'}';

  /// The verb for this part: a part made here is produced, one that arrives
  /// is worked on (painted, polished).
  String get produceVerb => isMadeHere ? 'Produce' : 'Work on';

  /// "3 of 4 made" / "1 / 1" for the header of the card.
  String get progressLabel =>
      '${fmtQty(isMadeHere ? madeqty : goodqty)} of ${fmtQty(needqty)}';

  /// "MS leg ×4" — the per-piece qty, which is what the operator works to.
  String get label => '$partname ×${fmtQty(qtyperpiece)}';

  static List<JobSubItem> listFrom(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => JobSubItem.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.partname.isNotEmpty)
            .toList()
      : const [];
}

/// One stage's parts from `interia/jobparts`.
class StageParts {
  final int stageid;
  final String stagename;

  /// Ready to show: "Make: MS frame x1, MS leg x4".
  final String text;
  final List<JobSubItem> made;
  final List<JobSubItem> comesin;

  const StageParts({
    this.stageid = 0,
    this.stagename = '',
    this.text = '',
    this.made = const [],
    this.comesin = const [],
  });

  factory StageParts.fromJson(Map<String, dynamic> j) => StageParts(
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    text: _str(j['text']),
    made: JobSubItem.listFrom(j['made']),
    comesin: JobSubItem.listFrom(j['comesin']),
  );
}

// ── Send back (returns) ────────────────────────────────────────────────────

/// One thing that can be sent back from a stage, as `sendback/options`
/// lists it. `partid` 0 = the whole item.
///
/// The two maxima are NOT interchangeable: [stageqty] is what arrived here
/// and has not been worked on, [qcqty] is what this stage already worked on
/// and can take back (with `worked=1`, which rejects it here first).
class SendBackGood {
  final int partid;
  final String name;

  /// Item · Part · Unit.
  final String kind;
  final double qtyperpiece;
  final double stageqty;
  final double qcqty;

  /// What physically holds it — the item a part is taken out of, or itself.
  final int holdpartid;
  final String holdname;
  final double holdratio;
  final int fixstagecount;

  const SendBackGood({
    this.partid = 0,
    this.name = '',
    this.kind = '',
    this.qtyperpiece = 0,
    this.stageqty = 0,
    this.qcqty = 0,
    this.holdpartid = 0,
    this.holdname = '',
    this.holdratio = 0,
    this.fixstagecount = 0,
  });

  factory SendBackGood.fromJson(Map<String, dynamic> j) => SendBackGood(
    partid: _int(j['partid']),
    name: _str(j['name'] ?? j['partname']),
    kind: _str(j['kind']),
    qtyperpiece: _dbl(j['qtyperpiece']),
    stageqty: _dbl(j['stageqty']),
    qcqty: _dbl(j['qcqty']),
    holdpartid: _int(j['holdpartid']),
    holdname: _str(j['holdname']),
    holdratio: _dbl(j['holdratio']),
    fixstagecount: _int(j['fixstagecount']),
  );

  /// This good is a component of [holdname] rather than a thing in its own
  /// right here — a Metal leg inside a Sofa, a Seat Frame inside a Sofa
  /// frame. The server still lists it, because it CAN extract one.
  bool get isInsideAnother => holdpartid > 0 && holdpartid != partid;

  /// Once pieces have been built into [holdname] they no longer exist
  /// separately on the floor: the whole assembled thing goes back, not a
  /// part of it (client rule, 2026-10-01 — "if the sofa frame and metal legs
  /// are formed to make a sofa, the whole sofa is sent back"). Pieces that
  /// are still LOOSE here — received and not worked on — can travel alone,
  /// which is why only the worked side is withheld.
  double maxFor({required bool worked}) =>
      worked ? (isInsideAnother ? 0 : qcqty) : stageqty;

  /// Only one of the two sides is offered when the other has nothing.
  bool get canUnworked => maxFor(worked: false) > 0;
  bool get canWorked => maxFor(worked: true) > 0;

  /// Nothing here to send back either way — the form hides it.
  bool get isEmpty => !canUnworked && !canWorked;
}

/// A stage this good can be sent back to: one it actually passed through.
class SendBackFixStage {
  final int stageid;
  final String stagename;

  /// Server-written: "Made here · came from here" / "On its route".
  final String note;

  /// Stages between the fix stage and home. The sender may tick any of
  /// them to be redone on the way back; none ticked = straight back.
  final List<SendBackFixStage> between;

  const SendBackFixStage({
    this.stageid = 0,
    this.stagename = '',
    this.note = '',
    this.between = const [],
  });

  factory SendBackFixStage.fromJson(Map<String, dynamic> j) => SendBackFixStage(
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    note: _str(j['note']),
    between: listFrom(j['between']),
  );

  static List<SendBackFixStage> listFrom(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => SendBackFixStage.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.stageid > 0)
            .toList()
      : const [];
}

/// The answer from `sendback/options` for one stage (and optionally one part).
class SendBackOptions {
  final List<SendBackGood> goods;

  /// The part the [fixstages] belong to. Picking another good means asking
  /// again with its partid — the route differs per part.
  final int partid;
  final List<SendBackFixStage> fixstages;

  /// The assembled thing that swallowed the parts we are NOT offering, e.g.
  /// "Sofa". Empty when nothing was held back for that reason. The form says
  /// so, otherwise an operator hunting for "Metal leg" just sees it missing.
  final String heldInside;

  const SendBackOptions({
    this.goods = const [],
    this.partid = 0,
    this.fixstages = const [],
    this.heldInside = '',
  });

  factory SendBackOptions.fromJson(Map<String, dynamic> j) {
    final all = (j['goods'] is List)
        ? (j['goods'] as List)
              .whereType<Map>()
              .map((e) => SendBackGood.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <SendBackGood>[];
    // Dropped only because they are already built into something else —
    // that holder is what goes back instead.
    final swallowed = all.where(
      (g) => g.isEmpty && g.isInsideAnother && g.qcqty > 0,
    );
    return SendBackOptions(
      goods: all.where((g) => !g.isEmpty).toList(),
      partid: _int(j['partid']),
      fixstages: SendBackFixStage.listFrom(j['fixstages']),
      heldInside: swallowed.isEmpty ? '' : swallowed.first.holdname,
    );
  }

  /// Nothing at this stage can go back, so the button stays hidden.
  bool get isEmpty => goods.isEmpty;

  SendBackGood? goodFor(int id) {
    for (final g in goods) {
      if (g.partid == id) return g;
    }
    return goods.isEmpty ? null : goods.first;
  }
}

/// One send back on a challan, as `returns` / `track/detail` lists it.
class ReturnTicket {
  final int returnid;

  /// Open · Back · Refused.
  final String status;
  final bool isopen;
  final String itemname;
  final String partname;
  final double qty;

  /// Operator · QC, and Stage (not worked yet) · QC (already worked).
  final String sentby;
  final String source;

  final String fromstagename;
  final String fixstagename;
  final String way;

  /// "PAINT 1, back 1".
  final String wherenow;
  final double backqty;
  final double openqty;

  final String faultstagename;
  final String reason;
  final String remarks;
  final List<String> photos;
  final String createdby;
  final String createdon;
  final String closedon;

  const ReturnTicket({
    this.returnid = 0,
    this.status = '',
    this.isopen = false,
    this.itemname = '',
    this.partname = '',
    this.qty = 0,
    this.sentby = '',
    this.source = '',
    this.fromstagename = '',
    this.fixstagename = '',
    this.way = '',
    this.wherenow = '',
    this.backqty = 0,
    this.openqty = 0,
    this.faultstagename = '',
    this.reason = '',
    this.remarks = '',
    this.photos = const [],
    this.createdby = '',
    this.createdon = '',
    this.closedon = '',
  });

  factory ReturnTicket.fromJson(Map<String, dynamic> j) => ReturnTicket(
    returnid: _int(j['returnid'] ?? j['id']),
    status: _str(j['status']),
    isopen: j['isopen'] == true,
    itemname: _str(j['itemname']),
    partname: _str(j['partname']),
    qty: _dbl(j['qty']),
    sentby: _str(j['sentby']),
    source: _str(j['source']),
    fromstagename: _str(j['fromstagename']),
    fixstagename: _str(j['fixstagename']),
    way: _str(j['way']),
    wherenow: _str(j['wherenow'] ?? j['atstagename']),
    backqty: _dbl(j['backqty']),
    openqty: _dbl(j['openqty']),
    faultstagename: _str(j['faultstagename']),
    reason: _str(j['reason']),
    remarks: _str(j['remarks']),
    photos: Consignment._urls(j['photos']),
    createdby: _str(j['createdby']),
    createdon: _str(j['createdon']),
    closedon: _str(j['closedon']),
  );

  /// "1 of 2 back" while it is still open.
  String get progressLabel => '${fmtQty(backqty)} of ${fmtQty(qty)} back';

  static List<ReturnTicket> listFrom(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => ReturnTicket.fromJson(Map<String, dynamic>.from(e)))
            .toList()
      : const [];
}

/// Rework counted against the stage whose work was faulty, wherever it was
/// actually fixed.
class ReworkFault {
  final String faultstagename;
  final double fixhereqty;
  final double sentbackqty;
  final double totalqty;

  const ReworkFault({
    this.faultstagename = '',
    this.fixhereqty = 0,
    this.sentbackqty = 0,
    this.totalqty = 0,
  });

  factory ReworkFault.fromJson(Map<String, dynamic> j) => ReworkFault(
    faultstagename: _str(j['faultstagename']),
    fixhereqty: _dbl(j['fixhereqty']),
    sentbackqty: _dbl(j['sentbackqty']),
    totalqty: _dbl(j['totalqty']),
  );

  /// "Fault: PAINT · 13 (1 fixed here, 12 sent back)".
  String get label =>
      'Fault: $faultstagename · ${fmtQty(totalqty)} '
      '(${fmtQty(fixhereqty)} fixed here, ${fmtQty(sentbackqty)} sent back)';

  static List<ReworkFault> listFrom(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => ReworkFault.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.faultstagename.isNotEmpty)
            .toList()
      : const [];
}

/// What `interia/returns` (and the same two lists on `track/detail`)
/// carries for one challan.
class ChallanReturns {
  final List<ReturnTicket> returns;
  final List<ReworkFault> faults;

  const ChallanReturns({this.returns = const [], this.faults = const []});

  factory ChallanReturns.fromJson(Map<String, dynamic> j) => ChallanReturns(
    returns: ReturnTicket.listFrom(j['returns']),
    faults: ReworkFault.listFrom(j['faults'] ?? j['reworkfaults']),
  );

  bool get isEmpty => returns.isEmpty && faults.isEmpty;

  /// Open ones first — the server already sorts, this only guards a
  /// build that does not.
  List<ReturnTicket> get sorted {
    final l = [...returns];
    l.sort((a, b) => (b.isopen ? 1 : 0) - (a.isopen ? 1 : 0));
    return l;
  }
}

// ── Packing (interia/pack/*) ───────────────────────────────────────────────
//
// At PACKING the operator does not "produce" — they pack. They say how many
// pieces went into boxes and, per box, what is inside and how many. Saving
// records those pieces as made at PACKING, so QC and dispatch carry on
// exactly as before.

/// The item being packed, as `pack/job` describes it.
class PackItem {
  final int challanid;
  final String challanno;
  final int itemid;
  final String itemname;
  final String description;
  final String room;
  final String size;
  final int boqid;
  final String boqno;
  final String clientname;
  final String sitename;
  final double planqty;
  final double packed;

  /// The most pieces THIS save may pack. Pieces already made at PACKING with
  /// the old Produce button count here too, so they can be given boxes
  /// without being made a second time.
  final double topack;

  const PackItem({
    this.challanid = 0,
    this.challanno = '',
    this.itemid = 0,
    this.itemname = '',
    this.description = '',
    this.room = '',
    this.size = '',
    this.boqid = 0,
    this.boqno = '',
    this.clientname = '',
    this.sitename = '',
    this.planqty = 0,
    this.packed = 0,
    this.topack = 0,
  });

  factory PackItem.fromJson(Map<String, dynamic> j) => PackItem(
    challanid: _int(j['challanid']),
    challanno: _str(j['challanno']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    description: _str(j['description']),
    room: _str(j['room']),
    size: _str(j['size']),
    boqid: _int(j['boqid']),
    boqno: _str(j['boqno']),
    clientname: _str(j['clientname']),
    sitename: _str(j['sitename']),
    planqty: _dbl(j['planqty']),
    packed: _dbl(j['packed']),
    topack: _dbl(j['topack']),
  );

  /// "Master Bedroom · BOQ/2026-27/8 · Rajiv Malhotra"
  String get subtitle => [
    if (room.isNotEmpty) room,
    if (boqno.isNotEmpty) boqno,
    if (clientname.isNotEmpty) clientname,
  ].join(' · ');
}

/// One box already saved, as `pack/job` → `packed[]` lists it.
class PackBox {
  final int boxid;
  final String boxno;
  final String contents;
  final double count;

  /// "box 2 of 3".
  final int boxof;
  final int boxesinpack;

  /// The save this box belongs to — Undo removes a whole pack, not one box.
  final int packid;
  final double packqty;

  final int challanid;
  final String challanno;
  final int itemid;
  final String itemname;
  final String description;
  final String room;

  /// Presigned, so they expire — never cached.
  final List<String> photos;
  final String packedby;
  final String packedon;

  /// The dispatch challan it left on; empty = still here.
  final String dcno;

  const PackBox({
    this.boxid = 0,
    this.boxno = '',
    this.contents = '',
    this.count = 0,
    this.boxof = 0,
    this.boxesinpack = 0,
    this.packid = 0,
    this.packqty = 0,
    this.challanid = 0,
    this.challanno = '',
    this.itemid = 0,
    this.itemname = '',
    this.description = '',
    this.room = '',
    this.photos = const [],
    this.packedby = '',
    this.packedon = '',
    this.dcno = '',
  });

  factory PackBox.fromJson(Map<String, dynamic> j) => PackBox(
    boxid: _int(j['boxid']),
    boxno: _str(j['boxno']),
    contents: _str(j['contents']),
    count: _dbl(j['count']),
    boxof: _int(j['boxof']),
    boxesinpack: _int(j['boxesinpack']),
    packid: _int(j['packid']),
    packqty: _dbl(j['packqty']),
    challanid: _int(j['challanid']),
    challanno: _str(j['challanno']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    description: _str(j['description']),
    room: _str(j['room']),
    photos: Consignment._urls(j['photos']),
    packedby: _str(j['packedby']),
    packedon: _str(j['packedon']),
    dcno: _str(j['dcno']),
  );

  /// Already on a dispatch challan — it cannot be undone any more.
  bool get isDispatched => dcno.trim().isNotEmpty;

  /// "Box 2 of 3"
  String get ofLabel =>
      boxesinpack > 1 ? 'Box $boxof of $boxesinpack' : 'Box $boxof';

  static List<PackBox> listFrom(dynamic v) => v is List
      ? v
            .whereType<Map>()
            .map((e) => PackBox.fromJson(Map<String, dynamic>.from(e)))
            .toList()
      : const [];
}

/// `pack/job`: the item, plus every box already saved against it.
class PackJob {
  final PackItem item;
  final List<PackBox> packed;

  const PackJob({this.item = const PackItem(), this.packed = const []});

  factory PackJob.fromJson(Map<String, dynamic> j) => PackJob(
    item: j['item'] is Map
        ? PackItem.fromJson(Map<String, dynamic>.from(j['item']))
        : const PackItem(),
    packed: PackBox.listFrom(j['packed']),
  );

  /// Saved boxes grouped by the save they belong to, newest first — Undo
  /// takes a whole pack, so the operator has to see them that way.
  Map<int, List<PackBox>> get byPack {
    final out = <int, List<PackBox>>{};
    for (final b in packed) {
      out.putIfAbsent(b.packid, () => []).add(b);
    }
    return out;
  }
}
