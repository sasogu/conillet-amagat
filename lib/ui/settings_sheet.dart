import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_info.dart';
import '../app_state.dart';
import 'bunny_art.dart';
import 'how_to_play.dart';
import 'skins_page.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const SettingsSheet(),
  );
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final strings = app.strings;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.settings, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            Text(strings.theme, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(strings.themeSystem),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(strings.themeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(strings.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {app.themeMode},
              onSelectionChanged: (selection) =>
                  app.setThemeMode(selection.first),
            ),
            const SizedBox(height: 20),
            Text(strings.language, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'es', label: Text(strings.spanish)),
                ButtonSegment(value: 'ca', label: Text(strings.valencian)),
              ],
              selected: {app.settings.language},
              onSelectionChanged: (selection) =>
                  app.setLanguage(selection.first),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.auto_fix_high_outlined),
              title: Text(strings.autoCross),
              value: app.settings.autoCross,
              onChanged: app.setAutoCross,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: BunnyLogo(size: 36, skin: app.skin),
              title: Text(strings.appearance),
              subtitle: Text(strings.skinName(app.selectedSkin)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute<void>(builder: (_) => SkinsPage(app: app)),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline),
              title: Text(strings.howToPlay),
              onTap: () => showHowToPlay(context, onSeen: app.markTutorialSeen),
            ),
            const Divider(height: 28),
            Text(strings.progress, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(strings.exportProgress),
              subtitle: Text(strings.exportProgressHint),
              onTap: () => _exportProgress(context, app),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_download_outlined),
              title: Text(strings.importProgress),
              subtitle: Text(strings.importProgressHint),
              onTap: () => _importProgress(context, app),
            ),
            const Divider(height: 28),
            Text(strings.about, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(strings.aboutText, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 10),
            SelectableText(
              repoUrl,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${strings.versionLabel(appVersion)} · ${strings.madeWith}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.close),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fileStamp(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}${two(date.month)}${two(date.day)}-'
      '${two(date.hour)}${two(date.minute)}';
}

Future<void> _exportProgress(BuildContext context, AppState app) async {
  final strings = app.strings;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(app.store.exportProgress());
    final path = await FilePicker.saveFile(
      dialogTitle: strings.exportProgress,
      fileName: 'conillet-amagat-progres-${_fileStamp(DateTime.now())}.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
    if (!kIsWeb && path == null) return;
    messenger.showSnackBar(SnackBar(content: Text(strings.exportDone)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(strings.exportError)));
  }
}

Future<void> _importProgress(BuildContext context, AppState app) async {
  final strings = app.strings;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await FilePicker.pickFiles(
      dialogTitle: strings.importProgress,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) throw const FormatException('Sin datos');
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException('Sin datos');
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.importConfirmTitle),
        content: Text(strings.importConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.importConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await app.importProgress(decoded.cast<String, Object?>());
    messenger.showSnackBar(SnackBar(content: Text(strings.importDone)));
  } on FormatException {
    messenger.showSnackBar(SnackBar(content: Text(strings.importInvalid)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(strings.importError)));
  }
}
