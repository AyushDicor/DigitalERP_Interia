import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/screen/ui/home/sales_report/searchable_dropdown.dart';

import 'task_controller.dart';

class TaskCreateScreen extends StatelessWidget {
  const TaskCreateScreen({Key? key}) : super(key: key);

  static const _primary = Color(0xFF5B5BD6);
  static const _bg = Color(0xFFF4F5F9);
  static const _text = Color(0xFF0F172A);
  static const _sub = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TaskModuleController>()) {
      Get.put(TaskModuleController());
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _text,
        title: const Text('Create Task',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: GetBuilder<TaskModuleController>(
        builder: (ctrl) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Task Title *'),
              _input(ctrl.titleCtrl, 'Enter task title'),
              const SizedBox(height: 16),

              _label('Description'),
              _input(ctrl.descCtrl, 'What needs to be done?', maxLines: 3),
              const SizedBox(height: 16),

              _label('Assign To'),
              SearchableDropdown<int>(
                hint: 'Select assignee',
                value: ctrl.createAssigneeId,
                options: ctrl.assignees
                    .map((a) => DdOption<int>(a.id, a.name))
                    .toList(),
                onChanged: ctrl.setCreateAssignee,
              ),
              const SizedBox(height: 16),

              _label('Priority'),
              _priorityRow(ctrl),
              const SizedBox(height: 16),

              _label('Due Date'),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: ctrl.createDueDate ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 3),
                  );
                  if (picked != null) ctrl.setCreateDueDate(picked);
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 18, color: _sub),
                      const SizedBox(width: 10),
                      Text(ctrl.createDueDateLabel,
                          style: TextStyle(
                              fontSize: 13.5,
                              color: ctrl.createDueDate == null ? _sub : _text)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _label('Client Reference'),
              _input(ctrl.clientCtrl, 'Client / company name (optional)'),
              const SizedBox(height: 16),

              _label('Tags'),
              _input(ctrl.tagsCtrl, 'e.g. Work, Urgent (optional)'),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: ctrl.creating
                      ? null
                      : () async {
                          final ok = await ctrl.createTask();
                          if (ok) Get.back();
                        },
                  child: ctrl.creating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Create Task',
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _text)),
      );

  Widget _input(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: _text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _sub),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primary)),
      ),
    );
  }

  Widget _priorityRow(TaskModuleController ctrl) {
    return Wrap(
      spacing: 8,
      children: ctrl.priorities
          .map((p) => ChoiceChip(
                label: Text(p),
                selected: ctrl.createPriority == p,
                selectedColor: _primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE2E8F0))),
                labelStyle: TextStyle(
                    color: ctrl.createPriority == p ? Colors.white : _text),
                onSelected: (_) => ctrl.setCreatePriority(p),
              ))
          .toList(),
    );
  }
}
