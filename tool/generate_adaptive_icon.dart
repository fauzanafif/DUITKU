// One-off tool: generates a proper transparent-background adaptive-icon
// foreground from the existing flattened (opaque, full-bleed) legacy
// launcher icon, so Android's adaptive-icon mask has margin to crop
// without cutting into the artwork or exposing the background layer.
//
// Run once with: dart run tool/generate_adaptive_icon.dart
// Safe to delete after running — it only touches files under
// android/app/src/main/res/mipmap-*/.
import 'dart:io';

import 'package:image/image.dart' as img;

// Android's adaptive-icon spec: a 108dp canvas where only the inner 66dp
// (~61%) is guaranteed visible after masking. Scaling the source icon to
// 60% and centering it on a transparent canvas keeps the full artwork
// inside that safe zone on every launcher mask shape.
const double _safeZoneScale = 0.60;

void main() {
  final resDir = Directory('android/app/src/main/res');
  final densityDirs = resDir
      .listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('mipmap-') && !d.path.contains('anydpi'));

  for (final dir in densityDirs) {
    final source = File('${dir.path}/ic_launcher.png');
    if (!source.existsSync()) continue;

    final decoded = img.decodePng(source.readAsBytesSync());
    if (decoded == null) continue;

    final canvasSize = decoded.width;
    final foreground = img.Image(
      width: canvasSize,
      height: canvasSize,
      numChannels: 4,
    );
    img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0));

    final targetSize = (canvasSize * _safeZoneScale).round();
    final resized = img.copyResize(
      decoded,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.average,
    );
    final offset = ((canvasSize - targetSize) / 2).round();
    img.compositeImage(foreground, resized, dstX: offset, dstY: offset);

    final outFile = File('${dir.path}/ic_launcher_foreground.png');
    outFile.writeAsBytesSync(img.encodePng(foreground));
    stdout.writeln('Wrote ${outFile.path} (${canvasSize}x$canvasSize)');
  }
}
