import 'package:flutter/material.dart';

import '../../models/plan_task.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';
import 'task_form_screen.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  Map<String, List<PlanTask>>? _data;
  Object? _error;

  static const _columns = [
    ('todo', 'To Do', Color(0xFF6B7280)),
    ('doing', 'Sedang', Color(0xFFF59E0B)),
    ('done', 'Selesai', Color(0xFF10B981)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/plan-tasks') as Map<String, dynamic>;
      if (mounted) {
        setState(() => _data = {
          for (final key in ['todo', 'doing', 'done'])
            key: (data[key] as List)
                .map((e) => PlanTask.fromJson(e as Map<String, dynamic>))
                .toList(),
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaskFormScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _move(PlanTask task, String targetColumn) async {
    try {
      await ApiClient.instance.patch('/plan-tasks/${task.id}/move', {
        'column': targetColumn,
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _delete(PlanTask task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tugas?'),
        content: Text('"${task.title}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/plan-tasks/${task.id}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildBoard()),
        FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Tugas'),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_data == null) return const LoadingView();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, label, color) in _columns)
            Container(
              width: 260,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(label,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text('(${_data![key]!.length})',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  ..._data![key]!.map((task) => _buildTaskCard(task, key)),
                  if (_data![key]!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('Kosong',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(PlanTask task, String currentColumn) {
    final currentIndex = _columns.indexWhere((c) => c.$1 == currentColumn);
    final prev = currentIndex > 0 ? _columns[currentIndex - 1] : null;
    final next = currentIndex < _columns.length - 1 ? _columns[currentIndex + 1] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.column == 'done' ? TextDecoration.lineThrough : null,
                    )),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'delete') _delete(task);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          if (task.dueDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Tenggat: ${task.dueDate!.substring(0, 10)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (prev != null)
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  color: Colors.grey,
                  onPressed: () => _move(task, prev.$1),
                ),
              if (next != null)
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  color: next.$3,
                  onPressed: () => _move(task, next.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
