import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dibuja una cara de gato geométrica y original.
void paintCatFace(
  Canvas canvas,
  Offset center,
  double radius, {
  required Color body,
  required Color eye,
  Color? outline,
}) {
  final head = Rect.fromCircle(
    center: center.translate(0, radius * 0.08),
    radius: radius,
  );
  final bodyPaint = Paint()..color = body;

  final path = Path()
    ..moveTo(head.left + head.width * 0.02, head.center.dy - head.height * 0.18)
    ..lineTo(head.left + head.width * 0.20, head.top - head.height * 0.22)
    ..lineTo(head.left + head.width * 0.48, head.top + head.height * 0.12)
    ..lineTo(head.right - head.width * 0.48, head.top + head.height * 0.12)
    ..lineTo(head.right - head.width * 0.20, head.top - head.height * 0.22)
    ..lineTo(
      head.right - head.width * 0.02,
      head.center.dy - head.height * 0.18,
    )
    ..close();
  canvas.drawPath(path, bodyPaint);
  canvas.drawCircle(head.center, radius, bodyPaint);

  final eyePaint = Paint()..color = eye;
  final eyeRadius = math.max(radius * 0.15, 1.1);
  canvas.drawCircle(
    head.center.translate(-radius * 0.38, -radius * 0.08),
    eyeRadius,
    eyePaint,
  );
  canvas.drawCircle(
    head.center.translate(radius * 0.38, -radius * 0.08),
    eyeRadius,
    eyePaint,
  );

  final nosePaint = Paint()..color = eye;
  final nose = Path()
    ..moveTo(head.center.dx - radius * 0.13, head.center.dy + radius * 0.28)
    ..lineTo(head.center.dx + radius * 0.13, head.center.dy + radius * 0.28)
    ..lineTo(head.center.dx, head.center.dy + radius * 0.45)
    ..close();
  canvas.drawPath(nose, nosePaint);

  if (outline != null) {
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16;
    canvas.drawCircle(head.center, radius, outlinePaint);
  }
}

class CatLogo extends StatelessWidget {
  const CatLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CatLogoPainter()),
    );
  }
}

class _CatLogoPainter extends CustomPainter {
  static const _tiles = [
    Color(0xFFF3C6B8),
    Color(0xFFF4E1AD),
    Color(0xFFCDE3C0),
    Color(0xFFBFDCE8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = size.width * 0.24;
    final background = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(
      background,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3C8D7C), Color(0xFF225C53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    final inset = size.width * 0.14;
    final gap = size.width * 0.035;
    final tileSize = (size.width - inset * 2 - gap) / 2;
    final tileRadius = Radius.circular(tileSize * 0.18);
    for (var index = 0; index < 4; index++) {
      final row = index ~/ 2;
      final col = index % 2;
      final tile = Rect.fromLTWH(
        inset + col * (tileSize + gap),
        inset + row * (tileSize + gap),
        tileSize,
        tileSize,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(tile, tileRadius),
        Paint()..color = _tiles[index],
      );
    }

    paintCatFace(
      canvas,
      Offset(size.width / 2, size.height * 0.53),
      size.width * 0.245,
      body: const Color(0xFF2F2A26),
      eye: const Color(0xFFFFF8EA),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
