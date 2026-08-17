import 'package:flutter/material.dart';

import '../../models/translation_exercise.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';
import 'translation_form_screen.dart';
import 'translation_detail_screen.dart';

import '../../widgets/global_bottom_nav_bar.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  List<TranslationExercise>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/translations') as List;
      if (mounted) {
        setState(() => _items = data
            .map((e) => TranslationExercise.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TranslationFormScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _delete(TranslationExercise item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus latihan?'),
        content: Text('"${item.title}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/translations/${item.id}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Honyaku')),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Latihan'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_items == null) return const LoadingView();

    final items = _items!;
    if (items.isEmpty) {
      return const EmptyState(
        message: 'Belum ada latihan terjemahan. Mulai dari teks pendek!',
        icon: Icons.translate,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final color = switch (item.status) {
          'done' => const Color(0xFF10B981),
          'in_progress' => const Color(0xFFF59E0B),
          _ => Colors.grey,
        };

        return Card(
          child: ListTile(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => TranslationDetailScreen(item: item)))
                .then((_) => _load()),
            onLongPress: () => _delete(item),
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: const Icon(Icons.translate, size: 20),
            ),
            title: Text(item.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${item.sourceText.characters.take(40)}\n${item.statusLabel} · ${item.revisionsCount} revisi',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ),
        );
      },
    );
  }
}
