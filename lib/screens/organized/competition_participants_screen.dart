import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supabase_config.dart';

class CompetitionParticipantsScreen extends StatefulWidget {
  final String competitionId;

  const CompetitionParticipantsScreen({super.key, required this.competitionId});

  @override
  State<CompetitionParticipantsScreen> createState() => _CompetitionParticipantsScreenState();
}

class _CompetitionParticipantsScreenState extends State<CompetitionParticipantsScreen> {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await SupabaseConfig.client
          .from('organized_competition_participants')
          .select('''
            participant_id,
            athlete_id,
            organized_competition_id,
            status,
            visible_id,
            first_name,
            last_name,
            created_at,
            classification:organized_competitions_classifications!inner(
              id,
              name,
              bow_type,
              environment,
              gender,
              age_group_id,
              age_groups:age_groups(age_group_tr, age_group_en)
            )
          ''')
          .eq('organized_competition_id', widget.competitionId)
          .order('created_at', ascending: false);

      setState(() {
        _participants = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateParticipantStatus(String participantId, String newStatus) async {
    try {
      await SupabaseConfig.client
          .from('organized_competition_participants')
          .update({'status': newStatus})
          .eq('participant_id', participantId);

      // Update local state
      setState(() {
        final index = _participants.indexWhere((p) => p['participant_id'] == participantId);
        if (index != -1) {
          _participants[index]['status'] = newStatus;
        }
      });

      final l10n = AppLocalizations.of(context)!;
      final message = newStatus == 'accepted' ? l10n.requestAccepted : l10n.requestRejected;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showAcceptDialog(String participantId, String participantName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.acceptRequest),
        content: Text(l10n.acceptRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.acceptRequest),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateParticipantStatus(participantId, 'accepted');
    }
  }

  Future<void> _showRejectDialog(String participantId, String participantName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectRequest),
        content: Text(l10n.rejectRequestConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.rejectRequest),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateParticipantStatus(participantId, 'cancelled');
    }
  }

  Future<void> _showChangeStatusDialog(String participantId, String participantName, String currentStatus) async {
    final l10n = AppLocalizations.of(context)!;
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$participantName - ${l10n.changeStatus}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('accepted'),
                icon: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary),
                label: Text(l10n.acceptedStatus),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.tertiary,
                  side: BorderSide(color: Theme.of(context).colorScheme.tertiary),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('cancelled'),
                icon: Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
                label: Text(l10n.cancelledStatus),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('pending'),
                icon: Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                label: Text(l10n.pendingStatus),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      await _updateParticipantStatus(participantId, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.participantsTitle),
        actions: [
          IconButton(
            onPressed: _loadParticipants,
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
              child: _buildBody(l10n, Theme.of(context).colorScheme),
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
                onPressed: _loadParticipants,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
              ),
            ],
          ),
        ),
      );
    }

    if (_participants.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_outlined, size: 80, color: colorScheme.primary.withOpacity(0.6)),
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
      onRefresh: _loadParticipants,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final p = _participants[index];
          final classification = p['classification'] as Map<String, dynamic>?;
          final ageGroups = classification != null ? classification['age_groups'] as Map<String, dynamic>? : null;
          final localeCode = Localizations.localeOf(context).languageCode;
          final ageGroupText = ageGroups == null
              ? (classification != null ? (classification['age_group_id']?.toString() ?? '-') : '-')
              : (localeCode == 'tr' ? (ageGroups['age_group_tr'] ?? '-') : (ageGroups['age_group_en'] ?? '-'));
          final status = p['status'] as String? ?? 'unknown';
          final isPending = status == 'pending';
          final isAccepted = status == 'accepted';
          final isCancelled = status == 'cancelled';
          final visibleId = p['visible_id'] as String? ?? p['athlete_id'] as String? ?? '-';
          final firstName = p['first_name'] as String? ?? '';
          final lastName = p['last_name'] as String? ?? '';
          final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator
                  if (isPending || isAccepted || isCancelled)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPending 
                            ? colorScheme.primaryContainer
                            : isAccepted 
                                ? colorScheme.tertiaryContainer
                                : colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPending 
                              ? colorScheme.primary.withOpacity(0.3)
                              : isAccepted 
                                  ? colorScheme.tertiary.withOpacity(0.3)
                                  : colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPending 
                                ? Icons.schedule
                                : isAccepted 
                                    ? Icons.check_circle
                                    : Icons.cancel,
                            size: 16,
                            color: isPending 
                                ? colorScheme.primary
                                : isAccepted 
                                    ? colorScheme.tertiary
                                    : colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPending 
                                ? l10n.pendingStatus
                                : isAccepted 
                                    ? l10n.acceptedStatus
                                    : l10n.cancelledStatus,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isPending 
                                  ? colorScheme.primary
                                  : isAccepted 
                                      ? colorScheme.tertiary
                                      : colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Participant name
                  if (fullName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (fullName.isNotEmpty) const SizedBox(height: 4),
                  // Athlete ID
                  Row(
                    children: [
                      Icon(Icons.badge, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.participantAthleteId}: $visibleId',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.participantGender}: ${classification != null ? (classification['gender'] ?? '-') : '-'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.cake, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.participantAgeGroup}: $ageGroupText',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.architecture, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.participantEquipment}: ${classification != null ? (classification['bow_type'] ?? '-') : '-'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Action buttons
                  if (isPending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showRejectDialog(
                              p['participant_id'] as String,
                              fullName.isNotEmpty ? fullName : visibleId,
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(l10n.rejectRequest),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAcceptDialog(
                              p['participant_id'] as String,
                              fullName.isNotEmpty ? fullName : visibleId,
                            ),
                            icon: const Icon(Icons.check, size: 18),
                            label: Text(l10n.acceptRequest),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isAccepted || isCancelled) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showChangeStatusDialog(
                          p['participant_id'] as String,
                          fullName.isNotEmpty ? fullName : visibleId,
                          status,
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(l10n.changeStatus),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


