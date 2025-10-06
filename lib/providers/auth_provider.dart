import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  debugPrint('auth.provider: subscribing to auth state changes');
  return SupabaseConfig.client.auth.onAuthStateChange.map((data) {
    debugPrint('auth.provider: auth event=${data.event} user=${data.session?.user.id ?? 'null'}');
    return data.session?.user;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.client.auth.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
