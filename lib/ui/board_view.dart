import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/game_store.dart';
import '../game/puzzle.dart';
import '../theme.dart';
import 'cat_art.dart';

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.puzzle,
    required this.marks,
    required this.blocked,
    required this.conflicts,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDragMark,
    required this.onDragEnd,
    this.enabled = true,
  });

  final Puzzle puzzle;
  final List<CellMark> marks;
  final Set<int> blocked;
  final Set<int> conflicts;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onDoubleTap;
  final ValueChanged<int> onDragMark;
  final VoidCallback onDragEnd;
  final bool enabled;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  Set<int> _visited = {};

  int? _cellAt(Offset position, double side) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx >= side ||
        position.dy >= side) {
      return null;
    }
    final size = widget.puzzle.size;
    final col = (position.dx / side * size).floor().clamp(0, size - 1);
    final row = (position.dy / side * size).floor().clamp(0, size - 1);
    return widget.puzzle.cellAt(row, col);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BoardColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final board = ClipRRect(
          borderRadius: BorderRadius.circular(math.max(14, side * 0.035)),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.square(side),
              painter: _BoardPainter(
                puzzle: widget.puzzle,
                marks: widget.marks,
                blocked: widget.blocked,
                conflicts: widget.conflicts,
                colors: colors,
              ),
            ),
          ),
        );

        if (!widget.enabled) {
          return SizedBox.square(dimension: side, child: board);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final cell = _cellAt(details.localPosition, side);
            if (cell != null) widget.onTap(cell);
          },
          onDoubleTapDown: (details) {
            final cell = _cellAt(details.localPosition, side);
            if (cell != null) widget.onDoubleTap(cell);
          },
          onPanStart: (details) {
            final cell = _cellAt(details.localPosition, side);
            if (cell == null) return;
            _visited = {cell};
            widget.onDragMark(cell);
          },
          onPanUpdate: (details) {
            final cell = _cellAt(details.localPosition, side);
            if (cell == null || _visited.contains(cell)) return;
            _visited.add(cell);
            widget.onDragMark(cell);
          },
          onPanEnd: (_) {
            _visited = {};
            widget.onDragEnd();
          },
          onPanCancel: () {
            _visited = {};
            widget.onDragEnd();
          },
          child: SizedBox.square(dimension: side, child: board),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.puzzle,
    required this.marks,
    required this.blocked,
    required this.conflicts,
    required this.colors,
  });

  final Puzzle puzzle;
  final List<CellMark> marks;
  final Set<int> blocked;
  final Set<int> conflicts;
  final BoardColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.size;
    final cellSize = size.width / n;

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      final rect = Rect.fromLTWH(
        col * cellSize,
        row * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(
        rect,
        Paint()..color = colors.regionColor(puzzle.regions[cell]),
      );
      if (conflicts.contains(cell)) {
        canvas.drawRect(
          rect.deflate(1),
          Paint()..color = colors.conflict.withValues(alpha: 0.20),
        );
      }
    }

    final gridPaint = Paint()
      ..color = colors.grid
      ..strokeWidth = 0.8;
    for (var index = 1; index < n; index++) {
      final offset = index * cellSize;
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        gridPaint,
      );
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), gridPaint);
    }

    final borderPaint = Paint()
      ..color = colors.border
      ..strokeWidth = math.max(2.5, cellSize * 0.075)
      ..strokeCap = StrokeCap.square;
    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      final region = puzzle.regions[cell];
      final left = col * cellSize;
      final top = row * cellSize;
      final right = left + cellSize;
      final bottom = top + cellSize;
      if (row == 0 || puzzle.regions[cell - n] != region) {
        canvas.drawLine(Offset(left, top), Offset(right, top), borderPaint);
      }
      if (col == 0 || puzzle.regions[cell - 1] != region) {
        canvas.drawLine(Offset(left, top), Offset(left, bottom), borderPaint);
      }
      if (row == n - 1) {
        canvas.drawLine(
          Offset(left, bottom),
          Offset(right, bottom),
          borderPaint,
        );
      }
      if (col == n - 1) {
        canvas.drawLine(Offset(right, top), Offset(right, bottom), borderPaint);
      }
    }

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      final rect = Rect.fromLTWH(
        col * cellSize,
        row * cellSize,
        cellSize,
        cellSize,
      );
      final mark = marks[cell];
      if (mark == CellMark.cat) {
        paintCatFace(
          canvas,
          rect.center,
          cellSize * 0.235,
          body: colors.cat,
          eye: colors.catEye,
        );
        if (conflicts.contains(cell)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(cellSize * 0.06),
              Radius.circular(cellSize * 0.18),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(2, cellSize * 0.055)
              ..color = colors.conflict,
          );
        }
      } else if (mark == CellMark.cross) {
        _paintCross(canvas, rect, colors.cross, cellSize, strong: true);
      } else if (blocked.contains(cell)) {
        _paintCross(canvas, rect, colors.autoCross, cellSize, strong: false);
      }
    }
  }

  void _paintCross(
    Canvas canvas,
    Rect rect,
    Color color,
    double cellSize, {
    required bool strong,
  }) {
    final inset = cellSize * 0.27;
    final paint = Paint()
      ..color = strong ? color : color.withValues(alpha: 0.62)
      ..strokeWidth = math.max(1.2, cellSize * (strong ? 0.055 : 0.042))
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      rect.topLeft.translate(inset, inset),
      rect.bottomRight.translate(-inset, -inset),
      paint,
    );
    canvas.drawLine(
      rect.topRight.translate(-inset, inset),
      rect.bottomLeft.translate(inset, -inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
