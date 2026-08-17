import 'package:flutter/material.dart';

import '../../models/deck.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';
import 'deck_form_screen.dart';
import 'deck_detail_screen.dart';
import 'review_screen.dart';

class SrsHomeScreen extends StatefulWidget {
  const SrsHomeScreen({super.key});

  @override
  State<SrsHomeScreen> createState() => _SrsHomeScreenState();
}

class _SrsHomeScreenState extends State<SrsHomeScreen> {
  List<Deck>? _decks;
  Object? _error;
  int _dueCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/decks') as List;
      final decks = data.map((e) => Deck.fromJson(e as Map<String, dynamic>)).toList();

      int due = 0;
      try {
        final dueData = await ApiClient.instance.get('/review/due') as Map<String, dynamic>;
        due = (dueData['total'] ?? 0) as int;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _decks = decks;
          _dueCount = due;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _createDeck() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeckFormScreen()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SRS Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDeck,
        icon: const Icon(Icons.add),
        label: const Text('Deck'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [ErrorView(message: _error.toString(), onRetry: _load)],
      );
    }
    if (_decks == null) return const LoadingView();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        _buildReviewBanner(),
        SectionHeader(title: 'Deck Kamu', trailing: Text('${_decks!.length} deck')),
        if (_decks!.isEmpty)
          const EmptyState(message: 'Belum ada deck. Buat deck pertamamu!'),
        ..._decks!.map((deck) => _buildDeckCard(deck)),
      ],
    );
  }

  Widget _buildReviewBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF4F6EF7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dueCount > 0 ? '$_dueCount kartu jatuh tempo' : 'Tidak ada kartu due',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gunakan SM-2 untuk jadwal review otomatis.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _dueCount > 0
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReviewScreen()),
                    ).then((_) => _load())
                : null,
            icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)))
            .then((_) => _load()),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: deck.colorValue().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.style, color: deck.colorValue()),
        ),
        title: Text(deck.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${deck.cardsCount} kartu · ${_typeLabel(deck.cardType)}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }

  String _typeLabel(String type) => switch (type) {
        'kanji' => 'Kanji',
        'kosakata' => 'Kosakata',
        'klip' => 'Klip',
        _ => type,
      };
}
