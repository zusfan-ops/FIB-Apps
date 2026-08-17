import 'package:flutter/material.dart';

import '../../models/clip.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'clip_form_screen.dart';

class ClipListScreen extends StatefulWidget {
  final VoidCallback? onChanged;

  const ClipListScreen({super.key, this.onChanged});

  @override
  State<ClipListScreen> createState() => _ClipListScreenState();
}

class _ClipListScreenState extends State<ClipListScreen> {
  List<Clip>? _clips;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/clips') as List;
      if (mounted) {
        setState(() => _clips =
            data.map((e) => Clip.fromJson(e as Map<String, dynamic>)).toList());
      }
      widget.onChanged?.call();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _toCard(Clip clip) async {
    final decks = await _fetchDecks();
    if (!mounted) return;
    if (decks == null || decks.isEmpty) return;

    final deckId = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih deck untuk kartu SRS'),
        children: decks.map((d) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, d['id'] as int),
              child: Text(d['name'] as String),
            )).toList(),
      ),
    );
    if (deckId == null) return;

    try {
      await ApiClient.instance.post('/clips/${clip.id}/to-card', {'deck_id': deckId});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Klip dikonversi ke kartu')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchDecks() async {
    try {
      final data = await ApiClient.instance.get('/decks') as List;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return null;
    }
  }

  Future<void> _deleteClip(Clip clip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus klip?'),
        content: Text('"${clip.expression}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/clips/${clip.id}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_clips == null) return const LoadingView();

    final clips = _clips!;
    if (clips.isEmpty) {
      return const EmptyState(
        message: 'Belum ada klip. Saat membaca, clip kata/frasa yang belum dikenal.',
        icon: Icons.content_copy_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: clips.length,
      itemBuilder: (context, i) {
        final clip = clips[i];
        return Card(
          child: ListTile(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => ClipFormScreen(clip: clip)))
                .then((_) => _load()),
            onLongPress: () => _deleteClip(clip),
            title: Text(clip.expression,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (clip.reading != null)
                  Text(clip.reading!, style: const TextStyle(fontSize: 12)),
                if (clip.meaning != null)
                  Text(clip.meaning!, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (clip.bookTitle != null)
                  Text('Sumber: ${clip.bookTitle}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clip.cardId != null)
                  const Icon(Icons.style, size: 18, color: Color(0xFF10B981))
                else
                  IconButton(
                    tooltip: 'Buat kartu SRS',
                    icon: const Icon(Icons.add_card, size: 20, color: AppColors.primary),
                    onPressed: () => _toCard(clip),
                  ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
