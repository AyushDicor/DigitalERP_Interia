// Tap Card — scan a physical card. Photograph the front (and optionally the
// back), run on-device OCR, then hand the extracted fields to the create form
// for review. Ported from TapCard's ScanScreen.
//
// The OCR is ML Kit's on-device text recogniser: no network call, so scanning
// works in the field with no signal — which is the point of the module.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_constant_new.dart';
import '../utils/show_message.dart';
import 'tap_card_create/tap_card_create_view.dart';
import 'tap_card_models.dart';
import 'tap_card_utils/tap_card_ocr_parser.dart';
import 'tap_card_utils/tap_card_widgets.dart';

class TapCardScanView extends StatefulWidget {
  const TapCardScanView({Key? key}) : super(key: key);

  @override
  State<TapCardScanView> createState() => _TapCardScanViewState();
}

class _TapCardScanViewState extends State<TapCardScanView> {
  File? _front;
  File? _back;
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTapBg,
      appBar: AppBar(
        backgroundColor: kTapSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: kTapBorder,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: newTextPrimary,
            size: 20,
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Card',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTapTextPrimary,
              ),
            ),
            Text(
              'Photograph the card to read its details',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: kTapTextSecondary,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: [
          _section(
            'Card Photos',
            Icons.photo_camera_outlined,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _slot('Front', _front, isBack: false)),
                const SizedBox(width: 12),
                Expanded(child: _slot('Back (optional)', _back, isBack: true)),
              ],
            ),
          ),
          _section(
            'Tips for best results',
            Icons.lightbulb_outline_rounded,
            Column(
              children: const [
                _Tip('Hold the card flat with good lighting'),
                _Tip('Make sure all the text is clearly visible'),
                _Tip('Add the back only if it has extra details'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _scanButton(),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _processing ? null : _skipToManual,
              child: const Text(
                'Enter details manually instead',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTapPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kTapSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kTapBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: kTapPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTapTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _slot(String label, File? file, {required bool isBack}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: kTapTextSecondary,
        ),
      ),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: _processing ? null : () => _chooseSource(isBack: isBack),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: kTapBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: file != null
                  ? kTapPrimary.withValues(alpha: 0.5)
                  : kTapBorder,
            ),
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 22,
                      color: kTapTextHint,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap to add',
                      style: TextStyle(fontSize: 11, color: kTapTextHint),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(file, fit: BoxFit.cover),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ],
  );

  Widget _scanButton() => GestureDetector(
    onTap: (_front == null || _processing) ? null : _runOcr,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: (_front == null || _processing)
            ? kTapPrimary.withValues(alpha: 0.5)
            : kTapPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: _processing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Reading card…',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.document_scanner_outlined,
                  size: 19,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Scan Card',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    ),
  );

  // ── Image picking ──
  void _chooseSource({required bool isBack}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kTapSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: kTapPrimary,
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(fontSize: 14, color: kTapTextPrimary),
              ),
              onTap: () {
                Get.back();
                _pick(ImageSource.camera, isBack: isBack);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: kTapPrimary,
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(fontSize: 14, color: kTapTextPrimary),
              ),
              onTap: () {
                Get.back();
                _pick(ImageSource.gallery, isBack: isBack);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source, {required bool isBack}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (picked == null) return;
      setState(() {
        if (isBack) {
          _back = File(picked.path);
        } else {
          _front = File(picked.path);
        }
      });
    } catch (e) {
      ShowMessage.showSnackBar('Photo', '$e');
    }
  }

  // ── OCR ──
  Future<void> _runOcr() async {
    if (_front == null) return;
    setState(() => _processing = true);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      // Read both sides into one pool of lines — details are often split
      // across the front and back, and the parser scores them together.
      final lines = <OcrLine>[];
      for (final file in [_front, _back]) {
        if (file == null) continue;
        final result = await recognizer.processImage(InputImage.fromFile(file));
        for (final block in result.blocks) {
          for (final line in block.lines) {
            lines.add(
              OcrLine(
                text: line.text,
                top: line.boundingBox.top.toDouble(),
                height: line.boundingBox.height.toDouble(),
              ),
            );
          }
        }
      }

      if (lines.isEmpty) {
        ShowMessage.showSnackBar(
          'Scan',
          'No text found on that image. Try again with better lighting, or enter the details manually.',
        );
        return;
      }

      final parsed = CardTextParser.parse(lines);
      final scanned = ScannedCardData(
        name: parsed.name,
        phone: parsed.phone,
        email: parsed.email,
        company: parsed.company,
        title: parsed.title,
        website: parsed.website,
        imageUrl: _front?.path,
        backImageUrl: _back?.path,
      );

      if (!mounted) return;
      final saved = await Get.to(() => TapCardCreateView(scanned: scanned));
      // Forward the form's result verbatim — it carries the success message —
      // so the list refreshes once and reports it.
      if (saved != null && saved != false) {
        Get.back(result: saved, closeOverlays: true);
      }
    } catch (e) {
      ShowMessage.showSnackBar('Scan', 'Could not read the card: $e');
    } finally {
      // The recogniser holds a native resource — always release it.
      await recognizer.close();
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _skipToManual() async {
    // Keep any photos already taken, just without the extracted text.
    final scanned = (_front == null && _back == null)
        ? null
        : ScannedCardData(imageUrl: _front?.path, backImageUrl: _back?.path);
    final saved = await Get.to(() => TapCardCreateView(scanned: scanned));
    if (saved != null && saved != false) {
      Get.back(result: saved, closeOverlays: true);
    }
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 14,
          color: newGreenColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: kTapTextSecondary),
          ),
        ),
      ],
    ),
  );
}
