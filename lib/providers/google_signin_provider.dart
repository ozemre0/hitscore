import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';
import '../services/google_oauth_config.dart';

final googleSignInProvider =
    StateNotifierProvider<GoogleSignInNotifier, AsyncValue<User?>>((ref) {
  return GoogleSignInNotifier();
});

class GoogleSignInNotifier extends StateNotifier<AsyncValue<User?>> {
  GoogleSignInNotifier() : super(const AsyncValue.data(null)) {
    _initializeGoogleSignIn();
  }

  late GoogleSignIn _googleSignIn;

  void _initializeGoogleSignIn() {
    if (kIsWeb) {
      return;
    }
    _googleSignIn = GoogleSignIn(
      // For Android, you typically leave clientId null and set only serverClientId
      clientId: Platform.isIOS
          ? '871385916265-ulcv6rj22kqhp8aatlvb52m03kh4r7rn.apps.googleusercontent.com'
          : null,
      serverClientId: GoogleOAuthConfig.androidServerClientId,
      scopes: const ['email', 'profile'],
    );
  }

  Future<void> signIn() async {
    if (kIsWeb) {
      state = const AsyncValue.loading();
      try {
        final bool response = await SupabaseConfig.client.auth.signInWithOAuth(
          OAuthProvider.google,
          queryParams: const {'prompt': 'select_account'},
        );
        if (response) {
          state = const AsyncValue.data(null);
        } else {
          state = const AsyncValue.data(null);
        }
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      }
      return;
    }

    state = const AsyncValue.loading();
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthResponse response = await SupabaseConfig.client.auth
          .signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      state = AsyncValue.data(response.user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      await SupabaseConfig.client.auth.signOut();
    } else {
      await _googleSignIn.signOut();
      await SupabaseConfig.client.auth.signOut();
    }
    state = const AsyncValue.data(null);
  }
}


