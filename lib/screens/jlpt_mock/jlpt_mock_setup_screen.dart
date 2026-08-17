import 'package:flutter/material.dart';

import '../../models/dictionary_entry.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import 'jlpt_mock_quiz_screen.dart';

class JlptMockSetupScreen extends StatefulWidget {
  const JlptMockSetupScreen({super.key});

  @override
  State<JlptMockSetupScreen> createState() => _JlptMockSetupScreenState();
}

class _JlptMockSetupScreenState extends State<JlptMockSetupScreen> {
  String _level = 'N3';
  int _count = 10;
  bool _loading = false;

  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
  static const _counts = [5, 10, 15, 20];

  Future<void> _start() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/dictionary/quiz?level=$_level&count=$_count') as List;
      final entries = data.map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      if (entries.length < 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kosakata level ini belum cukup untuk simulasi.')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JlptMockQuizScreen(level: _level, entries: entries)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulasi Ujian JLPT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6E7EF9)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.quiz_outlined, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Uji pemahaman kosakata & kanji dengan soal pilihan ganda bertimer.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pilih Level JLPT', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _levels
                  .map((l) => ChoiceChip(
                        label: Text(l),
                        selected: _level == l,
                        onSelected: (_) => setState(() => _level = l),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text('Jumlah Soal', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _counts
                  .map((c) => ChoiceChip(
                        label: Text('$c soal'),
                        selected: _count == c,
                        onSelected: (_) => setState(() => _count = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loading ? null : _start,
              icon: _loading
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              label: const Text('Mulai Simulasi'),
            ),
          ],
        ),
      ),
    );
  }
}
