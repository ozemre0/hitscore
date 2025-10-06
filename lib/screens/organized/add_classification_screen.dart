import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supabase_config.dart';

class AddClassificationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialClassification;
  const AddClassificationScreen({super.key, this.initialClassification});

  @override
  State<AddClassificationScreen> createState() => _AddClassificationScreenState();
}

class _AddClassificationScreenState extends State<AddClassificationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customDistanceController = TextEditingController();
  final TextEditingController _roundCountController = TextEditingController();
  final TextEditingController _arrowsPerSetController = TextEditingController();
  final TextEditingController _setsPerRoundController = TextEditingController();

  List<Map<String, dynamic>> _ageGroups = [];
  List<String> _bowTypes = [];
  List<String> _environments = [];
  List<String> _genders = [];
  final List<int> _distances = const [18, 20, 30, 50, 60, 70];
  final List<String> _scoreButtons = const ['X', '10', '9', '8', '7', '6', '5', '4', '3', '2', '1', 'M'];

  String? _selectedAgeGroup;
  String? _selectedBowType;
  String? _selectedEnvironment;
  String? _selectedGender;
  int? _selectedDistance;
  Set<String> _selectedScoreButtons = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initialClassification;
    if (init != null) {
      _nameController.text = init['name'] ?? '';
      _selectedAgeGroup = (init['ageGroupId'] ?? init['age_group_id'])?.toString();
      _selectedBowType = init['bowType'] ?? init['bow_type'];
      _selectedEnvironment = init['environment'];
      _selectedGender = init['gender'];
      _selectedDistance = init['distance'];
      if (_selectedDistance == null) {
        _customDistanceController.text = (init['distance'] ?? '').toString();
      }
      _roundCountController.text = (init['round_count'] ?? '').toString();
      _arrowsPerSetController.text = (init['arrow_per_set'] ?? '').toString();
      _setsPerRoundController.text = (init['set_per_round'] ?? '').toString();
      
      // Initialize score buttons from existing data
      if (init['available_score_buttons'] != null) {
        final scoreButtonsStr = init['available_score_buttons'] as String;
        print('DEBUG: Loading existing score buttons: $scoreButtonsStr');
        if (scoreButtonsStr.isNotEmpty) {
          // Parse the score buttons string like "[X,10,9,8,7,6,5,4,3,2,1,M]"
          final cleanStr = scoreButtonsStr.replaceAll('[', '').replaceAll(']', '');
          final buttons = cleanStr.split(',').map((e) => e.trim()).toList();
          _selectedScoreButtons = buttons.toSet();
          print('DEBUG: Parsed score buttons: $_selectedScoreButtons');
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeOptions();
  }

  Future<void> _initializeOptions() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client
          .from('age_groups')
          .select('age_group_id, age_group_tr, age_group_en')
          .order('age_group_id');
      _ageGroups = List<Map<String, dynamic>>.from(response);
    } catch (_) {
      _ageGroups = [
        {'age_group_id': 1, 'age_group_tr': '9 - 10', 'age_group_en': '9 - 10'},
        {'age_group_id': 2, 'age_group_tr': '11 - 12', 'age_group_en': '11 - 12'},
        {'age_group_id': 3, 'age_group_tr': '13 - 14', 'age_group_en': '13 - 14'},
        {'age_group_id': 4, 'age_group_tr': 'U18 (15-16-17)', 'age_group_en': 'U18 (15-16-17)'},
        {'age_group_id': 5, 'age_group_tr': 'U21 (18-19-20)', 'age_group_en': 'U21 (18-19-20)'},
        {'age_group_id': 6, 'age_group_tr': 'Büyükler', 'age_group_en': 'Senior'},
      ];
    } finally {
      _bowTypes = [l10n.bowTypeRecurve, l10n.bowTypeCompound, l10n.bowTypeBarebow];
      _environments = [l10n.environmentIndoor, l10n.environmentOutdoor];
      _genders = [l10n.genderMale, l10n.genderFemale, l10n.genderMixed];
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customDistanceController.dispose();
    _roundCountController.dispose();
    _arrowsPerSetController.dispose();
    _setsPerRoundController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty ||
        _selectedAgeGroup == null ||
        _selectedBowType == null ||
        _selectedEnvironment == null ||
        _selectedGender == null ||
        (_selectedDistance == null && _customDistanceController.text.trim().isEmpty) ||
        _roundCountController.text.trim().isEmpty ||
        _arrowsPerSetController.text.trim().isEmpty ||
        _setsPerRoundController.text.trim().isEmpty ||
        _selectedScoreButtons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFields)));
      return;
    }

    final distance = _selectedDistance ?? int.tryParse(_customDistanceController.text.trim());
    if (distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterValidDistance)));
      return;
    }

    final roundCount = int.tryParse(_roundCountController.text.trim());
    final arrowsPerSet = int.tryParse(_arrowsPerSetController.text.trim());
    final setsPerRound = int.tryParse(_setsPerRoundController.text.trim());
    if (roundCount == null || arrowsPerSet == null || setsPerRound == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.enterValidDistance)));
      return;
    }

    final selectedAgeGroup = _ageGroups.firstWhere((age) => age['age_group_id'].toString() == _selectedAgeGroup!);

    // Format score buttons as string array
    print('DEBUG: Selected score buttons: $_selectedScoreButtons');
    final scoreButtonsList = _selectedScoreButtons.toList()..sort((a, b) {
      // Custom sort: X first, then numbers (10, 9, 8...), then M last
      if (a == 'X') return -1;
      if (b == 'X') return 1;
      if (a == 'M') return 1;
      if (b == 'M') return -1;
      return int.tryParse(b)?.compareTo(int.tryParse(a) ?? 0) ?? 0;
    });
    final scoreButtonsString = '[${scoreButtonsList.join(',')}]';
    print('DEBUG: Formatted score buttons string: $scoreButtonsString');

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'ageGroup': Localizations.localeOf(context).languageCode == 'tr' ? selectedAgeGroup['age_group_tr'] : selectedAgeGroup['age_group_en'],
      'ageGroupId': selectedAgeGroup['age_group_id'],
      'bowType': _selectedBowType!,
      'environment': _selectedEnvironment!,
      'gender': _selectedGender!,
      'distance': distance,
      'round_count': roundCount,
      'arrow_per_set': arrowsPerSet,
      'set_per_round': setsPerRound,
      'available_score_buttons': scoreButtonsString,
    });
    print('DEBUG: Classification data saved with score buttons: $scoreButtonsString');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialClassification == null ? l10n.addClassificationTitle : l10n.editClassificationTitle),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                children: [
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
                      final displayText = Localizations.localeOf(context).languageCode == 'tr' ? age['age_group_tr'] : age['age_group_en'];
                      return DropdownMenuItem(value: age['age_group_id'].toString(), child: Text(displayText));
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
                    items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
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
                      decoration: InputDecoration(labelText: l10n.customDistanceMeters, border: const OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _roundCountController,
                    decoration: InputDecoration(labelText: l10n.roundCountLabel, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _arrowsPerSetController,
                    decoration: InputDecoration(labelText: l10n.arrowsPerSetLabel, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _setsPerRoundController,
                    decoration: InputDecoration(labelText: l10n.setsPerRoundLabel, border: const OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  // Score Buttons Selection
                  Text(
                    l10n.availableScoreButtonsLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.availableScoreButtonsDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scoreButtons.map((button) {
                      final isSelected = _selectedScoreButtons.contains(button);
                      return FilterChip(
                        label: Text(button),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedScoreButtons.add(button);
                              print('DEBUG: Score button added: $button. Current selection: $_selectedScoreButtons');
                            } else {
                              _selectedScoreButtons.remove(button);
                              print('DEBUG: Score button removed: $button. Current selection: $_selectedScoreButtons');
                            }
                          });
                        },
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        label: Text(l10n.save),
                        style: ElevatedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}


