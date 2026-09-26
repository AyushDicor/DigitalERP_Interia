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

  /// Design pack counts (live 2026-09-26). The drawings are APPROVED ones
  /// only — the backend drops anything under review — so these are safe to
  /// show as-is. The pack itself comes from `jobdesign`.
  final int drawingcount;
  final int materialcount;
  final int bomdesigncount;
  final bool hasdesign;

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
    this.drawingcount = 0,
    this.materialcount = 0,
    this.bomdesigncount = 0,
    this.hasdesign = false,
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
    // Backend convention (2026-09-21): a QC person's myjobs rows carry
    // status "Awaiting QC" (no canqc field) — that IS the QC grant.
    canqc:
        _canQc(j['canqc'] ?? j['qcallowed'] ?? j['isqc']) ||
        _str(j['status']).toLowerCase().contains('awaiting qc'),
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
  );

  /// Same job on the same (challan, item, stage) — the key `progress` upserts on.
  String get key => '$challanid/$itemid/$stageid';

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

  /// The myjobs row viewed as a consignment (when the backend flags it in
  /// transit on the row itself instead of a separate `incoming` list).
  Consignment toConsignment() => Consignment(
    consignmentid: consignmentid,
    issueid: consignmentid,
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
  const NextStage({required this.stageid, required this.stagename});

  /// `0 / ""` from the API means "this is the last stage".
  bool get isLast => stageid <= 0;

  factory NextStage.fromJson(Map<String, dynamic> j) => NextStage(
    stageid: _int(j['nextstageid']),
    stagename: _str(j['nextstagename']),
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

  /// Same consignment with blanks filled from [other] (e.g. `issuedby` only
  /// comes on the myjobs row, photos only on the incoming list).
  Consignment merge(Consignment other) => Consignment(
    consignmentid: consignmentid > 0 ? consignmentid : other.consignmentid,
    issueid: issueid > 0 ? issueid : other.issueid,
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
                  (e) => QcStageOption(_int(e['stageid']), _str(e['stagename'])),
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

  static const empty = QcHistory(
    summary: QcSummary(),
    stages: [],
    days: [],
  );
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
  String get qtyLabel =>
      qty > 0 ? '${fmtQty(qty)} $unit'.trim() : unit.trim();
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
