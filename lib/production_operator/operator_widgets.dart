// Widgets shared by the Production — Operator screens: KPI tiles, job cards,
// stage / status pills, progress bars, photo strip, buttons. Styled like the
// Visit / Bin screens (white cards, E2E8F0 borders, 5B6CF6 accent) with the
// operator mockup's green / amber / red / purple semantic tones.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:newdigitalerp/l10n/app_lang.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:newdigitalerp/utils/attachment_picker.dart';

import 'operator_controller.dart';
import 'operator_models.dart';

const opBg = Color(0xFFF5F6FC);
const opPrimary = Color(0xFF5B6CF6);
const opPrimary2 = Color(0xFF7B83FF);
const opGreen = Color(0xFF12A150);
const opGreenBg = Color(0xFFE7F7EE);
const opAmber = Color(0xFFE5890A);
const opAmberBg = Color(0xFFFDF1DD);
const opBlue = Color(0xFF2F6FED);
const opBlueBg = Color(0xFFE7EFFD);
const opPurple = Color(0xFF7C5CFF);
const opPurpleBg = Color(0xFFEFEAFF);
const opRed = Color(0xFFE5484D);
const opRedBg = Color(0xFFFDECEC);

const opGradient = LinearGradient(
  colors: [opPrimary, opPrimary2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
const opGreenGradient = LinearGradient(
  colors: [opGreen, Color(0xFF34C07D)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);
// Sending work backwards is not the green "forward" action — amber marks it
// as an exception everywhere it appears.
const opAmberGradient = LinearGradient(
  colors: [Color(0xFFC2410C), opAmber],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Stable colour per stage name (CARPANTRY brown, PAINT blue, …).
Color stageColor(String stage) {
  switch (stage.trim().toUpperCase()) {
    case 'CARPANTRY':
    case 'CARPENTRY':
      return const Color(0xFFB06A3B);
    case 'PAINT':
      return opBlue;
    case 'METAL':
      return const Color(0xFF64748B);
    case 'UPHOLSTRY':
    case 'UPHOLSTERY':
      return opPurple;
    case 'STONE':
      return const Color(0xFF0D9488);
    case 'GLASS':
      return const Color(0xFF0EA5E9);
    case 'ASSEBMLY':
    case 'ASSEMBLY':
      return opGreen;
  }
  const palette = [opBlue, opPurple, opGreen, opAmber, Color(0xFF0D9488)];
  return palette[stage.hashCode.abs() % palette.length];
}

BoxDecoration opCard({Color? border, double radius = 15}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border ?? newBorderColor),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF281E6E).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ],
);

class StagePill extends StatelessWidget {
  final String stage;
  const StagePill(this.stage, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = stageColor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            stage.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class SoftPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const SoftPill(this.text, {super.key, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// "To produce" / "Running" / "Awaiting QC" / "Done" / "Rework".
Widget jobStatePill(OperatorJob j) {
  if (j.isRework && !j.isDone) {
    return SoftPill('Rework'.tr, color: opRed, bg: opRedBg);
  }
  // A joining stage short of parts: it cannot start, whatever the balance
  // says, so this outranks To produce / Running.
  if (j.isWaitingForParts) {
    return SoftPill('Waiting for parts'.tr, color: opAmber, bg: opAmberBg);
  }
  switch (j.state) {
    case OperatorJobState.done:
      return SoftPill('Done'.tr, color: opGreen, bg: opGreenBg);
    case OperatorJobState.running:
      return SoftPill('Running'.tr, color: opBlue, bg: opBlueBg);
    case OperatorJobState.pending:
      return const SoftPill('To produce', color: opAmber, bg: opAmberBg);
  }
}

/// KPI tile: icon square + big number + label (dashboard 2×2 grid).
class KpiTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String value;
  final String label;
  final VoidCallback? onTap;
  const KpiTile({
    super.key,
    required this.icon,
    required this.color,
    required this.bg,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(11),
      decoration: opCard(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
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

/// Compact 3-up stat (My Work / QC headers).
class StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? color;
  const StatBox({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
    decoration: opCard(radius: 13),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color ?? newTextPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: newTextSecondary,
          ),
        ),
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final String? trailing;
  final VoidCallback? onTrailing;
  const SectionHeader(
    this.title, {
    super.key,
    this.count,
    this.trailing,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(3, 15, 3, 9),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: newTextPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: newBorderColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: newTextSecondary,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailing,
            child: Text(
              trailing!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: onTrailing == null ? newTextSecondary : opPrimary,
              ),
            ),
          ),
      ],
    ),
  );
}

class ThinBar extends StatelessWidget {
  final double pct; // 0..1
  final Color color;
  final double height;
  final Gradient? gradient;
  const ThinBar(
    this.pct, {
    super.key,
    this.color = opBlue,
    this.height = 6,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: SizedBox(
      height: height,
      child: Stack(
        children: [
          Container(color: newBorderColor),
          FractionallySizedBox(
            widthFactor: pct.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: gradient == null ? color : null,
                gradient: gradient,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Job card used on Home + My Work. `primaryLabel` drives the CTA text
/// (Start / Continue / Do QC …).
class JobCard extends StatelessWidget {
  final OperatorJob job;
  final VoidCallback onTap;
  final String? ctaLabel;
  final Color? ctaColor;
  final VoidCallback? onCta;
  final bool highlight;
  final bool showParty;

  /// Fraction 0..1 that also counts work inside unfinished pieces (a piece
  /// at 60% never shows as 0). Falls back to produced/issued when null.
  final double? fraction;

  /// e.g. "1 pc at 60%" — shown next to the qty line.
  final String wipNote;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    this.ctaLabel,
    this.ctaColor,
    this.onCta,
    this.highlight = false,
    this.showParty = true,
    this.fraction,
    this.wipNote = '',
  });

  @override
  Widget build(BuildContext context) {
    final j = job;
    final pct =
        fraction ?? (j.issuedqty <= 0 ? 0.0 : j.producedqty / j.issuedqty);
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: opCard(
          border: highlight ? opPrimary.withValues(alpha: 0.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    j.itemname,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: opPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  StagePill(j.stagename),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (j.challanno.isNotEmpty) j.challanno,
                if (j.boqno.isNotEmpty) j.boqno,
                if (showParty && j.partyname.isNotEmpty) j.partyname,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),
            if (highlight) ...[
              const SizedBox(height: 7),
              StagePill(j.stagename),
            ],
            // Pieces this stage sent back to an earlier one and has not got
            // returned. They are already out of balanceqty, so without this
            // the job simply looks smaller than the operator remembers.
            if (j.hasSentBack) ...[
              const SizedBox(height: 6),
              SoftPill(
                '${fmtQty(j.sentbackqty)} sent back',
                color: opAmber,
                bg: opAmberBg,
              ),
            ],
            // The parts this stage makes or receives — one line, written
            // by the server so the wording stays in step with tracking.
            if (j.subitemstext.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 12,
                    color: newTextHint,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      j.subitemstext,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: newTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            // What each earlier stage has handed over. Grey dashed = still
            // missing, which is what holds this stage up.
            if (j.parts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'PARTS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: newTextSecondary,
                    ),
                  ),
                  for (final p in j.parts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.arrived ? opGreenBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: p.arrived ? opGreenBg : newTextHint,
                          style: p.arrived
                              ? BorderStyle.solid
                              : BorderStyle.none,
                        ),
                      ),
                      child: Text(
                        '${p.stagename} ${fmtQty(p.qty)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: p.arrived ? opGreen : newTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            // Approved drawings / client materials exist for this item —
            // the job screen shows them under "Drawings & Details".
            if (j.hasdesign && j.designChipLabel.isNotEmpty) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: opBlueBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.architecture_outlined,
                      size: 11,
                      color: opBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      j.designChipLabel,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: opBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 9),
            ThinBar(
              j.isQcJob
                  ? (j.producedqty <= 0
                        ? 0
                        : (j.qcqty + j.rejectqty) / j.producedqty)
                  : pct,
              color: j.isQcJob ? opPurple : (j.isDone ? opGreen : opBlue),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: newTextSecondary,
                      ),
                      children: j.isQcJob
                          // QC assignment: the lot to check, not production.
                          ? [
                              TextSpan(
                                text: '${fmtQty(j.qcPending)} to check',
                                style: const TextStyle(color: opPurple),
                              ),
                              TextSpan(
                                text:
                                    ' · passed ${fmtQty(j.qcqty)} · rejected ${fmtQty(j.rejectqty)}',
                              ),
                            ]
                          : [
                              TextSpan(
                                text: fmtQty(j.producedqty),
                                style: const TextStyle(color: newTextPrimary),
                              ),
                              TextSpan(text: '/${fmtQty(j.issuedqty)}'),
                              if (j.balanceqty > 0)
                                TextSpan(
                                  text: ' · ${fmtQty(j.balanceqty)} left',
                                ),
                              if (wipNote.isNotEmpty)
                                TextSpan(
                                  text: ' · $wipNote',
                                  style: const TextStyle(color: opBlue),
                                ),
                              if (j.qcPending > 0)
                                TextSpan(
                                  text: ' · QC ${fmtQty(j.qcPending)}',
                                  style: const TextStyle(color: opPurple),
                                ),
                            ],
                    ),
                  ),
                ),
                if (ctaLabel != null)
                  SmallButton(
                    ctaLabel!,
                    color: ctaColor ?? opPrimary,
                    onTap: onCta ?? onTap,
                    filled: ctaColor != null,
                  )
                else
                  jobStatePill(j),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;
  const SmallButton(
    this.label, {
    super.key,
    required this.color,
    required this.onTap,
    this.filled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(9),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color : opBg,
        borderRadius: BorderRadius.circular(9),
        border: filled ? null : Border.all(color: newBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.white : color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Full-width CTA (Save progress / Save QC / Issue …).
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool busy;
  const BigButton(
    this.label, {
    super.key,
    this.icon,
    required this.onTap,
    this.gradient,
    this.color,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || busy;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: disabled ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: color == null ? (gradient ?? opGradient) : null,
            color: color,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 15, color: Colors.white),
              if (busy || icon != null) const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5, left: 1),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 8.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: newTextSecondary,
      ),
    ),
  );
}

InputDecoration opInput({String? hint, Widget? suffix}) => InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 12.5, color: newTextHint),
  filled: true,
  fillColor: newSurfaceColor,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
  suffixIcon: suffix,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: newBorderColor),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: newBorderColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: opPrimary, width: 1.4),
  ),
);

/// Read-only value box (date / stage that the user cannot edit).
class ValueBox extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  const ValueBox(this.text, {super.key, this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: newSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color ?? newBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color ?? newTextPrimary,
              ),
            ),
          ),
          if (icon != null) Icon(icon, size: 14, color: newTextHint),
        ],
      ),
    ),
  );
}

/// Dashed "add a photo" square + thumbnails of what's picked.
class PhotoStrip extends StatelessWidget {
  final List<PickedAttachment> photos;
  final VoidCallback onAdd;
  final void Function(PickedAttachment) onRemove;
  final String hint;
  final Color accent;
  const PhotoStrip({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.hint = 'Add a photo (optional)',
    this.accent = opPrimary,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onAdd,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Icon(Icons.photo_camera_outlined, color: accent, size: 18),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: photos.isEmpty
            ? Text(
                hint,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: newTextHint,
                ),
              )
            : SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: photos
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(p.path),
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 42,
                                    height: 42,
                                    color: newBorderColor,
                                    child: const Icon(
                                      Icons.image,
                                      size: 18,
                                      color: newTextHint,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => onRemove(p),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    ],
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: newBlueLightColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: opPrimary, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: newTextPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: newTextSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 14),
            SmallButton(action!, color: opPrimary, onTap: onAction ?? () {}),
          ],
        ],
      ),
    ),
  );
}

/// Shown at the top of every tab while the mock repo is active.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: opAmberBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: opAmber.withValues(alpha: 0.35)),
    ),
    child: const Row(
      children: [
        Icon(Icons.science_outlined, size: 15, color: opAmber),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Demo data — no jobs are issued to your login yet. Entries here are not saved to the ERP.',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A5A00),
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Dashed hint box ("Ramesh sees only Carpantry of this item…").
class HintBox extends StatelessWidget {
  final List<InlineSpan> spans;
  const HintBox(this.spans, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: newBorderColor),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: newTextSecondary,
          height: 1.5,
        ),
        children: spans,
      ),
    ),
  );
}

const hintBold = TextStyle(color: newTextPrimary, fontWeight: FontWeight.w800);

// ── Gradient header shared by Home / My Work / QC ────────────────────────────

/// Gradient header used by the My Jobs tabs and the Quality Check module.
/// [tag] picks the controller whose refresh button + spinner it drives.
class OperatorHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String avatarLetter;
  final Gradient gradient;
  final bool showDate;
  final String? tag;
  const OperatorHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.avatarLetter,
    this.gradient = opGradient,
    this.showDate = false,
    this.tag,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(gradient: gradient),
    padding: EdgeInsets.fromLTRB(
      14,
      MediaQuery.of(context).padding.top + 8,
      14,
      16,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.34),
                  width: 2,
                ),
              ),
              child: Text(
                avatarLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GetBuilder<OperatorController>(
              tag: tag,
              builder: (c) => InkWell(
                onTap: c.jobsLoading ? null : c.loadJobs,
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: c.jobsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
        if (showDate) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                // No locale argument on purpose — see [AppLang]. Naming one
                // needs initializeDateFormatting() for that locale, and
                // without it DateFormat throws LocaleDataException on every
                // build. The default is English, which is what we want.
                DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // The language switch lives here because this header is the
              // first thing on the operator's home screen — a worker who
              // cannot read the app must not have to hunt through settings.
              if (AppConst.offerHindi) ...[
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: AppLang.toggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.translate_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          AppLang.isHindi ? 'English' : 'हिन्दी',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    ),
  );
}

/// Rework job card (My Work / Home): REWORK badge, Issued · Produced ·
/// Passed · Rework tiles, "N pcs to re-produce" banner and a Re-produce CTA.
class ReworkJobCard extends StatelessWidget {
  final OperatorJob job;
  final VoidCallback onTap;
  const ReworkJobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final j = job;
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
                    '${j.challanno.isNotEmpty ? '${j.challanno} · ' : ''}${j.itemname}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: newTextPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: opAmberBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: opAmber.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'REWORK',
                    style: TextStyle(
                      color: Color(0xFF8A5A00),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (j.boqno.isNotEmpty)
                  SoftPill(j.boqno, color: opBlue, bg: opBlueBg),
                StagePill(j.stagename),
                if (j.partyname.isNotEmpty)
                  SoftPill(
                    j.partyname,
                    color: newTextSecondary,
                    bg: lightGreyColor,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _mini(fmtQty(j.issuedqty), 'Issued'.tr),
                _mini(fmtQty(j.producedqty), 'Produced'.tr),
                _mini(
                  fmtQty(j.qcqty),
                  'Passed'.tr,
                  color: j.qcqty > 0 ? opGreen : null,
                ),
                _mini(fmtQty(j.reworkQty), 'Rework'.tr, color: opAmber),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: opAmberBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: opAmber.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.replay_rounded, size: 14, color: opAmber),
                  const SizedBox(width: 7),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A5A00),
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: '${fmtQty(j.reworkQty)} pcs to re-produce',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: j.rejectreason.isNotEmpty
                                ? '\nReopened from QC · ${j.rejectreason}'
                                : '\nReopened from QC',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            BigButton('Re-produce  →', color: opAmber, onTap: onTap),
          ],
        ),
      ),
    );
  }

  Widget _mini(String v, String k, {Color? color}) => Expanded(
    child: Column(
      children: [
        Text(
          v,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? newTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          k.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: newTextSecondary,
          ),
        ),
      ],
    ),
  );
}

/// Keyboard entry for a piece count — for lots too big to tap out one by
/// one (500 pcs). Numeric keypad, quick +10/+50/+100 and "All" chips,
/// clamped to [0, max]. Returns the qty, or null when cancelled.
Future<int?> askQtyDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  required int current,
  required int max,
  String unit = 'pcs',
}) async {
  final ctrl = TextEditingController(text: current > 0 ? '$current' : '');
  ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
  int val() => int.tryParse(ctrl.text.trim()) ?? 0;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) {
        final v = val();
        final over = v > max;
        void setV(int n) => setD(() {
          ctrl.text = '${n.clamp(0, max)}';
          ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        });
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null) ...[
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
                decoration: opInput(hint: '0').copyWith(
                  suffixText: '/ $max $unit',
                  suffixStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: newTextSecondary,
                  ),
                  errorText: over ? 'Max $max $unit' : null,
                ),
                onChanged: (_) => setD(() {}),
                onSubmitted: (_) {
                  if (!over) Navigator.of(ctx).pop(v);
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final step in [10, 50, 100])
                    if (step <= max)
                      ActionChip(
                        label: Text(
                          '+$step',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: () => setV(v + step),
                      ),
                  ActionChip(
                    label: Text(
                      'All · $max',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: opPrimary,
                      ),
                    ),
                    backgroundColor: newBlueLightColor,
                    onPressed: () => setV(max),
                  ),
                  if (v > 0)
                    ActionChip(
                      label: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: opRed,
                        ),
                      ),
                      onPressed: () => setV(0),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel'.tr),
            ),
            FilledButton(
              onPressed: over ? null : () => Navigator.of(ctx).pop(v),
              style: FilledButton.styleFrom(backgroundColor: opPrimary),
              child: const Text('OK'),
            ),
          ],
        );
      },
    ),
  );
}

/// Caps a numeric field at [max] as it is typed: a bigger number is snapped
/// back to [max] instead of being accepted and rejected on save. Used for
/// "Qty to issue", which can never exceed the QC-passed qty still available.
class MaxQtyFormatter extends TextInputFormatter {
  final double max;
  const MaxQtyFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text.trim();
    if (t.isEmpty) return newValue;
    final v = double.tryParse(t);
    if (v == null) return oldValue; // letters / stray characters
    if (v <= max) return newValue;
    final capped = fmtQty(max);
    return TextEditingValue(
      text: capped,
      selection: TextSelection.collapsed(offset: capped.length),
    );
  }
}

// ── Snackbar ────────────────────────────────────────────────────────────────

enum OpSnackKind { success, error, warning, info }

/// Tone inferred from the title, so call sites stay one-liners:
/// "Not saved" / "…failed" → error, "Check …" / "… required" → warning,
/// "Saved" / "Issued" / "Received" → success, anything else → info.
OpSnackKind _kindFromTitle(String title) {
  final t = title.toLowerCase();
  if (t.contains('not ') ||
      t.contains('failed') ||
      t.contains('error') ||
      t.contains('could not')) {
    return OpSnackKind.error;
  }
  if (t.startsWith('check') ||
      t.contains('required') ||
      t.startsWith('nothing') ||
      t.contains('reason') ||
      t.contains('name')) {
    return OpSnackKind.warning;
  }
  if (t.contains('saved') ||
      t.contains('issued') ||
      t.contains('received') ||
      t.contains('accepted') ||
      t.contains('recorded') ||
      t.contains('done')) {
    return OpSnackKind.success;
  }
  return OpSnackKind.info;
}

/// Shop-floor snackbar: a floating white card with a coloured icon chip,
/// bold title and message. Replaces the plain black bar — readable at arm's
/// length, and never stacks (a new one replaces the one on screen).
void opSnack(String title, String message, {OpSnackKind? kind}) {
  final k = kind ?? _kindFromTitle(title);
  final (Color color, IconData icon) = switch (k) {
    OpSnackKind.success => (opGreen, Icons.check_circle_rounded),
    OpSnackKind.error => (opRed, Icons.error_outline_rounded),
    OpSnackKind.warning => (opAmber, Icons.warning_amber_rounded),
    OpSnackKind.info => (opPrimary, Icons.info_outline_rounded),
  };
  final text = message.trim();
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  Get.showSnackbar(
    GetSnackBar(
      snackPosition: SnackPosition.BOTTOM,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      borderRadius: 14,
      backgroundColor: Colors.white,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.13),
          blurRadius: 22,
          offset: const Offset(0, 6),
        ),
      ],
      padding: const EdgeInsets.all(13),
      duration: Duration(milliseconds: text.length > 70 ? 4200 : 3000),
      animationDuration: const Duration(milliseconds: 260),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      messageText: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                    height: 1.25,
                  ),
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: newTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
