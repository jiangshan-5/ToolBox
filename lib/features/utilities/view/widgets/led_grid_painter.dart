import 'package:flutter/material.dart';

class GridMatrixPainter extends CustomPainter {
  final Color dotColor;
  final double gridSpacing;
  final double dotRadius;

  GridMatrixPainter({
    required this.dotColor,
    this.gridSpacing = 16.0,
    this.dotRadius = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += gridSpacing) {
      for (double y = 0; y < size.height; y += gridSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridMatrixPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.gridSpacing != gridSpacing ||
      oldDelegate.dotRadius != dotRadius;
}
