import 'dart:convert';

/// Models for the Task module (list / detail / followups / dropdowns).
/// JSON is read defensively: the list endpoint returns camelCase keys while the
/// proc-backed detail/followups return PascalCase, so each getter tries both.

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _str(dynamic v) => v == null ? '' : v.toString();

dynamic _pick(Map m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k];
  }
  return null;
}

// ─────────────────────────── Task list ───────────────────────────
class TaskListResp {
  final bool success;
  final int status;
  final String message;
  final List<TaskRow> rows;
  final TaskSummary summary;

  TaskListResp({
    required this.success,
    required this.status,
    required this.message,
    required this.rows,
    required this.summary,
  });

  factory TaskListResp.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is Map) ? j['data'] as Map : {};
    final rowsRaw = (data['rows'] is List) ? data['rows'] as List : [];
    return TaskListResp(
      success: j['success'] == true,
      status: _int(j['status']),
      message: _str(j['message']),
      rows: rowsRaw.map((e) => TaskRow.fromJson(e as Map)).toList(),
      summary: TaskSummary.fromJson(
          (data['summary'] is Map) ? data['summary'] as Map : {}),
    );
  }
}

class TaskSummary {
  final int total;
  final int open;
  final int closed;
  TaskSummary({this.total = 0, this.open = 0, this.closed = 0});
  factory TaskSummary.fromJson(Map j) => TaskSummary(
        total: _int(j['total']),
        open: _int(j['open']),
        closed: _int(j['closed']),
      );
}

class TaskRow {
  final int taskid;
  final String title;
  final String description;
  final int assigneeid;
  final String assignee;
  final String priority;
  final String status;
  final String client;
  final String duedate;
  final String createddate;
  final String createdby;
  final String tags;

  TaskRow({
    required this.taskid,
    required this.title,
    required this.description,
    required this.assigneeid,
    required this.assignee,
    required this.priority,
    required this.status,
    required this.client,
    required this.duedate,
    required this.createddate,
    required this.createdby,
    required this.tags,
  });

  factory TaskRow.fromJson(Map j) => TaskRow(
        taskid: _int(_pick(j, ['taskid', 'TaskId'])),
        title: _str(_pick(j, ['title', 'TaskTitle'])),
        description: _str(_pick(j, ['description', 'Description'])),
        assigneeid: _int(_pick(j, ['assigneeid', 'AssigneeId'])),
        assignee: _str(_pick(j, ['assignee', 'AssigneeName'])),
        priority: _str(_pick(j, ['priority', 'Priority'])),
        status: _str(_pick(j, ['status', 'Status'])),
        client: _str(_pick(j, ['client', 'ClientReference', 'ClientName'])),
        duedate: _str(_pick(j, ['duedate', 'DueDate'])),
        createddate: _str(_pick(j, ['createddate', 'CreatedDate'])),
        createdby: _str(_pick(j, ['createdby', 'CreatedByName'])),
        tags: _str(_pick(j, ['tags', 'Tags'])),
      );
}

// ─────────────────────────── Task detail ───────────────────────────
class TaskDetailResponse {
  final bool success;
  final int status;
  final String message;
  final TaskInfo? task;
  final List<TaskFollowup> followups;

  TaskDetailResponse({
    required this.success,
    required this.status,
    required this.message,
    required this.task,
    required this.followups,
  });

  factory TaskDetailResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is Map) ? j['data'] as Map : {};
    final fRaw = (data['followups'] is List) ? data['followups'] as List : [];
    return TaskDetailResponse(
      success: j['success'] == true,
      status: _int(j['status']),
      message: _str(j['message']),
      task: (data['task'] is Map) ? TaskInfo.fromJson(data['task'] as Map) : null,
      followups: fRaw.map((e) => TaskFollowup.fromJson(e as Map)).toList(),
    );
  }
}

class TaskInfo {
  final int taskid;
  final String title;
  final String description;
  final int assigneeid;
  final String assignee;
  final String duedate;
  final String priority;
  final String tags;
  final String status;
  final int statusid;
  final String createddate;
  final String createdby;
  final String client;
  final int leadid;
  // taskmaster already carries these; /api/task/detail returns both.
  final String attachmentPath;
  final String attachmentUrl;

  /// The value worth showing — prefer the ready-to-open URL, fall back to the
  /// stored path when it is itself a URL.
  String get attachment {
    if (attachmentUrl.isNotEmpty) return attachmentUrl;
    if (attachmentPath.startsWith('http')) return attachmentPath;
    return '';
  }

  TaskInfo({
    required this.taskid,
    required this.title,
    required this.description,
    required this.assigneeid,
    required this.assignee,
    required this.duedate,
    required this.priority,
    required this.tags,
    required this.status,
    required this.statusid,
    required this.createddate,
    required this.createdby,
    required this.client,
    required this.leadid,
    this.attachmentPath = '',
    this.attachmentUrl = '',
  });

  factory TaskInfo.fromJson(Map j) => TaskInfo(
        taskid: _int(_pick(j, ['TaskId', 'taskid'])),
        title: _str(_pick(j, ['TaskTitle', 'title'])),
        description: _str(_pick(j, ['Description', 'description'])),
        assigneeid: _int(_pick(j, ['AssigneeId', 'assigneeid'])),
        assignee: _str(_pick(j, ['AssigneeName', 'assignee'])),
        duedate: _fmtDate(_pick(j, ['DueDate', 'duedate'])),
        priority: _str(_pick(j, ['Priority', 'priority'])),
        tags: _str(_pick(j, ['Tags', 'tags'])),
        status: _str(_pick(j, ['Status', 'status'])),
        statusid: _int(_pick(j, ['StatusId', 'statusid'])),
        createddate: _fmtDate(_pick(j, ['CreatedDate', 'createddate'])),
        createdby: _str(_pick(j, ['CreatedByName', 'createdby'])),
        client: _str(_pick(j, ['ClientReference', 'ClientName', 'client'])),
        leadid: _int(_pick(j, ['LeadId', 'leadid'])),
        attachmentPath:
            _str(_pick(j, ['AttachmentPath', 'attachmentpath', 'Files'])),
        attachmentUrl:
            _str(_pick(j, ['AttachmentUrl', 'attachmenturl', 'FileUrl'])),
      );
}

class TaskFollowup {
  final int commentid;
  final int userid;
  final String username;
  final String comment;
  final String createdat;

  TaskFollowup({
    required this.commentid,
    required this.userid,
    required this.username,
    required this.comment,
    required this.createdat,
  });

  factory TaskFollowup.fromJson(Map j) => TaskFollowup(
        commentid: _int(_pick(j, ['CommentId', 'commentid'])),
        userid: _int(_pick(j, ['UserId', 'userid'])),
        username: _str(_pick(j, ['UserName', 'username'])),
        comment: _str(_pick(j, ['CommentText', 'comment'])),
        createdat: _fmtDateTime(_pick(j, ['CreatedAt', 'createdat'])),
      );
}

// ─────────────────────────── Dropdowns ───────────────────────────
class TaskDropdownResp {
  final bool success;
  final int status;
  final String message;
  final List<IdName> assignees;
  final List<IdName> statuses;
  final List<String> priorities;

  TaskDropdownResp({
    required this.success,
    required this.status,
    required this.message,
    required this.assignees,
    required this.statuses,
    required this.priorities,
  });

  factory TaskDropdownResp.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is Map) ? j['data'] as Map : {};
    final a = (data['assignees'] is List) ? data['assignees'] as List : [];
    final s = (data['statuses'] is List) ? data['statuses'] as List : [];
    final p = (data['priorities'] is List) ? data['priorities'] as List : [];
    return TaskDropdownResp(
      success: j['success'] == true,
      status: _int(j['status']),
      message: _str(j['message']),
      assignees: a
          .map((e) => IdName(
              id: _int(_pick(e as Map, ['id'])),
              name: _str(_pick(e, ['name']))))
          .toList(),
      statuses: s
          .map((e) => IdName(
              id: _int(_pick(e as Map, ['taskstatusid', 'id'])),
              name: _str(_pick(e, ['taskstatus', 'name']))))
          .toList(),
      priorities: p.map((e) => e.toString()).toList(),
    );
  }
}

class IdName {
  final int id;
  final String name;
  IdName({required this.id, required this.name});
}

/// Generic write-response envelope (create / followup / status).
class TaskActionResponse {
  final bool success;
  final int status;
  final String message;
  final int taskid;
  TaskActionResponse({
    required this.success,
    required this.status,
    required this.message,
    this.taskid = 0,
  });
  factory TaskActionResponse.fromJson(Map<String, dynamic> j) {
    final data = (j['data'] is Map) ? j['data'] as Map : {};
    return TaskActionResponse(
      success: j['success'] == true,
      status: _int(j['status']),
      message: _str(j['message']),
      taskid: _int(_pick(data, ['taskid'])),
    );
  }
}

TaskListResp taskListRespFromJson(String s) =>
    TaskListResp.fromJson(json.decode(s) as Map<String, dynamic>);
TaskDetailResponse taskDetailResponseFromJson(String s) =>
    TaskDetailResponse.fromJson(json.decode(s) as Map<String, dynamic>);
TaskDropdownResp taskDropdownRespFromJson(String s) =>
    TaskDropdownResp.fromJson(json.decode(s) as Map<String, dynamic>);
TaskActionResponse taskActionResponseFromJson(String s) =>
    TaskActionResponse.fromJson(json.decode(s) as Map<String, dynamic>);

// Convert an ISO datetime ("2026-03-31T00:00:00") to "31-03-2026".
String _fmtDate(dynamic v) {
  final s = _str(v);
  if (s.isEmpty) return '';
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
}

// Convert an ISO datetime to "31-03-2026 17:03".
String _fmtDateTime(dynamic v) {
  final s = _str(v);
  if (s.isEmpty) return '';
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  final d =
      '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
  final t =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  return '$d  $t';
}
