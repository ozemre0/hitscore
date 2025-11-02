import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/supabase_config.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  Future<void> _sendResetEmail() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      _showSnackBar(l10n.emailRequired, isError: true);
      return;
    }

    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar(l10n.loginErrorInvalidCredentials, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb 
            ? 'https://hitarchery.com/reset-password' 
            : 'io.supabase.archeryozs://reset-password',
      );

      if (mounted) {
        setState(() => _isEmailSent = true);
        _showSnackBar(l10n.resetLinkSent);
      }
    } catch (e) {
      debugPrint('Reset password error: ${e.toString()}');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('network') || errorStr.contains('connection')) {
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
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    if (_isEmailSent) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.forgotPasswordTitle),
          automaticallyImplyLeading: false,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mark_email_read,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.resetLinkSent,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.forgotPasswordDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                          child: Text(l10n.backToLogin),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
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
                    Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.forgotPasswordTitle,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.forgotPasswordDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _sendResetEmail,
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Text(l10n.sendResetLink),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pop(context);
                        },
                        child: Text(l10n.backToLogin),
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
    super.dispose();
  }
}
