import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'competition_participants_screen.dart';

class ActiveCompetitionsScreen extends StatefulWidget {
  const ActiveCompetitionsScreen({super.key});

  @override
  State<ActiveCompetitionsScreen> createState() => _ActiveCompetitionsScreenState();
}

class _ActiveCompetitionsScreenState extends State<ActiveCompetitionsScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _competitions = [];
  List<Map<String, dynamic>> _filteredCompetitions = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final Set<String> _pendingCompetitionIds = <String>{};
  final Map<String, String> _pendingClassificationNameByCompetitionId = <String, String>{};

  // Filters
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

    // Search
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await SupabaseConfig.client
          .from('organized_competitions')
          .select('organized_competition_id,name,description,start_date,end_date,competition_visible_id,registration_allowed,status,score_allowed')
          .eq('is_deleted', false)
          .eq('status', 'active')
          .eq('registration_allowed', true)
          .order('start_date');

      final competitions = List<Map<String, dynamic>>.from(response);
      setState(() {
        _competitions = competitions;
        _filteredCompetitions = competitions;
      });
      await _loadUserPendingStatuses(competitions);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserPendingStatuses(List<Map<String, dynamic>> competitions) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null || competitions.isEmpty) return;
      final visibleIds = competitions.map((e) => e['organized_competition_id']).whereType<String>().toSet();
      if (visibleIds.isEmpty) return;
      final rows = await SupabaseConfig.client
          .from('organized_competition_participants')
          .select('organized_competition_id, classification_id')
          .eq('user_id', user.id)
          .eq('status', 'pending');
      final fetchedPending = rows.map<String>((r) => r['organized_competition_id'] as String).toSet();
      final pendingIds = fetchedPending.intersection(visibleIds);
      // Fetch classification names for those pending rows
      final classificationIds = rows
          .where((r) => r['classification_id'] != null && pendingIds.contains(r['organized_competition_id']))
          .map<String>((r) => r['classification_id'].toString())
          .toSet();
      Map<String, String> idToName = {};
      if (classificationIds.isNotEmpty) {
        final orFilter = classificationIds.map((id) => 'id.eq.$id').join(',');
        final clsRows = await SupabaseConfig.client
            .from('organized_competitions_classifications')
            .select('id, name')
            .or(orFilter);
        for (final cl in List<Map<String, dynamic>>.from(clsRows)) {
          idToName[cl['id'].toString()] = (cl['name'] ?? '').toString();
        }
      }
      setState(() {
        _pendingCompetitionIds
          ..clear()
          ..addAll(pendingIds);
        _pendingClassificationNameByCompetitionId.clear();
        for (final r in rows) {
          final cid = r['organized_competition_id'] as String?;
          final clid = r['classification_id']?.toString();
          if (cid != null && pendingIds.contains(cid) && clid != null) {
            final name = idToName[clid];
            if (name != null && name.isNotEmpty) {
              _pendingClassificationNameByCompetitionId[cid] = name;
            }
          }
        }
      });
    } catch (_) {
      // Ignore; not critical for initial render
    }
  }


  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final d = DateTime.parse(dateString);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return dateString;
    }
  }

  Future<void> _joinCompetition(Map<String, dynamic> competition) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('auth');
      }
      // 1) Ask user to select classification
      final classificationId = await _pickClassification(competition['organized_competition_id'] as String);
      if (classificationId == null) return; // user cancelled

      // 1.5) Prevent duplicate pending requests for the same classification
      try {
        final existing = await SupabaseConfig.client
            .from('organized_competition_participants')
            .select('participant_id')
            .eq('organized_competition_id', competition['organized_competition_id'])
            .eq('classification_id', classificationId)
            .eq('user_id', user.id)
            .limit(1)
            .maybeSingle();
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.alreadyRequestedThisClassification)),
            );
          }
          return;
        }
      } catch (_) {
        // Ignore select error and proceed; server will still protect with unique/constraints if any
      }

      // 2) Insert pending request with classification
      final participantId = const Uuid().v4();
      
      // Get user's role from profile
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      
      final userRole = profile?['role'] as String? ?? 'athlete';
      
      await SupabaseConfig.client.from('organized_competition_participants').insert({
        'participant_id': participantId,
        'organized_competition_id': competition['organized_competition_id'],
        'classification_id': classificationId,
        'user_id': user.id,
        'participant_role': userRole,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _pendingCompetitionIds.add(competition['organized_competition_id'] as String);
        });
        try {
          final cl = await SupabaseConfig.client
              .from('organized_competitions_classifications')
              .select('id, name')
              .eq('id', classificationId)
              .maybeSingle();
          if (cl != null) {
            setState(() {
              _pendingClassificationNameByCompetitionId[competition['organized_competition_id'] as String] = (cl['name'] ?? '').toString();
            });
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSent)));
      }
    } on PostgrestException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      final isDuplicate = e.code == '23505';
      final isForeignKeyError = e.code == '23503' && e.message.contains('user_id');
      
      if (isDuplicate) {
        setState(() {
          _pendingCompetitionIds.add(competition['organized_competition_id'] as String);
        });
        // Refresh pending statuses to fetch classification name
        // ignore: discarded_futures
        _loadUserPendingStatuses(_competitions);
      }
      
      String message;
      if (isDuplicate) {
        message = l10n.requestSent;
      } else if (isForeignKeyError) {
        message = l10n.athleteProfileRequired;
      } else {
        message = '${l10n.competitionJoinError}: ${e.message}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.competitionJoinError}: $e')),
        );
      }
    }
  }

  Future<String?> _pickClassification(String competitionId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final rows = await SupabaseConfig.client
          .from('organized_competitions_classifications')
          .select('id, name, age_groups:age_groups(age_group_tr, age_group_en), bow_type, gender, distance, environment')
          .eq('competition_id', competitionId)
          .order('created_at');
      final items = List<Map<String, dynamic>>.from(rows);
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noClassificationsAvailable)));
        }
        return null;
      }

      return await showDialog<String>(
        context: context,
        builder: (ctx) {
          final localeCode = Localizations.localeOf(ctx).languageCode;
          return AlertDialog(
            title: Text(l10n.selectClassificationTitle),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.selectClassificationInstruction,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (ctx2, index) {
                        final cl = items[index];
                        final ageGroups = cl['age_groups'] as Map<String, dynamic>?;
                        final ageName = ageGroups == null
                            ? ''
                            : (localeCode == 'tr' ? (ageGroups['age_group_tr'] ?? '') : (ageGroups['age_group_en'] ?? ''));
                        final subtitle = [
                          if (ageName.isNotEmpty) ageName,
                          if (cl['gender'] != null) cl['gender'],
                          if (cl['bow_type'] != null) cl['bow_type'],
                          if (cl['distance'] != null) '${cl['distance']}m',
                          if (cl['environment'] != null) cl['environment'],
                        ].where((e) => e != null && e.toString().isNotEmpty).join(' • ');
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(ctx).colorScheme.outline.withOpacity(0.8),
                              width: 1,
                            ),
                          ),
                          tileColor: Theme.of(ctx).colorScheme.surface,
                          title: Text(cl['name'] ?? '-'),
                          subtitle: subtitle.isNotEmpty
                              ? Text(subtitle, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant))
                              : null,
                          onTap: () => Navigator.of(ctx).pop(cl['id'].toString()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
      }
      return null;
    }
  }

  Future<void> _cancelRequest(Map<String, dynamic> competition) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: null,
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.cancel,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.cancelRequestConfirm,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.cancelRequest),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      await SupabaseConfig.client
          .from('organized_competition_participants')
          .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
          .match({
        'organized_competition_id': competition['organized_competition_id'],
        'user_id': user.id,
        'status': 'pending',
      });
      if (mounted) {
        setState(() {
          _pendingCompetitionIds.remove(competition['organized_competition_id'] as String);
          _pendingClassificationNameByCompetitionId.remove(competition['organized_competition_id'] as String);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestCancelled)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
      }
    }
  }

  void _showParticipants(Map<String, dynamic> competition) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CompetitionParticipantsScreen(
          competitionId: competition['organized_competition_id'] as String,
          competitionName: competition['name'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeCompetitionsTitle),
        actions: [
          IconButton(
            onPressed: _loadCompetitions,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _buildBody(l10n, colorScheme),
            ),
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
                    const SizedBox(height: 8),
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

  Widget _buildBody(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              SelectableText.rich(
                TextSpan(text: l10n.competitionLoadError, style: TextStyle(color: colorScheme.error, fontSize: 16)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(text: _error!, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: _loadCompetitions, icon: const Icon(Icons.refresh), label: Text(l10n.refresh)),
            ],
          ),
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
              Icon(Icons.emoji_events_outlined, size: 80, color: colorScheme.primary.withOpacity(0.6)),
              const SizedBox(height: 24),
              Text(l10n.activeCompetitionsEmptyTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.activeCompetitionsEmptyDesc, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
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
                      final c = _filteredCompetitions[index];
          final bool canRegister = (c['registration_allowed'] as bool?) ?? false;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      c['name'] ?? l10n.untitledCompetition,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (SupabaseConfig.client.auth.currentUser != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (canRegister ? Colors.green : Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: (canRegister ? Colors.green : Colors.grey).withOpacity(0.3)),
                      ),
                      child: Text(
                        canRegister ? l10n.registrationOpen : l10n.registrationClosed,
                        style: TextStyle(color: canRegister ? Colors.green : Colors.grey, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                ]),
                if (c['description'] != null && (c['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    c['description'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${l10n.competitionStartsOn}: ${_formatDate(c['start_date'])}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.event, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${l10n.competitionEndsOn}: ${_formatDate(c['end_date'])}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ]),
                if (c['competition_visible_id'] != null && c['competition_visible_id'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.confirmation_number, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${l10n.competitionVisibleIdLabel}: ${c['competition_visible_id']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
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
                                text: c['competition_visible_id'].toString(),
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
                  ]),
                ],
                Row(children: [
                  Icon(Icons.how_to_reg, size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(canRegister ? l10n.registrationOpen : l10n.registrationClosed, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 12),
                if (_pendingCompetitionIds.contains(c['organized_competition_id'])) ...[
                  Row(children: [
                    Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _pendingClassificationNameByCompetitionId[c['organized_competition_id']] ?? '-',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showParticipants(c),
                      icon: const Icon(Icons.people),
                      label: Text(l10n.participantsTitle),
                    ),
                    if (SupabaseConfig.client.auth.currentUser != null)
                      (_pendingCompetitionIds.contains(c['organized_competition_id'])
                          ? OutlinedButton.icon(
                              onPressed: () => _cancelRequest(c),
                              icon: const Icon(Icons.close),
                              label: Text(l10n.cancelRequest),
                            )
                          : OutlinedButton.icon(
                              onPressed: canRegister ? () => _joinCompetition(c) : null,
                              icon: const Icon(Icons.how_to_reg),
                              label: Text(l10n.competitionJoin),
                            )),
                  ],
                ),
              ]),
            ),
          );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}


