import 'package:flutter/material.dart';

import '../../models/class_schedule.dart';
import '../../models/schedule_item.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/calendar_agenda_view.dart';
import '../../widgets/common.dart';
import 'schedule_form_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ScheduleItem>? _items;
  List<ClassSchedule> _classSchedules = [];
  Object? _error;
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  bool _isCalendarMode = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final from = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    final to = DateTime(_focusedMonth.year, _focusedMonth.month + 2, 0);

    try {
      final futures = await Future.wait([
        ApiClient.instance.get(
          '/schedule-items?from=${from.toIso8601String().substring(0, 10)}&to=${to.toIso8601String().substring(0, 10)}',
        ),
        ApiClient.instance.get('/class-schedules').catchError((_) => {'schedules': []}),
      ]);

      final scheduleData = futures[0] as List;
      final classData = futures[1];

      List<ClassSchedule> loadedClasses = [];
      if (classData is Map<String, dynamic>) {
        final list = (classData['schedules'] as List? ?? []);
        loadedClasses = list
            .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (mounted) {
        setState(() {
          _items = scheduleData
              .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
              .toList();
          _classSchedules = loadedClasses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleDone(ScheduleItem item) async {
    try {
      await ApiClient.instance.put('/schedule-items/${item.id}', {
        'is_done': !item.isDone,
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus agenda?'),
        content: Text('"${item.title}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/schedule-items/${item.id}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _addSchedule({DateTime? initialDate}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          // Pass prefilled date
          item: initialDate != null
              ? ScheduleItem(
                  id: 0,
                  title: '',
                  date: initialDate.toIso8601String().substring(0, 10),
                )
              : null,
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _editItem(ScheduleItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(item: item)),
    );
    if (result == true) _load();
  }

  void _showScheduleItemDetail(ScheduleItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final color = switch (item.type.toLowerCase()) {
          'kuliah' => const Color(0xFF4F6EF7),
          'deadline' || 'uts' || 'uas' => const Color(0xFFF43F5E),
          'tugas' => const Color(0xFF10B981),
          'kegiatan' => const Color(0xFFF59E0B),
          _ => const Color(0xFF0EA5E9),
        };

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.type == 'kuliah'
                          ? Icons.school
                          : item.type == 'deadline'
                              ? Icons.alarm
                              : Icons.event_note,
                      color: color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              _detailItemRow(Icons.calendar_today, 'Tanggal & Jam', '${item.date}${item.timeLabel.isNotEmpty ? ' · Jam ${item.timeLabel} WIB' : ''}', color: color),
              if (item.course != null && item.course!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailItemRow(Icons.book_outlined, 'Mata Kuliah / Kategori', item.course!, color: const Color(0xFF4F6EF7)),
              ],
              if (item.location != null && item.location!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailItemRow(Icons.location_on_outlined, 'Lokasi / Ruangan', item.location!, color: const Color(0xFF10B981)),
              ],
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailItemRow(Icons.notes, 'Deskripsi / Catatan', item.description!, color: Colors.grey.shade700),
              ],
              const SizedBox(height: 12),
              _detailItemRow(Icons.flag_outlined, 'Prioritas', item.priority.toUpperCase(), color: Colors.orange.shade700),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteItem(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Agenda'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _editItem(item);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailItemRow(IconData icon, String label, String value, {required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatIndonesianDate(DateTime d) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dayName = days[d.weekday % 7];
    final monthName = months[d.month - 1];
    return '$dayName, ${d.day} $monthName ${d.year}';
  }

  String _dayLabel(DateTime d) {
    final today = DateTime.now();
    final date = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = date.difference(t).inDays;
    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Besok';
    if (diff == -1) return 'Kemarin';
    return _formatIndonesianDate(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSchedule(initialDate: _selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('Jadwal Baru'),
      ),
      body: Column(
        children: [
          // View Switcher (Kalender / Daftar)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.calendar_month, size: 18),
                      label: Text('Kalender'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.format_list_bulleted, size: 18),
                      label: Text('Daftar'),
                    ),
                  ],
                  selected: {_isCalendarMode},
                  onSelectionChanged: (set) {
                    setState(() => _isCalendarMode = set.first);
                  },
                ),
                IconButton.filledTonal(
                  tooltip: 'Segarkan Data',
                  icon: const Icon(Icons.refresh, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: _load,
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading && _items == null
                ? const LoadingView()
                : _error != null
                    ? ErrorView(message: _error.toString(), onRetry: _load)
                    : _isCalendarMode
                        ? _buildCalendarView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  /// Tampilan Mode Kalender dengan Panel Detail Jam & Agenda
  Widget _buildCalendarView() {
    final selectedStr = _selectedDate.toIso8601String().substring(0, 10);
    final selectedWeekday = _selectedDate.weekday; // 1=Senin ... 6=Sabtu, 7=Minggu

    // ScheduleItems untuk tanggal terpilih
    final dayItems = (_items ?? []).where((it) => it.date == selectedStr).toList();

    // Routine ClassSchedules untuk hari ini (Senin - Sabtu)
    final dayClasses = _classSchedules.where((cs) => cs.dayOfWeek == selectedWeekday).toList();

    final totalDayEvents = dayItems.length + dayClasses.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // Interactive Month Grid Calendar
          CalendarAgendaView(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            scheduleItems: _items ?? [],
            classSchedules: _classSchedules,
            onMonthChanged: (newMonth) {
              setState(() => _focusedMonth = newMonth);
              _load();
            },
            onDateSelected: (newDate) {
              setState(() {
                _selectedDate = newDate;
                if (newDate.month != _focusedMonth.month || newDate.year != _focusedMonth.year) {
                  _focusedMonth = DateTime(newDate.year, newDate.month, 1);
                }
              });
            },
          ),

          // Detail Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayLabel(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$totalDayEvents kegiatan / jam kuliah terjadwal',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _addSchedule(initialDate: _selectedDate),
                ),
              ],
            ),
          ),

          // Event & Class list for selected date
          if (totalDayEvents == 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'Tidak ada agenda/kuliah pada tanggal ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manfaatkan hari ini untuk istirahat atau belajar mandiri.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Jadwal Hari Ini'),
                    onPressed: () => _addSchedule(initialDate: _selectedDate),
                  ),
                ],
              ),
            )
          else ...[
            // 1. Tampilkan Jadwal Kuliah Rutin Mingguan FIB UNDIP
            if (dayClasses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'JADWAL PERKULIAHAN KAMPUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.primary,
                  ),
                ),
              ),
              for (final cs in dayClasses) _buildClassScheduleCard(cs),
            ],

            // 2. Tampilkan Agenda/Tugas/Deadline/Ujian Tanggal Tersebut
            if (dayItems.isNotEmpty) ...[
              if (dayClasses.isNotEmpty) const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'AGENDA & TUGAS MAHASISWA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              for (final item in dayItems) _buildScheduleItemCard(item),
            ],
          ],
        ],
      ),
    );
  }

  /// Card untuk Jadwal Kuliah Kampus (ClassSchedule)
  Widget _buildClassScheduleCard(ClassSchedule cs) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF4F6EF7), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge Jam Mulai - Selesai
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F6EF7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF4F6EF7)),
                      const SizedBox(width: 4),
                      Text(
                        cs.formattedTime,
                        style: const TextStyle(
                          color: Color(0xFF4F6EF7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${cs.credits} SKS',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                const Chip(
                  label: Text('Kuliah FIB', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Color(0xFFEEF2FF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cs.subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (cs.room != null) ...[
                  Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    cs.room!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                if (cs.lecturer != null) ...[
                  Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cs.lecturer!,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card untuk ScheduleItem (Agenda/Tugas/Ujian/Deadline)
  Widget _buildScheduleItemCard(ScheduleItem item) {
    final icon = switch (item.type) {
      'kuliah' => Icons.school_outlined,
      'deadline' => Icons.alarm,
      'tugas' => Icons.assignment_outlined,
      'uts' => Icons.edit_document,
      'uas' => Icons.edit_document,
      'kegiatan' => Icons.event_outlined,
      _ => Icons.notifications_outlined,
    };

    final color = switch (item.type.toLowerCase()) {
      'kuliah' => const Color(0xFF4F6EF7),
      'deadline' || 'uts' || 'uas' => const Color(0xFFF43F5E),
      'tugas' => const Color(0xFF10B981),
      'kegiatan' => const Color(0xFFF59E0B),
      _ => const Color(0xFF0EA5E9),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        onTap: () => _showScheduleItemDetail(item),
        onLongPress: () => _deleteItem(item),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.timeLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.timeLabel,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(
          [
            item.typeLabel,
            if (item.course != null) item.course!,
            if (item.location != null) item.location!,
          ].join(' · '),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Checkbox(
          value: item.isDone,
          onChanged: (_) => _toggleDone(item),
        ),
      ),
    );
  }

  /// Tampilan Mode Daftar (List View)
  Widget _buildListView() {
    final items = _items ?? [];
    if (items.isEmpty) {
      return const EmptyState(
        message: 'Tidak ada agenda dalam rentang ini.',
        icon: Icons.event_note_outlined,
      );
    }

    final grouped = <DateTime, List<ScheduleItem>>{};
    for (final item in items) {
      final d = DateTime.tryParse(item.date) ?? DateTime.now();
      grouped.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(item);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        for (final day in sortedDays) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              _dayLabel(day),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          ...grouped[day]!.map((item) => _buildScheduleItemCard(item)),
        ],
      ],
    );
  }
}
