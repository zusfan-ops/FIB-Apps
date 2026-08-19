import 'dart:convert';
import 'package:flutter/material.dart';

import '../../models/campus_photo.dart';
import '../../models/direct_message.dart';
import '../../models/marketplace_product.dart';
import '../../models/schedule_item.dart';
import '../../services/api_client.dart';
import '../../services/chat_service.dart';
import '../../services/notification_service.dart';
import '../../services/session.dart';
import '../../services/tab_switcher.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../campus/campus_photo_screen.dart';
import '../campus/class_schedule_screen.dart';
import '../chat/chat_list_screen.dart';
import '../chat/chat_room_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../marketplace/product_detail_screen.dart';
import '../marketplace/product_form_screen.dart';
import '../more/profile_screen.dart';
import '../../widgets/smart_image_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  List<CampusPhoto> _latestPhotos = [];
  List<ChatConversation> _latestConversations = [];
  List<MarketplaceProduct> _latestMarketplaceProducts = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final futures = await Future.wait([
        ApiClient.instance.get('/dashboard'),
        ApiClient.instance.get('/campus-photos?per_page=3'),
        ChatService.instance.getConversations(),
        ApiClient.instance.get('/marketplace-products?per_page=6'),
      ]);

      final data = futures[0];
      final photoRes = futures[1];
      final photoList = (photoRes['data'] as List<dynamic>?) ?? [];
      final convList = (futures[2] as List<ChatConversation>?) ?? [];
      final marketRes = futures[3];
      final marketList = (marketRes is Map<String, dynamic> && marketRes['data'] is List)
          ? (marketRes['data'] as List).map((p) => MarketplaceProduct.fromJson(p as Map<String, dynamic>)).toList()
          : <MarketplaceProduct>[];

      if (mounted) {
        setState(() {
          _data = data as Map<String, dynamic>;
          _latestPhotos = photoList
              .map((p) => CampusPhoto.fromJson(p as Map<String, dynamic>))
              .toList();
          _latestConversations = convList;
          _latestMarketplaceProducts = marketList;
        });

        // Jadwalkan notifikasi harian SRS Review (jam 19.30) jika ada kartu due
        final due = (data as Map<String, dynamic>)['srs_due_count'] as int? ?? 0;
        NotificationService.instance.scheduleDailySrsReminder(dueCount: due);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
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
    final user = Session.instance.user;
    final avatarProvider = _getAvatarProvider(user?.avatarUrl);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            if (mounted) setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primary,
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FIB UNDIP · 桜言葉', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    Text(
                      'Halo, ${user?.name.split(' ').first ?? 'Mahasiswa'} 👋',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          // WhatsApp Style Chat Shortcut with Unread Counter Badge
          ValueListenableBuilder<int>(
            valueListenable: ChatService.instance.totalUnreadNotifier,
            builder: (context, unreadCount, _) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF25D366),
                  child: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                tooltip: 'Chat Mahasiswa FIB',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
                  );
                  _load();
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error.toString(), onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _buildGreeting(),
                      _buildFibUndipQuickActions(),
                      _buildChatCard(),
                      _buildMarketplaceCard(),
                      _buildTimelineCard(),
                      _buildReviewCard(),
                      _buildJlptCard(),
                      _buildTodaySchedule(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChatCard() {
    if (_latestConversations.isEmpty) return const SizedBox.shrink();

    final latest = _latestConversations.first;
    final user = latest.user;
    final lastMsg = latest.lastMessage;
    final avatarProvider = _getAvatarProvider(user.avatarUrl);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: latest.unreadCount > 0
                ? const Color(0xFF10B981).withValues(alpha: 0.6)
                : Colors.grey.shade200,
            width: latest.unreadCount > 0 ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatRoomScreen(recipient: user)),
            );
            _load();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF10B981)),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pesan & Chat Mahasiswa',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChatListScreen()),
                        );
                        _load();
                      },
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua (${_latestConversations.length})',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),

                // Latest Message Content
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF10B981),
                          backgroundImage: avatarProvider,
                          child: avatarProvider == null
                              ? Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                        if (latest.unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${latest.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lastMsg != null)
                                Text(
                                  lastMsg.formattedTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: latest.unreadCount > 0 ? const Color(0xFF10B981) : Colors.grey.shade500,
                                    fontWeight: latest.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (user.studyProgram != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    user.studyProgram!.split(' ').take(3).join(' '),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  lastMsg?.hasAttachment == true
                                      ? '📷 [Foto/Gambar]'
                                      : (lastMsg?.message ?? 'Memulai percakapan baru'),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: latest.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                                    fontWeight: latest.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF047857)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Toko Mahasiswa/i (Preloved & Jasa)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                      );
                      _load();
                    },
                    child: Row(
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_latestMarketplaceProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF047857).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: Color(0xFF047857), size: 28),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punya buku kuliah atau barang preloved?',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Jual langsung ke sesama mahasiswa FIB UNDIP',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final res = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                          );
                          if (res == true) _load();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF047857),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Jual Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 175,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  itemCount: _latestMarketplaceProducts.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    if (idx == _latestMarketplaceProducts.length) {
                      return InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                          );
                          _load();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_circle_right_outlined, color: Color(0xFF047857), size: 28),
                              SizedBox(height: 6),
                              Text(
                                'Buka Toko\nSelengkapnya',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final product = _latestMarketplaceProducts[idx];
                    return InkWell(
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                        );
                        if (changed == true) _load();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Container(
                                height: 85,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                    ? SmartImageView(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.formattedPrice,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      color: Color(0xFF047857),
                                    ),
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    product.categoryLabel,
                                    style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFibUndipQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan Mahasiswa FIB UNDIP',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _quickBtn(
                  icon: Icons.calendar_month,
                  label: 'Jadwal Kuliah',
                  subtitle: '⏰ Reminder',
                  color: const Color(0xFF4F6EF7),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _quickBtn(
                  icon: Icons.chat_rounded,
                  label: 'Chat Mahasiswa',
                  subtitle: 'WhatsApp',
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _quickBtn(
                  icon: Icons.storefront_rounded,
                  label: 'Toko Mahasiswa',
                  subtitle: 'Preloved',
                  color: const Color(0xFF047857),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _quickBtn(
                  icon: Icons.photo_library,
                  label: 'Timeline Foto',
                  subtitle: 'Album',
                  color: const Color(0xFFF43F5E),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CampusPhotoScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    if (_latestPhotos.isEmpty) return const SizedBox.shrink();

    final latest = _latestPhotos.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CampusPhotoScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library, size: 18, color: Color(0xFFF43F5E)),
                    const SizedBox(width: 8),
                    const Text(
                      'Dokumentasi & Timeline Kampus',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),

              // Thumbnail & Details
              Stack(
                children: [
                  SmartImageView(
                    imageUrl: latest.photoUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              latest.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.favorite, size: 12, color: Colors.pinkAccent),
                              const SizedBox(width: 3),
                              Text('${latest.likesCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              const SizedBox(width: 8),
                              const Icon(Icons.chat_bubble, size: 12, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text('${latest.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final user = Session.instance.user;
    final streak = (_data?['streak_days'] ?? 0) as int;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
            if (mounted) setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat belajar, ${user?.name.split(' ').first ?? 'Mahasiswa'}!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.studyProgram ?? user?.university ?? 'FIB UNDIP'}${user?.nim != null ? ' · NIM: ${user!.nim}' : ''} · Target JLPT ${user?.jlptLevel ?? 'N3'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                    const SizedBox(height: 2),
                    Text(
                      '$streak hari',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const Text('streak', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final due = (_data?['due_cards'] ?? 0) as int;
    final reviewsToday = (_data?['reviews_today'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.style, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Ringkasan Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('${_data?['total_cards'] ?? 0}', 'Total kartu'),
                _stat('$due', 'Jatuh tempo'),
                _stat('$reviewsToday', 'Review hari ini'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => TabSwitcher.goTo(TabSwitcher.srs),
                icon: const Icon(Icons.play_arrow),
                label: Text(due > 0 ? 'Mulai Review ($due)' : 'Lihat Deck'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildJlptCard() {
    final target = _data?['jlpt_target'] as Map<String, dynamic>?;
    if (target == null) return const SizedBox.shrink();

    final daysLeft = target['days_left'] as int?;
    final progress = (target['progress_percent'] ?? 0) as int;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined, color: AppColors.accent),
                const SizedBox(width: 8),
                Text('Target ${target['level']}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (daysLeft != null)
                  Text(
                    daysLeft >= 0 ? 'Sisa $daysLeft hari' : 'Lewat ${-daysLeft} hari',
                    style: TextStyle(
                      fontSize: 12,
                      color: daysLeft >= 0 ? Colors.grey.shade600 : AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(target['title'] ?? '',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 6),
            Text('Checklist: ${target['checklist_done']}/${target['checklist_total']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final items = (_data?['today_schedule'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Jadwal Hari Ini',
            trailing: TextButton(
              onPressed: () => TabSwitcher.goTo(TabSwitcher.agenda),
              child: const Text('Lihat semua'),
            ),
          ),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              margin: const EdgeInsets.only(top: 4, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada agenda/kuliah hari ini.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah Jadwal Kuliah', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
                      );
                      _load();
                    },
                  ),
                ],
              ),
            )
          else
            ...items.map((e) {
              final item = ScheduleItem.fromJson(e as Map<String, dynamic>);
              final isKuliah = item.type == 'kuliah';
              final color = isKuliah ? const Color(0xFF4F6EF7) : AppColors.accent;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isKuliah ? const Color(0xFF4F6EF7).withValues(alpha: 0.3) : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    if (isKuliah) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClassScheduleScreen()),
                      );
                    } else {
                      TabSwitcher.goTo(TabSwitcher.agenda);
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      isKuliah ? Icons.school_outlined : Icons.alarm,
                      color: color,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                        ),
                      ),
                      if (item.timeLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (item.course != null && item.course!.isNotEmpty) item.course!,
                      if (item.location != null && item.location!.isNotEmpty) item.location!,
                    ].join(' · '),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ),
              );
            }),
        ],
      ),
    );
  }
}
