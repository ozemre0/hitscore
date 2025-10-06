import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_config.dart';
import 'dart:convert';

class ScoreEntryScreen extends ConsumerStatefulWidget {
  final String competitionId;
  final String competitionName;
  final String competitionVisibleId;
  final Map<String, dynamic>? classification;

  const ScoreEntryScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
    required this.competitionVisibleId,
    this.classification,
  });

  @override
  ConsumerState<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends ConsumerState<ScoreEntryScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scoreEntryTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _ScoreEntryContent(
                competitionId: widget.competitionId,
                competitionName: widget.competitionName,
                competitionVisibleId: widget.competitionVisibleId,
                classification: widget.classification,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreEntryContent extends ConsumerStatefulWidget {
  final String competitionId;
  final String competitionName;
  final String competitionVisibleId;
  final Map<String, dynamic>? classification;

  const _ScoreEntryContent({
    required this.competitionId,
    required this.competitionName,
    required this.competitionVisibleId,
    this.classification,
  });

  @override
  ConsumerState<_ScoreEntryContent> createState() => _ScoreEntryContentState();
}

class _ScoreEntryContentState extends ConsumerState<_ScoreEntryContent> {
  List<int> _currentArrows = [];
  int _currentSet = 1;
  int _totalScore = 0;
  int _currentSetScore = 0;
  List<Map<String, dynamic>> _completedSets = [];
  bool _isOverwriting = false;
  int _overwritingSetNumber = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingExistingData = true;
  
  // Classification parameters
  int get _arrowsPerSet => widget.classification?['arrow_per_set'] ?? 3;
  int get _setsPerRound => widget.classification?['set_per_round'] ?? 10;
  
  // Get available score buttons from classification
  List<String> get _availableScoreButtons {
    final scoreButtonsStr = widget.classification?['available_score_buttons'] as String?;
    if (scoreButtonsStr == null || scoreButtonsStr.isEmpty) {
      // Default score buttons if not specified
      return ['10', '9', '8', '7', '6', 'M'];
    }
    
    try {
      // Parse the score buttons string like "[X,10,9,8,7,6,5,4,3,2,1,M]"
      final cleanStr = scoreButtonsStr.replaceAll('[', '').replaceAll(']', '');
      final buttons = cleanStr.split(',').map((e) => e.trim()).toList();
      print('DEBUG: Parsed score buttons from classification: $buttons');
      
      // Debug X and M button parsing
      for (final button in buttons) {
        final score = _parseScoreButton(button);
        final label = _getScoreButtonLabel(button);
        print('DEBUG: Button "$button" -> Score: $score, Label: "$label"');
      }
      
      return buttons;
    } catch (e) {
      print('DEBUG: Error parsing score buttons: $e');
      // Fallback to default
      return ['10', '9', '8', '7', '6', 'M'];
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadExistingScoreData();
  }
  
  Future<void> _loadExistingScoreData() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        print('No user found');
        setState(() => _isLoadingExistingData = false);
        return;
      }
      
      print('Loading existing data for user: ${user.id}, competition: ${widget.competitionId}');
      
      // Find participant_id for this competition
      final participantResponse = await SupabaseConfig.client
          .from('organized_competition_participants')
          .select('participant_id')
          .eq('user_id', user.id)
          .eq('organized_competition_id', widget.competitionId)
          .maybeSingle();
      
      print('Participant response: $participantResponse');
      
      if (participantResponse == null) {
        print('No participant found');
        setState(() => _isLoadingExistingData = false);
        return;
      }
      
      final participantId = participantResponse['participant_id'] as String;
      print('Found participant_id: $participantId');
      
      // Load existing qualification data
      final qualificationResponse = await SupabaseConfig.client
          .from('organized_qualifications')
          .select('qualification_sets_data, qualification_total_score')
          .eq('participant_id', participantId)
          .maybeSingle();
      
      print('Qualification response: $qualificationResponse');
      
      if (qualificationResponse != null && qualificationResponse['qualification_sets_data'] != null) {
        final rawSetsData = qualificationResponse['qualification_sets_data'];
        print('Raw sets data: $rawSetsData (type: ${rawSetsData.runtimeType})');
        
        List<dynamic> setsData;
        if (rawSetsData is String) {
          // JSON string olarak geliyorsa parse et
          setsData = jsonDecode(rawSetsData) as List<dynamic>;
        } else {
          // Zaten List ise direkt kullan
          setsData = rawSetsData as List<dynamic>;
        }
        
        print('Parsed sets data: $setsData');
        
        // Convert back to _completedSets format
        final completedSets = <Map<String, dynamic>>[];
        int calculatedTotal = 0;
        
        for (final setData in setsData) {
          if (setData is List && setData.length >= 2) {
            final setNumber = setData[0] as int;
            final arrows = List<int>.from(setData[1] as List);
            final setScore = arrows.fold<int>(0, (sum, arrow) => sum + arrow);
            
            completedSets.add({
              'setNumber': setNumber,
              'arrows': arrows,
              'totalScore': setScore,
            });
            
            calculatedTotal += setScore;
          }
        }
        
        // Sort by set number
        completedSets.sort((a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int));
        
        setState(() {
          _completedSets = completedSets;
          _totalScore = calculatedTotal;
          _currentSet = _getNextSetNumber();
          _isLoadingExistingData = false;
        });
        
        print('Loaded existing score data: ${completedSets.length} sets, total: $calculatedTotal');
        print('Completed sets: $_completedSets');
      } else {
        print('No qualification data found or data is null');
        setState(() => _isLoadingExistingData = false);
      }
    } catch (e) {
      print('Error loading existing score data: $e');
      setState(() => _isLoadingExistingData = false);
    }
  }

  void _addScore(int score) {
    if (_currentArrows.length < _arrowsPerSet) {
      setState(() {
        _currentArrows.add(score);
        _currentSetScore += score;
        _totalScore += score;
      });
    }
  }

  void _undoLastArrow() {
    if (_currentArrows.isNotEmpty) {
      setState(() {
        final lastScore = _currentArrows.removeLast();
        _currentSetScore -= lastScore;
        _totalScore -= lastScore;
      });
    }
  }

  void _resetCurrentSet() {
    setState(() {
      _totalScore -= _currentSetScore;
      _currentArrows.clear();
      _currentSetScore = 0;
    });
  }

  void _completeSet() {
    if (_currentArrows.length == _arrowsPerSet) {
      setState(() {
        if (_isOverwriting) {
          // Overwrite modunda: mevcut seriyi güncelle
          _completedSets.add({
            'setNumber': _overwritingSetNumber,
            'arrows': List<int>.from(_currentArrows),
            'totalScore': _currentSetScore,
          });
          // Overwrite modundan çık ve doğru seri numarasını ayarla
          _isOverwriting = false;
          _overwritingSetNumber = 0;
          // En yüksek seri numarasını bul ve +1 yap
          if (_completedSets.isNotEmpty) {
            final maxSetNumber = _completedSets
                .map((set) => set['setNumber'] as int)
                .reduce((a, b) => a > b ? a : b);
            _currentSet = maxSetNumber + 1;
          }
        } else {
          // Normal mod: yeni seti ekle
          _completedSets.add({
            'setNumber': _currentSet,
            'arrows': List<int>.from(_currentArrows),
            'totalScore': _currentSetScore,
          });
          
          // Sonraki seri numarasını belirle
          _currentSet = _getNextSetNumber();
        }
        
        // Yeni set için hazırla
        _currentArrows.clear();
        _currentSetScore = 0;
        
        // Serileri seri numarasına göre sırala
        _completedSets.sort((a, b) => (a['setNumber'] as int).compareTo(b['setNumber'] as int));
        
        // Overall total'i yeniden hesapla
        _recalculateTotalScore();
        
        // Debug: Tamamlanan serileri print et
        _printCompletedSets();
        
        // Otomatik olarak skoru kaydet
        _saveScore();
        
        // Scroll'u en alta kaydır
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }
  
  void _printCompletedSets() {
    final debugData = _completedSets.map((set) => [
      set['setNumber'],
      set['arrows']
    ]).toList();
    print('Completed Sets: $debugData');
  }
  
  // Recalculate total score from all completed sets
  void _recalculateTotalScore() {
    _totalScore = _completedSets.fold<int>(0, (sum, set) => sum + (set['totalScore'] as int));
    print('DEBUG: Recalculated total score: $_totalScore from ${_completedSets.length} sets');
  }
  
  Future<void> _saveScore() async {
    if (_completedSets.isEmpty) return;
    
    try {
      // Format data as requested: [[1, [10, 10, 10, 10, 7, 7]], [2, [7, 7, 7, 7, 7, 7]]]
      final setsData = _completedSets.map((set) => [
        set['setNumber'],
        set['arrows']
      ]).toList();
      
      print('Saving qualification_sets_data: $setsData');
      
      // Get current user's participant_id for this competition
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      
      // Find participant_id for this competition
      final participantResponse = await SupabaseConfig.client
          .from('organized_competition_participants')
          .select('participant_id')
          .eq('user_id', user.id)
          .eq('organized_competition_id', widget.competitionId)
          .maybeSingle();
      
      if (participantResponse == null) {
        print('Participant not found for user ${user.id} in competition ${widget.competitionId}');
        return;
      }
      
      final participantId = participantResponse['participant_id'] as String;
      
      // Calculate total score
      final totalScore = _completedSets.fold<int>(0, (sum, set) => sum + (set['totalScore'] as int));
      
      // Update existing qualification record
      await SupabaseConfig.client
          .from('organized_qualifications')
          .update({
            'qualification_sets_data': setsData,
            'qualification_total_score': totalScore,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('participant_id', participantId);
      
      print('Score saved successfully: $totalScore points');
      print('Supabase e gönderildi: qualification_sets_data=$setsData, qualification_total_score=$totalScore');
    } catch (e) {
      print('Error saving score: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving score: $e')),
        );
      }
    }
  }
  
  int _getNextSetNumber() {
    if (_completedSets.isEmpty) return 1;
    
    // Mevcut seri numaralarını al ve sırala
    final existingSetNumbers = _completedSets
        .map((set) => set['setNumber'] as int)
        .toList()
      ..sort();
    
    // Eksik seri numarasını bul
    for (int i = 1; i <= existingSetNumbers.length + 1; i++) {
      if (!existingSetNumbers.contains(i)) {
        return i;
      }
    }
    
    // Eğer hiç eksik yoksa, en büyük + 1
    return existingSetNumbers.last + 1;
  }
  
  bool get _canAddMoreSets => _completedSets.length < _setsPerRound;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoadingExistingData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Scrollable content area
          Expanded(
                child: Column(
              children: [
                // Current set score display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '(${_currentArrows.length}/$_arrowsPerSet)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Total: $_currentSetScore',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Overall total score
                if (_completedSets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Overall Total: $_totalScore',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Current arrows display
                Row(
                  children: [
                    if (_currentArrows.isEmpty)
                      Text(
                        'No arrows yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Row(
                        children: _currentArrows.map((score) => Container(
                          width: 42,
                          height: 42,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _getColorForScore(score),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            score == 0 ? 'M' : score.toString(),
                            style: TextStyle(
                              color: _getTextColorForScore(score),
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Info message
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: _canAddMoreSets ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _canAddMoreSets ? Colors.blue.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _canAddMoreSets ? Icons.info_outline : Icons.warning_outlined,
                        size: 16,
                        color: _canAddMoreSets ? colorScheme.primary : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isOverwriting 
                            ? l10n.overwritingSet(_overwritingSetNumber)
                            : _canAddMoreSets 
                              ? l10n.tapScoreToContinue(_currentSet)
                              : 'Maximum sets reached ($_setsPerRound). You cannot add more sets.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Scrollable completed sets area
                Expanded(
                  child: _completedSets.isEmpty
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                             children: _completedSets.asMap().entries.map((entry) {
                               final index = entry.key;
                               final set = entry.value;
                               return GestureDetector(
                                 onTap: () => _showSetDialog(index),
                                 child: Container(
                                   margin: const EdgeInsets.only(bottom: 8),
                                   padding: const EdgeInsets.all(12.0),
                                   decoration: BoxDecoration(
                                     color: colorScheme.surface,
                                     borderRadius: BorderRadius.circular(8),
                                     border: Border.all(
                                       color: colorScheme.outline.withOpacity(0.3),
                                       width: 1,
                                     ),
                                   ),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Row(
                                         children: [
                                           Text(
                                             'Set ${set['setNumber']}',
                                             style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                               fontWeight: FontWeight.bold,
                                             ),
                                           ),
                                           const SizedBox(width: 8),
                                           Icon(
                                             Icons.touch_app,
                                             size: 16,
                                             color: colorScheme.onSurfaceVariant,
                                           ),
                                         ],
                                       ),
                                       const SizedBox(height: 8),
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(
                                             '${set['totalScore']}/${_arrowsPerSet * 10}',
                                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                               color: colorScheme.onSurfaceVariant,
                                             ),
                                           ),
                                           Row(
                                             children: (set['arrows'] as List<int>).map((score) => Container(
                                               width: 32,
                                               height: 32,
                                               margin: const EdgeInsets.only(left: 4),
                                               decoration: BoxDecoration(
                                                 color: _getColorForScore(score),
                                                 shape: BoxShape.circle,
                                                 border: Border.all(color: Colors.black26),
                                               ),
                                               alignment: Alignment.center,
                                               child: Text(
                                                 score == 0 ? 'M' : score.toString(),
                                                 style: TextStyle(
                                                   color: _getTextColorForScore(score),
                                                   fontSize: 15,
                                                   fontWeight: FontWeight.bold,
                                                 ),
                                               ),
                                             )).toList(),
                                           ),
                                         ],
                                       ),
                                     ],
                                   ),
                                 ),
                               );
                             }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // Fixed bottom section with score buttons and action buttons
          Column(
            children: [
              // Divider line above score buttons
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      colorScheme.outline.withOpacity(0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              
              // Score buttons - fixed at bottom (max 2 rows)
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final buttonCount = _availableScoreButtons.length;
                  
                  // Calculate optimal layout: max 6 buttons per row
                  final maxButtonsPerRow = 6;
                  final rows = (buttonCount / maxButtonsPerRow).ceil();
                  final buttonsPerRow = (buttonCount / rows).ceil();
                  
                  // Calculate button size based on available space
                  final availableWidth = screenWidth - 32; // Account for padding
                  final buttonSize = (availableWidth / buttonsPerRow) - 8;
                  final clampedButtonSize = buttonSize.clamp(40.0, 60.0);
                  
                  print('DEBUG: Score buttons layout - Total: $buttonCount, Rows: $rows, Buttons per row: $buttonsPerRow, Button size: $clampedButtonSize');
                  
                  return Column(
                    children: [
                      // First row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _availableScoreButtons.take(buttonsPerRow).map((button) {
                          final score = _parseScoreButton(button);
                          final colors = _getColorsForButton(button);
                          final label = _getScoreButtonLabel(button);
                          return _buildScoreButton(
                            context, 
                            score, 
                            colors['background']!, 
                            colors['text']!, 
                            label: label, 
                            size: clampedButtonSize, 
                            onTap: _canAddMoreSets ? () => _addScore(score) : null
                          );
                        }).toList(),
                      ),
                      // Second row (if needed)
                      if (buttonCount > buttonsPerRow) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _availableScoreButtons.skip(buttonsPerRow).map((button) {
                            final score = _parseScoreButton(button);
                            final colors = _getColorsForButton(button);
                            final label = _getScoreButtonLabel(button);
                            return _buildScoreButton(
                              context, 
                              score, 
                              colors['background']!, 
                              colors['text']!, 
                              label: label, 
                              size: clampedButtonSize, 
                              onTap: _canAddMoreSets ? () => _addScore(score) : null
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons - fixed at bottom
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentArrows.isNotEmpty ? _undoLastArrow : null,
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Undo'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentArrows.isNotEmpty ? _resetCurrentSet : null,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentArrows.length == _arrowsPerSet ? _completeSet : null,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButton(BuildContext context, int score, Color backgroundColor, Color textColor, {String? label, double? size, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonSize = size ?? 50.0;
    final isDisabled = onTap == null;
    
    return Material(
      color: Colors.transparent,
      elevation: isDisabled ? 0 : 2,
      borderRadius: BorderRadius.circular(buttonSize / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(buttonSize / 2),
        onTap: onTap,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDisabled ? backgroundColor.withOpacity(0.3) : backgroundColor,
            border: Border.all(
              color: colorScheme.outline.withOpacity(isDisabled ? 0.1 : 0.3),
              width: 1,
            ),
            boxShadow: isDisabled ? null : [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label ?? score.toString(),
            style: TextStyle(
              fontSize: buttonSize * 0.35, // Responsive font size
              fontWeight: FontWeight.bold,
              color: isDisabled ? textColor.withOpacity(0.5) : textColor,
            ),
          ),
        ),
      ),
    );
  }

  // Parse score button string to integer score
  int _parseScoreButton(String button) {
    if (button == 'X') return 10; // X is treated as 10 for scoring
    if (button == 'M') return 0;  // M is treated as 0 (miss)
    return int.tryParse(button) ?? 0;
  }
  
  // Get display label for score button
  String _getScoreButtonLabel(String button) {
    if (button == 'X') return 'X';
    if (button == 'M') return 'M';
    return button; // For numeric buttons, show the number
  }
  
  // Get colors for score button
  Map<String, Color> _getColorsForScore(int score) {
    switch (score) {
      case 10:
        return {'background': Colors.yellow, 'text': Colors.black};
      case 9:
        return {'background': Colors.yellow, 'text': Colors.black};
      case 8:
        return {'background': Colors.red, 'text': Colors.white};
      case 7:
        return {'background': Colors.red, 'text': Colors.white};
      case 6:
        return {'background': Colors.blue, 'text': Colors.white};
      case 5:
        return {'background': Colors.blue, 'text': Colors.white};
      case 4:
        return {'background': Colors.blue, 'text': Colors.white};
      case 3:
        return {'background': Colors.blue, 'text': Colors.white};
      case 2:
        return {'background': Colors.blue, 'text': Colors.white};
      case 1:
        return {'background': Colors.blue, 'text': Colors.white};
      case 0: // M (miss)
        return {'background': Colors.grey, 'text': Colors.white};
      default:
        return {'background': Colors.grey, 'text': Colors.white};
    }
  }
  
  // Get colors for specific button labels (X and M get special treatment)
  Map<String, Color> _getColorsForButton(String button) {
    if (button == 'X') {
      return {'background': Colors.yellow, 'text': Colors.black}; // X gets yellow like 10
    }
    if (button == 'M') {
      return {'background': Colors.grey, 'text': Colors.white}; // M gets grey like 0
    }
    // For numeric buttons, use the score-based colors
    final score = _parseScoreButton(button);
    return _getColorsForScore(score);
  }

  Color _getColorForScore(int score) {
    if (score == 10) return Colors.yellow;
    if (score == 9) return Colors.yellow;
    if (score == 8) return Colors.red;
    if (score == 7) return Colors.red;
    if (score == 6) return Colors.blue;
    if (score == 5) return Colors.blue;
    if (score == 4) return Colors.black;
    if (score == 3) return Colors.black;
    if (score == 2) return Colors.white;
    if (score == 1) return Colors.white;
    return Colors.grey; // 0 için (M)
  }

  Color _getTextColorForScore(int score) {
    if (score >= 9) return Colors.black;
    if (score >= 4 || score == 3) return Colors.white;
    return Colors.black;
  }

  void _showSetDialog(int setIndex) {
    final set = _completedSets[setIndex];
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editSet(set['setNumber'])),
        content: const SizedBox.shrink(),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isOverwriting = true;
                      _overwritingSetNumber = set['setNumber'];
                      // Edit edilen serinin oklarını yukarıdaki alana koy
                      _currentArrows = List<int>.from(set['arrows']);
                      _currentSetScore = set['totalScore'];
                      // İlgili seti geçici olarak gizle
                      _completedSets.removeWhere((s) => s['setNumber'] == set['setNumber']);
                      // Overall total'i yeniden hesapla
                      _recalculateTotalScore();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                  ),
                  child: Text(l10n.edit),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      // Seriyi sil
                      _completedSets.removeWhere((s) => s['setNumber'] == set['setNumber']);
                      // Overall total'i yeniden hesapla
                      _recalculateTotalScore();
                      // Sonraki seri numarasını güncelle
                      _currentSet = _getNextSetNumber();
                      // Debug: Silinmiş serileri print et
                      _printCompletedSets();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: Text(l10n.delete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
