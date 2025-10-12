import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class EliminationBracketScreen extends StatefulWidget {
  final String competitionId;
  final String competitionName;
  final Map<String, dynamic> eliminationSettings;

  const EliminationBracketScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
    required this.eliminationSettings,
  });

  @override
  State<EliminationBracketScreen> createState() => _EliminationBracketScreenState();
}

class _EliminationBracketScreenState extends State<EliminationBracketScreen> {
  int _currentRound = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _loadBracketData();
  }

  Future<void> _loadBracketData() async {
    setState(() {
      _isLoading = true;
    });

    // Simüle edilmiş veri - gerçek implementasyonda API'den gelecek
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _participants = _generateParticipants();
      _matches = _generateMatches();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eliminationBracketTitle),
        actions: [
          IconButton(
            onPressed: _loadBracketData,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text(l10n.eliminationSettings),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.exportResults),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        _buildHeader(l10n),
                        _buildRoundSelector(l10n),
                        Expanded(
                          child: _buildBracketContent(l10n),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.competitionName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatCard(l10n.totalParticipants, '${_participants.length}', Icons.people),
              const SizedBox(width: 16),
              _buildStatCard(l10n.activeMatches, '${_getActiveMatchesCount()}', Icons.sports_martial_arts),
              const SizedBox(width: 16),
              _buildStatCard(l10n.currentRound, '$_currentRound', Icons.timeline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundSelector(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalRounds = _calculateTotalRounds();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            l10n.round,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(totalRounds, (index) {
                  final roundNumber = index + 1;
                  final isSelected = _currentRound == roundNumber;
                  final isCompleted = _isRoundCompleted(roundNumber);
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$l10n.round $roundNumber'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _currentRound = roundNumber;
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
          ),
        ],
      ),
    );
  }

  Widget _buildBracketContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildBracketTree(l10n),
          const SizedBox(height: 24),
          _buildMatchList(l10n),
        ],
      ),
    );
  }

  Widget _buildBracketTree(AppLocalizations l10n) {
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
            Row(
              children: [
                Icon(Icons.account_tree, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.bracketTree,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBracketVisualization(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketVisualization(AppLocalizations l10n) {
    // Basit bracket görselleştirmesi
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.bracketVisualizationComingSoon,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bracketVisualizationSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchList(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentRoundMatches = _getMatchesForRound(_currentRound);
    
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
                Icon(Icons.sports_martial_arts, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.round} $_currentRound - ${l10n.matches}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentRoundMatches.isEmpty)
              _buildEmptyMatchesState(l10n)
            else
              ...currentRoundMatches.map((match) => _buildMatchCard(match, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMatchesState(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.sports_martial_arts_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMatchesInRound,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noMatchesInRoundSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = match['status'] as String;
    final participant1 = match['participant1'] as Map<String, dynamic>?;
    final participant2 = match['participant2'] as Map<String, dynamic>?;
    final winner = match['winner'] as String?;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = l10n.completed;
        break;
      case 'active':
        statusColor = colorScheme.primary;
        statusIcon = Icons.play_circle;
        statusText = l10n.active;
        break;
      case 'pending':
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.schedule;
        statusText = l10n.pending;
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.help;
        statusText = l10n.unknown;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: status == 'active' 
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
          width: status == 'active' ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (status == 'active')
                OutlinedButton.icon(
                  onPressed: () => _openMatchScoring(match),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(l10n.scoreMatch),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildParticipantInfo(
                  participant1,
                  winner == participant1?['id'],
                  l10n,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'VS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: _buildParticipantInfo(
                  participant2,
                  winner == participant2?['id'],
                  l10n,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantInfo(Map<String, dynamic>? participant, bool isWinner, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (participant == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.person_off, color: colorScheme.onSurfaceVariant, size: 24),
            const SizedBox(height: 4),
            Text(
              l10n.bye,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner 
            ? Colors.green.withOpacity(0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner 
              ? Colors.green
              : colorScheme.outline.withOpacity(0.2),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            Icon(Icons.emoji_events, color: Colors.green, size: 16),
          if (isWinner) const SizedBox(height: 4),
          Text(
            participant['name'] ?? l10n.unknown,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isWinner ? Colors.green : colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            participant['classification'] ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateParticipants() {
    // Simüle edilmiş katılımcı verisi
    return List.generate(16, (index) => {
      'id': 'participant_$index',
      'name': 'Sporcu ${index + 1}',
      'classification': 'Klasik Yay',
      'ranking': index + 1,
    });
  }

  List<Map<String, dynamic>> _generateMatches() {
    // Simüle edilmiş maç verisi
    return List.generate(8, (index) => {
      'id': 'match_$index',
      'round': 1,
      'status': index < 2 ? 'completed' : index < 4 ? 'active' : 'pending',
      'participant1': _participants[index * 2],
      'participant2': _participants[index * 2 + 1],
      'winner': index < 2 ? _participants[index * 2]['id'] : null,
    });
  }

  int _getActiveMatchesCount() {
    return _matches.where((match) => match['status'] == 'active').length;
  }

  int _calculateTotalRounds() {
    return 4; // Simüle edilmiş değer
  }

  bool _isRoundCompleted(int round) {
    return round < _currentRound;
  }

  List<Map<String, dynamic>> _getMatchesForRound(int round) {
    return _matches.where((match) => match['round'] == round).toList();
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'settings':
        // Ayarlar ekranına git
        break;
      case 'export':
        // Sonuçları dışa aktar
        break;
    }
  }

  void _openMatchScoring(Map<String, dynamic> match) {
    // Maç skor girişi ekranına git
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Placeholder(), // MatchScoringScreen gelecek
      ),
    );
  }
}
