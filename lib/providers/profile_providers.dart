import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';
import 'auth_provider.dart';
import 'dart:async';

/// Returns a best-effort display name for the current user from the `profiles` table.
/// Prefers `first_name + last_name`, falls back to `visible_id`, otherwise empty string.
final profileDisplayNameProvider = FutureProvider<String>((ref) async {
  // Recompute whenever auth state changes (user switches, signs in/out)
  ref.watch(authStateProvider);
  final User? currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return '';

  try {
    final dynamic response = await SupabaseConfig.client
        .from('profiles')
        .select('first_name, last_name, visible_id')
        .eq('id', currentUser.id)
        .maybeSingle();

    if (response == null) return '';

    final String? firstName = (response['first_name'] as String?)?.trim();
    final String? lastName = (response['last_name'] as String?)?.trim();
    final String? visibleId = (response['visible_id'] as String?)?.trim();

    final bool hasFirst = firstName != null && firstName.isNotEmpty;
    final bool hasLast = lastName != null && lastName.isNotEmpty;

    if (hasFirst && hasLast) {
      return '$firstName $lastName';
    }
    if (hasFirst) {
      return firstName;
    }
    if (hasLast) {
      return lastName;
    }
    return visibleId ?? '';
  } catch (_) {
    // Surface no UI errors here; UI can show generic error if needed via other providers.
    return '';
  }
});

/// Checks if the current user has a profile in the database.
/// Returns true if profile exists, false if not, null if no user is authenticated.
final profileExistsProvider = FutureProvider<bool?>((ref) async {
  // Recompute whenever auth state changes
  ref.watch(authStateProvider);
  final User? currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return null;

  try {
    final dynamic response = await SupabaseConfig.client
        .from('profiles')
        .select('id')
        .eq('id', currentUser.id)
        .maybeSingle();
    
    return response != null;
  } catch (_) {
    return false;
  }
});

/// Returns only the user's `first_name` for lightweight displays (like welcome banner).
/// Falls back to `visible_id` if `first_name` is missing, otherwise empty string.
final profileFirstNameProvider = FutureProvider<String>((ref) async {
  // Recompute whenever auth state changes (user switches, signs in/out)
  ref.watch(authStateProvider);
  final User? currentUser = SupabaseConfig.client.auth.currentUser;
  if (currentUser == null) return '';

  try {
    final dynamic response = await SupabaseConfig.client
        .from('profiles')
        .select('first_name, visible_id')
        .eq('id', currentUser.id)
        .maybeSingle();

    if (response == null) return '';

    final String? firstName = (response['first_name'] as String?)?.trim();
    if (firstName != null && firstName.isNotEmpty) {
      return firstName;
    }
    final String? visibleId = (response['visible_id'] as String?)?.trim();
    return visibleId ?? '';
  } catch (_) {
    return '';
  }
});

/// Fetches the current coach's athletes with optional search term and pagination.
class CoachAthletesParams {
  final String search;
  final int limit;
  final int offset;
  final String? competitionId; // for eligibility checks later
  const CoachAthletesParams({this.search = '', this.limit = 20, this.offset = 0, this.competitionId});

  @override
  bool operator ==(Object other) {
    return other is CoachAthletesParams &&
        other.search == search &&
        other.limit == limit &&
        other.offset == offset &&
        other.competitionId == competitionId;
  }

  @override
  int get hashCode => Object.hash(search, limit, offset, competitionId);
}

final coachAthletesProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, CoachAthletesParams>((ref, params) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return [];

  // Debounce-like small delay if search to avoid spamming requests on fast typing
  if (params.search.isNotEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  try {
    // Step 1: (legacy) coach linked athletes — not used for listing when restricting to own club
    // Kept for potential future use but no longer included in candidateIds
    try {
      await SupabaseConfig.client
          .from('athlete_coach')
          .select('athlete_id')
          .eq('coach_id', user.id)
          .eq('status', 'accepted');
    } catch (_) {}

    // Step 2: fetch coach profile to get club_id
    String? coachClubId;
    try {
      final dynamic coachProfile = await SupabaseConfig.client
          .from('profiles')
          .select('club_id')
          .eq('id', user.id)
          .maybeSingle();
      coachClubId = coachProfile != null ? coachProfile['club_id'] as String? : null;
    } catch (_) {
      coachClubId = null;
    }

    // Step 3: fetch same-club profile ids (all roles)
    final List<String> sameClubAthleteIds = <String>[];
    if ((coachClubId ?? '').isNotEmpty) {
      try {
        final List<dynamic> sameClubRows = await SupabaseConfig.client
            .from('profiles')
            .select('id')
            .eq('club_id', coachClubId!);
        for (final row in sameClubRows) {
          final String? id = row['id'] as String?;
          if (id != null && id.isNotEmpty && id != user.id) {
            sameClubAthleteIds.add(id);
          }
        }
      } catch (_) {
        // ignore club fetch errors; proceed with linked athletes only
      }
    }

    // Step 4: restrict to only same-club users
    final List<String> candidateIds = sameClubAthleteIds.toSet().toList();
    if (candidateIds.isEmpty) return [];

    // Step 5: fetch profiles for candidate ids
    // If there is a search term, push filtering to the server to reduce payload
    List<dynamic> rawProfiles;
    if (params.search.trim().isNotEmpty) {
      final String q = params.search.trim();
      rawProfiles = await SupabaseConfig.client
          .from('profiles')
          .select('id, first_name, last_name, visible_id, photo_url, gender')
          .eq('club_id', coachClubId!)
          .or('first_name.ilike.%$q%,last_name.ilike.%$q%,visible_id.ilike.%$q%')
          .order('first_name', ascending: true);
      // Still restrict to candidateIds in memory to be safe
      final Set<String> idSet = candidateIds.toSet();
      rawProfiles = rawProfiles.where((p) => idSet.contains(p['id'] as String? ?? '')).toList();
    } else {
      final String inList = '(${candidateIds.join(',')})';
      rawProfiles = await SupabaseConfig.client
          .from('profiles')
          .select('id, first_name, last_name, visible_id, photo_url, gender')
          .filter('id', 'in', inList)
          .order('first_name', ascending: true);
    }

    // Step 6: If competitionId is provided, fetch classification info for each candidate
    Map<String, Map<String, dynamic>> classificationByUserId = {};
    if (params.competitionId != null && params.competitionId!.isNotEmpty) {
      try {
        final List<dynamic> classificationRows = await SupabaseConfig.client
            .from('organized_competition_participants')
            .select('''
              user_id,
              classification:organized_competitions_classifications!inner(
                id,
                name,
                bow_type,
                environment,
                gender,
                age_group_id,
                age_groups:age_groups(age_group_tr, age_group_en)
              )
            ''')
            .eq('organized_competition_id', params.competitionId!)
            .inFilter('user_id', candidateIds);

        for (final row in classificationRows) {
          final String? userId = row['user_id'] as String?;
          final Map<String, dynamic>? classification = row['classification'] as Map<String, dynamic>?;
          if (userId != null && classification != null) {
            classificationByUserId[userId] = classification;
          }
        }
      } catch (_) {
        // continue without classification data on error
      }
    }

    // Client-side search filter to avoid server-side OR overriding IN
    String normalize(String input) {
      final String lower = input.toLowerCase();
      return lower
          .replaceAll('ı', 'i')
          .replaceAll('İ', 'i')
          .replaceAll('ş', 's')
          .replaceAll('Ş', 's')
          .replaceAll('ğ', 'g')
          .replaceAll('Ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('Ü', 'u')
          .replaceAll('ö', 'o')
          .replaceAll('Ö', 'o')
          .replaceAll('ç', 'c')
          .replaceAll('Ç', 'c')
          .replaceAll(RegExp('[áàâä]'), 'a')
          .replaceAll(RegExp('[éèêë]'), 'e')
          .replaceAll(RegExp('[íìîï]'), 'i')
          .replaceAll(RegExp('[óòôö]'), 'o')
          .replaceAll(RegExp('[úùûü]'), 'u')
          .replaceAll(RegExp('[ñ]'), 'n');
    }

    final String search = normalize(params.search.trim());
    List<Map<String, dynamic>> normalized = rawProfiles.map<Map<String, dynamic>>((p) {
      final String? uid = p['id'] as String?;
      final Map<String, dynamic>? classification = uid != null ? classificationByUserId[uid] : null;
      return {
        // keep expected key for UI
        'id': uid,
        // keep legacy key for any other callers
        'athlete_id': uid,
        'first_name': p['first_name'] as String?,
        'last_name': p['last_name'] as String?,
        'visible_id': p['visible_id'] as String?,
        'photo_url': p['photo_url'] as String?,
        'gender': p['gender'] as String?,
        'classification': classification,
      };
    }).toList();

    // Client-side filter becomes no-op when server-side search already applied
    if (search.isNotEmpty) {
      normalized = normalized.where((p) {
        final fn = normalize((p['first_name'] ?? '') as String);
        final ln = normalize((p['last_name'] ?? '') as String);
        final vi = normalize((p['visible_id'] ?? '') as String);
        return fn.contains(search) || ln.contains(search) || vi.contains(search);
      }).toList();
    }

    // Apply pagination after filtering (limit <= 0 means no limit)
    if (params.limit <= 0) {
      return normalized;
    }
    final int start = params.offset.clamp(0, normalized.length);
    final int end = (params.offset + params.limit).clamp(0, normalized.length);
    return normalized.sublist(start, end);
  } catch (_) {
    return [];
  }
});


