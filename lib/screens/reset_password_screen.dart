import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordReset = false;
  String? _userEmail;
  String? _resetToken;
  bool _isValidToken = false;
  bool _isCheckingToken = true;

  @override
  void initState() {
    super.initState();
    _checkResetToken();
  }

  Future<void> _checkResetToken() async {
    try {
      // URL'den token ve email bilgilerini al
      final currentUrl = Uri.base.toString();
      final uri = Uri.parse(currentUrl);
      
      debugPrint('[DEBUG] Current URL: $currentUrl');
      debugPrint('[DEBUG] URI Path: ${uri.path}');
      debugPrint('[DEBUG] URI Query: ${uri.query}');
      
      // URL'den token ve email parametrelerini al
      _resetToken = uri.queryParameters['token'] ?? uri.queryParameters['access_token'];
      _userEmail = uri.queryParameters['email'];
      
      debugPrint('[DEBUG] Reset Token: $_resetToken');
      debugPrint('[DEBUG] Reset Token Length: ${_resetToken?.length ?? 0}');
      debugPrint('[DEBUG] User Email: $_userEmail');
      debugPrint('[DEBUG] Full URL: $currentUrl');
      debugPrint('[DEBUG] Query Parameters: ${uri.queryParameters}');
      debugPrint('[DEBUG] Token First 10 chars: ${_resetToken?.substring(0, _resetToken!.length > 10 ? 10 : _resetToken!.length)}');
      debugPrint('[DEBUG] Token Last 10 chars: ${_resetToken?.substring(_resetToken!.length > 10 ? _resetToken!.length - 10 : 0)}');
      debugPrint('[DEBUG] Current Time: ${DateTime.now().toIso8601String()}');
      
      // Token yoksa veya email yoksa hata göster
      if (_resetToken == null || _userEmail == null) {
        if (mounted) {
          setState(() {
            _isValidToken = false;
            _isCheckingToken = false;
          });
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.invalidResetLink),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }
      
      // Token'ı Supabase ile doğrula
      try {
        final response = await SupabaseConfig.client.auth.verifyOTP(
          type: OtpType.recovery,
          token: _resetToken!,
          email: _userEmail!,
        );
        
        if (response.user != null) {
          debugPrint('[DEBUG] Token verified successfully for user: ${response.user!.email}');
          if (mounted) {
            setState(() {
              _isValidToken = true;
              _isCheckingToken = false;
            });
          }
        }
      } catch (e) {
        debugPrint('[DEBUG] Token verification failed: $e');
        if (mounted) {
          setState(() {
            _isValidToken = false;
            _isCheckingToken = false;
          });
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.invalidResetLink),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[DEBUG] Error checking reset token: $e');
      if (mounted) {
        setState(() {
          _isValidToken = false;
          _isCheckingToken = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordMismatch),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidToken || _resetToken == null || _userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.invalidResetLink),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
 
    try {
      // OTP token daha önce _checkResetToken içinde doğrulandı ve session oluşturuldu.
      // Token tek kullanımlık olduğundan burada TEKRAR verifyOTP çağırmıyoruz.
      // Sadece şifreyi güncelliyoruz.
      debugPrint('[DEBUG] Updating password for email: $_userEmail');
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
        ),
      );
      debugPrint('[DEBUG] Password updated successfully');

      // Başarılı olduysa state'i güncelle
      if (mounted) {
        setState(() => _isPasswordReset = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passwordResetSuccess),
            backgroundColor: Colors.green,
          ),
        );

        // 2 saniye sonra login sayfasına yönlendir
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[DEBUG] Password reset error: $e');
      debugPrint('[DEBUG] Error type: ${e.runtimeType}');
      
      if (mounted) {
        String errorMessage;
        
        // Hata tipine göre lokalize mesaj seç
        if (e.toString().contains('Token has expired') || e.toString().contains('otp_expired')) {
          errorMessage = l10n.tokenExpired;
        } else if (e.toString().contains('Invalid OTP') || e.toString().contains('invalid_grant') || e.toString().contains('Token has expired')) {
          errorMessage = l10n.invalidResetLink;
        } else if (e.toString().contains('Password should be at least')) {
          errorMessage = l10n.passwordTooShort;
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          errorMessage = l10n.networkError;
        } else {
          errorMessage = '${l10n.passwordResetError}: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 6),
                SelectableText.rich(
                  TextSpan(text: l10n.error(e.toString())),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: l10n.backToLogin,
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    
    // Token kontrol ediliyor
    if (_isCheckingToken) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                l10n.processingAuthentication,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Token geçersiz
    if (!_isValidToken) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.resetPasswordTitle),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.invalidResetLink,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.invalidResetLinkDescription,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Text(l10n.backToLogin),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_isPasswordReset) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.passwordResetSuccess,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.redirectingToLogin,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPasswordTitle),
        automaticallyImplyLeading: false,
      ),
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.resetPasswordNewPasswordTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Email bilgisini göster (değiştirilemez)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[850]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.emailLabel,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    _userEmail ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Token süresi uyarısı
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.tokenExpiryWarning,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.resetPasswordNewPasswordDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.newPasswordLabel,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (value.length < 6) {
                            return l10n.passwordTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.confirmPasswordRequired;
                          }
                          if (value != _passwordController.text) {
                            return l10n.passwordMismatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                              : Text(l10n.resetPasswordButton),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
