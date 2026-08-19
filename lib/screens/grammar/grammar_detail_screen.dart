import 'package:flutter/material.dart';

import '../../models/grammar_pattern.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/audio_speaker_button.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import 'grammar_form_screen.dart';

class GrammarDetailScreen extends StatefulWidget {
  final GrammarPattern pattern;

  const GrammarDetailScreen({super.key, required this.pattern});

  @override
  State<GrammarDetailScreen> createState() => _GrammarDetailScreenState();
}

class _GrammarDetailScreenState extends State<GrammarDetailScreen> {
  Future<void> _edit() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => GrammarFormScreen(pattern: widget.pattern)),
    );
    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pola?'),
        content: Text('"${widget.pattern.pattern}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/grammar/${widget.pattern.id}');
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pattern;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Grammar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.isBungo ? const Color(0xFFE8604C) : AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.pattern,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800)),
                    ),
                    JapaneseAudioButton(
                      text: p.pattern,
                      color: Colors.white,
                    ),
                  ],
                ),
                if (p.meaning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(p.meaning!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
              ],
            ),
          ),
          if (p.structure != null) ...[
            const _InfoCard(title: 'Struktur', icon: Icons.functions),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(p.structure!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
          if (p.usage != null) ...[
            const _InfoCard(title: 'Penggunaan', icon: Icons.info_outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(p.usage!, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ],
          if (p.examples.isNotEmpty) ...[
            const _InfoCard(title: 'Contoh', icon: Icons.format_quote),
            ...p.examples.map((e) {
              final jpText = e['jp'] ?? '';
              final idText = e['id'] ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(jpText,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500)),
                            if (idText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(idText,
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ],
                        ),
                      ),
                      if (jpText.isNotEmpty)
                        JapaneseAudioButton(text: jpText, isMini: true, tooltip: 'Dengarkan Contoh'),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (p.notes != null) ...[
            const _InfoCard(title: 'Catatan', icon: Icons.sticky_note_2_outlined),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(p.notes!, style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
          ],
          if (p.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                spacing: 6,
                children: p.tags
                    .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _InfoCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
