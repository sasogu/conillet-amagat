import 'package:flutter/material.dart';

import '../app_state.dart';
import 'carrot_icon.dart';

Future<void> showHowToPlay(
  BuildContext context, {
  Future<void> Function()? onSeen,
}) async {
  final strings = AppScope.of(context).strings;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: Text(strings.howToPlay, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HowToRow(
                icon: Icons.touch_app_outlined,
                title: strings.tutorialTapTitle,
                body: strings.tutorialTapBody,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _HowToRow(
                icon: Icons.cruelty_free,
                title: strings.tutorialBunnyTitle,
                body: strings.tutorialBunnyBody,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _HowToRow(
                icon: Icons.favorite_border_rounded,
                title: strings.tutorialLivesTitle,
                body: strings.tutorialLivesBody,
                theme: theme,
              ),
              const SizedBox(height: 16),
              _HowToRow(
                carrot: true,
                title: strings.tutorialCarrotsTitle,
                body: strings.tutorialCarrotsBody,
                theme: theme,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.understood),
          ),
        ],
      );
    },
  );
  if (onSeen != null) await onSeen();
}

class _HowToRow extends StatelessWidget {
  const _HowToRow({
    this.icon,
    this.carrot = false,
    required this.title,
    required this.body,
    required this.theme,
  });

  final IconData? icon;
  final bool carrot;
  final String title;
  final String body;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: carrot
              ? const CarrotIcon(size: 22)
              : Icon(icon, size: 22, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
