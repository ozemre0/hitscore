import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'athlete_multi_select_sheet.dart';
// import 'competition_classifications_screen.dart';
import '../../services/supabase_config.dart';
import '../elimination/elimination_settings_screen.dart';

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
            user_id,
            organized_competition_id,
            status,
            visible_id,
            first_name,
            last_name,
            created_at,
            participant_role,
            profiles:user_id (
              visible_id,
              first_name,
              last_name
            ),
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

      // Ensure visible_id/first_name/last_name are populated from embedded profiles when missing
      final loaded = List<Map<String, dynamic>>.from(response);
      for (final p in loaded) {
        final Map<String, dynamic>? prof = p['profiles'] as Map<String, dynamic>?;
        if (prof == null) continue;
        if (((p['visible_id'] as String?) ?? '').trim().isEmpty) {
          p['visible_id'] = prof['visible_id'] ?? p['visible_id'];
        }
        final bool hasName = (((p['first_name'] as String?) ?? '').trim().isNotEmpty) || (((p['last_name'] as String?) ?? '').trim().isNotEmpty);
        if (!hasName) {
          p['first_name'] = prof['first_name'] ?? p['first_name'];
          p['last_name'] = prof['last_name'] ?? p['last_name'];
        }
      }

      setState(() {
        _participants = loaded;
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

      // If status is changed to 'accepted', add participant to organized_qualifications table
      if (newStatus == 'accepted') {
        await _addParticipantToQualifications(participantId);
      }

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

  Future<void> _addParticipantToQualifications(String participantId) async {
    try {
      // Check if participant already exists in qualifications table
      final existing = await SupabaseConfig.client
          .from('organized_qualifications')
          .select('participant_id')
          .eq('participant_id', participantId)
          .maybeSingle();
      
      if (existing != null) {
        print('Participant $participantId already exists in organized_qualifications table');
        return;
      }
      
      final now = DateTime.now().toIso8601String();
      
      // Insert into organized_qualifications table with only participant_id and timestamps
      await SupabaseConfig.client.from('organized_qualifications').insert({
        'participant_id': participantId,
        'created_at': now,
        'updated_at': now,
      });
      
      // Log successful addition for debugging
      print('Successfully added participant $participantId to organized_qualifications table');
    } catch (e) {
      // Log error but don't show to user as this is a background operation
      print('Error adding participant $participantId to qualifications: $e');
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
            onPressed: _navigateToElimination,
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Eleme Sistemi',
          ),
          IconButton(
            onPressed: () async {
              // Open full-screen selector page instead of bottom sheet
              final result = await Navigator.of(context).push<UserMultiSelectResult>(
                MaterialPageRoute(
                  builder: (_) => UserMultiSelectSheet(competitionId: widget.competitionId),
                  fullscreenDialog: true,
                ),
              );
              if (result == null || result.userIds.isEmpty) return;

              // Pick classification for bulk add
              final classificationId = await _pickClassification(widget.competitionId);
              if (classificationId == null) return;

              await _bulkAddUsers(result.userIds, classificationId);
            },
            icon: const Icon(Icons.person_add),
            tooltip: l10n.addAthletes,
          ),
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

  Future<String?> _pickClassification(String competitionId) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final rows = await SupabaseConfig.client
          .from('organized_competitions_classifications')
          .select('id, name, age_groups:age_groups(age_group_tr, age_group_en), bow_type, gender, distance, environment')
          .eq('competition_id', competitionId)
          .order('created_at');
      if (!mounted) return null;
      final items = List<Map<String, dynamic>>.from(rows);
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noClassificationsAvailable)));
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
      }
      return null;
    }
  }

  Future<void> _bulkAddUsers(List<String> userIds, String classificationId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final now = DateTime.now().toIso8601String();
      // Fetch profile info for the selected users to persist visible data
      // This ensures the list shows visible_id instead of raw UUIDs after insert
      final String inList = '(${userIds.join(',')})';
      final List<dynamic> profileRows = await SupabaseConfig.client
          .from('profiles')
          .select('id, visible_id, first_name, last_name, role')
          .filter('id', 'in', inList);

      final Map<String, Map<String, dynamic>> profileById = {
        for (final row in profileRows)
          if (row is Map<String, dynamic> && (row['id'] as String?) != null)
            (row['id'] as String): row,
      };

      final rows = userIds.map((userId) {
        final Map<String, dynamic>? p = profileById[userId];
        return {
          'organized_competition_id': widget.competitionId,
          'classification_id': classificationId,
          'user_id': userId,
          'participant_role': p != null ? (p['role'] ?? 'athlete') : 'athlete',
          'visible_id': p != null ? (p['visible_id'] ?? '') : '',
          'first_name': p != null ? (p['first_name'] ?? '') : '',
          'last_name': p != null ? (p['last_name'] ?? '') : '',
          'status': 'pending',
          'created_at': now,
        };
      });
      await SupabaseConfig.client.from('organized_competition_participants').insert(rows.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.addedSuccessfully)));
      await _loadParticipants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.operationFailed}: $e')));
    }
  }

  Future<void> _navigateToElimination() async {
    // Şimdilik basit bir placeholder - gerçek implementasyonda yarışma adını alacak
    final competitionName = 'Yarışma'; // TODO: Gerçek yarışma adını al
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EliminationSettingsScreen(
          competitionId: widget.competitionId,
          competitionName: competitionName,
        ),
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
      child: Column(
        children: [
          // Eleme Sistemi Kartı
          Container(
            margin: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1.2),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _navigateToElimination,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(Icons.emoji_events, color: colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eleme Sistemi',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Eleme ayarlarını yapılandır ve bracket oluştur',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Katılımcı Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              itemCount: _participants.length,
        itemBuilder: (context, index) {
          final p = _participants[index];
          final classification = p['classification'] as Map<String, dynamic>?;
          final status = p['status'] as String? ?? 'unknown';
          final isPending = status == 'pending';
          final isAccepted = status == 'accepted';
          final isCancelled = status == 'cancelled';
          final visibleId = p['visible_id'] as String? ?? p['user_id'] as String? ?? '-';
          final firstName = p['first_name'] as String? ?? '';
          final lastName = p['last_name'] as String? ?? '';
          final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outline.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 2.0, 10.0, 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator with change status button
                  Row(
                    children: [
                      if (isPending || isAccepted || isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                size: 14,
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
                      const Spacer(),
                      if (isAccepted || isCancelled)
                        OutlinedButton.icon(
                          onPressed: () => _showChangeStatusDialog(
                            p['participant_id'] as String,
                            fullName.isNotEmpty ? fullName : visibleId,
                            status,
                          ),
                          icon: const Icon(Icons.edit, size: 14),
                          label: Text(
                            l10n.changeStatus,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                  // Participant name
                  if (fullName.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: colorScheme.primary),
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
                  const SizedBox(height: 2),
                  // Classification name and Athlete ID in same row
                  Row(
                    children: [
                      if (classification != null && (classification['name'] ?? '').toString().isNotEmpty) ...[
                        Icon(Icons.category, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l10n.participantClassification}: ${classification['name']}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.badge, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l10n.participantAthleteId}: $visibleId',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Athlete ID (if classification exists)
                  if (classification != null && (classification['name'] ?? '').toString().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${l10n.participantAthleteId}: $visibleId',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  // Action buttons for pending
                  if (isPending) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showRejectDialog(
                              p['participant_id'] as String,
                              fullName.isNotEmpty ? fullName : visibleId,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              l10n.rejectRequest,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showAcceptDialog(
                              p['participant_id'] as String,
                              fullName.isNotEmpty ? fullName : visibleId,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(color: colorScheme.primary),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                            child: Text(
                              l10n.acceptRequest,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }
}


