import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';

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


