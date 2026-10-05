// The send back card: one leg of a return standing at this stage.

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import 'operator_models.dart';
import 'operator_widgets.dart';

/// One leg of a send back, as it stands at THIS stage.
///
/// It is deliberately not a [JobCard]: the numbers on a send back row mean
/// different things (`balanceqty` is "to rework here", not "to produce") and
/// the actions come from the numbers rather than from `status` — one leg can
/// have pieces to rework AND pieces ready to send on at the same time, which
/// no single status word can express.
class SendBackJobCard extends StatelessWidget {
  final OperatorJob job;
  final VoidCallback onTap;

  /// Rework / QC / Send on. Null hides that button.
  final VoidCallback? onRework;
  final VoidCallback? onQc;
  final VoidCallback? onSendOn;

  const SendBackJobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.onRework,
    this.onQc,
    this.onSendOn,
  });

  @override
  Widget build(BuildContext context) {
    final j = job;
    final what = j.partname.isEmpty ? j.itemname : j.partname;
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: opCard(border: opAmber.withValues(alpha: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    what,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SoftPill('SENT BACK', color: opAmber, bg: opAmberBg),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (j.challanno.isNotEmpty) j.challanno,
                if (j.partname.isNotEmpty) j.itemname,
                if (j.partyname.isNotEmpty) j.partyname,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),

            // Where it came from and where it goes after the fix. The whole
            // way is server-written so it stays in step with tracking.
            if (j.returnway.isNotEmpty || j.returnfromstage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: opAmberBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: opAmber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.keyboard_return_rounded,
                          size: 13,
                          color: Color(0xFF8A4B06),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            j.returnway.isNotEmpty
                                ? j.returnway
                                : 'Back to ${j.returnfromstage}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8A4B06),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (j.returnwherenow.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        j.returnwherenow,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A4B06),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Why it came back, and whose work was faulty — the fix stage
            // and the stage at fault are not always the same.
            if (j.rejectreason.isNotEmpty || j.faultstage.isNotEmpty) ...[
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 12,
                    color: newTextHint,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      [
                        if (j.rejectreason.isNotEmpty) j.rejectreason,
                        if (j.faultstage.isNotEmpty) 'Fault: ${j.faultstage}',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: newTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 9),
            _counts(j),

            if (onRework != null || onQc != null || onSendOn != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onRework != null)
                    _action(
                      'Rework ${fmtQty(j.balanceqty)}',
                      Icons.build_rounded,
                      opAmber,
                      onRework!,
                    ),
                  if (onQc != null)
                    _action(
                      'QC ${fmtQty(j.canqcqty)}',
                      Icons.verified_outlined,
                      opPurple,
                      onQc!,
                    ),
                  if (onSendOn != null)
                    _action(
                      'Send ${fmtQty(j.cansendqty)} → ${j.returnnextstage}',
                      Icons.local_shipping_outlined,
                      opGreen,
                      onSendOn!,
                    ),
                ],
              ),
            ] else if (j.awaitingQcHere) ...[
              const SizedBox(height: 9),
              const Text(
                'Reworked — waiting for QC on their own login.',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: newTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Here · to rework · waiting for QC · ready to send. Only the figures the
  /// server actually sent are drawn, so an older build shows fewer, not zeros.
  Widget _counts(OperatorJob j) => Wrap(
    spacing: 14,
    runSpacing: 6,
    children: [
      _stat('Here', j.issuedqty),
      if (j.balanceqty > 0) _stat('To rework', j.balanceqty),
      if (j.canqcqty > 0) _stat('For QC', j.canqcqty),
      if (j.cansendqty > 0) _stat('To send', j.cansendqty),
      if (j.returnopenqty > 0) _stat('Still out', j.returnopenqty),
    ],
  );

  Widget _stat(String label, double v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: newTextSecondary,
        ),
      ),
      Text(
        fmtQty(v),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: newTextPrimary,
        ),
      ),
    ],
  );

  Widget _action(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}
