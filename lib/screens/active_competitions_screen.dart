import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ActiveCompetitionsScreen extends StatefulWidget {
  const ActiveCompetitionsScreen({super.key});

  @override
  State<ActiveCompetitionsScreen> createState() => _ActiveCompetitionsScreenState();
}

class _ActiveCompetitionsScreenState extends State<ActiveCompetitionsScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _competitions = [];
  final Set<String> _pendingCompetitionIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final nowIso = DateTime.now().toIso8601String();
      final response = await SupabaseConfig.client
          .from('organized_competitions')
          .select()
          .eq('is_deleted', false)
          .eq('status', 'active')
          .lte('registration_start_date', nowIso)
          .gte('registration_end_date', nowIso)
          .order('start_date');

      final competitions = List<Map<String, dynamic>>.from(response);
      setState(() {
        _competitions = competitions;
      });
      await _loadUserPendingStatuses(competitions);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          .select('organized_competition_id')
          .eq('athlete_id', user.id)
          .eq('status', 'pending');
      final fetchedPending = rows.map<String>((r) => r['organized_competition_id'] as String).toSet();
      final pendingIds = fetchedPending.intersection(visibleIds);
      setState(() {
        _pendingCompetitionIds
          ..clear()
          ..addAll(pendingIds);
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

      // 2) Insert pending request with classification
      final participantId = const Uuid().v4();
      await SupabaseConfig.client.from('organized_competition_participants').insert({
        'participant_id': participantId,
        'organized_competition_id': competition['organized_competition_id'],
        'classification_id': classificationId,
        'athlete_id': user.id,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _pendingCompetitionIds.add(competition['organized_competition_id'] as String);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSent)));
      }
    } on PostgrestException catch (e) {
      final l10n = AppLocalizations.of(context)!;
      final isDuplicate = e.code == '23505';
      final isForeignKeyError = e.code == '23503' && e.message.contains('athlete_id_fkey');
      
      if (isDuplicate) {
        setState(() {
          _pendingCompetitionIds.add(competition['organized_competition_id'] as String);
        });
      }
      
      String message;
      if (isDuplicate) {
        message = l10n.requestSent;
      } else if (isForeignKeyError) {
        message = l10n.athleteProfileRequired;
      } else {
        message = '${l10n.competitionJoinError}: ${e.message ?? e.details ?? e.code}';
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        'athlete_id': user.id,
        'status': 'pending',
      });
      if (mounted) {
        setState(() {
          _pendingCompetitionIds.remove(competition['organized_competition_id'] as String);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestCancelled)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
      }
    }
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

    return RefreshIndicator(
      onRefresh: _loadCompetitions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _competitions.length,
        itemBuilder: (context, index) {
          final c = _competitions[index];
          final isRegistrationWindow = c['registration_start_date'] != null && c['registration_end_date'] != null;
          final now = DateTime.now();
          bool canRegister = false;
          if (isRegistrationWindow) {
            try {
              final rs = DateTime.parse(c['registration_start_date']);
              final re = DateTime.parse(c['registration_end_date']);
              canRegister = now.isAfter(rs) && now.isBefore(re);
            } catch (_) {}
          }
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
                if (isRegistrationWindow) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.play_arrow, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${l10n.registrationStartLabel}: ${_formatDate(c['registration_start_date'])}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.stop, size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${l10n.registrationEndLabel}: ${_formatDate(c['registration_end_date'])}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ]),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _pendingCompetitionIds.contains(c['organized_competition_id'])
                      ? OutlinedButton.icon(
                          onPressed: () => _cancelRequest(c),
                          icon: const Icon(Icons.close),
                          label: Text(l10n.cancelRequest),
                        )
                      : OutlinedButton.icon(
                          onPressed: canRegister ? () => _joinCompetition(c) : null,
                          icon: const Icon(Icons.how_to_reg),
                          label: Text(l10n.competitionJoin),
                        ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}


