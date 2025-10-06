import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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
      debugPrint('google.signin: web platform, using Supabase OAuth flow');
      return;
    }
    debugPrint('google.signin: initializing GoogleSignIn (isIOS=${Platform.isIOS})');
    _googleSignIn = GoogleSignIn(
      // For Android, you typically leave clientId null and set only serverClientId
      clientId: Platform.isIOS
          ? '871385916265-o1noqvi90qrdnb4k5q8lapo8qn67lihs.apps.googleusercontent.com'
          : null,
      serverClientId: GoogleOAuthConfig.androidServerClientId,
      scopes: const ['email', 'profile'],
    );
  }

  Future<void> signIn() async {
    if (kIsWeb) {
      state = const AsyncValue.loading();
      try {
        debugPrint('google.signin: starting web OAuth');
        final bool response = await SupabaseConfig.client.auth.signInWithOAuth(
          OAuthProvider.google,
          queryParams: const {'prompt': 'select_account'},
        );
        if (response) {
          debugPrint('google.signin: web OAuth returned true');
          state = const AsyncValue.data(null);
        } else {
          debugPrint('google.signin: web OAuth returned false');
          state = const AsyncValue.data(null);
        }
      } catch (error, stackTrace) {
        debugPrint('google.signin: web OAuth error=$error');
        state = AsyncValue.error(error, stackTrace);
      }
      return;
    }

    state = const AsyncValue.loading();
    try {
      debugPrint('google.signin: signing out previous session from GoogleSignIn');
      await _googleSignIn.signOut();
      debugPrint('google.signin: prompting account selection');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('google.signin: user cancelled Google sign-in');
        state = const AsyncValue.data(null);
        return;
      }

      debugPrint('google.signin: got Google account: ${googleUser.id}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('google.signin: got tokens, idToken?=${googleAuth.idToken != null}');
      final AuthResponse response = await SupabaseConfig.client.auth
          .signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      debugPrint('google.signin: Supabase signInWithIdToken user=${response.user?.id}');
      state = AsyncValue.data(response.user);
    } catch (error, stackTrace) {
      debugPrint('google.signin: error=$error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    debugPrint('google.signin: signOut called');
    if (kIsWeb) {
      await SupabaseConfig.client.auth.signOut();
    } else {
      await _googleSignIn.signOut();
      await SupabaseConfig.client.auth.signOut();
    }
    debugPrint('google.signin: signOut completed');
    state = const AsyncValue.data(null);
  }
}


