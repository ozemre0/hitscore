import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_config.dart';
import '../providers/google_signin_provider.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize Supabase to avoid client not initialized errors
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SupabaseConfig.initialize();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    setState(() => _isLoading = true);
    try {
      debugPrint('login.email: attempting signInWithPassword email=${_emailController.text.trim()}');
      final AuthResponse response = await SupabaseConfig.client.auth
          .signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = response.user;
      debugPrint('login.email: signInWithPassword user=${user?.id}');
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginErrorGeneric)),
        );
        return;
      }

      if (user.emailConfirmedAt == null) {
        showDialog<void>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(l10n.emailVerificationRequiredTitle),
              content: Text(l10n.emailVerificationLoginContent),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.emailVerificationRequiredOk),
                ),
              ],
            );
          },
        );
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.loginSuccessRedirectingShort),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 800),
          ),
        );

      // Return to root so the root (home:) rebuild shows the correct screen
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint('login.email: error=$e');
      if (!mounted) return;
      final String message;
      final String errorText = e.toString();
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      if (errorText.contains('Invalid login credentials') ||
          errorText.contains('400') ||
          errorText.contains('invalid_grant')) {
        message = l10n.loginErrorInvalidCredentials;
      } else {
        message = l10n.loginErrorGeneric;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 48),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                ),
                              )
                            : Text(l10n.loginButton),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer(
                      builder: (context, ref, _) {
                        // Authentication state provider will handle navigation automatically
                        // No need for manual navigation listener
                        final state = ref.watch(googleSignInProvider);
                        final isLoading = state.isLoading || _isGoogleLoading;
                        return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onPressed:
                              (_isLoading || isLoading) ? null : () async {
                            setState(() => _isGoogleLoading = true);
                            await ref
                                .read(googleSignInProvider.notifier)
                                .signIn();
                            // If sign-in succeeded, pop to root so root decides
                            try {
                              final u = SupabaseConfig.client.auth.currentUser;
                              if (u != null && mounted) {
                                debugPrint('login.google: success user=${u.id}, popping to root');
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            } catch (_) {}
                            if (mounted) {
                              setState(() => _isGoogleLoading = false);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: Image.asset(
                                    'assets/images/google.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.loginWithGoogle,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final state = ref.watch(googleSignInProvider);
                        return state.hasError
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: SelectableText.rich(
                                  TextSpan(
                                    text: l10n.loginErrorGoogle,
                                  ),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


