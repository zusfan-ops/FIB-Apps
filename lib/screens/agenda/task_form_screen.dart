import 'package:flutter/material.dart';

import '../../services/api_client.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _column = 'todo';
  String? _dueDate;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await ApiClient.instance.post('/plan-tasks', {
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'column': _column,
        'due_date': _dueDate,
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
      appBar: AppBar(title: const Text('Tugas Rencana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul tugas'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _column,
                decoration: const InputDecoration(labelText: 'Kolom'),
                items: const [
                  DropdownMenuItem(value: 'todo', child: Text('To Do')),
                  DropdownMenuItem(value: 'doing', child: Text('Sedang dikerjakan')),
                  DropdownMenuItem(value: 'done', child: Text('Selesai')),
                ],
                onChanged: (v) => setState(() => _column = v ?? 'todo'),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked.toIso8601String().substring(0, 10));
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Tenggat (opsional)'),
                  child: Text(_dueDate ?? '—'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
