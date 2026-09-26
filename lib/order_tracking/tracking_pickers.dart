// Order / item picker sheet (mockup screen 2): searchable order list on top,
// the selected order's items underneath.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'tracking_controller.dart';
import 'tracking_models.dart';
import 'tracking_widgets.dart';

Future<void> showOrderPicker(BuildContext context, TrackingController c) {
  final searchCtrl = TextEditingController();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setS) {
        final q = searchCtrl.text.trim().toLowerCase();
        final list = q.isEmpty
            ? c.orders
            : c.orders
                  .where(
                    (o) =>
                        o.orderno.toLowerCase().contains(q) ||
                        o.partyname.toLowerCase().contains(q),
                  )
                  .toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.94,
          builder: (_, scroll) => Container(
            decoration: const BoxDecoration(
              color: trkBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DBEA),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: trkVioletBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.home_work_outlined,
                          size: 18,
                          color: trkViolet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Select order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: trkInk,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: trkGray),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setS(() {}),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search order no. or party',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: newTextHint,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8EAF4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8EAF4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: trkViolet),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GetBuilder<TrackingController>(
                    builder: (ctrl) => ListView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      children: [
                        const _SheetLabel('Orders in production'),
                        if (list.isEmpty)
                          const TrkEmpty(
                            icon: Icons.inbox_outlined,
                            title: 'No orders match that search.',
                          ),
                        ...list.map(
                          (o) => _OrderTile(
                            order: o,
                            selected: ctrl.order?.orderid == o.orderid,
                            onTap: () => ctrl.selectOrder(o),
                          ),
                        ),
                        if (ctrl.items.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _SheetLabel(
                            'Items in ${ctrl.order?.orderno ?? 'this order'}',
                          ),
                          Container(
                            decoration: trkCard(),
                            child: Column(
                              children: [
                                for (var i = 0; i < ctrl.items.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: Color(0xFFEDEEF7),
                                    ),
                                  _ItemTile(
                                    item: ctrl.items[i],
                                    selected:
                                        ctrl.item?.key == ctrl.items[i].key,
                                    onTap: () {
                                      ctrl.selectItem(ctrl.items[i]);
                                      Navigator.of(ctx).pop();
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: trkGray,
      ),
    ),
  );
}

class _OrderTile extends StatelessWidget {
  final TrackOrder order;
  final bool selected;
  final VoidCallback onTap;
  const _OrderTile({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: trkCard(border: selected ? trkViolet : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.orderno,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: trkInk,
                  ),
                ),
              ),
              if (order.overdue)
                const TrkPill('Overdue', fg: trkRed, bg: trkRedBg),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            order.partyname,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TrkBar(
                  pct: (order.fraction * 100).round(),
                  color: trkViolet,
                  height: 7,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${order.items} item${order.items == 1 ? '' : 's'} · '
                '${_n(order.produced)} / ${_n(order.ordered)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: newTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ItemTile extends StatelessWidget {
  final TrackItem item;
  final bool selected;
  final VoidCallback onTap;
  const _ItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemname,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: trkInk,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (item.itemcode.isNotEmpty) item.itemcode,
                    'prod ${_n(item.produced)}',
                    'QC ${_n(item.qcd)}',
                    if (item.rejected > 0) 'rej ${_n(item.rejected)}',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_rounded, color: trkViolet, size: 20),
        ],
      ),
    ),
  );
}

String _n(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
