import 'package:flutter/material.dart';

import '../../models/card_item.dart';
import '../../models/deck.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import 'card_form_screen.dart';
import 'review_screen.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  List<CardItem>? _cards;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance
          .get('/decks/${widget.deck.id}/cards') as List;
      if (mounted) {
        setState(() => _cards = data
            .map((e) => CardItem.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _addCard() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CardFormScreen(deck: widget.deck)),
    );
    if (result == true) _load();
  }

  Future<void> _editCard(CardItem card) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CardFormScreen(deck: widget.deck, card: card)),
    );
    if (result == true) _load();
  }

  Future<void> _deleteCard(CardItem card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kartu?'),
        content: Text('"${card.front}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiClient.instance.delete('/cards/${card.id}');
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
      appBar: AppBar(title: Text(widget.deck.name)),
      bottomNavigationBar: const GlobalBottomNavBar(selectedIndex: 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCard,
        icon: const Icon(Icons.add),
        label: const Text('Kartu'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_cards == null) return const LoadingView();

    final cards = _cards!;
    final dueCount = cards.where((c) {
      if (c.dueDate == null) return false;
      final due = DateTime.tryParse(c.dueDate!)?.toLocal();
      return due != null && !due.isAfter(DateTime.now());
    }).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.deck.colorValue().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.deck.description ?? 'Tanpa deskripsi',
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('${cards.length} kartu · $dueCount due',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  FilledButton.icon(
                    onPressed: dueCount > 0
                        ? () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => ReviewScreen(deckId: widget.deck.id)))
                            .then((_) => _load())
                        : null,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Review'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (cards.isEmpty)
          const EmptyState(message: 'Belum ada kartu di deck ini.', icon: Icons.style_outlined)
        else
          ...cards.map((card) => _buildCardTile(card)),
      ],
    );
  }

  Widget _buildCardTile(CardItem card) {
    return Card(
      child: ListTile(
        onTap: () => _editCard(card),
        onLongPress: () => _deleteCard(card),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: card.stateColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              card.front.characters.take(1).toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        title: Text(card.front, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if (card.readings?.display.isNotEmpty ?? false) card.readings!.display,
            if (card.meaning != null) card.meaning!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: card.stateColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(card.stateLabel,
                  style: TextStyle(fontSize: 11, color: card.stateColor)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
