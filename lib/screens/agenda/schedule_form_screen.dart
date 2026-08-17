import 'package:flutter/material.dart';

import '../../models/schedule_item.dart';
import '../../services/api_client.dart';

class ScheduleFormScreen extends StatefulWidget {
  final ScheduleItem? item;

  const ScheduleFormScreen({super.key, this.item});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _course;
  late final TextEditingController _location;
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  String _type = 'tugas';
  String _priority = 'medium';
  bool _loading = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _title = TextEditingController(text: it?.title ?? '');
    _description = TextEditingController(text: it?.description ?? '');
    _course = TextEditingController(text: it?.course ?? '');
    _location = TextEditingController(text: it?.location ?? '');
    if (it != null) {
      _date = DateTime.tryParse(it.date) ?? DateTime.now();
      if (it.time != null && it.time!.length >= 5) {
        _time = TimeOfDay(
          hour: int.parse(it.time!.substring(0, 2)),
          minute: int.parse(it.time!.substring(3, 5)),
        );
      }
      _type = it.type;
      _priority = it.priority;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _course.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'title': _title.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'date': _date.toIso8601String().substring(0, 10),
      'time': _time != null
          ? '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'
          : null,
      'type': _type,
      'course': _course.text.trim().isEmpty ? null : _course.text.trim(),
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
      'priority': _priority,
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/schedule-items/${widget.item!.id}', body);
      } else {
        await ApiClient.instance.post('/schedule-items', body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Agenda' : 'Agenda Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal'),
                        child: Text(_date.toIso8601String().substring(0, 10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time ?? TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _time = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Jam (opsional)'),
                        child: Text(_time == null
                            ? '—'
                            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipe'),
                items: const [
                  DropdownMenuItem(value: 'kuliah', child: Text('Kuliah')),
                  DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                  DropdownMenuItem(value: 'tugas', child: Text('Tugas')),
                  DropdownMenuItem(value: 'uts', child: Text('UTS')),
                  DropdownMenuItem(value: 'uas', child: Text('UAS')),
                  DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan')),
                  DropdownMenuItem(value: 'pengingat', child: Text('Pengingat')),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'tugas'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _course,
                      decoration: const InputDecoration(labelText: 'Mata kuliah'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(labelText: 'Lokasi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioritas'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Rendah')),
                  DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                  DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'medium'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
