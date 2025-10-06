import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';
import 'dart:async';

/// Returns a best-effort display name for the current user from the `profiles` table.
/// Prefers `first_name + last_name`, falls back to `visible_id`, otherwise empty string.
final profileDisplayNameProvider = FutureProvider<String>((ref) async {
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

/// Returns only the user's `first_name` for lightweight displays (like welcome banner).
/// Falls back to `visible_id` if `first_name` is missing, otherwise empty string.
final profileFirstNameProvider = FutureProvider<String>((ref) async {
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
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  try {
    // Step 1: fetch athlete ids linked to this coach and accepted
    final List<dynamic> links = await SupabaseConfig.client
        .from('athlete_coach')
        .select('athlete_id')
        .eq('coach_id', user.id)
        .eq('status', 'accepted');

    if (links.isEmpty) return [];

    final List<String> athleteIds = links
        .map((row) => (row['athlete_id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    // Step 2: fetch profiles for those athleteIds
    // Build IN list (no quotes for UUID ids)
    final String inList = '(${athleteIds.join(',')})';
    final List<dynamic> rawProfiles = await SupabaseConfig.client
        .from('profiles')
        .select('id, first_name, last_name, visible_id, photo_url, gender')
        .filter('id', 'in', inList)
        .order('first_name', ascending: true);

    // Step 3: If competitionId is provided, fetch classification info for each athlete
    Map<String, Map<String, dynamic>> athleteClassifications = {};
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
            .inFilter('user_id', athleteIds);

        for (final row in classificationRows) {
          final String? userId = row['user_id'] as String?;
          final Map<String, dynamic>? classification = row['classification'] as Map<String, dynamic>?;
          if (userId != null && classification != null) {
            athleteClassifications[userId] = classification;
          }
        }
      } catch (e) {
        // If classification fetch fails, continue without classification data
        // Silently continue without classification data
      }
    }

    // Client-side search filter to avoid server-side OR overriding IN
    String normalize(String input) {
      final String lower = input.toLowerCase();
      // Basic accent folding for Turkish and common Latin accents
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
      final String? athleteId = p['id'] as String?;
      final Map<String, dynamic>? classification = athleteId != null ? athleteClassifications[athleteId] : null;
      
      return {
        'athlete_id': athleteId,
        'first_name': p['first_name'] as String?,
        'last_name': p['last_name'] as String?,
        'visible_id': p['visible_id'] as String?,
        'photo_url': p['photo_url'] as String?,
        'gender': p['gender'] as String?,
        'classification': classification,
      };
    }).toList();

    if (search.isNotEmpty) {
      normalized = normalized.where((p) {
        final fn = normalize((p['first_name'] ?? '') as String);
        final ln = normalize((p['last_name'] ?? '') as String);
        final vi = normalize((p['visible_id'] ?? '') as String);
        return fn.contains(search) || ln.contains(search) || vi.contains(search);
      }).toList();
    }

    // Apply pagination after filtering
    final int start = params.offset.clamp(0, normalized.length);
    final int end = (params.offset + params.limit).clamp(0, normalized.length);
    return normalized.sublist(start, end);
  } catch (_) {
    return [];
  }
});


