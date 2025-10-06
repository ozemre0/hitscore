import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supabase_config.dart';
import 'add_classification_screen.dart';

class CompetitionClassificationsScreen extends StatefulWidget {
  final String competitionId;
  final bool isEditMode;
  const CompetitionClassificationsScreen({super.key, required this.competitionId, this.isEditMode = false});

  @override
  State<CompetitionClassificationsScreen> createState() => _CompetitionClassificationsScreenState();
}

class _CompetitionClassificationsScreenState extends State<CompetitionClassificationsScreen> {
  List<Map<String, dynamic>> _classifications = [];
  bool _isLoading = false;
  Map<String, dynamic>? _competitionData;

  @override
  void initState() {
    super.initState();
    _loadCompetitionData();
    if (widget.isEditMode) {
      _loadClassifications();
    }
  }

  Future<void> _loadCompetitionData() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client
          .from('organized_competitions')
          .select()
          .eq('is_deleted', false)
          .eq('organized_competition_id', widget.competitionId)
          .single();
      setState(() => _competitionData = response);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.competitionLoadError}: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadClassifications() async {
    try {
      final response = await SupabaseConfig.client
          .from('organized_competitions_classifications')
          .select('''
            *,
            age_groups!inner(age_group_tr, age_group_en)
          ''')
          .eq('competition_id', widget.competitionId)
          .order('created_at');
      
      setState(() {
        _classifications = List<Map<String, dynamic>>.from(response).map((classification) {
          // Add the age group name based on current locale
          final ageGroupData = classification['age_groups'];
          final ageGroupName = ageGroupData != null 
              ? (Localizations.localeOf(context).languageCode == 'tr' 
                  ? ageGroupData['age_group_tr'] 
                  : ageGroupData['age_group_en'])
              : 'Unknown';

          // Normalize keys to camelCase used by UI and save logic
          return {
            ...classification,
            'ageGroup': ageGroupName,
            'ageGroupId': classification['age_group_id'],
            'bowType': classification['bow_type'],
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.competitionLoadError}: $e')),
        );
      }
    }
  }

  Future<void> _addClassification() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(
      builder: (context) => const AddClassificationScreen(),
    ));
    if (result != null) {
      setState(() => _classifications.add(result));
    }
  }

  Future<void> _editClassification(int index) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(MaterialPageRoute(
      builder: (context) => AddClassificationScreen(initialClassification: _classifications[index]),
    ));
    if (result != null) {
      setState(() => _classifications[index] = result);
    }
  }

  void _deleteClassification(int index) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.classificationDeleteTitle),
        content: Text(l10n.classificationDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              setState(() => _classifications.removeAt(index));
              Navigator.of(context).pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _saveClassifications() async {
    final l10n = AppLocalizations.of(context)!;
    if (_classifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.classificationAtLeastOneRequired)));
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Get existing classifications to compare
      final existingClassifications = await SupabaseConfig.client
          .from('organized_competitions_classifications')
          .select('id, name, age_group_id, bow_type, environment, gender, distance, round_count, arrow_per_set, set_per_round, available_score_buttons')
          .eq('competition_id', widget.competitionId);
      
      print('DEBUG: Existing classifications: ${existingClassifications.length}');
      
      // Process each classification
      for (final classification in _classifications) {
        final classificationData = {
          'competition_id': widget.competitionId,
          'name': classification['name'],
          'age_group_id': classification['ageGroupId'],
          'bow_type': classification['bowType'],
          'environment': classification['environment'],
          'gender': classification['gender'],
          'distance': classification['distance'],
          'round_count': classification['round_count'],
          'arrow_per_set': classification['arrow_per_set'],
          'set_per_round': classification['set_per_round'],
          'available_score_buttons': classification['available_score_buttons'],
        };
        
        print('DEBUG: Processing classification: ${classificationData['name']}');
        
        // Check if this classification already exists (by name and competition)
        final existing = existingClassifications.firstWhere(
          (existing) => existing['name'] == classification['name'],
          orElse: () => <String, dynamic>{},
        );
        
        if (existing.isNotEmpty) {
          // Update existing classification
          print('DEBUG: Updating existing classification: ${existing['id']}');
          await SupabaseConfig.client
              .from('organized_competitions_classifications')
              .update(classificationData)
              .eq('id', existing['id']);
        } else {
          // Insert new classification
          print('DEBUG: Inserting new classification');
          await SupabaseConfig.client
              .from('organized_competitions_classifications')
              .insert(classificationData);
        }
      }
      
      // Remove classifications that are no longer in the list
      final currentNames = _classifications.map((c) => c['name']).toList();
      final toDelete = existingClassifications.where(
        (existing) => !currentNames.contains(existing['name'])
      ).toList();
      
      if (toDelete.isNotEmpty) {
        print('DEBUG: Removing ${toDelete.length} classifications that are no longer needed');
        for (final classification in toDelete) {
          // Check if this classification has participants
          final participants = await SupabaseConfig.client
              .from('organized_competition_participants')
              .select('participant_id')
              .eq('classification_id', classification['id'])
              .limit(1);
          
          if (participants.isEmpty) {
            // Safe to delete - no participants
            await SupabaseConfig.client
                .from('organized_competitions_classifications')
                .delete()
                .eq('id', classification['id']);
            print('DEBUG: Deleted classification: ${classification['name']}');
          } else {
            print('DEBUG: Cannot delete classification ${classification['name']} - has participants');
          }
        }
      }
      
      if (widget.isEditMode) {
        // In edit mode, just update the timestamp
        await SupabaseConfig.client
            .from('organized_competitions')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('organized_competition_id', widget.competitionId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.competitionUpdateSuccess)));
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // In create mode, activate the competition
        await SupabaseConfig.client
            .from('organized_competitions')
            .update({'status': 'active', 'updated_at': DateTime.now().toIso8601String()})
            .eq('organized_competition_id', widget.competitionId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.competitionCreatedSuccess)));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.classifications), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_competitionData != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.emoji_events, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _competitionData!['name'] ?? 'İsimsiz Yarışma',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ]),
                        if (_competitionData!['description'] != null) ...[
                          const SizedBox(height: 8),
                          Text(_competitionData!['description'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 8),
                        Text('${l10n.competitionDateLabel}: ${_formatDate(_competitionData!['start_date'])}', style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(l10n.classifications, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(onPressed: _addClassification, icon: const Icon(Icons.add), label: Text(l10n.addClassification)),
                ]),
                const SizedBox(height: 16),
                if (_classifications.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(children: [
                          Icon(Icons.category_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(l10n.noClassificationsYet, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(l10n.noClassificationsDesc, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                  )
                else
                  ...List.generate(_classifications.length, (index) {
                    final classification = _classifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(classification['name']),
                        subtitle: Text('${classification['ageGroup']} • ${classification['bowType']} • ${classification['gender']} • ${classification['distance']}m • ${classification['environment']}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(onPressed: () => _editClassification(index), icon: const Icon(Icons.edit)),
                          IconButton(onPressed: () => _deleteClassification(index), icon: const Icon(Icons.delete), color: Colors.red),
                        ]),
                      ),
                    );
                  }),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.back))),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveClassifications,
                      icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check),
                      label: Text(_isLoading ? l10n.savingGeneric : l10n.completeCompetition),
                    ),
                  ),
                ]),
              ]),
            ),
    );
  }

  String _formatDate(String? dateStr) {
    final l10n = AppLocalizations.of(context)!;
    if (dateStr == null) return l10n.competitionDateNotProvided;
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return l10n.competitionInvalidDate;
    }
  }
}

// Dialog removed in favor of full-screen page


