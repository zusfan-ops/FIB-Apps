import 'package:flutter/material.dart';

import '../../models/thesis_profile.dart';
import '../../services/api_client.dart';

class ThesisProfileFormScreen extends StatefulWidget {
  final ThesisProfile profile;

  const ThesisProfileFormScreen({super.key, required this.profile});

  @override
  State<ThesisProfileFormScreen> createState() => _ThesisProfileFormScreenState();
}

class _ThesisProfileFormScreenState extends State<ThesisProfileFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _advisor1;
  late final TextEditingController _advisor2;
  late final TextEditingController _notes;
  DateTime? _targetDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.profile.title ?? '');
    _advisor1 = TextEditingController(text: widget.profile.advisor1 ?? '');
    _advisor2 = TextEditingController(text: widget.profile.advisor2 ?? '');
    _notes = TextEditingController(text: widget.profile.notes ?? '');
    final raw = widget.profile.targetDefenseDate;
    _targetDate = raw != null ? DateTime.tryParse(raw) : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _advisor1.dispose();
    _advisor2.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiClient.instance.put('/thesis/profile', {
        'title': _title.text.trim().isEmpty ? null : _title.text.trim(),
        'advisor_1': _advisor1.text.trim().isEmpty ? null : _advisor1.text.trim(),
        'advisor_2': _advisor2.text.trim().isEmpty ? null : _advisor2.text.trim(),
        'target_defense_date': _targetDate != null
            ? '${_targetDate!.year.toString().padLeft(4, '0')}-${_targetDate!.month.toString().padLeft(2, '0')}-${_targetDate!.day.toString().padLeft(2, '0')}'
            : null,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Skripsi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Judul Skripsi'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _advisor1,
              decoration: const InputDecoration(labelText: 'Dosen Pembimbing 1'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _advisor2,
              decoration: const InputDecoration(labelText: 'Dosen Pembimbing 2 (opsional)'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Target Tanggal Sidang'),
                child: Text(
                  _targetDate != null
                      ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year}'
                      : 'Pilih tanggal',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
