// Production — Operator: data access.
//
// `OperatorRepo` is the contract the controller talks to. `ApiOperatorRepo`
// hits the live `interia/*` endpoints (see operator_models.dart for the list).
// `MockOperatorRepo` is an in-memory sample (Ramesh / CARPANTRY / BOQ jobs)
// used ONLY as a demo fallback: when the API reports no jobs issued to the
// logged-in user and [kOperatorDemoFallback] is on, the controller swaps to
// the mock so every screen can still be shown to the client. Set the flag to
// false once real challans are being issued to operators.

import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/services/api_service/api_client.dart';

import 'operator_models.dart';

/// Show sample jobs when the API has none for this user. Demo-only.
// 2026-09-21: OFF — client wants real ERP data only. The mock repo below is
// kept for design demos; flip to true to show sample jobs when myjobs is empty.
const bool kOperatorDemoFallback = false;

/// Login values every operator call echoes in its body (there is no token).
class OperatorSession {
  final int compid;
  final int branchid;
  final int userid;
  final String yearid;
  final String name;
  const OperatorSession({
    required this.compid,
    required this.branchid,
    required this.userid,
    required this.yearid,
    required this.name,
  });

  Map<String, dynamic> get common => {
    'compid': compid,
    'branchid': branchid,
    'userid': userid,
    'yearid': yearid,
  };
}

abstract class OperatorRepo {
  bool get isMock;

  Future<OperatorResult<List<OperatorJob>>> myJobs(OperatorSession s);

  /// Day-wise history of one job (produce / QC / reject / issue events).
  /// Backend contract (to be published): POST interia/entries
  ///   { compid, challanid, itemid, stageid } -> [LedgerEntry]
  /// [stageid] overrides the job's stage — 0 = every stage of the
  /// challan/item (used to infer what already went forward).
  Future<OperatorResult<List<LedgerEntry>>> entries(
    OperatorSession s,
    OperatorJob job, {
    int? stageid,
  });
  Future<OperatorResult<List<JobStageRow>>> jobStages(
    OperatorSession s,
    int challanid,
    int itemid,
  );

  /// Next stage for THIS challan (routing is per challan since 2026-09-22).
  /// The stages this one feeds. Since 2026-09-28 the answer carries a
  /// `nextstages[]` list, so a split returns every destination with its own
  /// plan / sent / remaining qty. [itemid] is required for a per-item route.
  Future<OperatorResult<NextStage>> nextStage(
    OperatorSession s,
    int stageid,
    int challanid, {
    int itemid = 0,
  });
  Future<OperatorResult<List<ProgressRow>>> progressGet(
    OperatorSession s,
    int challanid,
    int itemid,
    int stageid,
  );
  Future<OperatorResult<List<Stoppage>>> stoppages(
    OperatorSession s, {
    int challanid = 0,
    String type = '',
  });

  /// `entrydate` lets the operator back-date an entry (e.g. yesterday's
  /// pieces entered this morning). Sent as yyyy-MM-dd; the backend must
  /// honour it instead of stamping "now".
  /// [partid] records ONE part of the job instead of the whole item, and
  /// the qty is then in part units. 0 (the default) = item-level, as always.
  /// The same applies to qcPass, qcReject, issue and receive.
  Future<OperatorWriteResult> produce(
    OperatorSession s,
    OperatorJob job,
    double producedqty, {
    int partid = 0,
    int returnid = 0,
    DateTime? entrydate,
    String remarks = '',
  });

  /// `wipqty` = how many pieces the % applies to (batch work). Sent as
  /// `wipqty` AND encoded in remarks ("wip=20 …") so it round-trips even
  /// before the backend stores the column.
  /// Since 2026-09-23 every call APPENDS a history row (it used to overwrite
  /// one row per stage). [imageKeys] are S3 keys from `interia/uploadimage`;
  /// they are filed against THIS update and come back on `progressget`.
  Future<OperatorWriteResult> progress(
    OperatorSession s,
    OperatorJob job,
    double pct,
    double wipqty, {
    String remarks = '',
    List<String> imageKeys = const [],
  });
  Future<OperatorWriteResult> qcPass(
    OperatorSession s,
    OperatorJob job,
    double qcqty, {
    int partid = 0,
    int returnid = 0,
    String remarks = '',
    DateTime? entrydate,
  });
  Future<OperatorWriteResult> qcReject(
    OperatorSession s,
    OperatorJob job,
    double rejectqty, {
    int partid = 0,
    int returnid = 0,
    required String disposition,
    required String reason,
    int faultstageid = 0,
    int faultpartid = 0,
    String remarks = '',
    String imagepath = '',
    DateTime? entrydate,
  });

  /// Every QC check this login saved, newest first, grouped by day.
  ///   POST interia/qchistory { compid, userid, fromdate, todate, stageid }
  /// `result` and `search` exist on the endpoint too but are applied in the
  /// app instead: the server does not recompute `summary` for them, so the
  /// KPI cards would contradict the list.
  Future<OperatorResult<QcHistory>> qcHistory(
    OperatorSession s, {
    DateTime? from,
    DateTime? to,
    int stageid = 0,
  });

  /// The design pack for one job: approved drawings, the client's custom
  /// materials and the order's BOM design files.
  ///   POST interia/jobdesign { compid, orderrefid, itemid }
  /// All three are required; the urls that come back are presigned and
  /// expire, so the result is re-read rather than cached.
  Future<OperatorResult<JobDesign>> jobDesign(
    OperatorSession s,
    int orderrefid,
    int itemid,
  );

  /// What can be sent back from [stageid], and which earlier stages it may
  /// go to. Ask again with a [partid] when the operator picks a different
  /// good — the route is per part, not per stage.
  Future<OperatorResult<SendBackOptions>> sendBackOptions(
    OperatorSession s, {
    required int challanid,
    required int stageid,
    int partid = 0,
  });

  /// Send pieces back to an earlier stage. [worked] 1 = pieces this stage
  /// already worked on (they are rejected here first, capped by the good's
  /// `qcqty`); 0 = pieces that arrived and were never touched (`stageqty`).
  /// [redostageids] are stages to redo on the way home; empty = straight
  /// back. Answers with `data.returnid`.
  Future<OperatorWriteResult> sendBack(
    OperatorSession s, {
    required int challanid,
    required int stageid,
    required int partid,
    required double qty,
    required int fixstageid,
    required String reason,
    int worked = 0,
    List<int> redostageids = const [],
    int faultstageid = 0,
    List<String> imageKeys = const [],
    GatePass? gatePass,
  });

  /// Every send back on a challan, plus the rework counted against each
  /// stage whose work was faulty.
  Future<OperatorResult<ChallanReturns>> challanReturns(
    OperatorSession s, {
    required int challanid,
    int itemid = 0,
  });

  /// The item to pack, how many pieces are still packable, and the boxes
  /// already saved against it.
  Future<OperatorResult<PackJob>> packJob(
    OperatorSession s, {
    required int challanid,
    required int itemid,
  });

  /// Record [qty] pieces packed into [boxes]. This is what makes them
  /// "produced" at PACKING — there is no separate produce call.
  ///
  /// [clienttoken] must be a fresh id per Save tap and the SAME id on a
  /// retry: the server answers "Already saved." with the same box numbers
  /// rather than packing the pieces twice.
  Future<OperatorWriteResult> packSave(
    OperatorSession s, {
    required int challanid,
    required int itemid,
    required double qty,
    required List<Map<String, dynamic>> boxes,
    required String clienttoken,
    DateTime? entrydate,
  });

  /// Undo one save (its `packid`). The boxes go; the pieces stay made at
  /// PACKING and can be packed again.
  Future<OperatorWriteResult> packRemove(
    OperatorSession s, {
    required int packid,
  });

  /// QC rejects AND sends the pieces back to an earlier stage, in one call.
  ///
  /// Different from [sendBack]: the rejection is recorded here and now, and
  /// the rework at THIS stage only opens as the pieces come home. [partid]
  /// is what was checked (0 = the item); [sendbackpartid] is what actually
  /// travels, which may be a part taken out of the rejected item.
  /// Answers with `data.returnid`.
  Future<OperatorWriteResult> qcRejectSendBack(
    OperatorSession s,
    OperatorJob job, {
    required double rejectqty,
    required int fixstageid,
    required String reason,
    int partid = 0,
    int sendbackpartid = 0,
    double sendbackqty = 0,
    List<int> redostageids = const [],
    int faultstageid = 0,
    String remarks = '',
    List<String> imageKeys = const [],
    GatePass? gatePass,
  });

  /// Issue QC-passed qty to the next stage. With [gatePass] the consignment
  /// travels via loader: extra fields go in the same call and the next stage
  /// sees it under `incoming` until they Accept / Reject it.
  Future<OperatorWriteResult> issue(
    OperatorSession s,
    OperatorJob job,
    double issueqty, {
    int partid = 0,
    int returnid = 0,
    NextStage? to,
    String batchno = '',
    GatePass? gatePass,
  });

  /// Consignments in transit to this login's stage (proposed:
  /// POST interia/incoming { compid, userid, branchid }).
  Future<OperatorResult<List<Consignment>>> incoming(OperatorSession s);

  /// Book a consignment in. A receipt can be PARTIAL: [qtyaccepted] is taken
  /// in at this stage and [qtyrejected] goes back to the sender to be made
  /// again (rework). The receiver has no scrap option — writing stock off is
  /// the sending stage's QC decision, through `qcReject`.
  Future<OperatorWriteResult> receive(
    OperatorSession s,
    Consignment cn, {
    int partid = 0,
    int returnid = 0,
    required String loadername,
    required DateTime receivedAt,
    required double qtyaccepted,
    required double qtyrejected,
    String reason = '',
    List<String> signedReceiptKeys = const [],
    List<String> itemImageKeys = const [],
    String remarks = '',
  });
  Future<OperatorWriteResult> stoppage(
    OperatorSession s, {
    required bool downtime,
    required String reason,
    OperatorJob? job,
    String remarks = '',
    DateTime? from,
    DateTime? to,
    int durationmin = 0,
    DateTime? entrydate,
    String imagepath = '',
  });
  Future<OperatorResult<UploadedImage>> uploadImage(
    OperatorSession s,
    String filePath,
  );
}

// ── Live API ───────────────────────────────────────────────────────────────

class ApiOperatorRepo implements OperatorRepo {
  static const _myjobs = 'interia/myjobs';
  static const _entries = 'interia/entries';
  static const _jobstages = 'interia/jobstages';
  static const _nextstage = 'interia/nextstage';
  static const _produce = 'interia/produce';
  static const _qc = 'interia/qc';
  static const _qcreject = 'interia/qcreject';
  static const _qchistory = 'interia/qchistory';
  static const _jobdesign = 'interia/jobdesign';
  static const _issue = 'interia/issue';
  static const _incoming = 'interia/incoming';
  static const _receive = 'interia/receive';
  static const _downtime = 'interia/downtime';
  static const _bottleneck = 'interia/bottleneck';
  static const _stoppages = 'interia/stoppages';
  static const _progress = 'interia/progress';
  static const _progressget = 'interia/progressget';
  static const _uploadimage = 'interia/uploadimage';
  static const _sendbackoptions = 'interia/sendback/options';
  static const _sendback = 'interia/sendback';
  static const _returns = 'interia/returns';
  static const _packjob = 'interia/pack/job';
  static const _packsave = 'interia/pack/save';
  static const _packremove = 'interia/pack/remove';

  static final _dt = DateFormat('yyyy-MM-dd HH:mm');
  static final _d = DateFormat('yyyy-MM-dd');

  @override
  bool get isMock => false;

  Future<Map<String, dynamic>> _post(
    String method,
    Map<String, dynamic> body,
  ) async {
    final raw = await ApiClient().postAppJson(method: method, body: body);
    if (raw.isEmpty) {
      return {'success': false, 'message': 'No response from server.'};
    }
    try {
      final j = jsonDecode(raw);
      return j is Map ? Map<String, dynamic>.from(j) : {'success': false};
    } catch (e) {
      return {'success': false, 'message': 'Bad response: $e'};
    }
  }

  OperatorResult<List<T>> _list<T>(
    Map<String, dynamic> env,
    T Function(Map<String, dynamic>) f,
  ) {
    final ok = env['success'] == true;
    final data = env['data'];
    final rows = data is List
        ? data
              .whereType<Map>()
              .map((e) => f(Map<String, dynamic>.from(e)))
              .toList()
        : <T>[];
    return OperatorResult(
      ok: ok,
      message: (env['message'] ?? '').toString(),
      data: rows,
    );
  }

  Map<String, dynamic> _jobCtx(OperatorJob job) => {
    'challanid': job.challanid,
    'orderrefid': job.orderrefid,
    'itemid': job.itemid,
    'itemname': job.itemname,
    'stageid': job.stageid,
    'stagename': job.stagename,
  };

  @override
  Future<OperatorResult<List<OperatorJob>>> myJobs(OperatorSession s) async =>
      _list(
        await _post(_myjobs, {
          'compid': s.compid,
          'userid': s.userid,
          'branchid': s.branchid,
        }),
        OperatorJob.fromJson,
      );

  @override
  Future<OperatorResult<List<LedgerEntry>>> entries(
    OperatorSession s,
    OperatorJob job, {
    int? stageid,
  }) async => _list(
    await _post(_entries, {
      'compid': s.compid,
      'challanid': job.challanid,
      'itemid': job.itemid,
      'stageid': stageid ?? job.stageid,
    }),
    LedgerEntry.fromJson,
  );

  @override
  Future<OperatorResult<List<JobStageRow>>> jobStages(
    OperatorSession s,
    int challanid,
    int itemid,
  ) async => _list(
    await _post(_jobstages, {
      'compid': s.compid,
      'challanid': challanid,
      'itemid': itemid,
    }),
    JobStageRow.fromJson,
  );

  @override
  Future<OperatorResult<NextStage>> nextStage(
    OperatorSession s,
    int stageid,
    int challanid, {
    int itemid = 0,
  }) async {
    final env = await _post(_nextstage, {
      'compid': s.compid,
      'stageid': stageid,
      'challanid': challanid,
      if (itemid > 0) 'itemid': itemid,
    });
    final d = env['data'];
    return OperatorResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map ? NextStage.fromJson(Map<String, dynamic>.from(d)) : null,
    );
  }

  @override
  Future<OperatorResult<List<ProgressRow>>> progressGet(
    OperatorSession s,
    int challanid,
    int itemid,
    int stageid,
  ) async => _list(
    await _post(_progressget, {
      'compid': s.compid,
      'challanid': challanid,
      'itemid': itemid,
      'stageid': stageid,
    }),
    ProgressRow.fromJson,
  );

  @override
  Future<OperatorResult<List<Stoppage>>> stoppages(
    OperatorSession s, {
    int challanid = 0,
    String type = '',
  }) async => _list(
    await _post(_stoppages, {
      'compid': s.compid,
      'challanid': challanid,
      if (type.isNotEmpty) 'type': type,
    }),
    Stoppage.fromJson,
  );

  @override
  Future<OperatorWriteResult> produce(
    OperatorSession s,
    OperatorJob job,
    double producedqty, {
    int partid = 0,
    int returnid = 0,
    DateTime? entrydate,
    String remarks = '',
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_produce, {
      ...s.common,
      if (partid > 0) 'partid': partid,
      if (returnid > 0) 'returnid': returnid,
      ..._jobCtx(job),
      'producedqty': producedqty,
      'entrydate': _d.format(entrydate ?? DateTime.now()),
      'remarks': remarks,
    }),
  );

  @override
  Future<OperatorWriteResult> progress(
    OperatorSession s,
    OperatorJob job,
    double pct,
    double wipqty, {
    String remarks = '',
    List<String> imageKeys = const [],
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_progress, {
      'compid': s.compid,
      'userid': s.userid,
      'branchid': s.branchid, // photos only attach when this is sent
      'imagepath': imageKeys.join(','),
      'challanid': job.challanid,
      'orderrefid': job.orderrefid,
      'itemid': job.itemid,
      'stageid': job.stageid,
      'stagename': job.stagename,
      'progresspct': pct,
      'wipqty': wipqty,
      // The wip encoding must stay first — parseWipFromRemarks reads it.
      'remarks': remarks.trim().isEmpty
          ? ProgressRow.wipRemarks(wipqty, pct)
          : '${ProgressRow.wipRemarks(wipqty, pct)} · ${remarks.trim()}',
    }),
  );

  @override
  Future<OperatorWriteResult> qcPass(
    OperatorSession s,
    OperatorJob job,
    double qcqty, {
    int partid = 0,
    int returnid = 0,
    String remarks = '',
    DateTime? entrydate,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_qc, {
      ...s.common,
      if (partid > 0) 'partid': partid,
      if (returnid > 0) 'returnid': returnid,
      ..._jobCtx(job),
      'qcqty': qcqty,
      'rejectqty': 0,
      'entrydate': _d.format(entrydate ?? DateTime.now()),
      // The endpoint takes remarks; without this a QC pass note was typed
      // and silently thrown away.
      'remarks': remarks,
    }),
  );

  @override
  Future<OperatorWriteResult> qcReject(
    OperatorSession s,
    OperatorJob job,
    double rejectqty, {
    int partid = 0,
    int returnid = 0,
    required String disposition,
    required String reason,
    int faultstageid = 0,
    int faultpartid = 0,
    String remarks = '',
    String imagepath = '',
    DateTime? entrydate,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_qcreject, {
      ...s.common,
      if (partid > 0) 'partid': partid,
      if (returnid > 0) 'returnid': returnid,
      ..._jobCtx(job),
      'rejectqty': rejectqty,
      'disposition': disposition,
      'reason': reason,
      if (faultstageid > 0) 'faultstageid': faultstageid,
      if (faultpartid > 0) 'faultpartid': faultpartid,
      'remarks': remarks,
      'imagepath': imagepath,
      'entrydate': _d.format(entrydate ?? DateTime.now()),
    }),
  );

  @override
  Future<OperatorResult<QcHistory>> qcHistory(
    OperatorSession s, {
    DateTime? from,
    DateTime? to,
    int stageid = 0,
  }) async {
    final env = await _post(_qchistory, {
      'compid': s.compid,
      'userid': s.userid,
      // Left out = the server's own window (last 30 days, ending today).
      if (from != null) 'fromdate': _d.format(from),
      if (to != null) 'todate': _d.format(to),
      if (stageid > 0) 'stageid': stageid,
    });
    final d = env['data'];
    return OperatorResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map ? QcHistory.fromJson(Map<String, dynamic>.from(d)) : null,
    );
  }

  @override
  Future<OperatorResult<JobDesign>> jobDesign(
    OperatorSession s,
    int orderrefid,
    int itemid,
  ) async {
    final env = await _post(_jobdesign, {
      'compid': s.compid,
      'orderrefid': orderrefid,
      'itemid': itemid,
    });
    final d = env['data'];
    return OperatorResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map ? JobDesign.fromJson(Map<String, dynamic>.from(d)) : null,
    );
  }

  @override
  Future<OperatorResult<SendBackOptions>> sendBackOptions(
    OperatorSession s, {
    required int challanid,
    required int stageid,
    int partid = 0,
  }) async {
    final env = await _post(_sendbackoptions, {
      'compid': s.compid,
      'challanid': challanid,
      'stageid': stageid,
      if (partid > 0) 'partid': partid,
    });
    final d = env['data'];
    return OperatorResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map
          ? SendBackOptions.fromJson(Map<String, dynamic>.from(d))
          : null,
    );
  }

  @override
  Future<OperatorWriteResult> sendBack(
    OperatorSession s, {
    required int challanid,
    required int stageid,
    required int partid,
    required double qty,
    required int fixstageid,
    required String reason,
    int worked = 0,
    List<int> redostageids = const [],
    int faultstageid = 0,
    List<String> imageKeys = const [],
    GatePass? gatePass,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_sendback, {
      ...s.common,
      'challanid': challanid,
      'stageid': stageid,
      // 0 is a real value here: it means the whole item, so it always goes.
      'partid': partid,
      'qty': qty,
      'worked': worked,
      'fixstageid': fixstageid,
      'redostageids': redostageids,
      if (faultstageid > 0) 'faultstageid': faultstageid,
      'reason': reason,
      'imagepath': imageKeys.join(','),
      'vialoader': gatePass == null ? 0 : 1,
      if (gatePass != null) ...{
        'loadername': gatePass.loadername,
        'issuedate': _d.format(gatePass.issuedAt),
        'issuetime': DateFormat('HH:mm').format(gatePass.issuedAt),
        'remarks': gatePass.remarks,
        'receiptimages': gatePass.receiptKeys,
        'itemimages': gatePass.itemKeys,
      },
    }),
  );

  @override
  Future<OperatorResult<ChallanReturns>> challanReturns(
    OperatorSession s, {
    required int challanid,
    int itemid = 0,
  }) async {
    final env = await _post(_returns, {
      'compid': s.compid,
      'challanid': challanid,
      if (itemid > 0) 'itemid': itemid,
    });
    final d = env['data'];
    return OperatorResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map
          ? ChallanReturns.fromJson(Map<String, dynamic>.from(d))
          : const ChallanReturns(),
    );
  }

  @override
  Future<OperatorResult<PackJob>> packJob(
    OperatorSession s, {
    required int challanid,
    required int itemid,
  }) async {
    final env = await _post(_packjob, {
      'compid': s.compid,
      'challanid': challanid,
      'itemid': itemid,
    });
    final d = env['data'];
    return OperatorResult(
      ok: env['success'] == true,
      message: (env['message'] ?? '').toString(),
      data: d is Map
          ? PackJob.fromJson(Map<String, dynamic>.from(d))
          : const PackJob(),
    );
  }

  @override
  Future<OperatorWriteResult> packSave(
    OperatorSession s, {
    required int challanid,
    required int itemid,
    required double qty,
    required List<Map<String, dynamic>> boxes,
    required String clienttoken,
    DateTime? entrydate,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_packsave, {
      ...s.common,
      'challanid': challanid,
      'itemid': itemid,
      'qty': qty,
      // A JSON array, one entry per box.
      'boxes': boxes,
      // Makes the save idempotent across a retry.
      'clienttoken': clienttoken,
      'entrydate': _d.format(entrydate ?? DateTime.now()),
    }),
  );

  @override
  Future<OperatorWriteResult> packRemove(
    OperatorSession s, {
    required int packid,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_packremove, {
      'compid': s.compid,
      'userid': s.userid,
      'packid': packid,
    }),
  );

  @override
  Future<OperatorWriteResult> qcRejectSendBack(
    OperatorSession s,
    OperatorJob job, {
    required double rejectqty,
    required int fixstageid,
    required String reason,
    int partid = 0,
    int sendbackpartid = 0,
    double sendbackqty = 0,
    List<int> redostageids = const [],
    int faultstageid = 0,
    String remarks = '',
    List<String> imageKeys = const [],
    GatePass? gatePass,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_qcreject, {
      ...s.common,
      ..._jobCtx(job),
      // The fork: the same endpoint rejects in place without this.
      'action': 'sendback',
      // 0 is meaningful (the item), so both always go.
      'partid': partid,
      'sendbackpartid': sendbackpartid > 0 ? sendbackpartid : partid,
      'rejectqty': rejectqty,
      'sendbackqty': sendbackqty > 0 ? sendbackqty : rejectqty,
      'fixstageid': fixstageid,
      'redostageids': redostageids,
      if (faultstageid > 0) 'faultstageid': faultstageid,
      'reason': reason,
      'remarks': remarks,
      'imagepath': imageKeys.join(','),
      'vialoader': gatePass == null ? 0 : 1,
      if (gatePass != null) ...{
        'loadername': gatePass.loadername,
        'issuedate': _d.format(gatePass.issuedAt),
        'issuetime': DateFormat('HH:mm').format(gatePass.issuedAt),
        'receiptimages': gatePass.receiptKeys,
        'itemimages': gatePass.itemKeys,
      },
    }),
  );

  @override
  Future<OperatorWriteResult> issue(
    OperatorSession s,
    OperatorJob job,
    double issueqty, {
    int partid = 0,
    int returnid = 0,
    NextStage? to,
    String batchno = '',
    GatePass? gatePass,
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_issue, {
      ...s.common,
      if (partid > 0) 'partid': partid,
      if (returnid > 0) 'returnid': returnid,
      'challanid': job.challanid,
      'orderrefid': job.orderrefid,
      'itemid': job.itemid,
      'itemname': job.itemname,
      'fromstageid': job.stageid,
      'fromstagename': job.stagename,
      if (to != null && !to.isLast) 'tostageid': to.stageid,
      if (to != null && !to.isLast) 'tostagename': to.stagename,
      'batchno': batchno,
      'issueqty': issueqty,
      'vialoader': gatePass == null ? 0 : 1,
      if (gatePass != null) ...{
        'loadername': gatePass.loadername,
        'issuedate': _d.format(gatePass.issuedAt),
        'issuetime': DateFormat('HH:mm').format(gatePass.issuedAt),
        'remarks': gatePass.remarks,
        'receiptimages': gatePass.receiptKeys,
        'itemimages': gatePass.itemKeys,
      },
    }),
  );

  @override
  Future<OperatorResult<List<Consignment>>> incoming(OperatorSession s) async =>
      _list(
        await _post(_incoming, {
          'compid': s.compid,
          'userid': s.userid,
          'branchid': s.branchid,
        }),
        Consignment.fromJson,
      );

  @override
  Future<OperatorWriteResult> receive(
    OperatorSession s,
    Consignment cn, {
    int partid = 0,
    int returnid = 0,
    required String loadername,
    required DateTime receivedAt,
    required double qtyaccepted,
    required double qtyrejected,
    String reason = '',
    List<String> signedReceiptKeys = const [],
    List<String> itemImageKeys = const [],
    String remarks = '',
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(_receive, {
      ...s.common,
      if (partid > 0) 'partid': partid,
      if (returnid > 0) 'returnid': returnid,
      'consignmentid': cn.consignmentid,
      'issueid': cn.issueid,
      'challanid': cn.challanid,
      'itemid': cn.itemid,
      'fromstageid': cn.fromstageid,
      'tostageid': cn.tostageid,
      'action': qtyrejected <= 0
          ? 'Accept'
          : (qtyaccepted <= 0 ? 'Reject' : 'Partial'),
      'loadername': loadername,
      'receivedate': _d.format(receivedAt),
      'receivetime': DateFormat('HH:mm').format(receivedAt),
      'qtyaccepted': qtyaccepted,
      'qtyrejected': qtyrejected,
      'reason': reason,
      // Kept for the older contract, which had no accept/reject split.
      'qtyreceived': qtyaccepted,
      'signedreceiptimages': signedReceiptKeys,
      'itemimages': itemImageKeys,
      'remarks': remarks,
    }),
  );

  @override
  Future<OperatorWriteResult> stoppage(
    OperatorSession s, {
    required bool downtime,
    required String reason,
    OperatorJob? job,
    String remarks = '',
    DateTime? from,
    DateTime? to,
    int durationmin = 0,
    DateTime? entrydate,
    String imagepath = '',
  }) async => OperatorWriteResult.fromEnvelope(
    await _post(downtime ? _downtime : _bottleneck, {
      ...s.common,
      'reason': reason,
      'remarks': remarks,
      if (job != null) ..._jobCtx(job),
      if (from != null) 'fromtime': _dt.format(from),
      if (to != null) 'totime': _dt.format(to),
      'durationmin': durationmin,
      'entrydate': _d.format(entrydate ?? DateTime.now()),
      'imagepath': imagepath,
    }),
  );

  /// multipart: compid + file → { filepath, filename, url }.
  @override
  Future<OperatorResult<UploadedImage>> uploadImage(
    OperatorSession s,
    String filePath,
  ) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseAppUrl}$_uploadimage'),
      );
      req.headers['X-Api-Key'] = ApiClient.apiKey;
      req.fields['compid'] = s.compid.toString();
      req.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      log('interia/uploadimage [${streamed.statusCode}]: $body');
      if (streamed.statusCode != 200) {
        return OperatorResult(
          ok: false,
          message: 'Upload failed (${streamed.statusCode})',
        );
      }
      final env = Map<String, dynamic>.from(jsonDecode(body) as Map);
      final d = env['data'];
      return OperatorResult(
        ok: env['success'] == true && d is Map,
        message: (env['message'] ?? '').toString(),
        data: d is Map
            ? UploadedImage.fromJson(Map<String, dynamic>.from(d))
            : null,
      );
    } catch (e) {
      return OperatorResult(ok: false, message: e.toString());
    }
  }
}

// ── Demo fallback ──────────────────────────────────────────────────────────

/// In-memory sample data mirroring the design mockup (Ramesh · Carpentry ·
/// BOQ/2026-27/2). Writes mutate the lists so the flow can be walked end to
/// end: produce → QC → reject/rework → issue to PAINT.
class MockOperatorRepo implements OperatorRepo {
  static final MockOperatorRepo instance = MockOperatorRepo._();
  MockOperatorRepo._();

  @override
  bool get isMock => true;

  static const _stages = [
    NextStage(stageid: 5264, stagename: 'CARPANTRY'),
    NextStage(stageid: 5265, stagename: 'PAINT'),
    NextStage(stageid: 5266, stagename: 'METAL'),
    NextStage(stageid: 5267, stagename: 'UPHOLSTRY'),
    NextStage(stageid: 5268, stagename: 'STONE'),
    NextStage(stageid: 5269, stagename: 'GLASS'),
    NextStage(stageid: 5270, stagename: 'ASSEBMLY'),
  ];

  late final List<OperatorJob> _jobs = [
    _job(
      5,
      'PC/2026-27/5',
      3101,
      '3-Door Sliding Wardrobe with Mirror Panel',
      issued: 1,
      produced: 0,
      qc: 0,
      rej: 0,
      status: 'Issued',
    ),
    _job(
      8,
      'PC/2026-27/8',
      3102,
      '3-Door Sliding Wardrobe',
      issued: 5,
      produced: 3,
      qc: 0,
      rej: 0,
      status: 'In Progress',
    ),
    _job(
      9,
      'PC/2026-27/9',
      3103,
      '4-Door Hinged Wardrobe with Loft',
      issued: 8,
      produced: 3,
      qc: 3,
      rej: 0,
      status: 'In Progress',
    ),
    _job(
      11,
      'PC/2026-27/11',
      3104,
      '3-Seater Sofa with Metal Legs',
      issued: 2,
      produced: 0,
      qc: 0,
      rej: 0,
      status: 'Issued',
    ),
    _job(
      12,
      'PC/2026-27/12',
      3105,
      '6-Seater Dining Table',
      issued: 2,
      produced: 2,
      qc: 2,
      rej: 0,
      status: 'Completed',
    ),
  ];

  /// progress % keyed by job.key
  /// (pct, wipqty) keyed by job.key — sample job 8 has 2 pcs at 60%.
  final Map<String, (double, double)> _progress = {'8/3102/5264': (60, 2)};

  /// qty already issued forward, keyed by job.key
  final Map<String, double> _issuedFwd = {'12/3105/5264': 2};

  final List<Stoppage> _stoppages = [
    Stoppage(
      id: 1,
      type: 'Downtime',
      reason: 'Machine breakdown',
      remarks: 'Blade motor tripped',
      fromtime: '2026-09-19 11:10',
      totime: '2026-09-19 11:55',
      durationmin: 45,
      challanid: 5,
      itemname: '3-Door Sliding Wardrobe with Mirror Panel',
      stagename: 'CARPANTRY',
      imagepath: '',
      createdon: '2026-09-19 11:56',
    ),
    Stoppage(
      id: 2,
      type: 'Bottleneck',
      reason: 'Waiting for material',
      remarks: 'Ply 18mm not received from store',
      fromtime: '2026-09-19 10:30',
      totime: '2026-09-19 11:15',
      durationmin: 45,
      challanid: 8,
      itemname: '3-Door Sliding Wardrobe',
      stagename: 'CARPANTRY',
      imagepath: '',
      createdon: '2026-09-19 12:05',
    ),
  ];

  int _nextId = 100;

  /// Day-wise history, keyed by job.key. Seeded so the log has something to
  /// show for the running sample job.
  final Map<String, List<LedgerEntry>> _ledger = {
    '8/3102/5264': [
      LedgerEntry(
        id: 1,
        entrytype: 'Produce',
        entrydate: '2026-09-18 16:40',
        qty: 2,
        userid: 905007,
        username: 'Ramesh',
        remarks: '',
        disposition: '',
      ),
      LedgerEntry(
        id: 2,
        entrytype: 'Produce',
        entrydate: '2026-09-19 11:20',
        qty: 1,
        userid: 905007,
        username: 'Ramesh',
        remarks: '',
        disposition: '',
      ),
    ],
  };

  void _log(
    OperatorSession s,
    OperatorJob j,
    String type,
    double qty, {
    DateTime? at,
    String remarks = '',
    String disposition = '',
  }) {
    final d = at ?? DateTime.now();
    final stamp =
        DateFormat('yyyy-MM-dd').format(d) +
        (at == null ? DateFormat(' HH:mm').format(d) : ' 00:00');
    (_ledger[j.key] ??= []).add(
      LedgerEntry(
        id: _nextId++,
        entrytype: type,
        entrydate: stamp,
        qty: qty,
        userid: s.userid,
        username: s.name,
        remarks: remarks,
        disposition: disposition,
      ),
    );
  }

  @override
  Future<OperatorResult<List<LedgerEntry>>> entries(
    OperatorSession s,
    OperatorJob job, {
    int? stageid,
  }) async {
    await _lag();
    return OperatorResult(
      ok: true,
      message: 'demo',
      data: List.of(_ledger[job.key] ?? const []),
    );
  }

  static OperatorJob _job(
    int challanid,
    String no,
    int itemid,
    String item, {
    required double issued,
    required double produced,
    required double qc,
    required double rej,
    required String status,
  }) => OperatorJob(
    challanid: challanid,
    challanno: no,
    challandate: '2026-09-18',
    stageid: 5264,
    stagename: 'CARPANTRY',
    itemid: itemid,
    itemname: item,
    boqno: 'BOQ/2026-27/2',
    partyname: 'Rajiv Malhotra',
    orderrefid: 4471,
    issuedqty: issued,
    producedqty: produced,
    qcqty: qc,
    rejectqty: rej,
    balanceqty: issued - produced,
    issuedate: '2026-09-19',
    markerid: 9012,
    status: status,
  );

  Future<void> _lag() => Future.delayed(const Duration(milliseconds: 350));

  OperatorJob? _find(OperatorJob j) =>
      _jobs.where((x) => x.key == j.key).firstOrNull;

  void _refreshStatus(OperatorJob j) {
    j.balanceqty = j.issuedqty - j.producedqty;
    if (j.isDone) {
      j.status = 'Completed';
    } else if (j.isRunning) {
      j.status = j.isRework ? 'Rework · In Progress' : 'In Progress';
    }
  }

  @override
  Future<OperatorResult<List<OperatorJob>>> myJobs(OperatorSession s) async {
    await _lag();
    return OperatorResult(ok: true, message: 'demo', data: List.of(_jobs));
  }

  @override
  Future<OperatorResult<List<JobStageRow>>> jobStages(
    OperatorSession s,
    int challanid,
    int itemid,
  ) async {
    await _lag();
    final j = _jobs.where((x) => x.challanid == challanid).firstOrNull;
    if (j == null) return const OperatorResult(ok: true, message: '', data: []);
    final fwd = _issuedFwd[j.key] ?? 0;
    return OperatorResult(
      ok: true,
      message: '',
      data: [
        JobStageRow(
          stageid: 5264,
          stagename: 'CARPANTRY',
          seq: 1,
          itemqty: j.issuedqty,
          issuedqty: j.issuedqty,
          producedqty: j.producedqty,
          qcqty: j.qcqty,
          rejectqty: j.rejectqty,
          balanceqty: j.balanceqty,
        ),
        JobStageRow(
          stageid: 5265,
          stagename: 'PAINT',
          seq: 2,
          itemqty: j.issuedqty,
          issuedqty: fwd,
          producedqty: 0,
          qcqty: 0,
          rejectqty: 0,
          balanceqty: fwd,
        ),
        for (var i = 0; i < _stages.skip(2).length; i++)
          JobStageRow(
            stageid: _stages.skip(2).elementAt(i).stageid,
            stagename: _stages.skip(2).elementAt(i).stagename,
            seq: 3 + i,
            itemqty: j.issuedqty,
            issuedqty: 0,
            producedqty: 0,
            qcqty: 0,
            rejectqty: 0,
            balanceqty: 0,
          ),
      ],
    );
  }

  @override
  Future<OperatorResult<NextStage>> nextStage(
    OperatorSession s,
    int stageid,
    int challanid, {
    int itemid = 0,
  }) async {
    final i = _stages.indexWhere((x) => x.stageid == stageid);
    if (i < 0 || i + 1 >= _stages.length) {
      return const OperatorResult(
        ok: true,
        message: 'OK',
        data: NextStage(stageid: 0, stagename: ''),
      );
    }
    // The demo route is linear — one destination, owed everything.
    final n = _stages[i + 1];
    return OperatorResult(
      ok: true,
      message: 'OK',
      data: NextStage(
        stageid: n.stageid,
        stagename: n.stagename,
        stages: [
          NextStageOption(
            stageid: n.stageid,
            stagename: n.stagename,
            planqty: 10,
            remainingqty: 10,
            splitmode: 'Full',
          ),
        ],
      ),
    );
  }

  @override
  Future<OperatorResult<List<ProgressRow>>> progressGet(
    OperatorSession s,
    int challanid,
    int itemid,
    int stageid,
  ) async {
    final (pct, wip) = _progress['$challanid/$itemid/$stageid'] ?? (0.0, 0.0);
    return OperatorResult(
      ok: true,
      message: '',
      data: [
        ProgressRow(
          itemid: itemid,
          stageid: stageid,
          stagename: 'CARPANTRY',
          progresspct: pct,
          remarks: '',
          updatedon: '',
          wipqty: wip,
        ),
      ],
    );
  }

  @override
  Future<OperatorResult<List<Stoppage>>> stoppages(
    OperatorSession s, {
    int challanid = 0,
    String type = '',
  }) async {
    await _lag();
    return OperatorResult(
      ok: true,
      message: '',
      data: _stoppages.reversed
          .where((x) => challanid == 0 || x.challanid == challanid)
          .where(
            (x) => type.isEmpty || x.type.toLowerCase() == type.toLowerCase(),
          )
          .toList(),
    );
  }

  @override
  Future<OperatorWriteResult> produce(
    OperatorSession s,
    OperatorJob job,
    double producedqty, {
    int partid = 0,
    int returnid = 0,
    DateTime? entrydate,
    String remarks = '',
  }) async {
    await _lag();
    final j = _find(job);
    if (j == null) return OperatorWriteResult.fail('Job not found.');
    if (producedqty <= 0) return OperatorWriteResult.fail('Qty must be > 0.');
    if (producedqty > j.balanceqty) {
      return OperatorWriteResult.fail(
        'Produced (${fmtQty(producedqty)}) exceeds balance (${fmtQty(j.balanceqty)}).',
      );
    }
    _log(s, j, 'Produce', producedqty, at: entrydate);
    if (j.isRework) {
      // Re-producing a rework lot only burns the rework balance.
      j.balanceqty -= producedqty;
      if (j.balanceqty <= 0) j.status = 'Done';
    } else {
      j.producedqty += producedqty;
      _refreshStatus(j);
    }
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'Produced ${fmtQty(producedqty)}.',
    );
  }

  @override
  Future<OperatorWriteResult> progress(
    OperatorSession s,
    OperatorJob job,
    double pct,
    double wipqty, {
    String remarks = '',
    List<String> imageKeys = const [],
  }) async {
    _progress[job.key] = (pct, wipqty);
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'Progress saved (${pct.toStringAsFixed(0)}%).',
    );
  }

  @override
  Future<OperatorWriteResult> qcPass(
    OperatorSession s,
    OperatorJob job,
    double qcqty, {
    int partid = 0,
    int returnid = 0,
    String remarks = '',
    DateTime? entrydate,
  }) async {
    await _lag();
    final j = _find(job);
    if (j == null) return OperatorWriteResult.fail('Job not found.');
    if (qcqty > j.qcPending) {
      return OperatorWriteResult.fail(
        'QC qty exceeds produced − already QC\'d (${fmtQty(j.qcPending)}).',
      );
    }
    j.qcqty += qcqty;
    _log(s, j, 'QC', qcqty, at: entrydate);
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'QC passed ${fmtQty(qcqty)}.',
    );
  }

  @override
  Future<OperatorWriteResult> qcReject(
    OperatorSession s,
    OperatorJob job,
    double rejectqty, {
    int partid = 0,
    int returnid = 0,
    required String disposition,
    required String reason,
    int faultstageid = 0,
    int faultpartid = 0,
    String remarks = '',
    String imagepath = '',
    DateTime? entrydate,
  }) async {
    await _lag();
    final j = _find(job);
    if (j == null) return OperatorWriteResult.fail('Job not found.');
    if (rejectqty > j.qcPending) {
      return OperatorWriteResult.fail(
        'Reject qty exceeds produced − already QC\'d (${fmtQty(j.qcPending)}).',
      );
    }
    j.rejectqty += rejectqty;
    _log(
      s,
      j,
      'Reject',
      rejectqty,
      at: entrydate,
      remarks: reason,
      disposition: disposition,
    );
    if (disposition == 'Rework') {
      // Backend contract: status "Rework", balanceqty = pieces to redo;
      // producedqty is left as is.
      j.status = 'Rework';
      j.balanceqty += rejectqty;
    } else {
      _refreshStatus(j);
    }
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'Reject ($disposition) recorded.',
    );
  }

  @override
  Future<OperatorResult<List<Consignment>>> incoming(OperatorSession s) async =>
      const OperatorResult(ok: true, message: 'demo', data: []);

  @override
  Future<OperatorWriteResult> receive(
    OperatorSession s,
    Consignment cn, {
    int partid = 0,
    int returnid = 0,
    required String loadername,
    required DateTime receivedAt,
    required double qtyaccepted,
    required double qtyrejected,
    String reason = '',
    List<String> signedReceiptKeys = const [],
    List<String> itemImageKeys = const [],
    String remarks = '',
  }) async => OperatorWriteResult(
    ok: true,
    id: _nextId++,
    message: qtyrejected <= 0
        ? 'Consignment accepted.'
        : 'Rejected ${fmtQty(qtyrejected)} — sent back to be produced again.',
  );

  @override
  Future<OperatorWriteResult> issue(
    OperatorSession s,
    OperatorJob job,
    double issueqty, {
    int partid = 0,
    int returnid = 0,
    NextStage? to,
    String batchno = '',
    GatePass? gatePass,
  }) async {
    await _lag();
    final j = _find(job);
    if (j == null) return OperatorWriteResult.fail('Job not found.');
    final fwd = _issuedFwd[j.key] ?? 0;
    if (issueqty > j.qcqty - fwd) {
      return OperatorWriteResult.fail(
        'Only QC-passed qty can be issued (max ${fmtQty(j.qcqty - fwd)}).',
      );
    }
    final target = (to != null && !to.isLast)
        ? to
        : (await nextStage(s, j.stageid, j.challanid)).data!;
    _issuedFwd[j.key] = fwd + issueqty;
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'Issued ${fmtQty(issueqty)} to ${target.stagename}.',
      tostageid: target.stageid,
      tostagename: target.stagename,
    );
  }

  @override
  Future<OperatorWriteResult> stoppage(
    OperatorSession s, {
    required bool downtime,
    required String reason,
    OperatorJob? job,
    String remarks = '',
    DateTime? from,
    DateTime? to,
    int durationmin = 0,
    DateTime? entrydate,
    String imagepath = '',
  }) async {
    await _lag();
    final f = DateFormat('yyyy-MM-dd HH:mm');
    _stoppages.add(
      Stoppage(
        id: _nextId++,
        type: downtime ? 'Downtime' : 'Bottleneck',
        reason: reason,
        remarks: remarks,
        fromtime: from == null ? '' : f.format(from),
        totime: to == null ? '' : f.format(to),
        durationmin: durationmin,
        challanid: job?.challanid ?? 0,
        itemname: job?.itemname ?? '',
        stagename: job?.stagename ?? '',
        imagepath: imagepath,
        createdon: f.format(DateTime.now()),
      ),
    );
    return OperatorWriteResult(
      ok: true,
      id: _nextId,
      message: downtime ? 'Downtime saved.' : 'Bottleneck saved.',
    );
  }

  @override
  Future<OperatorResult<QcHistory>> qcHistory(
    OperatorSession s, {
    DateTime? from,
    DateTime? to,
    int stageid = 0,
  }) async {
    await _lag();
    final d = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();
    final yest = today.subtract(const Duration(days: 1));
    QcEntry e(
      int id,
      DateTime on,
      String time,
      String item,
      String stage,
      double pass,
      double rej,
    ) => QcEntry(
      id: id,
      qcdate: d.format(on),
      time: time,
      ts: '${d.format(on)} 12:00',
      challanid: 900 + id,
      challanno: '${10 + id}',
      orderrefid: 585241,
      boqno: 'BOQ/2026-27/2',
      partyname: 'Rajiv Malhotra',
      itemid: 585220 + id,
      itemname: item,
      stageid: stage == 'PAINT' ? 5265 : 5264,
      stagename: stage,
      qcqty: pass,
      rejectqty: rej,
      result: rej > 0 ? (pass > 0 ? 'Partial' : 'Rejected') : 'Passed',
      tone: rej > 0 ? (pass > 0 ? 'amber' : 'red') : 'green',
      disposition: rej > 0 ? 'Rework' : '',
      reason: rej > 0 ? 'Finish defect' : '',
      remarks: rej > 0 ? 'Patchy top coat on two panels.' : '',
      producedby: stage == 'PAINT' ? 'Vinod Painter' : 'Ramesh Vishwakarma',
      photos: const [],
    );
    final days = [
      QcDay(
        qcdate: d.format(today),
        daylabel: 'Today · ${DateFormat('d MMM yyyy').format(today)}',
        passedqty: 4,
        rejectedqty: 1,
        entries: [
          e(1, today, '04:20 PM', 'Accent Lounge Chair', 'PAINT', 3, 0),
          e(2, today, '11:05 AM', '4-Door Hinged Wardrobe', 'CARPANTRY', 1, 1),
        ],
      ),
      QcDay(
        qcdate: d.format(yest),
        daylabel: 'Yesterday · ${DateFormat('d MMM yyyy').format(yest)}',
        passedqty: 2,
        rejectedqty: 1,
        entries: [
          e(3, yest, '06:30 PM', '3-Door Sliding Wardrobe', 'PAINT', 2, 0),
          e(4, yest, '02:10 PM', '6-Seater Dining Table', 'CARPANTRY', 0, 1),
        ],
      ),
    ];
    return OperatorResult(
      ok: true,
      message: 'demo',
      data: QcHistory(
        summary: QcSummary(
          fromdate: d.format(from ?? today.subtract(const Duration(days: 30))),
          todate: d.format(to ?? today),
          entries: 4,
          lots: 4,
          passedqty: 6,
          rejectedqty: 2,
          reworkqty: 2,
          scrapqty: 0,
          passrate: 75,
        ),
        stages: const [
          QcStageOption(5264, 'CARPANTRY'),
          QcStageOption(5265, 'PAINT'),
        ],
        days: days,
      ),
    );
  }

  @override
  Future<OperatorResult<JobDesign>> jobDesign(
    OperatorSession s,
    int orderrefid,
    int itemid,
  ) async {
    await _lag();
    return const OperatorResult(ok: true, message: 'demo', data: JobDesign());
  }

  @override
  Future<OperatorResult<SendBackOptions>> sendBackOptions(
    OperatorSession s, {
    required int challanid,
    required int stageid,
    int partid = 0,
  }) async {
    await _lag();
    return const OperatorResult(
      ok: true,
      message: 'Nothing here can be sent back.',
      data: SendBackOptions(),
    );
  }

  @override
  Future<OperatorWriteResult> sendBack(
    OperatorSession s, {
    required int challanid,
    required int stageid,
    required int partid,
    required double qty,
    required int fixstageid,
    required String reason,
    int worked = 0,
    List<int> redostageids = const [],
    int faultstageid = 0,
    List<String> imageKeys = const [],
    GatePass? gatePass,
  }) async {
    await _lag();
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: '${fmtQty(qty)} sent back.',
    );
  }

  @override
  Future<OperatorResult<ChallanReturns>> challanReturns(
    OperatorSession s, {
    required int challanid,
    int itemid = 0,
  }) async {
    await _lag();
    return const OperatorResult(
      ok: true,
      message: 'demo',
      data: ChallanReturns(),
    );
  }

  @override
  Future<OperatorResult<PackJob>> packJob(
    OperatorSession s, {
    required int challanid,
    required int itemid,
  }) async {
    await _lag();
    return const OperatorResult(ok: true, message: 'demo', data: PackJob());
  }

  @override
  Future<OperatorWriteResult> packSave(
    OperatorSession s, {
    required int challanid,
    required int itemid,
    required double qty,
    required List<Map<String, dynamic>> boxes,
    required String clienttoken,
    DateTime? entrydate,
  }) async {
    await _lag();
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'Packed ${fmtQty(qty)} in ${boxes.length} box(es).',
    );
  }

  @override
  Future<OperatorWriteResult> packRemove(
    OperatorSession s, {
    required int packid,
  }) async {
    await _lag();
    return OperatorWriteResult(ok: true, id: packid, message: 'Pack removed.');
  }

  @override
  Future<OperatorWriteResult> qcRejectSendBack(
    OperatorSession s,
    OperatorJob job, {
    required double rejectqty,
    required int fixstageid,
    required String reason,
    int partid = 0,
    int sendbackpartid = 0,
    double sendbackqty = 0,
    List<int> redostageids = const [],
    int faultstageid = 0,
    String remarks = '',
    List<String> imageKeys = const [],
    GatePass? gatePass,
  }) async {
    await _lag();
    return OperatorWriteResult(
      ok: true,
      id: _nextId++,
      message: 'Rejected ${fmtQty(rejectqty)} and sent back.',
    );
  }

  @override
  Future<OperatorResult<UploadedImage>> uploadImage(
    OperatorSession s,
    String filePath,
  ) async {
    await _lag();
    final name = filePath.split(RegExp(r'[\\/]')).last;
    return OperatorResult(
      ok: true,
      message: 'demo',
      data: UploadedImage(
        filepath: '${s.compid}/operator/demo_$name',
        filename: name,
        url: filePath,
      ),
    );
  }
}
