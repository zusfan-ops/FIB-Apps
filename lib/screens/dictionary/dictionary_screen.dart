import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/deck.dart';
import '../../models/dictionary_entry.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/audio_speaker_button.dart';
import '../../widgets/common.dart';
import '../../widgets/global_bottom_nav_bar.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<DictionaryEntry>? _entries;
  Object? _error;
  String? _level;

  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final query = <String, String>{};
      if (_searchController.text.trim().isNotEmpty) {
        query['q'] = _searchController.text.trim();
      }
      if (_level != null) query['level'] = _level!;
      final qs = query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final data = await ApiClient.instance.get('/dictionary${qs.isNotEmpty ? '?$qs' : ''}') as List;
      if (mounted) {
        setState(() => _entries = data.map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>)).toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openDetail(DictionaryEntry entry) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DictionaryDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kamus Kanji & Kosakata')),
      bottomNavigationBar: const GlobalBottomNavBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari kanji, kosakata, atau arti...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _levelChip('Semua', null),
                ..._levels.map((l) => _levelChip(l, l)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _levelChip(String label, String? value) {
    final selected = _level == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _level = value);
          _load();
        },
      ),
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return ErrorView(message: _error.toString(), onRetry: _load);
    }
    if (_entries == null) return const LoadingView();
    if (_entries!.isEmpty) {
      return const EmptyState(
        message: 'Tidak ada entri kamus yang cocok.',
        icon: Icons.menu_book_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _entries!.length,
      itemBuilder: (context, i) {
        final entry = _entries![i];
        return Card(
          child: ListTile(
            onTap: () => _openDetail(entry),
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.term.isNotEmpty ? entry.term.substring(0, 1) : '?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            title: Text(entry.term, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [if (entry.readingLabel.isNotEmpty) entry.readingLabel, entry.meaning].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                JapaneseAudioButton(text: entry.term, isMini: true),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(entry.jlptLevel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DictionaryDetailSheet extends StatefulWidget {
  final DictionaryEntry entry;

  const _DictionaryDetailSheet({required this.entry});

  @override
  State<_DictionaryDetailSheet> createState() => _DictionaryDetailSheetState();
}

class _DictionaryDetailSheetState extends State<_DictionaryDetailSheet> {
  bool _saving = false;

  Future<void> _addToDeck() async {
    List<Deck> decks;
    try {
      final data = await ApiClient.instance.get('/decks') as List;
      decks = data.map((e) => Deck.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }

    if (!mounted) return;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buat deck SRS terlebih dahulu di menu Review.')),
      );
      return;
    }

    final selected = await showDialog<Deck>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pilih Deck'),
        children: decks
            .map((d) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, d),
                  child: Text(d.name),
                ))
            .toList(),
      ),
    );
    if (selected == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await ApiClient.instance.post('/dictionary/${widget.entry.id}/save-to-deck', {'deck_id': selected.id});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ditambahkan ke deck "${selected.name}"')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(entry.term, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ),
                JapaneseAudioButton(text: entry.term),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text(entry.jlptLevel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (entry.readingLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.readingLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            ],
            const SizedBox(height: 12),
            Text(entry.meaning, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (entry.exampleSentence != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(entry.exampleSentence!, style: const TextStyle(fontSize: 14)),
                        ),
                        JapaneseAudioButton(text: entry.exampleSentence!, isMini: true, tooltip: 'Dengarkan Contoh Kalimat'),
                      ],
                    ),
                    if (entry.exampleTranslation != null) ...[
                      const SizedBox(height: 4),
                      Text(entry.exampleTranslation!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _addToDeck,
              icon: _saving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
              label: const Text('Tambah ke Deck SRS'),
            ),
          ],
        ),
      ),
    );
  }
}
