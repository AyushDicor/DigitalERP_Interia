import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/production/production_controller.dart';
import 'package:newdigitalerp/production/production_models.dart';

/// Screen 1 — pick a production stage. Chips come from /production/stages; the
/// stage flagged `isfirst` shows a "1st" badge (the line's entry point).
/// Tapping a chip loads that stage's batches and opens the entry screen.
class ProductionStagePickerView extends StatelessWidget {
  const ProductionStagePickerView({super.key});

  static const _green = Color(0xFF16A34A);
  static const _border = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ProductionController());
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text('Production — Bulk Entry',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: GetBuilder<ProductionController>(
        init: c,
        builder: (ctrl) {
          if (ctrl.stagesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.stagesError.isNotEmpty && ctrl.stages.isEmpty) {
            return _error(ctrl);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.grid_view_rounded, size: 20, color: _green),
                    SizedBox(width: 8),
                    Text('Pick a stage',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tap a stage to bulk-enter Produced & QC for its batches.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children:
                      ctrl.stages.map((s) => _stageChip(ctrl, s)).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stageChip(ProductionController ctrl, ProductionStage s) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => ctrl.openStage(s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _green.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.stagename,
              style: const TextStyle(
                  color: _green, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            if (s.isfirst) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('1st',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _error(ProductionController ctrl) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF94A3B8), size: 40),
              const SizedBox(height: 12),
              Text(ctrl.stagesError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: ctrl.loadStages,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _border)),
              ),
            ],
          ),
        ),
      );
}
