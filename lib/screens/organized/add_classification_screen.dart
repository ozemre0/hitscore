import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supabase_config.dart';

class AddClassificationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialClassification;
  final List<Map<String, dynamic>>? existingClassifications;
  final int? excludeIndex;
  const AddClassificationScreen({
    super.key,
    this.initialClassification,
    this.existingClassifications,
    this.excludeIndex,
  });

  @override
  State<AddClassificationScreen> createState() => _AddClassificationScreenState();
}

class _AddClassificationScreenState extends State<AddClassificationScreen> {
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
  bool _optionsInitialized = false;

  // Generate automatic classification name based on selected properties
  String _generateClassificationName() {
    // Don't generate name if age groups are not loaded yet
    if (_ageGroups.isEmpty) {
      return '';
    }
    
    if (_selectedAgeGroup == null || 
        _selectedBowType == null || 
        _selectedGender == null || 
        _selectedEnvironment == null ||
        (_selectedDistance == null && _customDistanceController.text.trim().isEmpty)) {
      return '';
    }

    final locale = Localizations.localeOf(context).languageCode;
    
    // Get age group name safely
    String ageGroupName = '';
    try {
      final selectedAgeGroup = _ageGroups.firstWhere(
        (age) => age['age_group_id'].toString() == _selectedAgeGroup!,
        orElse: () => <String, dynamic>{},
      );
      ageGroupName = selectedAgeGroup.isNotEmpty 
          ? (locale == 'tr' ? selectedAgeGroup['age_group_tr'] : selectedAgeGroup['age_group_en'])
          : '';
    } catch (e) {
      // If age group not found, use empty string
      ageGroupName = '';
    }

    // Get distance
    final distance = _selectedDistance ?? int.tryParse(_customDistanceController.text.trim());
    final distanceText = distance != null ? '${distance}m' : '';

    // Build name parts
    final parts = <String>[];
    if (ageGroupName.isNotEmpty) parts.add(ageGroupName);
    if (_selectedGender != null) parts.add(_selectedGender!);
    if (_selectedBowType != null) parts.add(_selectedBowType!);
    if (distanceText.isNotEmpty) parts.add(distanceText);
    if (_selectedEnvironment != null) parts.add(_selectedEnvironment!);

    return parts.join(' ');
  }

  // Auto-select score buttons based on bow type and environment
  void _autoSelectScoreButtons() {
    if (_selectedBowType == null || _selectedEnvironment == null) {
      return;
    }

    Set<String> autoSelectedButtons = {};

    // Normalize bow type and environment for comparison
    final bowType = _selectedBowType!.toLowerCase();
    final environment = _selectedEnvironment!.toLowerCase();
    
    // Check for Turkish/English variations
    final isCompound = bowType.contains('makaralı') || bowType.contains('compound');
    final isRecurve = bowType.contains('klasik') || bowType.contains('recurve');
    final isBarebow = bowType.contains('barebow');
    final isIndoor = environment.contains('salon') || environment.contains('indoor');
    final isOutdoor = environment.contains('açık') || environment.contains('outdoor');

    if (isCompound && isOutdoor) {
      // Makaralı + Outdoor: X 10 9 8 7 6M
      autoSelectedButtons = {'X', '10', '9', '8', '7', '6', 'M'};
    } else if (isIndoor) {
      // Any bow type + Indoor: 10 9 8 7 6 M
      autoSelectedButtons = {'10', '9', '8', '7', '6', 'M'};
    } else if ((isRecurve || isBarebow) && isOutdoor) {
      // Klasik/Barebow + Outdoor: X 10 9 8 7 6 5 4 3 2 1 M
      autoSelectedButtons = {'X', '10', '9', '8', '7', '6', '5', '4', '3', '2', '1', 'M'};
    }

    if (autoSelectedButtons.isNotEmpty) {
      setState(() {
        _selectedScoreButtons = autoSelectedButtons;
      });
    }
  }

  // Auto-fill round settings based on environment
  void _autoFillRoundSettings() {
    if (_selectedEnvironment == null) {
      return;
    }

    final environment = _selectedEnvironment!.toLowerCase();
    final isIndoor = environment.contains('salon') || environment.contains('indoor');
    final isOutdoor = environment.contains('açık') || environment.contains('outdoor');

    if (isOutdoor) {
      // Outdoor settings: 2 rounds, 6 arrows per set, 6 sets per round
      _roundCountController.text = '2';
      _arrowsPerSetController.text = '6';
      _setsPerRoundController.text = '6';
    } else if (isIndoor) {
      // Indoor settings: 18m distance, 2 rounds, 3 arrows per set, 10 sets per round
      setState(() {
        _selectedDistance = 18;
      });
      _roundCountController.text = '2';
      _arrowsPerSetController.text = '3';
      _setsPerRoundController.text = '10';
    }
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initialClassification;
    if (init != null) {
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
    if (!_optionsInitialized) {
      _initializeOptions();
    }
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
      // Normalize any pre-filled selections coming from DB or route args (EN/TR) to current l10n labels
      if (_selectedBowType != null) {
        final map = <String, String>{
          'Recurve': l10n.bowTypeRecurve,
          'Compound': l10n.bowTypeCompound,
          'Barebow': l10n.bowTypeBarebow,
          // Turkish variants (old and new)
          'Klasik Yay': l10n.bowTypeRecurve,
          'Makaralı Yay': l10n.bowTypeCompound,
          'Klasik': l10n.bowTypeRecurve,
          'Makaralı': l10n.bowTypeCompound,
        };
        _selectedBowType = map[_selectedBowType!] ?? _selectedBowType;
      }
      if (_selectedEnvironment != null) {
        final map = <String, String>{
          'Indoor': l10n.environmentIndoor,
          'Outdoor': l10n.environmentOutdoor,
          // Turkish variants
          'Salon': l10n.environmentIndoor,
          'Açık Hava': l10n.environmentOutdoor,
        };
        _selectedEnvironment = map[_selectedEnvironment!] ?? _selectedEnvironment;
      }
      if (_selectedGender != null) {
        final map = <String, String>{
          'Male': l10n.genderMale,
          'Female': l10n.genderFemale,
          'Mixed': l10n.genderMixed,
          // Turkish variants
          'Erkek': l10n.genderMale,
          'Kadın': l10n.genderFemale,
          'Karma': l10n.genderMixed,
        };
        _selectedGender = map[_selectedGender!] ?? _selectedGender;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _optionsInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _customDistanceController.dispose();
    _roundCountController.dispose();
    _arrowsPerSetController.dispose();
    _setsPerRoundController.dispose();
    super.dispose();
  }

  bool _isDuplicateClassification(Map<String, dynamic> newClassification) {
    if (widget.existingClassifications == null) return false;
    
    for (int i = 0; i < widget.existingClassifications!.length; i++) {
      if (widget.excludeIndex != null && i == widget.excludeIndex) continue;
      
      final existing = widget.existingClassifications![i];
      final existingAgeGroupId = existing['ageGroupId'] ?? existing['age_group_id'];
      final existingBowType = existing['bowType'] ?? existing['bow_type'];
      
      if (existingAgeGroupId == newClassification['ageGroupId'] &&
          existingBowType == newClassification['bowType'] &&
          existing['environment'] == newClassification['environment'] &&
          existing['gender'] == newClassification['gender'] &&
          existing['distance'] == newClassification['distance']) {
        return true;
      }
    }
    return false;
  }

  void _save() {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedAgeGroup == null ||
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

    // Prepare classification data for duplicate check
    final classificationData = {
      'ageGroupId': selectedAgeGroup['age_group_id'],
      'bowType': _selectedBowType!,
      'environment': _selectedEnvironment!,
      'gender': _selectedGender!,
      'distance': distance,
    };

    // Check for duplicate before saving
    if (_isDuplicateClassification(classificationData)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.classificationDuplicateError)),
      );
      return;
    }

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
    print('DEBUG: Classification data saved: ${_generateClassificationName()} with score buttons: $scoreButtonsString');
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
                  // Auto-generated name preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.classificationNamePreview,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final generatedName = _generateClassificationName();
                            final isEmpty = generatedName.isEmpty;
                            return Text(
                              isEmpty 
                                  ? l10n.classificationNamePreviewEmpty
                                  : generatedName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isEmpty 
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            );
                          },
                        ),
                      ],
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
                    onChanged: (value) {
                      setState(() => _selectedBowType = value);
                      _autoSelectScoreButtons();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedEnvironment,
                    decoration: InputDecoration(labelText: l10n.environmentLabel, border: const OutlineInputBorder()),
                    items: _environments.map((env) => DropdownMenuItem(value: env, child: Text(env))).toList(),
                    onChanged: (value) {
                      setState(() => _selectedEnvironment = value);
                      _autoSelectScoreButtons();
                      _autoFillRoundSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(labelText: l10n.genderLabel, border: const OutlineInputBorder()),
                    items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                  const SizedBox(height: 16),
                  // Distance Section with Auto-fill indicator for Indoor
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedDistance,
                          decoration: InputDecoration(
                            labelText: l10n.distanceMetersLabel, 
                            border: const OutlineInputBorder(),
                            suffixIcon: _selectedEnvironment != null && 
                                       (_selectedEnvironment!.toLowerCase().contains('salon') || 
                                        _selectedEnvironment!.toLowerCase().contains('indoor')) &&
                                       _selectedDistance == 18
                                ? Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          l10n.autoFilled,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : null,
                          ),
                          items: [
                            ..._distances.map((d) => DropdownMenuItem(value: d, child: Text('${d}m'))),
                            DropdownMenuItem(value: -1, child: Text(l10n.customDistance)),
                          ],
                          onChanged: (value) => setState(() => _selectedDistance = value == -1 ? null : value),
                        ),
                      ),
                    ],
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
                  // Round Settings Section with Auto-fill indicator
                  Row(
                    children: [
                      Text(
                        l10n.roundSettingsLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_selectedEnvironment != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.autoFilled,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  NumberInputField(
                    controller: _roundCountController,
                    labelText: l10n.roundCountLabel,
                    minValue: 1,
                    maxValue: 10,
                  ),
                  const SizedBox(height: 16),
                  NumberInputField(
                    controller: _arrowsPerSetController,
                    labelText: l10n.arrowsPerSetLabel,
                    minValue: 1,
                    maxValue: 12,
                  ),
                  const SizedBox(height: 16),
                  NumberInputField(
                    controller: _setsPerRoundController,
                    labelText: l10n.setsPerRoundLabel,
                    minValue: 1,
                    maxValue: 20,
                  ),
                  const SizedBox(height: 16),
                  // Score Buttons Selection
                  Row(
                    children: [
                      Text(
                        l10n.availableScoreButtonsLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_selectedBowType != null && _selectedEnvironment != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.autoSelected,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                      return Container(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 40,
                        ),
                        child: FilterChip(
                        label: Text(
                          button,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14, // Sabit font boyutu
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
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
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                        showCheckmark: true,
                        elevation: 0, // Sabit elevation
                        side: BorderSide(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: isSelected ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        // Sabit boyut için padding ekle
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
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

// Reusable NumberInputField widget with +/- buttons
class NumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final int minValue;
  final int maxValue;
  final VoidCallback? onChanged;

  const NumberInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.minValue = 1,
    this.maxValue = 99,
    this.onChanged,
  });

  void _increment() {
    final currentValue = int.tryParse(controller.text) ?? minValue;
    if (currentValue < maxValue) {
      controller.text = (currentValue + 1).toString();
      onChanged?.call();
    }
  }

  void _decrement() {
    final currentValue = int.tryParse(controller.text) ?? minValue;
    if (currentValue > minValue) {
      controller.text = (currentValue - 1).toString();
      onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrement button
        Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: IconButton(
            onPressed: _decrement,
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
        ),
        // Text field
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            onChanged: (value) {
              // Validate range when user types
              final intValue = int.tryParse(value);
              if (intValue != null) {
                if (intValue < minValue) {
                  controller.text = minValue.toString();
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                } else if (intValue > maxValue) {
                  controller.text = maxValue.toString();
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              }
              onChanged?.call();
            },
          ),
        ),
        // Increment button
        Container(
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: IconButton(
            onPressed: _increment,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


