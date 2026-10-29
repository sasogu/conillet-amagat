import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/game_store.dart';
import '../game/campaign.dart';
import '../game/game_controller.dart';
import '../game/puzzle.dart';
import '../game/scoring.dart';
import '../l10n/strings.dart';
import 'board_view.dart';
import 'bunny_art.dart';
import 'carrot_icon.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.app,
    required this.puzzle,
    required this.mode,
    required this.levelIndex,
  });

  final AppState app;
  final Puzzle puzzle;
  final String mode;
  final int levelIndex;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final GameController controller;
  late final Listenable _animation;
  bool _dialogShown = false;
  bool _failDialogShown = false;
  bool _noLivesDialogOpen = false;
  bool _resetDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.app.savedGame;
    SavedGame? restore;
    if (saved != null &&
        saved.mode == widget.mode &&
        saved.levelIndex == widget.levelIndex &&
        saved.puzzle.size == widget.puzzle.size &&
        saved.puzzle.seed == widget.puzzle.seed &&
        saved.marks.length == widget.puzzle.cellCount) {
      restore = saved;
    }

    final given = widget.mode == 'campaign'
        ? givenCellsFor(
            widget.puzzle,
            campaignStageFor(
              widget.app.repository,
              widget.levelIndex,
            ).givenBunnies,
          )
        : const <int>[];
    controller = GameController(
      puzzle: widget.puzzle,
      app: widget.app,
      mode: widget.mode,
      levelIndex: widget.levelIndex,
      restore: restore,
      given: given,
    );
    _animation = Listenable.merge([controller, widget.app]);
    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    _onControllerChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      controller.resume();
    }
  }

  void _onControllerChanged() {
    if (controller.finished && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWinDialog();
      });
    }
    if (controller.failed) {
      if (!_failDialogShown) {
        _failDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNoLivesDialog();
        });
      }
    } else {
      _failDialogShown = false;
    }
  }

  Future<void> _showNoLivesDialog() async {
    if (_noLivesDialogOpen) return;
    _noLivesDialogOpen = true;
    final strings = widget.app.strings;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.favorite_border_rounded,
          size: 44,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(strings.noLivesTitle, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(strings.noLivesBody, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CarrotIcon(size: 20),
                const SizedBox(width: 6),
                Text(
                  strings.carrotsOwned(widget.app.stats.carrots),
                  style: Theme.of(dialogContext).textTheme.labelLarge,
                ),
              ],
            ),
            if (!controller.canRevive) ...[
              const SizedBox(height: 8),
              Text(
                strings.reviveNeeds(reviveCost),
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => _goHome(dialogContext),
            child: Text(strings.home),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.reset();
            },
            child: Text(strings.restart),
          ),
          if (controller.canRevive)
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await controller.revive();
              },
              child: Text(strings.reviveWithCarrots(reviveCost)),
            ),
        ],
      ),
    );
    _noLivesDialogOpen = false;
  }

  void _handleDoubleTap(int cell) {
    final result = controller.handleDoubleTap(cell);
    if (!mounted || result != DoubleTapResult.wrong) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.app.strings.wrongBunny(controller.lives)),
        ),
      );
  }

  Future<void> _showWinDialog() async {
    final strings = widget.app.strings;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final score = scoreFor(
          puzzle: controller.puzzle,
          seconds: controller.elapsedSeconds,
          lives: controller.lives,
        );
        final advance = widget.mode == 'campaign'
            ? stageAdvanceFor(
                size: controller.puzzle.size,
                seconds: controller.elapsedSeconds,
                lives: controller.lives,
                hintsUsed: controller.hintsUsed,
                maxLives: startingLives,
              )
            : 1;
        return AlertDialog(
          icon: Center(child: BunnyLogo(size: 58, skin: widget.app.skin)),
          title: Text(strings.winTitle, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.winBody, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                '+${Strings.formatNumber(score.points)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                strings.points,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.scoreBreakdown(
                  score.base,
                  score.timeBonus,
                  score.livesBonus,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.65,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (score.carrots > 0) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0; index < score.carrots; index++)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1),
                              child: CarrotIcon(size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      strings.carrotsFed(score.carrots),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (advance > 1) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rocket_launch_outlined,
                        size: 18,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          strings.fastAdvance(advance),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Result(
                    icon: Icons.timer_outlined,
                    label: strings.time,
                    value: Strings.formatDuration(controller.elapsedSeconds),
                    theme: theme,
                  ),
                  _Result(
                    icon: Icons.lightbulb_outline,
                    label: strings.hints,
                    value: '${controller.hintsUsed}',
                    theme: theme,
                  ),
                ],
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => _goHome(dialogContext),
              child: Text(strings.home),
            ),
            if (widget.mode == 'campaign')
              FilledButton(
                onPressed: () =>
                    _nextStage(dialogContext, widget.levelIndex + advance),
                child: Text(strings.next),
              )
            else
              FilledButton(
                onPressed: () =>
                    _nextStage(dialogContext, widget.app.campaignStage),
                child: Text(strings.playStage),
              ),
          ],
        );
      },
    );
  }

  void _goHome(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    Navigator.of(context).pop();
  }

  void _nextStage(BuildContext dialogContext, int number) {
    Navigator.of(dialogContext).pop();
    final stage = campaignStageFor(widget.app.repository, number);
    final puzzle = widget.app.repository.levelPuzzle(stage.size, stage.level);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          app: widget.app,
          puzzle: puzzle,
          mode: 'campaign',
          levelIndex: stage.number,
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    if (_resetDialogOpen) return;
    if (controller.marks.every((mark) => mark == CellMark.none)) {
      controller.reset();
      return;
    }
    _resetDialogOpen = true;
    final strings = widget.app.strings;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.restartTitle),
        content: Text(strings.restartBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.restart),
          ),
        ],
      ),
    );
    _resetDialogOpen = false;
    if (result == true && mounted) controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final strings = widget.app.strings;
        final theme = Theme.of(context);
        final puzzle = widget.puzzle;
        final title = widget.mode == 'daily'
            ? strings.dailyTitle
            : strings.stageLabel(widget.levelIndex);
        final subtitle =
            '${strings.sizeLabel(puzzle.size)} · '
            '${strings.difficulty(puzzle.difficulty)}';

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TimerChip(
                  seconds: controller.elapsedSeconds,
                  paused: controller.paused,
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final board = Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 24 : 16,
                    8,
                    wide ? 12 : 16,
                    8,
                  ),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: BoardView(
                        puzzle: puzzle,
                        marks: controller.marks,
                        blocked: controller.blockedCells,
                        conflicts: controller.conflictCells,
                        given: controller.givenCells,
                        skin: widget.app.skin,
                        enabled: controller.canPlay && !controller.paused,
                        onTap: controller.handleTap,
                        onDoubleTap: _handleDoubleTap,
                        onDragMark: controller.handleDrag,
                        onDragEnd: () {},
                      ),
                    ),
                  ),
                );

                final controls = _Controls(
                  strings: strings,
                  controller: controller,
                  onUndo: controller.undo,
                  onHint: controller.hint,
                  onReset: _confirmReset,
                  onToggleAutoCross: () =>
                      widget.app.setAutoCross(!widget.app.settings.autoCross),
                  wide: wide,
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: board),
                      SizedBox(
                        width: 310,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(8, 12, 20, 20),
                          child: controls,
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(child: board),
                    controls,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.seconds, required this.paused});

  final int seconds;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            paused ? Icons.pause_circle_outline : Icons.timer_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            Strings.formatDuration(seconds),
            style: theme.textTheme.labelLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.strings,
    required this.controller,
    required this.onUndo,
    required this.onHint,
    required this.onReset,
    required this.onToggleAutoCross,
    required this.wide,
  });

  final Strings strings;
  final GameController controller;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onReset;
  final VoidCallback onToggleAutoCross;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = controller.puzzle.size;

    final tools = Row(
      children: [
        Expanded(
          child: _ToolButton(
            icon: Icons.undo_rounded,
            label: strings.undo,
            onPressed: controller.canUndo ? onUndo : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            icon: Icons.lightbulb_outline_rounded,
            label: strings.hint,
            onPressed: controller.canPlay ? onHint : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            icon: Icons.restart_alt_rounded,
            label: strings.reset,
            onPressed: controller.finished ? null : onReset,
          ),
        ),
      ],
    );

    final status = Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          selected: controller.autoCrossEnabled,
          onSelected: (_) => onToggleAutoCross(),
          avatar: Icon(
            Icons.auto_fix_high_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          label: Text(strings.autoCrossShort),
        ),
        Tooltip(
          message: strings.lives,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < startingLives; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    index < controller.lives
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: index < controller.lives
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${strings.hints}: ${controller.hintsUsed}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, wide ? 4 : 8, 16, wide ? 8 : 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressTrail(
            count: controller.bunnyCount,
            total: total,
            strings: strings,
          ),
          const SizedBox(height: 10),
          if (wide) ...[status, const SizedBox(height: 14)],
          tools,
          const SizedBox(height: 10),
          if (!wide) status,
          const SizedBox(height: 8),
          Text(
            strings.instructions(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTrail extends StatelessWidget {
  const _ProgressTrail({
    required this.count,
    required this.total,
    required this.strings,
  });

  final int count;
  final int total;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.pets_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                strings.bunnyProgress(count, total),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$count/$total',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: count / total),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: theme.colorScheme.surfaceContainer,
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null;
    final foreground = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.35);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: foreground),
              const SizedBox(height: 3),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
