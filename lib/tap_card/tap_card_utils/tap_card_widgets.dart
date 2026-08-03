// Shared bits of the Tap Card module: the palette every view uses, the category
// chips/badges, the image resolver, and the rendered card used for QR sharing
// and save-to-gallery.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:newdigitalerp/utils/app_constant_new.dart';

import '../tap_card_models.dart';

// Local palette, declared per module the way the other ribbel list views do.
const Color kTapPrimary = purpleColor;
const Color kTapBg = Color(0xFFF6F7FB);
const Color kTapSurface = Colors.white;
const Color kTapBorder = Color(0xFFE4E7F0);
const Color kTapTextPrimary = Color(0xFF111827);
const Color kTapTextSecondary = Color(0xFF6B7280);
const Color kTapTextHint = Color(0xFF9CA3AF);

/// Category accent colour, matching TapCard's mapping.
Color tapCategoryColor(String? category) {
  switch (category) {
    case TapCardCategory.personal:
      return const Color(0xFF7C3AED);
    case TapCardCategory.other:
      return newOrangeColor;
    default:
      return kTapPrimary;
  }
}

/// Resolve a stored image value to something Image can render: an http URL
/// becomes a NetworkImage, anything else is treated as a local file path (a
/// photo taken offline that hasn't uploaded yet).
ImageProvider? tapCardImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return NetworkImage(path);
  final f = File(path);
  return f.existsSync() ? FileImage(f) : null;
}

/// Renders a stored image value, with a graceful placeholder when it's missing
/// or fails to load.
class TapCardImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  const TapCardImage(this.path, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final provider = tapCardImageProvider(path);
    if (provider == null) return const _ImagePlaceholder();
    return Image(
      image: provider,
      fit: fit,
      width: double.infinity,
      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      loadingBuilder: (ctx, child, progress) => progress == null
          ? child
          : const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kTapPrimary,
                ),
              ),
            ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF1F3F9),
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported_outlined,
      size: 22,
      color: kTapTextHint,
    ),
  );
}

/// The Business / Personal / Other selector on the create form.
class TapCategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const TapCategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TapCardCategory.all.map((cat) {
        final active = cat == selected;
        final color = tapCategoryColor(cat);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: 0.10) : kTapSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? color : kTapBorder,
                  width: active ? 1.4 : 1,
                ),
              ),
              child: Text(
                cat,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? color : kTapTextSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Small pill showing a card's category.
class TapCategoryBadge extends StatelessWidget {
  final String? category;
  const TapCategoryBadge(this.category, {super.key});

  @override
  Widget build(BuildContext context) {
    final label = (category ?? '').isEmpty
        ? TapCardCategory.business
        : category!;
    final color = tapCategoryColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// "Not synced yet" marker shown on cards still sitting in the write queue.
class TapPendingBadge extends StatelessWidget {
  const TapPendingBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: newOrangeLightColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.cloud_off_rounded, size: 11, color: newOrangeColor),
        SizedBox(width: 4),
        Text(
          'Not synced',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: newOrangeColor,
          ),
        ),
      ],
    ),
  );
}

/// The circular initial avatar used in the list and detail header.
class TapCardAvatar extends StatelessWidget {
  final TapCardModel card;
  final double size;
  const TapCardAvatar(this.card, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final color = tapCategoryColor(card.category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        card.initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// The gradient business card rendered for sharing and save-to-gallery. Kept as
/// a plain widget (no screenshot dependency here) so the detail screen can both
/// display it and capture it.
class TapCardPreview extends StatelessWidget {
  final TapCardModel card;
  const TapCardPreview(this.card, {super.key});

  @override
  Widget build(BuildContext context) {
    final accent = tapCategoryColor(card.category);
    return Container(
      width: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  card.initial,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if ((card.title ?? '').isNotEmpty)
                      Text(
                        card.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((card.company ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                card.company!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if ((card.phone ?? '').isNotEmpty)
            _row(Icons.phone_rounded, card.phone!),
          if ((card.email ?? '').isNotEmpty)
            _row(Icons.email_rounded, card.email!),
          if ((card.website ?? '').isNotEmpty)
            _row(Icons.language_rounded, card.website!),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
