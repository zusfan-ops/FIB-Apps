import 'package:flutter/material.dart';
import '../models/schedule_item.dart';
import '../models/class_schedule.dart';
import '../theme.dart';

/// Komponen Kalender Interaktif yang menampilkan grid tanggal,
/// navigasi bulan, indikator warna event/kuliah, dan pemilihan tanggal.
class CalendarAgendaView extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;
  final List<ScheduleItem> scheduleItems;
  final List<ClassSchedule> classSchedules;

  const CalendarAgendaView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.onMonthChanged,
    required this.onDateSelected,
    required this.scheduleItems,
    this.classSchedules = const [],
  });

  static const List<String> _monthNames = [
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

  static const List<String> _weekDayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  /// Mengambil semua warna event/kuliah untuk tanggal tertentu
  List<Color> _getEventColorsForDate(DateTime date) {
    final colors = <Color>{};
    final dateStr = date.toIso8601String().substring(0, 10);

    // 1. Cek ScheduleItem pada tanggal ini
    for (final item in scheduleItems) {
      if (item.date == dateStr) {
        final color = switch (item.type.toLowerCase()) {
          'kuliah' => const Color(0xFF4F6EF7),
          'deadline' || 'uts' || 'uas' => const Color(0xFFF43F5E),
          'tugas' => const Color(0xFF10B981),
          'kegiatan' => const Color(0xFFF59E0B),
          _ => const Color(0xFF0EA5E9),
        };
        colors.add(color);
      }
    }

    // 2. Cek ClassSchedule (kuliah mingguan rutin) pada hari ini (weekday 1=Senin s/d 6=Sabtu)
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    final hasClass = classSchedules.any((s) => s.dayOfWeek == dayOfWeek);
    if (hasClass) {
      colors.add(const Color(0xFF4F6EF7)); // Warna khas kuliah
    }

    return colors.toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    // Kalkulasi hari-hari dalam bulan yang sedang aktif
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Hari dalam minggu untuk tanggal 1 (1 = Monday, ..., 7 = Sunday)
    final startingWeekday = firstDayOfMonth.weekday; // 1 (Senin) .. 7 (Minggu)
    final leadingEmptyCells = startingWeekday - 1;

    // Total sel dalam grid (pembulatan ke kelipatan 7)
    final totalCells = leadingEmptyCells + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          children: [
            // Header Kalender: Bulan, Tahun, Navigasi, dan Tombol Hari Ini
            Row(
              children: [
                IconButton(
                  tooltip: 'Bulan Sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded, size: 26),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final prev = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
                    onMonthChanged(prev);
                  },
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                        helpText: 'PILIH TANGGAL AGENDA',
                      );
                      if (picked != null) {
                        onMonthChanged(DateTime(picked.year, picked.month, 1));
                        onDateSelected(picked);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${_monthNames[focusedMonth.month - 1]} ${focusedMonth.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bulan Berikutnya',
                  icon: const Icon(Icons.chevron_right_rounded, size: 26),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final next = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
                    onMonthChanged(next);
                  },
                ),
                const SizedBox(width: 4),
                // Tombol Hari Ini
                ActionChip(
                  avatar: const Icon(Icons.today_rounded, size: 14, color: AppColors.primary),
                  label: const Text(
                    'Hari Ini',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onPressed: () {
                    onMonthChanged(DateTime(today.year, today.month, 1));
                    onDateSelected(today);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Baris Nama Hari (Senin - Minggu)
            Row(
              children: List.generate(7, (index) {
                final isWeekend = index >= 5; // Sabtu & Minggu
                return Expanded(
                  child: Center(
                    child: Text(
                      _weekDayNames[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isWeekend ? const Color(0xFFF43F5E) : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Divider(height: 14, thickness: 0.8),

            // Grid Tanggal
            Column(
              children: List.generate(totalRows, (rowIndex) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: List.generate(7, (colIndex) {
                      final cellIndex = rowIndex * 7 + colIndex;
                      final dayNumber = cellIndex - leadingEmptyCells + 1;

                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const Expanded(child: SizedBox(height: 42));
                      }

                      final cellDate = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
                      final isSelected = _isSameDay(cellDate, selectedDate);
                      final isToday = _isSameDay(cellDate, today);
                      final eventColors = _getEventColorsForDate(cellDate);
                      final isWeekend = colIndex >= 5;

                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onDateSelected(cellDate),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isToday && !isSelected
                                  ? Border.all(color: AppColors.primary, width: 1.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : isToday
                                            ? AppColors.primary
                                            : isWeekend
                                                ? const Color(0xFFE11D48)
                                                : Colors.grey.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Dots indikator event/jadwal
                                if (eventColors.isNotEmpty)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: eventColors.take(3).map((c) {
                                      return Container(
                                        width: 5,
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : c,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }).toList(),
                                  )
                                else
                                  const SizedBox(height: 5),
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

            // Legend / Petunjuk Warna
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendDot(const Color(0xFF4F6EF7), 'Kuliah'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFF43F5E), 'Deadline / Ujian'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFF10B981), 'Tugas'),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFF59E0B), 'Kegiatan'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
