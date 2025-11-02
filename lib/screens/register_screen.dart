import 'package:flutter/material.dart';
import '../services/supabase_config.dart';
import 'login_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _showEmailVerificationDialog() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.emailVerificationRequiredTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.emailVerificationRequiredContent),
            ],
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(l10n.emailVerificationRequiredOk),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (email.isEmpty) {
      _showSnackBar(l10n.emailRequired, isError: true);
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar(l10n.loginErrorInvalidCredentials, isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(l10n.passwordTooShort, isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar(l10n.passwordMismatch, isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb 
            ? 'https://hitarchery.com/confirm_signup' 
            : 'io.supabase.archeryozs://login-callback',
      );
      if (response.user != null) {
        // If identities is empty, Supabase indicates the email is already registered
        final identities = response.user!.identities;
        final isAlreadyRegistered = identities == null || identities.isEmpty;
        if (mounted) {
          if (isAlreadyRegistered) {
            _showEmailAlreadyRegisteredDialog();
          } else {
            _showEmailVerificationDialog();
          }
        }
      }
    } catch (e) {
      // Log the detailed error for debugging
      debugPrint('Sign up error: ${e.toString()}');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('weak') || errorStr.contains('authweakpassword') || errorStr.contains('at least 6')) {
          _showSnackBar(l10n.passwordTooShort, isError: true);
        } else if (errorStr.contains('network') || errorStr.contains('connection')) {
          _showSnackBar(l10n.networkError, isError: true);
        } else if (errorStr.contains('too many requests') || errorStr.contains('rate limit')) {
          _showSnackBar(l10n.tooManyRequests, isError: true);
        } else if (errorStr.contains('invalid email')) {
          _showSnackBar(l10n.loginErrorInvalidCredentials, isError: true);
        } else {
          _showSnackBar(l10n.loginErrorGeneric, isError: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEmailAlreadyRegisteredDialog() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.emailAlreadyRegisteredTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.emailAlreadyRegisteredMessage),
            ],
          ),
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.emailVerificationRequiredOk),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(l10n.goToLogin),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
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
                  children: [
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
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPasswordLabel,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_add_alt_1_outlined),
                                  const SizedBox(width: 8),
                                  Text(l10n.register),
                                ],
                              ),
                      ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
