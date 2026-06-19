import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'task_controller.dart';
import 'task_models.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({Key? key}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  late final TaskModuleController c;
  late final int taskId;

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<TaskModuleController>()
        ? Get.find<TaskModuleController>()
        : Get.put(TaskModuleController());
    final args = Get.arguments;
    taskId = (args is Map && args['taskid'] != null)
        ? int.tryParse(args['taskid'].toString()) ?? 0
        : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => c.loadDetail(taskId));
  }

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
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _text,
        title: const Text('Task Detail',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GetBuilder<TaskModuleController>(
        builder: (ctrl) {
          if (ctrl.detailLoading) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }
          final d = ctrl.detail;
          if (d == null) {
            return const Center(
                child: Text('Task not found', style: TextStyle(color: _sub)));
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerCard(d),
                      const SizedBox(height: 14),
                      _statusActions(ctrl, d),
                      const SizedBox(height: 14),
                      _followupsCard(ctrl),
                    ],
                  ),
                ),
              ),
              _addFollowupBar(ctrl, d),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _row(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: _sub),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: _sub)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _text)),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEF0F4)),
        ),
        child: child,
      );

  Widget _headerCard(TaskInfo d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(d.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: _text)),
              ),
              const SizedBox(width: 8),
              if (d.priority.isNotEmpty)
                _badge(d.priority, _priorityColor(d.priority)),
            ],
          ),
          const SizedBox(height: 8),
          _badge(d.status.isEmpty ? 'Pending' : d.status, _statusColor(d.status)),
          const SizedBox(height: 14),
          if (d.description.isNotEmpty) ...[
            Text(d.description,
                style: const TextStyle(fontSize: 13.5, color: _text, height: 1.4)),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEEF0F4)),
            const SizedBox(height: 14),
          ],
          _row(Icons.person_outline, 'Assigned to', d.assignee),
          _row(Icons.business_outlined, 'Client', d.client),
          _row(Icons.event_outlined, 'Due date', d.duedate),
          _row(Icons.label_outline, 'Tags', d.tags),
          _row(Icons.account_circle_outlined, 'Created by', d.createdby),
          _row(Icons.schedule_outlined, 'Created on', d.createddate),
          _row(Icons.tag, 'Task ID', '#${d.taskid}'),
        ],
      ),
    );
  }

  Widget _statusActions(TaskModuleController ctrl, TaskInfo d) {
    final closed = ['close', 'done', 'completed']
        .contains(d.status.toLowerCase());
    return Row(
      children: [
        if (!closed)
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Mark Done'),
              onPressed: () => ctrl.changeStatus(d.taskid, 'Done'),
            ),
          ),
        if (!closed) const SizedBox(width: 10),
        if (d.status.toLowerCase() != 'open')
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('Mark Open'),
              onPressed: () => ctrl.changeStatus(d.taskid, 'Open'),
            ),
          ),
      ],
    );
  }

  Widget _followupsCard(TaskModuleController ctrl) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.forum_outlined, size: 18, color: _primary),
              const SizedBox(width: 8),
              Text('Followups (${ctrl.followups.length})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _text)),
            ],
          ),
          const SizedBox(height: 12),
          if (ctrl.followups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No followups yet',
                    style: TextStyle(fontSize: 13, color: _sub)),
              ),
            )
          else
            ...List.generate(ctrl.followups.length, (i) {
              final f = ctrl.followups[i];
              final isLast = i == ctrl.followups.length - 1;
              return _followupTile(f, isLast);
            }),
        ],
      ),
    );
  }

  Widget _followupTile(TaskFollowup f, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                    color: _primary, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                    child: Container(width: 2, color: const Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(f.username.isEmpty ? 'User' : f.username,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _text)),
                      const Spacer(),
                      Text(f.createdat,
                          style: const TextStyle(fontSize: 11, color: _sub)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(f.comment,
                      style: const TextStyle(
                          fontSize: 13, color: _text, height: 1.35)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addFollowupBar(TaskModuleController ctrl, TaskInfo d) {
    final statusNames = ctrl.statuses.map((e) => e.name).toList();
    return Container(
      padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEF0F4))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusNames.isNotEmpty)
            Row(
              children: [
                const Text('Status:', style: TextStyle(fontSize: 12.5, color: _sub)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      value: statusNames.contains(ctrl.followupStatus)
                          ? ctrl.followupStatus
                          : (statusNames.contains(d.status) ? d.status : null),
                      hint: const Text('Select status',
                          style: TextStyle(fontSize: 13)),
                      items: statusNames
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: ctrl.setFollowupStatus,
                    ),
                  ),
                ),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl.commentCtrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Add a followup comment...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ctrl.savingFollowup
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: _primary)),
                    )
                  : CircleAvatar(
                      radius: 23,
                      backgroundColor: _primary,
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                        onPressed: () => ctrl.saveFollowup(d.taskid),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
