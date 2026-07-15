/// Indian-format number helpers (lakh / crore grouping): 100000 -> "1,00,000".
///
/// Used everywhere money/amounts are shown so the whole app renders values the
/// Indian way (last 3 digits grouped, then in pairs) instead of the western
/// thousands grouping. Keeps the app's existing "strip trailing .00" behaviour:
/// whole numbers show no decimals, fractional values show [decimals] places.
library;

/// Groups a string of plain integer digits (no sign, no decimals) the Indian way.
/// "100000" -> "1,00,000", "10000000" -> "1,00,00,000", "500" -> "500".
String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  String head = digits.substring(0, digits.length - 3);
  // Insert a comma before every pair of digits (counted from the right) in the head.
  head = head.replaceAllMapped(RegExp(r'\B(?=(\d{2})+(?!\d))'), (_) => ',');
  return '$head,$last3';
}

/// Formats a numeric value in Indian grouping. Accepts num / numeric String / null.
/// Whole numbers -> no decimals ("1,00,000"); fractional -> [decimals] places
/// ("1,00,000.50"). Handles negatives.
String inrNum(dynamic value, {int decimals = 2}) {
  if (value == null) return '0';

  double number;
  if (value is num) {
    number = value.toDouble();
  } else if (value is String) {
    number = double.tryParse(value.trim()) ?? 0;
  } else {
    return '0';
  }

  final bool neg = number < 0;
  number = number.abs();

  String intPart;
  String fracPart = '';
  if (decimals < 1 || number % 1 == 0) {
    // whole numbers (or decimals disabled) -> no fractional part
    intPart = number.round().toString();
  } else {
    final fixed = number.toStringAsFixed(decimals); // e.g. "1234.50"
    final dot = fixed.indexOf('.');
    intPart = fixed.substring(0, dot);
    fracPart = fixed.substring(dot); // includes the '.'
  }

  return '${neg ? '-' : ''}${_groupIndian(intPart)}$fracPart';
}

/// Convenience: value prefixed with the rupee symbol. "₹1,00,000".
String inrMoney(dynamic value, {int decimals = 2}) =>
    '₹${inrNum(value, decimals: decimals)}';

/// Drop-in replacement for `.toStringAsFixed(n)` on money values that adds
/// Indian grouping: `amount.toStringAsFixed(2)` -> `amount.toInr()`,
/// `amount.toStringAsFixed(0)` -> `amount.toInr(decimals: 0)`.
extension InrNumFormat on num {
  String toInr({int decimals = 2}) => inrNum(this, decimals: decimals);
}
