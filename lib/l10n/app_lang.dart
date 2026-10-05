// Hindi for the shop floor.
//
// Keys ARE the English sentences. That means two things: a string nobody has
// translated yet falls back to readable English rather than a missing-key
// placeholder, and an existing screen is localised by appending `.tr` without
// inventing an identifier for every label.
//
// NUMBERS, DATES AND TIMES STAY IN LATIN DIGITS in both languages — a worker
// reads "4" and "11:30" the same way whatever the labels say, and Devanagari
// digits on a qty field would be a step backwards, not forwards. Nothing here
// touches `fmtQty`, `NumberFormat` or `DateFormat`; see [latinLocale].

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

const Locale enLocale = Locale('en', 'US');
const Locale hiLocale = Locale('hi', 'IN');

/// Always format numbers, dates and times against this, never the UI locale.
/// Hindi labels, Latin digits — which is what the floor asked for.
const String latinLocale = 'en_IN';

/// Remembered on the device, not against the user: a shared handset on the
/// floor should stay in Hindi whoever signs in next.
class AppLang {
  const AppLang._();

  static const _key = 'app_language';

  static Locale get current => isHindi ? hiLocale : enLocale;

  static bool get isHindi {
    try {
      return (GetStorage().read<String>(_key) ?? 'en') == 'hi';
    } catch (_) {
      return false;
    }
  }

  static void set(bool hindi) {
    try {
      GetStorage().write(_key, hindi ? 'hi' : 'en');
    } catch (_) {}
    Get.updateLocale(hindi ? hiLocale : enLocale);
  }

  static void toggle() => set(!isHindi);

  static String get label => isHindi ? 'हिन्दी' : 'English';
}

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // English needs no map: a missing key falls through to the key itself,
    // which IS the English text.
    'en_US': const {},
    'hi_IN': _hi,
  };
}

/// Server-written statuses, translated for display only.
///
/// These arrive in English from `myjobs`, `jobparts` and the rest, and the
/// app must keep comparing the ENGLISH value for behaviour — never the
/// translated one. Use [trStatus] at the point of drawing, nowhere else.
String trStatus(String serverStatus) {
  final s = serverStatus.trim();
  if (s.isEmpty || !AppLang.isHindi) return s;
  return _statusHi[s.toLowerCase()] ?? s;
}

const Map<String, String> _statusHi = {
  // job statuses
  'to produce': 'बनाना है',
  'running': 'चल रहा है',
  'in progress': 'चल रहा है',
  'done': 'पूरा',
  'rework': 'दोबारा बनाना है',
  'in transit': 'रास्ते में',
  'waiting for parts': 'पुर्ज़ों का इंतज़ार',
  'awaiting qc': 'QC बाकी है',
  'ready to send': 'भेजने के लिए तैयार',
  'sent back': 'वापस भेजा गया',
  // part statuses
  'to make': 'बनाना है',
  'to work': 'काम करना है',
  'waiting': 'इंतज़ार',
  'on the loader': 'लोडर पर',
  'sent': 'भेज दिया',
  'to join': 'जोड़ना है',
  'joined': 'जुड़ गया',
  'part received': 'कुछ पुर्ज़े आए',
  'all received': 'सभी पुर्ज़े आ गए',
  'made with the item': 'आइटम के साथ बना',
  // send back
  'open': 'खुला',
  'back': 'वापस आ गया',
  'refused': 'मना किया',
};

const Map<String, String> _hi = {
  // ── shell ──
  'My Jobs': 'मेरे काम',
  'Home': 'होम',
  'My Work': 'मेरा काम',
  'Log': 'रिकॉर्ड',
  'QC': 'QC',
  'All': 'सभी',
  'To do': 'करना है',
  'Pending': 'बाकी',
  'Running': 'चल रहा',
  'Done': 'पूरा',
  'Rework': 'दोबारा',
  'To issue': 'भेजना है',
  'Incoming': 'आने वाला',
  'Awaiting receipt': 'रसीद बाकी',
  'Sent back to fix': 'सुधार के लिए वापस आया',
  'Nothing here': 'यहाँ कुछ नहीं',
  'Nothing pending QC': 'QC के लिए कुछ नहीं',

  // ── job card / job screen ──
  'Issued': 'दिया गया',
  'Produced': 'बनाया',
  'Balance': 'बाकी',
  'Current piece': 'मौजूदा पीस',
  'Start production': 'काम शुरू करें',
  'Continue': 'जारी रखें',
  'Add production': 'उत्पादन दर्ज करें',
  'Production': 'उत्पादन',
  'Rework here': 'यहीं दोबारा बनाएँ',
  'Route': 'रास्ता',
  'Parts': 'पुर्ज़े',
  'Coming in': 'आ रहे हैं',
  'Make here': 'यहाँ बनाना है',
  'Need': 'चाहिए',
  'Made': 'बना',
  'Sent': 'भेजा',
  'Drawings & Details': 'ड्रॉइंग और जानकारी',
  'Downtime': 'मशीन बंद',
  'Bottleneck': 'रुकावट',
  'Production log': 'उत्पादन रिकॉर्ड',

  // ── QC ──
  'Quality Check': 'क्वालिटी जाँच',
  'Do QC': 'QC करें',
  'QC passed': 'QC पास',
  'Rejected': 'रिजेक्ट',
  'Passed': 'पास',
  'Save QC': 'QC सेव करें',
  'Reject reason (required)': 'रिजेक्ट का कारण (ज़रूरी)',
  'Remarks (optional)': 'टिप्पणी (वैकल्पिक)',
  'Photo of the defect': 'खराबी की फोटो',
  'The rejected pieces: what now?': 'रिजेक्ट पीस का क्या करें?',
  'Fix it here': 'यहीं ठीक करें',
  'Send it back': 'वापस भेजें',
  'Next: where to send it': 'आगे: कहाँ भेजना है',

  // ── issue / hand over ──
  'Issue to next stage': 'अगले स्टेज को भेजें',
  'Hand over': 'सौंपें',
  'Qty to issue': 'भेजने की संख्या',
  'Loader name': 'लोडर का नाम',
  'Issue date': 'भेजने की तारीख',
  'Issue time': 'भेजने का समय',
  'Issue receipt photo(s) — required': 'रसीद की फोटो — ज़रूरी',
  'Item photo(s)': 'सामान की फोटो',
  'Receive consignment': 'खेप लें',
  'Accept': 'स्वीकार करें',
  'Reject': 'मना करें',

  // ── send back ──
  'Send back': 'वापस भेजें',
  'What goes back?': 'क्या वापस जाएगा?',
  'Fix at': 'कहाँ ठीक होगा',
  'Way back': 'वापसी का रास्ता',
  'How many, and how': 'कितने, और कैसे',
  'Reason': 'कारण',
  'Whose work is faulty?': 'किसका काम खराब है?',
  'Photo': 'फोटो',
  'Qty': 'संख्या',
  'Direct': 'सीधे',
  'Loader': 'लोडर',
  'Already worked on here?': 'यहाँ काम हो चुका है?',
  'Not worked yet': 'अभी काम नहीं हुआ',
  'Already worked': 'काम हो चुका',
  'Nothing here to send back': 'यहाँ वापस भेजने को कुछ नहीं',

  // ── packing ──
  'Pack': 'पैक करें',
  'Pack item': 'आइटम पैक करें',
  'Packing': 'पैकिंग',
  'Pieces packed': 'पैक किए पीस',
  'left to pack': 'पैक करना बाकी',
  'Boxes': 'डिब्बे',
  'Add box': 'डिब्बा जोड़ें',
  'Save box': 'डिब्बा सेव करें',
  'Save packing': 'पैकिंग सेव करें',
  'What is inside': 'अंदर क्या है',
  'How many': 'कितने',
  'Photo of the box (optional)': 'डिब्बे की फोटो (वैकल्पिक)',
  'Already packed': 'पहले पैक किया',
  'Undo': 'वापस लें',
  'Cancel': 'रद्द करें',

  // ── order tracking ──
  'Order Tracking': 'ऑर्डर ट्रैकिंग',
  'Orders': 'ऑर्डर',
  'Items': 'आइटम',
  'Stages': 'स्टेज',
  'Overdue': 'देर से',
  'Waiting for parts': 'पुर्ज़ों का इंतज़ार',
  'Can make now': 'अभी बना सकते हैं',
  'Search': 'खोजें',
  'Filter': 'छाँटें',

  // ── common ──
  'Save': 'सेव करें',
  'Close': 'बंद करें',
  'Refresh': 'रिफ्रेश',
  'Retry': 'फिर कोशिश करें',
  'Loading…': 'लोड हो रहा है…',
  'Something went wrong': 'कुछ गड़बड़ हुई',
  'Language': 'भाषा',
};
