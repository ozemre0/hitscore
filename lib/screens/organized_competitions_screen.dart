import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'organized/competition_management_screen.dart';
import 'edit_competition_screen.dart';
import 'organized/create_competition_screen.dart';

class OrganizedCompetitionsScreen extends ConsumerStatefulWidget {
  const OrganizedCompetitionsScreen({super.key});

  @override
  ConsumerState<OrganizedCompetitionsScreen> createState() => _OrganizedCompetitionsScreenState();
}

class _OrganizedCompetitionsScreenState extends ConsumerState<OrganizedCompetitionsScreen> {
  final GlobalKey<_OrganizedCompetitionsContentState> _contentKey = GlobalKey<_OrganizedCompetitionsContentState>();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrganizedCompetitionsTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _OrganizedCompetitionsContent(key: _contentKey),
            ),
          );
        },
      ),
    );
  }
}

class _OrganizedCompetitionsContent extends ConsumerStatefulWidget {
  const _OrganizedCompetitionsContent({super.key});
  @override
  ConsumerState<_OrganizedCompetitionsContent> createState() => _OrganizedCompetitionsContentState();
}

class _OrganizedCompetitionsContentState extends ConsumerState<_OrganizedCompetitionsContent> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _filteredCompetitions = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChangedImmediate);
    _loadCompetitions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChangedImmediate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> list = _competitions;

    if (_fromDate != null || _toDate != null) {
      list = list.where((c) {
        final startStr = c['start_date'] as String?;
        if (startStr == null) return false;
        DateTime d;
        try {
          d = DateTime.parse(startStr);
        } catch (_) {
          return false;
        }
        if (_fromDate != null && d.isBefore(DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day))) return false;
        if (_toDate != null && d.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59))) return false;
        return true;
      }).toList(growable: false);
    }

    if (query.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final visibleId = c['competition_visible_id']?.toString().toLowerCase() ?? '';
        return name.contains(query) || visibleId.contains(query);
      }).toList(growable: false);
    }

    setState(() {
      _filteredCompetitions = list;
    });
  }

  Future<void> _loadCompetitions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not found';
          _isLoading = false;
        });
        return;
      }

      // Get competitions created by the current user
      debugPrint('[OrganizedCompetitions] Loading competitions for user: ${user.id}');
      final response = await SupabaseConfig.client
          .from('organized_competitions')
          .select('''
            organized_competition_id,
            name,
            description,
            start_date,
            end_date,
            registration_allowed,
            score_allowed,
            competition_visible_id,
            created_at,
            classifications:organized_competitions_classifications!competition_id(id),
            participants:organized_competition_participants!fk_organized_competition(status)
          ''')
          .eq('created_by', user.id)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      debugPrint('[OrganizedCompetitions] Loaded ${list.length} competitions');
      if (list.isNotEmpty) {
        debugPrint('[OrganizedCompetitions] First item keys: ${list.first.keys.toList()}');
        debugPrint('[OrganizedCompetitions] First item id: ${list.first['organized_competition_id']} visible_id: ${list.first['competition_visible_id']}');
      }

      setState(() {
        _competitions = list;
        _filteredCompetitions = list;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e, st) {
      debugPrint('[OrganizedCompetitions] Error loading competitions: $e');
      debugPrint(st.toString());
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToManagement(String competitionId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompetitionParticipantsScreen(competitionId: competitionId),
      ),
    );
    if (mounted) {
      await _loadCompetitions();
    }
  }

  Future<void> _navigateToEdit(Map<String, dynamic> competition) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCompetitionScreen(competition: competition),
      ),
    );
    if (result == true) {
      await _loadCompetitions();
    }
  }

  Future<void> _navigateToCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateCompetitionScreen(),
      ),
    );
    if (mounted) {
      await _loadCompetitions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            SelectableText.rich(
              TextSpan(
                text: l10n.competitionLoadError,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadCompetitions,
              child: Text(l10n.refresh),
            ),
          ],
        ),
      );
    }

    if (_competitions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.myCompetitionsEmptyTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.myCompetitionsEmptyDesc,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _navigateToCreate,
                icon: const Icon(Icons.add),
                label: Text(l10n.createCompetitionTitle),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompetitions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        itemCount: 1 + (_filteredCompetitions.isEmpty ? 1 : _filteredCompetitions.length),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: l10n.searchCompetitionHint,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: l10n.clear,
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                ),
                        ),
                        onChanged: (_) => _onSearchChangedImmediate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openFiltersSheet,
                      icon: const Icon(Icons.filter_list),
                      label: Text(l10n.filter),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _navigateToCreate,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.createCompetitionTitle),
                    ),
                  ],
                ),
                if (_fromDate != null || _toDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _fromDate != null && _toDate != null
                              ? '${l10n.dateRange}: '
                                '${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} – '
                                '${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}'
                              : _fromDate != null
                                  ? '${l10n.dateFrom}: '
                                    '${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year}'
                                  : '${l10n.dateTo}: '
                                    '${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                          });
                          _applyFilters();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                        child: Text(l10n.clear),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            );
          }

          if (_filteredCompetitions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  l10n.noResults,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }

          final competition = _filteredCompetitions[index - 1];
          return _OrganizedCompetitionCard(
            competition: competition,
            onParticipantsTap: () => _navigateToManagement(competition['organized_competition_id']),
            onEditTap: () => _navigateToEdit(competition),
          );
        },
      ),
    );
  }

  Future<void> _openFiltersSheet() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black54.withOpacity(0.3),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 16 + MediaQuery.of(modalCtx).viewPadding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.filters,
                            style: Theme.of(modalCtx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                            });
                            setModalState(() {});
                            _applyFilters();
                          },
                          child: Text(l10n.clear),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.dateRange, style: Theme.of(modalCtx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, now.day);
                            final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                            setState(() {
                              _fromDate = start;
                              _toDate = end;
                            });
                            setModalState(() {});
                            _applyFilters();
                          },
                          child: Text(l10n.presetToday),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            final weekday = now.weekday;
                            final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
                            final endBase = start.add(const Duration(days: 6));
                            final end = DateTime(endBase.year, endBase.month, endBase.day, 23, 59, 59);
                            setState(() {
                              _fromDate = start;
                              _toDate = end;
                            });
                            setModalState(() {});
                            _applyFilters();
                          },
                          child: Text(l10n.presetThisWeek),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            final start = DateTime(now.year, now.month, 1);
                            final nextMonth = DateTime(now.year, now.month + 1, 1);
                            final endBase = nextMonth.subtract(const Duration(days: 1));
                            final end = DateTime(endBase.year, endBase.month, endBase.day, 23, 59, 59);
                            setState(() {
                              _fromDate = start;
                              _toDate = end;
                            });
                            setModalState(() {});
                            _applyFilters();
                          },
                          child: Text(l10n.presetThisMonth),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final initStart = _fromDate ?? DateTime.now();
                        final initEnd = _toDate ?? initStart;
                        final picked = await showDateRangePicker(
                          context: modalCtx,
                          firstDate: DateTime(DateTime.now().year - 5),
                          lastDate: DateTime(DateTime.now().year + 5),
                          initialDateRange: DateTimeRange(start: initStart, end: initEnd),
                        );
                        if (picked != null) {
                          final start = DateTime(picked.start.year, picked.start.month, picked.start.day);
                          final end = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
                          setState(() {
                            _fromDate = start;
                            _toDate = end;
                          });
                          setModalState(() {});
                          _applyFilters();
                        }
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fromDate == null || _toDate == null
                              ? '${l10n.dateFrom} • ${l10n.dateTo}'
                              : '${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} – ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (buttonCtx) {
                              final cancelColor = Theme.of(buttonCtx).brightness == Brightness.dark
                                  ? Colors.redAccent
                                  : Colors.red.shade700;
                              return OutlinedButton(
                                onPressed: () {
                                  Navigator.of(modalCtx).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cancelColor,
                                  side: BorderSide(color: cancelColor, width: 1),
                                ),
                                child: Text(l10n.cancel),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OrganizedCompetitionCard extends StatelessWidget {
  final Map<String, dynamic> competition;
  final VoidCallback onParticipantsTap;
  final VoidCallback onEditTap;

  const _OrganizedCompetitionCard({
    required this.competition,
    required this.onParticipantsTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    final competitionName = competition['name'] as String?;
    final competitionVisibleId = competition['competition_visible_id'] as String?;
    final competitionDescription = competition['description'] as String?;
    final startDate = competition['start_date'] as String?;
    final endDate = competition['end_date'] as String?;
    final int classificationCount = () {
      final dynamic rel = competition['classifications'];
      if (rel is List) return rel.length;
      return 0;
    }();
    final int pendingCount = () {
      final dynamic rel = competition['participants'];
      if (rel is List) {
        int c = 0;
        for (final item in rel) {
          if (item is Map && (item['status'] == 'pending' || item['status'] == 'Pending')) {
            c++;
          }
        }
        return c;
      }
      return 0;
    }();
    final int acceptedCount = () {
      final dynamic rel = competition['participants'];
      if (rel is List) {
        int c = 0;
        for (final item in rel) {
          if (item is Map && (item['status'] == 'accepted' || item['status'] == 'Accepted')) {
            c++;
          }
        }
        return c;
      }
      return 0;
    }();
    final bool registrationAllowed = (competition['registration_allowed'] as bool?) ?? false;
    final bool scoreAllowed = (competition['score_allowed'] as bool?) ?? false;

    // Registration state based on boolean flag
    final isRegistrationOpen = registrationAllowed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        onTap: onParticipantsTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: competitionName ?? l10n.untitledCompetition,
                      child: Text(
                        competitionName ?? l10n.untitledCompetition,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),
              if (competitionDescription != null && competitionDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  competitionDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.competitionStartsOn}: ${_formatDate(startDate ?? '')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.competitionEndsOn}: ${_formatDate(endDate ?? '')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (pendingCount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.hourglass_empty, size: 16, color: colorScheme.error),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.pendingRequestsCount(pendingCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.verified, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade800),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l10n.acceptedParticipantsCount(acceptedCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              if (competitionVisibleId != null && competitionVisibleId.toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.confirmation_number, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${l10n.competitionVisibleIdLabel}: $competitionVisibleId',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: l10n.competitionVisibleIdCopyTooltip,
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(
                                text: competitionVisibleId.toString(),
                              ));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.competitionVisibleIdCopied)),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l10n.competitionClassificationsCount(classificationCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    isRegistrationOpen ? Icons.how_to_reg : Icons.block,
                    size: 16,
                    color: isRegistrationOpen 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade900)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.red : Colors.red.shade700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRegistrationOpen ? l10n.registrationOpen : l10n.registrationClosed,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isRegistrationOpen 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade900)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.red : Colors.red.shade700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    scoreAllowed ? Icons.score : Icons.scoreboard_outlined,
                    size: 16,
                    color: scoreAllowed 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade900)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.red : Colors.red.shade700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scoreAllowed ? l10n.scoreEntryAllowed : l10n.scoreEntryNotAllowed,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scoreAllowed 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade400 : Colors.green.shade900)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.red : Colors.red.shade700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEditTap,
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.competitionEdit),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onParticipantsTap,
                    icon: const Icon(Icons.people),
                    label: Text(l10n.competitionParticipants),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.secondary,
                      side: BorderSide(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

