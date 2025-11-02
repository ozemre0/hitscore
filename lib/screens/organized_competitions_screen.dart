import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'organized/competition_management_screen.dart';
import 'organized/add_organizer_screen.dart';
import 'edit_competition_screen.dart';
import 'organized/create_competition_screen.dart';

class OrganizedCompetitionsScreen extends ConsumerStatefulWidget {
  const OrganizedCompetitionsScreen({super.key});

  @override
  ConsumerState<OrganizedCompetitionsScreen> createState() => _OrganizedCompetitionsScreenState();
}

class _OrganizedCompetitionsScreenState extends ConsumerState<OrganizedCompetitionsScreen> {
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
              child: _OrganizedCompetitionsContent(),
            ),
          );
        },
      ),
    );
  }
}

class _OrganizedCompetitionsContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OrganizedCompetitionsContent> createState() => _OrganizedCompetitionsContentState();
}

class _OrganizedCompetitionsContentState extends ConsumerState<_OrganizedCompetitionsContent> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _filteredCompetitions = [];
  String? _error;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _scorePermission = 'all'; // 'all' | 'allowed' | 'not_allowed'
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

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

      // Get competitions where current user is creator or listed as organizer
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
            organizer_ids,
            created_at,
            classifications:organized_competitions_classifications!competition_id(id),
            participants:organized_competition_participants!fk_organized_competition(status)
          ''')
          .or('created_by.eq.${user.id},organizer_ids.cs.{${user.id}}')
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

  void _applyFilters() {
    final rawQuery = _searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> list = _competitions;

    // Score permission filter
    if (_scorePermission != 'all') {
      final wantAllowed = _scorePermission == 'allowed';
      list = list.where((c) {
        final allowed = c['score_allowed'] as bool? ?? false;
        return wantAllowed ? allowed : !allowed;
      }).toList(growable: false);
    }

    // Date range filter (by start_date)
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

    // Search by name, description or competition_visible_id
    if (rawQuery.isNotEmpty) {
      list = list.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final desc = (c['description'] ?? '').toString().toLowerCase();
        final visibleId = c['competition_visible_id']?.toString().toLowerCase() ?? '';
        return name.contains(rawQuery) || desc.contains(rawQuery) || visibleId.contains(rawQuery);
      }).toList(growable: false);
    }

    setState(() {
      _filteredCompetitions = list;
    });
  }

  void _onSearchChangedImmediate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _applyFilters();
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
                            final weekday = now.weekday; // Mon=1
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

  Future<void> _createAndOpenCompetition() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateCompetitionScreen(),
      ),
    );
    if (mounted) {
      await _loadCompetitions();
    }
  }

  Future<void> _deleteCompetition(Map<String, dynamic> competition) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.competitionDelete),
        content: Text(l10n.competitionDeleteConfirm),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseConfig.client
          .from('organized_competitions')
          .update({'is_deleted': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('organized_competition_id', competition['organized_competition_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.competitionDeleteSuccess)),
      );
      await _loadCompetitions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.errorGeneric}: $e')),
      );
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _createAndOpenCompetition,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createCompetitionTitle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _createAndOpenCompetition,
              icon: const Icon(Icons.add),
                label: Text(l10n.createCompetitionTitle),
            ),
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
            onRefresh: _loadCompetitions,
            child: _filteredCompetitions.isEmpty
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
                    itemCount: _filteredCompetitions.length,
                    itemBuilder: (context, index) {
                      final competition = _filteredCompetitions[index];
                      return _OrganizedCompetitionCard(
                        competition: competition,
                        onParticipantsTap: () => _navigateToManagement(competition['organized_competition_id']),
                        onEditTap: () => _navigateToEdit(competition),
                        onDeleteTap: () => _deleteCompetition(competition),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _OrganizedCompetitionCard extends StatelessWidget {
  final Map<String, dynamic> competition;
  final VoidCallback onParticipantsTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _OrganizedCompetitionCard({
    required this.competition,
    required this.onParticipantsTap,
    required this.onEditTap,
    required this.onDeleteTap,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
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
                          // copy icon removed
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
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: false,
                        barrierColor: Colors.black54.withOpacity(0.3),
                        builder: (modalCtx) {
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(modalCtx).pop();
                                      onEditTap();
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: Text(l10n.competitionEdit),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      Navigator.of(modalCtx).pop();
                                      final String compId = (competition['organized_competition_id'] as String?) ?? '';
                                      final List<dynamic> arr = (competition['organizer_ids'] as List<dynamic>?) ?? <dynamic>[];
                                      final List<String> initial = arr.whereType<String>().toList();
                                      final result = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (context) => AddOrganizerScreen(
                                            competitionId: compId,
                                            initialOrganizerIds: initial,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        // Reload the list to reflect changes
                                        if (context.mounted) {
                                          final state = context.findAncestorStateOfType<_OrganizedCompetitionsContentState>();
                                          state?._loadCompetitions();
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.person_add_alt_1),
                                    label: Text(l10n.addOrganizer),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(modalCtx).pop();
                                      onDeleteTap();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: Text(l10n.competitionDelete),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
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

