import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../providers/competitions_providers.dart';
import 'competition_participants_screen.dart';

class CompetitionArchiveScreen extends ConsumerWidget {
  const CompetitionArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.competitionArchiveTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: _ArchiveBody(l10n: l10n),
            ),
          );
        },
      ),
    );
  }
}

class _ArchiveBody extends ConsumerWidget {
  final AppLocalizations l10n;
  const _ArchiveBody({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final competitionsAsync = ref.watch(competitionArchiveProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: competitionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => SelectableText.rich(
              TextSpan(text: err.toString()),
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            data: (list) {
              if (list.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      l10n.competitionArchiveEmptyTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.competitionArchiveEmptyDesc,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  final title = (item['name'] as String?) ?? l10n.untitledCompetition;
                  final competitionId = item['organized_competition_id'] as String?;
                  final startRaw = item['start_date'] as String?;
                  String? formattedDate;
                  if (startRaw != null) {
                    try {
                      final dt = DateTime.parse(startRaw).toLocal();
                      formattedDate = DateFormat('dd.MM.yyyy').format(dt);
                    } catch (_) {
                      formattedDate = null;
                    }
                  }
                  // Determine if we should show a date header (when day changes)
                  String? prevFormattedDate;
                  if (index > 0) {
                    final prev = list[index - 1];
                    final prevRaw = prev['start_date'] as String?;
                    if (prevRaw != null) {
                      try {
                        final pdt = DateTime.parse(prevRaw).toLocal();
                        prevFormattedDate = DateFormat('dd.MM.yyyy').format(pdt);
                      } catch (_) {
                        prevFormattedDate = null;
                      }
                    }
                  }

                  final bool showHeader = index == 0
                      ? (formattedDate != null)
                      : (formattedDate != null && formattedDate != prevFormattedDate);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeader) ...[
                        if (index != 0) const Divider(height: 24),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                          child: Text(
                            formattedDate,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          // No date subtitle inside the card; dates are shown in group headers
                          onTap: competitionId == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => CompetitionParticipantsScreen(
                                        competitionId: competitionId,
                                        competitionName: title,
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}


