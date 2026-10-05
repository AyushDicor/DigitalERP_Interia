// Order Production Tracking — shared widgets and the colour mapping.
//
// The API sends a `tone` ("violet", "green", "red", "teal", "blue", "amber",
// "gray") and a pipeline `state` ("done" / "active" / "pending"); the exact
// hex values below come from the web page and the mockup, so the phone and
// the browser show the same colours.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

const trkBg = Color(0xFFF5F6FC);
const trkInk = Color(0xFF1A1E36);
const trkHeader = Color(0xFF1B2140);
const trkViolet = Color(0xFF4F3FD6);
const trkVioletBg = Color(0xFFEEEBFF);
const trkGreen = Color(0xFF0B7A3B);
const trkGreenBg = Color(0xFFE3F6EA);
const trkRed = Color(0xFFB42323);
const trkRedBg = Color(0xFFFDE6E6);
const trkTeal = Color(0xFF0B6E6E);
const trkTealBg = Color(0xFFDFF3F3);
const trkBlue = Color(0xFF2358C4);
const trkBlueBg = Color(0xFFE4EDFD);
const trkAmber = Color(0xFFE0A526);

/// Stage in rework — deliberately a deeper amber than [trkAmber] ("not
/// started"), so "being re-made" cannot be mistaken for "not begun".
const trkOrange = Color(0xFFE08A00);
const trkOrangeBg = Color(0xFFFDF1DD);
const trkOrangeText = Color(0xFFB36B00);
const trkGray = Color(0xFF4A5170);
const trkGrayBg = Color(0xFFF1F2F8);

/// ("violet" | "green" | …) → (text/icon colour, pill background).
({Color fg, Color bg}) toneColors(String tone) => switch (tone.toLowerCase()) {
  'violet' => (fg: trkViolet, bg: trkVioletBg),
  'green' => (fg: trkGreen, bg: trkGreenBg),
  'red' => (fg: trkRed, bg: trkRedBg),
  'teal' => (fg: trkTeal, bg: trkTealBg),
  'blue' => (fg: trkBlue, bg: trkBlueBg),
  'amber' => (fg: trkAmber, bg: trkOrangeBg),
  // "orange" = the stage has work to re-make (2026-09-25).
  'orange' => (fg: trkOrange, bg: trkOrangeBg),
  _ => (fg: trkGray, bg: trkGrayBg),
};

/// Icon per trail event — the label itself always comes from the API.
IconData eventIcon(String eventtype) => switch (eventtype) {
  'Produced' => Icons.bar_chart_rounded,
  'QC' => Icons.check_rounded,
  'Rejected' => Icons.close_rounded,
  'RejectedLoader' => Icons.close_rounded,
  'Issued' => Icons.send_rounded,
  'IssuedLoader' => Icons.send_rounded,
  'ReceivedLoader' => Icons.call_received_rounded,
  'Progress' => Icons.show_chart_rounded,
  _ => Icons.circle_outlined,
};

BoxDecoration trkCard({Color? border, double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: border ?? const Color(0xFFE8EAF4)),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF281E6E).withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ],
);

/// Dark header bar used on every tab.
class TrackHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? meta;
  final Widget? action;
  const TrackHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.meta,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: trkHeader,
    padding: EdgeInsets.fromLTRB(
      12,
      MediaQuery.of(context).padding.top + 10,
      12,
      14,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RoundBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
        if (meta != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  meta!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(11),
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: Colors.white, size: 19),
    ),
  );
}

/// KPI card: icon chip, big number, caption.
class KpiCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String value;
  final String caption;
  const KpiCard({
    super.key,
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: trkCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: trkGray,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: trkInk,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: newTextHint,
          ),
        ),
      ],
    ),
  );
}

/// The completion ring on the summary card.
class PctRing extends StatelessWidget {
  final int pct;
  final double size;
  const PctRing({super.key, required this.pct, this.size = 68});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: (pct / 100).clamp(0, 1),
            strokeWidth: 7,
            backgroundColor: const Color(0xFFEDEEF7),
            valueColor: const AlwaysStoppedAnimation(trkViolet),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            color: trkViolet,
          ),
        ),
      ],
    ),
  );
}

/// Small rounded pill (status, qty, "Overdue").
class TrkPill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final double size;

  /// Optional leading glyph — the lock on "Waiting for parts".
  final IconData? icon;
  const TrkPill(
    this.text, {
    super.key,
    required this.fg,
    required this.bg,
    this.size = 10,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(100),
    ),
    child: icon == null
        ? Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: size + 2, color: fg),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
  );
}

/// Round avatar with the API's initials.
class InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const InitialsAvatar(this.initials, {super.key, this.size = 26});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: trkVioletBg, shape: BoxShape.circle),
    child: Text(
      initials,
      style: TextStyle(
        fontSize: size * 0.38,
        fontWeight: FontWeight.w800,
        color: trkViolet,
      ),
    ),
  );
}

/// Horizontal completion bar. A value above 0 always shows a sliver of fill.
class TrkBar extends StatelessWidget {
  final int pct;
  final Color color;
  final double height;
  const TrkBar({
    super.key,
    required this.pct,
    required this.color,
    this.height = 9,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: LayoutBuilder(
      builder: (_, c) => Stack(
        children: [
          Container(height: height, color: const Color(0xFFEDEEF7)),
          Container(
            height: height,
            width: c.maxWidth * (pct.clamp(0, 100) / 100).clamp(0.04, 1.0),
            color: color,
          ),
        ],
      ),
    ),
  );
}

class TrkSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const TrkSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: trkInk,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class TrkEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const TrkEmpty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 40, color: newTextHint),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: trkInk,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
  );
}

// ── Snackbar (same look as the My Jobs one) ─────────────────────────────────

enum TrackSnackKind { success, error, info }

void trackSnack(
  String title,
  String message, {
  TrackSnackKind kind = TrackSnackKind.info,
}) {
  final (Color color, IconData icon) = switch (kind) {
    TrackSnackKind.success => (trkGreen, Icons.check_circle_rounded),
    TrackSnackKind.error => (trkRed, Icons.error_outline_rounded),
    TrackSnackKind.info => (trkViolet, Icons.info_outline_rounded),
  };
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
      duration: const Duration(seconds: 3),
      isDismissible: true,
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
                    color: trkInk,
                  ),
                ),
                if (message.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    message.trim(),
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
