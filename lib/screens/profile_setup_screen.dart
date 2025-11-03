import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_config.dart';
import '../providers/profile_providers.dart';
import 'home_shell.dart';
import 'login_screen.dart';

class ClubOption {
  final String id;
  final String name;
  final bool isIndividual;

  ClubOption({required this.id, required this.name, this.isIndividual = false});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  dynamic _selectedImage; // File or XFile depending on platform
  String? _currentPhotoUrl;

  String? _selectedRole;
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  bool _isLoading = false;
  bool _isLoadingClubs = false;

  String? _selectedCountry;
  String? _selectedCity;
  List<String> _availableCountries = [];
  List<String> _availableCities = [];
  List<ClubOption> _availableClubs = [];
  ClubOption? _selectedClub;

  // Dial codes map (subset for brevity, extend as needed)
  final Map<String, Map<String, String>> _countryCodes = const {
    'TR': {'code': '+90', 'flag': '🇹🇷', 'name': 'Turkey'},
    'US': {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
    'UK': {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
    'DE': {'code': '+49', 'flag': '🇩🇪', 'name': 'Germany'},
    'FR': {'code': '+33', 'flag': '🇫🇷', 'name': 'France'},
    'IT': {'code': '+39', 'flag': '🇮🇹', 'name': 'Italy'},
    'ES': {'code': '+34', 'flag': '🇪🇸', 'name': 'Spain'},
  };
  String _selectedDialIso = 'TR';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    await _loadCountries();
    try {
      final User? user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final dynamic existing = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted) return;
      
      if (existing != null) {
        setState(() {
          // Use existing profile data only
          _firstNameController.text = (existing['first_name'] ?? '').toString();
          _lastNameController.text = (existing['last_name'] ?? '').toString();
          _addressController.text = (existing['address'] ?? '').toString();
          final phone = (existing['phone_number'] ?? '').toString();
          _phoneController.text = phone.startsWith('+')
              ? phone.split(' ').skip(1).join(' ')
              : phone;
          _selectedRole = (existing['role'])?.toString();
          _selectedGender = (existing['gender'])?.toString();
          final dynamic birth = existing['birth_date'];
          if (birth is String && birth.isNotEmpty) {
            _selectedBirthDate = DateTime.tryParse(birth);
          }
          _selectedCountry = (existing['country'])?.toString();
          _selectedCity = (existing['city'])?.toString();
          _currentPhotoUrl = (existing['photo_url'])?.toString();
        });
        if (_selectedCountry != null) {
          await _loadCitiesForCountry(_selectedCountry!);
        }
        await _loadClubsForLocation(_selectedCountry, _selectedCity);
        if (mounted) {
          setState(() {
            if (existing['club_id'] != null) {
              final String id = existing['club_id'].toString();
              final ClubOption? found = _availableClubs.firstWhere(
                (c) => c.id == id,
                orElse: () => ClubOption(
                  id: id,
                  name: (existing['club_name'] ?? 'Club').toString(),
                ),
              );
              _selectedClub = found;
            } else {
              final l10n = AppLocalizations.of(context);
              _selectedClub = ClubOption(
                id: 'individual',
                name: l10n?.individualClub ?? '',
                isIndividual: true,
              );
            }
          });
        }
      } else {
        // No existing profile: default to Individual (No Club)
        final l10n = AppLocalizations.of(context);
        setState(() {
          _selectedClub = ClubOption(
            id: 'individual',
            name: l10n?.individualClub ?? '',
            isIndividual: true,
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _selectedClub = ClubOption(
          id: 'individual',
          name: l10n?.individualClub ?? '',
          isIndividual: true,
        );
      });
    }
  }

  Future<void> _loadCountries() async {
    try {
      final List<dynamic> rows = await SupabaseConfig.client
          .from('clubs')
          .select('country')
          .not('country', 'is', null);
      final countries = rows
          .map((e) => (e['country'] as String?)?.trim())
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      if (!mounted) return;
      setState(() {
        _availableCountries = countries;
      });
    } catch (e) {
      if (!mounted) return;
      _showNetworkAwareError(e);
    }
  }

  Future<void> _loadCitiesForCountry(String country) async {
    try {
      final List<dynamic> rows = await SupabaseConfig.client
          .from('clubs')
          .select('city')
          .eq('country', country)
          .not('city', 'is', null);
      final cities = rows
          .map((e) => (e['city'] as String?)?.trim())
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      if (!mounted) return;
      setState(() {
        _availableCities = cities;
      });
    } catch (e) {
      if (!mounted) return;
      _showNetworkAwareError(e);
    }
  }

  Future<void> _loadClubsForLocation(String? country, String? city) async {
    try {
      setState(() => _isLoadingClubs = true);
      var query = SupabaseConfig.client.from('clubs').select('club_id, club_name, country, city');
      if (country != null) {
        query = query.eq('country', country);
      }
      if (country != null && city != null) {
        query = query.eq('city', city);
      }
      final List<dynamic> rows = await query;
      final clubs = rows.map((e) => ClubOption(
            id: (e['club_id'] ?? e['id']).toString(),
            name: (e['club_name'] ?? e['name'] ?? 'Club').toString(),
          ));
      if (!mounted) return;
      setState(() {
        _availableClubs = clubs.toList();
        _isLoadingClubs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingClubs = false);
      _showNetworkAwareError(e);
    }
  }

  void _showNetworkAwareError(Object e) {
    final String msg = e.toString().toLowerCase();
    final l10n = AppLocalizations.of(context);
    final String text = (msg.contains('timeout') || msg.contains('connection'))
        ? (l10n?.networkError ?? 'Network error')
        : (l10n != null ? l10n.errorGeneric : 'Error: ${e.toString()}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        if (Platform.isAndroid || Platform.isIOS) {
          setState(() => _selectedImage = File(image.path));
        } else {
          setState(() => _selectedImage = image);
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n != null ? l10n.errorGeneric : 'Error: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadPhoto(String userId) async {
    if (_selectedImage == null) return null;
    try {
      final String path = 'profiles/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (_selectedImage is File) {
        await SupabaseConfig.client.storage.from('profile-photos').upload(
              path,
              _selectedImage as File,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else if (_selectedImage is XFile) {
        final bytes = await (_selectedImage as XFile).readAsBytes();
        await SupabaseConfig.client.storage.from('profile-photos').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true, contentType: 'image/jpeg'),
            );
      }
      final String publicUrl = SupabaseConfig.client.storage.from('profile-photos').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      _showNetworkAwareError(e);
      return null;
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.birthDateRequired)),
      );
      return;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.roleRequired)),
      );
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genderRequired)),
      );
      return;
    }

    // Show role warning dialog first, then save if confirmed
    final bool? shouldSave = await _showRoleWarningDialog();
    if (shouldSave == true) {
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    setState(() => _isLoading = true);
    try {
      final User? user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadPhoto(user.id);
      }

      String formattedPhone = _phoneController.text.trim();
      if (formattedPhone.isNotEmpty) {
        final dial = _countryCodes[_selectedDialIso]!['code']!;
        formattedPhone = '$dial $formattedPhone';
      } else {
        formattedPhone = '';
      }

      // Generate visible_id
      final String visibleId = await _generateVisibleId(
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
      );

      final payload = {
        'id': user.id,
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'role': _selectedRole,
        'gender': _selectedGender,
        'birth_date': _selectedBirthDate!.toIso8601String(),
        'address': _addressController.text.isNotEmpty ? _addressController.text : null,
        'phone_number': formattedPhone.isNotEmpty ? formattedPhone : null,
        'photo_url': photoUrl ?? _currentPhotoUrl,
        'club_id': (_selectedClub != null && !_selectedClub!.isIndividual) ? _selectedClub!.id : null,
        'city': (_selectedClub != null && !_selectedClub!.isIndividual) ? _selectedCity : null,
        'country': (_selectedClub != null && !_selectedClub!.isIndividual) ? _selectedCountry : null,
        'visible_id': visibleId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // upsert ensures idempotency
      await SupabaseConfig.client.from('profiles').upsert(payload);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdated)),
      );
      
      if (!mounted) return;
      // Invalidate the profile providers to trigger a refresh
      ref.invalidate(profileExistsProvider);
      ref.invalidate(profileFirstNameProvider);
      ref.invalidate(profileDisplayNameProvider);
      
      // Navigate to home shell with the new profile
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _generateVisibleId(String firstName, String lastName) async {
    try {
      // Get first letters and convert to lowercase
      final String firstInitial = firstName.isNotEmpty ? firstName[0].toLowerCase() : 'a';
      final String lastInitial = lastName.isNotEmpty ? lastName[0].toLowerCase() : 'a';
      final String baseId = '$firstInitial$lastInitial';

      // Query existing visible_ids that start with the same initials
      final List<dynamic> existingIds = await SupabaseConfig.client
          .from('profiles')
          .select('visible_id')
          .like('visible_id', '$baseId%')
          .not('visible_id', 'is', null);

      // Extract numbers from existing IDs and find the next available number
      int maxNumber = 0;
      for (final row in existingIds) {
        final String? visibleId = row['visible_id']?.toString();
        if (visibleId != null && visibleId.startsWith(baseId)) {
          final String numberPart = visibleId.substring(baseId.length);
          final int? number = int.tryParse(numberPart);
          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      // Generate the next sequential number
      final int nextNumber = maxNumber + 1;
      return '$baseId$nextNumber';
    } catch (e) {
      // Fallback: use timestamp if there's an error
      final String firstInitial = firstName.isNotEmpty ? firstName[0].toLowerCase() : 'a';
      final String lastInitial = lastName.isNotEmpty ? lastName[0].toLowerCase() : 'a';
      final int timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
      return '$firstInitial$lastInitial$timestamp';
    }
  }

  Future<void> _handleExit() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            l10n.exit,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Text(
            l10n.exitSetupConfirm,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.exit,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      // Sign out and navigate to login screen
      try {
        await SupabaseConfig.client.auth.signOut();
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        // Even if sign out fails, navigate to login screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  Future<bool?> _showRoleWarningDialog() async {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.roleWarningTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                  foregroundColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Close',
              ),
            ],
          ),
          content: Text(
            l10n.roleWarningMessage,
            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.7) : theme.primaryColor,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.understood,
                style: TextStyle(
                  color: isDark ? Colors.white : theme.primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool get _isFormComplete {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _selectedRole != null &&
        _selectedGender != null &&
        _selectedBirthDate != null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isLoading ? null : _handleExit,
          icon: const Icon(Icons.close),
          tooltip: l10n.exit,
        ),
        title: Text(l10n.setupProfile),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _submitForm,
            icon: Icon(
              Icons.save,
              color: _isLoading 
                  ? theme.iconTheme.color?.withOpacity(0.5)
                  : theme.iconTheme.color,
            ),
            tooltip: l10n.save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.all(constraints.maxWidth * 0.04 > 24 ? 24 : constraints.maxWidth * 0.04),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: _selectImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.scaffoldBackgroundColor,
                                      border: Border.all(color: theme.primaryColor, width: 2),
                                    ),
                                    child: (_selectedImage == null && _currentPhotoUrl == null)
                                        ? Icon(Icons.person_outline_rounded, size: 48, color: theme.primaryColor)
                                        : null,
                                  ),
                                  if (_selectedImage != null || _currentPhotoUrl != null)
                                    Positioned.fill(
                                      child: ClipOval(
                                        child: _selectedImage != null
                                            ? (_selectedImage is XFile
                                                ? Image.network((_selectedImage as XFile).path, fit: BoxFit.cover)
                                                : Image.file(_selectedImage as File, fit: BoxFit.cover))
                                            : Image.network(_currentPhotoUrl!, fit: BoxFit.cover),
                                      ),
                                    ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFormCard(context, isDark, l10n),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _submitForm,
                                icon: Icon(Icons.save),
                                label: Text(l10n.save),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _isLoading 
                                        ? (isDark 
                                            ? Colors.white.withOpacity(0.5)
                                            : theme.primaryColor.withOpacity(0.5))
                                        : (_isFormComplete && isDark
                                            ? Colors.white
                                            : theme.primaryColor), 
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: _isLoading
                                      ? (isDark 
                                          ? Colors.white.withOpacity(0.7)
                                          : theme.primaryColor.withOpacity(0.7))
                                      : (_isFormComplete && isDark
                                          ? Colors.white
                                          : theme.primaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDark, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildNameFields(context, isDark, l10n)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildOtherFields(context, isDark, l10n)),
                    ],
                  )
                : Column(
                    children: [
                      _buildNameFields(context, isDark, l10n),
                      const SizedBox(height: 16),
                      _buildOtherFields(context, isDark, l10n),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildNameFields(BuildContext context, bool isDark, AppLocalizations l10n) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: '${l10n.firstName} *',
            labelStyle: TextStyle(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (v) => v == null || v.isEmpty ? l10n.firstNameRequired : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: '${l10n.lastName} *',
            labelStyle: TextStyle(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (v) => v == null || v.isEmpty ? l10n.lastNameRequired : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: l10n.addressSimple,
            labelStyle: TextStyle(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(l10n.phoneNumber, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor)),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 520;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: constraints.maxWidth * 0.4, child: _buildDialCountryDropdown(context)),
                  const SizedBox(width: 12),
          Expanded(child: _buildPhoneField(context, isDark, l10n)),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialCountryDropdown(context),
                const SizedBox(height: 12),
                _buildPhoneField(context, isDark, l10n),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDialCountryDropdown(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hintTextColor = isDark ? Colors.white70 : theme.hintColor;
    final cardColor = isDark ? theme.colorScheme.surface : theme.cardColor;

    final entries = _countryCodes.entries.toList()
      ..sort((a, b) => a.value['name']!.compareTo(b.value['name']!));
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedDialIso,
        items: entries
            .map((e) => DropdownMenuItem<String>(
                  value: e.key,
                  child: Row(
                    children: [
                      Text(e.value['flag']!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${e.value['name']} (${e.value['code']})', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedDialIso = v ?? 'TR'),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        icon: Icon(Icons.arrow_drop_down, size: 24, color: hintTextColor),
        isExpanded: true,
        dropdownColor: cardColor,
        isDense: true,
        itemHeight: 50,
        menuMaxHeight: 500,
      ),
    );
  }

  Widget _buildPhoneField(BuildContext context, bool isDark, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final hintTextColor = isDark ? Colors.white70 : theme.hintColor;
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: l10n.phoneNumber,
        hintStyle: TextStyle(color: hintTextColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        prefixIcon: Icon(Icons.phone_outlined, color: hintTextColor),
      ),
    );
  }

  Widget _buildOtherFields(BuildContext context, bool isDark, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final hintTextColor = isDark ? Colors.white70 : theme.hintColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      children: [
        _buildRolePicker(context, isDark, l10n),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            labelText: '${l10n.gender} *',
            labelStyle: TextStyle(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: [
            DropdownMenuItem(value: 'male', child: Text(l10n.male, style: TextStyle(color: textColor))),
            DropdownMenuItem(value: 'female', child: Text(l10n.female, style: TextStyle(color: textColor))),
          ],
          onChanged: (v) => setState(() => _selectedGender = v),
          validator: (v) => v == null ? l10n.genderRequired : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 20, color: hintTextColor),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${l10n.birthDate} *', style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
                        const SizedBox(height: 4),
                      Text(
                        _selectedBirthDate != null
                            ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                            : l10n.dateNotSelected,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: _selectedBirthDate != null ? FontWeight.bold : FontWeight.normal,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: hintTextColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildClubSection(context, isDark, l10n),
      ],
    );
  }

  Widget _buildClubSection(BuildContext context, bool isDark, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final hintTextColor = isDark ? Colors.white70 : theme.hintColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? theme.colorScheme.surface : theme.cardColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_martial_arts_outlined, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text('${l10n.clubInfo} *', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
        value: _availableCountries.contains(_selectedCountry ?? '') ? _selectedCountry : null,
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l10n.allCountries, style: TextStyle(color: hintTextColor), overflow: TextOverflow.ellipsis)),
              ..._availableCountries.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c, style: TextStyle(color: textColor), overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) async {
              setState(() {
                _selectedCountry = v;
                _selectedCity = null;
                _selectedClub = null;
                _availableCities.clear();
                _availableClubs.clear();
              });
              if (v != null) {
                await _loadCitiesForCountry(v);
              }
            },
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: l10n.selectCountry,
              labelStyle: TextStyle(color: hintTextColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              prefixIcon: Icon(Icons.flag_outlined, color: hintTextColor),
            ),
            icon: Icon(Icons.arrow_drop_down, color: hintTextColor),
            dropdownColor: cardColor,
            isExpanded: true,
            menuMaxHeight: 200,
            isDense: true,
            itemHeight: 48,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
        value: _availableCities.contains(_selectedCity ?? '') ? _selectedCity : null,
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l10n.allCities, style: TextStyle(color: hintTextColor), overflow: TextOverflow.ellipsis)),
              ..._availableCities.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c, style: TextStyle(color: textColor), overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) async {
              setState(() {
                _selectedCity = v;
                _selectedClub = null;
                _availableClubs.clear();
              });
              await _loadClubsForLocation(_selectedCountry, v);
            },
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: l10n.selectCity,
              labelStyle: TextStyle(color: hintTextColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              prefixIcon: Icon(Icons.location_city_outlined, color: hintTextColor),
            ),
            icon: Icon(Icons.arrow_drop_down, color: hintTextColor),
            dropdownColor: cardColor,
            isExpanded: true,
            menuMaxHeight: 200,
            isDense: true,
            itemHeight: 48,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ClubOption?>(
                  value: _selectedClub,
                  onChanged: (v) => setState(() => _selectedClub = v),
                  decoration: InputDecoration(
                    labelText: l10n.selectClub,
                    labelStyle: TextStyle(color: hintTextColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    prefixIcon: Icon(Icons.sports_martial_arts_outlined, color: hintTextColor),
                    suffixIcon: _isLoadingClubs
                        ? Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                            ),
                          )
                        : null,
                  ),
                  items: [
                    DropdownMenuItem<ClubOption?>(
                      value: ClubOption(id: 'individual', name: l10n.individualClub, isIndividual: true),
                      child: Text(l10n.individualClub, style: TextStyle(color: textColor, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                    ..._availableClubs.map((c) => DropdownMenuItem<ClubOption?>(
                          value: c,
                          child: Text(c.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  icon: Icon(Icons.arrow_drop_down, color: hintTextColor),
                  dropdownColor: cardColor,
                  isExpanded: true,
                  menuMaxHeight: 300,
                  isDense: true,
                  itemHeight: 52,
                ),
              ),
              if (_selectedClub != null && !_selectedClub!.isIndividual)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedClub = ClubOption(id: 'individual', name: l10n.individualClub, isIndividual: true);
                        _selectedCountry = null;
                        _selectedCity = null;
                        _availableCities.clear();
                        _availableClubs.clear();
                      });
                    },
                    icon: Icon(Icons.close, color: theme.colorScheme.error, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: l10n.removeClub,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolePicker(BuildContext context, bool isDark, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('${l10n.role} *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildRoleOption(
                context: context,
                value: 'athlete',
                title: l10n.athlete,
                icon: Icons.sports_martial_arts_outlined,
                isDark: isDark,
                textColor: textColor,
                theme: theme,
              ),
              Divider(height: 1, color: theme.dividerColor),
              _buildRoleOption(
                context: context,
                value: 'coach',
                title: l10n.coach,
                icon: Icons.sports_outlined,
                isDark: isDark,
                textColor: textColor,
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required String value,
    required String title,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required ThemeData theme,
  }) {
    final isSelected = _selectedRole == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedRole = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark 
                  ? Colors.white.withOpacity(0.15)
                  : theme.primaryColor.withOpacity(0.15))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected 
              ? Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.5)
                      : theme.primaryColor.withOpacity(0.5),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (isDark ? Colors.white : theme.primaryColor)
                  : textColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected 
                      ? (isDark ? Colors.white : theme.primaryColor)
                      : textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? Colors.white : theme.primaryColor,
                size: 20,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: textColor.withOpacity(0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}


