// Regenerates the Android + iOS launcher icons from the 1024px brand plate.
//
// Why this exists: the shipped icons used the whole brand plate (border, wordmark
// and tagline, full bleed) as the adaptive-icon *foreground*. Android masks the
// outer ~18/108 of a foreground on every side, so the wordmark was cropped to
// "igitalER" on the launcher and on the Android 12+ splash screen, which reuses
// that same foreground. A foreground must be transparent art sitting well inside
// the 66/108 safe zone, so we lift just the cube mark out of the plate and place
// it at 58% of the canvas. The wordmark stays on the Play Store icon, which is
// never masked and is shown large enough to read.
//
// Run from the project root:  dart run tool/make_launcher_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

/// Source art: the untouched 1024px brand plate. Kept under tool/ rather than
/// assets/ so it is not bundled into the app, and deliberately NOT one of the
/// files this script writes — an earlier revision read the iOS 1024 icon, which
/// it then overwrote, so a second run would have re-cropped its own output.
const _source = 'tool/brand/dicor_plate_1024.png';

/// Fraction of the icon canvas the mark occupies. 0.58 keeps it inside the
/// 66/108 (0.611) adaptive-icon safe zone with a little room to spare.
const _adaptiveScale = 0.58;

/// Legacy/iOS canvases are not mask-cropped, so the mark can breathe a bit more.
const _plateScale = 0.62;

const _androidDensities = <String, int>{
  'mdpi': 1,
  'hdpi': 2, // x1.5 — handled via the dp tables below
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

/// Adaptive foreground is 108dp; legacy launcher icon is 48dp.
const _foregroundPx = <String, int>{
  'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432,
};
const _legacyPx = <String, int>{
  'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192,
};

late final img.Color _white;
late final img.Color _brandBlue;

void main() {
  final src = img.decodePng(File(_source).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode $_source');
    exit(1);
  }
  _white = img.ColorRgba8(255, 255, 255, 255);
  _brandBlue = _sampleBorderColour(src);
  stdout.writeln('brand blue: #${_hex(_brandBlue)}');

  final mark = _extractMark(src);
  stdout.writeln('mark: ${mark.width}x${mark.height}');

  _writeAndroid(mark);
  _writeIos(mark);
  _writeAppLogo(mark);
  stdout.writeln('done');
}

// ---------------------------------------------------------------------------
// Extracting the cube mark
// ---------------------------------------------------------------------------

/// True when a pixel is plate background rather than artwork.
bool _isBackdrop(img.Pixel p) {
  if (p.a < 24) return true;
  return p.r >= 218 && p.g >= 218 && p.b >= 218;
}

/// Finds the cube by scanning down the plate interior for the first band of
/// rows containing artwork, and stopping at the gutter above the wordmark.
/// Detected rather than hard-coded so a re-cut of the source plate still works.
({int top, int bottom}) _markBand(img.Image src, int inset) {
  final rows = <bool>[];
  for (var y = 0; y < src.height; y++) {
    var content = false;
    for (var x = inset; x < src.width - inset && !content; x++) {
      if (!_isBackdrop(src.getPixel(x, y))) content = true;
    }
    rows.add(content);
  }

  var top = -1, bottom = -1, gap = 0;
  const gutter = 12; // blank rows that mean "the mark ended"
  for (var y = inset; y < src.height - inset; y++) {
    if (rows[y]) {
      if (top < 0) top = y;
      bottom = y;
      gap = 0;
    } else if (top >= 0) {
      if (++gap >= gutter) break;
    }
  }
  if (top < 0) throw StateError('no artwork found inside the plate');
  return (top: top, bottom: bottom);
}

/// Lifts the cube out of the plate: flood-fills the near-white backdrop inward
/// from the crop border so the white gaps *between* the cube's layers — which
/// connect to the outside — are removed too, while the layers themselves stay.
/// Naive white-keying would also punch holes in any light artwork; flooding
/// from the border only removes background that is actually reachable.
img.Image _extractMark(img.Image src) {
  const inset = 100; // skip the plate's blue border ring
  final band = _markBand(src, inset);
  final x0 = inset, x1 = src.width - inset;
  final y0 = (band.top - 6).clamp(0, src.height - 1);
  final y1 = (band.bottom + 6).clamp(0, src.height - 1);
  final w = x1 - x0, h = y1 - y0 + 1;

  final region = img.copyCrop(src, x: x0, y: y0, width: w, height: h);

  // Flood fill (iterative, 4-connected) from every border pixel that is backdrop.
  final filled = List<bool>.filled(w * h, false);
  final stack = <int>[];
  void seed(int x, int y) {
    final i = y * w + x;
    if (filled[i]) return;
    if (!_isBackdrop(region.getPixel(x, y))) return;
    filled[i] = true;
    stack.add(i);
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }
  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    final x = i % w, y = i ~/ w;
    if (x > 0) seed(x - 1, y);
    if (x < w - 1) seed(x + 1, y);
    if (y > 0) seed(x, y - 1);
    if (y < h - 1) seed(x, y + 1);
  }

  // Everything the fill could not reach is the mark.
  final out = img.Image(width: w, height: h, numChannels: 4);
  var minX = w, minY = h, maxX = -1, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (filled[y * w + x]) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      final p = region.getPixel(x, y);
      out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  return img.copyCrop(out,
      x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

/// The plate's border ring colour, sampled at the top-centre of the frame.
img.Color _sampleBorderColour(img.Image src) {
  final x = src.width ~/ 2;
  for (var y = 0; y < src.height ~/ 4; y++) {
    final p = src.getPixel(x, y);
    if (p.a > 200 && p.b > p.r + 50 && p.b > 140) {
      return img.ColorRgba8(p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
    }
  }
  return img.ColorRgba8(29, 122, 246, 255);
}

String _hex(img.Color c) => [c.r, c.g, c.b]
    .map((v) => v.toInt().toRadixString(16).padLeft(2, '0'))
    .join()
    .toUpperCase();

// ---------------------------------------------------------------------------
// Composition
// ---------------------------------------------------------------------------

/// Centres [mark] on a [size]x[size] canvas, scaled so its longest side is
/// [scale] of the canvas. Aspect ratio is preserved — force-resizing a
/// non-square mark to a square is what distorts these icons.
void _placeMark(img.Image canvas, img.Image mark, double scale) {
  final size = canvas.width;
  final target = (size * scale).round();
  final ratio = target / (mark.width > mark.height ? mark.width : mark.height);
  final w = (mark.width * ratio).round().clamp(1, size);
  final h = (mark.height * ratio).round().clamp(1, size);
  final resized =
      img.copyResize(mark, width: w, height: h, interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, resized,
      dstX: (size - w) ~/ 2, dstY: (size - h) ~/ 2);
}

img.Image _transparentCanvas(int size) =>
    img.Image(width: size, height: size, numChannels: 4);

/// White rounded-square plate with the brand ring, for legacy (API < 26) icons.
img.Image _squarePlate(int size, img.Image mark) {
  final c = _transparentCanvas(size);
  final r = (size * 0.22).round();
  final ring = (size * 0.055).clamp(1, size).round();
  img.fillRect(c, x1: 0, y1: 0, x2: size - 1, y2: size - 1, radius: r, color: _brandBlue);
  img.fillRect(c,
      x1: ring,
      y1: ring,
      x2: size - 1 - ring,
      y2: size - 1 - ring,
      radius: (r - ring).clamp(0, size),
      color: _white);
  _placeMark(c, mark, _plateScale);
  return c;
}

/// White disc with the brand ring, for `ic_launcher_round`.
img.Image _roundPlate(int size, img.Image mark) {
  final c = _transparentCanvas(size);
  final cx = size ~/ 2, cy = size ~/ 2;
  final outer = size ~/ 2;
  final ring = (size * 0.055).clamp(1, size).round();
  img.fillCircle(c, x: cx, y: cy, radius: outer, color: _brandBlue);
  img.fillCircle(c, x: cx, y: cy, radius: outer - ring, color: _white);
  _placeMark(c, mark, _plateScale);
  return c;
}

/// Opaque white square — iOS/macOS/watchOS apply their own mask and reject alpha.
img.Image _opaqueSquare(int size, img.Image mark) {
  final c = img.Image(width: size, height: size, numChannels: 3);
  img.fill(c, color: _white);
  _placeMark(c, mark, _plateScale);
  return c;
}

/// Flat silhouette for Android 13+ themed icons; the system tints it.
img.Image _monochrome(img.Image mark) {
  final out = img.Image(width: mark.width, height: mark.height, numChannels: 4);
  for (var y = 0; y < mark.height; y++) {
    for (var x = 0; x < mark.width; x++) {
      out.setPixelRgba(x, y, 0, 0, 0, mark.getPixel(x, y).a.toInt());
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Emitting files
// ---------------------------------------------------------------------------

void _png(String path, img.Image image) {
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(img.encodePng(image));
}

void _writeAndroid(img.Image mark) {
  const res = 'android/app/src/main/res';
  final mono = _monochrome(mark);

  for (final density in _androidDensities.keys) {
    final fg = _transparentCanvas(_foregroundPx[density]!);
    _placeMark(fg, mark, _adaptiveScale);
    _png('$res/mipmap-$density/ic_launcher_foreground.png', fg);

    final mo = _transparentCanvas(_foregroundPx[density]!);
    _placeMark(mo, mono, _adaptiveScale);
    _png('$res/mipmap-$density/ic_launcher_monochrome.png', mo);

    final size = _legacyPx[density]!;
    _png('$res/mipmap-$density/ic_launcher.png', _squarePlate(size, mark));
    _png('$res/mipmap-$density/ic_launcher_round.png', _roundPlate(size, mark));
  }

  // Both adaptive XMLs must be written: flutter_launcher_icons only ever
  // rewrites ic_launcher.xml, which is how ic_launcher_round.xml kept pointing
  // at the Android Studio template's green-grid background.
  const adaptive = '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
''';
  File('$res/mipmap-anydpi-v26/ic_launcher.xml').writeAsStringSync(adaptive);
  File('$res/mipmap-anydpi-v26/ic_launcher_round.xml').writeAsStringSync(adaptive);

  File('$res/values/colors.xml').writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
''');

  // The green-grid vector this used to point at is now unreferenced; leaving it
  // around is how it gets picked up again by the next regeneration.
  final greenGrid = File('$res/drawable/ic_launcher_background.xml');
  if (greenGrid.existsSync()) greenGrid.deleteSync();
}

void _writeIos(img.Image mark) {
  const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  for (final f in Directory(dir).listSync().whereType<File>()) {
    if (!f.path.endsWith('.png')) continue;
    final existing = img.decodePng(f.readAsBytesSync());
    if (existing == null) continue;
    _png(f.path, _opaqueSquare(existing.width, mark));
  }
}

/// In-app splash / drawer logo. Transparent so it sits on the app's own
/// background, and mark-only because the splash already prints "Dicor ERP".
void _writeAppLogo(img.Image mark) {
  final c = _transparentCanvas(512);
  _placeMark(c, mark, 0.92);
  _png('assets/images/dicor.png', c);
}
