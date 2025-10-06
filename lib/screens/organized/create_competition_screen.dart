import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_config.dart';
import 'competition_classifications_screen.dart';

class CreateCompetitionScreen extends StatefulWidget {
  const CreateCompetitionScreen({super.key});

  @override
  State<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool _registrationAllowed = false;
  bool _scoreAllowed = false;

  DateTime? _startDate;
  DateTime? _endDate;
  // Registration window removed; using flags instead
  bool _isLoading = false;

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

  String _normalizeNameToPrefix(String name) {
    String lower = name.toLowerCase();
    const Map<String, String> trMap = {
      'ç': 'c', 'ğ': 'g', 'ı': 'i', 'ö': 'o', 'ş': 's', 'ü': 'u',
      'â': 'a', 'î': 'i', 'û': 'u'
    };
    String replaced = lower.split('').map((ch) => trMap[ch] ?? ch).join();
    final alnum = replaced.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return alnum.isEmpty
        ? 'cmp'
        : (alnum.length >= 3 ? alnum.substring(0, 3) : alnum.padRight(3, 'x'));
  }

  Future<String> _generateVisibleId(String name) async {
    final prefix = _normalizeNameToPrefix(name);
    final existing = await SupabaseConfig.client
        .from('organized_competitions')
        .select('competition_visible_id')
        .ilike('competition_visible_id', '${prefix}%');
    final count = (existing as List).length;
    return '$prefix$count';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    // no extra controllers to dispose
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
        controller.text = "${selectedDateTime.day.toString().padLeft(2, '0')}.${selectedDateTime.month.toString().padLeft(2, '0')}.${selectedDateTime.year} ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}";
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

  Future<void> _saveCompetition() async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('No user');
      }
      final uuid = const Uuid();
      final competitionId = uuid.v4();
      final visibleId = await _generateVisibleId(_nameController.text.trim());
      final competitionData = {
        'organized_competition_id': competitionId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'registration_allowed': _registrationAllowed,
        'score_allowed': _scoreAllowed,
        'competition_visible_id': visibleId,
        'created_by': user.id,
        'status': 'draft',
      };
      await SupabaseConfig.client.from('organized_competitions').insert(competitionData);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.competitionSavedSuccess)),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CompetitionClassificationsScreen(competitionId: competitionId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: SelectableText.rich(
            TextSpan(text: e.toString()),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createCompetitionTitle),
        elevation: 0,
      ),
      body: Scrollbar(
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
            Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title removed as requested; keeping only the description below
                    Text(
                      l10n.competitionGeneralInfoDesc,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
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
              onChanged: (v) => setState(() => _registrationAllowed = v),
              title: Text(l10n.registrationAllowedLabel),
              secondary: IconButton(
                tooltip: l10n.registrationAllowedDesc,
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfo(
                  title: l10n.registrationAllowedLabel,
                  message: l10n.registrationAllowedDesc,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _scoreAllowed,
              onChanged: (v) => setState(() => _scoreAllowed = v),
              title: Text(l10n.scoreAllowedLabel),
              secondary: IconButton(
                tooltip: l10n.scoreAllowedDesc,
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfo(
                  title: l10n.scoreAllowedLabel,
                  message: l10n.scoreAllowedDesc,
                ),
              ),
            ),
            const SizedBox(height: 24),
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
            Column(
              children: [
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
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveCompetition,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isLoading ? l10n.savingInProgress : l10n.saveAndContinue),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}


