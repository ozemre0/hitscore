import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/profile_providers.dart';

class UserMultiSelectResult {
  final List<String> userIds;
  const UserMultiSelectResult(this.userIds);
}

class UserMultiSelectSheet extends ConsumerStatefulWidget {
  final String competitionId;
  const UserMultiSelectSheet({super.key, required this.competitionId});

  @override
  ConsumerState<UserMultiSelectSheet> createState() => _UserMultiSelectSheetState();
}

class _UserMultiSelectSheetState extends ConsumerState<UserMultiSelectSheet> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = <String>{};
  String _genderFilter = 'all'; // 'all' | 'male' | 'female'
  Timer? _debounce;
  String _debouncedQuery = '';
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 120;
  int _offset = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels < 400) {
        _loadNextPage(ref);
      }
    });
  }

  Future<void> _loadNextPage(WidgetRef ref) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    try {
      final next = await ref.read(
        coachAthletesProvider(
          CoachAthletesParams(
            search: (_debouncedQuery.isNotEmpty ? _debouncedQuery : _searchController.text.trim()),
            limit: _pageSize,
            offset: _offset,
            competitionId: widget.competitionId,
          ),
        ).future,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(List<Map<String, dynamic>>.from(next));
        _offset += next.length;
        _hasMore = next.length == _pageSize;
      });
    } finally {
      _isLoadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    final clampedTextScaler = media.textScaler.clamp(maxScaleFactor: 1.3);
    final effectiveQuery = _debouncedQuery.isNotEmpty ? _debouncedQuery : _searchController.text.trim();
    // Initial page watch; subsequent pages are prefetched via _loadNextPage
    final params = CoachAthletesParams(search: effectiveQuery, limit: _pageSize, offset: 0, competitionId: widget.competitionId);
    final asyncUsers = ref.watch(coachAthletesProvider(params));

    return MediaQuery(
      data: media.copyWith(textScaler: clampedTextScaler),
      child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 600;
            final double maxWidth = isWide ? 560 : constraints.maxWidth;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight,
                ),
                child: Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: AppBar(
                      title: Text(l10n.addAthletes),
                      automaticallyImplyLeading: true,
                    ),
                    body: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (_) {
                                        _debounce?.cancel();
                                        _debounce = Timer(const Duration(milliseconds: 400), () {
                                          if (!mounted) return;
                                          setState(() {
                                            _debouncedQuery = _searchController.text.trim();
                                          });
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: l10n.searchAthleteHint,
                                        prefixIcon: const Icon(Icons.search),
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: Text(l10n.all),
                                    selected: _genderFilter == 'all',
                                    onSelected: (_) => setState(() => _genderFilter = 'all'),
                                  ),
                                  ChoiceChip(
                                    label: Text(l10n.genderFemale),
                                    selected: _genderFilter == 'female',
                                    onSelected: (_) => setState(() => _genderFilter = _genderFilter == 'female' ? 'all' : 'female'),
                                  ),
                                  ChoiceChip(
                                    label: Text(l10n.genderMale),
                                    selected: _genderFilter == 'male',
                                    onSelected: (_) => setState(() => _genderFilter = _genderFilter == 'male' ? 'all' : 'male'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: asyncUsers.when(
                            data: (list) {
                              // Reset list on new query and prefetch next page
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                final incoming = List<Map<String, dynamic>>.from(list);
                                final bool queryChanged = true; // first page always resets
                                if (queryChanged) {
                                  setState(() {
                                    _items = incoming;
                                    _offset = incoming.length;
                                    _hasMore = incoming.length == _pageSize;
                                  });
                                  if (_hasMore) {
                                    _loadNextPage(ref);
                                  }
                                }
                              });

                              List<Map<String, dynamic>> items = _items.isNotEmpty ? _items : List<Map<String, dynamic>>.from(list);
                              if (_genderFilter != 'all') {
                                items = items.where((a) {
                                  final g = ((a['gender'] ?? '') as String).toLowerCase();
                                  final isFemale = g.startsWith('f') || g.startsWith('k');
                                  final isMale = g.startsWith('m') || g.startsWith('e');
                                  return _genderFilter == 'female' ? isFemale : isMale;
                                }).toList();
                              }
                              if (items.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.noResults,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                controller: _scrollController,
                                itemCount: items.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_hasMore && index == items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  final a = items[index];
                                  final String userId = (a['id'] ?? a['athlete_id'] ?? '') as String;
                                  final String first = (a['first_name'] ?? '') as String;
                                  final String last = (a['last_name'] ?? '') as String;
                                  final String name = ('$first $last').trim();
                                  final String visible = (a['visible_id'] ?? '') as String;
                                  final bool selected = _selected.contains(userId);
                                  final g = ((a['gender'] ?? '') as String).toLowerCase();
                                  final isFemale = g.startsWith('f') || g.startsWith('k');
                                  final isMale = g.startsWith('m') || g.startsWith('e');
                                  final Color iconColor = Theme.of(context).colorScheme.primary;
                                  final IconData? genderIcon = isFemale
                                      ? Icons.female
                                      : isMale
                                          ? Icons.male
                                          : null;
                                  
                                  // Get classification info
                                  final Map<String, dynamic>? classification = a['classification'] as Map<String, dynamic>?;
                                  final Map<String, dynamic>? ageGroups = classification != null ? classification['age_groups'] as Map<String, dynamic>? : null;
                                  final String localeCode = Localizations.localeOf(context).languageCode;
                                  final String ageGroupText = ageGroups == null
                                      ? (classification != null ? (classification['age_group_id']?.toString() ?? '') : '')
                                      : (localeCode == 'tr' ? (ageGroups['age_group_tr'] ?? '') : (ageGroups['age_group_en'] ?? ''));
                                  
                                  // Build classification display text from properties
                                  String classificationDisplayText = '';
                                  if (classification != null) {
                                    final parts = <String>[];
                                    if (ageGroupText.isNotEmpty) parts.add(ageGroupText);
                                    if (classification['bow_type'] != null) parts.add(classification['bow_type']);
                                    if (classification['gender'] != null) parts.add(classification['gender']);
                                    if (classification['distance'] != null) parts.add('${classification['distance']}m');
                                    if (classification['environment'] != null) parts.add(classification['environment']);
                                    classificationDisplayText = parts.join(' • ');
                                  }

                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(userId);
                                        } else {
                                          _selected.remove(userId);
                                        }
                                      });
                                    },
                                    title: () {
                                      if (name.isNotEmpty) {
                                        return Text(name);
                                      }
                                      if (visible.isNotEmpty && genderIcon != null) {
                                        return Row(
                                          children: [
                                            Icon(genderIcon, size: 18, color: iconColor),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(visible)),
                                          ],
                                        );
                                      }
                                      return Text(visible);
                                    }(),
                                    subtitle: () {
                                      // Build subtitle text with simple concatenation
                                      List<String> subtitleParts = [];
                                      
                                      // Add visible ID if name is not empty
                                      if (name.isNotEmpty && visible.isNotEmpty) {
                                        subtitleParts.add(visible);
                                      }
                                      
                                      // Add classification info if available
                                      if (classificationDisplayText.isNotEmpty) {
                                        subtitleParts.add('${l10n.classification}: $classificationDisplayText');
                                      }
                                      
                                      // Add age group if available
                                      if (ageGroupText.isNotEmpty) {
                                        subtitleParts.add(ageGroupText);
                                      }
                                      
                                      if (subtitleParts.isEmpty) return null;
                                      
                                      return Text(
                                        subtitleParts.join(' • '),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }(),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(
                              child: SelectableText.rich(
                                TextSpan(text: l10n.operationFailed),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    bottomNavigationBar: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          top: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _selected.isEmpty
                                    ? null
                                    : () {
                                        Navigator.of(context).pop(UserMultiSelectResult(_selected.toList()));
                                      },
                                icon: const Icon(Icons.person_add),
                                label: Text(l10n.addToCompetition),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                ),
                              ),
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


