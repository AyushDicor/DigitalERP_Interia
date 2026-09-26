// ---------------------------------------------------------------------------
// Display-only attendance insights (light mode) — ported from the experiment
// app's "Aurora" module but re-skinned to a light palette and made fully
// self-contained (no shared theme).
//
// Everything here is derived from the `details` list the attendance summary API
// already returns. No requests, no controller state, no writes — if the data
// can't be parsed the insight simply doesn't render.
//
// Drop `AttendanceInsightsCard(details)` into the attendance screen; it renders
// a "This Month" card with a day-streak badge, worked hours, typical start, a
// live on-the-clock timer, and a month heatmap. Returns nothing when there's
// no parseable data.
// ---------------------------------------------------------------------------
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:newdigitalerp/response/attendance_summary_response.dart';

// -- Light palette (scoped to these widgets) --------------------------------
const Color _ink = Color(0xFF1E293B);
const Color _muted = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _card = Colors.white;
const Color _green = Color(0xFF16A34A);
const Color _amber = Color(0xFFD97706);
const Color _red = Color(0xFFDC2626);
const Color _purple = Color(0xFF5B6CF6);
const Color _cyan = Color(0xFF0891B2);

enum DayStatus { present, active, absent, weekend, future }

class AttendanceInsights {
  final int streak;
  final Duration worked;
  final int? averageCheckInMinutes;
  final DateTime? activeSince;
  final Map<int, DayStatus> byDay;
  final int year;
  final int month;
  final int siteCount;

  const AttendanceInsights._({
    required this.streak,
    required this.worked,
    required this.averageCheckInMinutes,
    required this.activeSince,
    required this.byDay,
    required this.year,
    required this.month,
    required this.siteCount,
  });

  static const empty = AttendanceInsights._(
    streak: 0,
    worked: Duration.zero,
    averageCheckInMinutes: null,
    activeSince: null,
    byDay: {},
    year: 0,
    month: 0,
    siteCount: 0,
  );

  bool get hasData => byDay.isNotEmpty;

  /// Builds every insight in a single pass. Never throws: any record that
  /// cannot be parsed is skipped.
  factory AttendanceInsights.from(List<DayDetails>? details) {
    if (details == null || details.isEmpty) return empty;

    final records = <DateTime, DayDetails>{};
    for (final d in details) {
      final day = _parseDate(d.date);
      if (day != null) records[day] = d;
    }
    if (records.isEmpty) return empty;

    final dates = records.keys.toList()..sort();
    final latest = dates.last;

    var totalMinutes = 0;
    final checkIns = <int>[];
    final sites = <String>{};
    DateTime? activeSince;

    records.forEach((day, rec) {
      final inAt = _parseTime(rec.inTime);
      final outAt = _parseTime(rec.outTime);
      if (inAt != null) {
        checkIns.add(inAt);
        if (outAt != null && outAt > inAt) {
          totalMinutes += outAt - inAt;
        } else if (outAt == null && day == latest) {
          activeSince =
              DateTime(day.year, day.month, day.day, inAt ~/ 60, inAt % 60);
        }
      }
      final loc = (rec.location ?? '').trim();
      if (loc.isNotEmpty) sites.add(loc);
    });

    final year = latest.year;
    final month = latest.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final byDay = <int, DayStatus>{};

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final rec = records[date];
      if (rec != null) {
        byDay[d] = (rec.outTime == null || rec.outTime!.isEmpty)
            ? DayStatus.active
            : DayStatus.present;
      } else if (date.isAfter(latest)) {
        byDay[d] = DayStatus.future;
      } else if (_isWeekend(date)) {
        byDay[d] = DayStatus.weekend;
      } else {
        byDay[d] = DayStatus.absent;
      }
    }

    // Streak: walk back from the newest record. A weekend with no punch is
    // skipped rather than treated as a break; a missed working day ends it.
    var streak = 0;
    var cursor = latest;
    while (true) {
      if (records.containsKey(cursor)) {
        streak++;
      } else if (!_isWeekend(cursor)) {
        break;
      }
      final next = cursor.subtract(const Duration(days: 1));
      if (next.month != month || next.year != year) break;
      cursor = next;
    }

    return AttendanceInsights._(
      streak: streak,
      worked: Duration(minutes: totalMinutes),
      averageCheckInMinutes: checkIns.isEmpty
          ? null
          : (checkIns.reduce((a, b) => a + b) / checkIns.length).round(),
      activeSince: activeSince,
      byDay: byDay,
      year: year,
      month: month,
      siteCount: sites.length,
    );
  }

  static bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  static DateTime? _parseDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    try {
      final d = DateFormat('dd-MM-yyyy').parseStrict(value);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }

  /// Minutes since midnight, or null when unparseable.
  static int? _parseTime(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    for (final pattern in const ['hh:mm a', 'h:mm a', 'HH:mm']) {
      try {
        final t = DateFormat(pattern).parse(value);
        return t.hour * 60 + t.minute;
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}

String _formatHm(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}

String _formatMinutesOfDay(int minutes) {
  final h24 = minutes ~/ 60;
  final m = (minutes % 60).toString().padLeft(2, '0');
  final ampm = h24 >= 12 ? 'PM' : 'AM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:$m $ampm';
}

// ── Attendance-rate ring ────────────────────────────────────────────────────
/// Animated circular attendance-rate gauge (present / present+absent) with the
/// percentage and present/total in the centre. Light-mode port of the
/// experiment's punch-card ring.
class AttendanceRateRing extends StatelessWidget {
  final int present;
  final int absent;
  final double size;
  const AttendanceRateRing({
    super.key,
    required this.present,
    required this.absent,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    final total = present + absent;
    final rate = total == 0 ? 0.0 : present / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: rate),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(value * 100).round()}%',
                  style: const TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      fontFeatures: [FontFeature.tabularFigures()])),
              Text(total == 0 ? 'no data' : '$present / $total',
                  style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - 11) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = _border;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = const SweepGradient(
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [_purple, _cyan, _green, _purple],
      transform: GradientRotation(-math.pi / 2),
    ).createShader(rect);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ── Public card ────────────────────────────────────────────────────────────
/// The whole "This Month" insights card. Renders nothing when there's no
/// parseable attendance data, so it's safe to always include.
class AttendanceInsightsCard extends StatelessWidget {
  final List<DayDetails>? details;
  const AttendanceInsightsCard(this.details, {super.key});

  @override
  Widget build(BuildContext context) {
    final insights = AttendanceInsights.from(details);
    if (!insights.hasData) return const SizedBox.shrink();
    final avg = insights.averageCheckInMinutes;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.calendar_month_rounded, size: 16, color: _purple),
          SizedBox(width: 6),
          Text('This Month',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _ink)),
          Spacer(),
          Text('Your rhythm at a glance',
              style: TextStyle(fontSize: 10.5, color: _muted)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _StreakBadge(insights.streak),
          const Spacer(),
          _Stat('Worked', _formatHm(insights.worked), _cyan),
          const SizedBox(width: 18),
          _Stat('Usual in', avg == null ? '—' : _formatMinutesOfDay(avg),
              _purple),
        ]),
        if (insights.activeSince != null) ...[
          const SizedBox(height: 14),
          _OnTheClock(insights.activeSince!),
        ],
        const SizedBox(height: 14),
        Container(height: 1, color: _border),
        const SizedBox(height: 14),
        _MonthHeatmap(insights),
        const SizedBox(height: 12),
        const _HeatmapLegend(),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: _muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
        ],
      );
}

/// Flame badge for the current attendance streak.
class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge(this.streak);
  @override
  Widget build(BuildContext context) {
    final hot = streak >= 3;
    final color = hot ? _amber : _muted;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(hot ? '🔥' : '✨', style: const TextStyle(fontSize: 17)),
      const SizedBox(width: 7),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$streak',
              style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const Text('day streak',
              style: TextStyle(
                  color: _muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
        ],
      ),
    ]);
  }
}

/// Ticking elapsed time since the current check-in. Owns its own timer so the
/// per-second rebuild stays inside this widget.
class _OnTheClock extends StatefulWidget {
  final DateTime since;
  const _OnTheClock(this.since);
  @override
  State<_OnTheClock> createState() => _OnTheClockState();
}

class _OnTheClockState extends State<_OnTheClock> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = _since();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _since());
    });
  }

  Duration _since() {
    final d = DateTime.now().difference(widget.since);
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withValues(alpha: 0.28)),
      ),
      child: Row(children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: _amber, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        const Text('ON THE CLOCK',
            style: TextStyle(
                color: _amber,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5)),
        const Spacer(),
        Text('$h:$m:$s',
            style: const TextStyle(
                color: _amber,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontFeatures: [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

/// Month grid — one cell per day, coloured by status.
class _MonthHeatmap extends StatelessWidget {
  final AttendanceInsights insights;
  const _MonthHeatmap(this.insights);

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Color _fill(DayStatus s) {
    switch (s) {
      case DayStatus.present:
        return _green.withValues(alpha: 0.85);
      case DayStatus.active:
        return _amber.withValues(alpha: 0.9);
      case DayStatus.absent:
        return _red.withValues(alpha: 0.14);
      case DayStatus.weekend:
        return const Color(0xFFF1F5F9);
      case DayStatus.future:
        return const Color(0xFFF8FAFC);
    }
  }

  Color _inkFor(DayStatus s) {
    switch (s) {
      case DayStatus.present:
      case DayStatus.active:
        return Colors.white;
      case DayStatus.absent:
        return _red;
      case DayStatus.weekend:
        return _muted;
      case DayStatus.future:
        return const Color(0xFFCBD5E1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!insights.hasData) return const SizedBox.shrink();

    final firstWeekday = DateTime(insights.year, insights.month, 1).weekday;
    final cells = <Widget>[
      for (var i = 1; i < firstWeekday; i++) const SizedBox.shrink(),
      for (final entry in insights.byDay.entries) _cell(entry.key, entry.value),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final chunk = cells.sublist(i, (i + 7).clamp(0, cells.length));
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [
          for (var c = 0; c < 7; c++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: c < chunk.length
                    ? chunk[c]
                    : const AspectRatio(aspectRatio: 1),
              ),
            ),
        ]),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        for (final l in _weekdayLabels)
          Expanded(
            child: Center(
              child: Text(l,
                  style: const TextStyle(
                      color: _muted, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
      const SizedBox(height: 7),
      ...rows,
    ]);
  }

  Widget _cell(int day, DayStatus status) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: _fill(status),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text('$day',
            style: TextStyle(
                color: _inkFor(status),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ),
    );
  }
}

/// Colour key for the heatmap.
class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();
  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 14, runSpacing: 6, children: [
      _item('Present', _green.withValues(alpha: 0.85)),
      _item('On the clock', _amber.withValues(alpha: 0.9)),
      _item('Absent', _red.withValues(alpha: 0.14)),
      _item('Off day', const Color(0xFFF1F5F9)),
    ]);
  }

  Widget _item(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 9,
        height: 9,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              color: _muted, fontSize: 9.5, fontWeight: FontWeight.w600)),
    ]);
  }
}
