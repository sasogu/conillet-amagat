import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/game_store.dart';
import '../l10n/strings.dart';
import '../ranking/ranking_api.dart';

enum _RankingTab { daily, history, general }

class RankingPage extends StatefulWidget {
  const RankingPage({super.key, required this.app, this.api});

  final AppState app;
  final RankingApi? api;

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  late final RankingApi _api;
  late final bool _ownsApi;
  late final TextEditingController _nicknameController;
  int _requestId = 0;
  _RankingTab _tab = _RankingTab.daily;
  DailyRanking? _daily;
  HistoryRanking? _history;
  GeneralRanking? _general;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;

  String get _today => AppState.dayKeyString(DateTime.now());

  bool get _hasDaily =>
      widget.app.stats.lastDaily == _today &&
      widget.app.stats.lastDailyScore > 0;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? RankingApi();
    _ownsApi = widget.api == null;
    _nicknameController = TextEditingController(text: widget.app.nickname);
    _load();
    _syncAutomatically();
  }

  @override
  void dispose() {
    if (_ownsApi) _api.close();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_tab == _RankingTab.daily) {
        final data = await _api.daily(
          day: _today,
          deviceId: widget.app.playerId,
        );
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _daily = data;
          _loading = false;
        });
      } else if (_tab == _RankingTab.history) {
        final data = await _api.history(deviceId: widget.app.playerId);
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _history = data;
          _loading = false;
        });
      } else {
        final data = await _api.general(deviceId: widget.app.playerId);
        if (!mounted || requestId != _requestId) return;
        setState(() {
          _general = data;
          _loading = false;
        });
      }
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _error = error is RankingException
            ? error.message
            : widget.app.strings.rankingError;
      });
    }
  }

  Future<void> _syncAutomatically() async {
    if (widget.app.nickname.isEmpty) return;
    final synced = await widget.app.syncRanking(api: _api);
    if (mounted && synced) await _load();
  }

  Future<void> _changeTab(_RankingTab tab) async {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _error = null;
    });
    await _load();
  }

  bool _validNickname(String value) {
    if (value.length < 3 || value.length > 16) return false;
    return RegExp(
      r'^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñÇçÀÈÌÒÙàèìòù _.-]+$',
    ).hasMatch(value);
  }

  Future<void> _saveNickname() async {
    final value = _nicknameController.text.trim();
    if (!_validNickname(value)) {
      _showMessage(widget.app.strings.nicknameInvalid);
      return;
    }
    await widget.app.setNickname(value);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    _showMessage(widget.app.strings.nicknameSaved);
    await _syncAutomatically();
  }

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: widget.app.nickname);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(widget.app.strings.editNickname),
        content: TextField(
          controller: controller,
          maxLength: 16,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.app.strings.nickname,
            helperText: widget.app.strings.nicknameHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(widget.app.strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (!_validNickname(value)) {
                _showMessage(widget.app.strings.nicknameInvalid);
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: Text(widget.app.strings.saveNickname),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await widget.app.setNickname(result);
    if (mounted) {
      _showMessage(widget.app.strings.nicknameSaved);
      await _syncAutomatically();
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_hasDaily) return;
    final stats = widget.app.stats;
    setState(() => _submitting = true);
    try {
      await _api.submitDaily(
        deviceId: widget.app.playerId,
        nickname: widget.app.nickname,
        day: _today,
        score: stats.lastDailyScore,
        seconds: stats.lastDailySeconds,
        lives: stats.lastDailyLives,
        size: stats.lastDailySize,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      _showMessage(widget.app.strings.rankingSent);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(
        error is RankingException
            ? error.message
            : widget.app.strings.rankingError,
      );
    }
  }

  Future<void> _syncPoints() async {
    if (_submitting) return;
    if (widget.app.nickname.isEmpty) {
      _showMessage(widget.app.strings.rankingJoinTitle);
      return;
    }
    setState(() => _submitting = true);
    try {
      await _api.submitPoints(
        deviceId: widget.app.playerId,
        nickname: widget.app.nickname,
        points: widget.app.stats.points,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(widget.app.strings.rankingPointsSent);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(
        error is RankingException
            ? error.message
            : widget.app.strings.rankingError,
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.app,
      builder: (context, _) {
        final strings = widget.app.strings;
        final theme = Theme.of(context);
        final nickname = widget.app.nickname;

        return Scaffold(
          appBar: AppBar(
            title: Text(strings.ranking),
            actions: [
              IconButton(
                tooltip: strings.retry,
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              if (nickname.isEmpty)
                _NicknameCard(
                  controller: _nicknameController,
                  strings: strings,
                  onSave: _saveNickname,
                )
              else
                _PlayingAsCard(
                  nickname: nickname,
                  strings: strings,
                  onEdit: _editNickname,
                  theme: theme,
                ),
              const SizedBox(height: 14),
              SegmentedButton<_RankingTab>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _RankingTab.daily,
                    label: Text(strings.rankingToday),
                  ),
                  ButtonSegment(
                    value: _RankingTab.history,
                    label: Text(strings.rankingHistory),
                  ),
                  ButtonSegment(
                    value: _RankingTab.general,
                    label: Text(strings.rankingGeneral),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) => _changeTab(selection.first),
              ),
              const SizedBox(height: 14),
              if (_tab == _RankingTab.daily) ...[
                _DailyResultCard(
                  strings: strings,
                  stats: widget.app.stats,
                  hasDaily: _hasDaily,
                  canSubmit: nickname.isNotEmpty,
                  submitting: _submitting,
                  submitted: _submitted,
                  onSubmit: _submit,
                  theme: theme,
                ),
                const SizedBox(height: 14),
              ] else if (_tab == _RankingTab.general) ...[
                _GeneralPointsCard(
                  strings: strings,
                  points: widget.app.stats.points,
                  canSync: nickname.isNotEmpty,
                  submitting: _submitting,
                  onSync: _syncPoints,
                  theme: theme,
                ),
                const SizedBox(height: 14),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorCard(
                  message: _error!,
                  retry: strings.retry,
                  onRetry: _load,
                  theme: theme,
                )
              else if (_tab == _RankingTab.daily)
                _DailyList(ranking: _daily, strings: strings, theme: theme)
              else if (_tab == _RankingTab.history)
                _HistoryList(ranking: _history, strings: strings, theme: theme)
              else
                _GeneralList(ranking: _general, strings: strings, theme: theme),
              if (nickname.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  strings.rankingPrivacy,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NicknameCard extends StatelessWidget {
  const _NicknameCard({
    required this.controller,
    required this.strings,
    required this.onSave,
  });

  final TextEditingController controller;
  final Strings strings;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.rankingJoinTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.rankingPrivacy,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLength: 16,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSave(),
              decoration: InputDecoration(
                labelText: strings.nickname,
                helperText: strings.nicknameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSave,
                child: Text(strings.rankingJoin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayingAsCard extends StatelessWidget {
  const _PlayingAsCard({
    required this.nickname,
    required this.strings,
    required this.onEdit,
    required this.theme,
  });

  final String nickname;
  final Strings strings;
  final VoidCallback onEdit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
        title: Text('${strings.playingAs} $nickname'),
        trailing: IconButton(
          tooltip: strings.editNickname,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _DailyResultCard extends StatelessWidget {
  const _DailyResultCard({
    required this.strings,
    required this.stats,
    required this.hasDaily,
    required this.canSubmit,
    required this.submitting,
    required this.submitted,
    required this.onSubmit,
    required this.theme,
  });

  final Strings strings;
  final StatsData stats;
  final bool hasDaily;
  final bool canSubmit;
  final bool submitting;
  final bool submitted;
  final VoidCallback onSubmit;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (!hasDaily) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.rankingNoDaily,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.rankingDailyResult,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Strings.formatNumber(stats.lastDailyScore),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    strings.points.toLowerCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  Strings.formatDuration(stats.lastDailySeconds),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${stats.lastDailySize}×${stats.lastDailySize}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                for (var index = 0; index < 3; index++)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      index < (stats.lastDailyLives)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: index < (stats.lastDailyLives)
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.45,
                            ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSubmit && !submitting ? onSubmit : null,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  submitted ? strings.rankingUpdate : strings.rankingSubmit,
                ),
              ),
            ),
            if (!canSubmit) ...[
              const SizedBox(height: 8),
              Text(
                strings.rankingJoinTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyList extends StatelessWidget {
  const _DailyList({
    required this.ranking,
    required this.strings,
    required this.theme,
  });

  final DailyRanking? ranking;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final entries = ranking?.entries ?? const <RankingEntry>[];
    final my = ranking?.my;
    final showMy = my != null && !entries.any((entry) => entry.me);

    if (entries.isEmpty) {
      return _EmptyCard(text: strings.rankingEmptyDaily, theme: theme);
    }

    return Column(
      children: [
        for (final entry in entries)
          _DailyTile(entry: entry, strings: strings, theme: theme),
        if (showMy) ...[
          const SizedBox(height: 8),
          _MyDailyTile(entry: my, strings: strings, theme: theme),
        ],
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.ranking,
    required this.strings,
    required this.theme,
  });

  final HistoryRanking? ranking;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final entries = ranking?.entries ?? const <HistoryEntry>[];
    final my = ranking?.my;
    final showMy = my != null && !entries.any((entry) => entry.me);

    if (entries.isEmpty) {
      return _EmptyCard(text: strings.rankingEmptyHistory, theme: theme);
    }

    return Column(
      children: [
        for (final entry in entries)
          _HistoryTile(entry: entry, strings: strings, theme: theme),
        if (showMy) ...[
          const SizedBox(height: 8),
          _MyHistoryTile(entry: my, strings: strings, theme: theme),
        ],
      ],
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({
    required this.entry,
    required this.strings,
    required this.theme,
  });

  final RankingEntry entry;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.me
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : null,
      child: ListTile(
        leading: _RankBadge(rank: entry.rank, theme: theme),
        title: Text(
          entry.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${Strings.formatNumber(entry.score)} ${strings.points.toLowerCase()}'
          ' · ${Strings.formatDuration(entry.seconds)}',
        ),
        trailing: entry.me
            ? Icon(Icons.person_outline, color: theme.colorScheme.primary)
            : null,
      ),
    );
  }
}

class _MyDailyTile extends StatelessWidget {
  const _MyDailyTile({
    required this.entry,
    required this.strings,
    required this.theme,
  });

  final RankingEntry? entry;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final value = entry;
    if (value == null) return const SizedBox.shrink();
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: _RankBadge(rank: value.rank, theme: theme),
        title: Text(strings.yourPosition),
        subtitle: Text(
          '${value.nickname} · '
          '${Strings.formatNumber(value.score)} ${strings.points.toLowerCase()}'
          ' · ${Strings.formatDuration(value.seconds)}',
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.strings,
    required this.theme,
  });

  final HistoryEntry entry;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.me
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : null,
      child: ListTile(
        leading: _RankBadge(rank: entry.rank, theme: theme),
        title: Text(
          entry.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${Strings.formatNumber(entry.total)} ${strings.points.toLowerCase()}'
          ' · ${strings.days(entry.days)}',
        ),
        trailing: entry.me
            ? Icon(Icons.person_outline, color: theme.colorScheme.primary)
            : null,
      ),
    );
  }
}

class _MyHistoryTile extends StatelessWidget {
  const _MyHistoryTile({
    required this.entry,
    required this.strings,
    required this.theme,
  });

  final HistoryEntry? entry;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final value = entry;
    if (value == null) return const SizedBox.shrink();
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: _RankBadge(rank: value.rank, theme: theme),
        title: Text(strings.yourPosition),
        subtitle: Text(
          '${value.nickname} · '
          '${Strings.formatNumber(value.total)} ${strings.points.toLowerCase()}'
          ' · ${strings.days(value.days)}',
        ),
      ),
    );
  }
}

class _GeneralPointsCard extends StatelessWidget {
  const _GeneralPointsCard({
    required this.strings,
    required this.points,
    required this.canSync,
    required this.submitting,
    required this.onSync,
    required this.theme,
  });

  final Strings strings;
  final int points;
  final bool canSync;
  final bool submitting;
  final VoidCallback onSync;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.rankingPointsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Strings.formatNumber(points),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    strings.points.toLowerCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              strings.rankingPointsNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSync && !submitting ? onSync : null,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(strings.rankingSyncPoints),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralList extends StatelessWidget {
  const _GeneralList({
    required this.ranking,
    required this.strings,
    required this.theme,
  });

  final GeneralRanking? ranking;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final entries = ranking?.entries ?? const <GeneralEntry>[];
    final my = ranking?.my;
    final showMy = my != null && !entries.any((entry) => entry.me);

    if (entries.isEmpty) {
      return _EmptyCard(text: strings.rankingEmptyGeneral, theme: theme);
    }

    return Column(
      children: [
        for (final entry in entries)
          _GeneralTile(entry: entry, strings: strings, theme: theme),
        if (showMy) ...[
          const SizedBox(height: 8),
          _MyGeneralTile(entry: my, strings: strings, theme: theme),
        ],
      ],
    );
  }
}

class _GeneralTile extends StatelessWidget {
  const _GeneralTile({
    required this.entry,
    required this.strings,
    required this.theme,
  });

  final GeneralEntry entry;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.me
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
          : null,
      child: ListTile(
        leading: _RankBadge(rank: entry.rank, theme: theme),
        title: Text(
          entry.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${Strings.formatNumber(entry.points)} ${strings.points.toLowerCase()}',
        ),
        trailing: entry.me
            ? Icon(Icons.person_outline, color: theme.colorScheme.primary)
            : null,
      ),
    );
  }
}

class _MyGeneralTile extends StatelessWidget {
  const _MyGeneralTile({
    required this.entry,
    required this.strings,
    required this.theme,
  });

  final GeneralEntry? entry;
  final Strings strings;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final value = entry;
    if (value == null) return const SizedBox.shrink();
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: _RankBadge(rank: value.rank, theme: theme),
        title: Text(strings.yourPosition),
        subtitle: Text(
          '${value.nickname} · '
          '${Strings.formatNumber(value.points)} ${strings.points.toLowerCase()}',
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.theme});

  final int rank;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = switch (rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9AA0A6),
      3 => const Color(0xFFB06A3B),
      _ => theme.colorScheme.surfaceContainerHighest,
    };
    final foreground = rank <= 3
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;
    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        '$rank',
        style: theme.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.retry,
    required this.onRetry,
    required this.theme,
  });

  final String message;
  final String retry;
  final VoidCallback onRetry;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(onPressed: onRetry, child: Text(retry)),
          ],
        ),
      ),
    );
  }
}
