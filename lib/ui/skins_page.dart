import 'package:flutter/material.dart';

import '../app_state.dart';
import '../game/bunny_skin.dart';
import '../l10n/strings.dart';
import 'bunny_art.dart';
import 'carrot_icon.dart';

class SkinsPage extends StatelessWidget {
  const SkinsPage({super.key, required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final strings = app.strings;
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(strings.appearance),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CarrotIcon(size: 20),
                    const SizedBox(width: 5),
                    Text(
                      Strings.formatNumber(app.stats.carrots),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: bunnySkins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final skin = bunnySkins[index];
              final unlocked = app.unlockedSkins.contains(skin.id);
              final selected = app.selectedSkin == skin.id;
              final subtitle = selected
                  ? strings.skinSelected
                  : unlocked
                  ? strings.skinChoose
                  : '${strings.skinUnlock} · ${skin.cost} '
                        '${strings.carrots.toLowerCase()}';

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    if (selected) return;
                    if (unlocked) {
                      await app.selectSkin(skin.id);
                      return;
                    }
                    final ok = await app.unlockSkin(skin.id);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              strings.notEnoughCarrots(skin.cost),
                            ),
                          ),
                        );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        BunnyLogo(size: 54, skin: skin),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.skinName(skin.id),
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
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.colorScheme.primary,
                          )
                        else if (unlocked)
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        else
                          Icon(
                            Icons.lock_outline,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
