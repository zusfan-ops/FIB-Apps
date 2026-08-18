import 'package:flutter/material.dart';

import '../../models/card_item.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/audio_speaker_button.dart';
import '../../widgets/common.dart';

class ReviewScreen extends StatefulWidget {
  final int? deckId;

  const ReviewScreen({super.key, this.deckId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  List<CardItem>? _cards;
  int _index = 0;
  bool _revealed = false;
  bool _submitting = false;
  Object? _error;
  int _passed = 0;
  int _failed = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final query = widget.deckId != null ? '?deck_id=${widget.deckId}' : '';
      final data = await ApiClient.instance.get('/review/due$query') as Map<String, dynamic>;
      final cards = (data['cards'] as List)
          .map((e) => CardItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _cards = cards);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  CardItem? get _current =>
      (_cards == null || _cards!.isEmpty || _index >= _cards!.length) ? null : _cards![_index];

  Future<void> _submit(int rating) async {
    final card = _current;
    if (card == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      await ApiClient.instance.post('/review/${card.id}', {'rating': rating});
      if (rating >= 3) {
        _passed++;
      } else {
        _failed++;
      }
      if (mounted) {
        setState(() {
          if (_index + 1 >= _cards!.length) {
            _finished = true;
          } else {
            _index++;
            _revealed = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ErrorView(message: _error.toString(), onRetry: _load);
    }
    if (_cards == null) return const LoadingView();
    if (_cards!.isEmpty) {
      return const EmptyState(
        message: 'Tidak ada kartu yang jatuh tempo. Semua selesai!',
        icon: Icons.celebration_outlined,
      );
    }
    if (_finished) return _buildFinished();

    final card = _current!;
    final progress = (_index + (_revealed ? 1 : 0)) / _cards!.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text('${_index + 1} / ${_cards!.length}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(child: _revealed ? _buildBack(card) : _buildFront(card)),
          if (_revealed) _buildRatingButtons(),
        ],
      ),
    );
  }

  Widget _buildFront(CardItem card) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = true),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(card.front,
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              JapaneseAudioButton(text: card.front),
              const SizedBox(height: 12),
              if (card.readings?.display.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(card.readings!.display,
                      style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text('Ketuk untuk melihat jawaban',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBack(CardItem card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(card.front,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(width: 8),
              JapaneseAudioButton(text: card.front, isMini: true),
            ],
          ),
          if (card.readings?.display.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(card.readings!.display,
                  style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
            ),
          const Divider(height: 24),
          if (card.meaning != null)
            Text(card.meaning!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          if (card.exampleSentence != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(card.exampleSentence!, style: const TextStyle(fontSize: 15)),
                      ),
                      JapaneseAudioButton(text: card.exampleSentence!, isMini: true, tooltip: 'Dengarkan Contoh Kalimat'),
                    ],
                  ),
                  if (card.exampleTranslation != null) ...[
                    const SizedBox(height: 4),
                    Text(card.exampleTranslation!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (card.tags.isNotEmpty)
                for (final tag in card.tags.take(3))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(label: Text(tag), visualDensity: VisualDensity.compact),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _RatingButton(
                label: 'Lagi',
                subtitle: '0',
                color: const Color(0xFFEF4444),
                onTap: () => _submit(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RatingButton(
                label: 'Sulit',
                subtitle: '3',
                color: const Color(0xFFF59E0B),
                onTap: () => _submit(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RatingButton(
                label: 'Bagus',
                subtitle: '4',
                color: const Color(0xFF10B981),
                onTap: () => _submit(4),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RatingButton(
                label: 'Mudah',
                subtitle: '5',
                color: AppColors.primary,
                onTap: () => _submit(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFinished() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 72, color: AppColors.accent),
            const SizedBox(height: 16),
            const Text('Review Selesai!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Berhasil $_passed · Perlu ulang $_failed',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RatingButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
