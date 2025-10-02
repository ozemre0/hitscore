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
  final TextEditingController _registrationStartController = TextEditingController();
  final TextEditingController _registrationEndController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _registrationStartDate;
  DateTime? _registrationEndDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _registrationStartController.dispose();
    _registrationEndController.dispose();
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
      final competitionData = {
        'organized_competition_id': competitionId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'registration_start_date': _registrationStartDate?.toIso8601String(),
        'registration_end_date': _registrationEndDate?.toIso8601String(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.competitionGeneralInfo,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
            Text(l10n.registrationDatesLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              l10n.registrationDatesOptional,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _registrationStartController,
              decoration: InputDecoration(
                labelText: l10n.registrationStartLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.play_arrow),
                hintText: l10n.competitionDateHint,
              ),
              readOnly: true,
              onTap: () => _selectDateTime(_registrationStartController, _registrationStartDate, (d) => _registrationStartDate = d),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _registrationEndController,
              decoration: InputDecoration(
                labelText: l10n.registrationEndLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.stop),
                hintText: l10n.competitionDateHint,
              ),
              readOnly: true,
              onTap: () => _selectDateTime(_registrationEndController, _registrationEndDate, (d) => _registrationEndDate = d),
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


