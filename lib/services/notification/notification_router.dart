import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/response/all_visit_data_response.dart';

/// Opens the right screen when a notification is tapped.
///
/// The backend labels every push with a module and a record id:
///
///     data: { "module": "task", "id": "41" }
///
/// This table turns that label into a screen. Adding notifications for another
/// module is then a BACKEND-only change — as long as the module already has an
/// entry below, no new app build is needed.
///
/// Two kinds of entry:
///  * `detail`  — the module's detail screen can open from an id alone.
///  * `listOnly`— it can't (the screen is driven by its list), so we open the
///                module's list instead. The user still lands in the right
///                place; they just pick the record.
///
/// Unknown module, or no id where one is required, falls back to the list —
/// and if there is no entry at all, nothing happens. Never throws: a bad
/// payload must not crash the app on a notification tap.
class NotificationRouter {
  const NotificationRouter._();

  static final Map<String, _Target> _targets = {
    // ── open the exact record ──
    'task': _Target.detail(
      route: AppRoutes.taskDetail,
      args: (id) => {'taskid': id},
      listRoute: AppRoutes.taskManagement,
    ),
    'visit': _Target.detail(
      route: AppRoutes.visitPlanDetail,
      // This screen reads its argument as a VisitListData and uses `.visitid`.
      args: (id) => VisitListData(visitid: id),
      listRoute: AppRoutes.visitPlan,
    ),

    // ── land on the module's list ──
    // These detail screens are opened by their list (they read state the list
    // sets, not Get.arguments), so an id alone can't open them. Routing to the
    // list is honest and still useful. To upgrade one, give its detail screen
    // an id-based entry point and move it to _Target.detail above.
    'approval': _Target.listOnly(AppRoutes.approvalHub),
    // Leave approval lives inside the Approval Hub (the Leave Requests card),
    // and ManagerLeaveHistoryView has no named route — the hub is the honest
    // landing spot, and its card carries the pending badge.
    'leave': _Target.listOnly(AppRoutes.approvalHub),
    'reimbursement': _Target.listOnly(AppRoutes.reimbursement),
    'payment': _Target.listOnly(AppRoutes.paymentRequestListScreen),
    'mrn': _Target.listOnly(AppRoutes.mrnScreen),
    'grn': _Target.listOnly(AppRoutes.grnScreen),
    'indent': _Target.listOnly(AppRoutes.indentList),
    'purchaseorder': _Target.listOnly(AppRoutes.purchaseOrder),
    'saleorder': _Target.listOnly(AppRoutes.performaInvoice),
    'lead': _Target.listOnly(AppRoutes.leadManagement),

    // ── INTERIA shop floor ──
    // Every shop-floor push lands on My Jobs, which opens on the operator's
    // own stage: the job, the QC queue and the send back rows are all there,
    // and each is only reachable once its list has loaded, so an id alone
    // cannot open one. `challanid` is still sent — it is what the operator
    // matches the notification against, and it is what a future detail
    // entry point would use.
    'myjobs': _Target.listOnly(AppRoutes.productionOperator),
    'qc': _Target.listOnly(AppRoutes.productionOperator),
    'sendback': _Target.listOnly(AppRoutes.productionOperator),
    'ordertracking': _Target.listOnly(AppRoutes.orderTracking),
    'attendance': _Target.listOnly(AppRoutes.attendance),
  };

  /// Modules the current build understands. Handy for logging/diagnostics.
  static Iterable<String> get knownModules => _targets.keys;

  /// Route a tapped notification.
  ///
  /// [module] is the backend's label ("task", "visit", …) — matched
  /// case-insensitively, so "Task" and "TASK" both work.
  static void open({String? module, int id = 0}) {
    final key = (module ?? '').trim().toLowerCase();
    if (key.isEmpty) return;

    final target = _targets[key];
    if (target == null) {
      // Newer backend module than this APK knows about. The notification text
      // was still shown; there is simply nowhere specific to go.
      return;
    }

    try {
      if (target.detailRoute != null && id > 0 && target.args != null) {
        Get.toNamed(target.detailRoute!, arguments: target.args!(id));
        return;
      }
      if (target.listRoute != null) Get.toNamed(target.listRoute!);
    } catch (_) {
      // A navigation failure must never take the app down from a tap.
    }
  }

  /// Parses the legacy payloads the app already used before modules existed:
  /// a bare task id ("41") or "visit:16". Returns null if it isn't one.
  static ({String module, int id})? legacyPayload(String? payload) {
    final raw = (payload ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('visit:')) {
      return (module: 'visit', id: int.tryParse(raw.substring(6)) ?? 0);
    }
    if (raw.startsWith('leave:')) {
      return (module: 'leave', id: int.tryParse(raw.substring(6)) ?? 0);
    }
    final id = int.tryParse(raw);
    return id == null ? null : (module: 'task', id: id);
  }
}

typedef _ArgsBuilder = dynamic Function(int id);

class _Target {
  final String? detailRoute;
  final _ArgsBuilder? args;
  final String? listRoute;

  const _Target._({this.detailRoute, this.args, this.listRoute});

  /// The detail screen can open from an id; [listRoute] is the fallback when
  /// the push arrives without one.
  factory _Target.detail({
    required String route,
    required _ArgsBuilder args,
    String? listRoute,
  }) =>
      _Target._(detailRoute: route, args: args, listRoute: listRoute);

  /// Only the module's list can be opened.
  factory _Target.listOnly(String route) => _Target._(listRoute: route);
}
