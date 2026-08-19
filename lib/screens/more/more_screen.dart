import 'package:flutter/material.dart';

import '../academic/gpa_screen.dart';
import '../../services/notification_service.dart';
import '../../services/tts_service.dart';
import '../../services/update_checker_service.dart';
import '../campus/class_schedule_screen.dart';
import '../campus/campus_diary_screen.dart';
import '../campus/campus_photo_screen.dart';
import '../chat/chat_list_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../thesis/thesis_screen.dart';
import 'profile_screen.dart';
import '../../screens/grammar/grammar_screen.dart';
import '../../screens/translation/translation_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitur & Layanan Kampus')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'AKADEMIK & KEHIDUPAN KAMPUS FIB UNDIP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Color(0xFFF43F5E),
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.storefront_rounded,
            title: 'Toko Mahasiswa/i',
            subtitle: 'Marketplace kampus: preloved buku kuliah, merchandise & jasa',
            color: const Color(0xFF047857),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.chat_rounded,
            title: 'Chat & Diskusi Mahasiswa FIB',
            subtitle: 'Komunikasi pesan langsung ala WhatsApp antar mahasiswa',
            color: const Color(0xFF25D366),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.calendar_month,
            title: 'Jadwal Kuliah Mahasiswa',
            subtitle: 'Atur jadwal mingguan & pengingat 2 jam sebelum mulai',
            color: const Color(0xFF4F6EF7),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.auto_stories,
            title: 'Catatan Kampus & Diary',
            subtitle: 'Diary perkuliahan, bimbingan dosen & refleksi',
            color: const Color(0xFF10B981),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CampusDiaryScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.photo_library,
            title: 'Timeline & Dokumentasi Kampus',
            subtitle: 'Album foto kegiatan Bunkasai & kebersamaan mahasiswa',
            color: const Color(0xFFF43F5E),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CampusPhotoScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.calculate_outlined,
            title: 'Kalkulator IPK',
            subtitle: 'Catat nilai per mata kuliah & hitung IPK otomatis',
            color: const Color(0xFF0EA5E9),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GpaScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.assignment_outlined,
            title: 'Tracker Skripsi',
            subtitle: 'Progress per bab, dosen pembimbing & countdown sidang',
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThesisScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              'STUDI SASTRA & BAHASA JEPANG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.grey,
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.import_contacts_outlined,
            title: 'Kamus Kanji & Kosakata',
            subtitle: 'Cari kanji/kosakata N5-N1 & simpan langsung ke deck SRS',
            color: const Color(0xFF14B8A6),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DictionaryScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.school_outlined,
            title: 'Grammar Reference',
            subtitle: 'Pola grammar modern & sastra klasik Bungo',
            color: const Color(0xFF8B5CF6),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GrammarScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.translate,
            title: 'Latihan Terjemahan (Honyaku)',
            subtitle: 'Honyaku: tulis & bandingkan revisi teks sastra',
            color: const Color(0xFFEC4899),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TranslationScreen()),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.person_outline,
            title: 'Profil Mahasiswa',
            subtitle: 'Akun, target kelulusan & pengaturan',
            color: const Color(0xFF64748B),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              'SISTEM & PEMBARUAN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.grey,
              ),
            ),
          ),
          _menuTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi Alarm & Pengingat Kuliah',
            subtitle: 'Uji kirim notifikasi push & alarm pengingat 2 jam',
            color: const Color(0xFF0284C7),
            onTap: () async {
              await NotificationService.instance.showInstantNotification(
                id: 888,
                title: '⏰ Pengingat Kuliah FIB UNDIP',
                body: 'Kuliah Choukai (08:00 WIB) di Gedung B Lt.2. Notifikasi alarm lokal berhasil aktif!',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifikasi alarm simulasi telah dikirim ke status bar.')),
                );
              }
            },
          ),
          _menuTile(
            context,
            icon: Icons.volume_up_rounded,
            title: 'Audio Suara Jepang (Choukai TTS)',
            subtitle: 'Uji pelafalan suara aksen Jepang asli (ja-JP)',
            color: const Color(0xFF8B5CF6),
            onTap: () {
              TtsService.instance.speakJapanese('桜言葉へようこそ！日本語の勉強を頑張りましょう。');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memutar pelafalan audio Jepang...')),
              );
            },
          ),
          _menuTile(
            context,
            icon: Icons.system_update_rounded,
            title: 'Cek Pembaruan Aplikasi',
            subtitle: 'Periksa rilis APK terbaru di GitHub (v${UpdateCheckerService.currentVersion})',
            color: const Color(0xFFE11D48),
            onTap: () => UpdateCheckerService.instance.checkAndShowUpdateDialog(context, isManualCheck: true),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
