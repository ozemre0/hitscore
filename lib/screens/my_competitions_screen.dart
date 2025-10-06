import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.participantCompetitionsTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _ParticipantCompetitionsContent(),
            ),
          );
        },
      ),
    );
  }
}

class _ParticipantCompetitionsContent extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ParticipantCompetitionsContent> createState() => _ParticipantCompetitionsContentState();
}

class _ParticipantCompetitionsContentState extends ConsumerState<_ParticipantCompetitionsContent> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _participations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParticipations();
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
          _error = 'User not found';
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
        _participations = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
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
    );
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

    return RefreshIndicator(
      onRefresh: _loadParticipations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _participations.length,
        itemBuilder: (context, index) {
          final participation = _participations[index];
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
