import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';

class MatchScoringScreen extends StatefulWidget {
  final String matchId;
  final String competitionId;
  final Map<String, dynamic> participant1;
  final Map<String, dynamic> participant2;
  final String bowType;

  const MatchScoringScreen({
    super.key,
    required this.matchId,
    required this.competitionId,
    required this.participant1,
    required this.participant2,
    required this.bowType,
  });

  @override
  State<MatchScoringScreen> createState() => _MatchScoringScreenState();
}

class _MatchScoringScreenState extends State<MatchScoringScreen> {
  int _currentSet = 1;
  int _maxSets = 5;
  
  // Recurve/Barebow için
  int _participant1Points = 0;
  int _participant2Points = 0;
  
  // Compound için
  int _participant1TotalScore = 0;
  int _participant2TotalScore = 0;
  
  List<Map<String, dynamic>> _sets = [];
  bool _needsTieBreak = false;
  bool _isMatchCompleted = false;
  
  final List<TextEditingController> _participant1Controllers = [];
  final List<TextEditingController> _participant2Controllers = [];

  @override
  void initState() {
    super.initState();
    _initializeMatch();
  }

  void _initializeMatch() {
    _maxSets = widget.bowType == 'compound' ? 5 : 5;
    
    for (int i = 0; i < _maxSets; i++) {
      _participant1Controllers.add(TextEditingController());
      _participant2Controllers.add(TextEditingController());
      _sets.add({
        'setNumber': i + 1,
        'participant1Score': null,
        'participant2Score': null,
        'participant1Points': 0,
        'participant2Points': 0,
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _participant1Controllers) {
      controller.dispose();
    }
    for (var controller in _participant2Controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchScoringTitle),
        actions: [
          if (!_isMatchCompleted)
            TextButton(
              onPressed: _saveMatch,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: Column(
                children: [
                  _buildMatchHeader(l10n),
                  _buildScoreBoard(l10n),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildSetSelector(l10n),
                          const SizedBox(height: 16),
                          _buildCurrentSetScoring(l10n),
                          const SizedBox(height: 16),
                          _buildSetsHistory(l10n),
                          if (_needsTieBreak) ...[
                            const SizedBox(height: 16),
                            _buildTieBreakSection(l10n),
                          ],
                          const SizedBox(height: 24),
                          if (!_isMatchCompleted)
                            _buildActionButtons(l10n)
                          else
                            _buildMatchCompletedCard(l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchHeader(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                Icon(Icons.person, color: colorScheme.primary, size: 32),
                const SizedBox(height: 8),
                Text(
                  widget.participant1['name'] ?? l10n.participant1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'VS',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Icon(Icons.person_outline, color: colorScheme.secondary, size: 32),
                const SizedBox(height: 8),
                Text(
                  widget.participant2['name'] ?? l10n.participant2,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompound = widget.bowType == 'compound';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScoreDisplay(
            isCompound ? '$_participant1TotalScore' : '$_participant1Points',
            widget.participant1['name'] ?? l10n.participant1,
            colorScheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '-',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildScoreDisplay(
            isCompound ? '$_participant2TotalScore' : '$_participant2Points',
            widget.participant2['name'] ?? l10n.participant2,
            colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(String score, String name, Color color) {
    return Column(
      children: [
        Text(
          score,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          widget.bowType == 'compound' ? 'Total' : 'Points',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSetSelector(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
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
            Text(
              l10n.selectSet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_maxSets, (index) {
                  final setNumber = index + 1;
                  final isSelected = _currentSet == setNumber;
                  final setData = _sets[index];
                  final isCompleted = setData['participant1Score'] != null && 
                                     setData['participant2Score'] != null;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${l10n.set} $setNumber'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _currentSet = setNumber;
                          });
                        }
                      },
                      selectedColor: colorScheme.primaryContainer,
                      side: BorderSide(
                        color: isCompleted 
                            ? Colors.green
                            : isSelected 
                                ? colorScheme.primary 
                                : colorScheme.outline,
                      ),
                      avatar: isCompleted 
                          ? const Icon(Icons.check, size: 16, color: Colors.green)
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSetScoring(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSetIndex = _currentSet - 1;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.scoreboard, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.set} $_currentSet ${l10n.scoring}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.participant1['name'] ?? l10n.participant1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _participant1Controllers[currentSetIndex],
                        decoration: InputDecoration(
                          labelText: l10n.score,
                          border: const OutlineInputBorder(),
                          suffixText: '/ 30',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _MaxValueInputFormatter(30),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.participant2['name'] ?? l10n.participant2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _participant2Controllers[currentSetIndex],
                        decoration: InputDecoration(
                          labelText: l10n.score,
                          border: const OutlineInputBorder(),
                          suffixText: '/ 30',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _MaxValueInputFormatter(30),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveCurrentSet,
                child: Text(l10n.saveSet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsHistory(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final completedSets = _sets.where((set) => 
      set['participant1Score'] != null && set['participant2Score'] != null
    ).toList();
    
    if (completedSets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
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
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.completedSets,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...completedSets.map((set) => _buildSetHistoryTile(set, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildSetHistoryTile(Map<String, dynamic> set, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final setNumber = set['setNumber'] as int;
    final p1Score = set['participant1Score'] as int;
    final p2Score = set['participant2Score'] as int;
    final p1Points = set['participant1Points'] as int;
    final p2Points = set['participant2Points'] as int;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${l10n.set} $setNumber',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$p1Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: p1Score > p2Score ? Colors.green : colorScheme.onSurface,
                  ),
                ),
                Text(
                  ' - ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '$p2Score',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: p2Score > p1Score ? Colors.green : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (widget.bowType != 'compound') ...[
            const SizedBox(width: 16),
            Text(
              '($p1Points - $p2Points)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTieBreakSection(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.orange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.tieBreak,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tieBreakDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Beraberlik atışı ekranı
              },
              icon: const Icon(Icons.sports_martial_arts),
              label: Text(l10n.startTieBreak),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.cancel),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _completeMatch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.completeMatch),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCompletedCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.withOpacity(0.3), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.matchCompleted,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.matchCompletedDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _saveCurrentSet() {
    final currentSetIndex = _currentSet - 1;
    final p1Text = _participant1Controllers[currentSetIndex].text;
    final p2Text = _participant2Controllers[currentSetIndex].text;
    
    if (p1Text.isEmpty || p2Text.isEmpty) {
      _showError('Lütfen her iki skoru da girin');
      return;
    }
    
    final p1Score = int.tryParse(p1Text);
    final p2Score = int.tryParse(p2Text);
    
    if (p1Score == null || p2Score == null) {
      _showError('Geçersiz skor');
      return;
    }
    
    setState(() {
      _sets[currentSetIndex]['participant1Score'] = p1Score;
      _sets[currentSetIndex]['participant2Score'] = p2Score;
      
      if (widget.bowType == 'compound') {
        // Compound için toplam skor
        _participant1TotalScore += p1Score;
        _participant2TotalScore += p2Score;
      } else {
        // Recurve/Barebow için set puanı
        if (p1Score > p2Score) {
          _sets[currentSetIndex]['participant1Points'] = 2;
          _participant1Points += 2;
        } else if (p2Score > p1Score) {
          _sets[currentSetIndex]['participant2Points'] = 2;
          _participant2Points += 2;
        } else {
          _sets[currentSetIndex]['participant1Points'] = 1;
          _sets[currentSetIndex]['participant2Points'] = 1;
          _participant1Points += 1;
          _participant2Points += 1;
        }
      }
      
      // Sonraki set'e geç
      if (_currentSet < _maxSets) {
        _currentSet++;
      }
      
      // Kazanan kontrolü
      _checkMatchCompletion();
    });
  }

  void _checkMatchCompletion() {
    if (widget.bowType == 'compound') {
      // Compound: Tüm setler tamamlandı mı?
      final completedSets = _sets.where((set) => set['participant1Score'] != null).length;
      if (completedSets == _maxSets) {
        if (_participant1TotalScore == _participant2TotalScore) {
          _needsTieBreak = true;
        } else {
          _isMatchCompleted = true;
        }
      }
    } else {
      // Recurve/Barebow: 6 puana ulaşıldı mı?
      if (_participant1Points >= 6 || _participant2Points >= 6) {
        _isMatchCompleted = true;
      } else {
        final completedSets = _sets.where((set) => set['participant1Score'] != null).length;
        if (completedSets == _maxSets && _participant1Points == _participant2Points) {
          _needsTieBreak = true;
        }
      }
    }
  }

  void _saveMatch() {
    // Maçı kaydet - API çağrısı
    Navigator.of(context).pop();
  }

  void _completeMatch() {
    if (!_isMatchCompleted) {
      _showError('Maçı tamamlamak için yeterli skor girilmedi');
      return;
    }
    
    // Maçı tamamla ve kaydet
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;
  
  _MaxValueInputFormatter(this.maxValue);
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }
    
    return newValue;
  }
}

