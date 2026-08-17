import 'package:flutter/material.dart';

class JlptMockResultScreen extends StatelessWidget {
  final String level;
  final int total;
  final int correct;
  final int durationSeconds;

  const JlptMockResultScreen({
    super.key,
    required this.level,
    required this.total,
    required this.correct,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final score = total > 0 ? ((correct / total) * 100).round() : 0;
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    final color = score >= 70 ? const Color(0xFF10B981) : (score >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFE8604C));

    return Scaffold(
      appBar: AppBar(title: Text('Hasil Simulasi $level')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color, width: 4),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                score >= 70 ? 'Kerja bagus!' : (score >= 50 ? 'Lumayan, terus berlatih!' : 'Ayo belajar lagi!'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('$correct dari $total soal benar', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                'Waktu: ${minutes}m ${seconds}s',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Kembali ke Beranda'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
