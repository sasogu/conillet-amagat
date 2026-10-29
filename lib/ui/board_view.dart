import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/game_store.dart';
import '../game/bunny_skin.dart';
import '../game/puzzle.dart';
import '../theme.dart';
import 'bunny_art.dart';

class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.puzzle,
    required this.marks,
    required this.blocked,
    required this.conflicts,
    this.given = const {},
    this.skin = whiteBunnySkin,
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
  final Set<int> given;
  final BunnySkin skin;
  final ValueChanged<int> onTap;
  final ValueChanged<int> onDoubleTap;
  final ValueChanged<int> onDragMark;
  final VoidCallback onDragEnd;
  final bool enabled;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  Set<int> _visited = {};
  late final AnimationController _placementAnimation;
  late List<CellMark> _previousMarks;
  int? _placedCell;

  @override
  void initState() {
    super.initState();
    _previousMarks = List.of(widget.marks);
    _placementAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_previousMarks.length != widget.marks.length) {
      _previousMarks = List.of(widget.marks);
      return;
    }
    for (var cell = 0; cell < widget.marks.length; cell++) {
      if (widget.marks[cell] == CellMark.bunny &&
          _previousMarks[cell] != CellMark.bunny &&
          !widget.given.contains(cell)) {
        _placedCell = cell;
        _placementAnimation.forward(from: 0);
        break;
      }
    }
    _previousMarks = List.of(widget.marks);
  }

  @override
  void dispose() {
    _placementAnimation.dispose();
    super.dispose();
  }

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
                given: widget.given,
                skin: widget.skin,
                colors: colors,
                placedCell: _placedCell,
                placementProgress: _placementAnimation.value,
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
    required this.given,
    required this.skin,
    required this.colors,
    required this.placedCell,
    required this.placementProgress,
  });

  final Puzzle puzzle;
  final List<CellMark> marks;
  final Set<int> blocked;
  final Set<int> conflicts;
  final Set<int> given;
  final BunnySkin skin;
  final BoardColors colors;
  final int? placedCell;
  final double placementProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final n = puzzle.size;
    final cellSize = size.width / n;
    final gap = math.max(1.6, cellSize * 0.04);
    final tileRadius = Radius.circular(cellSize * 0.14);

    canvas.drawRect(Offset.zero & size, Paint()..color = colors.gap);

    for (var cell = 0; cell < puzzle.cellCount; cell++) {
      final row = puzzle.rowOf(cell);
      final col = puzzle.colOf(cell);
      final rect = Rect.fromLTWH(
        col * cellSize,
        row * cellSize,
        cellSize,
        cellSize,
      ).deflate(gap / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, tileRadius),
        Paint()..color = colors.regionColor(puzzle.regions[cell]),
      );
      if (conflicts.contains(cell)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, tileRadius),
          Paint()..color = colors.conflict.withValues(alpha: 0.20),
        );
      }
      if (given.contains(cell)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(math.max(1.2, cellSize * 0.035)),
            tileRadius,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.1, cellSize * 0.028)
            ..color = skin.outline,
        );
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
      if (mark == CellMark.bunny) {
        final appearing = cell == placedCell && placementProgress < 1;
        if (appearing) {
          final sparkle = 1 - placementProgress;
          canvas.drawCircle(
            rect.center,
            cellSize * (0.25 + placementProgress * 0.19),
            Paint()
              ..color = skin.body.withValues(alpha: sparkle * 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(1.5, cellSize * 0.045 * sparkle),
          );
          canvas.save();
          canvas.translate(rect.center.dx, rect.center.dy);
          final scale =
              0.65 + 0.35 * Curves.easeOutBack.transform(placementProgress);
          canvas.scale(scale);
          canvas.translate(-rect.center.dx, -rect.center.dy);
        }
        paintBunnyFace(
          canvas,
          rect.center,
          cellSize * 0.245,
          body: skin.body,
          eye: skin.eye,
          outline: skin.outline,
          innerEar: skin.innerEar,
        );
        if (appearing) canvas.restore();
        if (conflicts.contains(cell)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(cellSize * 0.12), tileRadius),
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
    final inset = cellSize * 0.295;
    final paint = Paint()
      ..color = strong ? color : color.withValues(alpha: 0.55)
      ..strokeWidth = math.max(1.2, cellSize * (strong ? 0.05 : 0.038))
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
