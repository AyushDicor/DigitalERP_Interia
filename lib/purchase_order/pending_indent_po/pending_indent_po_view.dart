// Pending Indent for PO — list of approved indents awaiting a Purchase Order.
// Tapping a row opens the PO create form pre-seeded from that indent; once the
// PO is saved the indent closes and drops off this list on refresh.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:newdigitalerp/purchase_order/pending_indent_po/pending_indent_po_controller.dart';
import 'package:newdigitalerp/purchase_order/pending_indent_po/pending_indent_po_models.dart';
import 'package:newdigitalerp/purchase_order/purchase_order_create_view.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/summary_cards.dart';

const Color _kPrimary = purpleColor;
const Color _kBg = Color(0xFFF6F7FB);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFE4E7F0);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF6B7280);
const Color _kTextHint = Color(0xFF9CA3AF);

class PendingIndentPoView extends StatelessWidget {
  const PendingIndentPoView({super.key});

  static String _qty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PendingIndentPoController>(
      init: PendingIndentPoController(),
      builder: (c) => Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: _kBorder,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              margin: const EdgeInsets.all(10),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: _kTextPrimary, size: 16),
            ),
          ),
          title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Pending Indent for PO',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary)),
                Text('Generate a Purchase Order from an indent',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: _kTextSecondary)),
              ]),
        ),
        body: RefreshIndicator(
          color: _kPrimary,
          onRefresh: () => c.loadList(),
          child: c.isBusy && c.allIndents.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                      color: _kPrimary, strokeWidth: 2.5))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                  children: [
                    _statsRow(c),
                    const SizedBox(height: 14),
                    _searchField(c),
                    const SizedBox(height: 12),
                    if (c.indentList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(children: const [
                            Icon(Icons.playlist_add_check_circle_outlined,
                                size: 46, color: _kTextHint),
                            SizedBox(height: 10),
                            Text('No pending indents',
                                style: TextStyle(
                                    fontSize: 13.5, color: _kTextSecondary)),
                          ]),
                        ),
                      )
                    else
                      ...c.indentList.map((o) => _indentCard(context, c, o)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _statsRow(PendingIndentPoController c) {
    return SummaryCards([
      SummaryStat(
          '${c.totalRecords}', 'Pending', newOrangeColor, newOrangeLightColor),
      SummaryStat(
          '${c.filteredCount}', 'Showing', newBlueColor, newBlueLightColor),
    ], padding: EdgeInsets.zero);
  }

  Widget _searchField(PendingIndentPoController c) => Container(
        decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder)),
        child: TextField(
          onChanged: c.onSearch,
          style: const TextStyle(fontSize: 14, color: _kTextPrimary),
          decoration: const InputDecoration(
            hintText: 'Search indent no, request by, plant…',
            hintStyle: TextStyle(fontSize: 13.5, color: _kTextHint),
            prefixIcon: Icon(Icons.search, size: 20, color: _kTextSecondary),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          ),
        ),
      );

  Widget _indentCard(
      BuildContext context, PendingIndentPoController c, PendingIndentItem o) {
    return GestureDetector(
      onTap: () async {
        final created = await Get.to(
            () => PurchaseOrderCreateView(seedIndentId: o.indentid));
        if (created == true) c.loadList();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(o.indentno.isEmpty ? '(no indent no)' : o.indentno,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _kBg, borderRadius: BorderRadius.circular(6)),
              child: Text('#${o.indentid}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kTextSecondary)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _meta(Icons.person_outline_rounded, o.reqby),
            const SizedBox(width: 14),
            _meta(Icons.event_outlined, o.createdate),
          ]),
          if (o.requestto.trim().isNotEmpty || o.plant.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (o.requestto.trim().isNotEmpty)
                _meta(Icons.store_outlined, o.requestto),
              if (o.plant.trim().isNotEmpty) ...[
                const SizedBox(width: 14),
                _meta(Icons.factory_outlined, o.plant),
              ],
            ]),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: _kBorder),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('INDENT QTY',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _kTextSecondary,
                      letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(_qty(o.totalqty),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary)),
            ]),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: _kPrimary, borderRadius: BorderRadius.circular(9)),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Text('Create PO',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(width: 5),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: Colors.white),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Flexible(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: _kTextSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, color: _kTextSecondary)),
          ),
        ]),
      );
}
