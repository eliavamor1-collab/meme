import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.settings,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'הגדרות',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── מראה ──
                  _sectionLabel(context, 'מראה', colorScheme),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _themeLabel(
                            context,
                            'כהה',
                            Icons.dark_mode_rounded,
                            settings.isDarkMode,
                            colorScheme,
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: !settings.isDarkMode,
                            onChanged: (val) => settings.toggleTheme(!val),
                            thumbIcon: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const Icon(
                                  Icons.light_mode_rounded,
                                  size: 16,
                                );
                              }
                              return const Icon(
                                Icons.dark_mode_rounded,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          _themeLabel(
                            context,
                            'בהיר',
                            Icons.light_mode_rounded,
                            !settings.isDarkMode,
                            colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── תצוגה ──
                  _sectionLabel(context, 'תצוגה', colorScheme),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: SwitchListTile(
                      secondary: Icon(
                        Icons.category_rounded,
                        color: colorScheme.primary,
                      ),
                      title: const Text('חלוקה לקטגוריות'),
                      subtitle: Text(
                        settings.groupByCategory ? 'מופעל' : 'כבוי',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      value: settings.groupByCategory,
                      onChanged: (val) => settings.setGroupByCategory(val),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Meme Soundboard v1.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(
    BuildContext context,
    String label,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _themeLabel(
    BuildContext context,
    String text,
    IconData icon,
    bool active,
    ColorScheme colorScheme,
  ) {
    final color = active
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.4);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
