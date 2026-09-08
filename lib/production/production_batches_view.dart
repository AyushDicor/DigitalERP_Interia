import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/production/production_controller.dart';
import 'package:newdigitalerp/production/production_models.dart';

/// Screen 2 — one card per batch at the chosen stage. Each card shows the
/// batch/item, plan vs progress, the balance, and two inputs (Produced, QC OK).
/// "Save All" posts every touched card in one /production/saveentry call.
class ProductionBatchesView extends StatelessWidget {
  const ProductionBatchesView({super.key});

  static const _purple = Color(0xFF5B6CF6);
  static const _green = Color(0xFF16A34A);
  static const _border = Color(0xFFE2E8F0);
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductionController>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: _ink,
        title: Text(c.selectedStage?.stagename ?? 'Batches',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: GetBuilder<ProductionController>(
        builder: (ctrl) {
          if (ctrl.batchesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = ctrl.batches?.rows ?? [];
          if (all.isEmpty) {
            return _empty(ctrl);
          }
          final rows = ctrl.visibleRows;
          return Column(
            children: [
              _searchField(ctrl),
              Expanded(
                child: rows.isEmpty
                    ? _noMatch(ctrl)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                        itemCount: rows.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _batchCard(ctrl, rows[i]),
                      ),
              ),
              _saveBar(ctrl),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField(ProductionController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: TextField(
        controller: ctrl.searchCtrl,
        onChanged: ctrl.setSearch,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: _ink),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search batch no or item…',
          hintStyle: const TextStyle(fontSize: 13.5, color: _muted),
          prefixIcon: const Icon(Icons.search, size: 20, color: _muted),
          suffixIcon: ctrl.search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _muted),
                  onPressed: () {
                    ctrl.searchCtrl.clear();
                    ctrl.setSearch('');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _purple, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _noMatch(ProductionController ctrl) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, color: Color(0xFF94A3B8), size: 40),
              const SizedBox(height: 12),
              Text('No batches match "${ctrl.search}".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted)),
            ],
          ),
        ),
      );

  Widget _batchCard(ProductionController ctrl, ProductionBatchRow r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(r.batchno,
                    style: const TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5)),
              ),
              const Spacer(),
              Text('Bal: ${_qty(r.availableqty)} ${r.unit}',
                  style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.itemname,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 4),
          Text(
            'Plan ${_qty(r.planqty)} · Produced ${_qty(r.producedsofar)} · QC ${_qty(r.qcsofar)}',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _numField(
                    label: 'Produced', ctrl: ctrl.producedCtrls[r.challanid]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numField(
                    label: 'QC OK', ctrl: ctrl.qcCtrls[r.challanid]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numField(
                    label: 'Issue', ctrl: ctrl.issueCtrls[r.challanid]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numField({required String label, TextEditingController? ctrl}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: _muted,
                  fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
          decoration: InputDecoration(
            isDense: true,
            hintText: '0',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _purple, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveBar(ProductionController ctrl) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: ctrl.saving ? null : ctrl.saveAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              disabledBackgroundColor: _purple.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: ctrl.saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : const Text('Save All',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _empty(ProductionController ctrl) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF94A3B8), size: 40),
              const SizedBox(height: 12),
              Text(
                  ctrl.batchesError.isNotEmpty
                      ? ctrl.batchesError
                      : 'No batches at this stage.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: ctrl.loadBatches,
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

/// Trim trailing ".0" and group with Indian separators (1,00,000).
String _qty(double v) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  final neg = s.startsWith('-');
  final body = neg ? s.substring(1) : s;
  final dot = body.indexOf('.');
  final intPart = dot == -1 ? body : body.substring(0, dot);
  final frac = dot == -1 ? '' : body.substring(dot);
  return '${neg ? '-' : ''}${_indianHead(intPart)}$frac';
}

/// Indian grouping of the integer string (no decimals): 12345678 -> 1,23,45,678
String _indianHead(String intPart) {
  if (intPart.length <= 3) return intPart;
  final last3 = intPart.substring(intPart.length - 3);
  var rest = intPart.substring(0, intPart.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}
