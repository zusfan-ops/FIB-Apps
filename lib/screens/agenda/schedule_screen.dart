import 'package:flutter/material.dart';

import '../../models/schedule_item.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'schedule_form_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ScheduleItem>? _items;
  Object? _error;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final from = _anchor.subtract(const Duration(days: 14));
    final to = _anchor.add(const Duration(days: 60));
    try {
      final data = await ApiClient.instance.get(
        '/schedule-items?from=${from.toIso8601String().substring(0, 10)}&to=${to.toIso8601String().substring(0, 10)}',
      ) as List;
      if (mounted) {
        setState(() => _items = data
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
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

  Future<void> _delete(ScheduleItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus agenda?'),
        content: Text('"${item.title}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
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

  Future<void> _add() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScheduleFormScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _edit(ScheduleItem item) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(item: item)),
    );
    if (result == true) _load();
  }

  String _dayLabel(DateTime d) {
    final today = DateTime.now();
    final date = DateTime(d.year, d.month, d.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = date.difference(t).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    if (diff == -1) return 'Kemarin';
    return formatDateShort(d);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _anchor = _anchor.subtract(const Duration(days: 30)));
                  _load();
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _anchor,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => _anchor = picked);
                      _load();
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    '${formatDateShort(_anchor)} ${_anchor.year}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _anchor = _anchor.add(const Duration(days: 30)));
                  _load();
                },
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Hari ini',
                onPressed: () {
                  setState(() => _anchor = DateTime.now());
                  _load();
                },
                icon: const Icon(Icons.today_outlined),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList()),
        FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Jadwal'),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_items == null) return const LoadingView();

    final items = _items!;
    if (items.isEmpty) {
      return const EmptyState(
          message: 'Tidak ada agenda dalam rentang ini.', icon: Icons.event_note_outlined);
    }

    final grouped = <DateTime, List<ScheduleItem>>{};
    for (final item in items) {
      final d = DateTime.tryParse(item.date) ?? DateTime.now();
      grouped.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(item);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final day in sortedDays) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _dayLabel(day),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          ...grouped[day]!.map((item) => _buildItem(item)),
        ],
      ],
    );
  }

  Widget _buildItem(ScheduleItem item) {
    final icon = switch (item.type) {
      'kuliah' => Icons.school_outlined,
      'deadline' => Icons.alarm,
      'tugas' => Icons.assignment_outlined,
      'uts' => Icons.edit_document,
      'uas' => Icons.edit_document,
      'kegiatan' => Icons.event_outlined,
      _ => Icons.notifications_outlined,
    };

    final color = switch (item.priority) {
      'high' => AppColors.accent,
      'low' => const Color(0xFF10B981),
      _ => AppColors.primary,
    };

    return Card(
      child: ListTile(
        onTap: () => _edit(item),
        onLongPress: () => _delete(item),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, size: 20, color: color),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: item.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          [
            if (item.timeLabel.isNotEmpty) item.timeLabel,
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
}
