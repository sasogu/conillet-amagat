import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Dibuja una cara de conejo geométrica y original.
void paintBunnyFace(
  Canvas canvas,
  Offset center,
  double radius, {
  required Color body,
  required Color eye,
  Color? outline,
  Color? innerEar,
}) {
  final head = Rect.fromCircle(
    center: center.translate(0, radius * 0.10),
    radius: radius,
  );
  final bodyPaint = Paint()..color = body;

  for (final side in const [-1.0, 1.0]) {
    canvas.save();
    canvas.translate(
      head.center.dx + side * radius * 0.44,
      head.center.dy - radius * 1.02,
    );
    canvas.rotate(side * 0.10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 0.54,
        height: radius * 1.46,
      ),
      bodyPaint,
    );
    if (innerEar != null) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 0.26,
          height: radius * 1.0,
        ),
        Paint()..color = innerEar,
      );
    }
    canvas.restore();
  }

  canvas.drawCircle(head.center, radius, bodyPaint);

  final eyePaint = Paint()..color = eye;
  final eyeRadius = math.max(radius * 0.15, 1.1);
  canvas.drawCircle(
    head.center.translate(-radius * 0.36, -radius * 0.06),
    eyeRadius,
    eyePaint,
  );
  canvas.drawCircle(
    head.center.translate(radius * 0.36, -radius * 0.06),
    eyeRadius,
    eyePaint,
  );

  final nosePaint = Paint()..color = eye;
  final nose = Path()
    ..moveTo(head.center.dx - radius * 0.12, head.center.dy + radius * 0.26)
    ..lineTo(head.center.dx + radius * 0.12, head.center.dy + radius * 0.26)
    ..lineTo(head.center.dx, head.center.dy + radius * 0.42)
    ..close();
  canvas.drawPath(nose, nosePaint);

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: head.center.translate(0, radius * 0.56),
        width: radius * 0.20,
        height: radius * 0.16,
      ),
      Radius.circular(radius * 0.05),
    ),
    Paint()..color = const Color(0xFFFFF8EA),
  );

  if (outline != null) {
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16;
    canvas.drawCircle(head.center, radius, outlinePaint);
  }
}

class BunnyLogo extends StatelessWidget {
  const BunnyLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BunnyLogoPainter()),
    );
  }
}

class _BunnyLogoPainter extends CustomPainter {
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

    paintBunnyFace(
      canvas,
      Offset(size.width / 2, size.height * 0.57),
      size.width * 0.22,
      body: const Color(0xFF2F2A26),
      eye: const Color(0xFFFFF8EA),
      innerEar: const Color(0xFFE7A79E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
