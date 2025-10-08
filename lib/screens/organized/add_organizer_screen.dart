import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../services/supabase_config.dart';

class AddOrganizerScreen extends ConsumerStatefulWidget {
  final String competitionId;
  final List<String> initialOrganizerIds;

  const AddOrganizerScreen({super.key, required this.competitionId, required this.initialOrganizerIds});

  @override
  ConsumerState<AddOrganizerScreen> createState() => _AddOrganizerScreenState();
}

class _AddOrganizerScreenState extends ConsumerState<AddOrganizerScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _results = <Map<String, dynamic>>[];
  final Set<String> _selectedUserIds = <String>{};
  String? _creatorId;

  @override
  void initState() {
    super.initState();
    _selectedUserIds.addAll(widget.initialOrganizerIds);
    _searchController.addListener(_onSearchChanged);
    // Do not load all users by default; wait for search input
    _loadCreator();
    _loadSelectedUsers();
  }

  Future<void> _loadCreator() async {
    try {
      final dynamic row = await SupabaseConfig.client
          .from('organized_competitions')
          .select('created_by')
          .eq('organized_competition_id', widget.competitionId)
          .single();
      final String? creator = (row is Map<String, dynamic>) ? row['created_by'] as String? : null;
      if (creator != null) {
        setState(() {
          _creatorId = creator;
          _selectedUserIds.add(creator);
        });
        // ensure creator appears in initial list
        await _loadSelectedUsers();
      }
    } catch (_) {
      // ignore; saving step will still try to keep creator if available
    }
  }

  Future<void> _loadSelectedUsers() async {
    if (_selectedUserIds.isEmpty) {
      setState(() {
        _results = <Map<String, dynamic>>[];
      });
      return;
    }
    try {
      final String inList = '(${_selectedUserIds.join(',')})';
      final List<dynamic> rows = await SupabaseConfig.client
          .from('profiles')
          .select('id, visible_id, first_name, last_name')
          .filter('id', 'in', inList)
          .order('last_name', ascending: true)
          .order('first_name', ascending: true)
          .order('visible_id', ascending: true);
      final List<Map<String, dynamic>> mapped = <Map<String, dynamic>>[];
      for (final dynamic r in rows) {
        if (r is Map<String, dynamic>) mapped.add(r);
      }
      setState(() {
        _results = mapped;
      });
    } catch (_) {
      // best-effort; ignore
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final String q = _searchController.text.trim();
      if (q.isEmpty) {
        _loadSelectedUsers();
      } else {
        _performSearch(q);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      await _loadSelectedUsers();
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final String normalized = query.trim().replaceAll(RegExp(r'\s+'), ' ');
      final List<String> tokens = normalized
          .toLowerCase()
          .split(' ')
          .where((t) => t.isNotEmpty)
          .toList(growable: false);
      final String like = '%${normalized.replaceAll('%', '').replaceAll('_', '')}%';
      List<dynamic> rows;
      final selectBase = SupabaseConfig.client
          .from('profiles')
          .select('id, visible_id, first_name, last_name');

      // Build a broad OR for all tokens to ensure server returns candidates
      final List<String> orParts = <String>[];
      if (tokens.isEmpty) {
        orParts.addAll(<String>[
          'visible_id.ilike.$like',
          'first_name.ilike.$like',
          'last_name.ilike.$like',
        ]);
      } else {
        for (final String t in tokens) {
          final String tl = '%${t.replaceAll('%', '').replaceAll('_', '')}%';
          orParts.add('first_name.ilike.$tl');
          orParts.add('last_name.ilike.$tl');
          orParts.add('visible_id.ilike.$tl');
        }
      }

      rows = await selectBase
          .or(orParts.join(','))
          .order('last_name', ascending: true)
          .order('first_name', ascending: true)
          .order('visible_id', ascending: true)
          .limit(100);

      // Client-side ensure all tokens exist in full name or visible_id
      final List<Map<String, dynamic>> mapped = <Map<String, dynamic>>[];
      for (final dynamic r in rows) {
        if (r is! Map<String, dynamic>) continue;
        final String first = (r['first_name'] as String?)?.toLowerCase() ?? '';
        final String last = (r['last_name'] as String?)?.toLowerCase() ?? '';
        final String vis = (r['visible_id'] as String?)?.toLowerCase() ?? '';
        final String full = ('$first $last').trim();
        final bool ok = tokens.every((t) => full.contains(t) || vis.contains(t));
        if (ok) mapped.add(Map<String, dynamic>.from(r));
      }

      setState(() {
        _results = mapped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final Set<String> toSave = Set<String>.from(_selectedUserIds);
      if (_creatorId != null) {
        toSave.add(_creatorId!);
      }
      final List<String> newOrganizerIds = toSave.toList();
      await SupabaseConfig.client
          .from('organized_competitions')
          .update({'organizer_ids': newOrganizerIds})
          .eq('organized_competition_id', widget.competitionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.organizersUpdated)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorGeneric}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addOrganizersTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.addOrganizersSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: l10n.searchUserHint,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SelectableText.rich(
                        TextSpan(text: _error!),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _results.isEmpty
                            ? Center(
                                child: Text(
                                  _searchController.text.trim().isEmpty ? l10n.searchToFindUsers : l10n.noResults,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final Map<String, dynamic> u = _results[index];
                                  final String id = (u['id'] as String?) ?? '';
                                  final String visibleId = (u['visible_id'] as String?) ?? '';
                                  final String firstName = (u['first_name'] as String?) ?? '';
                                  final String lastName = (u['last_name'] as String?) ?? '';
                                  final bool selected = _selectedUserIds.contains(id);
                                  final bool isCreator = _creatorId != null && id == _creatorId;
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: isCreator
                                        ? null
                                        : (bool? v) {
                                            setState(() {
                                              if (v == true) {
                                                _selectedUserIds.add(id);
                                              } else {
                                                _selectedUserIds.remove(id);
                                              }
                                            });
                                          },
                                    title: Text('${firstName} ${lastName}'.trim().isEmpty ? visibleId : '${firstName} ${lastName}'.trim()),
                                    subtitle: Row(
                                      children: [
                                        if (visibleId.isNotEmpty) Text(visibleId),
                                        if (visibleId.isNotEmpty && isCreator) const SizedBox(width: 6),
                                        if (isCreator)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(AppLocalizations.of(context)!.creatorTag, style: Theme.of(context).textTheme.labelSmall),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: const Icon(Icons.check),
                        label: Text(l10n.update),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


