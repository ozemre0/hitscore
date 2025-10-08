import 'package:flutter/material.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'score_entry_screen.dart';

class ParticipantCompetitionsScreen extends ConsumerStatefulWidget {
  const ParticipantCompetitionsScreen({super.key});

  @override
  ConsumerState<ParticipantCompetitionsScreen> createState() => _ParticipantCompetitionsScreenState();
}

class _ParticipantCompetitionsScreenState extends ConsumerState<ParticipantCompetitionsScreen> {
  final GlobalKey<_ParticipantCompetitionsContentState> _contentKey = GlobalKey<_ParticipantCompetitionsContentState>();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.participantCompetitionsTitle),
        actions: const [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _ParticipantCompetitionsContent(key: _contentKey),
            ),
          );
        },
      ),
    );
  }
}

class _ParticipantCompetitionsContent extends ConsumerStatefulWidget {
  const _ParticipantCompetitionsContent({super.key});
  @override
  ConsumerState<_ParticipantCompetitionsContent> createState() => _ParticipantCompetitionsContentState();
}

class _ParticipantCompetitionsContentState extends ConsumerState<_ParticipantCompetitionsContent> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _participations = [];
  List<Map<String, dynamic>> _filteredParticipations = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  String _scorePermission = 'all'; // 'all' | 'allowed' | 'not_allowed'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChangedImmediate);
    _loadParticipations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadParticipations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'auth';
          _isLoading = false;
        });
        return;
      }

      // Get user's participations with qualification data
      final response = await SupabaseConfig.client
          .from('organized_competition_participants')
          .select('''
            participant_id,
            organized_competition_id,
            status,
            created_at,
            classification_id,
            organized_competitions!fk_organized_competition (
              name,
              competition_visible_id,
              start_date,
              end_date,
              status,
              score_allowed
            ),
            classification:organized_competitions_classifications(
              name,
              arrow_per_set,
              set_per_round,
              available_score_buttons
            ),
            qualification:organized_qualifications(
              qualification_total_score,
              qualification_sets_data,
              created_at,
              updated_at
            )
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      

      setState(() {
        _participations = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChangedImmediate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final rawQuery = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> list = _participations;

    // Score permission filter
    if (_scorePermission != 'all') {
      final wantAllowed = _scorePermission == 'allowed';
      list = list.where((p) {
        final comp = p['organized_competitions'] as Map<String, dynamic>?;
        final allowed = comp?['score_allowed'] as bool? ?? false;
        return wantAllowed ? allowed : !allowed;
      }).toList(growable: false);
    }

    // Date range filter (by competition start_date)
    if (_fromDate != null || _toDate != null) {
      list = list.where((p) {
        final comp = p['organized_competitions'] as Map<String, dynamic>?;
        final startStr = comp?['start_date'] as String?;
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

    // Search by competition name or competition_visible_id
    if (rawQuery.isNotEmpty) {
      list = list.where((p) {
        final comp = p['organized_competitions'] as Map<String, dynamic>?;
        final name = (comp?['name'] ?? '').toString().toLowerCase();
        final visibleId = comp?['competition_visible_id']?.toString().toLowerCase() ?? '';
        return name.contains(rawQuery) || visibleId.contains(rawQuery);
      }).toList(growable: false);
    }

    setState(() {
      _filteredParticipations = list;
    });
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
                              _scorePermission = 'all';
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
                Text(l10n.scorePermission, style: Theme.of(modalCtx).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Builder(
                      builder: (bctx) {
                        final isDark = Theme.of(bctx).brightness == Brightness.dark;
                        final allowedColor = isDark ? Colors.greenAccent : Colors.green.shade700;
                        final notAllowedColor = isDark ? Colors.redAccent : Colors.red.shade700;
                        final neutralSelected = Theme.of(bctx).colorScheme.primary.withOpacity(0.12);
                        final outline = Theme.of(bctx).colorScheme.outline.withOpacity(0.6);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.all),
                              selected: _scorePermission == 'all',
                              selectedColor: neutralSelected,
                              side: BorderSide(color: _scorePermission == 'all' ? Theme.of(bctx).colorScheme.primary : outline),
                              onSelected: (sel) {
                                if (!sel) return;
                                setState(() => _scorePermission = 'all');
                                setModalState(() {});
                                _applyFilters();
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(
                                l10n.scoreAllowed,
                                style: Theme.of(bctx).textTheme.bodyMedium?.copyWith(
                                      color: _scorePermission == 'allowed' ? allowedColor : null,
                                      fontWeight: _scorePermission == 'allowed' ? FontWeight.w600 : null,
                                    ),
                              ),
                              selected: _scorePermission == 'allowed',
                              selectedColor: allowedColor.withOpacity(0.15),
                              side: BorderSide(color: _scorePermission == 'allowed' ? allowedColor : outline),
                              onSelected: (sel) {
                                if (!sel) return;
                                setState(() => _scorePermission = 'allowed');
                                setModalState(() {});
                                _applyFilters();
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(
                                l10n.scoreNotAllowed,
                                style: Theme.of(bctx).textTheme.bodyMedium?.copyWith(
                                      color: _scorePermission == 'not_allowed' ? notAllowedColor : null,
                                      fontWeight: _scorePermission == 'not_allowed' ? FontWeight.w600 : null,
                                    ),
                              ),
                              selected: _scorePermission == 'not_allowed',
                              selectedColor: notAllowedColor.withOpacity(0.15),
                              side: BorderSide(color: _scorePermission == 'not_allowed' ? notAllowedColor : outline),
                              onSelected: (sel) {
                                if (!sel) return;
                                setState(() => _scorePermission = 'not_allowed');
                                setModalState(() {});
                                _applyFilters();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        final weekday = now.weekday; // 1..7 Mon..Sun
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

  void _navigateToScoreEntry(Map<String, dynamic> participation, Map<String, dynamic>? competition, Map<String, dynamic>? classification) {
    if (competition == null) return;
    
    final l10n = AppLocalizations.of(context)!;
    final scoreAllowed = competition['score_allowed'] as bool? ?? false;
    
    // Check if score entry is allowed
    if (!scoreAllowed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.scoreEntryNotAllowedTitle),
          content: Text(l10n.scoreEntryNotAllowedMessage),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    
    final competitionId = participation['organized_competition_id'] as String;
    final competitionName = competition['name'] as String? ?? 'Untitled Competition';
    final competitionVisibleId = competition['competition_visible_id'] as String? ?? 'N/A';
    
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScoreEntryScreen(
          competitionId: competitionId,
          competitionName: competitionName,
          competitionVisibleId: competitionVisibleId,
          classification: classification,
        ),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result is Map && result['updatedQualification'] != null) {
        final updated = Map<String, dynamic>.from(result['updatedQualification'] as Map);
        setState(() {
          // Find and update this participation's qualification fields in-place
          for (int i = 0; i < _participations.length; i++) {
            final p = _participations[i];
            if ((p['organized_competition_id'] as String?) == competitionId) {
              // qualification is a list; ensure first item exists
              List<dynamic> q = [];
              final qData = p['qualification'];
              if (qData is List) {
                q = List<dynamic>.from(qData);
              } else if (qData is Map<String, dynamic>) {
                q = [qData];
              }
              if (q.isEmpty) q = [{}];
              final Map<String, dynamic> q0 = Map<String, dynamic>.from(q.first as Map? ?? {});
              q0['qualification_total_score'] = updated['qualification_total_score'];
              q0['qualification_sets_data'] = updated['qualification_sets_data'];
              q[0] = q0;
              p['qualification'] = q;
              _participations[i] = p;
              break;
            }
          }
          _applyFilters();
        });
      }
    });
  }

  Future<void> _leaveCompetition(String competitionId) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.leaveCompetition),
        content: Text(l10n.leaveCompetitionConfirm),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            child: Text(l10n.leaveCompetition),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseConfig.client
            .from('organized_competition_participants')
            .delete()
            .eq('organized_competition_id', competitionId)
            .eq('athlete_id', SupabaseConfig.client.auth.currentUser!.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.competitionLeft)),
          );
          _loadParticipations();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.leaveCompetitionError)),
          );
        }
      }
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
                text: l10n.participantCompetitionsLoadError,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadParticipations,
              child: Text(l10n.refresh),
            ),
          ],
        ),
      );
    }

    if (_participations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
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
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openFiltersSheet,
                icon: const Icon(Icons.filter_list),
                label: Text(l10n.filter),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_fromDate != null || _toDate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
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
          ),
        if (_scorePermission != 'all')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Icon(Icons.score, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.scorePermission}: '
                    '${_scorePermission == 'allowed' ? l10n.scoreAllowed : l10n.scoreNotAllowed}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _scorePermission = 'all';
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
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadParticipations,
            child: _filteredParticipations.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            l10n.noResults,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredParticipations.length,
                    itemBuilder: (context, index) {
                      final participation = _filteredParticipations[index];
                      final competition = participation['organized_competitions'] as Map<String, dynamic>?;
                      final classification = participation['classification'] as Map<String, dynamic>?;

                      // Handle qualification data - it comes as a List, we need the first item
                      Map<String, dynamic>? qualification;
                      final qualificationData = participation['qualification'];
                      if (qualificationData is List && qualificationData.isNotEmpty) {
                        qualification = qualificationData.first as Map<String, dynamic>?;
                      } else if (qualificationData is Map<String, dynamic>) {
                        qualification = qualificationData;
                      }

                      return _SimpleParticipationCard(
                        participation: participation,
                        competition: competition,
                        classification: classification,
                        qualification: qualification,
                        onLeave: () => _leaveCompetition(participation['organized_competition_id']),
                        onCardTap: () => _navigateToScoreEntry(participation, competition, classification),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _SimpleParticipationCard extends StatelessWidget {
  final Map<String, dynamic> participation;
  final Map<String, dynamic>? competition;
  final Map<String, dynamic>? classification;
  final Map<String, dynamic>? qualification;
  final VoidCallback onLeave;
  final VoidCallback onCardTap;

  const _SimpleParticipationCard({
    required this.participation,
    required this.competition,
    required this.classification,
    required this.qualification,
    required this.onLeave,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    final status = participation['status'] as String? ?? 'pending';
    final joinedAt = participation['created_at'] as String?;
    final competitionName = competition?['name'] as String?;
    final competitionVisibleId = competition?['competition_visible_id'] as String?;
    final competitionDescription = competition?['description'] as String?;
    final startDate = competition?['start_date'] as String?;
    final endDate = competition?['end_date'] as String?;
    final competitionStatus = competition?['status'] as String? ?? 'draft';
    final classificationName = classification?['name'] as String?;
    final scoreAllowed = competition?['score_allowed'] as bool? ?? false;
    
    // Calculate score information
    final currentScore = qualification?['qualification_total_score'] as int? ?? 0;
    final arrowPerSet = classification?['arrow_per_set'] as int? ?? 3;
    final setPerRound = classification?['set_per_round'] as int? ?? 10;
    final maxScore = arrowPerSet * setPerRound * 10; // Maximum possible score
    final hasQualificationData = qualification != null && qualification!['qualification_total_score'] != null;
    

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: status == 'accepted' ? onCardTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          competitionName ?? l10n.untitledCompetition,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (classificationName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            classificationName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Score information
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasQualificationData 
                                ? colorScheme.primary.withOpacity(0.1)
                                : colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasQualificationData 
                                ? '$currentScore / $maxScore'
                                : 'Henüz skor girilmemiş',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: hasQualificationData 
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _StatusChip(status: status),
                      if (status == 'accepted') ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            if (competitionVisibleId != null) ...[
              const SizedBox(height: 4),
              Text(
                '${l10n.competitionVisibleIdLabel}: ${competitionVisibleId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (competitionDescription != null && competitionDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                competitionDescription,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
            const SizedBox(height: 4),
            Row(
              children: [
                if (joinedAt != null) ...[
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.joinedOn}: ${_formatDate(joinedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Spacer(),
                if (competitionStatus == 'active' && status == 'accepted')
                  OutlinedButton(
                    onPressed: onLeave,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(l10n.leaveCompetition),
                  ),
              ],
            ),
            if (startDate != null || endDate != null) ...[
              const SizedBox(height: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (startDate != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.competitionStartsOn}: ${_formatDate(startDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (endDate != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.stop,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${l10n.competitionEndsOn}: ${_formatDate(endDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ));
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

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'accepted':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        text = l10n.acceptedStatus;
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        text = l10n.pendingStatus;
        break;
      case 'rejected':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        text = l10n.cancelledStatus;
        break;
      default:
        backgroundColor = colorScheme.surfaceVariant;
        textColor = colorScheme.onSurfaceVariant;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
