import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'my_competitions_screen.dart';
import 'active_competitions_screen.dart';
import 'organized_competitions_screen.dart';
import 'competition_archive_screen.dart';
import '../services/supabase_config.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String displayName;

  const HomeScreen({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      drawer: _HomeDrawer(displayName: displayName),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _WelcomeBannerCard(title: l10n.welcomeWithName(displayName)),
                      const SizedBox(height: 16),
                      _HomeCardButton(
                        icon: Icons.emoji_events,
                        title: l10n.participantCompetitionsTitle,
                        subtitle: l10n.participantCompetitionsSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ParticipantCompetitionsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HomeCardButton(
                        icon: Icons.sports_martial_arts,
                        title: l10n.activeCompetitionsTitle,
                        subtitle: l10n.activeCompetitionsSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ActiveCompetitionsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HomeCardButton(
                        icon: Icons.admin_panel_settings,
                        title: l10n.myOrganizedCompetitionsTitle,
                        subtitle: l10n.myOrganizedCompetitionsSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OrganizedCompetitionsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _HomeCardButton(
                        icon: Icons.public,
                        title: l10n.competitionArchiveTitle,
                        subtitle: l10n.competitionArchiveSubtitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CompetitionArchiveScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _HomeCardButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCardButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.35), width: 1.2),
      ),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 20) * 0.9,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBannerCard extends StatelessWidget {
  final String title;
  const _WelcomeBannerCard({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.primary.withOpacity(0.30), width: 1.0),
      ),
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withOpacity(0.10),
              ),
              child: Icon(Icons.waving_hand, color: cs.primary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final String displayName;

  const _HomeDrawer({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withOpacity(0.15),
                    child: Icon(Icons.person, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.welcomeWithName(displayName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.appTitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settingsTitle),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.signOut),
              onTap: () async {
                Navigator.pop(context);
                final bool? confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(l10n.signOut),
                      content: Text(l10n.signOutConfirm),
                      actions: <Widget>[
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(dialogContext).colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Text(l10n.cancel),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(
                              color: Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(l10n.signOut),
                        ),
                      ],
                    );
                  },
                );
                
                if (confirmed == true) {
                  try {
                    await SupabaseConfig.client.auth.signOut();
                    // The authentication state provider will automatically handle navigation
                    // No need for manual navigation as the app will rebuild based on auth state
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.errorGeneric)),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}