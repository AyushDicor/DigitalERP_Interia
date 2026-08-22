import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/repo/visit_entry_repo.dart';
import 'package:newdigitalerp/services/notification/notification_router.dart';
import 'package:newdigitalerp/response/all_visit_data_response.dart';
import 'package:newdigitalerp/screen/auth/login/login_model.dart';
import 'package:newdigitalerp/services/api_service/api.dart';
import 'package:newdigitalerp/utils/shared_pre.dart';

/// Notifies the logged-in user when someone assigns a task to them.
///
/// TWO SOURCES, one on-screen result:
///
///  1. **Polling (works today, no backend change).** The app asks
///     `/api/task/list` for tasks whose `assigneeid` is the logged-in user and
///     raises a local notification for any task id it has never seen. Runs on
///     login, on app resume, and every [_pollEvery] while the app is alive.
///
///  2. **FCM push (needs the backend to send it).** All the receiving code is
///     wired up here already — foreground messages are turned into the same
///     notification, and a tap opens the task. The day the API starts sending a
///     push on task create, it will just work; see
///     `docs/PUSH_NOTIFICATIONS_BACKEND_SPEC.md`.
///
/// Because polling only runs while the app process is alive, a user who never
/// opens the app gets nothing until the backend push lands. That is the known
/// limit of the app-only approach, not a bug.
class TaskNotificationService with WidgetsBindingObserver {
  TaskNotificationService._();
  static final TaskNotificationService instance = TaskNotificationService._();

  /// Re-check the moment the user comes back to the app — that is when a
  /// notification is most likely to be both fresh and wanted.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) checkNow();
  }

  static const _channelId = 'task_assignments';
  static const _channelName = 'Task Assignments';
  static const _channelDesc = 'Alerts when a task is assigned to you';

  /// How often to re-check while the app is open.
  static const _pollEvery = Duration(minutes: 3);

  /// Highest task id already notified, per user: `lastSeenTaskId_<userid>`.
  static String _seenKey(int userId) => 'lastSeenTaskId_$userId';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Api _api = Api();

  bool _initialised = false;
  bool _checking = false;
  Timer? _timer;

  // ───────────────────────── setup ─────────────────────────

  /// Safe to call more than once. Never throws — a device without Play
  /// Services (or an iOS build without APNs) must not break app startup.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    WidgetsBinding.instance.addObserver(this);

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (r) => _openTask(r.payload),
      );

      // Android 8+ requires the channel to exist before the first notification.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ));

      // Android 13+ needs the runtime POST_NOTIFICATIONS grant. Android permits
      // only one permission request at a time, so these two must run in
      // sequence — never alongside a request from anywhere else in the app.
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      debugPrint('Notification permission granted: $granted');
    } catch (e) {
      debugPrint('Local notifications init skipped: $e');
    }

    // iOS/APNs permission (a no-op on Android, which is already handled above).
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM permission request skipped: $e');
    }

    // Token: fetched once here, and refreshed via a single listener. Attaching
    // this per HomeController instance previously produced duplicate listeners
    // and a storm of repeated callbacks.
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await saveToken(token);
      FirebaseMessaging.instance.onTokenRefresh.listen(saveToken);
    } catch (e) {
      debugPrint('FCM token fetch skipped: $e');
    }

    // ── FCM receiving path (fires only once the backend sends pushes) ──
    try {
      FirebaseMessaging.onMessage.listen(_onPush);
      FirebaseMessaging.onMessageOpenedApp
          .listen((m) => _openTask(_payloadOf(m)));
      final opened = await FirebaseMessaging.instance.getInitialMessage();
      if (opened != null) {
        // App was launched by tapping the push — wait for the first route.
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _openTask(_payloadOf(opened)));
      }
    } catch (e) {
      debugPrint('FCM listeners skipped: $e');
    }
  }

  /// Normalises a push into "<module>:<id>" for [NotificationRouter].
  ///
  /// Preferred (generic) payload — works for ANY module with no app change:
  ///     data: { "module": "task", "id": "41" }
  /// Older module-specific keys are still accepted so a backend that hasn't
  /// switched yet keeps working:
  ///     data: { "taskid": "41" }   /   data: { "visitid": "16" }
  static String? _payloadOf(RemoteMessage m) {
    final module = m.data['module']?.toString().trim();
    if (module != null && module.isNotEmpty) {
      final id = m.data['id']?.toString().trim() ?? '';
      return '$module:$id';
    }
    final visitId = m.data['visitid']?.toString();
    if (visitId != null && visitId.isNotEmpty) return 'visit:$visitId';
    final taskId = m.data['taskid']?.toString();
    if (taskId != null && taskId.isNotEmpty) return 'task:$taskId';
    return null;
  }

  // ───────────────────────── polling ─────────────────────────

  /// Which user the watcher is currently running for (0 = not running).
  int _startedFor = 0;

  /// Start watching for tasks assigned to the logged-in user.
  ///
  /// Safe to call repeatedly — several screens refresh the session on build,
  /// and without this guard each one would fire another task/list request.
  Future<void> start() async {
    final userId = _currentUser()?.userid ?? 0;
    if (userId > 0 && userId == _startedFor && _timer != null) return;

    await init();
    await _syncTopic();
    _startedFor = userId;
    _timer?.cancel();
    _timer = Timer.periodic(_pollEvery, (_) => checkNow());
    await checkNow();
  }

  /// Stop watching (call on logout).
  void stop() {
    _timer?.cancel();
    _timer = null;
    _startedFor = 0;
    leaveTopic(); // fire-and-forget: this phone stops receiving their pushes
  }

  /// The logged-in user, read straight from local storage.
  ///
  /// Deliberately NOT `Get.find<HomeController>()`: this service is started
  /// from HomeController.onInit, and a Get.find() while that controller is
  /// still initialising makes GetX construct a second one — which starts the
  /// service again, forever. Storage is the same source HomeController itself
  /// reads, with no circular dependency.
  UserData? _currentUser() {
    try {
      final saved = SharedPre.getObjs(SharedPre.userData);
      if (saved == null || saved.isEmpty) return null;
      return UserData.fromJson(saved);
    } catch (e) {
      debugPrint('Notification user lookup failed: $e');
      return null;
    }
  }

  // ───────────────────────── FCM topic ─────────────────────────
  //
  // Each user listens on a topic named after them — 'user_<compid>_<userid>'.
  // A sender can then push to one person without anyone keeping a table of
  // device tokens, and you can also hand-send to a single user straight from
  // the Firebase console (Messaging → target: topic).

  static const _topicKey = 'fcmTopic';

  /// Mirror of the stored topic. Logout wipes storage immediately, so the
  /// unsubscribe must not depend on still being able to read it back.
  String _currentTopic = '';

  static String topicFor(int compId, int userId) => 'user_${compId}_$userId';

  /// Subscribe the device to the logged-in user's topic, leaving whichever
  /// topic it was on before (shared phones, account switches).
  Future<void> _syncTopic() async {
    try {
      final user = _currentUser();
      final userId = user?.userid ?? 0;
      final compId = user?.compId ?? 0;
      if (userId <= 0 || compId <= 0) {
        debugPrint('Push topic: no user yet, skipping');
        return;
      }

      final topic = topicFor(compId, userId);
      final previous = _currentTopic.isNotEmpty
          ? _currentTopic
          : await SharedPre.getStringValue(_topicKey);
      if (previous == topic) {
        _currentTopic = topic;
        debugPrint('Push topic: already subscribed to $topic');
        return;
      }

      if (previous.isNotEmpty) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(previous);
      }
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _currentTopic = topic;
      await SharedPre.setValue(_topicKey, topic);
      debugPrint('Subscribed to push topic: $topic');
    } catch (e) {
      debugPrint('Topic subscribe skipped: $e');
    }
  }

  /// Leave the current topic — call on logout, before the session is cleared.
  Future<void> leaveTopic() async {
    try {
      final previous = _currentTopic.isNotEmpty
          ? _currentTopic
          : await SharedPre.getStringValue(_topicKey);
      if (previous.isEmpty) return;
      _currentTopic = '';
      await FirebaseMessaging.instance.unsubscribeFromTopic(previous);
      await SharedPre.clear(_topicKey);
    } catch (e) {
      debugPrint('Topic unsubscribe skipped: $e');
    }
  }

  /// Forget the baseline for a user, so the next check re-establishes it
  /// without firing notifications for tasks that already existed.
  Future<void> resetBaseline(int userId) async =>
      SharedPre.clear(_seenKey(userId));

  /// One pass: fetch my tasks, notify anything newer than the last seen id.
  Future<void> checkNow() async {
    if (_checking) return; // a slow poll must not stack up on resume
    _checking = true;
    try {
      final user = _currentUser();
      final userId = user?.userid ?? 0;
      final compId = user?.compId ?? 0;
      if (userId <= 0 || compId <= 0) return; // not logged in yet

      // Visits and leave requests are checked alongside tasks on the same tick.
      await _checkVisits(compId, userId, user?.name ?? '');
      await _checkLeaveRequests(compId, userId);

      final res = await _api.getTaskList(<String, String>{
        'compid': compId.toString(),
        'userid': userId.toString(),
        'assigneeid': userId.toString(), // only tasks assigned to me
      });
      if (res.status != 200) return;

      // Defensive: the endpoint already filters, but never notify someone
      // about a task that isn't theirs.
      final mine = res.rows.where((t) => t.assigneeid == userId).toList();
      if (mine.isEmpty) return;

      var highest = 0;
      for (final t in mine) {
        if (t.taskid > highest) highest = t.taskid;
      }

      // getIntValue returns -1 when the key has never been written.
      final seen = await SharedPre.getIntValue(_seenKey(userId)) as int;

      // First run for this user: remember where we are, don't announce the
      // whole existing backlog.
      if (seen < 0) {
        await SharedPre.setValue(_seenKey(userId), highest);
        return;
      }
      if (highest <= seen) return;

      final fresh = mine.where((t) => t.taskid > seen).toList()
        ..sort((a, b) => a.taskid.compareTo(b.taskid));
      await SharedPre.setValue(_seenKey(userId), highest);

      if (fresh.length > 3) {
        await _show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '${fresh.length} new tasks assigned to you',
          body: fresh.map((t) => t.title).take(3).join(', '),
          payload: null,
        );
        return;
      }
      for (final t in fresh) {
        await _show(
          id: t.taskid,
          title: 'New task assigned to you',
          body: _bodyFor(t.title, t.createdby, t.priority, t.duedate),
          payload: 'task:${t.taskid}',
        );
      }
    } catch (e) {
      debugPrint('Task notification check failed: $e');
    } finally {
      _checking = false;
    }
  }

  // ────────────────────── leave requests ──────────────────────

  /// Highest leave-application id already notified, per approver.
  static String _seenLeaveKey(int userId) => 'lastSeenLeaveId_$userId';

  /// Notifies an approver when someone applies for leave.
  ///
  /// No access check is needed here: /api/pendingleavelist/… returns an empty
  /// list for anyone without the leave-approval grant (ERP menu 2388), and it
  /// only ever returns rows still at status 'Pending'. So a non-approver simply
  /// never gets one of these.
  Future<void> _checkLeaveRequests(int compId, int userId) async {
    try {
      final res = await _api.getPendingLeaveList(<String, String>{
        'compid': compId.toString(),
        'userid': userId.toString(),
        'executiveid': '0',
      });
      if (res.status != 200) return;

      final pending = res.data ?? [];
      if (pending.isEmpty) return;

      int idOf(dynamic l) => int.tryParse('${l.id ?? 0}') ?? 0;

      var highest = 0;
      for (final l in pending) {
        final id = idOf(l);
        if (id > highest) highest = id;
      }

      final seen = await SharedPre.getIntValue(_seenLeaveKey(userId)) as int;
      // First run for this approver: set the baseline, don't announce the
      // backlog of leaves that were already waiting.
      if (seen < 0) {
        await SharedPre.setValue(_seenLeaveKey(userId), highest);
        return;
      }
      if (highest <= seen) return;

      final fresh = pending.where((l) => idOf(l) > seen).toList()
        ..sort((a, b) => idOf(a).compareTo(idOf(b)));
      await SharedPre.setValue(_seenLeaveKey(userId), highest);

      if (fresh.length > 3) {
        await _show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '${fresh.length} leave requests need your approval',
          body: fresh
              .map((l) => l.executivename ?? '')
              .where((n) => n.isNotEmpty)
              .take(3)
              .join(', '),
          payload: 'leave:0',
        );
        return;
      }
      for (final l in fresh) {
        final who = (l.executivename ?? '').trim();
        final bits = <String>[
          if ((l.title ?? '').trim().isNotEmpty) l.title!.trim(),
          if ((l.date ?? '').trim().isNotEmpty) l.date!.trim(),
          if ((l.reason ?? '').trim().isNotEmpty) l.reason!.trim(),
        ];
        await _show(
          // Offset so a leave id can't collide with a task or visit id.
          id: 800000 + idOf(l),
          title: who.isEmpty
              ? 'New leave request to approve'
              : '$who applied for leave',
          body: bits.join(' · '),
          payload: 'leave:${idOf(l)}',
        );
      }
    } catch (e) {
      debugPrint('Leave notification check failed: $e');
    }
  }

  // ───────────────────────── visits ─────────────────────────

  /// Highest visit id already notified, per user.
  static String _seenVisitKey(int userId) => 'lastSeenVisitId_$userId';

  /// Notifies about visits newly assigned to this user.
  ///
  /// Caveat: /api/visit/list does NOT filter by assignee — it returns the same
  /// rows whatever userid is passed — and its rows carry only VisitedByName,
  /// not VisitedById. So "mine" is decided by matching that name against the
  /// logged-in user. If the backend ever returns VisitedById in the list (or
  /// filters server-side), switch to that: it is exact, this is not.
  Future<void> _checkVisits(int compId, int userId, String myName) async {
    final me = myName.trim().toLowerCase();
    if (me.isEmpty) return;
    try {
      final rows = await VisitEntryRepo.list(
          compid: compId.toString(), userid: userId.toString());
      final mine = rows
          .where((v) => v.visitedBy.trim().toLowerCase() == me)
          .toList();
      if (mine.isEmpty) return;

      var highest = 0;
      for (final v in mine) {
        if (v.id > highest) highest = v.id;
      }

      final seen = await SharedPre.getIntValue(_seenVisitKey(userId)) as int;
      // First run for this user: set the baseline, don't announce the backlog.
      if (seen < 0) {
        await SharedPre.setValue(_seenVisitKey(userId), highest);
        return;
      }
      if (highest <= seen) return;

      final fresh = mine.where((v) => v.id > seen).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      await SharedPre.setValue(_seenVisitKey(userId), highest);

      if (fresh.length > 3) {
        await _show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '${fresh.length} new visits assigned to you',
          body: fresh.map((v) => v.visitTo).where((t) => t.isNotEmpty).take(3).join(', '),
          payload: null,
        );
        return;
      }
      for (final v in fresh) {
        final bits = <String>[
          if (v.visitTo.isNotEmpty) v.visitTo,
          if (v.purposeType.isNotEmpty) v.purposeType,
          if (v.location.isNotEmpty) v.location,
          if (v.visitDate.isNotEmpty) v.visitDate,
        ];
        await _show(
          // Offset so a visit id can't collide with a task id of the same value.
          id: 900000 + v.id,
          title: 'New visit assigned to you',
          body: bits.join(' · '),
          payload: 'visit:${v.id}',
        );
      }
    } catch (e) {
      debugPrint('Visit notification check failed: $e');
    }
  }

  String _bodyFor(String title, String by, String priority, String due) {
    final bits = <String>[
      if (title.isNotEmpty) title,
      if (by.isNotEmpty) 'from $by',
      if (priority.isNotEmpty) priority,
      if (due.isNotEmpty) 'due $due',
    ];
    return bits.join(' · ');
  }

  // ───────────────────────── push → notification ─────────────────────────

  /// A push that arrived while the app is in the foreground. Android does not
  /// draw those itself, so re-raise it through the same local channel.
  Future<void> _onPush(RemoteMessage m) async {
    try {
      final visitId = int.tryParse(m.data['visitid']?.toString() ?? '') ?? 0;
      final taskId = int.tryParse(m.data['taskid']?.toString() ?? '') ?? 0;
      final isVisit = visitId > 0;

      final title = m.notification?.title ??
          m.data['title']?.toString() ??
          (isVisit
              ? 'New visit assigned to you'
              : 'New task assigned to you');
      final body = m.notification?.body ?? m.data['body']?.toString() ?? '';

      await _show(
        // Same offset the polled visit notifications use, so a push and a poll
        // for the same visit replace each other instead of showing twice.
        id: isVisit
            ? 900000 + visitId
            : (taskId > 0
                ? taskId
                : DateTime.now().millisecondsSinceEpoch ~/ 1000),
        title: title,
        body: body,
        payload: _payloadOf(m),
      );

      // Keep polling in step so the same record isn't announced twice.
      final user = _currentUser();
      final uid = user?.userid ?? 0;
      if (uid <= 0) return;
      final key = isVisit ? _seenVisitKey(uid) : _seenKey(uid);
      final id = isVisit ? visitId : taskId;
      if (id > 0) {
        final seen = await SharedPre.getIntValue(key) as int;
        if (id > seen) await SharedPre.setValue(key, id);
      }
    } catch (e) {
      debugPrint('Push display failed: $e');
    }
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    required String? payload,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Open the task the notification refers to.
  /// Opens whatever the notification referred to.
  ///
  /// Payload is "<module>:<id>" (e.g. "visit:16"), or a bare task id for the
  /// notifications this app raised before modules existed. Either way the
  /// decision of WHICH screen lives in [NotificationRouter], so a new module
  /// only needs a line there — not changes scattered through this service.
  void _openTask(String? payload) {
    final raw = (payload ?? '').trim();
    if (raw.isEmpty) {
      NotificationRouter.open(module: 'task');
      return;
    }

    final sep = raw.indexOf(':');
    if (sep > 0) {
      NotificationRouter.open(
        module: raw.substring(0, sep),
        id: int.tryParse(raw.substring(sep + 1)) ?? 0,
      );
      return;
    }

    // Legacy: a bare number meant a task id.
    final legacy = NotificationRouter.legacyPayload(raw);
    if (legacy != null) {
      NotificationRouter.open(module: legacy.module, id: legacy.id);
    }
  }

  // ───────────────────────── FCM token ─────────────────────────

  /// Hand the device's FCM token to the backend so it can push to this user.
  ///
  /// The register endpoint does not exist yet (see the backend spec), so this
  /// only stores the token locally. Flip [backendSupportsPush] to true once the
  /// API exposes `notification/registertoken` — nothing else needs to change.
  static const bool backendSupportsPush = false;

  String _lastSavedToken = '';

  Future<void> saveToken(String? token) async {
    if (token == null || token.isEmpty) return;
    if (token == _lastSavedToken) return; // don't re-log/re-register the same one
    _lastSavedToken = token;
    debugPrint('FCM token: $token');
    await SharedPre.setValue('fcmToken', token);
    if (!backendSupportsPush) return;
    try {
      final user = _currentUser();
      if (user?.userid == null || user?.compId == null) return;
      await _api.registerPushToken(<String, String>{
        'compid': user!.compId.toString(),
        'userid': user.userid.toString(),
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      });
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  /// Debug helper — raises the notification without waiting for a real task.
  Future<void> showTestNotification() async {
    await init();
    await _show(
      id: 999999,
      title: 'New task assigned to you',
      body: 'Test notification · Task module',
      payload: null,
    );
  }
}

/// Handles a push that arrives while the app is backgrounded or killed.
/// Must be a top-level function — the OS spins up a fresh isolate for it.
@pragma('vm:entry-point')
Future<void> taskPushBackgroundHandler(RemoteMessage message) async {
  // Android draws `notification` payloads itself, so there is nothing to do
  // here for the normal case; this exists so data-only pushes are not dropped.
  debugPrint('Background push: ${jsonEncode(message.data)}');
}
