import 'package:flutter/material.dart';

import '../../models/class_schedule.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/global_bottom_nav_bar.dart';

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

  static const List<Map<String, String>> _timePresets = [
    {'label': 'Sesi 1 (07:30 - 09:10)', 'start': '07:30', 'end': '09:10'},
    {'label': 'Sesi 2 (08:00 - 09:40)', 'start': '08:00', 'end': '09:40'},
    {'label': 'Sesi 3 (09:40 - 11:20)', 'start': '09:40', 'end': '11:20'},
    {'label': 'Sesi 4 (13:00 - 14:40)', 'start': '13:00', 'end': '14:40'},
    {'label': 'Sesi 5 (15:30 - 17:10)', 'start': '15:30', 'end': '17:10'},
    {'label': 'Sesi 6 (18:30 - 20:10)', 'start': '18:30', 'end': '20:10'},
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _subject = TextEditingController(text: s?.subject ?? '');
    _code = TextEditingController(text: s?.code ?? '');
    _lecturer = TextEditingController(text: s?.lecturer ?? '');
    _room = TextEditingController(text: s?.room ?? 'Gedung A FIB UNDIP');

    String parseTime(String? raw, String fallback) {
      if (raw == null || raw.trim().isEmpty) return fallback;
      final clean = raw.trim();
      if (clean.length >= 5) return clean.substring(0, 5);
      return clean;
    }

    _startTime = TextEditingController(text: parseTime(s?.startTime, '08:00'));
    _endTime = TextEditingController(text: parseTime(s?.endTime, '09:40'));
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

  Future<void> _pickTime({required bool isStart}) async {
    final currentText = isStart ? _startTime.text.trim() : _endTime.text.trim();
    TimeOfDay initial = isStart ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 9, minute: 40);

    if (currentText.contains(':')) {
      final parts = currentText.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? initial.hour;
        final m = int.tryParse(parts[1]) ?? initial.minute;
        initial = TimeOfDay(hour: h, minute: m);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'PILIH JAM MULAI KULIAH' : 'PILIH JAM SELESAI KULIAH',
      confirmText: 'TERAPKAN',
      cancelText: 'BATAL',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime.text = formatted;
        } else {
          _endTime.text = formatted;
        }
      });
    }
  }

  void _applyPreset(String start, String end) {
    setState(() {
      _startTime.text = start;
      _endTime.text = end;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final start = _startTime.text.trim().isEmpty ? '08:00' : _startTime.text.trim();
      final end = _endTime.text.trim().isEmpty ? '09:40' : _endTime.text.trim();

      final payload = {
        'subject': _subject.text.trim(),
        'code': _code.text.trim().isEmpty ? null : _code.text.trim(),
        'lecturer': _lecturer.text.trim().isEmpty ? null : _lecturer.text.trim(),
        'room': _room.text.trim().isEmpty ? null : _room.text.trim(),
        'day_of_week': _dayOfWeek,
        'start_time': start,
        'end_time': end,
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
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan jadwal: $e'),
          backgroundColor: Colors.red,
        ),
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
            tooltip: 'Simpan',
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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

            // Time Picking Section
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickTime(isStart: true),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _startTime,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Jam Mulai *',
                          hintText: '08:00',
                          prefixIcon: const Icon(Icons.access_time, color: Color(0xFF4F6EF7)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            onPressed: () => _pickTime(isStart: true),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pickTime(isStart: false),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _endTime,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Jam Selesai *',
                          hintText: '09:40',
                          prefixIcon: const Icon(Icons.timer_off_outlined, color: Color(0xFF4F6EF7)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar, size: 18),
                            onPressed: () => _pickTime(isStart: false),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Preset Jam Kuliah Cepat
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preset Jam Kuliah Cepat:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _timePresets.map((p) {
                      final isSelected = _startTime.text == p['start'] && _endTime.text == p['end'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(p['label']!, style: const TextStyle(fontSize: 11.5)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF4F6EF7).withValues(alpha: 0.15),
                          onSelected: (_) => _applyPreset(p['start']!, p['end']!),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Smart Reminder Banner
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
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
