import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/app_routes/app_routes.dart';

import '../../../../utils/app_constant_new.dart';
import 'task_controller.dart';
import 'task_models.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<TaskModuleController>()
        ? Get.find<TaskModuleController>()
        : Get.put(TaskModuleController());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _text,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: newTextPrimary, size: 20),
        ),
        title: const Text('Task Management',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [

          GetBuilder<TaskModuleController>(
            builder: (ctrl) => Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () => _openFilter(context, ctrl),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: purpleLightest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        const Center(
                          child: Icon(Icons.filter_list_rounded, color: purpleColor, size: 20),
                        ),
                        if (ctrl.hasFilter)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6, right: 6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 2)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () async {
          c.resetCreateForm();
          await Get.toNamed(AppRoutes.createTask);
        },
      ),
      body: GetBuilder<TaskModuleController>(
        builder: (ctrl) {
          if (ctrl.listLoading) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }
          return RefreshIndicator(
            color: _primary,
            onRefresh: ctrl.loadTasks,
            child: Column(
              children: [
                _summaryBar(ctrl),
                Expanded(
                  child: ctrl.visibleTasks.isEmpty
                      ? _empty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 90),
                          itemCount: ctrl.visibleTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _taskCard(ctrl.visibleTasks[i], ctrl),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryBar(TaskModuleController c) {
    Widget pill(String label, int value, Color color) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEF0F4)),
            ),
            child: Column(
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: _sub)),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 2),
      child: Row(
        children: [
          pill('Total', c.summary.total, _text),
          pill('Open', c.summary.open, _primary),
          pill('Closed', c.summary.closed, const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _empty() => ListView(
        children: const [
          SizedBox(height: 120),
          Icon(Icons.task_alt_rounded, size: 60, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Center(
            child: Text('No tasks found',
                style: TextStyle(fontSize: 15, color: _sub)),
          ),
        ],
      );

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFEA580C);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF16A34A);
      default:
        return _sub;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'close':
      case 'done':
      case 'completed':
        return const Color(0xFF16A34A);
      case 'open':
        return _primary;
      default:
        return const Color(0xFFD97706); // pending
    }
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _taskCard(TaskRow t, TaskModuleController c) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await Get.toNamed(AppRoutes.taskDetail,
            arguments: {'taskid': t.taskid});
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEF0F4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(t.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _text)),
                ),
                const SizedBox(width: 8),
                if (t.priority.isNotEmpty)
                  _badge(t.priority, _priorityColor(t.priority)),
              ],
            ),
            if (t.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: _sub)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _badge(t.status.isEmpty ? 'Pending' : t.status,
                    _statusColor(t.status)),
                const Spacer(),
                if (t.assignee.isNotEmpty) ...[
                  const Icon(Icons.person_outline, size: 14, color: _sub),
                  const SizedBox(width: 3),
                  Text(t.assignee,
                      style: const TextStyle(fontSize: 12, color: _sub)),
                ],
              ],
            ),
            if (t.client.isNotEmpty || t.duedate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (t.client.isNotEmpty) ...[
                    const Icon(Icons.business_outlined, size: 14, color: _sub),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(t.client,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _sub)),
                    ),
                  ] else
                    const Spacer(),
                  if (t.duedate.isNotEmpty) ...[
                    const Icon(Icons.event_outlined, size: 14, color: _sub),
                    const SizedBox(width: 3),
                    Text(t.duedate,
                        style: const TextStyle(fontSize: 12, color: _sub)),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // A labelled dropdown whose options come from the loaded list. Hidden when empty.
  Widget _filterDropdown(String label, List<String> options, String value,
      ValueChanged<String?> onChanged) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: _sub)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value.isEmpty ? null : value,
                hint: const Text('All', style: TextStyle(fontSize: 13)),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All')),
                  ...options.map((o) => DropdownMenuItem(
                      value: o,
                      child: Text(o, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bottom sheet ──
  void _openFilter(BuildContext context, TaskModuleController c) {
    final statusOptions = ['All', 'Open', 'Pending', 'Close', 'Done'];
    final priorityOptions = ['All', 'Low', 'Medium', 'High', 'Urgent'];
    final searchCtrl = TextEditingController(text: c.filterSearch);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18),
        child: GetBuilder<TaskModuleController>(
          builder: (ctrl) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Filters',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: _text)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      searchCtrl.clear();
                      ctrl.clearFilters();
                      Get.back();
                    },
                    child: const Text('Clear', style: TextStyle(color: _primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Search',
                  style: TextStyle(fontSize: 12.5, color: _sub)),
              const SizedBox(height: 6),
              TextField(
                controller: searchCtrl,
                onChanged: ctrl.setSearch,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Title / client / assignee',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Status',
                  style: TextStyle(fontSize: 12.5, color: _sub)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: statusOptions
                    .map((s) => ChoiceChip(
                          label: Text(s),
                          selected: ctrl.filterStatus == s,
                          selectedColor: _primary,
                          labelStyle: TextStyle(
                              color: ctrl.filterStatus == s
                                  ? Colors.white
                                  : _text),
                          onSelected: (_) => ctrl.setStatusFilter(s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              const Text('Priority',
                  style: TextStyle(fontSize: 12.5, color: _sub)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: priorityOptions
                    .map((p) => ChoiceChip(
                          label: Text(p),
                          selected: ctrl.filterPriority == p,
                          selectedColor: _primary,
                          labelStyle: TextStyle(
                              color: ctrl.filterPriority == p
                                  ? Colors.white
                                  : _text),
                          onSelected: (_) => ctrl.setPriorityFilter(p),
                        ))
                    .toList(),
              ),
              // Client-side filters — options come only from the loaded list.
              _filterDropdown('Assigned To', ctrl.assigneeOptions,
                  ctrl.filterAssignee, ctrl.setAssigneeFilter),
              _filterDropdown('Created By', ctrl.createdByOptions,
                  ctrl.filterCreatedBy, ctrl.setCreatedByFilter),
              _filterDropdown('Tags', ctrl.tagOptions, ctrl.filterTag,
                  ctrl.setTagFilter),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ctrl.setSearch(searchCtrl.text);
                    ctrl.loadTasks();
                    Get.back();
                  },
                  child: const Text('Apply Filters',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
