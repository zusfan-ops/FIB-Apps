import 'package:flutter/material.dart';

import '../../models/class_schedule.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
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

  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

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
          // Jadwalkan notifikasi alarm 2 jam sebelum kelas dimulai secara lokal di Android
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah FIB UNDIP'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
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
                // ⏰ Alert Pengingat 2 Jam Sebelum Kuliah
                if (_upcomingToday.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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

                // Total SKS Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Beban SKS: $_totalCredits SKS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${_allSchedules.length} Mata Kuliah Terdaftar',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(6, (index) {
                      final dayNumber = index + 1;
                      final dayClasses =
                          _allSchedules.where((s) => s.dayOfWeek == dayNumber).toList();

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
                          itemBuilder: (context, i) {
                            final item = dayClasses[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: item.isImminent
                                      ? const Color(0xFFF43F5E)
                                      : Colors.grey.shade200,
                                  width: item.isImminent ? 1.5 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4F6EF7).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.formattedTime,
                                            style: const TextStyle(
                                              color: Color(0xFF4F6EF7),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
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
                                                builder: (_) =>
                                                    ClassScheduleFormScreen(schedule: item),
                                              ),
                                            );
                                            if (res == true) _load();
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20, color: Colors.red),
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
                                          Icon(Icons.meeting_room_outlined,
                                              size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.room!,
                                              style: TextStyle(
                                                  color: Colors.grey.shade700, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (item.lecturer != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.person_outline,
                                              size: 16, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item.lecturer!,
                                              style: TextStyle(
                                                  color: Colors.grey.shade700, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (item.notes != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.notes!,
                                          style: TextStyle(
                                              color: Colors.grey.shade800, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}
