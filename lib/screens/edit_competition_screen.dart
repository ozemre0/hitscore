import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/supabase_config.dart';
import 'organized/competition_classifications_screen.dart';

class EditCompetitionScreen extends StatefulWidget {
  final Map<String, dynamic> competition;

  const EditCompetitionScreen({super.key, required this.competition});

  @override
  State<EditCompetitionScreen> createState() => _EditCompetitionScreenState();
}

class _EditCompetitionScreenState extends State<EditCompetitionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  // registration date controllers removed

  DateTime? _startDate;
  DateTime? _endDate;
  // registration dates removed; using boolean flags globally
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _registrationAllowed = false;
  bool _scoreAllowed = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _showInfo({required String title, required String message}) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final media = MediaQuery.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: media.size.height * 0.6),
            child: SingleChildScrollView(
              child: SelectableText(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).maybePop(),
              child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  void _initializeForm() {
    _nameController.text = widget.competition['name'] ?? '';
    _descriptionController.text = widget.competition['description'] ?? '';
    
    // Parse dates
    if (widget.competition['start_date'] != null) {
      _startDate = DateTime.parse(widget.competition['start_date']);
      _startDateController.text = _formatDateTime(_startDate!);
    }
    
    if (widget.competition['end_date'] != null) {
      _endDate = DateTime.parse(widget.competition['end_date']);
      _endDateController.text = _formatDateTime(_endDate!);
    }
    
    // registration window removed
    _registrationAllowed = (widget.competition['registration_allowed'] as bool?) ?? false;
    _scoreAllowed = (widget.competition['score_allowed'] as bool?) ?? false;
    
    // Add listeners to track changes
    _nameController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
    _startDateController.addListener(_checkForChanges);
    _endDateController.addListener(_checkForChanges);
    // no reg date listeners
  }

  void _checkForChanges() {
    final originalName = widget.competition['name'] ?? '';
    final originalDescription = widget.competition['description'] ?? '';
    final originalStartDate = widget.competition['start_date'];
    final originalEndDate = widget.competition['end_date'];
    // removed registration window comparison
    
    final hasNameChanged = _nameController.text.trim() != originalName;
    final hasDescriptionChanged = _descriptionController.text.trim() != originalDescription;
    final hasStartDateChanged = _startDate?.toIso8601String() != originalStartDate;
    final hasEndDateChanged = _endDate?.toIso8601String() != originalEndDate;
    
    final hasBoolChanged = _registrationAllowed != ((widget.competition['registration_allowed'] as bool?) ?? false)
        || _scoreAllowed != ((widget.competition['score_allowed'] as bool?) ?? false);
    final hasChanges = hasNameChanged || hasDescriptionChanged || hasStartDateChanged || hasEndDateChanged || hasBoolChanged;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    // no extra controllers
    super.dispose();
  }

  Future<void> _selectDateTime(TextEditingController controller, DateTime? currentDateTime, Function(DateTime) onDateTimeSelected) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDateTime?.toLocal() ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentDateTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        onDateTimeSelected(selectedDateTime);
        controller.text = _formatDateTime(selectedDateTime);
        _checkForChanges();
      }
    }
  }

  bool _validateForm() {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.competitionNameRequired)),
      );
      return false;
    }
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.startDateRequired)),
      );
      return false;
    }
    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.endDateRequired)),
      );
      return false;
    }
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.startDateCannotBeAfterEndDate)),
      );
      return false;
    }
    return true;
  }

  Future<void> _updateCompetition() async {
    if (!_validateForm()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user');
      }

      final competitionData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'registration_allowed': _registrationAllowed,
        'score_allowed': _scoreAllowed,
        // registration window removed
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client
          .from('organized_competitions')
          .update(competitionData)
          .eq('organized_competition_id', widget.competition['organized_competition_id']);

      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.competitionUpdateSuccess)),
      );
      
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.competitionUpdateError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.exit),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.editCompetitionTitle),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: (_isLoading || !_hasChanges) ? null : _updateCompetition,
              child: Text(l10n.save),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final clampedTextScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
          return SafeArea(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: clampedTextScaler),
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                  ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.competitionNameLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.emoji_events),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.competitionDescriptionLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _registrationAllowed,
                      onChanged: (v) {
                        setState(() {
                          _registrationAllowed = v;
                          _checkForChanges();
                        });
                      },
                      title: Text(l10n.registrationAllowedLabel),
                      subtitle: Text(l10n.registrationAllowedDesc),
                      secondary: IconButton(
                        tooltip: l10n.registrationAllowedDesc,
                        icon: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => _showInfo(
                          title: l10n.registrationAllowedLabel,
                          message: l10n.registrationAllowedDesc,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _scoreAllowed,
                      onChanged: (v) {
                        setState(() {
                          _scoreAllowed = v;
                          _checkForChanges();
                        });
                      },
                      title: Text(l10n.scoreAllowedLabel),
                      subtitle: Text(l10n.scoreAllowedDesc),
                      secondary: IconButton(
                        tooltip: l10n.scoreAllowedDesc,
                        icon: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => _showInfo(
                          title: l10n.scoreAllowedLabel,
                          message: l10n.scoreAllowedDesc,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.competitionDuration,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.competitionDurationDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _startDateController,
                      decoration: InputDecoration(
                        labelText: l10n.startDate,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.start),
                        hintText: l10n.competitionDateHint,
                      ),
                      readOnly: true,
                      onTap: () => _selectDateTime(_startDateController, _startDate, (d) => _startDate = d),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _endDateController,
                      decoration: InputDecoration(
                        labelText: l10n.endDate,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.event),
                        hintText: l10n.competitionDateHint,
                      ),
                      readOnly: true,
                      onTap: () => _selectDateTime(_endDateController, _endDate, (d) => _endDate = d),
                    ),
                    // registration date section removed
                    const SizedBox(height: 32),
                    // Classifications Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.category,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.classifications,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noClassificationsDesc,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CompetitionClassificationsScreen(
                                        competitionId: widget.competition['organized_competition_id'],
                                        isEditMode: true,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    // Refresh competition data if needed
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.competitionUpdateSuccess)),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.edit),
                                label: Text(l10n.classifications),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || !_hasChanges) ? null : _updateCompetition,
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? l10n.savingInProgress : l10n.save),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ));
        },
      ),
    ));
  }
}
