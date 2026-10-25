import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_state.dart';
import '../data/game_store.dart';
import '../game/puzzle.dart';
import '../l10n/strings.dart';
import 'bunny_art.dart';
import 'game_page.dart';
import 'settings_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openGame(
    BuildContext context, {
    required Puzzle puzzle,
    required String mode,
    required int levelIndex,
  }) async {
    final app = AppScope.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          app: app,
          puzzle: puzzle,
          mode: mode,
          levelIndex: levelIndex,
        ),
      ),
    );
    app.reloadFromStore();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final strings = app.strings;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daily = app.repository.dailyPuzzle(now);
    final saved = app.savedGame;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                _Header(strings: strings),
                const SizedBox(height: 22),
                if (saved != null) ...[
                  _ContinueCard(
                    saved: saved,
                    strings: strings,
                    onTap: () => _openGame(
                      context,
                      puzzle: saved.puzzle,
                      mode: saved.mode,
                      levelIndex: saved.levelIndex,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _DailyCard(
                  key: const ValueKey('daily-card'),
                  puzzle: daily,
                  date: now,
                  completed: app.dailyCompletedToday,
                  strings: strings,
                  onTap: () => _openGame(
                    context,
                    puzzle: daily,
                    mode: 'daily',
                    levelIndex: AppState.dateKey(now),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Text(
                      strings.levelsTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${strings.sizeLabel(6)} – ${strings.sizeLabel(supportedSizes.last)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.42,
                  children: [
                    for (final size in supportedSizes)
                      _LevelCard(
                        key: ValueKey('level-$size'),
                        size: size,
                        level: app.levelFor(size),
                        solved: app.stats.solvedBySize[size] ?? 0,
                        strings: strings,
                        onTap: () {
                          final level = app.levelFor(size);
                          _openGame(
                            context,
                            puzzle: app.repository.levelPuzzle(size, level),
                            mode: 'level',
                            levelIndex: level,
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                _StatsCard(
                  solved: app.stats.solved,
                  streak: app.stats.dailyStreak,
                  strings: strings,
                ),
                const SizedBox(height: 26),
                Text(
                  strings.aboutText,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.versionLabel(appVersion),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.strings});

  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const BunnyLogo(size: 58),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.tagline,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: strings.settings,
          onPressed: () => showSettingsSheet(context),
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.saved,
    required this.strings,
    required this.onTap,
  });

  final SavedGame saved;
  final Strings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bunnies = saved.marks.where((mark) => mark == CellMark.bunny.index).length;
    final subtitle = saved.mode == 'daily'
        ? '${strings.dailyTitle} · ${strings.sizeLabel(saved.puzzle.size)}'
        : '${strings.levelLabel(saved.levelIndex)} · ${strings.sizeLabel(saved.puzzle.size)}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.continueTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$bunnies/${saved.puzzle.size} ${strings.bunnies.toLowerCase()} · '
                      '${Strings.formatDuration(saved.elapsedSeconds)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    super.key,
    required this.puzzle,
    required this.date,
    required this.completed,
    required this.strings,
    required this.onTap,
  });

  final Puzzle puzzle;
  final DateTime date;
  final bool completed;
  final Strings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer,
            Color.alphaBlend(scheme.tertiaryContainer, scheme.primaryContainer),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      strings.dateLong(date),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (completed)
                      Icon(
                        Icons.check_circle_rounded,
                        color: scheme.onPrimaryContainer,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  strings.dailyTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Pill(
                      label: strings.sizeLabel(puzzle.size),
                      foreground: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      label: strings.difficulty(puzzle.difficulty),
                      foreground: scheme.onPrimaryContainer,
                    ),
                    if (completed) ...[
                      const SizedBox(width: 8),
                      _Pill(
                        label: strings.dailyDone,
                        foreground: scheme.onPrimaryContainer,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Material(
                      color: scheme.onPrimaryContainer,
                      borderRadius: BorderRadius.circular(100),
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cruelty_free,
                                size: 18,
                                color: scheme.primaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                completed ? strings.playAgain : strings.play,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.primaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    super.key,
    required this.size,
    required this.level,
    required this.solved,
    required this.strings,
    required this.onTap,
  });

  final int size;
  final int level;
  final int solved;
  final Strings strings;
  final VoidCallback onTap;

  static const _accents = {
    6: Color(0xFF5C8D6E),
    7: Color(0xFFB98A3E),
    8: Color(0xFF4E7E9C),
    9: Color(0xFF9C5D6E),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accents[size] ?? theme.colorScheme.primary;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    strings.sizeLabel(size),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                strings.levelLabel(level),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    strings.difficulty(
                      size <= 6
                          ? Difficulty.easy
                          : size == 7
                          ? Difficulty.medium
                          : size == 8
                          ? Difficulty.hard
                          : Difficulty.expert,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (solved > 0) ...[
                    Icon(
                      Icons.check_circle_outline,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$solved',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.solved,
    required this.streak,
    required this.strings,
  });

  final int solved;
  final int streak;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                value: '$solved',
                label: strings.solvedStat,
                icon: Icons.emoji_events_outlined,
                theme: theme,
              ),
            ),
            Container(
              width: 1,
              height: 44,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _Stat(
                value: '$streak',
                label: strings.streakStat,
                icon: Icons.local_fire_department_outlined,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.theme,
  });

  final String value;
  final String label;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
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
