import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class EliminationSettingsScreen extends StatefulWidget {
  final String competitionId;
  final String competitionName;

  const EliminationSettingsScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
  });

  @override
  State<EliminationSettingsScreen> createState() => _EliminationSettingsScreenState();
}

class _EliminationSettingsScreenState extends State<EliminationSettingsScreen> {
  String _selectedBowType = 'recurve';
  int _cutoffRank = 16;
  int _selectedBracketSize = 16;
  final List<String> _bowTypes = ['recurve', 'barebow', 'compound'];
  int? _expandedCombinationIndex;
  final TextEditingController _cutoffController = TextEditingController();
  Timer? _incrementTimer;
  Timer? _decrementTimer;

  @override
  void initState() {
    super.initState();
    _cutoffController.text = _cutoffRank.toString();
  }

  @override
  void dispose() {
    _cutoffController.dispose();
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
    super.dispose();
  }

  void _updateCutoffRank(int newValue) {
    if (newValue >= 8 && newValue <= 256) {
      setState(() {
        _cutoffRank = newValue;
        _cutoffController.text = _cutoffRank.toString();
        // İlk geçerli hedef boyutu seç
        final combinations = _calculatePossibleCombinations();
        if (combinations.isNotEmpty) {
          _selectedBracketSize = combinations.first['targetSize'];
        }
      });
    }
  }

  void _startIncrementing() {
    if (_cutoffRank < 256) {
      _updateCutoffRank(_cutoffRank + 1);
      _incrementTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        if (_cutoffRank < 256) {
          _updateCutoffRank(_cutoffRank + 1);
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _startDecrementing() {
    if (_cutoffRank > 8) {
      _updateCutoffRank(_cutoffRank - 1);
      _decrementTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        if (_cutoffRank > 8) {
          _updateCutoffRank(_cutoffRank - 1);
        } else {
          timer.cancel();
        }
      });
    }
  }

  void _stopIncrementing() {
    _incrementTimer?.cancel();
    _incrementTimer = null;
  }

  void _stopDecrementing() {
    _decrementTimer?.cancel();
    _decrementTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eliminationSettingsTitle),
        actions: [
          TextButton(
            onPressed: _saveSettings,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompetitionInfoCard(l10n),
                    const SizedBox(height: 16),
                    _buildBowTypeCard(l10n),
                    const SizedBox(height: 16),
                    _buildByeSettingsCard(l10n),
                    const SizedBox(height: 24),
                    _buildActionButtons(l10n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompetitionInfoCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.eliminationSettingsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.competitionName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.eliminationSettingsSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBowTypeCard(AppLocalizations l10n) {
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
              l10n.bowTypeSelection,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bowTypeSelectionSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bowTypes.map((bowType) {
                final isSelected = _selectedBowType == bowType;
                return ChoiceChip(
                  label: Text(_getBowTypeDisplayName(bowType, l10n)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedBowType = bowType;
                      });
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  side: BorderSide(
                    color: isSelected ? colorScheme.primary : colorScheme.outline,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildByeSettingsCard(AppLocalizations l10n) {
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
            // Cutoff Slider Section
            Text(
              'Kesme Sınırı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk $_cutoffRank sıradaki sporcu eleme sistemine dahil olur',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sporcu Sayısı',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Azalt butonu
                    GestureDetector(
                      onTapDown: _cutoffRank > 8 ? (_) => _startDecrementing() : null,
                      onTapUp: (_) => _stopDecrementing(),
                      onTapCancel: () => _stopDecrementing(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 16,
                          color: _cutoffRank > 8 
                              ? colorScheme.primary 
                              : colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                    
                    // TextField
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _cutoffController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          filled: true,
                          fillColor: colorScheme.primaryContainer.withOpacity(0.3),
                        ),
                        onChanged: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue != null && newValue >= 8 && newValue <= 256) {
                            _updateCutoffRank(newValue);
                          }
                        },
                        onSubmitted: (value) {
                          final newValue = int.tryParse(value);
                          if (newValue == null || newValue < 8 || newValue > 256) {
                            // Geçersiz değer, eski değere geri dön
                            _cutoffController.text = _cutoffRank.toString();
                          }
                        },
                      ),
                    ),
                    
                    // Arttır butonu
                    GestureDetector(
                      onTapDown: _cutoffRank < 256 ? (_) => _startIncrementing() : null,
                      onTapUp: (_) => _stopIncrementing(),
                      onTapCancel: () => _stopIncrementing(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 16,
                          color: _cutoffRank < 256 
                              ? colorScheme.primary 
                              : colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '8-256 arasında bir değer girin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bracket Combinations Section
            Text(
              'Olası Bracket Kombinasyonları',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cutoff ($_cutoffRank sporcu) için mevcut seçenekler:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Combination Cards
            ..._calculatePossibleCombinations().asMap().entries.map((entry) {
              final index = entry.key;
              final combination = entry.value;
              final isSelected = _selectedBracketSize == combination['targetSize'];
              final isExpanded = _expandedCombinationIndex == index;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    // Main card
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedBracketSize = combination['targetSize'];
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Selection indicator
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              child: isSelected 
                                  ? Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            
                            // Combination info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${combination['targetSize']} Kişilik Bracket',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getShortDescription(combination['targetSize']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Expand button
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _expandedCombinationIndex = isExpanded ? null : index;
                                });
                              },
                              icon: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              tooltip: isExpanded ? 'Kapat' : 'Tüm Maçları Göster',
                            ),
                            
                            // Recommended badge
                            if (combination['recommended'] == true) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Önerilen',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Expanded content
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.sports_martial_arts,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Detaylı Maç Programı',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              combination['description'],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
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
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.saveAndContinue),
          ),
        ),
      ],
    );
  }







  List<Map<String, dynamic>> _calculatePossibleCombinations() {
    List<Map<String, dynamic>> combinations = [];
    
    // Case'lere göre olası hedef boyutlar
    List<int> possibleTargets = [8, 16, 32, 64, 128, 256];
    
    for (int target in possibleTargets) {
      // Hedef cutoff'tan küçük veya eşit olmalı
      if (target <= _cutoffRank) {
        // Case'lere göre: cutoff hedefin 2 katından küçük veya eşit olmalı
        // Örnek: 20 sporcu, 8 hedef → 20 <= 16 ✓, 20 sporcu, 16 hedef → 20 <= 32 ✓
        if (_cutoffRank <= target * 2) {
          combinations.add({
            'targetSize': target,
            'description': _getCombinationDescription(target),
            'recommended': _isRecommendedTarget(target),
          });
        }
      }
    }
    
    return combinations;
  }
  
  String _getShortDescription(int targetSize) {
    if (_cutoffRank <= targetSize) {
      return 'Tüm sporcular ana tabloda';
    } else {
      int excess = _cutoffRank - targetSize;
      int eliminationParticipants = excess * 2;
      return 'Ön Eleme: $eliminationParticipants sporcu → $excess kazanan';
    }
  }

  String _getCombinationDescription(int targetSize) {
    if (_cutoffRank <= targetSize) {
      // Direkt hedef boyuta ulaşılabilir - Ana tablo başlangıcı
      return 'Ana Tablo Başlangıcı ($_cutoffRank sporcu)\n${_getMainTableMatches(targetSize)}';
    } else {
      // Eleme turu gerekli
      int excess = _cutoffRank - targetSize;
      int eliminationParticipants = excess * 2;
      int directQualifiers = _cutoffRank - eliminationParticipants;
      
      String description = 'Ön Eleme ($_cutoffRank → $targetSize sporcu)\n';
      description += _getEliminationMatches(directQualifiers + 1, _cutoffRank);
      description += '\n\nAna Tablo Başlangıcı ($targetSize sporcu)\n';
      description += _getMainTableMatches(targetSize);
      
      return description;
    }
  }
  
  String _getEliminationMatches(int start, int end) {
    List<String> matches = [];
    int matchCount = 1;
    
    // Case'lerdeki gibi eşleşmeler: en düşük vs en yüksek
    for (int i = start; i <= (start + end) ~/ 2; i++) {
      int opponent = end - (i - start);
      if (i < opponent) {
        matches.add('Maç $matchCount: $i vs $opponent');
        matchCount++;
      }
    }
    
    return matches.join('\n');
  }
  
  String _getMainTableMatches(int targetSize) {
    List<String> matches = [];
    int matchCount = 1;
    
    if (_cutoffRank <= targetSize) {
      // Direkt ana tablo - herkes dahil
      for (int i = 1; i <= targetSize ~/ 2; i++) {
        int opponent = targetSize - i + 1;
        if (i < opponent) {
          matches.add('Maç $matchCount: $i vs $opponent');
          matchCount++;
        }
      }
    } else {
      // Eleme sonrası ana tablo
      int excess = _cutoffRank - targetSize;
      int eliminationParticipants = excess * 2;
      int directQualifiers = _cutoffRank - eliminationParticipants;
      
      for (int i = 1; i <= targetSize ~/ 2; i++) {
        int opponent = targetSize - i + 1;
        if (i < opponent) {
          if (i <= directQualifiers && opponent <= directQualifiers) {
            // Her ikisi de direkt geçen
            matches.add('Maç $matchCount: $i vs $opponent');
          } else if (i <= directQualifiers) {
            // Birinci direkt geçen, ikinci eleme kazananı
            int winnerIndex = opponent - directQualifiers;
            matches.add('Maç $matchCount: $i vs W1_$winnerIndex');
          } else {
            // Her ikisi de eleme kazananı
            int winnerIndex1 = i - directQualifiers;
            int winnerIndex2 = opponent - directQualifiers;
            matches.add('Maç $matchCount: W1_$winnerIndex1 vs W1_$winnerIndex2');
          }
          matchCount++;
        }
      }
    }
    
    return matches.join('\n');
  }
  
  bool _isRecommendedTarget(int targetSize) {
    // En yakın küçük 2'nin kuvveti önerilen
    int previousPowerOfTwo = _getPreviousPowerOfTwo(_cutoffRank);
    return targetSize == previousPowerOfTwo;
  }
  
  int _getPreviousPowerOfTwo(int n) {
    if (n <= 1) return 1;
    
    int power = 1;
    while (power * 2 <= n) {
      power *= 2;
    }
    return power;
  }

  String _getBowTypeDisplayName(String bowType, AppLocalizations l10n) {
    switch (bowType) {
      case 'recurve':
        return l10n.recurveBow;
      case 'barebow':
        return l10n.barebowBow;
      case 'compound':
        return l10n.compoundBow;
      default:
        return bowType;
    }
  }


  void _saveSettings() {
    // Ayarları kaydetme mantığı
    Navigator.of(context).pop();
  }
}
