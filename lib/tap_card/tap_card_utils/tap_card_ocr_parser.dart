// Turns the raw lines ML Kit reads off a business card into a best guess at
// name / title / company / phone / email / website.
//
// Ported unchanged from TapCard's CardTextParser. The heuristics matter: a
// business card has no structure, so each field is inferred from a different
// signal — layout (the name is usually the biggest text near the top), regex
// (email, phone, domain), and keyword lists (job titles, company suffixes).
// Everything here is a guess the user reviews on the form before saving.

import '../tap_card_models.dart';

/// A recognised line plus the layout geometry used to rank it.
class OcrLine {
  final String text;
  final double top; // y-position on the card (smaller = higher up)
  final double height; // bounding-box height ≈ font size
  const OcrLine({required this.text, required this.top, required this.height});
}

class CardTextParser {
  static ScannedCardData parse(List<OcrLine> rawLines) {
    final lines = rawLines.where((l) => l.text.trim().isNotEmpty).toList();
    final textLines = lines.map((l) => l.text.trim()).toList();
    final fullText = textLines.join('\n');

    final email = _extractEmail(fullText);
    final website = _extractWebsite(fullText, email);
    final phone = _extractPhone(textLines);
    final name = _extractName(lines, email);
    final company = _extractCompany(textLines, email, website, name);
    final title = _extractTitle(textLines, name);

    return ScannedCardData(
      name: name,
      phone: phone,
      email: email,
      company: company,
      title: title,
      website: website,
    );
  }

  // ── Phone: collect all, skip fax, prefer a 10-digit mobile (6-9 start) ──
  static String? _extractPhone(List<String> lines) {
    final rx = RegExp(r'(\+?\d[\d\s\-().]{7,}\d)');
    String? firstValid;
    String? mobile;

    for (final line in lines) {
      final lower = line.toLowerCase();
      final isFax = lower.contains('fax');
      for (final m in rx.allMatches(line)) {
        final raw = m.group(0)!.trim();
        final digits = raw.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 7 || digits.length > 15) continue;
        firstValid ??= raw;
        if (isFax) continue;

        final local = digits.length > 10
            ? digits.substring(digits.length - 10)
            : digits;
        final looksMobile =
            local.length == 10 && RegExp(r'^[6-9]').hasMatch(local);
        final labelled =
            lower.contains('mob') ||
            lower.contains('cell') ||
            lower.contains('+91');
        if (looksMobile && (mobile == null || labelled)) {
          mobile = raw;
        }
      }
    }
    return mobile ?? firstValid;
  }

  static String? _extractEmail(String text) {
    final rx = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+', caseSensitive: false);
    return rx.firstMatch(text)?.group(0)?.toLowerCase();
  }

  // ── Website: a real domain that isn't part of the email ──
  static String? _extractWebsite(String text, String? email) {
    final rx = RegExp(
      r'((https?:\/\/)?(www\.)[^\s,;]+|\b[a-z0-9][a-z0-9.-]*\.(com|in|io|co|net|org|app|biz|info|me)\b[^\s,;]*)',
      caseSensitive: false,
    );
    for (final m in rx.allMatches(text)) {
      final site = m.group(0)!.trim();
      if (site.contains('@')) continue;
      if (email != null && email.contains(site.toLowerCase())) continue;
      return site;
    }
    return null;
  }

  static const _titleKeywords = [
    'ceo',
    'cto',
    'coo',
    'cfo',
    'cmo',
    'vp',
    'vice president',
    'director',
    'manager',
    'engineer',
    'developer',
    'designer',
    'consultant',
    'analyst',
    'executive',
    'president',
    'founder',
    'co-founder',
    'head',
    'lead',
    'officer',
    'associate',
    'intern',
    'architect',
    'specialist',
    'coordinator',
    'advisor',
    'partner',
    'proprietor',
    'owner',
    'principal',
    'sales',
    'marketing',
    'accountant',
    'administrator',
    'supervisor',
    'representative',
    'agent',
    'technician',
    'doctor',
    'dr.',
    'professor',
  ];

  static const _companyKeywords = [
    'pvt',
    'ltd',
    'inc',
    'llc',
    'llp',
    'corp',
    'co.',
    'group',
    'technologies',
    'technology',
    'solutions',
    'services',
    'systems',
    'ventures',
    'industries',
    'enterprises',
    'enterprise',
    'consulting',
    'labs',
    'studio',
    'company',
    'pvt.',
    'limited',
    'associates',
    'traders',
    'international',
    'global',
    'infotech',
    'softwares',
    'software',
  ];

  // ── Name: biggest, name-shaped line near the top, matched to the email ──
  static String? _extractName(List<OcrLine> lines, String? email) {
    double maxH = 1;
    for (final l in lines) {
      if (l.height > maxH) maxH = l.height;
    }
    final emailLocal = email
        ?.split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');

    OcrLine? best;
    double bestScore = -1;

    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      final t = l.text.trim();
      final lower = t.toLowerCase();

      if (t.contains('@')) continue;
      if (RegExp(r'\d{3,}').hasMatch(t)) continue;
      if (RegExp(
        r'www\.|http|\.(com|in|io|co|net|org)',
        caseSensitive: false,
      ).hasMatch(lower)) {
        continue;
      }
      if (_titleKeywords.any((kw) => lower.contains(kw))) continue;
      if (_companyKeywords.any((kw) => lower.contains(kw))) continue;

      final letters = t.replaceAll(RegExp(r'[^A-Za-z]'), '').length;
      if (letters < 3) continue;

      final words = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isEmpty || words.length > 4) continue;

      final nameLike =
          words.every((w) => RegExp(r'^[A-Z]').hasMatch(w)) ||
          t == t.toUpperCase();

      double score = 0;
      score += (l.height / maxH) * 3; // bigger text → likely name
      score += (1 - (i / lines.length)) * 1.5; // higher up → likely name
      if (nameLike) score += 2;
      if (words.length >= 2 && words.length <= 3) score += 1;

      // Strong signal: the name appears inside the email local-part.
      if (emailLocal != null && emailLocal.isNotEmpty) {
        final collapsed = t.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (collapsed.isNotEmpty &&
            (emailLocal.contains(collapsed) ||
                collapsed.contains(emailLocal))) {
          score += 2.5;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = l;
      }
    }
    return best?.text.trim();
  }

  // ── Company: suffix keyword → else derived from the email/website domain ──
  static String? _extractCompany(
    List<String> lines,
    String? email,
    String? website,
    String? name,
  ) {
    for (final line in lines) {
      if (line == name) continue;
      final lower = line.toLowerCase();
      if (_companyKeywords.any((kw) => lower.contains(kw))) return line;
    }

    final domain = _domainRoot(website) ?? _domainRoot(email);
    if (domain != null) {
      // Prefer an actual line that matches the domain root.
      for (final line in lines) {
        if (line == name) continue;
        final collapsed = line.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (collapsed.contains(domain) &&
            collapsed.length < domain.length + 14) {
          return line;
        }
      }
      // Else Title-case the domain root (technova → Technova).
      return domain[0].toUpperCase() + domain.substring(1);
    }
    return null;
  }

  static String? _domainRoot(String? s) {
    if (s == null || s.isEmpty) return null;
    final afterAt = s.contains('@') ? s.split('@').last : s;
    final clean = afterAt
        .toLowerCase()
        .replaceAll(RegExp(r'^https?:\/\/'), '')
        .replaceAll('www.', '');
    final host = clean.split(RegExp(r'[\/\s]')).first;
    final parts = host.split('.');
    if (parts.length < 2) return null;
    final root = parts[parts.length - 2];
    // A personal mailbox domain says nothing about the company.
    const generic = [
      'gmail',
      'yahoo',
      'hotmail',
      'outlook',
      'rediffmail',
      'icloud',
      'live',
      'aol',
      'protonmail',
    ];
    if (generic.contains(root)) return null;
    return root;
  }

  // ── Title: keyword line → else the line just below the name ──
  static String? _extractTitle(List<String> lines, String? name) {
    for (final line in lines) {
      if (line == name) continue;
      final lower = line.toLowerCase();
      if (_titleKeywords.any((kw) => lower.contains(kw))) return line;
    }
    if (name != null) {
      final idx = lines.indexOf(name);
      if (idx != -1 && idx + 1 < lines.length) {
        final next = lines[idx + 1];
        final lower = next.toLowerCase();
        if (!next.contains('@') &&
            !RegExp(r'\d{3,}').hasMatch(next) &&
            !_companyKeywords.any((kw) => lower.contains(kw))) {
          return next;
        }
      }
    }
    return null;
  }
}
