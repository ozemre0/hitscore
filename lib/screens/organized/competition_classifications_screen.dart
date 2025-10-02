import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supabase_config.dart';

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
          
          return {
            ...classification,
            'ageGroup': ageGroupName,
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

  void _addClassification() {
    showDialog(
      context: context,
      builder: (context) => _ClassificationDialog(
        onSave: (classification) {
          setState(() => _classifications.add(classification));
        },
      ),
    );
  }

  void _editClassification(int index) {
    showDialog(
      context: context,
      builder: (context) => _ClassificationDialog(
        classification: _classifications[index],
        onSave: (classification) {
          setState(() => _classifications[index] = classification);
        },
      ),
    );
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
      // First, delete existing classifications for this competition
      await SupabaseConfig.client
          .from('organized_competitions_classifications')
          .delete()
          .eq('competition_id', widget.competitionId);
      
      // Then insert new classifications
      if (_classifications.isNotEmpty) {
        final classificationsData = _classifications.map((classification) => {
          'competition_id': widget.competitionId,
          'name': classification['name'],
          'age_group_id': classification['ageGroupId'],
          'bow_type': classification['bowType'],
          'environment': classification['environment'],
          'gender': classification['gender'],
          'distance': classification['distance'],
        }).toList();
        
        await SupabaseConfig.client
            .from('organized_competitions_classifications')
            .insert(classificationsData);
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

class _ClassificationDialog extends StatefulWidget {
  final Map<String, dynamic>? classification;
  final Function(Map<String, dynamic>) onSave;
  const _ClassificationDialog({this.classification, required this.onSave});

  @override
  State<_ClassificationDialog> createState() => _ClassificationDialogState();
}

class _ClassificationDialogState extends State<_ClassificationDialog> {
  final _nameController = TextEditingController();
  String? _selectedAgeGroup;
  String? _selectedBowType;
  String? _selectedEnvironment;
  String? _selectedGender;
  int? _selectedDistance;
  final _customDistanceController = TextEditingController();

  List<Map<String, dynamic>> _ageGroups = [];
  List<String> _bowTypes = [];
  List<String> _environments = [];
  List<String> _genders = [];
  final List<int> _distances = [18, 20, 30, 50, 60, 70];

  @override
  void initState() {
    super.initState();
    if (widget.classification != null) {
      _nameController.text = widget.classification!['name'] ?? '';
      _selectedAgeGroup = widget.classification!['age_group_id']?.toString();
      _selectedBowType = widget.classification!['bowType'];
      _selectedEnvironment = widget.classification!['environment'];
      _selectedGender = widget.classification!['gender'];
      _selectedDistance = widget.classification!['distance'];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeOptions();
  }

  Future<void> _initializeOptions() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Load age groups from database
    try {
      final response = await SupabaseConfig.client
          .from('age_groups')
          .select('age_group_id, age_group_tr, age_group_en')
          .order('age_group_id');
      
      setState(() {
        _ageGroups = List<Map<String, dynamic>>.from(response);
        _bowTypes = [
          l10n.bowTypeRecurve,
          l10n.bowTypeCompound,
          l10n.bowTypeBarebow,
        ];
        _environments = [
          l10n.environmentIndoor,
          l10n.environmentOutdoor,
        ];
        _genders = [
          l10n.genderMale,
          l10n.genderFemale,
          l10n.genderMixed,
        ];
      });
    } catch (e) {
      // Fallback to hardcoded values if database fails
      setState(() {
        _ageGroups = [
          {'age_group_id': 1, 'age_group_tr': '9 - 10', 'age_group_en': '9 - 10'},
          {'age_group_id': 2, 'age_group_tr': '11 - 12', 'age_group_en': '11 - 12'},
          {'age_group_id': 3, 'age_group_tr': '13 - 14', 'age_group_en': '13 - 14'},
          {'age_group_id': 4, 'age_group_tr': 'U18 (15-16-17)', 'age_group_en': 'U18 (15-16-17)'},
          {'age_group_id': 5, 'age_group_tr': 'U21 (18-19-20)', 'age_group_en': 'U21 (18-19-20)'},
          {'age_group_id': 6, 'age_group_tr': 'Büyükler', 'age_group_en': 'Senior'},
        ];
        _bowTypes = [
          l10n.bowTypeRecurve,
          l10n.bowTypeCompound,
          l10n.bowTypeBarebow,
        ];
        _environments = [
          l10n.environmentIndoor,
          l10n.environmentOutdoor,
        ];
        _genders = [
          l10n.genderMale,
          l10n.genderFemale,
          l10n.genderMixed,
        ];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customDistanceController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty ||
        _selectedAgeGroup == null ||
        _selectedBowType == null ||
        _selectedEnvironment == null ||
        _selectedGender == null ||
        (_selectedDistance == null && _customDistanceController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }
    final distance = _selectedDistance ?? int.tryParse(_customDistanceController.text.trim());
    if (distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterValidDistance)));
      return;
    }
    // Find the selected age group data
    final selectedAgeGroup = _ageGroups.firstWhere(
      (age) => age['age_group_id'].toString() == _selectedAgeGroup!,
    );
    
    widget.onSave({
      'name': _nameController.text.trim(),
      'ageGroup': selectedAgeGroup['age_group_tr'], // Store Turkish name for display
      'ageGroupId': selectedAgeGroup['age_group_id'], // Store ID for database
      'bowType': _selectedBowType!,
      'environment': _selectedEnvironment!,
      'gender': _selectedGender!,
      'distance': distance,
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.classification == null ? l10n.addClassificationTitle : l10n.editClassificationTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.classificationNameLabel,
              border: const OutlineInputBorder(),
              hintText: '${l10n.ageGroupSenior} ${l10n.male} ${l10n.bowTypeRecurve} 70m',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedAgeGroup,
            decoration: InputDecoration(labelText: l10n.ageGroupLabel, border: const OutlineInputBorder()),
            items: _ageGroups.map((age) {
              final displayText = Localizations.localeOf(context).languageCode == 'tr' 
                  ? age['age_group_tr'] 
                  : age['age_group_en'];
              return DropdownMenuItem(
                value: age['age_group_id'].toString(),
                child: Text(displayText),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedAgeGroup = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBowType,
            decoration: InputDecoration(labelText: l10n.bowTypeLabel, border: const OutlineInputBorder()),
            items: _bowTypes.map((bow) => DropdownMenuItem(value: bow, child: Text(bow))).toList(),
            onChanged: (value) => setState(() => _selectedBowType = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedEnvironment,
            decoration: InputDecoration(labelText: l10n.environmentLabel, border: const OutlineInputBorder()),
            items: _environments.map((env) => DropdownMenuItem(value: env, child: Text(env))).toList(),
            onChanged: (value) => setState(() => _selectedEnvironment = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(labelText: l10n.genderLabel, border: const OutlineInputBorder()),
            items: _genders.map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _selectedDistance,
            decoration: InputDecoration(labelText: l10n.distanceMetersLabel, border: const OutlineInputBorder()),
            items: [
              ..._distances.map((d) => DropdownMenuItem(value: d, child: Text('${d}m'))),
              DropdownMenuItem(value: -1, child: Text(l10n.customDistance)),
            ],
            onChanged: (value) => setState(() => _selectedDistance = value == -1 ? null : value),
          ),
          if (_selectedDistance == null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customDistanceController,
              decoration: InputDecoration(
                labelText: l10n.customDistanceMeters,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        ElevatedButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}


