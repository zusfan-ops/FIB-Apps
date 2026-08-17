import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/dictionary_entry.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import 'jlpt_mock_result_screen.dart';

class JlptMockQuizScreen extends StatefulWidget {
  final String level;
  final List<DictionaryEntry> entries;

  const JlptMockQuizScreen({super.key, required this.level, required this.entries});

  @override
  State<JlptMockQuizScreen> createState() => _JlptMockQuizScreenState();
}

class _JlptMockQuizScreenState extends State<JlptMockQuizScreen> {
  final _random = Random();
  final _stopwatch = Stopwatch();
  late final List<List<String>> _choices;
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _choices = widget.entries.map((entry) {
      final pool = widget.entries.where((e) => e.id != entry.id).map((e) => e.meaning).toSet().toList()..shuffle(_random);
      final distractors = pool.take(3).toList();
      final options = [entry.meaning, ...distractors]..shuffle(_random);
      return options;
    }).toList();
  }

  void _select(String option) {
    if (_answered) return;
    setState(() {
      _selected = option;
      _answered = true;
      if (option == widget.entries[_index].meaning) _correct++;
    });
  }

  Future<void> _next() async {
    if (_index < widget.entries.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      return;
    }

    _stopwatch.stop();
    final duration = _stopwatch.elapsed.inSeconds;
    try {
      await ApiClient.instance.post('/jlpt-mock-results', {
        'level': widget.level,
        'total_questions': widget.entries.length,
        'correct_count': _correct,
        'duration_seconds': duration,
      });
    } catch (_) {
      // Skor tetap ditampilkan walau gagal tersimpan ke riwayat.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => JlptMockResultScreen(
          level: widget.level,
          total: widget.entries.length,
          correct: _correct,
          durationSeconds: duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entries[_index];
    final options = _choices[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text('Simulasi ${widget.level} · ${_index + 1}/${widget.entries.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_index + 1) / widget.entries.length,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text('Apa arti dari:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(entry.term, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            if (entry.readingLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.readingLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            ],
            const SizedBox(height: 32),
            ...options.map((option) {
              final isCorrect = option == entry.meaning;
              final isSelected = option == _selected;
              Color? bg;
              Color? border;
              if (_answered) {
                if (isCorrect) {
                  bg = Colors.green.shade50;
                  border = Colors.green;
                } else if (isSelected) {
                  bg = Colors.red.shade50;
                  border = Colors.red;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () => _select(option),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: bg,
                    side: BorderSide(color: border ?? Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(option, style: const TextStyle(color: Colors.black87)),
                ),
              );
            }),
            const Spacer(),
            if (_answered)
              FilledButton(
                onPressed: _next,
                child: Text(_index < widget.entries.length - 1 ? 'Soal Berikutnya' : 'Lihat Hasil'),
              ),
          ],
        ),
      ),
    );
  }
}
