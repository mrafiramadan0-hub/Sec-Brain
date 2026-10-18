import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secbrain_app/widgets/secbrain_logo.dart';

void main() {
  test('Generate high resolution PNG logo assets and launcher icons', () async {
    // 1. Function to render SecBrainEmblemPainter to PNG bytes
    Future<Uint8List> renderIconToPng(int size, {Color? bg}) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const painter = SecBrainEmblemPainter(color: secBrainPine);

      if (bg != null) {
        final bgPaint = Paint()..color = bg;
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
          bgPaint,
        );
      }

      painter.paint(canvas, Size(size.toDouble(), size.toDouble()));
      final picture = recorder.endRecording();
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    }

    // 2. Function to render Full Brandmark (Icon + SecBrain + SECURE INTELLIGENCE)
    Future<Uint8List> renderFullLogoToPng(int width, int height) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // White/transparent background
      final iconSize = height * 0.58;
      final iconX = width * 0.08;
      final iconY = (height - iconSize) / 2;

      canvas.save();
      canvas.translate(iconX, iconY);
      const emblemPainter = SecBrainEmblemPainter(color: secBrainPine);
      emblemPainter.paint(canvas, Size(iconSize, iconSize));
      canvas.restore();

      // Text Painter for SecBrain
      final fontSize = iconSize * 0.72;
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: 'Sec',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: secBrainPine,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Brain',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: secBrainDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textX = iconX + iconSize + width * 0.035;
      final textY = iconY + (iconSize - textPainter.height) / 2 - height * 0.06;
      textPainter.paint(canvas, Offset(textX, textY));

      // Subtitle "SECURE INTELLIGENCE"
      final subFontSize = fontSize * 0.32;
      final subSpan = TextSpan(
        text: 'SECURE INTELLIGENCE',
        style: TextStyle(
          fontSize: subFontSize,
          fontWeight: FontWeight.w700,
          color: secBrainSub,
          letterSpacing: subFontSize * 0.35,
        ),
      );
      final subPainter = TextPainter(
        text: subSpan,
        textDirection: TextDirection.ltr,
      );
      subPainter.layout();
      subPainter.paint(
        canvas,
        Offset(textX, textY + textPainter.height + height * 0.03),
      );

      final picture = recorder.endRecording();
      final img = await picture.toImage(width, height);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    }

    // Target Directories
    final assetsDir = Directory('assets/images');
    if (!assetsDir.existsSync()) {
      assetsDir.createSync(recursive: true);
    }

    // Write Assets
    final icon512 = await renderIconToPng(512);
    File('assets/images/logo_icon.png').writeAsBytesSync(icon512);

    final fullLogo = await renderFullLogoToPng(1024, 400);
    File('assets/images/logo.png').writeAsBytesSync(fullLogo);
    File('assets/images/logo_full.png').writeAsBytesSync(fullLogo);

    // Android Launcher Icons (with white background / solid for crisp home screen icon)
    final mipmaps = {
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    };

    for (final entry in mipmaps.entries) {
      final file = File(entry.key);
      if (file.parent.existsSync()) {
        final bytes = await renderIconToPng(entry.value, bg: Colors.white);
        file.writeAsBytesSync(bytes);
      }
    }

    expect(File('assets/images/logo.png').existsSync(), true);
    expect(File('assets/images/logo_icon.png').existsSync(), true);
  });
}
