import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';
import 'profile_setup_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'no_user';
      });
      return;
    }
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
        );
        return;
      }

      Map<String, dynamic> hydrated = Map<String, dynamic>.from(data);

      // Try to hydrate club_name from clubs table if only club_id is present
      final dynamic rawClubId = hydrated['club_id'] ?? hydrated['clubId'];
      final String? clubId = rawClubId?.toString();
      final String? existingClubName = (hydrated['club_name'] ??
              hydrated['clubName'] ??
              hydrated['name'] ??
              hydrated['club'] ??
              hydrated['club_title'] ??
              hydrated['club_name_tr'])
          as String?;
      if (existingClubName == null && clubId != null && clubId.isNotEmpty) {
        try {
          final club = await SupabaseConfig.client
              .from('clubs')
              .select('club_name')
              .eq('club_id', clubId)
              .maybeSingle();
          if (club != null && club['club_name'] is String) {
            hydrated['club_name'] = club['club_name'] as String;
          }
        } catch (_) {
          // ignore hydration errors; UI will simply hide the row
        }
      }

      setState(() {
        _profile = hydrated;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SelectableText.rich(
                      TextSpan(text: l10n.errorGeneric),
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth < 600 ? constraints.maxWidth : 600.0;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _buildHeaderCard(context),
                                    const SizedBox(height: 16),
                                    _buildProfileIdRow(context),
                                    const SizedBox(height: 12),
                                    _buildRoleGenderBirthClubCards(context),
                                    const SizedBox(height: 12),
                                    const SizedBox(height: 12),
                                    _buildEditButton(context),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildAvatar() {
    final photoUrl = (_profile?['photo_url'] ?? _profile?['photoUrl']) as String?;
    final firstName = (_profile?['first_name'] ?? _profile?['firstName'] ?? '') as String;
    return CircleAvatar(
      radius: 40,
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: (photoUrl == null || photoUrl.isEmpty)
          ? Text(firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : 'U')
          : null,
    );
  }

  Widget _buildDisplayName(BuildContext context) {
    final firstName = (_profile?['first_name'] ?? _profile?['firstName'] ?? '') as String;
    final lastName = (_profile?['last_name'] ?? _profile?['lastName'] ?? '') as String;
    final display = ('$firstName $lastName').trim();
    return Text(
      display.isNotEmpty ? display : '',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoRows(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final role = (_profile?['role']) as String?;
    final gender = (_profile?['gender']) as String?;
    final birthRaw = _profile?['birth_date'] ?? _profile?['birthDate'];
    final clubName = (_profile?['club_name'] ??
            _profile?['clubName'] ??
            _profile?['club'] ??
            _profile?['club_title'] ??
            _profile?['club_name_tr'])
        as String?;
    final address = (_profile?['address']) as String?;
    final phone = (_profile?['phone_number'] ?? _profile?['phoneNumber']) as String?;
    final String? email = SupabaseConfig.client.auth.currentUser?.email;

    String? birthDate;
    if (birthRaw is String && birthRaw.isNotEmpty) {
      birthDate = birthRaw;
    } else if (birthRaw is DateTime) {
      birthDate = '${birthRaw.day.toString().padLeft(2, '0')}/${birthRaw.month.toString().padLeft(2, '0')}/${birthRaw.year}';
    }

    Widget buildItem({required IconData icon, required String label, required String value}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 6),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final items = <Widget>[];
    if (role != null && role.isNotEmpty) {
      items.add(buildItem(icon: Icons.badge_outlined, label: l10n.role, value: role));
    }
    if (gender != null && gender.isNotEmpty) {
      items.add(buildItem(icon: Icons.people_outline, label: l10n.gender, value: gender));
    }
    if (birthDate != null && birthDate.isNotEmpty) {
      items.add(buildItem(icon: Icons.cake_outlined, label: l10n.birthDateLabel, value: birthDate));
    }
    if (clubName != null && clubName.isNotEmpty) {
      items.add(buildItem(icon: Icons.sports_soccer_outlined, label: l10n.clubLabel, value: clubName));
    }
    if (address != null && address.isNotEmpty) {
      items.add(buildItem(icon: Icons.location_on_outlined, label: l10n.addressSimple, value: address));
    }
    // Place email just above the phone number
    if (email != null && email.isNotEmpty) {
      items.add(buildItem(icon: Icons.email_outlined, label: l10n.emailLabel, value: email));
    }
    if (phone != null && phone.isNotEmpty) {
      items.add(buildItem(icon: Icons.phone_outlined, label: l10n.phoneNumberSimple, value: phone));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Column(children: items);
  }

  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 12),
          _buildDisplayName(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRoleGenderBirthClubCards(BuildContext context) {
    return _buildInfoRows(context);
  }

  Widget _buildProfileIdRow(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final profileId = (_profile?['visible_id'] ?? _profile?['visibleId'] ?? _profile?['id'])?.toString();
    if (profileId == null || profileId.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.center,
      child: ActionChip(
        avatar: const Icon(Icons.copy, size: 18),
        label: Text('${l10n.profileId}: $profileId', style: theme.textTheme.titleMedium),
        backgroundColor: theme.colorScheme.surface,
        shape: StadiumBorder(side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2))),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: profileId));
        },
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final updated = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: _profile)),
          );
          if (updated == true && mounted) {
            _loadProfile();
          }
        },
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.editProfile),
      ),
    );
  }
}


