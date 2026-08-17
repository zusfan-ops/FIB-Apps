import 'package:flutter/material.dart';

import '../../models/jlpt_mock_result.dart';
import '../../models/jlpt_target.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../jlpt_mock/jlpt_mock_setup_screen.dart';
import 'jlpt_form_screen.dart';

class JlptScreen extends StatefulWidget {
  const JlptScreen({super.key});

  @override
  State<JlptScreen> createState() => _JlptScreenState();
}

class _JlptScreenState extends State<JlptScreen> {
  List<JlptTarget>? _targets;
  List<JlptMockResult> _mockResults = [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _loadMockResults();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/jlpt-targets') as List;
      if (mounted) {
        setState(() => _targets = data
            .map((e) => JlptTarget.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadMockResults() async {
    try {
      final data = await ApiClient.instance.get('/jlpt-mock-results') as Map<String, dynamic>;
      final results = (data['results'] as List? ?? [])
          .map((e) => JlptMockResult.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _mockResults = results);
    } catch (_) {
      // Riwayat simulasi bersifat opsional, abaikan bila gagal dimuat.
    }
  }

  Future<void> _openMockSetup() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JlptMockSetupScreen()),
    );
    _loadMockResults();
  }

  Future<void> _toggleCheck(JlptTarget target, JlptChecklistItem item) async {
    try {
      await ApiClient.instance.post('/jlpt-targets/${target.id}/check-item', {
        'item_id': item.id,
        'is_done': !item.isDone,
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const JlptFormScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _delete(JlptTarget target) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus target?'),
        content: Text('Target ${target.level} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/jlpt-targets/${target.id}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String _targetDateLabel(JlptTarget target) {
    final date = target.targetDate?.substring(0, 10) ?? '';
    final days = target.daysLeft;
    if (days == null) return 'Target: $date';
    final daysText = days >= 0
        ? 'sisa $days hari'
        : 'lewat ${-days} hari';
    return 'Target: $date · $daysText';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMockCard(),
        Expanded(child: _buildList()),
        FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Target'),
        ),
      ],
    );
  }

  Widget _buildMockCard() {
    return Card(
      child: InkWell(
        onTap: _openMockSetup,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Simulasi Ujian JLPT', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      _mockResults.isEmpty
                          ? 'Belum ada percobaan. Yuk mulai berlatih!'
                          : 'Skor terakhir: ${_mockResults.first.score} (${_mockResults.first.level}) · ${_mockResults.length} percobaan',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_targets == null) return const LoadingView();

    final targets = _targets!;
    if (targets.isEmpty) {
      return const EmptyState(
          message: 'Belum ada target JLPT. Buat target untuk persiapan ujian!',
          icon: Icons.emoji_events_outlined);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: targets.map((t) => _buildTarget(t)).toList(),
    );
  }

  Widget _buildTarget(JlptTarget target) {
    final color = switch (target.level) {
      'N1' => const Color(0xFFE8604C),
      'N2' => const Color(0xFFF59E0B),
      'N3' => AppColors.primary,
      'N4' => const Color(0xFF10B981),
      _ => const Color(0xFF8B5CF6),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(target.level,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (target.title != null)
                        Text(target.title!,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (target.targetDate != null)
                        Text(
                          _targetDateLabel(target),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => _delete(target),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (target.progressPercent / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            ...target.checklistItems.map((item) => CheckboxListTile(
                  value: item.isDone,
                  onChanged: (_) => _toggleCheck(target, item),
                  title: Text(item.name),
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ),
      ),
    );
  }
}
