import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/direct_message.dart';
import '../../services/chat_service.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/student_profile_dialog.dart';
import 'chat_room_screen.dart';
import 'student_directory_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _loading = true);
    try {
      final list = await ChatService.instance.getConversations();
      if (mounted) {
        setState(() {
          _conversations = list;
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year && now.month == time.month && now.day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays == 1) {
      return 'Kemarin';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Session.instance.user?.id ?? 0;

    final filtered = _conversations.where((conv) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return conv.user.name.toLowerCase().contains(q) ||
          (conv.user.studyProgram?.toLowerCase().contains(q) ?? false) ||
          (conv.lastMessage?.message?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Mahasiswa FIB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Kontak Mahasiswa',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()),
              );
              _loadConversations();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Mulai Chat Baru',
        child: const Icon(Icons.chat),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()),
          );
          _loadConversations();
        },
      ),
      body: Column(
        children: [
          // Search conversations bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama teman atau pesan...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),

          // Conversation List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            final avatarProvider = _getAvatarProvider(conv.user.avatarUrl);
                            final isMeSender = conv.lastMessage?.senderId == currentUserId;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatRoomScreen(recipient: conv.user),
                                  ),
                                );
                                _loadConversations();
                              },
                              leading: GestureDetector(
                                onTap: () => StudentProfileDialog.show(context, conv.user),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  backgroundImage: avatarProvider,
                                  child: avatarProvider == null
                                      ? Text(
                                          conv.user.name.isNotEmpty
                                              ? conv.user.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 20,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conv.user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(conv.updatedAt),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: conv.unreadCount > 0 ? AppColors.primary : Colors.grey.shade500,
                                      fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  if (isMeSender && conv.lastMessage != null) ...[
                                    Icon(
                                      conv.lastMessage!.isRead ? Icons.done_all : Icons.done,
                                      size: 15,
                                      color: conv.lastMessage!.isRead
                                          ? const Color(0xFF34B7F1)
                                          : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  if (conv.lastMessage?.attachmentUrl != null &&
                                      conv.lastMessage!.attachmentUrl!.isNotEmpty) ...[
                                    const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 3),
                                  ],
                                  Expanded(
                                    child: Text(
                                      conv.lastMessage?.message ??
                                          (conv.lastMessage?.attachmentUrl != null ? 'Foto' : ''),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                                        fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  if (conv.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF25D366), // WhatsApp badge green
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        conv.unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Percakapan Mahasiswa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai mengobrol dan berdiskusi dengan mahasiswa FIB UNDIP sekarang!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudentDirectoryScreen()),
                );
                _loadConversations();
              },
              icon: const Icon(Icons.person_search_rounded, color: Colors.white),
              label: const Text('Cari Kontak Teman Mahasiswa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
