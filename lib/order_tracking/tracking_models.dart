// Order Production Tracking — data model.
//
// Five read-only endpoints (`interia/track/*`) return the same data as the web
// page /Interia/Production/OrderTracking (menu 2391):
//   kpis    → the five cards
//   orders  → order picker
//   items   → item picker (an item is challanid + itemid, always sent together)
//   detail  → everything for one item: summary, pipeline, stage completion,
//             who-did-what, filter lists and the activity trail
//   export  → the trail as CSV (raw file, not the JSON envelope)
//
// The API already sends ready-to-show labels (`eventlabel`, `statelabel`,
// `daylabel`) and colour keys (`tone`, `state`) — the app only maps those to
// colours, it never re-derives the wording.

double _dbl(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _int(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
String _str(dynamic v) => (v ?? '').toString();
List<String> _strs(dynamic v) => v is List
    ? v.map((e) => '$e'.trim()).where((s) => s.isNotEmpty).toList()
    : const [];

/// The five KPI cards (`track/kpis`).
class TrackKpis {
  final int ordersInProd;
  final int itemsInProgress;
  final int entriesToday;

  /// null → show "—" (no QC recorded yet).
  final double? qcPassRate;
  final int overdueOrders;

  const TrackKpis({
    this.ordersInProd = 0,
    this.itemsInProgress = 0,
    this.entriesToday = 0,
    this.qcPassRate,
    this.overdueOrders = 0,
  });

  factory TrackKpis.fromJson(Map<String, dynamic> j) => TrackKpis(
    ordersInProd: _int(j['orders_in_prod']),
    itemsInProgress: _int(j['items_in_progress']),
    entriesToday: _int(j['entries_today']),
    qcPassRate: j['qc_pass_rate'] == null ? null : _dbl(j['qc_pass_rate']),
    overdueOrders: _int(j['overdue_orders']),
  );
}

/// One order in production (`track/orders`).
class TrackOrder {
  final int orderid;
  final String orderno;
  final String partyname;
  final String orderdate;
  final String deliverydate;
  final int items;
  final double produced;
  final double ordered;

  const TrackOrder({
    required this.orderid,
    required this.orderno,
    required this.partyname,
    required this.orderdate,
    required this.deliverydate,
    required this.items,
    required this.produced,
    required this.ordered,
  });

  factory TrackOrder.fromJson(Map<String, dynamic> j) => TrackOrder(
    orderid: _int(j['orderid']),
    orderno: _str(j['orderno']),
    partyname: _str(j['partyname']),
    orderdate: _str(j['orderdate']),
    deliverydate: _str(j['deliverydate']),
    items: _int(j['items']),
    produced: _dbl(j['produced']),
    ordered: _dbl(j['ordered']),
  );

  double get fraction =>
      ordered <= 0 ? 0 : (produced / ordered).clamp(0, 1).toDouble();

  /// Past the delivery date and not finished — the red "Overdue" pill.
  bool get overdue {
    final d = _parseDisplayDate(deliverydate);
    if (d == null) return false;
    final today = DateTime.now();
    return d.isBefore(DateTime(today.year, today.month, today.day)) &&
        produced < ordered;
  }

  /// "18 Sep 2026" → DateTime. The API sends display text, not ISO.
  static DateTime? _parseDisplayDate(String s) {
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final p = s.trim().split(RegExp(r'\s+'));
    if (p.length < 3) return null;
    final d = int.tryParse(p[0]);
    final m =
        months[p[1].toLowerCase().substring(
          0,
          p[1].length < 3 ? p[1].length : 3,
        )];
    final y = int.tryParse(p[2]);
    return (d == null || m == null || y == null) ? null : DateTime(y, m, d);
  }
}

/// One item of an order (`track/items`). Identified by challanid + itemid.
class TrackItem {
  final int challanid;
  final int itemid;
  final String itemname;
  final String itemcode;
  final double produced;
  final double qcd;
  final double rejected;
  final double ordered;

  const TrackItem({
    required this.challanid,
    required this.itemid,
    required this.itemname,
    required this.itemcode,
    required this.produced,
    required this.qcd,
    required this.rejected,
    required this.ordered,
  });

  factory TrackItem.fromJson(Map<String, dynamic> j) => TrackItem(
    challanid: _int(j['challanid']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    itemcode: _str(j['itemcode']),
    produced: _dbl(j['produced']),
    qcd: _dbl(j['qcd']),
    rejected: _dbl(j['rejected']),
    ordered: _dbl(j['ordered']),
  );

  String get key => '$challanid/$itemid';
}

/// Header of the % ring: "Ordered 1 · Output 0 · QC 0 · 7 stages".
class TrackSummary {
  final double ordered;
  final double output;
  final double qc;
  final int stages;
  final int completionpct;
  final String text;

  const TrackSummary({
    this.ordered = 0,
    this.output = 0,
    this.qc = 0,
    this.stages = 0,
    this.completionpct = 0,
    this.text = '',
  });

  factory TrackSummary.fromJson(Map<String, dynamic> j) => TrackSummary(
    ordered: _dbl(j['ordered']),
    output: _dbl(j['output']),
    qc: _dbl(j['qc']),
    stages: _int(j['stages']),
    completionpct: _int(j['completionpct']),
    text: _str(j['text']),
  );
}

/// One step of the stage pipeline, in planned order.
class PipelineStage {
  final int step;
  final int stageid;
  final String stagename;

  /// Last operator at the stage — empty means show "—".
  final String operatorname;
  final double itemqty;

  /// Raw produced qty — information only. Anything rejected here (by QC, or
  /// sent back by the next stage) does NOT count as done, so the screen shows
  /// [good] instead.
  final double produced;

  /// produced − rejected. This is the stage's real output.
  final double good;

  /// Still to be re-made at this stage (0 = nothing).
  final double rework;
  final double qcd;
  final double reject;
  final double received;

  /// done | rework | active | pending (+ its ready label).
  final String state;
  final String statelabel;

  /// good / itemqty, capped at 100.
  final int completionpct;

  // ── Parallel route (live 2026-09-28). All empty / 0 on a linear challan,
  // so the screen keeps its old shape without special-casing anything. ──

  /// 0-based step. Stages sharing a column run side by side.
  final int column;

  /// Stage ids this one waits for, and their names joined by " + ".
  final List<int> dependson;
  final String waitsfor;

  /// Next stage names joined by " + ". Empty on the last stage.
  final String nextstages;

  /// Ready to show: "After GLASS + PAINT" or "Starts on challan date".
  final String startslabel;

  /// Planned dates, yyyy-MM-dd.
  final String startdate;
  final String targetdate;

  /// Past its target date and not finished.
  final bool overdue;

  /// All (every part must arrive) | Sum (shared qty joining again).
  final String joinmode;

  /// Full | Share — see [NextStageOption] on the operator side.
  final String splitmode;

  /// Joining stage: what it can build from the parts already in hand.
  final double canmake;

  /// Joining stage only (2+ entries), one per earlier stage.
  final List<StagePart> parts;

  /// Parts made at, or arriving into, this stage (live 2026-09-29).
  final List<StageSubItem> subitems;

  const PipelineStage({
    required this.step,
    required this.stageid,
    required this.stagename,
    required this.operatorname,
    required this.itemqty,
    required this.produced,
    required this.qcd,
    required this.reject,
    required this.received,
    required this.state,
    required this.statelabel,
    required this.completionpct,
    this.good = 0,
    this.rework = 0,
    this.column = 0,
    this.dependson = const [],
    this.waitsfor = '',
    this.nextstages = '',
    this.startslabel = '',
    this.startdate = '',
    this.targetdate = '',
    this.overdue = false,
    this.joinmode = '',
    this.splitmode = '',
    this.canmake = 0,
    this.parts = const [],
    this.subitems = const [],
  });

  factory PipelineStage.fromJson(Map<String, dynamic> j) => PipelineStage(
    step: _int(j['step']),
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    operatorname: _str(j['operatorname']),
    itemqty: _dbl(j['itemqty']),
    produced: _dbl(j['produced']),
    // Older builds sent no `good` — fall back to produced − reject.
    good: j['good'] != null
        ? _dbl(j['good'])
        : (_dbl(j['produced']) - _dbl(j['reject']))
              .clamp(0, double.infinity)
              .toDouble(),
    rework: _dbl(j['rework']),
    qcd: _dbl(j['qcd']),
    reject: _dbl(j['reject']),
    received: _dbl(j['received']),
    state: _str(j['state']),
    statelabel: _str(j['statelabel']),
    completionpct: _int(j['completionpct']),
    // An old build sends no column — step − 1 keeps every stage in its own
    // group, which draws as today's plain stepper.
    column: j['column'] != null ? _int(j['column']) : _int(j['step']) - 1,
    dependson: j['dependson'] is List
        ? (j['dependson'] as List).map(_int).where((e) => e > 0).toList()
        : const [],
    waitsfor: _str(j['waitsfor']),
    nextstages: _str(j['nextstages']),
    startslabel: _str(j['startslabel']),
    startdate: _str(j['startdate']),
    targetdate: _str(j['targetdate']),
    overdue: j['overdue'] == true,
    joinmode: _str(j['joinmode']),
    splitmode: _str(j['splitmode']),
    canmake: _dbl(j['canmake']),
    parts: j['parts'] is List
        ? (j['parts'] as List)
              .whereType<Map>()
              .map((e) => StagePart.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
    subitems: j['subitems'] is List
        ? (j['subitems'] as List)
              .whereType<Map>()
              .map((e) => StageSubItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );

  /// A stage is finished ONLY when the server says `done` — work waiting to
  /// be re-made keeps it out of that state however much was produced.
  bool get isDone => state == 'done';
  bool get isActive => state == 'active';
  bool get isRework => state == 'rework';

  /// A joining stage that cannot start: some parts have not arrived.
  bool get isWaiting => state == 'waiting';

  /// "Due 06 Oct" / "Overdue · 06 Oct" — empty when the plan has no date.
  String get dueLabel {
    if (targetdate.isEmpty) return '';
    final d = DateTime.tryParse(targetdate);
    final when = d == null
        ? targetdate
        : '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]}';
    return overdue ? 'Overdue · $when' : 'Due $when';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "0 / 1 · QC 2 · Rej 1" — good against planned, then the extras.
  String get qtyLabel {
    final n = StringBuffer('${_n(good)} / ${_n(itemqty)}');
    if (qcd > 0) n.write(' · QC ${_n(qcd)}');
    if (reject > 0) n.write(' · Rej ${_n(reject)}');
    return n.toString();
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

/// One bar in "Stage completion".
class StageCompletion {
  final String stagename;
  final int completionpct;

  /// green | violet | amber — the API decides, the app only colours it.
  final String tone;

  const StageCompletion({
    required this.stagename,
    required this.completionpct,
    required this.tone,
  });

  factory StageCompletion.fromJson(Map<String, dynamic> j) => StageCompletion(
    stagename: _str(j['stagename']),
    completionpct: _int(j['completionpct']),
    tone: _str(j['tone']),
  );
}

/// One row of "Who did what".
class PersonWork {
  final String person;
  final String initials;
  final String stagename;
  final double produced;
  final double qc;
  final double rejected;

  const PersonWork({
    required this.person,
    required this.initials,
    required this.stagename,
    required this.produced,
    required this.qc,
    required this.rejected,
  });

  factory PersonWork.fromJson(Map<String, dynamic> j) => PersonWork(
    person: _str(j['person']),
    initials: _str(j['initials']),
    stagename: _str(j['stagename']),
    produced: _dbl(j['produced']),
    qc: _dbl(j['qc']),
    rejected: _dbl(j['rejected']),
  );
}

/// One event in the activity trail.
class TrailEntry {
  /// Produced | QC | Rejected | Issued | IssuedLoader | ReceivedLoader |
  /// RejectedLoader | Progress — an unknown code still arrives with a usable
  /// [eventlabel] and tone "gray".
  final String eventtype;
  final String eventlabel;
  final String tone;
  final String stagename;
  final String fromstage;

  /// Ready text for a hand-off, e.g. "→ METAL" / "← PAINT"; empty otherwise.
  final String flow;
  final double qty;

  /// "pcs", or "%" on a Progress event.
  final String unit;
  final String operator;
  final String initials;
  final String remarks;
  final String loadername;
  final String daydate;
  final String ts;
  final String time;

  /// Presigned S3 URLs — they expire after 6 hours, so never cache them.
  final List<String> photos;

  const TrailEntry({
    required this.eventtype,
    required this.eventlabel,
    required this.tone,
    required this.stagename,
    required this.fromstage,
    required this.flow,
    required this.qty,
    required this.unit,
    required this.operator,
    required this.initials,
    required this.remarks,
    required this.loadername,
    required this.daydate,
    required this.ts,
    required this.time,
    required this.photos,
  });

  factory TrailEntry.fromJson(Map<String, dynamic> j) => TrailEntry(
    eventtype: _str(j['eventtype']),
    eventlabel: _str(j['eventlabel']),
    tone: _str(j['tone']),
    stagename: _str(j['stagename']),
    fromstage: _str(j['fromstage']),
    flow: _str(j['flow']),
    qty: _dbl(j['qty']),
    unit: _str(j['unit']),
    operator: _str(j['operator']),
    initials: _str(j['initials']),
    remarks: _str(j['remarks']),
    loadername: _str(j['loadername']),
    daydate: _str(j['daydate']),
    ts: _str(j['ts']),
    time: _str(j['time']),
    photos: _strs(j['photos']),
  );

  /// "1 pcs" / "100%" — the qty pill.
  String get qtyLabel {
    final n = qty == qty.roundToDouble()
        ? qty.toStringAsFixed(0)
        : qty.toStringAsFixed(2);
    return unit == '%' ? '$n%' : '$n $unit';
  }
}

/// A day group of the timeline view.
class TrailDay {
  final String daydate;

  /// Already worded by the server: "Today · …" / "Yesterday · …".
  final String daylabel;
  final int count;
  final List<TrailEntry> entries;

  const TrailDay({
    required this.daydate,
    required this.daylabel,
    required this.count,
    required this.entries,
  });

  factory TrailDay.fromJson(Map<String, dynamic> j) => TrailDay(
    daydate: _str(j['daydate']),
    daylabel: _str(j['daylabel']),
    count: _int(j['count']),
    entries: (j['entries'] is List)
        ? (j['entries'] as List)
              .whereType<Map>()
              .map((e) => TrailEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );
}

/// Everything `track/detail` returns for one item.
class TrackDetail {
  final int orderid;
  final int challanid;
  final int itemid;
  final String itemname;
  final String itemcode;
  final TrackSummary summary;
  final List<PipelineStage> pipeline;
  final List<StageCompletion> stagecompletion;
  final List<PersonWork> whodidwhat;
  final List<String> stages;
  final List<String> persons;
  final int trailcount;
  final List<TrailDay> trail;
  final List<TrailEntry> trailflat;

  /// How the challan is routed. [TrackRoute.branched] is the switch that
  /// decides whether the pipeline is grouped into steps or drawn as the
  /// plain vertical stepper it has always been.
  final TrackRoute route;

  /// One ready-made sentence per joining stage that is short of parts, e.g.
  /// "ASSEBMLY is waiting for GLASS (QC-passed 1, not sent yet)."
  final List<String> waitnotes;

  /// One row per part, with a cell per pipeline stage. Empty on a challan
  /// planned without parts.
  final List<SubItemGridRow> subitemgrid;

  const TrackDetail({
    this.orderid = 0,
    this.challanid = 0,
    this.itemid = 0,
    this.itemname = '',
    this.itemcode = '',
    this.summary = const TrackSummary(),
    this.pipeline = const [],
    this.stagecompletion = const [],
    this.whodidwhat = const [],
    this.stages = const [],
    this.persons = const [],
    this.trailcount = 0,
    this.trail = const [],
    this.trailflat = const [],
    this.route = const TrackRoute(),
    this.waitnotes = const [],
    this.subitemgrid = const [],
  });

  factory TrackDetail.fromJson(Map<String, dynamic> j) {
    final order = j['order'] is Map
        ? Map<String, dynamic>.from(j['order'])
        : <String, dynamic>{};
    final filters = j['filters'] is Map
        ? Map<String, dynamic>.from(j['filters'])
        : <String, dynamic>{};
    List<T> list<T>(dynamic v, T Function(Map<String, dynamic>) f) => v is List
        ? v
              .whereType<Map>()
              .map((e) => f(Map<String, dynamic>.from(e)))
              .toList()
        : <T>[];
    return TrackDetail(
      orderid: _int(order['orderid']),
      challanid: _int(order['challanid']),
      itemid: _int(order['itemid']),
      itemname: _str(order['itemname']),
      itemcode: _str(order['itemcode']),
      summary: j['summary'] is Map
          ? TrackSummary.fromJson(Map<String, dynamic>.from(j['summary']))
          : const TrackSummary(),
      pipeline: list(j['pipeline'], PipelineStage.fromJson),
      stagecompletion: list(j['stagecompletion'], StageCompletion.fromJson),
      whodidwhat: list(j['whodidwhat'], PersonWork.fromJson),
      stages: _strs(filters['stages']),
      persons: _strs(filters['persons']),
      trailcount: _int(j['trailcount']),
      trail: list(j['trail'], TrailDay.fromJson),
      trailflat: list(j['trailflat'], TrailEntry.fromJson),
      route: j['route'] is Map
          ? TrackRoute.fromJson(Map<String, dynamic>.from(j['route']))
          : const TrackRoute(),
      subitemgrid: j['subitemgrid'] is List
          ? (j['subitemgrid'] as List)
                .whereType<Map>()
                .map(
                  (e) => SubItemGridRow.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      waitnotes: j['waitnotes'] is List
          ? (j['waitnotes'] as List)
                .map((e) => _str(e))
                .where((e) => e.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

/// How this challan is routed (`track/detail.route`).
class TrackRoute {
  /// 1 when the challan was planned with "Waits for". 0 on old challans.
  final int isroute;

  /// **The switch for the layout.** True when stages run side by side — a
  /// split, a join, or a second start stage. False draws the old stepper.
  final bool branched;

  /// Number of steps when branched, number of stages otherwise.
  final int columns;

  /// stage id → stage id, with whether the earlier one has finished. Only
  /// needed to draw connecting lines, which the phone layout does without.
  final List<RouteEdge> edges;

  const TrackRoute({
    this.isroute = 0,
    this.branched = false,
    this.columns = 0,
    this.edges = const [],
  });

  factory TrackRoute.fromJson(Map<String, dynamic> j) => TrackRoute(
    isroute: _int(j['isroute']),
    branched: j['branched'] == true,
    columns: _int(j['columns']),
    edges: j['edges'] is List
        ? (j['edges'] as List)
              .whereType<Map>()
              .map((e) => RouteEdge.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const [],
  );
}

class RouteEdge {
  final int from;
  final int to;
  final bool done;
  const RouteEdge({this.from = 0, this.to = 0, this.done = false});

  factory RouteEdge.fromJson(Map<String, dynamic> j) => RouteEdge(
    from: _int(j['from']),
    to: _int(j['to']),
    done: j['done'] == true,
  );
}

/// One earlier stage a joining stage is waiting on (`pipeline[].parts[]`).
class StagePart {
  final String stagename;
  final double received;
  final double intransit;
  final double made;
  final double qc;

  /// received | intransit | notsent | waitingqc | notmade.
  final String state;

  /// Ready to show — "received 1", "QC-passed 1, not sent yet", …
  /// The server writes it, so the app never builds this sentence itself.
  final String text;

  /// green | blue | amber | gray.
  final String tone;

  /// This part is what is holding the stage up.
  final bool waitingfor;

  const StagePart({
    this.stagename = '',
    this.received = 0,
    this.intransit = 0,
    this.made = 0,
    this.qc = 0,
    this.state = '',
    this.text = '',
    this.tone = '',
    this.waitingfor = false,
  });

  factory StagePart.fromJson(Map<String, dynamic> j) => StagePart(
    stagename: _str(j['stagename']),
    received: _dbl(j['received']),
    intransit: _dbl(j['intransit']),
    made: _dbl(j['made']),
    qc: _dbl(j['qc']),
    state: _str(j['state']),
    text: _str(j['text']),
    tone: _str(j['tone']),
    waitingfor: j['waitingfor'] == true,
  );
}

/// Envelope of a read call.
class TrackResult<T> {
  final bool ok;
  final String message;
  final T? data;
  const TrackResult({required this.ok, required this.message, this.data});
}

/// A downtime / bottleneck event (`interia/stoppages`). Not part of the
/// `track/*` set — the operator app logs these and the supervisor needs to
/// see them, so the tracking screen reads the same endpoint.
class TrackStoppage {
  final int id;

  /// "Downtime" (line stopped) or "Bottleneck" (running slow / blocked).
  final String stype;
  final int challanid;
  final int itemid;
  final String itemname;
  final int stageid;
  final String stagename;
  final String reason;
  final String remarks;
  final String fromtime;
  final String totime;
  final int durationmin;
  final String imagepath;
  final String entrydate;
  final String createdon;

  const TrackStoppage({
    required this.id,
    required this.stype,
    required this.challanid,
    required this.itemid,
    required this.itemname,
    required this.stageid,
    required this.stagename,
    required this.reason,
    required this.remarks,
    required this.fromtime,
    required this.totime,
    required this.durationmin,
    required this.imagepath,
    required this.entrydate,
    required this.createdon,
  });

  factory TrackStoppage.fromJson(Map<String, dynamic> j) => TrackStoppage(
    id: _int(j['Id'] ?? j['id']),
    stype: _str(j['stype'] ?? j['type']),
    challanid: _int(j['challanid']),
    itemid: _int(j['itemid']),
    itemname: _str(j['itemname']),
    stageid: _int(j['stageid']),
    stagename: _str(j['stagename']),
    reason: _str(j['reason']),
    remarks: _str(j['remarks']),
    fromtime: _str(j['fromtime']),
    totime: _str(j['totime']),
    durationmin: _int(j['durationmin']),
    imagepath: _str(j['imagepath']),
    entrydate: _str(j['entrydate']),
    createdon: _str(j['createdon']),
  );

  /// No end time yet → the line is still stopped right now.
  bool get isOngoing => totime.trim().isEmpty;

  bool get isDowntime => stype.toLowerCase().startsWith('down');

  /// Red for a stopped line, amber for a bottleneck.
  String get tone => isDowntime ? 'red' : 'amber';

  /// "1 h 58 m" / "45 m" — blank while it is still running.
  String get durationLabel {
    if (durationmin <= 0) return '';
    final h = durationmin ~/ 60, m = durationmin % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  /// The day it belongs to, for grouping with the trail.
  String get daydate => entrydate.length >= 10
      ? entrydate.substring(0, 10)
      : (fromtime.length >= 10 ? fromtime.substring(0, 10) : entrydate);

  /// "12:02" out of "2026-09-21 12:02".
  String get startTime =>
      fromtime.length >= 16 ? fromtime.substring(11, 16) : '';
}

/// One part at one stage (`pipeline[].subitems[]`, and every non-null cell of
/// [SubItemGridRow]). Phase 1 is display only — `text` and `tone` are written
/// by the server so the wording matches the operator app.
class StageSubItem {
  final int partid;

  /// `made` = made at this stage, `in` = arrives from [fromstage].
  final String kind;
  final String partname;
  final double qtyperpiece;
  final double totalqty;
  final String fromstage;
  final String nextstage;
  final String path;

  /// How many are actually here / done.
  final double qty;

  /// Ready to show: "Made 4 / 8", "Received 1 / 1", "Waiting", "Not made yet".
  final String text;

  /// green | blue | amber | gray.
  final String tone;

  const StageSubItem({
    this.partid = 0,
    this.kind = '',
    this.partname = '',
    this.qtyperpiece = 0,
    this.totalqty = 0,
    this.fromstage = '',
    this.nextstage = '',
    this.path = '',
    this.qty = 0,
    this.text = '',
    this.tone = '',
  });

  factory StageSubItem.fromJson(Map<String, dynamic> j) => StageSubItem(
    partid: _int(j['partid']),
    kind: _str(j['kind']),
    partname: _str(j['partname']),
    qtyperpiece: _dbl(j['qtyperpiece']),
    totalqty: _dbl(j['totalqty']),
    fromstage: _str(j['fromstage']),
    nextstage: _str(j['nextstage']),
    path: _str(j['path']),
    qty: _dbl(j['qty']),
    text: _str(j['text']),
    tone: _str(j['tone']),
  );
}

/// One row of `subitemgrid`: a part, and where it has got to at each stage.
/// [cells] lines up with `pipeline` in the same order; a null cell means the
/// part does not pass that stage and is drawn as "—".
class SubItemGridRow {
  final String partname;
  final double qtyperpiece;
  final double totalqty;
  final String path;

  /// The stage that makes it.
  final String madeat;
  final List<StageSubItem?> cells;

  const SubItemGridRow({
    this.partname = '',
    this.qtyperpiece = 0,
    this.totalqty = 0,
    this.path = '',
    this.madeat = '',
    this.cells = const [],
  });

  factory SubItemGridRow.fromJson(Map<String, dynamic> j) => SubItemGridRow(
    partname: _str(j['partname']),
    qtyperpiece: _dbl(j['qtyperpiece']),
    totalqty: _dbl(j['totalqty']),
    path: _str(j['path']),
    madeat: _str(j['madeat']),
    cells: j['cells'] is List
        ? (j['cells'] as List)
              .map(
                (e) => e is Map
                    ? StageSubItem.fromJson(Map<String, dynamic>.from(e))
                    : null,
              )
              .toList()
        : const [],
  );

  /// Only the stages this part actually passes through, paired with their
  /// name — the phone shows these as lines instead of a wide grid.
  List<(String, StageSubItem)> steps(List<String> stagenames) => [
    for (var i = 0; i < cells.length && i < stagenames.length; i++)
      if (cells[i] != null) (stagenames[i], cells[i]!),
  ];
}
