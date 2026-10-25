import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_state.dart';
import '../data/game_store.dart';
import '../game/campaign.dart';
import '../game/puzzle.dart';
import '../l10n/strings.dart';
import 'bunny_art.dart';
import 'carrot_icon.dart';
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

  void _openStage(BuildContext context, CampaignStage stage) {
    final app = AppScope.of(context);
    _openGame(
      context,
      puzzle: app.repository.levelPuzzle(stage.size, stage.level),
      mode: 'campaign',
      levelIndex: stage.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final strings = app.strings;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daily = app.repository.dailyPuzzle(now);
    final saved = app.savedGame;
    final stage = campaignStageFor(app.repository, app.campaignStage);
    final campaignPuzzle = app.repository.levelPuzzle(stage.size, stage.level);

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
                _CampaignCard(
                  key: const ValueKey('campaign-card'),
                  stage: stage,
                  puzzle: campaignPuzzle,
                  strings: strings,
                  onTap: () => _openStage(context, stage),
                ),
                const SizedBox(height: 14),
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
                _StatsCard(
                  solved: app.stats.solved,
                  streak: app.stats.dailyStreak,
                  points: app.stats.points,
                  carrots: app.stats.carrots,
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
        : '${strings.stageLabel(saved.levelIndex)} · '
              '${strings.sizeLabel(saved.puzzle.size)}';

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

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    super.key,
    required this.stage,
    required this.puzzle,
    required this.strings,
    required this.onTap,
  });

  final CampaignStage stage;
  final Puzzle puzzle;
  final Strings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progressLabel = stage.endless
        ? strings.allStagesDone
        : strings.stageProgress(
            stage.completed.clamp(0, stage.totalStages),
            stage.totalStages,
          );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.campaignTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          strings.stageLabel(stage.number),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Pill(
                    label: strings.sizeLabel(puzzle.size),
                    foreground: scheme.primary,
                  ),
                  _Pill(
                    label: strings.difficulty(puzzle.difficulty),
                    foreground: scheme.primary,
                  ),
                  if (stage.givenBunnies > 0)
                    _Pill(
                      label: strings.givenBunnies(stage.givenBunnies),
                      foreground: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: stage.progress,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progressLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('campaign-play'),
                  onPressed: onTap,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(strings.playStage),
                ),
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.solved,
    required this.streak,
    required this.points,
    required this.carrots,
    required this.strings,
  });

  final int solved;
  final int streak;
  final int points;
  final int carrots;
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Container(
      width: 1,
      height: 44,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: Strings.formatNumber(points),
                    label: strings.points,
                    icon: Icon(
                      Icons.stars_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    theme: theme,
                  ),
                ),
                divider,
                Expanded(
                  child: _Stat(
                    value: Strings.formatNumber(carrots),
                    label: strings.carrots,
                    icon: const CarrotIcon(size: 24),
                    theme: theme,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '$solved',
                    label: strings.solvedStat,
                    icon: Icon(
                      Icons.emoji_events_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    theme: theme,
                  ),
                ),
                divider,
                Expanded(
                  child: _Stat(
                    value: '$streak',
                    label: strings.streakStat,
                    icon: Icon(
                      Icons.local_fire_department_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    theme: theme,
                  ),
                ),
              ],
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
  final Widget icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon,
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
