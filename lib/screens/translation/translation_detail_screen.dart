import 'package:flutter/material.dart';

import '../../models/translation_exercise.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import 'translation_form_screen.dart';

class TranslationDetailScreen extends StatefulWidget {
  final TranslationExercise item;

  const TranslationDetailScreen({super.key, required this.item});

  @override
  State<TranslationDetailScreen> createState() => _TranslationDetailScreenState();
}

class _TranslationDetailScreenState extends State<TranslationDetailScreen> {
  late TranslationExercise _item;
  late final TextEditingController _myTranslation;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _myTranslation = TextEditingController(text: widget.item.myTranslation ?? '');
  }

  @override
  void dispose() {
    _myTranslation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance
          .get('/translations/${_item.id}') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _item = TranslationExercise.fromJson(data);
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_myTranslation.text.trim().isEmpty) return;
    setState(() => _loading = true);

    try {
      final data = await ApiClient.instance.post(
        '/translations/${_item.id}/submit-revision',
        {
          'content': _myTranslation.text.trim(),
          'status': 'in_progress',
        },
      );
      if (mounted) {
        setState(() {
          _item = TranslationExercise.fromJson(data as Map<String, dynamic>);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markDone() async {
    if (_myTranslation.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/translations/${_item.id}/submit-revision', {
        'content': _myTranslation.text.trim(),
        'status': 'done',
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Latihan ditandai selesai')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editSource() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TranslationFormScreen(item: _item)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Terjemahan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editSource,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_item.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_item.sourceText,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _myTranslation,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Terjemahanmu (${_item.targetLang ?? 'id'})',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan Revisi'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _markDone,
                  icon: const Icon(Icons.check),
                  label: const Text('Selesai'),
                ),
              ),
            ],
          ),
          if (_item.bestTranslation != null) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Terjemahan Terbaik (Revisi Akhir)',
              content: _item.bestTranslation!,
              highlight: true,
            ),
          ],
          if (_item.revisions.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Riwayat Revisi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._item.revisions.reversed.map((rev) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rev.content,
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                        if (rev.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              rev.createdAt!.substring(0, 16).replaceAll('T', ' '),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF10B981).withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: highlight ? const Color(0xFF0B8A5E) : null)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
