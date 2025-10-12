import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class EliminationStatusScreen extends StatefulWidget {
  final String competitionId;
  final String competitionName;
  final String participantId;

  const EliminationStatusScreen({
    super.key,
    required this.competitionId,
    required this.competitionName,
    required this.participantId,
  });

  @override
  State<EliminationStatusScreen> createState() => _EliminationStatusScreenState();
}

class _EliminationStatusScreenState extends State<EliminationStatusScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _eliminationStatus;
  List<Map<String, dynamic>> _myMatches = [];

  @override
  void initState() {
    super.initState();
    _loadEliminationStatus();
  }

  Future<void> _loadEliminationStatus() async {
    setState(() {
      _isLoading = true;
    });

    // Simüle edilmiş veri - gerçek implementasyonda API'den gelecek
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _eliminationStatus = _generateStatus();
      _myMatches = _generateMyMatches();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eliminationStatusTitle),
        actions: [
          IconButton(
            onPressed: _loadEliminationStatus,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadEliminationStatus,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatusCard(l10n),
                            const SizedBox(height: 16),
                            _buildCurrentPositionCard(l10n),
                            const SizedBox(height: 16),
                            _buildNextMatchCard(l10n),
                            const SizedBox(height: 16),
                            _buildMyMatchesCard(l10n),
                            const SizedBox(height: 16),
                            _buildStatisticsCard(l10n),
                          ],
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = _eliminationStatus?['status'] ?? 'active';
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'active':
        statusColor = colorScheme.primary;
        statusIcon = Icons.play_circle;
        statusText = l10n.statusActive;
        break;
      case 'eliminated':
        statusColor = colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = l10n.statusEliminated;
        break;
      case 'champion':
        statusColor = Colors.amber;
        statusIcon = Icons.emoji_events;
        statusText = l10n.statusChampion;
        break;
      default:
        statusColor = colorScheme.onSurfaceVariant;
        statusIcon = Icons.help;
        statusText = l10n.statusUnknown;
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(statusIcon, color: statusColor, size: 48),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.competitionName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPositionCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentRound = _eliminationStatus?['currentRound'] ?? 1;
    final position = _eliminationStatus?['position'] ?? '-';
    final isBye = _eliminationStatus?['hasBye'] ?? false;
    
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
                Icon(Icons.location_on, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.currentPosition,
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
                  child: _buildPositionInfoTile(
                    l10n.round,
                    '$currentRound',
                    Icons.timeline,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPositionInfoTile(
                    l10n.bracketPosition,
                    '$position',
                    Icons.place,
                    colorScheme,
                  ),
                ),
              ],
            ),
            if (isBye) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.byeStatusMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInfoTile(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
    );
  }

  Widget _buildNextMatchCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final nextMatch = _eliminationStatus?['nextMatch'] as Map<String, dynamic>?;
    
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
                Icon(Icons.sports_martial_arts, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.nextMatch,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (nextMatch != null)
              _buildMatchInfo(nextMatch, l10n)
            else
              _buildNoNextMatch(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchInfo(Map<String, dynamic> match, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final opponent = match['opponent'] as Map<String, dynamic>?;
    final scheduledTime = match['scheduledTime'] as String?;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Icon(Icons.person, color: colorScheme.primary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    l10n.you,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
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
              const SizedBox(width: 24),
              Column(
                children: [
                  Icon(Icons.person_outline, color: colorScheme.secondary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    opponent?['name'] ?? l10n.tbd,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (scheduledTime != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: colorScheme.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              Text(
                '$l10n.scheduledTime: $scheduledTime',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNoNextMatch(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noUpcomingMatch,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMyMatchesCard(AppLocalizations l10n) {
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
                Icon(Icons.history, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.myMatches,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_myMatches.isEmpty)
              _buildEmptyMatchesState(l10n)
            else
              ..._myMatches.map((match) => _buildMatchHistoryTile(match, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMatchesState(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.sports_martial_arts_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noMatchHistory,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryTile(Map<String, dynamic> match, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final opponent = match['opponent'] as Map<String, dynamic>?;
    final result = match['result'] as String;
    final score = match['score'] as String?;
    final round = match['round'] as int;
    
    final isWin = result == 'win';
    final resultColor = isWin ? Colors.green : Colors.red;
    final resultIcon = isWin ? Icons.check_circle : Icons.cancel;
    final resultText = isWin ? l10n.victory : l10n.defeat;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: resultColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: resultColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(resultIcon, color: resultColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$l10n.round $round',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$resultText vs ${opponent?['name'] ?? l10n.unknown}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (score != null)
                  Text(
                    score,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final stats = _eliminationStatus?['statistics'] as Map<String, dynamic>? ?? {};
    
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
                Icon(Icons.bar_chart, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.statistics,
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
                  child: _buildStatTile(
                    l10n.matchesPlayed,
                    '${stats['matchesPlayed'] ?? 0}',
                    Icons.sports_martial_arts,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatTile(
                    l10n.wins,
                    '${stats['wins'] ?? 0}',
                    Icons.emoji_events,
                    colorScheme,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatTile(
                    l10n.losses,
                    '${stats['losses'] ?? 0}',
                    Icons.trending_down,
                    colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _generateStatus() {
    // Simüle edilmiş durum verisi
    return {
      'status': 'active',
      'currentRound': 2,
      'position': 'A-4',
      'hasBye': false,
      'nextMatch': {
        'opponent': {'name': 'Sporcu 8', 'classification': 'Klasik Yay'},
        'scheduledTime': '14:30',
      },
      'statistics': {
        'matchesPlayed': 2,
        'wins': 2,
        'losses': 0,
      },
    };
  }

  List<Map<String, dynamic>> _generateMyMatches() {
    // Simüle edilmiş maç geçmişi
    return [
      {
        'round': 1,
        'opponent': {'name': 'Sporcu 16'},
        'result': 'win',
        'score': '6-2',
      },
      {
        'round': 2,
        'opponent': {'name': 'Sporcu 5'},
        'result': 'win',
        'score': '6-4',
      },
    ];
  }
}

