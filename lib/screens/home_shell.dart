import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'profile_setup_screen.dart';
import '../providers/profile_providers.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    // Check if profile exists and redirect if not
    final profileExists = ref.watch(profileExistsProvider);
    
    return profileExists.when(
      data: (exists) {
        // If profile doesn't exist, show profile setup screen
        if (exists == false) {
          return const ProfileSetupScreen();
        }
        
        // If profile exists, show normal home shell
        final tabs = <Widget>[
          Consumer(builder: (context, ref, _) {
            final asyncName = ref.watch(profileFirstNameProvider);
            return asyncName.when(
              data: (name) => HomeScreen(displayName: name),
              loading: () => const HomeScreen(displayName: ''),
              error: (_, __) => const HomeScreen(displayName: ''),
            );
          }),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: SafeArea(child: tabs[_currentIndex]),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: l10n.homeTab,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: l10n.profileTab,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading profile')),
      ),
    );
  }
}


