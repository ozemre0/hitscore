import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../providers/competitions_providers.dart';
import 'competition_participants_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local search query provider for the archive screen
final _archiveSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class CompetitionArchiveScreen extends ConsumerWidget {
  const CompetitionArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.competitionArchiveTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: const _CompetitionArchiveContent(),
            ),
          );
        },
      ),
    );
  }
}

class _CompetitionArchiveContent extends ConsumerStatefulWidget {
  const _CompetitionArchiveContent();

  @override
  ConsumerState<_CompetitionArchiveContent> createState() => _CompetitionArchiveContentState();
}

class _CompetitionArchiveContentState extends ConsumerState<_CompetitionArchiveContent> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(_archiveSearchQueryProvider));
    _searchFocusNode = FocusNode();
    _searchController.addListener(() {
      final text = _searchController.text;
      if (ref.read(_archiveSearchQueryProvider) != text) {
        ref.read(_archiveSearchQueryProvider.notifier).state = text;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final competitionsAsync = ref.watch(allCompetitionsArchiveProvider);
    final searchQuery = ref.watch(_archiveSearchQueryProvider);
    
    return competitionsAsync.when(
      data: (competitions) {
        // Apply client-side search filter by name
        List<Map<String, dynamic>> list = competitions;
        final q = searchQuery.trim().toLowerCase();
        if (q.isNotEmpty) {
          list = list.where((c) {
            final name = (c['name'] ?? '').toString().toLowerCase();
            final visibleId = (c['competition_visible_id'] ?? '').toString().toLowerCase();
            return name.contains(q) || visibleId.contains(q);
          }).toList(growable: false);
        }
        if (list.isEmpty) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_isSearchActive) {
                setState(() => _isSearchActive = false);
                _searchFocusNode.unfocus();
              }
            },
            child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12.0),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('archiveSearchField'),
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) => _searchFocusNode.requestFocus(),
                                  onTap: () {
                                    if (!_isSearchActive) {
                                      setState(() => _isSearchActive = true);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: l10n.searchCompetitionHint,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverToBoxAdapter(
                  child: const _EmptyArchiveCard(),
                ),
              ),
            ],
          ),
          );
        }
        
        // Group competitions by date
        final Map<String, List<Map<String, dynamic>>> groupedCompetitions = {};
        for (final competition in list) {
          final String? startDate = competition['start_date'] as String?;
          if (startDate != null) {
            try {
              final DateTime date = DateTime.parse(startDate);
              final String dateKey = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
              groupedCompetitions.putIfAbsent(dateKey, () => []).add(competition);
            } catch (_) {
              // If date parsing fails, add to "Unknown" group
              groupedCompetitions.putIfAbsent('Bilinmeyen', () => []).add(competition);
            }
          } else {
            // If no date, add to "Unknown" group
            groupedCompetitions.putIfAbsent('Bilinmeyen', () => []).add(competition);
          }
        }
        
        // Sort date keys (newest first)
        final sortedDateKeys = groupedCompetitions.keys.toList()
          ..sort((a, b) {
            if (a == 'Bilinmeyen') return 1;
            if (b == 'Bilinmeyen') return -1;
            try {
              final DateTime dateA = DateTime.parse(a.split('.').reversed.join('-'));
              final DateTime dateB = DateTime.parse(b.split('.').reversed.join('-'));
              return dateB.compareTo(dateA);
            } catch (_) {
              return a.compareTo(b);
            }
          });
        
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_isSearchActive) {
              setState(() => _isSearchActive = false);
              _searchFocusNode.unfocus();
            }
          },
          child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey('archiveSearchField'),
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _searchFocusNode.requestFocus(),
                                onTap: () {
                                  if (!_isSearchActive) {
                                    setState(() => _isSearchActive = true);
                                  }
                                },
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.search),
                                  hintText: l10n.searchCompetitionHint,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList.builder(
                itemCount: sortedDateKeys.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedDateKeys[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < sortedDateKeys.length - 1 ? 8.0 : 0,
                    ),
                    child: _DateGroupCard(
                      date: dateKey,
                      competitions: groupedCompetitions[dateKey]!,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        );
      },
      loading: () => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_isSearchActive) {
            setState(() => _isSearchActive = false);
            _searchFocusNode.unfocus();
          }
        },
        child: CustomScrollView(
          slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12.0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                            Expanded(
                              child: TextField(
                              key: const ValueKey('archiveSearchField'),
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchFocusNode.requestFocus(),
                                onTap: () {
                                  if (!_isSearchActive) {
                                    setState(() => _isSearchActive = true);
                                  }
                                },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: l10n.searchCompetitionHint,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: const _LoadingCard(),
            ),
          ),
          ],
        ),
      ),
      error: (error, stack) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_isSearchActive) {
            setState(() => _isSearchActive = false);
            _searchFocusNode.unfocus();
          }
        },
        child: CustomScrollView(
          slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                            Expanded(
                              child: TextField(
                              key: const ValueKey('archiveSearchField'),
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchFocusNode.requestFocus(),
                                onTap: () {
                                  if (!_isSearchActive) {
                                    setState(() => _isSearchActive = true);
                                  }
                                },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: l10n.searchCompetitionHint,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: _ErrorCard(error: error.toString()),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

// Info card removed per request

class _DateGroupCard extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> competitions;

  const _DateGroupCard({
    required this.date,
    required this.competitions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Text(
            date,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
        ),
        // Competitions list
        ...competitions.map((competition) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _CompetitionCard(competition: competition),
        )),
      ],
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  final Map<String, dynamic> competition;

  const _CompetitionCard({required this.competition});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    final String name = competition['name'] as String? ?? l10n.untitledCompetition;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1.0),
      ),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final String? competitionId = competition['organized_competition_id'] as String?;
          if (competitionId == null) return;
          final String competitionName = competition['name'] as String? ?? l10n.untitledCompetition;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CompetitionParticipantsScreen(
                competitionId: competitionId,
                competitionName: competitionName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13.2, horizontal: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyArchiveCard extends StatelessWidget {
  const _EmptyArchiveCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1.0),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.archive_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.competitionArchiveEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.competitionArchiveEmptyDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.3), width: 1.0),
      ),
      color: colorScheme.surface,
      child: const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1.0),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorGeneric,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText.rich(
              TextSpan(
                text: error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}