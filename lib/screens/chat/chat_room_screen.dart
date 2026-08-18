import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/direct_message.dart';
import '../../models/user.dart';
import '../../services/chat_service.dart';
import '../../services/image_picker_helper.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/student_profile_dialog.dart';

class ChatRoomScreen extends StatefulWidget {
  final User recipient;

  const ChatRoomScreen({super.key, required this.recipient});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DirectMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollingTimer;

  // Selected quick phrase suggestions
  static const List<String> _quickPhrases = [
    'こんにちは！ (Halo!)',
    '課題について聞きたいです (Mau tanya tentang tugas)',
    '一緒に勉強しましょう！ (Ayo belajar bareng!)',
    'ありがとうございます！ (Terima kasih!)',
    'お疲れ様でした (Kerja bagus/semangat)',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages(initial: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(initial: false);
    });
  }

  Future<void> _loadMessages({bool initial = false}) async {
    if (initial) {
      setState(() => _loading = true);
    }
    try {
      final data = await ChatService.instance.getChatHistory(widget.recipient.id);
      final newMessages = data['messages'] as List<DirectMessage>;

      if (mounted) {
        final hadMessagesCount = _messages.length;
        setState(() {
          _messages = newMessages;
          _loading = false;
        });

        // Scroll to bottom jika ada pesan baru atau saat initial load
        if (initial || newMessages.length > hadMessagesCount) {
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted && initial) {
        setState(() => _loading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({Uint8List? imageBytes, String? filename}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageBytes == null) return;

    _messageController.clear();
    setState(() => _sending = true);

    try {
      final sent = await ChatService.instance.sendMessage(
        recipientId: widget.recipient.id,
        message: text.isNotEmpty ? text : null,
        imageBytes: imageBytes,
        filename: filename,
      );

      if (mounted) {
        setState(() {
          _messages.add(sent);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage({bool fromCamera = false}) async {
    try {
      final picked = await AppImagePicker.pickImage(fromCamera: fromCamera);
      if (picked != null) {
        await _sendMessage(imageBytes: picked.bytes, filename: picked.name);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kirim Lampiran Gambar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Galeri Foto'),
                subtitle: const Text('Pilih foto materi/catatan kuliah dari galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Ambil Foto Kamera'),
                subtitle: const Text('Ambil foto langsung dokumen atau buku'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(fromCamera: true);
                },
              ),
            ],
          ),
        ),
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

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1)),
                        fit: BoxFit.contain,
                      )
                    : Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Session.instance.user?.id ?? 0;
    final avatarProvider = _getAvatarProvider(widget.recipient.avatarUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFEFEAE2), // WhatsApp subtle background tint
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: InkWell(
          onTap: () => StudentProfileDialog.show(context, widget.recipient, showChatButton: false),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white24,
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        widget.recipient.name.isNotEmpty
                            ? widget.recipient.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipient.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.recipient.studyProgram ?? 'Mahasiswa FIB UNDIP',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Profil Mahasiswa',
            onPressed: () => StudentProfileDialog.show(context, widget.recipient, showChatButton: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.senderId == currentUserId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Quick Japanese & Academic Phrases
          Container(
            height: 38,
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: _quickPhrases.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final phrase = _quickPhrases[idx];
                return ActionChip(
                  label: Text(
                    phrase,
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _messageController.text = phrase;
                  },
                );
              },
            ),
          ),

          // Bottom Message Input Bar (WhatsApp style)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: _sending ? null : _showAttachmentSheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    onPressed: _sending ? null : () => _pickAndSendImage(fromCamera: true),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan chat...',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : () => _sendMessage(),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: _sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'Mulai percakapan dengan ${widget.recipient.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kirim pesan diskusi tugas, riset, atau bahasa Jepang',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DirectMessage msg, bool isMe) {
    final timeStr = '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white, // WhatsApp bubble colors
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Attachment if present
            if (msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showImagePreview(msg.attachmentUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: msg.attachmentUrl!.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(msg.attachmentUrl!.substring(msg.attachmentUrl!.indexOf(',') + 1)),
                            fit: BoxFit.cover,
                          )
                        : Image.network(msg.attachmentUrl!, fit: BoxFit.cover),
                  ),
                ),
              ),
              if (msg.message != null && msg.message!.isNotEmpty) const SizedBox(height: 6),
            ],

            // Message text
            if (msg.message != null && msg.message!.isNotEmpty)
              Text(
                msg.message!,
                style: const TextStyle(fontSize: 14.5, color: Colors.black87),
              ),

            const SizedBox(height: 2),

            // Time & Checkmark
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg.isRead ? const Color(0xFF34B7F1) : Colors.grey.shade500,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
