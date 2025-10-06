import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../services/onboarding_service.dart';
import '../providers/settings_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedLanguageCode = 'en';

  final List<Map<String, String>> _supportedLanguages = const [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await OnboardingService.getSavedLanguage();
    if (!mounted) return;
    if (savedLanguage != null) {
      setState(() => _selectedLanguageCode = savedLanguage);
    } else {
      final deviceLanguageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      setState(() => _selectedLanguageCode = deviceLanguageCode == 'tr' ? 'tr' : 'en');
    }
  }

  Future<void> _onLanguageSelected(String languageCode) async {
    setState(() => _selectedLanguageCode = languageCode);
    await OnboardingService.saveSelectedLanguage(languageCode);
    ref.read(localeProvider.notifier).state = Locale(languageCode);
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _buildLanguageSelectionPage(l10n),
                    _buildIntroductionPage(l10n),
                    _buildFeaturesPage(l10n),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final selected = _currentPage == i;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: (_currentPage == 0 && _selectedLanguageCode == null) ? null : _nextPage,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                  ),
                  child: Text(_currentPage == 2 ? l10n.onboardingGetStarted : l10n.onboardingLanguageNext),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelectionPage(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(l10n.onboardingWelcomeTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 12),
        Text(l10n.onboardingWelcomeSubtitle, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.5, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: _supportedLanguages.length,
            itemBuilder: (context, index) {
              final language = _supportedLanguages[index];
              final isSelected = _selectedLanguageCode == language['code'];
              return GestureDetector(
                onTap: () => _onLanguageSelected(language['code']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(language['flag']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(language['name']!, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIntroductionPage(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(l10n.onboardingIntroTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.onboardingIntroDescription, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          Icon(Icons.emoji_events, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage(AppLocalizations l10n) {
    final items = [
      (Icons.emoji_events, l10n.onboardingFeatureSessionsTitle, l10n.onboardingFeatureSessionsDescription, Theme.of(context).colorScheme.primary),
      (Icons.admin_panel_settings, l10n.onboardingFeatureCoachTitle, l10n.onboardingFeatureCoachDescription, Theme.of(context).colorScheme.secondary),
      (Icons.score, l10n.onboardingFeatureToolsTitle, l10n.onboardingFeatureToolsDescription, Theme.of(context).colorScheme.tertiary),
    ];
    return Column(
      children: [
        Text(l10n.onboardingFeaturesTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final (icon, title, desc, color) = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: (color as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}


