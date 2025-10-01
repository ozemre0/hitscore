// Simplified edit profile screen adapted from reference, keeping l10n and responsiveness
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_config.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;
  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  dynamic _selectedImage; // File | XFile
  String? _photoUrl;
  bool _removePhoto = false;
  final ScrollController _scrollController = ScrollController();

  String? _country;
  String? _city;
  String? _club;

  // Dynamic lists from Supabase clubs table
  List<String> _countries = [];
  List<String> _cities = [];
  List<String> _clubNames = [];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile ?? {};
    _firstNameController.text = (p['first_name'] ?? p['firstName'] ?? '') as String;
    _lastNameController.text = (p['last_name'] ?? p['lastName'] ?? '') as String;
    _addressController.text = (p['address'] ?? '') as String;
    _phoneController.text = (p['phone_number'] ?? p['phoneNumber'] ?? '') as String;
    _gender = (p['gender'] as String?)?.isNotEmpty == true ? p['gender'] as String : null;
    final birthRaw = p['birth_date'] ?? p['birthDate'];
    if (birthRaw is String && birthRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(birthRaw);
      if (parsed != null) _birthDate = parsed;
    } else if (birthRaw is DateTime) {
      _birthDate = birthRaw;
    }
    _country = (p['country'] as String?)?.isNotEmpty == true ? p['country'] as String : null;
    _city = (p['city'] as String?)?.isNotEmpty == true ? p['city'] as String : null;
    _club = (p['club_name'] ?? p['clubName']) as String?;
    _photoUrl = (p['photo_url'] ?? p['photoUrl']) as String?;

    // Load countries, then dependent lists for current selections
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCountries();
      if (_country != null) {
        await _loadCities(_country!);
        if (_city != null) {
          await _loadClubs(_country!, _city!);
        }
      }
    });
  }

  Future<void> _loadCountries() async {
    try {
      final rows = await SupabaseConfig.client
          .from('clubs')
          .select('country')
          .order('country', ascending: true);
      final set = <String>{};
      for (final r in rows as List) {
        final c = (r['country'] as String?)?.trim();
        if (c != null && c.isNotEmpty) set.add(c);
      }
      if (!mounted) return;
      setState(() => _countries = set.toList());
    } catch (_) {
      // silently ignore; dropdown will be empty
    }
  }

  Future<void> _loadCities(String country) async {
    try {
      final rows = await SupabaseConfig.client
          .from('clubs')
          .select('city')
          .eq('country', country)
          .order('city', ascending: true);
      final set = <String>{};
      for (final r in rows as List) {
        final c = (r['city'] as String?)?.trim();
        if (c != null && c.isNotEmpty) set.add(c);
      }
      if (!mounted) return;
      setState(() => _cities = set.toList());
    } catch (_) {}
  }

  Future<void> _loadClubs(String country, String city) async {
    try {
      final rows = await SupabaseConfig.client
          .from('clubs')
          .select('club_name')
          .eq('country', country)
          .eq('city', city)
          .order('club_name', ascending: true);
      final list = <String>[];
      for (final r in rows as List) {
        final n = (r['club_name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) list.add(n);
      }
      if (!mounted) return;
      setState(() => _clubNames = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxHeight: 800, maxWidth: 800);
    if (image != null) {
      setState(() {
        _selectedImage = kIsWeb ? image : File(image.path);
        _removePhoto = false;
      });
    }
  }

  void _removePhotoLocal() {
    setState(() {
      _selectedImage = null;
      _photoUrl = null;
      _removePhoto = true;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _birthDate ?? now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final l10n = AppLocalizations.of(context);
      final userId = widget.initialProfile?['id']?.toString() ?? SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted && l10n != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
        }
        return;
      }

      // Resolve club_id from selected club name if possible
      String? clubId;
      if ((_club != null && _club!.isNotEmpty) && (_country != null && _city != null)) {
        try {
          final String country = _country!;
          final String city = _city!;
          final String clubName = _club!;
          final club = await SupabaseConfig.client
              .from('clubs')
              .select('club_id')
              .eq('country', country)
              .eq('city', city)
              .eq('club_name', clubName)
              .maybeSingle();
          if (club != null && club['club_id'] is String) {
            clubId = club['club_id'] as String;
          }
        } catch (_) {}
      }

      // Handle photo upload/remove
      String? newPhotoUrl = _photoUrl;
      if (_removePhoto) {
        newPhotoUrl = null;
      } else if (_selectedImage != null) {
        try {
          final bytes = kIsWeb
              ? await (_selectedImage as XFile).readAsBytes()
              : await (_selectedImage as File).readAsBytes();
          final path = 'profile_photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
          await SupabaseConfig.client.storage.from('profile_photos').uploadBinary(path, bytes);
          final public = SupabaseConfig.client.storage.from('profile_photos').getPublicUrl(path);
          newPhotoUrl = public;
        } catch (_) {}
      }

      final payload = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'gender': _gender,
        'birth_date': _birthDate?.toIso8601String(),
        'country': _country,
        'city': _city,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (clubId != null) {
        payload['club_id'] = clubId;
      } else if (_club == null || _club!.isEmpty) {
        // clear club if removed
        payload['club_id'] = null;
      }
      if (_removePhoto) {
        payload['photo_url'] = null;
      } else if (newPhotoUrl != _photoUrl && newPhotoUrl != null) {
        payload['photo_url'] = newPhotoUrl;
      }

      await SupabaseConfig.client.from('profiles').update(payload).eq('id', userId);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      if (mounted && l10n != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        actions: [
          IconButton(onPressed: _isLoading ? null : _save, icon: const Icon(Icons.save_outlined)),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage: () {
                          if (_selectedImage != null) {
                            return (kIsWeb ? NetworkImage((_selectedImage as XFile).path) : FileImage(_selectedImage as File)) as ImageProvider;
                          }
                          if (_photoUrl != null && _photoUrl!.isNotEmpty) {
                            return NetworkImage(_photoUrl!);
                          }
                          return null;
                        }(),
                        child: (_selectedImage == null && (_photoUrl == null || _photoUrl!.isEmpty))
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: Theme.of(context).colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _isLoading
                                ? null
                                : () {
                                    final l10n = AppLocalizations.of(context);
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      builder: (ctx) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(Icons.camera_alt_outlined),
                                              title: Text(l10n?.changePhoto ?? 'Change photo'),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _pickImage();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                                              title: Text(l10n?.removePhoto ?? 'Remove photo', style: const TextStyle(color: Colors.red)),
                                              onTap: () {
                                                Navigator.pop(ctx);
                                                _removePhotoLocal();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Info Card
                _SectionCard(
                  icon: Icons.person_outline,
                  title: l10n.personalInfo,
                  child: Column(
                    children: [
                      _InputField(
                        controller: _firstNameController,
                        label: l10n.firstName,
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty) ? l10n.firstNameRequired : null,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _lastNameController,
                        label: l10n.lastName,
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.isEmpty) ? l10n.lastNameRequired : null,
                      ),
                      const SizedBox(height: 12),
                      _ClickableField(
                        label: l10n.birthDate,
                        value: _birthDate == null ? l10n.dateNotSelected : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                        icon: Icons.cake_outlined,
                        onTap: _isLoading ? null : _pickBirthDate,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        items: [
                          DropdownMenuItem(value: 'male', child: Text(l10n.male)),
                          DropdownMenuItem(value: 'female', child: Text(l10n.female)),
                        ],
                        onChanged: _isLoading ? null : (v) => setState(() => _gender = v),
                        decoration: InputDecoration(labelText: l10n.gender, prefixIcon: const Icon(Icons.wc_outlined), border: const OutlineInputBorder()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Club Info Card
                _SectionCard(
                  icon: Icons.sports_martial_arts_outlined,
                  title: l10n.clubInfo,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _country,
                        items: _countries.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) async {
                                setState(() {
                                  _country = v;
                                  _city = null;
                                  _club = null;
                                  _cities = [];
                                  _clubNames = [];
                                });
                                if (v != null) await _loadCities(v);
                              },
                        decoration: InputDecoration(labelText: l10n.selectCountry, prefixIcon: const Icon(Icons.flag_outlined), border: const OutlineInputBorder()),
                        isExpanded: true,
                        menuMaxHeight: 288,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _city,
                        items: _cities.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                        onChanged: _isLoading || _country == null
                            ? null
                            : (v) async {
                                setState(() {
                                  _city = v;
                                  _club = null;
                                  _clubNames = [];
                                });
                                if (v != null && _country != null) await _loadClubs(_country!, v);
                              },
                        decoration: InputDecoration(labelText: l10n.selectCity, prefixIcon: const Icon(Icons.location_city_outlined), border: const OutlineInputBorder()),
                        isExpanded: true,
                        menuMaxHeight: 288,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _club,
                        items: _clubNames.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                        onChanged: _isLoading ? null : (v) => setState(() => _club = v),
                        decoration: InputDecoration(labelText: l10n.selectClub, prefixIcon: const Icon(Icons.sports_gymnastics_outlined), border: const OutlineInputBorder()),
                        isExpanded: true,
                        menuMaxHeight: 288,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : () => setState(() => _club = null),
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: Text(l10n.removeClub),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Information
                _SectionCard(
                  icon: Icons.contact_mail_outlined,
                  title: l10n.contactInfo,
                  child: Column(
                    children: [
                      _InputField(
                        controller: _addressController,
                        label: l10n.addressSimple,
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 12),
                      _InputField(
                        controller: _phoneController,
                        label: l10n.phoneNumberSimple,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (_) => null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save / Cancel Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: const Icon(Icons.save),
                        label: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : theme.primaryColor;
    final iconColor = isDark ? theme.primaryColor.withOpacity(0.8) : theme.primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: titleColor)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(padding: const EdgeInsets.all(16.0), child: child),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  const _InputField({required this.controller, required this.label, required this.icon, this.maxLines = 1, this.validator, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _ClickableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  const _ClickableField({required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: const OutlineInputBorder()),
        child: Text(value),
      ),
    );
  }
}


