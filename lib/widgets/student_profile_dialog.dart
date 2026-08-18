import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../screens/chat/chat_room_screen.dart';
import '../theme.dart';

class StudentProfileDialog extends StatelessWidget {
  final User student;
  final bool showChatButton;

  const StudentProfileDialog({
    super.key,
    required this.student,
    this.showChatButton = true,
  });

  static void show(BuildContext context, User student, {bool showChatButton = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudentProfileDialog(student: student, showChatButton: showChatButton),
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    var cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    final url = Uri.parse('https://wa.me/$cleaned');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImageProvider;
    if (student.avatarUrl != null && student.avatarUrl!.isNotEmpty) {
      if (student.avatarUrl!.startsWith('data:image')) {
        try {
          final commaIdx = student.avatarUrl!.indexOf(',');
          if (commaIdx != -1) {
            final bytes = base64Decode(student.avatarUrl!.substring(commaIdx + 1));
            avatarImageProvider = MemoryImage(bytes);
          }
        } catch (_) {}
      } else {
        avatarImageProvider = NetworkImage(student.avatarUrl!);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.primary,
              backgroundImage: avatarImageProvider,
              child: avatarImageProvider == null
                  ? Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              student.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (student.nim != null && student.nim!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'NIM: ${student.nim}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (student.studyProgram != null && student.studyProgram!.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.menu_book, size: 14, color: AppColors.primary),
                    label: Text(student.studyProgram!, style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                if (student.semester != null && student.semester!.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.school, size: 14, color: Color(0xFF10B981)),
                    label: Text('Semester ${student.semester}', style: const TextStyle(fontSize: 12)),
                    backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                if (student.jlptLevel != null && student.jlptLevel!.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.flag, size: 14, color: Color(0xFFF43F5E)),
                    label: Text('JLPT ${student.jlptLevel}', style: const TextStyle(fontSize: 12)),
                    backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.08),
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (student.bio != null && student.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  '"${student.bio}"',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (student.phoneNumber != null && student.phoneNumber!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(student.phoneNumber!),
                      icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF10B981)),
                      label: const Text('WhatsApp', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (student.phoneNumber != null && student.phoneNumber!.isNotEmpty && showChatButton)
                  const SizedBox(width: 10),
                if (showChatButton)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(recipient: student),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_rounded, color: Colors.white),
                      label: const Text('Kirim Pesan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
