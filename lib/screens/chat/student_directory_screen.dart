import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/chat_service.dart';
import '../../theme.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/student_profile_dialog.dart';
import 'chat_room_screen.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _students = [];
  bool _loading = true;
  String _selectedProdi = 'Semua Prodi';

  static const List<String> _prodiFilterOptions = [
    'Semua Prodi',
    'S1 Bahasa dan Kebudayaan Jepang',
    'S1 Sastra Indonesia',
    'S1 Sastra Inggris',
    'S1 Sejarah',
    'S1 Ilmu Perpustakaan dan Informasi',
    'S1 Antropologi Sosial',
  ];

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory() async {
    setState(() => _loading = true);
    try {
      final list = await ChatService.instance.getStudentDirectory(
        search: _searchController.text.trim(),
        studyProgram: _selectedProdi,
      );
      if (mounted) {
        setState(() {
          _students = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  ImageProvider? _getAvatarProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('data:image')) {
      try {
        final commaIdx = avatarUrl.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(avatarUrl.substring(commaIdx + 1));
          return MemoryImage(bytes);
        }
      } catch (_) {}
    }
    return NetworkImage(avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak Mahasiswa FIB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDirectory,
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Nama, NIM, atau Prodi...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadDirectory();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (_) => _loadDirectory(),
            ),
          ),

          // Prodi Horizontal Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _prodiFilterOptions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final prodi = _prodiFilterOptions[idx];
                final isSelected = _selectedProdi == prodi;
                return ChoiceChip(
                  label: Text(
                    prodi == 'Semua Prodi' ? 'Semua' : prodi.replaceFirst('S1 ', ''),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedProdi = prodi);
                      _loadDirectory();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Student List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('Mahasiswa tidak ditemukan', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDirectory,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _students.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final avatarProvider = _getAvatarProvider(student.avatarUrl);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ChatRoomScreen(recipient: student),
                                    ),
                                  );
                                },
                                leading: GestureDetector(
                                  onTap: () => StudentProfileDialog.show(context, student),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    backgroundImage: avatarProvider,
                                    child: avatarProvider == null
                                        ? Text(
                                            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        student.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ),
                                    if (student.jlptLevel != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'JLPT ${student.jlptLevel}',
                                          style: const TextStyle(
                                            color: Color(0xFFF43F5E),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (student.nim != null && student.nim!.isNotEmpty)
                                      Text(
                                        'NIM: ${student.nim}',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                                      ),
                                    Text(
                                      student.studyProgram ?? 'FIB Universitas Diponegoro',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatRoomScreen(recipient: student),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
