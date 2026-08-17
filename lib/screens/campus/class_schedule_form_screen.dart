import 'package:flutter/material.dart';

import '../../models/class_schedule.dart';
import '../../services/api_client.dart';

class ClassScheduleFormScreen extends StatefulWidget {
  final ClassSchedule? schedule;

  const ClassScheduleFormScreen({super.key, this.schedule});

  @override
  State<ClassScheduleFormScreen> createState() => _ClassScheduleFormScreenState();
}

class _ClassScheduleFormScreenState extends State<ClassScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subject;
  late final TextEditingController _code;
  late final TextEditingController _lecturer;
  late final TextEditingController _room;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;
  late final TextEditingController _notes;

  int _dayOfWeek = 1;
  int _credits = 2;
  int _reminderMinutes = 120; // Default 2 Jam
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _subject = TextEditingController(text: s?.subject ?? '');
    _code = TextEditingController(text: s?.code ?? '');
    _lecturer = TextEditingController(text: s?.lecturer ?? '');
    _room = TextEditingController(text: s?.room ?? 'Gedung A FIB UNDIP');
    _startTime = TextEditingController(text: s?.startTime.substring(0, 5) ?? '08:00');
    _endTime = TextEditingController(text: s?.endTime.substring(0, 5) ?? '09:40');
    _notes = TextEditingController(text: s?.notes ?? '');
    _dayOfWeek = s?.dayOfWeek ?? 1;
    _credits = s?.credits ?? 2;
    _reminderMinutes = s?.reminderMinutes ?? 120;
  }

  @override
  void dispose() {
    _subject.dispose();
    _code.dispose();
    _lecturer.dispose();
    _room.dispose();
    _startTime.dispose();
    _endTime.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final payload = {
        'subject': _subject.text.trim(),
        'code': _code.text.trim().isEmpty ? null : _code.text.trim(),
        'lecturer': _lecturer.text.trim().isEmpty ? null : _lecturer.text.trim(),
        'room': _room.text.trim().isEmpty ? null : _room.text.trim(),
        'day_of_week': _dayOfWeek,
        'start_time': _startTime.text.trim(),
        'end_time': _endTime.text.trim(),
        'credits': _credits,
        'reminder_minutes': _reminderMinutes,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      };

      if (widget.schedule == null) {
        await ApiClient.instance.post('/class-schedules', payload);
      } else {
        await ApiClient.instance.put('/class-schedules/${widget.schedule!.id}', payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.schedule == null
              ? 'Jadwal kuliah berhasil ditambahkan'
              : 'Jadwal kuliah berhasil diperbarui'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan jadwal: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? 'Tambah Jadwal Kuliah' : 'Edit Jadwal Kuliah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _subject,
              decoration: const InputDecoration(
                labelText: 'Mata Kuliah *',
                hintText: 'cth: Sastra Jepang Modern',
                prefixIcon: Icon(Icons.book),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Mata kuliah wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: const InputDecoration(
                      labelText: 'Hari Kuliah',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Senin')),
                      DropdownMenuItem(value: 2, child: Text('Selasa')),
                      DropdownMenuItem(value: 3, child: Text('Rabu')),
                      DropdownMenuItem(value: 4, child: Text('Kamis')),
                      DropdownMenuItem(value: 5, child: Text('Jumat')),
                      DropdownMenuItem(value: 6, child: Text('Sabtu')),
                    ],
                    onChanged: (v) => setState(() => _dayOfWeek = v ?? 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _credits,
                    decoration: const InputDecoration(
                      labelText: 'Bobot SKS',
                      prefixIcon: Icon(Icons.stars),
                    ),
                    items: [1, 2, 3, 4, 6]
                        .map((sks) => DropdownMenuItem(value: sks, child: Text('$sks SKS')))
                        .toList(),
                    onChanged: (v) => setState(() => _credits = v ?? 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTime,
                    decoration: const InputDecoration(
                      labelText: 'Jam Mulai',
                      hintText: '08:00',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endTime,
                    decoration: const InputDecoration(
                      labelText: 'Jam Selesai',
                      hintText: '09:40',
                      prefixIcon: Icon(Icons.timer_off),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              color: Colors.pink.shade50.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.pink.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Color(0xFFF43F5E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pengingat Kuliah Cerdas',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Pemberitahuan aktif $_reminderMinutes menit (2 jam) sebelum kuliah dimulai.',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _room,
              decoration: const InputDecoration(
                labelText: 'Ruang Kuliah',
                hintText: 'cth: Gedung A Lt. 2 Ruang 204 FIB UNDIP',
                prefixIcon: Icon(Icons.meeting_room),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lecturer,
              decoration: const InputDecoration(
                labelText: 'Dosen Pengampu',
                hintText: 'cth: Dr. Budi Santoso, M.Hum.',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan / Materi Kuliah',
                hintText: 'Membawa buku teks sastra atau tugas presentasi...',
                prefixIcon: Icon(Icons.note_alt),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_loading ? 'Menyimpan...' : 'Simpan Jadwal Kuliah'),
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
