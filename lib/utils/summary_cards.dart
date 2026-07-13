// Shared "reimbursement-style" summary cards used across list screens (MRN, GRN,
// Indent, Lead, Payment Request, MRN QC, …). A white rounded card with a soft
// shadow, a coloured value pill, and a label — rendered as an even row.
//
// Usage:
//   SummaryCards([
//     SummaryStat('$total',   'Total',    newBlueColor,   newBlueLightColor),
//     SummaryStat('$pending', 'Pending',  newOrangeColor, newOrangeLightColor),
//     SummaryStat('$approved','Approved', newGreenColor,  newGreenLightColor),
//   ]),

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

class SummaryStat {
  final String value;
  final String label;
  final Color fg; // value text colour
  final Color bg; // value pill background
  const SummaryStat(this.value, this.label, this.fg, this.bg);
}

/// Compact Indian-currency label for the amount card (₹1.2K / ₹3.4L / ₹5.6Cr).
String compactInr(double v, [String sym = '₹']) {
  if (v >= 10000000) return '$sym${(v / 10000000).toStringAsFixed(1)}Cr';
  if (v >= 100000) return '$sym${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '$sym${(v / 1000).toStringAsFixed(1)}K';
  return '$sym${v.toStringAsFixed(0)}';
}

class SummaryCards extends StatelessWidget {
  final List<SummaryStat> stats;
  final EdgeInsets padding;
  const SummaryCards(
    this.stats, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 2),
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 10));
      children.add(_card(stats[i]));
    }
    return Padding(padding: padding, child: Row(children: children));
  }

  Widget _card(SummaryStat s) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: s.fg),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),
          ]),
        ),
      );
}
