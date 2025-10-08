import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';
import 'auth_provider.dart';

/// Provides archived competitions for the current user.
///
/// A competition is considered "archived" if it is associated with the
/// current user via `organized_competition_participants` and has a
/// non-null `start_date`. We return a normalized, UI-friendly list of maps.
final competitionArchiveProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Recompute when auth state changes so archive updates on sign in/out
  ref.watch(authStateProvider);

  final User? currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return <Map<String, dynamic>>[];

  try {
    // Fetch competitions the user is a participant of, joined with competition fields
    final List<dynamic> rows = await SupabaseConfig.client
        .from('organized_competition_participants')
        .select('''
          organized_competition_id,
          competition:organized_competitions(
            organized_competition_id,
            name,
            start_date
          )
        ''')
        .eq('user_id', currentUser.id);

    // Normalize data to a flat structure expected by the UI
    final List<Map<String, dynamic>> normalized = <Map<String, dynamic>>[];
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final Map<String, dynamic>? comp = row['competition'] as Map<String, dynamic>?;
      if (comp == null) continue;
      normalized.add(<String, dynamic>{
        'organized_competition_id': comp['organized_competition_id'] as String?,
        'name': comp['name'] as String?,
        'start_date': comp['start_date'] as String?,
      });
    }

    // Sort by start_date descending (most recent first)
    int safeCompare(String? a, String? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1; // nulls last
      if (b == null) return -1;
      try {
        final DateTime ad = DateTime.parse(a).toUtc();
        final DateTime bd = DateTime.parse(b).toUtc();
        return bd.compareTo(ad);
      } catch (_) {
        return 0;
      }
    }

    normalized.sort((m1, m2) => safeCompare(m1['start_date'] as String?, m2['start_date'] as String?));

    return normalized;
  } catch (e, st) {
    debugPrint('[competitionArchiveProvider] error: $e');
    debugPrint(st.toString());
    // Surface an empty list on error; UI shows error via AsyncValue.error if thrown.
    // We choose to return [] to avoid breaking UI flows; adjust if needed.
    return <Map<String, dynamic>>[];
  }
});

/// Provides all competitions for the archive screen.
/// Fetches all competitions (active, completed, draft) sorted by date.
final allCompetitionsArchiveProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Recompute when auth state changes
  ref.watch(authStateProvider);

  try {
    // Fetch all competitions with their details
    final List<dynamic> rows = await SupabaseConfig.client
        .from('organized_competitions')
        .select('''
          organized_competition_id,
          name,
          description,
          start_date,
          end_date,
          status,
          registration_allowed,
          score_allowed,
          competition_visible_id,
          created_at,
          created_by,
          organizer_ids
        ''')
        .eq('is_deleted', false)
        .order('start_date', ascending: false);

    final List<Map<String, dynamic>> competitions = List<Map<String, dynamic>>.from(rows);
    
    // Sort by start_date descending (most recent first)
    competitions.sort((a, b) {
      final String? dateA = a['start_date'] as String?;
      final String? dateB = b['start_date'] as String?;
      
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1; // nulls last
      if (dateB == null) return -1;
      
      try {
        final DateTime dateTimeA = DateTime.parse(dateA).toUtc();
        final DateTime dateTimeB = DateTime.parse(dateB).toUtc();
        return dateTimeB.compareTo(dateTimeA);
      } catch (_) {
        return 0;
      }
    });

    return competitions;
  } catch (e, st) {
    debugPrint('[allCompetitionsArchiveProvider] error: $e');
    debugPrint(st.toString());
    return <Map<String, dynamic>>[];
  }
});


