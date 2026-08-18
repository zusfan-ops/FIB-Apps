import 'dart:convert';
import 'package:flutter/material.dart';

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
        title: const Text('Profil'),
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
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        backgroundImage: avatarImageProvider,
                        child: avatarImageProvider == null
                            ? Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (user?.jlptLevel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Target JLPT ${user!.jlptLevel}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
                      label: const Text(
                        'Edit Profil & Foto Mahasiswa',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            const SizedBox(height: 12),

            // Study Program info
            if (user?.studyProgram != null && user!.studyProgram!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: AppColors.primary),
                  title: Text(user.studyProgram!),
                  subtitle: const Text('Program Studi'),
                ),
              ),

            // University info
            if (user?.university != null && user!.university!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_outlined, color: AppColors.primary),
                  title: Text(user.university!),
                  subtitle: const Text('Fakultas / Universitas'),
                ),
              ),

            // Bio info
            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.format_quote_outlined, color: AppColors.primary),
                  title: const Text('Catatan & Minat Sastra'),
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
                      'SakuraKotoba (桜言葉) v1.2.0\nSRS SM-2 · Reading Tracker · Grammar & Bungo · Honyaku · Agenda FIB UNDIP',
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
                      'Keluar',
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

