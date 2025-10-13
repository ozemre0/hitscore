import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';

class CompetitionParticipantsScreen extends StatefulWidget {
  final String competitionId;
  final String competitionName;

  const CompetitionParticipantsScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  State<CompetitionParticipantsScreen> createState() => _CompetitionParticipantsScreenState();
}

class _CompetitionParticipantsScreenState extends State<CompetitionParticipantsScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _classifications = [];
  List<Map<String, dynamic>> _participants = [];
  String? _selectedClassificationId;
  String? _selectedClassificationName;
  int _setsPerRound = 10;
  
  RealtimeChannel? _qualificationsChannel;
  Timer? _autoRefreshTimer;
  final Set<String> _dirtyParticipantIds = <String>{};
  Timer? _coalesceTimer;
  int _eventCountWindow = 0;
  DateTime _eventWindowStart = DateTime.now();
  final Map<String, int> _prevRankById = <String, int>{};
  final Map<String, int> _rankPulseCounter = <String, int>{};
  final Set<String> _activePulseIds = <String>{};
  final List<String> _pulseQueue = <String>[];
  Timer? _pulseBatchTimer;
  final Set<String> _expandedParticipantIds = <String>{}; // support multiple open drawers
  
  double _computeAverageFromParticipant(Map<String, dynamic> participant) {
    try {
      final List<dynamic>? qualifications = participant['qualifications'] as List<dynamic>?;
      if (qualifications == null || qualifications.isEmpty) return 0.0;
      final Map<String, dynamic>? q0 = qualifications.first as Map<String, dynamic>?;
      if (q0 == null) return 0.0;
      final dynamic sets = q0['qualification_sets_data'];
      List<dynamic> rawList;
      if (sets == null) return 0.0;
      if (sets is String) {
        try {
          rawList = (jsonDecode(sets) as List).toList();
        } catch (_) {
          return 0.0;
        }
      } else if (sets is List) {
        rawList = sets;
      } else {
        return 0.0;
      }

      int count = 0;
      int sum = 0;
      for (final item in rawList) {
        if (item is List && item.length >= 2 && item[1] is List) {
          final List<dynamic> arrows = List<dynamic>.from(item[1] as List);
          for (final v in arrows) {
            count++;
            if (v is String) {
              final String s = v.toUpperCase();
              if (s == 'X') {
                sum += 10;
              } else if (s == 'M') {
                sum += 0;
              } else {
                sum += int.tryParse(v) ?? 0;
              }
            } else {
              sum += (v as num?)?.toInt() ?? 0;
            }
          }
        }
      }
      if (count == 0) return 0.0;
      return sum / count;
    } catch (_) {
      return 0.0;
    }
  }

  String _formatTruncate3(double value) {
    final double truncated = (value * 1000).floor() / 1000.0;
    return truncated.toStringAsFixed(3);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadClassifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _qualificationsChannel?.unsubscribe();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedClassificationId != null) {
      // On app resume, do a one-time refresh and reset periodic timer
      _autoRefreshTimer?.cancel();
      _loadParticipantsByClassification(_selectedClassificationId!);
    }
  }

  Future<void> _loadClassifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await SupabaseConfig.client
          .from('organized_competitions_classifications')
          .select('''
            id,
            name,
            age_groups:age_groups(age_group_tr, age_group_en),
            bow_type,
            gender,
            distance,
            environment
          ''')
          .eq('competition_id', widget.competitionId)
          .order('created_at');

      final classifications = List<Map<String, dynamic>>.from(response);
      
      if (mounted) {
        setState(() {
          _classifications = classifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadParticipantsByClassification(String classificationId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load classification config for rounds
      try {
        final cl = await SupabaseConfig.client
            .from('organized_competitions_classifications')
            .select('round_count, set_per_round')
            .eq('id', classificationId)
            .maybeSingle();
        if (cl != null) {
          _setsPerRound = (cl['set_per_round'] as int?) ?? 10;
        }
      } catch (_) {}

      final response = await SupabaseConfig.client
          .from('organized_competition_participants')
          .select('''
            participant_id,
            profiles:user_id (
              first_name,
              last_name,
              club_id,
              clubs:club_id (
                club_name
              )
            ),
            qualifications:organized_qualifications!participant_id (
              qualification_total_score,
              qualification_sets_data
            )
          ''')
          .eq('organized_competition_id', widget.competitionId)
          .eq('classification_id', classificationId)
          .eq('status', 'accepted')
          .order('created_at');

      final participants = List<Map<String, dynamic>>.from(response);
      
      // Sort participants by average score (highest to lowest)
      participants.sort((a, b) {
        final double aAvg = _computeAverageFromParticipant(a);
        final double bAvg = _computeAverageFromParticipant(b);
        return bAvg.compareTo(aAvg);
      });
      
      if (mounted) {
        setState(() {
          _participants = participants;
          _isLoading = false;
        });
        _syncPrevRanksAfterFrame();
        // Prepare participant ids for filtered realtime subscription
        final List<String> participantIds = participants
            .map((p) => (p['participant_id'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

        // Use realtime instead of periodic polling; keep polling disabled while subscribed
        _autoRefreshTimer?.cancel();
        _subscribeQualifications(participantIds);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  

  

  

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedClassificationId == null ? l10n.participantsTitle : _selectedClassificationName ?? l10n.participantsTitle),
        leading: _selectedClassificationId != null
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _selectedClassificationId = null;
                    _selectedClassificationName = null;
                    _participants = [];
                  });
                },
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          IconButton(
            onPressed: _selectedClassificationId == null ? _loadClassifications : () => _loadParticipantsByClassification(_selectedClassificationId!),
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

  void _subscribeQualifications(List<String> participantIds) {
    // Unsubscribe existing channel first
    _qualificationsChannel?.unsubscribe();
    _qualificationsChannel = null;

    if (participantIds.isEmpty || _selectedClassificationId == null) {
      return;
    }


    _eventCountWindow = 0;
    _eventWindowStart = DateTime.now();
    _dirtyParticipantIds.clear();
    _coalesceTimer?.cancel();

    final channelName = 'qual_${widget.competitionId}_${_selectedClassificationId}';
    final channel = SupabaseConfig.client.channel(channelName);

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'organized_qualifications',
      callback: (payload) {
        if (!mounted || _selectedClassificationId == null) return;

        // Backpressure window (per ~1s)
        final now = DateTime.now();
        if (now.difference(_eventWindowStart).inMilliseconds > 1000) {
          _eventWindowStart = now;
          _eventCountWindow = 0;
        }
        _eventCountWindow++;

        // If too many updates, fallback to one-time full refresh shortly
        if (_eventCountWindow > 20) {
          _coalesceTimer?.cancel();
          _dirtyParticipantIds.clear();
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (!mounted || _selectedClassificationId == null) return;
            _loadParticipantsByClassification(_selectedClassificationId!);
          });
          return;
        }

        final Map<String, dynamic>? newRow = payload.newRecord;
        final String? participantId = newRow != null ? newRow['participant_id'] as String? : null;
        // Client-side filter to only handle currently displayed participant ids
        if (participantId == null || !participantIds.contains(participantId)) {
          return;
        }
        _dirtyParticipantIds.add(participantId);

        _coalesceTimer?.cancel();
        _coalesceTimer = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _applyCoalescedQualificationUpdates(payload: newRow);
        });
      },
    );

    channel.subscribe();
    _qualificationsChannel = channel;
  }

  void _applyCoalescedQualificationUpdates({Map<String, dynamic>? payload}) {
    if (_dirtyParticipantIds.isEmpty) return;

    final Map<String, int> updatedScores = {};
    final Map<String, dynamic> updatedSetsDataByParticipantId = {};
    // Try to get score from last payload if available; otherwise we still mark dirty for re-sort
    if (payload != null) {
      final String? pid = payload['participant_id'] as String?;
      final int? total = payload['qualification_total_score'] as int?;
      final dynamic setsData = payload['qualification_sets_data'];
      if (pid != null && total != null) {
        updatedScores[pid] = total;
      }
      if (pid != null && setsData != null) {
        updatedSetsDataByParticipantId[pid] = setsData;
      }
    }

    bool changed = false;
    for (int i = 0; i < _participants.length; i++) {
      final p = _participants[i];
      final String? pid = p['participant_id'] as String?;
      if (pid == null || !_dirtyParticipantIds.contains(pid)) continue;

      final List<dynamic>? quals = p['qualifications'] as List<dynamic>?;
      if (quals != null && quals.isNotEmpty) {
        final Map<String, dynamic>? q0 = quals.first as Map<String, dynamic>?;
        if (q0 != null) {
          final int? newScore = updatedScores[pid];
          if (newScore != null) {
            q0['qualification_total_score'] = newScore;
            changed = true;
          } else {
            // Mark as changed; we will re-sort even if value unknown (server authoritative)
            changed = true;
          }
          if (updatedSetsDataByParticipantId.containsKey(pid)) {
            q0['qualification_sets_data'] = updatedSetsDataByParticipantId[pid];
            changed = true;
          }
        }
      }
    }

    _dirtyParticipantIds.clear();

    if (changed) {
      // Keep a snapshot of previous ranks before we change order
      final Map<String, int> oldRanks = Map<String, int>.from(_prevRankById);
      // Re-sort by computed average desc
      _participants.sort((a, b) {
        final double aAvg = _computeAverageFromParticipant(a);
        final double bAvg = _computeAverageFromParticipant(b);
        return bAvg.compareTo(aAvg);
      });
      // Queue pulses for changed ranks within Top 20 (processed in batches of 10)
      final List<String> changedTop20 = <String>[];
      for (int i = 0; i < _participants.length && i < 20; i++) {
        final String? pid = _participants[i]['participant_id'] as String?;
        if (pid == null) continue;
        final int newRank = i + 1;
        final int? prevRank = oldRanks[pid];
        if (prevRank != null && prevRank != newRank) {
          changedTop20.add(pid);
        }
      }
      _enqueuePulseIds(changedTop20);
      setState(() {});
      _syncPrevRanksAfterFrame();
    }
  }

  void _enqueuePulseIds(List<String> ids) {
    if (ids.isEmpty) return;
    for (final id in ids) {
      if (!_pulseQueue.contains(id) && !_activePulseIds.contains(id)) {
        _pulseQueue.add(id);
      }
    }
    if (_pulseBatchTimer == null && _activePulseIds.isEmpty) {
      _startNextPulseBatch();
    }
  }

  void _startNextPulseBatch() {
    if (_pulseQueue.isEmpty) {
      _activePulseIds.clear();
      _pulseBatchTimer = null;
      return;
    }
    _activePulseIds.clear();
    while (_activePulseIds.length < 10 && _pulseQueue.isNotEmpty) {
      final String id = _pulseQueue.removeAt(0);
      _activePulseIds.add(id);
      _rankPulseCounter[id] = (_rankPulseCounter[id] ?? 0) + 1; // bump key to trigger animation
    }
    setState(() {});
    _pulseBatchTimer?.cancel();
    _pulseBatchTimer = Timer(const Duration(milliseconds: 360), () {
      // small buffer beyond 320ms to finish frames
      _activePulseIds.clear();
      setState(() {});
      // Start next batch if any
      if (_pulseQueue.isNotEmpty) {
        _startNextPulseBatch();
      } else {
        _pulseBatchTimer = null;
      }
    });
  }

  void _syncPrevRanksAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _participants.length; i++) {
        final String? pid = _participants[i]['participant_id'] as String?;
        if (pid != null) {
          _prevRankById[pid] = i + 1; // ranks are 1-based
        }
      }
    });
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
                TextSpan(
                  text: l10n.participantsLoadError,
                  style: TextStyle(color: colorScheme.error, fontSize: 16),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText.rich(
                TextSpan(
                  text: _error!,
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _selectedClassificationId == null ? _loadClassifications : () => _loadParticipantsByClassification(_selectedClassificationId!),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
              ),
            ],
          ),
        ),
      );
    }

    // Show classifications list if none selected
    if (_selectedClassificationId == null) {
      return _buildClassificationsList(l10n, colorScheme);
    }

    // Show participants list if classification selected
    return _buildParticipantsList(l10n, colorScheme);
  }

  Widget _buildClassificationsList(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_classifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category_outlined,
                size: 80,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.noClassificationsYet,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noClassificationsDesc,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _classifications.length,
        itemBuilder: (context, index) {
          final classification = _classifications[index];
          final ageGroups = classification['age_groups'] as Map<String, dynamic>?;
          final localeCode = Localizations.localeOf(context).languageCode;
          
          final rawBowType = (classification['bow_type'] ?? '').toString();
          final rawGender = (classification['gender'] ?? '').toString();
          final distance = classification['distance']?.toString() ?? '';
          final rawEnvironment = (classification['environment'] ?? '').toString();
          
          // Localize DB-stored English/TR values to current locale labels
          String mapBow(String v) {
            switch (v) {
              case 'Recurve':
              case 'Klasik Yay':
              case 'Klasik':
                return l10n.bowTypeRecurve;
              case 'Compound':
              case 'Makaralı Yay':
              case 'Makaralı':
                return l10n.bowTypeCompound;
              case 'Barebow':
                return l10n.bowTypeBarebow;
            }
            return v;
          }
          String mapEnv(String v) {
            switch (v) {
              case 'Indoor':
              case 'Salon':
                return l10n.environmentIndoor;
              case 'Outdoor':
              case 'Açık Hava':
                return l10n.environmentOutdoor;
            }
            return v;
          }
          String mapGender(String v) {
            switch (v) {
              case 'Male':
              case 'Erkek':
                return l10n.genderMale;
              case 'Female':
              case 'Kadın':
                return l10n.genderFemale;
              case 'Mixed':
              case 'Karma':
                return l10n.genderMixed;
            }
            return v;
          }
          
          final bowType = mapBow(rawBowType);
          final gender = mapGender(rawGender);
          final environment = mapEnv(rawEnvironment);
          final ageGroupName = ageGroups == null
              ? ''
              : (localeCode == 'tr' ? (ageGroups['age_group_tr'] ?? '') : (ageGroups['age_group_en'] ?? ''));
          
          // Generate localized classification name
          final parts = <String>[];
          if (ageGroupName.isNotEmpty) parts.add(ageGroupName);
          if (gender.isNotEmpty) parts.add(gender);
          if (bowType.isNotEmpty) parts.add(bowType);
          if (distance.isNotEmpty) parts.add('${distance}m');
          if (environment.isNotEmpty) parts.add(environment);
          final name = parts.join(' ');
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.category,
                  color: colorScheme.primary,
                ),
              ),
              title: Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                setState(() {
                  _selectedClassificationId = classification['id'].toString();
                  _selectedClassificationName = name;
                });
                // Cancel any previous periodic refresh before loading new classification
                _autoRefreshTimer?.cancel();
                _loadParticipantsByClassification(classification['id'].toString());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticipantsList(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: colorScheme.primary.withOpacity(0.6),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.participantsEmptyTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.participantsEmptyDesc,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadParticipantsByClassification(_selectedClassificationId!),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final participant = _participants[index];
          final profile = participant['profiles'] as Map<String, dynamic>?;
          final clubs = profile?['clubs'] as Map<String, dynamic>?;
          final qualifications = participant['qualifications'] as List<dynamic>?;
          
          final firstName = profile?['first_name'] ?? '';
          final lastName = profile?['last_name'] ?? '';
          final fullName = '$firstName $lastName'.trim();
          final clubName = clubs?['club_name'] ?? '';
          
          // Get qualification total score, default to 0 if null
          final qualificationData = qualifications?.isNotEmpty == true 
              ? qualifications!.first as Map<String, dynamic>?
              : null;
          final totalScore = qualificationData?['qualification_total_score'] as int? ?? 0;

          final String pid = (participant['participant_id'] as String?) ?? '';
          final int currentRank = index + 1;
          final int prevRank = _prevRankById[pid] ?? currentRank;
          final bool wasTop = prevRank <= 20;
          final bool isTop = currentRank <= 20;
          final bool shouldAnimate = (wasTop || isTop) && _activePulseIds.contains(pid);
          final bool movedUp = prevRank > currentRank; // smaller rank = moved up

          List<dynamic> _parseSets() {
            final qData = qualificationData;
            if (qData == null) return const [];
            final dynamic raw = qData['qualification_sets_data'];
            if (raw == null) return const [];
            if (raw is String) {
              try {
                return (jsonDecode(raw) as List).toList();
              } catch (_) {
                return const [];
              }
            }
            if (raw is List) return raw;
            return const [];
          }

          final bool expanded = _expandedParticipantIds.contains(pid);
          final List<dynamic> sets = expanded ? _parseSets() : const [];
          final cs = Theme.of(context).colorScheme;

          Widget tile = Card(
            margin: const EdgeInsets.only(bottom: 4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              dense: true,
              visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$currentRank',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              title: Text(
                fullName.isNotEmpty ? fullName : l10n.participantAthleteId,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.0),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: clubName.isNotEmpty
                  ? Text(
                      clubName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  : Text(
                      l10n.noClub,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                        height: 1.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(builder: (context) {
                    final sets = qualificationData?['qualification_sets_data'];
                    List<dynamic> rawList;
                    if (sets == null) {
                      rawList = const [];
                    } else if (sets is String) {
                      try {
                        rawList = (jsonDecode(sets) as List).toList();
                      } catch (_) {
                        rawList = const [];
                      }
                    } else if (sets is List) {
                      rawList = sets;
                    } else {
                      rawList = const [];
                    }

                    int arrowCount = 0;
                    int pointsSum = 0;
                    for (final item in rawList) {
                      if (item is List && item.length >= 2 && item[1] is List) {
                        final List<dynamic> arrows = List<dynamic>.from(item[1] as List);
                        for (final v in arrows) {
                          arrowCount++;
                          if (v is String) {
                            if (v == AppLocalizations.of(context)!.arrowXSymbol) {
                              pointsSum += 10;
                            } else if (v == AppLocalizations.of(context)!.arrowMissSymbol) {
                              pointsSum += 0;
                            } else {
                              pointsSum += int.tryParse(v) ?? 0;
                            }
                          } else {
                            pointsSum += (v as num?)?.toInt() ?? 0;
                          }
                        }
                      }
                    }

                    final double avg = arrowCount > 0 ? pointsSum / arrowCount : 0.0;
                    final textTheme = Theme.of(context).textTheme;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalScore',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${_formatTruncate3(avg)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.0,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(width: 6),
                  IconButton(
                    visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: () {
                      setState(() {
                        if (_expandedParticipantIds.contains(pid)) {
                          _expandedParticipantIds.remove(pid);
                        } else {
                          _expandedParticipantIds.add(pid);
                        }
                      });
                    },
                    icon: Icon(expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, size: 22),
                    tooltip: null,
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  if (_expandedParticipantIds.contains(pid)) {
                    _expandedParticipantIds.remove(pid);
                  } else {
                    _expandedParticipantIds.add(pid);
                  }
                });
              },
            ),
          );

          final Widget details = AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: expanded && sets.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 2),
                    child: Column(
                      children: () {
                        final List<Widget> roundChildren = [];
                        // Insert Round 1 header if there is at least one set
                        if (sets.isNotEmpty) {
                          roundChildren.add(_RoundSeparator(label: l10n.roundSeparator(1), color: cs.primary));
                        }
                        for (int i = 0; i < sets.length; i++) {
                          final item = sets[i];
                          int setNo = i + 1;
                          List<dynamic> rawArrows = const [];
                          if (item is List && item.length >= 2) {
                            if (item[0] is int) setNo = item[0] as int;
                            if (item[1] is List) rawArrows = List<dynamic>.from(item[1] as List);
                          }
                          final arrowsInt = rawArrows.map<int>((v) {
                            if (v is String) {
                              if (v == 'X') return 10;
                              if (v == 'M') return 0;
                              return int.tryParse(v) ?? 0;
                            }
                            return (v as num?)?.toInt() ?? 0;
                          }).toList();
                          final setTotal = arrowsInt.fold<int>(0, (s, a) => s + a);
                          final maxSetPoints = (arrowsInt.length) * 10;

                          roundChildren.add(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cs.outline.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '$setNo',
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: rawArrows.map<Widget>((v) {
                                          final l10n = AppLocalizations.of(context)!;
                                          final int score = v is String
                                              ? (v == l10n.arrowXSymbol ? 10 : (v == l10n.arrowMissSymbol ? 0 : int.tryParse(v) ?? 0))
                                              : ((v as num?)?.toInt() ?? 0);
                          final String label;
                          if (v is String) {
                            // If it's already a string (X, M, etc.), use it as is
                            label = v;
                          } else {
                            // For numeric values, always show the number (don't convert 10 to X)
                            label = score.toString();
                          }
                                          Color bg;
                                          Color fg;
                                          if (score >= 9) {
                                            bg = Colors.yellow;
                                            fg = Colors.black;
                                          } else if (score >= 7) {
                                            bg = Colors.red;
                                            fg = Colors.white;
                                          } else if (score >= 5) {
                                            bg = Colors.blue;
                                            fg = Colors.white;
                                          } else if (score >= 1) {
                                            bg = Colors.black;
                                            fg = Colors.white;
                                          } else {
                                            bg = Colors.grey;
                                            fg = Colors.white;
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: bg,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.black26),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  color: fg,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  height: 1.0,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${l10n.total}: $setTotal/$maxSetPoints',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          // Insert round separator after each round boundary, except after last item
                          final bool isBoundary = ((i + 1) % _setsPerRound == 0) && (i < sets.length - 1);
                          if (isBoundary) {
                            final nextRound = ((i + 1) / _setsPerRound).ceil() + 1;
                            roundChildren.add(_RoundSeparator(label: l10n.roundSeparator(nextRound), color: cs.primary));
                          }
                        }
                        return roundChildren;
                      }(),
                    ),
                  )
                : const SizedBox.shrink(),
          );

          // Per-item pulse animation on rank change (robust to reordering)
          final int pulseKey = _rankPulseCounter[pid] ?? 0;
          if (!shouldAnimate || pulseKey == 0) {
            return KeyedSubtree(
              key: ValueKey<String>('row_$pid'),
              child: Column(
                children: [
                  tile,
                  details,
                ],
              ),
            );
          }

          return TweenAnimationBuilder<double>(
            key: ValueKey<String>('pulse_${pid}_$pulseKey'),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubicEmphasized,
            builder: (context, t, child) {
              final double dy = movedUp ? -4.0 * (1 - t) : 4.0 * (1 - t); // small vertical nudge in px
              final double opacity = 0.7 + 0.3 * t;
              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                tile,
                details,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoundSeparator extends StatelessWidget {
  final String label;
  final Color color;
  const _RoundSeparator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color.withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    color.withOpacity(0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
