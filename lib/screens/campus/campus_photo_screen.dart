import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/campus_photo.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/smart_image_view.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/student_profile_dialog.dart';
import '../chat/chat_room_screen.dart';
import 'campus_photo_upload_screen.dart';

class CampusPhotoScreen extends StatefulWidget {
  const CampusPhotoScreen({super.key});

  @override
  State<CampusPhotoScreen> createState() => _CampusPhotoScreenState();
}

class _CampusPhotoScreenState extends State<CampusPhotoScreen> {
  bool _loading = true;
  List<CampusPhoto> _photos = [];
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'Semua Momen'},
    {'id': 'bunkasai', 'label': 'Bunkasai'},
    {'id': 'seminar', 'label': 'Seminar'},
    {'id': 'kuliah', 'label': 'Perkuliahan'},
    {'id': 'organisasi', 'label': 'Organisasi'},
    {'id': 'wisuda', 'label': 'Wisuda'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loading = true);
    try {
      String path = '/campus-photos?per_page=30';
      if (_selectedCategory != 'all') {
        path += '&category=$_selectedCategory';
      }

      final res = await ApiClient.instance.get(path);
      final rawList = (res['data'] as List<dynamic>?) ?? [];
      setState(() {
        _photos = rawList
            .map((item) => CampusPhoto.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat timeline foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleLike(CampusPhoto photo) async {
    // Optimistic UI update
    setState(() {
      photo.isLiked = !photo.isLiked;
      photo.likesCount += photo.isLiked ? 1 : -1;
    });

    try {
      final res = await ApiClient.instance.post('/campus-photos/${photo.id}/like', {});
      if (res != null && res is Map<String, dynamic> && res['likes_count'] != null) {
        setState(() {
          photo.likesCount = res['likes_count'] as int;
          photo.isLiked = res['liked'] as bool;
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        photo.isLiked = !photo.isLiked;
        photo.likesCount += photo.isLiked ? 1 : -1;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui like: $e')),
      );
    }
  }

  Future<void> _shareToWhatsApp(CampusPhoto photo) async {
    final shareUrl = 'https://fib.ordr.my.id/p/${photo.id}';
    final message = '📸 ${photo.title}\n${photo.description ?? ""}\n\nLihat foto dokumentasi kegiatan FIB UNDIP: $shareUrl';
    final waUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tautan disalin: $shareUrl')),
      );
    }
  }

  void _openCommentsModal(CampusPhoto photo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PhotoCommentsSheet(photo: photo),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline & Dokumentasi Kampus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Unggah Momen'),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CampusPhotoUploadScreen()),
          );
          if (res == true) _loadPhotos();
        },
      ),
      body: Column(
        children: [
          // Filter Kategori
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['id'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat['id']!);
                      _loadPhotos();
                    }
                  },
                );
              },
            ),
          ),

          // Timeline Feed List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _photos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_album_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada momen kampus di kategori ini',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Jadilah mahasiswa pertama yang mengunggah foto!',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPhotos,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            final photo = _photos[index];
                            return _buildPhotoCard(photo, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
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

  void _openUploaderProfile(CampusPhoto photo) {
    final student = User(
      id: photo.userId,
      name: photo.uploaderName ?? 'Mahasiswa FIB UNDIP',
      email: '',
      nim: photo.uploaderNim,
      studyProgram: photo.uploaderStudyProgram ?? photo.uploaderUniversity,
      university: photo.uploaderUniversity,
      jlptLevel: photo.uploaderJlpt,
      avatarUrl: photo.uploaderAvatar,
    );
    StudentProfileDialog.show(context, student);
  }

  Widget _buildPhotoCard(CampusPhoto photo, ThemeData theme) {
    final currentUserId = Session.instance.user?.id ?? 0;
    final isNotMe = photo.userId != 0 && photo.userId != currentUserId;
    final avatarProvider = _getAvatarProvider(photo.uploaderAvatar);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Pengunggah
          InkWell(
            onTap: () => _openUploaderProfile(photo),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFF43F5E),
                    foregroundColor: Colors.white,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? Text(
                            (photo.uploaderName ?? 'M')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.uploaderName ?? 'Mahasiswa Sastra Jepang',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${photo.uploaderStudyProgram ?? photo.location} · ${photo.eventDate ?? ""}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      photo.category.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF43F5E)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foto Utama (Full Image - SmartImageView)
          InkWell(
            onTap: () => _openCommentsModal(photo),
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade100,
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 520,
              ),
              child: SmartImageView(
                imageUrl: photo.photoUrl,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Action Bar: Like, Komentar, Chat Mahasiswa, Share WhatsApp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Tombol Like
                IconButton(
                  icon: Icon(
                    photo.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: photo.isLiked ? const Color(0xFFF43F5E) : Colors.grey.shade700,
                  ),
                  onPressed: () => _toggleLike(photo),
                ),
                Text(
                  '${photo.likesCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),

                // Tombol Komentar
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _openCommentsModal(photo),
                ),
                Text(
                  '${photo.commentsCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),

                // Chat Mahasiswa Button (jika bukan postingan sendiri)
                if (isNotMe) ...[
                  IconButton(
                    icon: const Icon(Icons.chat_rounded, color: AppColors.primary, size: 20),
                    tooltip: 'Chat Mahasiswa Pengunggah',
                    onPressed: () {
                      final student = User(
                        id: photo.userId,
                        name: photo.uploaderName ?? 'Mahasiswa FIB UNDIP',
                        email: '',
                        nim: photo.uploaderNim,
                        studyProgram: photo.uploaderStudyProgram ?? photo.uploaderUniversity,
                        university: photo.uploaderUniversity,
                        jlptLevel: photo.uploaderJlpt,
                        avatarUrl: photo.uploaderAvatar,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChatRoomScreen(recipient: student)),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],

                // Tombol Share WhatsApp
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFF25D366)),
                  ),
                  icon: const Icon(Icons.share, size: 14, color: Color(0xFF25D366)),
                  label: const Text(
                    'WA',
                    style: TextStyle(color: Color(0xFF25D366), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _shareToWhatsApp(photo),
                ),
              ],
            ),
          ),

          // Judul & Keterangan Foto
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (photo.description != null && photo.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    photo.description!,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                  ),
                ],
                if (photo.commentsCount > 0) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _openCommentsModal(photo),
                    child: Text(
                      'Lihat semua ${photo.commentsCount} komentar...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCommentsSheet extends StatefulWidget {
  final CampusPhoto photo;
  const _PhotoCommentsSheet({required this.photo});

  @override
  State<_PhotoCommentsSheet> createState() => _PhotoCommentsSheetState();
}

class _PhotoCommentsSheetState extends State<_PhotoCommentsSheet> {
  final _commentController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  List<PhotoComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final res = await ApiClient.instance.get('/campus-photos/${widget.photo.id}/comments');
      final list = (res is List<dynamic>)
          ? res
          : (res is Map<String, dynamic> && res['data'] is List)
              ? res['data'] as List<dynamic>
              : <dynamic>[];

      setState(() {
        _comments = list.map((c) => PhotoComment.fromJson(c as Map<String, dynamic>)).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final res = await ApiClient.instance.post('/campus-photos/${widget.photo.id}/comments', {
        'comment': text,
      });

      if (res != null && res is Map<String, dynamic>) {
        final newComment = PhotoComment.fromJson(res);
        setState(() {
          _comments.add(newComment);
          widget.photo.commentsCount += 1;
        });
        _commentController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komentar berhasil dikirim!')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim komentar: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.chat, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Komentar (${_comments.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),

            // Daftar Komentar
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada komentar. Jadilah yang pertama berkomentar!',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _comments.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(
                                    (c.userName ?? 'M')[0].toUpperCase(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.userName ?? 'Mahasiswa',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(c.comment, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
            ),

            // Input Komentar
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar untuk momen ini...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 18),
                  onPressed: _submitting ? null : _submitComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
