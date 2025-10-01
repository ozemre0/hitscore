import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _SectionHeader(title: l10n.languageSettings),
            _CardContainer(
              child: Column(
                children: [
                  _LanguageTile(
                    flag: '🇹🇷',
                    title: 'Türkçe',
                    value: 'tr',
                    selected: currentLocale == 'tr',
                    onTap: () => ref.read(localeProvider.notifier).state = const Locale('tr'),
                  ),
                  const Divider(height: 1),
                  _LanguageTile(
                    flag: '🇬🇧',
                    title: 'English',
                    value: 'en',
                    selected: currentLocale == 'en',
                    onTap: () => ref.read(localeProvider.notifier).state = const Locale('en'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(title: l10n.themeSettings),
            _CardContainer(
              child: Column(
                children: [
                  _ThemeTile(
                    icon: Icons.light_mode,
                    title: l10n.lightTheme,
                    selected: themeMode == ThemeMode.light,
                    onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                  ),
                  const Divider(height: 1),
                  _ThemeTile(
                    icon: Icons.dark_mode,
                    title: l10n.darkTheme,
                    selected: themeMode == ThemeMode.dark,
                    onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                  ),
                  const Divider(height: 1),
                  _ThemeTile(
                    icon: Icons.brightness_auto,
                    title: l10n.systemTheme,
                    selected: themeMode == ThemeMode.system,
                    onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 0.5),
      ),
      child: child,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String title;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title),
      trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}


