import 'package:flutter/material.dart';

class CarrotIcon extends StatelessWidget {
  const CarrotIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CarrotPainter()),
    );
  }
}

class _CarrotPainter extends CustomPainter {
  static const _orange = Color(0xFFE8832C);
  static const _leaf = Color(0xFF4F8B4A);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final paint = Paint()..color = _orange;

    final body = Path()
      ..moveTo(width * 0.32, height * 0.26)
      ..quadraticBezierTo(
        width * 0.50,
        height * 0.16,
        width * 0.68,
        height * 0.26,
      )
      ..quadraticBezierTo(
        width * 0.62,
        height * 0.68,
        width * 0.50,
        height * 0.98,
      )
      ..quadraticBezierTo(
        width * 0.38,
        height * 0.68,
        width * 0.32,
        height * 0.26,
      )
      ..close();
    canvas.drawPath(body, paint);

    final leafPaint = Paint()
      ..color = _leaf
      ..strokeWidth = width * 0.10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leafCenter = Offset(width * 0.50, height * 0.24);
    for (final angle in [-0.85, 0.0, 0.85]) {
      final end = Offset(
        leafCenter.dx + angle * width * 0.22,
        leafCenter.dy - height * 0.20,
      );
      canvas.drawLine(leafCenter, end, leafPaint);
    }

    final ridgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..strokeWidth = width * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(width * 0.44, height * 0.44),
      Offset(width * 0.40, height * 0.58),
      ridgePaint,
    );
    canvas.drawLine(
      Offset(width * 0.55, height * 0.40),
      Offset(width * 0.52, height * 0.54),
      ridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
