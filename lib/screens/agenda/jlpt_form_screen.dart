import 'package:flutter/material.dart';

import '../../models/jlpt_target.dart';
import '../../services/api_client.dart';
import '../../theme.dart';

class JlptFormScreen extends StatefulWidget {
  final JlptTarget? target;

  const JlptFormScreen({super.key, this.target});

  @override
  State<JlptFormScreen> createState() => _JlptFormScreenState();
}

class _JlptFormScreenState extends State<JlptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _targetDate;
  final List<TextEditingController> _checklist = [];
  String _level = 'N3';
  bool _loading = false;

  bool get _isEdit => widget.target != null;

  @override
  void initState() {
    super.initState();
    final t = widget.target;
    _title = TextEditingController(text: t?.title ?? '');
    _targetDate = TextEditingController(
        text: t?.targetDate?.length == 10 ? t!.targetDate! : '');
    if (t != null) _level = t.level;
    if (t != null && t.checklistItems.isNotEmpty) {
      for (final item in t.checklistItems) {
        _checklist.add(TextEditingController(text: item.name));
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _targetDate.dispose();
    for (final c in _checklist) {
      c.dispose();
    }
    super.dispose();
  }

  void _addChecklistField([String? value]) {
    setState(() => _checklist.add(TextEditingController(text: value ?? '')));
  }

  void _removeChecklistField(int index) {
    setState(() => _checklist.removeAt(index));
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_targetDate.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _targetDate.text = picked.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'level': _level,
      'title': _title.text.trim().isEmpty ? null : _title.text.trim(),
      'target_date': _targetDate.text.isEmpty ? null : _targetDate.text,
      if (!_isEdit)
        'checklist': _checklist
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/jlpt-targets/${widget.target!.id}', body);
      } else {
        await ApiClient.instance.post('/jlpt-targets', body);
      }
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Target JLPT' : 'Target JLPT Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _level,
                decoration: const InputDecoration(labelText: 'Level'),
                items: const [
                  DropdownMenuItem(value: 'N1', child: Text('N1')),
                  DropdownMenuItem(value: 'N2', child: Text('N2')),
                  DropdownMenuItem(value: 'N3', child: Text('N3')),
                  DropdownMenuItem(value: 'N4', child: Text('N4')),
                  DropdownMenuItem(value: 'N5', child: Text('N5')),
                ],
                onChanged: (v) => setState(() => _level = v ?? 'N3'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul (opsional)'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tanggal ujian'),
                  child: Text(_targetDate.text.isEmpty ? '—' : _targetDate.text),
                ),
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Checklist materi',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _addChecklistField(),
                      icon: const Icon(Icons.add, color: AppColors.primary),
                    ),
                  ],
                ),
                ..._checklist.asMap().entries.map((entry) => Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: entry.value,
                            decoration: InputDecoration(
                              labelText: 'Item ${entry.key + 1}',
                              hintText: 'contoh: Kanji N3 (600)',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _checklist.length > 1
                              ? () => _removeChecklistField(entry.key)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.grey),
                        ),
                      ],
                    )),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Buat Target'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
