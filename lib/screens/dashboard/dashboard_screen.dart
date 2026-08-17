import 'package:flutter/material.dart';

import '../../models/campus_photo.dart';
import '../../models/schedule_item.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../services/tab_switcher.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../campus/campus_diary_screen.dart';
import '../campus/campus_photo_screen.dart';
import '../campus/class_schedule_screen.dart';
import '../../widgets/smart_image_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  List<CampusPhoto> _latestPhotos = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = await Future.wait([
        ApiClient.instance.get('/dashboard'),
        ApiClient.instance.get('/campus-photos?per_page=3'),
      ]);

      final data = futures[0];
      final photoRes = futures[1];
      final photoList = (photoRes['data'] as List<dynamic>?) ?? [];

      if (mounted) {
        setState(() {
          _data = data as Map<String, dynamic>;
          _latestPhotos = photoList
              .map((p) => CampusPhoto.fromJson(p as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2638),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/sakura_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FIB UNDIP · 桜言葉', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  'Halo, ${user?.name.split(' ').first ?? 'Mahasiswa'} 👋',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error.toString(), onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _buildGreeting(),
                      _buildFibUndipQuickActions(),
                      _buildTimelineCard(),
                      _buildReviewCard(),
                      _buildJlptCard(),
                      _buildTodaySchedule(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFibUndipQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Mahasiswa FIB UNDIP',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _quickBtn(
                  icon: Icons.calendar_month,
                  label: 'Jadwal Kuliah',
                  subtitle: '⏰ Reminder 2 Jam',
                  color: const Color(0xFF4F6EF7),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickBtn(
                  icon: Icons.auto_stories,
                  label: 'Catatan Diary',
                  subtitle: 'Refleksi & Kuliah',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CampusDiaryScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _quickBtn(
                  icon: Icons.photo_library,
                  label: 'Timeline Foto',
                  subtitle: 'Album Kampus',
                  color: const Color(0xFFF43F5E),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CampusPhotoScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    if (_latestPhotos.isEmpty) return const SizedBox.shrink();

    final latest = _latestPhotos.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CampusPhotoScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, size: 18, color: Color(0xFFF43F5E)),
                    const SizedBox(width: 8),
                    const Text(
                      'Dokumentasi & Timeline Kampus',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),

              // Thumbnail & Details
              Stack(
                children: [
                  SmartImageView(
                    imageUrl: latest.photoUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              latest.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.pinkAccent),
                              const SizedBox(width: 3),
                              Text('${latest.likesCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              const SizedBox(width: 8),
                              const Icon(Icons.chat_bubble, size: 12, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text('${latest.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final user = Session.instance.user;
    final streak = (_data?['streak_days'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat belajar, ${user?.name.split(' ').first ?? 'Mahasiswa'}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${user?.jlptLevel ?? 'N3'} · ${user?.university ?? 'FIB UNDIP'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
              const SizedBox(height: 2),
              Text(
                '$streak hari',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const Text('streak', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard() {
    final due = (_data?['due_cards'] ?? 0) as int;
    final reviewsToday = (_data?['reviews_today'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.style, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Ringkasan Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('${_data?['total_cards'] ?? 0}', 'Total kartu'),
                _stat('$due', 'Jatuh tempo'),
                _stat('$reviewsToday', 'Review hari ini'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => TabSwitcher.goTo(TabSwitcher.srs),
                icon: const Icon(Icons.play_arrow),
                label: Text(due > 0 ? 'Mulai Review ($due)' : 'Lihat Deck'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildJlptCard() {
    final target = _data?['jlpt_target'] as Map<String, dynamic>?;
    if (target == null) return const SizedBox.shrink();

    final daysLeft = target['days_left'] as int?;
    final progress = (target['progress_percent'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Target ${target['level']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (daysLeft != null)
                  Text(
                    daysLeft >= 0 ? 'Sisa $daysLeft hari' : 'Lewat ${-daysLeft} hari',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysLeft >= 0 ? Colors.grey.shade600 : AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(target['title'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            Text('Checklist: ${target['checklist_done']}/${target['checklist_total']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final items = (_data?['today_schedule'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Jadwal Hari Ini',
            trailing: TextButton(
              onPressed: () => TabSwitcher.goTo(TabSwitcher.agenda),
              child: const Text('Lihat semua'),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Tidak ada jadwal hari ini.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...items.map((e) {
              final item = ScheduleItem.fromJson(e as Map<String, dynamic>);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.type == 'kuliah' ? AppColors.primary.withValues(alpha: 0.15) : AppColors.accent.withValues(alpha: 0.15),
                    child: Icon(
                      item.type == 'kuliah' ? Icons.school_outlined : Icons.alarm,
                      color: item.type == 'kuliah' ? AppColors.primary : AppColors.accent,
                    ),
                  ),
                  title: Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${item.timeLabel}${item.course != null ? ' · ${item.course}' : ''}${item.location != null ? ' · ${item.location}' : ''}',
                  ),
                  isThreeLine: false,
                ),
              );
            }),
        ],
      ),
    );
  }
}
