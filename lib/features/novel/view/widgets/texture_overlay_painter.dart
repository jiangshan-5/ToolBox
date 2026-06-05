import 'package:flutter/material.dart';
import 'dart:math';

class TextureOverlayPainter extends CustomPainter {
  final int themeIndex;
  TextureOverlayPainter(this.themeIndex);

  @override
  void paint(Canvas canvas, Size size) {
    if (themeIndex == 0) {
      // Rice paper texture
      final Paint linePaint = Paint()
        ..color = const Color(0x0E000000)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      final Paint dotPaint = Paint()
        ..color = const Color(0x08000000)
        ..style = PaintingStyle.fill;
        
      final random = Random(42);
      
      final int fiberCount = (size.width * size.height / 3000).round().clamp(100, 1000);
      for (int i = 0; i < fiberCount; i++) {
        final double x = random.nextDouble() * size.width;
        final double y = random.nextDouble() * size.height;
        final double length = random.nextDouble() * 12 + 4;
        final double angle = random.nextDouble() * pi * 2;
        
        final double endX = x + cos(angle) * length;
        final double endY = y + sin(angle) * length;
        
        canvas.drawLine(Offset(x, y), Offset(endX, endY), linePaint);
      }
      
      final int speckleCount = (size.width * size.height / 8000).round().clamp(50, 400);
      for (int i = 0; i < speckleCount; i++) {
        final double x = random.nextDouble() * size.width;
        final double y = random.nextDouble() * size.height;
        final double radius = random.nextDouble() * 1.5 + 0.5;
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    } else if (themeIndex == 4) {
      // Abyss theme: cosmic glow/rings
      final Paint paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.7, -0.6),
          radius: 1.2,
          colors: [
            const Color(0x1F7A1A7A),
            const Color(0x0C1A1A5A),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      final Paint glowPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.6, 0.8),
          radius: 1.5,
          colors: [
            const Color(0x180D47A1),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

      final random = Random(12345);
      final int starCount = (size.width * size.height / 15000).round().clamp(30, 200);
      final Paint starPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < starCount; i++) {
        final double x = random.nextDouble() * size.width;
        final double y = random.nextDouble() * size.height;
        final double opacity = random.nextDouble() * 0.15 + 0.05;
        starPaint.color = Color.fromRGBO(208, 208, 255, opacity);
        final double radius = random.nextDouble() * 1.2 + 0.4;
        canvas.drawCircle(Offset(x, y), radius, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TextureOverlayPainter oldDelegate) {
    return oldDelegate.themeIndex != themeIndex;
  }
}
