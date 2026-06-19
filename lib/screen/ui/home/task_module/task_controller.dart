import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/home/home_contoller.dart';
import 'package:newdigitalerp/services/api_service/api.dart';
import 'package:newdigitalerp/utils/show_message.dart';

import 'task_models.dart';

/// Single controller for the whole Task module — list, detail, create, followups.
class TaskModuleController extends GetxController {
  final Api _api = Api();
  final HomeController home = Get.find<HomeController>();

  // ── List state ──
  bool listLoading = false;
  List<TaskRow> tasks = [];
  TaskSummary summary = TaskSummary();

  // Filters (status/priority/search are server-side)
  String filterStatus = 'All'; // All / Open / Pending / Close / Done
  String filterPriority = 'All'; // All / Low / Medium / High / Urgent
  String filterSearch = '';

  // Client-side filters — options come ONLY from the currently loaded list.
  String filterAssignee = ''; // '' = All
  String filterCreatedBy = '';
  String filterTag = '';

  // Distinct option lists derived from the loaded tasks (not every DB value).
  List<String> _distinct(String Function(TaskRow) sel) {
    final set = <String>{};
    for (final t in tasks) {
      final v = sel(t).trim();
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> get assigneeOptions => _distinct((t) => t.assignee);
  List<String> get createdByOptions => _distinct((t) => t.createdby);
  List<String> get tagOptions {
    // Tags may be comma-separated — split into individual values.
    final set = <String>{};
    for (final t in tasks) {
      for (final part in t.tags.split(',')) {
        final v = part.trim();
        if (v.isNotEmpty) set.add(v);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  // Tasks after applying the client-side filters to the loaded list.
  List<TaskRow> get visibleTasks {
    return tasks.where((t) {
      if (filterAssignee.isNotEmpty && t.assignee != filterAssignee) return false;
      if (filterCreatedBy.isNotEmpty && t.createdby != filterCreatedBy) return false;
      if (filterTag.isNotEmpty &&
          !t.tags.split(',').map((e) => e.trim()).contains(filterTag)) return false;
      return true;
    }).toList();
  }

  // ── Dropdowns (shared by filter + create) ──
  List<IdName> assignees = [];
  List<IdName> statuses = [];
  List<String> priorities = ['Low', 'Medium', 'High', 'Urgent'];

  // ── Detail state ──
  bool detailLoading = false;
  TaskInfo? detail;
  List<TaskFollowup> followups = [];

  // ── Create form state ──
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tagsCtrl = TextEditingController();
  final clientCtrl = TextEditingController();
  int? createAssigneeId;
  String createPriority = 'Medium';
  DateTime? createDueDate;
  bool creating = false;

  // ── Followup form state ──
  final commentCtrl = TextEditingController();
  String followupStatus = '';
  bool savingFollowup = false;

  String get _compId => home.currentUserData?.compId.toString() ?? '';
  String get _branchId => home.currentUserData?.branchId.toString() ?? '';
  String get _userId => home.currentUserData?.userid.toString() ?? '';
  String get _yearId => home.currentUserData?.yearId.toString() ?? '';
  String get _userName => home.currentUserData?.name?.toString() ?? '';

  bool get hasFilter =>
      filterStatus != 'All' ||
      filterPriority != 'All' ||
      filterSearch.isNotEmpty ||
      filterAssignee.isNotEmpty ||
      filterCreatedBy.isNotEmpty ||
      filterTag.isNotEmpty;

  void setAssigneeFilter(String? v) { filterAssignee = v ?? ''; update(); }
  void setCreatedByFilter(String? v) { filterCreatedBy = v ?? ''; update(); }
  void setTagFilter(String? v) { filterTag = v ?? ''; update(); }

  @override
  void onInit() {
    super.onInit();
    loadDropdowns();
    loadTasks();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    tagsCtrl.dispose();
    clientCtrl.dispose();
    commentCtrl.dispose();
    super.onClose();
  }

  // ───────────────────────── List ─────────────────────────
  Future<void> loadTasks() async {
    listLoading = true;
    update();
    try {
      final body = <String, String>{
        'compid': _compId,
        'userid': _userId, // visibility: creator / assignee / admin only
        'status': filterStatus,
        'priority': filterPriority,
        'search': filterSearch,
      };
      final res = await _api.getTaskList(body);
      if (res.status == 200) {
        tasks = res.rows;
        summary = res.summary;
      } else {
        tasks = [];
        summary = TaskSummary();
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      listLoading = false;
      update();
    }
  }

  void setStatusFilter(String? v) {
    filterStatus = v ?? 'All';
    update();
  }

  void setPriorityFilter(String? v) {
    filterPriority = v ?? 'All';
    update();
  }

  void setSearch(String v) {
    filterSearch = v;
  }

  void clearFilters() {
    filterStatus = 'All';
    filterPriority = 'All';
    filterSearch = '';
    filterAssignee = '';
    filterCreatedBy = '';
    filterTag = '';
    update();
    loadTasks();
  }

  // ───────────────────────── Dropdowns ─────────────────────────
  Future<void> loadDropdowns() async {
    try {
      final res = await _api.getTaskDropdownsV2({'compid': _compId});
      if (res.status == 200) {
        assignees = res.assignees;
        statuses = res.statuses;
        if (res.priorities.isNotEmpty) priorities = res.priorities;
        update();
      }
    } catch (_) {}
  }

  // ───────────────────────── Detail ─────────────────────────
  Future<void> loadDetail(int taskId) async {
    detailLoading = true;
    detail = null;
    followups = [];
    commentCtrl.clear();
    followupStatus = '';
    update();
    try {
      final res = await _api.getTaskDetailV2({
        'compid': _compId,
        'taskid': taskId.toString(),
      });
      if (res.status == 200 && res.task != null) {
        detail = res.task;
        followups = res.followups;
        followupStatus = detail!.status;
      } else {
        ShowMessage.showSnackBar('Error', res.message);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
    } finally {
      detailLoading = false;
      update();
    }
  }

  void setFollowupStatus(String? v) {
    followupStatus = v ?? followupStatus;
    update();
  }

  int _statusIdFor(String name) {
    for (final s in statuses) {
      if (s.name.toLowerCase() == name.toLowerCase()) return s.id;
    }
    return 0;
  }

  // ───────────────────────── Add followup ─────────────────────────
  Future<bool> saveFollowup(int taskId) async {
    if (commentCtrl.text.trim().isEmpty) {
      ShowMessage.showSnackBar('Required', 'Please enter a comment');
      return false;
    }
    savingFollowup = true;
    update();
    try {
      final body = <String, String>{
        'compid': _compId,
        'taskid': taskId.toString(),
        'userid': _userId,
        'username': _userName,
        'comment': commentCtrl.text.trim(),
      };
      // include status change if it differs from current
      if (followupStatus.isNotEmpty &&
          followupStatus.toLowerCase() != (detail?.status ?? '').toLowerCase()) {
        body['status'] = followupStatus;
        body['statusid'] = _statusIdFor(followupStatus).toString();
      }
      final res = await _api.addTaskFollowupV2(body);
      if (res.status == 200) {
        commentCtrl.clear();
        await loadDetail(taskId);
        await loadTasks(); // refresh list status/counts
        ShowMessage.showSnackBar('Success', 'Followup added');
        return true;
      }
      ShowMessage.showSnackBar('Error', res.message);
      return false;
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
      return false;
    } finally {
      savingFollowup = false;
      update();
    }
  }

  Future<bool> changeStatus(int taskId, String status) async {
    try {
      final res = await _api.updateTaskStatusV2({
        'compid': _compId,
        'taskid': taskId.toString(),
        'status': status,
        'statusid': _statusIdFor(status).toString(),
      });
      if (res.status == 200) {
        await loadDetail(taskId);
        await loadTasks();
        ShowMessage.showSnackBar('Success', 'Task marked $status');
        return true;
      }
      ShowMessage.showSnackBar('Error', res.message);
      return false;
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
      return false;
    }
  }

  // ───────────────────────── Create ─────────────────────────
  void resetCreateForm() {
    titleCtrl.clear();
    descCtrl.clear();
    tagsCtrl.clear();
    clientCtrl.clear();
    createAssigneeId = null;
    createPriority = 'Medium';
    createDueDate = null;
    update();
  }

  void setCreateAssignee(int? id) {
    createAssigneeId = id;
    update();
  }

  void setCreatePriority(String? v) {
    createPriority = v ?? 'Medium';
    update();
  }

  void setCreateDueDate(DateTime? d) {
    createDueDate = d;
    update();
  }

  String get createDueDateLabel => createDueDate == null
      ? 'Select due date'
      : '${createDueDate!.day.toString().padLeft(2, '0')}-${createDueDate!.month.toString().padLeft(2, '0')}-${createDueDate!.year}';

  Future<bool> createTask() async {
    if (titleCtrl.text.trim().isEmpty) {
      ShowMessage.showSnackBar('Required', 'Please enter a task title');
      return false;
    }
    creating = true;
    update();
    try {
      String assigneeName = '';
      if (createAssigneeId != null) {
        assigneeName = assignees
            .firstWhere((a) => a.id == createAssigneeId,
                orElse: () => IdName(id: 0, name: ''))
            .name;
      }
      final body = <String, String>{
        'compid': _compId,
        'branchid': _branchId,
        'userid': _userId,
        'yearid': _yearId,
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'assigneeid': (createAssigneeId ?? 0).toString(),
        'assignee': assigneeName,
        'priority': createPriority,
        'tags': tagsCtrl.text.trim(),
        'clientreference': clientCtrl.text.trim(),
        if (createDueDate != null)
          'duedate':
              '${createDueDate!.year}-${createDueDate!.month.toString().padLeft(2, '0')}-${createDueDate!.day.toString().padLeft(2, '0')}',
      };
      final res = await _api.createTaskV2(body);
      if (res.status == 200) {
        resetCreateForm();
        await loadTasks();
        ShowMessage.showSnackBar('Success', 'Task created');
        return true;
      }
      ShowMessage.showSnackBar('Error', res.message);
      return false;
    } catch (e) {
      ShowMessage.showSnackBar('Error', '$e');
      return false;
    } finally {
      creating = false;
      update();
    }
  }
}
