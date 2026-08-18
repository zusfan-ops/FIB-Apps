import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme.dart';

/// Tombol Speaker Audio Pelafalan Bahasa Jepang (Choukai)
class JapaneseAudioButton extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final bool isMini;
  final String? tooltip;
  final double? rate;

  const JapaneseAudioButton({
    super.key,
    required this.text,
    this.size = 22,
    this.color,
    this.isMini = false,
    this.tooltip,
    this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: TtsService.instance.currentlySpeakingText,
      builder: (context, speakingText, _) {
        final isThisSpeaking = speakingText == text;
        final activeColor = color ?? AppColors.primary;

        if (isMini) {
          return IconButton(
            tooltip: tooltip ?? 'Dengarkan Pelafalan ($text)',
            icon: Icon(
              isThisSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              size: size,
              color: isThisSpeaking ? const Color(0xFFF43F5E) : activeColor,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              if (isThisSpeaking) {
                TtsService.instance.stop();
              } else {
                TtsService.instance.speakJapanese(text, rate: rate);
              }
            },
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isThisSpeaking) {
              TtsService.instance.stop();
            } else {
              TtsService.instance.speakJapanese(text, rate: rate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isThisSpeaking
                  ? const Color(0xFFF43F5E).withValues(alpha: 0.15)
                  : activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isThisSpeaking ? const Color(0xFFF43F5E) : activeColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isThisSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                  size: size,
                  color: isThisSpeaking ? const Color(0xFFF43F5E) : activeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isThisSpeaking ? 'Memutar...' : 'Dengarkan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isThisSpeaking ? const Color(0xFFF43F5E) : activeColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
