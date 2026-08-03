// Tap Card — detail page. Gradient header, quick Call/Email/Website actions,
// tap-to-copy detail rows, the scanned card photos, and the share options
// (vCard QR, share text, save the rendered card to the gallery).
// Ported from TapCard's ContactDetailScreen + MyCardScreen + SaveCardWidget.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_constant_new.dart';
import '../../utils/show_message.dart';
import '../tap_card_controller.dart';
import '../tap_card_create/tap_card_create_view.dart';
import '../tap_card_models.dart';
import '../tap_card_utils/tap_card_widgets.dart';

class TapCardDetailView extends StatefulWidget {
  final TapCardModel card;
  const TapCardDetailView({Key? key, required this.card}) : super(key: key);

  @override
  State<TapCardDetailView> createState() => _TapCardDetailViewState();
}

class _TapCardDetailViewState extends State<TapCardDetailView> {
  late TapCardModel card = widget.card;
  final _screenshot = ScreenshotController();
  bool _savingImage = false;

  TapCardController get _list => Get.find<TapCardController>();

  @override
  Widget build(BuildContext context) {
    final accent = tapCategoryColor(card.category);

    return Scaffold(
      backgroundColor: kTapBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: accent,
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Get.back(),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _edit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _confirmDelete,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _header(accent)),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                child: Column(
                  children: [
                    _quickActions(),
                    const SizedBox(height: 12),
                    _detailsCard(),
                    if ((card.imageUrl ?? '').isNotEmpty ||
                        (card.backImageUrl ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _photosCard(),
                    ],
                    const SizedBox(height: 12),
                    _shareCard(),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Header ──
  Widget _header(Color accent) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accent.withValues(alpha: 0.75)],
      ),
    ),
    child: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              card.initial,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              card.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if ((card.title ?? '').isNotEmpty)
            Text(
              card.title!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          if ((card.company ?? '').isNotEmpty)
            Text(
              card.company!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          const SizedBox(height: 14),
        ],
      ),
    ),
  );

  // ── Quick actions ──
  Widget _quickActions() {
    final actions = <Widget>[];
    if ((card.phone ?? '').isNotEmpty) {
      actions.add(
        _action(
          Icons.phone_rounded,
          'Call',
          () => _launch('tel:${card.phone}'),
        ),
      );
      actions.add(
        _action(
          Icons.message_rounded,
          'SMS',
          () => _launch('sms:${card.phone}'),
        ),
      );
    }
    if ((card.email ?? '').isNotEmpty) {
      actions.add(
        _action(
          Icons.email_rounded,
          'Email',
          () => _launch('mailto:${card.email}'),
        ),
      );
    }
    if ((card.website ?? '').isNotEmpty) {
      final url = card.website!.startsWith('http')
          ? card.website!
          : 'https://${card.website}';
      actions.add(
        _action(Icons.language_rounded, 'Website', () => _launch(url)),
      );
    }
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions,
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: kTapSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kTapBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: kTapPrimary),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: kTapTextSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── Details ──
  Widget _detailsCard() => _card('Details', Icons.info_outline_rounded, [
    _row(Icons.person_outline_rounded, 'Name', card.name),
    if ((card.title ?? '').isNotEmpty)
      _row(Icons.work_outline_rounded, 'Job Title', card.title!),
    if ((card.phone ?? '').isNotEmpty)
      _row(Icons.phone_outlined, 'Phone', card.phone!),
    if ((card.email ?? '').isNotEmpty)
      _row(Icons.email_outlined, 'Email', card.email!),
    if ((card.company ?? '').isNotEmpty)
      _row(Icons.business_outlined, 'Company', card.company!),
    if ((card.website ?? '').isNotEmpty)
      _row(Icons.language_outlined, 'Website', card.website!),
    _row(
      Icons.sell_outlined,
      'Category',
      card.category ?? TapCardCategory.business,
    ),
    if (card.createdAt != null)
      _row(Icons.event_outlined, 'Saved on', _formatDate(card.createdAt!)),
  ]);

  Widget _photosCard() => _card('Card Photos', Icons.photo_outlined, [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((card.imageUrl ?? '').isNotEmpty)
          Expanded(child: _photo('Front', card.imageUrl!)),
        if ((card.imageUrl ?? '').isNotEmpty &&
            (card.backImageUrl ?? '').isNotEmpty)
          const SizedBox(width: 12),
        if ((card.backImageUrl ?? '').isNotEmpty)
          Expanded(child: _photo('Back', card.backImageUrl!)),
      ],
    ),
  ]);

  Widget _photo(String label, String path) => Column(
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
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: InteractiveViewer(
              child: TapCardImage(path, fit: BoxFit.contain),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(height: 120, child: TapCardImage(path)),
        ),
      ),
    ],
  );

  // ── Share ──
  Widget _shareCard() => _card('Share', Icons.ios_share_rounded, [
    // Rendered off-screen at a fixed width so the captured image is the same
    // on every device, regardless of screen size.
    Center(
      child: Screenshot(controller: _screenshot, child: TapCardPreview(card)),
    ),
    const SizedBox(height: 16),
    Row(
      children: [
        Expanded(child: _shareBtn(Icons.qr_code_2_rounded, 'QR Code', _showQr)),
        const SizedBox(width: 10),
        Expanded(child: _shareBtn(Icons.share_outlined, 'Share', _shareText)),
        const SizedBox(width: 10),
        Expanded(
          child: _shareBtn(
            _savingImage ? Icons.hourglass_top_rounded : Icons.download_rounded,
            'Save',
            _savingImage ? null : _saveToGallery,
          ),
        ),
      ],
    ),
  ]);

  Widget _shareBtn(IconData icon, String label, VoidCallback? onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: purpleLightest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kTapPrimary.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: kTapPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTapPrimary,
                ),
              ),
            ],
          ),
        ),
      );

  void _showQr() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: kTapSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                card.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kTapTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scan to save this contact',
                style: TextStyle(fontSize: 11.5, color: kTapTextSecondary),
              ),
              const SizedBox(height: 18),
              QrImageView(
                data: card.toVCard(),
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTapPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareText() async {
    try {
      await SharePlus.instance.share(ShareParams(text: card.toShareText()));
    } catch (e) {
      ShowMessage.showSnackBar('Share', '$e');
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _savingImage = true);
    try {
      // Capture from the widget rather than the on-screen render, so the image
      // is a clean 3x card with no surrounding UI.
      final Uint8List bytes = await _screenshot.captureFromWidget(
        TapCardPreview(card),
        pixelRatio: 3.0,
        context: context,
      );

      final safeName = card.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final result = await SaverGallery.saveImage(
        bytes,
        fileName:
            'TapCard_${safeName}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        androidRelativePath: 'Pictures/TapCard',
        skipIfExists: false,
      );

      ShowMessage.showSnackBar(
        'Tap Card',
        result.isSuccess
            ? 'Card saved to your gallery.'
            : (result.errorMessage ?? 'Could not save the image.'),
      );
    } catch (e) {
      ShowMessage.showSnackBar('Tap Card', '$e');
    } finally {
      if (mounted) setState(() => _savingImage = false);
    }
  }

  // ── Edit / delete ──
  Future<void> _edit() async {
    final saved = await Get.to(() => TapCardCreateView(editing: card));
    // The form returns its success message (or true) — anything but null/false
    // means the card was stored.
    if (saved != null && saved != false) {
      await _list.loadList();
      // Pull the refreshed row back so this screen reflects the edit.
      final updated = _list.allCards.firstWhereOrNull(
        (c) => c.key == card.key || (card.id > 0 && c.id == card.id),
      );
      if (updated != null && mounted) setState(() => card = updated);
      if (saved is String && saved.isNotEmpty) {
        ShowMessage.showSnackBar('Tap Card', saved);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kTapSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete card?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kTapTextPrimary,
          ),
        ),
        content: Text(
          '“${card.name}” will be removed from your wallet.',
          style: const TextStyle(fontSize: 13, color: kTapTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kTapTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: newRedColor)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final err = await _list.deleteCard(card);
    if (err != null) {
      ShowMessage.showSnackBar('Tap Card', err);
      return;
    }
    // Pop BEFORE showing the message. GetX 4.6.5's Get.back() begins with
    //     if (isSnackbarOpen && !closeOverlays) { closeCurrentSnackbar(); return; }
    // so raising a snackbar first makes back() dismiss that snackbar and return
    // without ever popping the route — the screen would sit there having
    // already deleted the card, with the message flashing away too fast to read.
    Get.back();
    ShowMessage.showSnackBar('Tap Card', 'Card deleted.');
  }

  // ── Helpers ──
  Widget _card(String title, IconData icon, List<Widget> children) => Container(
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
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  /// Tap any detail row to copy it — the fastest way to get a number into
  /// another app.
  Widget _row(IconData icon, String label, String value) => GestureDetector(
    onTap: () async {
      await Clipboard.setData(ClipboardData(text: value));
      ShowMessage.showSnackBar('Copied', '$label copied.');
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 15, color: kTapTextHint),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: kTapTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kTapTextPrimary,
              ),
            ),
          ),
          const Icon(Icons.copy_rounded, size: 13, color: kTapTextHint),
        ],
      ),
    ),
  );

  Future<void> _launch(String uri) async {
    try {
      final u = Uri.parse(uri);
      if (!await launchUrl(u, mode: LaunchMode.externalApplication)) {
        ShowMessage.showSnackBar(
          'Tap Card',
          'Nothing on this device can open that.',
        );
      }
    } catch (e) {
      ShowMessage.showSnackBar('Tap Card', '$e');
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
