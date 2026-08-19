import 'package:flutter/material.dart';

import '../../models/class_schedule.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../../theme.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import 'class_schedule_form_screen.dart';

class ClassScheduleScreen extends StatefulWidget {
  const ClassScheduleScreen({super.key});

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClassSchedule> _allSchedules = [];
  List<ClassSchedule> _upcomingToday = [];
  int _totalCredits = 0;
  bool _loading = true;
  bool _isCalendarMode = true; // Default Kalender Bulanan

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  static const List<String> _weekDayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday; // 1 = Monday
    final initialIndex = (today >= 1 && today <= 6) ? today - 1 : 0;
    _tabController = TabController(length: 6, vsync: this, initialIndex: initialIndex);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/class-schedules');
      if (res is Map<String, dynamic>) {
        final list = (res['schedules'] as List? ?? [])
            .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
            .toList();
        final upcoming = (res['upcoming_today'] as List? ?? [])
            .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
            .toList();
        final credits = res['total_credits'] as int? ?? 0;

        if (mounted) {
          setState(() {
            _allSchedules = list;
            _upcomingToday = upcoming;
            _totalCredits = credits;
            _loading = false;
          });
          NotificationService.instance.syncClassSchedules(list);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat jadwal: $e')),
        );
      }
    }
  }

  Future<void> _deleteSchedule(ClassSchedule item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Jadwal Kuliah?'),
        content: Text('Hapus mata kuliah "${item.subject}" dari jadwal Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await ApiClient.instance.delete('/class-schedules/${item.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jadwal kuliah berhasil dihapus')),
          );
        }
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  void _showScheduleDetailModal(ClassSchedule item, {DateTime? specificDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                      color: const Color(0xFF4F6EF7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.school, color: Color(0xFF4F6EF7), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.credits} SKS',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (item.code != null && item.code!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.code!,
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

              // Detail Grid
              _detailRow(
                Icons.calendar_today_rounded,
                'Hari & Waktu',
                '${item.dayName}${specificDate != null ? ' (${specificDate.day} ${_monthNames[specificDate.month - 1]} ${specificDate.year})' : ''}\n${item.formattedTime} WIB',
                color: const Color(0xFF4F6EF7),
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.meeting_room_rounded,
                'Ruang Kuliah',
                item.room ?? 'Gedung A FIB UNDIP',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.person_rounded,
                'Dosen Pengampu',
                item.lecturer ?? 'Dosen Fakultas Ilmu Budaya UNDIP',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.alarm_on_rounded,
                'Pengingat Cerdas',
                'Aktif ${item.reminderMinutes} menit (2 jam) sebelum kuliah dimulai',
                color: const Color(0xFFF43F5E),
              ),

              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailRow(
                  Icons.notes_rounded,
                  'Catatan Kuliah',
                  item.notes!,
                  color: Colors.grey.shade700,
                ),
              ],

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
                        _deleteSchedule(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Jadwal'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final res = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClassScheduleFormScreen(schedule: item),
                          ),
                        );
                        if (res == true) _load();
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

  Widget _detailRow(IconData icon, String label, String value, {required Color color}) {
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah FIB UNDIP'),
        bottom: !_isCalendarMode
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _days.map((d) => Tab(text: d)).toList(),
              )
            : null,
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kuliah'),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClassScheduleFormScreen()),
          );
          if (res == true) _load();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mode Toggle Header (Kalender Bulanan vs Per Hari)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                            icon: Icon(Icons.view_week_outlined, size: 18),
                            label: Text('Hari'),
                          ),
                        ],
                        selected: {_isCalendarMode},
                        onSelectionChanged: (set) {
                          setState(() => _isCalendarMode = set.first);
                        },
                      ),
                      // Summary Chips
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F6EF7).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_totalCredits SKS · ${_allSchedules.length} MK',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F6EF7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ⏰ Alert Pengingat 2 Jam Sebelum Kuliah
                if (_upcomingToday.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade50, const Color(0xFFFFE4E6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF43F5E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alarm_on, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⏰ Pengingat 2 Jam Sebelum Kuliah',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE11D48),
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${_upcomingToday.first.subject} (${_upcomingToday.first.formattedTime}) di ${_upcomingToday.first.room ?? "FIB UNDIP"}',
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Body View
                Expanded(
                  child: _isCalendarMode ? _buildMonthCalendarView() : _buildDayTabsView(),
                ),
              ],
            ),
    );
  }

  /// 📅 1. Tampilan Kalender Satu Bulan Lengkap & Interaktif
  Widget _buildMonthCalendarView() {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 (Senin) .. 7 (Minggu)
    final leadingEmptyCells = startingWeekday - 1;
    final totalCells = leadingEmptyCells + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    final selectedWeekday = _selectedDate.weekday;
    final classesForSelectedDate =
        _allSchedules.where((s) => s.dayOfWeek == selectedWeekday).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          // Month Header Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Bulan Sebelumnya',
                        icon: const Icon(Icons.chevron_left, size: 24),
                        onPressed: () {
                          setState(() {
                            _focusedMonth =
                                DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
                          });
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Bulan Berikutnya',
                        icon: const Icon(Icons.chevron_right, size: 24),
                        onPressed: () {
                          setState(() {
                            _focusedMonth =
                                DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Hari Ini', style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(today.year, today.month, 1);
                            _selectedDate = today;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Weekday Names
                  Row(
                    children: List.generate(7, (i) {
                      final isWeekend = i >= 5;
                      return Expanded(
                        child: Center(
                          child: Text(
                            _weekDayNames[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isWeekend ? const Color(0xFFF43F5E) : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const Divider(height: 12, thickness: 0.8),

                  // Calendar Grid Cells
                  Column(
                    children: List.generate(totalRows, (r) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: List.generate(7, (c) {
                            final cellIndex = r * 7 + c;
                            final dayNum = cellIndex - leadingEmptyCells + 1;

                            if (dayNum < 1 || dayNum > daysInMonth) {
                              return const Expanded(child: SizedBox(height: 42));
                            }

                            final cellDate =
                                DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                            final isSelected = _isSameDay(cellDate, _selectedDate);
                            final isToday = _isSameDay(cellDate, today);
                            final cellWeekday = cellDate.weekday;
                            final countClasses =
                                _allSchedules.where((s) => s.dayOfWeek == cellWeekday).length;
                            final isWeekend = c >= 5;

                            return Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() => _selectedDate = cellDate);
                                  final dayClasses = _allSchedules
                                      .where((s) => s.dayOfWeek == cellDate.weekday)
                                      .toList();
                                  if (dayClasses.length == 1) {
                                    _showScheduleDetailModal(dayClasses.first,
                                        specificDate: cellDate);
                                  }
                                },
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : isToday
                                            ? AppColors.primary.withValues(alpha: 0.12)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: isToday && !isSelected
                                        ? Border.all(color: AppColors.primary, width: 1.5)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$dayNum',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected || isToday
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : isToday
                                                  ? AppColors.primary
                                                  : isWeekend
                                                      ? const Color(0xFFE11D48)
                                                      : Colors.black87,
                                        ),
                                      ),
                                      if (countClasses > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 2),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF4F6EF7),
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Header Jadwal Hari Terpilih
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_days[(_selectedDate.weekday - 1).clamp(0, 5)]}, ${_selectedDate.day} ${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${classesForSelectedDate.length} Mata Kuliah Terjadwal',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah'),
                  onPressed: () async {
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ClassScheduleFormScreen()),
                    );
                    if (res == true) _load();
                  },
                ),
              ],
            ),
          ),

          if (classesForSelectedDate.isEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada jadwal kuliah di hari ${_days[(_selectedDate.weekday - 1).clamp(0, 5)]}',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            ...classesForSelectedDate.map((item) => _buildScheduleCard(item, specificDate: _selectedDate)),
        ],
      ),
    );
  }

  /// 📑 2. Tampilan Tab Per Hari (Senin - Sabtu)
  Widget _buildDayTabsView() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(6, (index) {
        final dayNumber = index + 1;
        final dayClasses = _allSchedules.where((s) => s.dayOfWeek == dayNumber).toList();

        if (dayClasses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada jadwal kuliah di hari ${_days[index]}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah Kuliah Hari Ini'),
                  onPressed: () async {
                    final res = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClassScheduleFormScreen(),
                      ),
                    );
                    if (res == true) _load();
                  },
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: dayClasses.length,
            itemBuilder: (context, i) => _buildScheduleCard(dayClasses[i]),
          ),
        );
      }),
    );
  }

  Widget _buildScheduleCard(ClassSchedule item, {DateTime? specificDate}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.isImminent ? const Color(0xFFF43F5E) : Colors.grey.shade200,
          width: item.isImminent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showScheduleDetailModal(item, specificDate: specificDate),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F6EF7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF4F6EF7)),
                        const SizedBox(width: 4),
                        Text(
                          item.formattedTime,
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
                      '${item.credits} SKS',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final res = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClassScheduleFormScreen(schedule: item),
                        ),
                      );
                      if (res == true) _load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _deleteSchedule(item),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.room != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.room!,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
              if (item.lecturer != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.lecturer!,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
