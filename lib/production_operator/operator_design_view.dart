// "Drawings & Details" — the design pack for the open job (interia/jobdesign).
//
// The operator cannot build the item from a quantity alone: they need the
// approved technical drawings, the materials the client specified, and the
// order's BOM design files. This sits near the top of the job screen, above
// Produce / QC, and is collapsible so it stays out of the way once read.
//
// Everything here is read-only — nothing in this file touches the produce, QC
// or loader flows.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';
import 'package:url_launcher/url_launcher.dart';

import 'operator_controller.dart';
import 'operator_models.dart';
import 'operator_widgets.dart';

/// Collapsible "Drawings & Details" card for the job screen.
class JobDesignSection extends StatelessWidget {
  const JobDesignSection({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorController>(
    builder: (c) {
      final d = c.design;
      // The card is shown even when the pack is empty: "nothing approved yet,
      // talk to planning" is something the operator needs to know, not
      // clutter to hide.
      return Container(
        margin: const EdgeInsets.only(bottom: 13),
        decoration: opCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(c, d),
            if (c.designOpen) ...[
              Divider(height: 1, color: newBorderColor.withValues(alpha: 0.7)),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
                child: _body(context, c, d),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _header(OperatorController c, JobDesign? d) => InkWell(
    borderRadius: BorderRadius.circular(15),
    onTap: c.toggleDesign,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: opBlueBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.architecture_outlined,
              size: 17,
              color: opBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drawings & Details'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: newTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _subtitle(c, d),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: newTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!c.designLoading)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: c.loadJobDesign,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: newTextSecondary,
                ),
              ),
            ),
          Icon(
            c.designOpen
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: newTextSecondary,
          ),
        ],
      ),
    ),
  );

  String _subtitle(OperatorController c, JobDesign? d) {
    if (c.designLoading) return 'Loading…'.tr;
    if (c.designError.isNotEmpty) return 'Could not load';
    if (d == null || d.isEmpty) return 'Nothing approved yet';
    return [
      if (d.drawings.isNotEmpty)
        '${d.drawings.length} ${d.drawings.length == 1 ? 'drawing' : 'drawings'}',
      if (d.visibleMaterials.isNotEmpty)
        '${d.visibleMaterials.length} '
            '${d.visibleMaterials.length == 1 ? 'material' : 'materials'}',
      if (d.bomdesigns.isNotEmpty) '${d.bomdesigns.length} BOM',
    ].join(' · ');
  }

  Widget _body(BuildContext context, OperatorController c, JobDesign? d) {
    if (c.designLoading) return const _DesignShimmer();
    if (c.designError.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c.designError,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: opRed,
            ),
          ),
          const SizedBox(height: 10),
          SmallButton(
            'Retry'.tr,
            color: opPrimary,
            icon: Icons.refresh_rounded,
            onTap: c.loadJobDesign,
          ),
        ],
      );
    }
    if (d == null || d.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: newSurfaceColor,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No approved drawings or details for this item yet.',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: newTextPrimary,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Please contact the planning / design team.',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: newTextSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (d.drawings.isNotEmpty) ...[
          _label('Technical drawings', d.drawings.length),
          ...d.drawings.map((x) => _drawingCard(context, x)),
        ],
        if (d.visibleMaterials.isNotEmpty) ...[
          if (d.drawings.isNotEmpty) const SizedBox(height: 14),
          _label('Client custom material', d.visibleMaterials.length),
          ...d.visibleMaterials.map((m) => _materialRow(context, m)),
        ],
        if (d.bomdesigns.isNotEmpty) ...[
          if (d.drawings.isNotEmpty || d.visibleMaterials.isNotEmpty)
            const SizedBox(height: 14),
          _label('BOM design files', d.bomdesigns.length),
          ...d.bomdesigns.map((b) => _bomRow(context, b)),
        ],
      ],
    );
  }

  Widget _label(String text, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: newTextSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: newTextHint,
          ),
        ),
      ],
    ),
  );

  // ── Drawing ──

  Widget _drawingCard(BuildContext context, Drawing d) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: newSurfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: newBorderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                d.drawingno.isEmpty ? 'Drawing' : d.drawingno,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
            ),
            if (d.status.isNotEmpty)
              SoftPill(d.status, color: opGreen, bg: opGreenBg),
          ],
        ),
        if (d.type.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            d.type,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: opBlue,
            ),
          ),
        ],
        if (d.remarks.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            d.remarks,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
              height: 1.3,
            ),
          ),
        ],
        if (d.docno.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Doc ${d.docno}',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: newTextHint,
            ),
          ),
        ],
        if (d.images.isNotEmpty) ...[
          const SizedBox(height: 9),
          _imageStrip(context, d.images, d.drawingno),
        ],
        ...d.docs.map((f) => _fileTile(context, f)),
      ],
    ),
  );

  // ── Material ──

  Widget _materialRow(BuildContext context, DesignMaterial m) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: newSurfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: newBorderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                m.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: newTextPrimary,
                ),
              ),
            ),
            if (m.qtyLabel.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                m.qtyLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: opPrimary,
                ),
              ),
            ],
          ],
        ),
        if (m.category.isNotEmpty) ...[
          const SizedBox(height: 4),
          SoftPill(m.category, color: opPurple, bg: opPurpleBg),
        ],
        if (m.remarks.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            m.remarks,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: newTextSecondary,
              height: 1.3,
            ),
          ),
        ],
        if (m.photos.where((p) => p.isimage).isNotEmpty) ...[
          const SizedBox(height: 9),
          _imageStrip(
            context,
            m.photos.where((p) => p.isimage).toList(),
            m.name,
          ),
        ],
        ...m.photos.where((p) => !p.isimage).map((f) => _fileTile(context, f)),
      ],
    ),
  );

  // ── BOM ──

  Widget _bomRow(BuildContext context, BomDesign b) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: newSurfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: newBorderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          b.designno.isEmpty ? 'Design' : 'Design ${b.designno}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: newTextPrimary,
          ),
        ),
        if (b.files.where((f) => f.isimage).isNotEmpty) ...[
          const SizedBox(height: 9),
          _imageStrip(
            context,
            b.files.where((f) => f.isimage).toList(),
            'Design ${b.designno}',
          ),
        ],
        ...b.files.where((f) => !f.isimage).map((f) => _fileTile(context, f)),
      ],
    ),
  );

  // ── Files ──

  /// Thumbnails that open a swipeable, pinch-zoom viewer of this group only.
  Widget _imageStrip(
    BuildContext context,
    List<DesignFile> images,
    String title,
  ) => SizedBox(
    height: 74,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Get.to(
          () => DesignGalleryView(files: images, index: i, title: title),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 74,
            height: 74,
            color: Colors.white,
            child: Image.network(
              images[i].url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.8),
                      ),
                    ),
              // A presigned url that has expired looks exactly like this —
              // the refresh button in the header re-reads them.
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: newTextHint,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// A PDF / DWG / other document: name + open. There is no in-app PDF
  /// viewer in this app, so it opens in whatever the device uses — the same
  /// thing the ERP print button does.
  Widget _fileTile(BuildContext context, DesignFile f) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => openDesignFile(f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: newBorderColor),
        ),
        child: Row(
          children: [
            Icon(
              f.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.insert_drive_file_outlined,
              size: 16,
              color: f.isPdf ? opRed : opBlue,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                f.name.isEmpty ? 'Document' : f.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: newTextPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: newTextSecondary,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Opens a non-image design file outside the app.
Future<void> openDesignFile(DesignFile f) async {
  if (f.url.isEmpty) return;
  try {
    final ok = await launchUrl(
      Uri.parse(f.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      opSnack('Could not open', 'No app on this phone can open ${f.name}.');
    }
  } catch (e) {
    opSnack('Could not open', '$e');
  }
}

/// Full-screen drawing viewer: pinch to zoom, swipe between the images of the
/// same drawing / material.
class DesignGalleryView extends StatefulWidget {
  final List<DesignFile> files;
  final int index;
  final String title;
  const DesignGalleryView({
    super.key,
    required this.files,
    required this.index,
    required this.title,
  });

  @override
  State<DesignGalleryView> createState() => _DesignGalleryViewState();
}

class _DesignGalleryViewState extends State<DesignGalleryView> {
  late final PageController _pages = PageController(initialPage: widget.index);
  late int _at = widget.index;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.files[_at];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.files.length == 1
                  ? f.name
                  : '${_at + 1} of ${widget.files.length} · ${f.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.files.length,
        onPageChanged: (i) => setState(() => _at = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 6,
          child: Center(
            child: Image.network(
              widget.files[i].url,
              fit: BoxFit.contain,
              loadingBuilder: (_, child, p) => p == null
                  ? child
                  : const CircularProgressIndicator(color: Colors.white),
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'This drawing could not be loaded.\nGo back and refresh the '
                  'section — the link may have expired.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder blocks while the pack loads — the section keeps its shape
/// instead of jumping once the drawings arrive.
class _DesignShimmer extends StatelessWidget {
  const _DesignShimmer();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _bar(120, 9),
      const SizedBox(height: 10),
      _block(64),
      const SizedBox(height: 9),
      _block(64),
    ],
  );

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: newBorderColor.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _block(double h) => Container(
    width: double.infinity,
    height: h,
    decoration: BoxDecoration(
      color: newSurfaceColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: newBorderColor),
    ),
  );
}
