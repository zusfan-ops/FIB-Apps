import 'package:flutter/material.dart';

import '../../models/thesis_milestone.dart';
import '../../models/thesis_profile.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import 'thesis_profile_form_screen.dart';

class ThesisScreen extends StatefulWidget {
  const ThesisScreen({super.key});

  @override
  State<ThesisScreen> createState() => _ThesisScreenState();
}

class _ThesisScreenState extends State<ThesisScreen> {
  ThesisProfile? _profile;
  List<ThesisMilestone> _milestones = [];
  int? _daysLeft;
  int _progressPercent = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/thesis') as Map<String, dynamic>;
      final milestones = (data['milestones'] as List? ?? [])
          .map((e) => ThesisMilestone.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _profile = ThesisProfile.fromJson(data['profile'] as Map<String, dynamic>);
          _milestones = milestones;
          _daysLeft = data['days_left'] as int?;
          _progressPercent = (data['progress_percent'] as num?)?.round() ?? 0;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _editProfile() async {
    if (_profile == null) return;
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ThesisProfileFormScreen(profile: _profile!)),
    );
    if (result == true) _load();
  }

  Future<void> _cycleStatus(ThesisMilestone milestone) async {
    final next = switch (milestone.status) {
      'todo' => 'doing',
      'doing' => 'done',
      _ => 'todo',
    };
    try {
      await ApiClient.instance.put('/thesis/milestones/${milestone.id}', {'status': next});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addMilestone() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Milestone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'cth: Revisi Bab 2'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    try {
      await ApiClient.instance.post('/thesis/milestones', {'title': title});
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteMilestone(ThesisMilestone milestone) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus milestone?'),
        content: Text('"${milestone.title}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/thesis/milestones/${milestone.id}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Color _statusColor(String status) => switch (status) {
        'doing' => const Color(0xFFF59E0B),
        'done' => const Color(0xFF10B981),
        _ => Colors.grey,
      };

  IconData _statusIcon(String status) => switch (status) {
        'doing' => Icons.hourglass_bottom,
        'done' => Icons.check_circle,
        _ => Icons.radio_button_unchecked,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker Skripsi'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editProfile),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Milestone'),
        onPressed: _addMilestone,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ErrorView(message: _error.toString(), onRetry: _load);
    if (_profile == null) return const LoadingView();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6E7EF9)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_profile!.title?.isNotEmpty ?? false) ? _profile!.title! : 'Judul skripsi belum diisi',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_profile!.advisor1 != null || _profile!.advisor2 != null)
                  Text(
                    [_profile!.advisor1, _profile!.advisor2].where((e) => e != null && e.isNotEmpty).join(' & '),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Progress', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('$_progressPercent%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Sidang', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          _daysLeft == null
                              ? 'Belum diatur'
                              : (_daysLeft! >= 0 ? 'H-$_daysLeft' : 'Lewat ${-_daysLeft!} hari'),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progressPercent / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Progress Per Bab', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          ..._milestones.map((m) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => _cycleStatus(m),
                  leading: Icon(_statusIcon(m.status), color: _statusColor(m.status)),
                  title: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(m.statusLabel, style: TextStyle(color: _statusColor(m.status), fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                    onPressed: () => _deleteMilestone(m),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
