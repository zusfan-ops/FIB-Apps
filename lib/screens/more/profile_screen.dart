import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../services/update_checker_service.dart';
import '../../theme.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _refreshProfile() async {
    try {
      final res = await ApiClient.instance.get('/auth/me');
      if (res is Map<String, dynamic>) {
        final updated = User.fromJson(res);
        await Session.instance.updateUser(updated);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (updated == true && mounted) {
      setState(() {});
    }
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

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await ApiClient.instance.post('/auth/logout');
    } catch (_) {}
    await Session.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user;

    ImageProvider? avatarImageProvider;
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      if (user.avatarUrl!.startsWith('data:image')) {
        try {
          final commaIdx = user.avatarUrl!.indexOf(',');
          if (commaIdx != -1) {
            final bytes = base64Decode(user.avatarUrl!.substring(commaIdx + 1));
            avatarImageProvider = MemoryImage(bytes);
          }
        } catch (_) {}
      } else {
        avatarImageProvider = NetworkImage(user.avatarUrl!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa FIB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profil',
            onPressed: _openEditProfile,
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(selectedIndex: 4),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // KTM Digital / Student Identity Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'KARTU IDENTITAS MAHASISWA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'FIB UNDIP',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          backgroundImage: avatarImageProvider,
                          child: avatarImageProvider == null
                              ? Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Mahasiswa FIB',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user?.nim != null && user!.nim!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'NIM: ${user.nim}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (user?.semester != null && user!.semester!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Semester ${user.semester}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                if (user?.angkatan != null && user!.angkatan!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Angkatan ${user.angkatan}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                if (user?.jlptLevel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF43F5E),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'JLPT ${user!.jlptLevel}',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openEditProfile,
                      icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                      label: const Text(
                        'Edit Profil & Ganti Foto Mahasiswa',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Study Program info
            if (user?.studyProgram != null && user!.studyProgram!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  ),
                  title: Text(user.studyProgram!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Program Studi FIB UNDIP'),
                ),
              ),

            // Contact / WhatsApp info
            if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_outlined, color: Color(0xFF10B981)),
                  ),
                  title: Text(user.phoneNumber!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Nomor WhatsApp / Kontak'),
                  trailing: TextButton.icon(
                    onPressed: () => _openWhatsApp(user.phoneNumber!),
                    icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFF10B981)),
                    label: const Text('Buka WA', style: TextStyle(color: Color(0xFF10B981))),
                  ),
                ),
              ),

            // University info
            if (user?.university != null && user!.university!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_outlined, color: Color(0xFF6366F1)),
                  ),
                  title: Text(user.university!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Fakultas & Perguruan Tinggi'),
                ),
              ),

            // Bio info
            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.format_quote_outlined, color: Color(0xFFEC4899)),
                  ),
                  title: const Text('Catatan & Minat Sastra', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(user.bio!),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // App info & Logout
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.primary),
                    title: const Text('Tentang Aplikasi'),
                    subtitle: const Text(
                      'SakuraKotoba (桜言葉) v1.3.0\nSRS SM-2 · Reading Tracker · Grammar & Bungo · Honyaku · Chat Mahasiswa FIB UNDIP',
                    ),
                    isThreeLine: true,
                    trailing: TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.system_update_alt_rounded, size: 16),
                      label: const Text('Cek Update', style: TextStyle(fontSize: 12)),
                      onPressed: () => UpdateCheckerService.instance.checkAndShowUpdateDialog(context, isManualCheck: true),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.system_update_rounded, color: Color(0xFFE11D48)),
                    title: const Text('Pembaruan APK GitHub Releases'),
                    subtitle: const Text('Periksa rilis versi terbaru & unduh APK'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => UpdateCheckerService.instance.checkAndShowUpdateDialog(context, isManualCheck: true),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red.shade400),
                    title: Text(
                      'Keluar dari Akun',
                      style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600),
                    ),
                    onTap: _loggingOut ? null : _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
