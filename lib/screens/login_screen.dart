import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_screen.dart';
import '../services/supabase_config.dart';
import 'home_shell.dart';
import '../providers/google_signin_provider.dart';

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
      final AuthResponse response = await SupabaseConfig.client.auth
          .signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = response.user;
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

      // Navigate to HomeScreen after successful login
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeShell(),
        ),
      );
    } catch (e) {
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

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    setState(() => _isGoogleLoading = true);
    try {
      // Web: Supabase OAuth; Mobile: use google_sign_in package
      if (SupabaseConfig.client.auth.currentSession == null) {
        // proceed regardless; session will be set by auth call
      }

      // Use Supabase OAuth which handles web and can accept native tokens via provider flow if configured
      final bool result = await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        queryParams: const {'prompt': 'select_account'},
      );
      if (!mounted) return;
      if (result) {
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
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginErrorGeneric)),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
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
                        ref.listen<AsyncValue<User?>>(googleSignInProvider,
                            (prev, next) async {
                          next.whenOrNull(data: (user) async {
                            if (user != null && context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const HomeShell(),
                                ),
                              );
                            }
                          });
                        });
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


