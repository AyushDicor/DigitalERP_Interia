// Tap Card — create/edit form controller. Holds the six text fields, the
// category choice and the two card photos, then hands the assembled card to
// TapCardController.saveCard (which owns the online/offline decision).
//
// Ported from TapCard's ConfirmCardScreen, which was scan-only. Here the same
// form serves three entry points: a blank manual entry, a form pre-filled from
// an OCR scan, and editing an existing card.

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:newdigitalerp/screen/base/base_controller.dart';
import 'package:newdigitalerp/utils/show_message.dart';

import '../tap_card_controller.dart';
import '../tap_card_models.dart';

class TapCardCreateController extends AppBaseController {
  /// The card being edited, or null when creating.
  final TapCardModel? editing;

  /// Values lifted from an OCR scan, or null for a blank/manual form.
  final ScannedCardData? scanned;

  TapCardCreateController({this.editing, this.scanned});

  final nameCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();

  String category = TapCardCategory.defaultCategory;

  /// Front/back card photos — a local file path when just picked, or an http
  /// URL when the card was loaded from the server.
  String? frontImage;
  String? backImage;

  /// Per-field validation errors, keyed by field name.
  final Map<String, String> errors = {};

  bool saving = false;

  bool get isEdit => editing != null;

  /// True when the form was seeded by the scanner — the view shows the
  /// "review these details" hint only in that case.
  bool get fromScan => scanned != null;

  @override
  void onInit() {
    super.onInit();
    final e = editing;
    final s = scanned;
    if (e != null) {
      nameCtrl.text = e.name;
      titleCtrl.text = e.title ?? '';
      phoneCtrl.text = e.phone ?? '';
      emailCtrl.text = e.email ?? '';
      companyCtrl.text = e.company ?? '';
      websiteCtrl.text = e.website ?? '';
      category = e.category ?? TapCardCategory.defaultCategory;
      frontImage = e.imageUrl;
      backImage = e.backImageUrl;
    } else if (s != null) {
      nameCtrl.text = s.name ?? '';
      titleCtrl.text = s.title ?? '';
      phoneCtrl.text = s.phone ?? '';
      emailCtrl.text = s.email ?? '';
      companyCtrl.text = s.company ?? '';
      websiteCtrl.text = s.website ?? '';
      frontImage = s.imageUrl;
      backImage = s.backImageUrl;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    titleCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    companyCtrl.dispose();
    websiteCtrl.dispose();
    super.onClose();
  }

  void setCategory(String v) {
    category = v;
    update();
  }

  void clearError(String field) {
    if (errors.remove(field) != null) update();
  }

  // ── Images ──
  Future<void> pickImage({
    required bool front,
    required ImageSource source,
  }) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (picked == null) return;
      if (front) {
        frontImage = picked.path;
      } else {
        backImage = picked.path;
      }
      update();
    } catch (e) {
      ShowMessage.showSnackBar('Photo', '$e');
    }
  }

  void removeImage({required bool front}) {
    if (front) {
      frontImage = null;
    } else {
      backImage = null;
    }
    update();
  }

  bool isLocalFile(String? path) =>
      path != null && path.isNotEmpty && !path.startsWith('http');

  File fileFor(String path) => File(path);

  // ── Validation ──
  /// Name is the only hard requirement; a card with nothing but a name is still
  /// worth keeping. Phone/email are checked for shape only when filled in —
  /// TapCard accepted anything, which let obvious typos through.
  bool validate() {
    errors.clear();

    if (nameCtrl.text.trim().isEmpty) {
      errors['name'] = 'Name is required';
    }

    final phone = phoneCtrl.text.trim();
    if (phone.isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 7) errors['phone'] = 'Enter a valid phone number';
    }

    final email = emailCtrl.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address';
    }

    update();
    return errors.isEmpty;
  }

  String? _opt(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  /// Message for the list screen to show once it has popped back. Set by
  /// [save]; read by the caller. Shown there rather than here because a
  /// snackbar raised during a route transition is easily swallowed.
  String? successMessage;

  /// Save and return true when the card was stored (on the server, or locally
  /// when offline). The caller pops with this value so the list refreshes.
  Future<bool> save() async {
    if (!validate()) return false;

    saving = true;
    update();

    String? err;
    try {
      final card = TapCardModel(
        id: editing?.id ?? 0,
        localId: editing?.localId,
        name: nameCtrl.text.trim(),
        title: _opt(titleCtrl),
        phone: _opt(phoneCtrl),
        email: _opt(emailCtrl),
        company: _opt(companyCtrl),
        website: _opt(websiteCtrl),
        imageUrl: frontImage,
        backImageUrl: backImage,
        category: category,
        createdAt: editing?.createdAt,
      );

      final listCtrl = Get.find<TapCardController>();
      err = await listCtrl.saveCard(card);
      successMessage = err != null
          ? null
          : (listCtrl.offline
                ? 'Saved on this device — it will sync when you are back online.'
                : (isEdit ? 'Card updated.' : 'Card saved.'));
    } catch (e) {
      log('TapCard: save failed — $e');
      err = '$e';
    } finally {
      saving = false;
      update();
    }

    // Reporting is deliberately OUTSIDE the try above. Showing a snackbar is
    // presentation, not part of the save: if it throws, the card is already
    // stored and we must still report success and let the screen pop. Having
    // this inside the try meant one bad snackbar turned a completed save into
    // a silent failure — no message, no navigation, but a row in the database.
    if (err != null) {
      log('TapCard: save reported failure — $err');
      try {
        ShowMessage.showSnackBar('Tap Card', err);
      } catch (e) {
        log('TapCard: could not show error snackbar — $e');
      }
      return false;
    }
    log('TapCard: save OK — "$successMessage"');
    return true;
  }
}
