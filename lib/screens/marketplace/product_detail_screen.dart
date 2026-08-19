import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/marketplace_product.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/smart_image_view.dart';
import '../chat/chat_room_screen.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final MarketplaceProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late MarketplaceProduct _product;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await ApiClient.instance.get('/marketplace-products/${_product.id}');
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _product = MarketplaceProduct.fromJson(res);
        });
      }
    } catch (_) {}
  }

  bool get _isOwner => Session.instance.user?.id == _product.userId;

  Future<void> _toggleSold() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.patch('/marketplace-products/${_product.id}/toggle-sold', {});
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _product = MarketplaceProduct.fromJson(res);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_product.isSold ? '🏷️ Barang ditandai TERJUAL' : '✅ Barang ditandai TERSEDIA kembali'),
            backgroundColor: _product.isSold ? Colors.orange : const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang Jualan'),
        content: Text('Apakah Anda yakin ingin menghapus "${_product.title}" dari Toko Mahasiswa/i?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ApiClient.instance.delete('/marketplace-products/${_product.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: Colors.black87),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openWhatsApp() async {
    var phone = _product.contactWhatsapp ?? _product.user?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor kontak WhatsApp penjual tidak tersedia.')),
      );
      return;
    }

    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '62${phone.substring(1)}';
    }

    final message = Uri.encodeComponent(
      'Halo kak ${_product.user?.name ?? ''}, saya tertarik dengan barang "${_product.title}" (${_product.formattedPrice}) di Toko Mahasiswa FIB UNDIP. Apakah barang ini masih tersedia?',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
        );
      }
    }
  }

  void _openInAppChat() {
    if (_product.user == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          recipient: _product.user!,
          initialMessage: 'Halo kak, apakah barang "${_product.title}" (${_product.formattedPrice}) di Toko Mahasiswa masih tersedia?',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _product.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        actions: [
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Barang',
              onPressed: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => ProductFormScreen(product: _product)),
                );
                if (updated == true) _fetchDetail();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Hapus Barang',
              onPressed: _loading ? null : _deleteProduct,
            ),
          ],
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          // Gambar Produk
          Stack(
            children: [
              Container(
                height: 260,
                width: double.infinity,
                color: Colors.grey.shade100,
                child: _product.imageUrl != null && _product.imageUrl!.isNotEmpty
                    ? SmartImageView(
                        imageUrl: _product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 260,
                      )
                    : Container(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        child: const Center(
                          child: Icon(Icons.shopping_bag_outlined, size: 72, color: AppColors.primary),
                        ),
                      ),
              ),

              // Status Sold Badge
              if (_product.isSold)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'SUDAH TERJUAL',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 15, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'TERSEDIA',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

              // Condition Badge
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _product.conditionLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Harga Produk
                Text(
                  _product.formattedPrice,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF047857),
                  ),
                ),
                const SizedBox(height: 6),

                // Judul Produk
                Text(
                  _product.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Kategori & Lokasi Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.category_outlined, size: 16, color: AppColors.primary),
                      label: Text(_product.categoryLabel, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
                    if (_product.location != null && _product.location!.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFE11D48)),
                        label: Text(_product.location!, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Profil Penjual (Mahasiswa FIB)
                if (user != null) ...[
                  const Text('Penjual Mahasiswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary,
                            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                                ? Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  user.studyProgram ?? user.university ?? 'FIB UNDIP',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                ),
                                if (user.angkatan != null && user.angkatan!.isNotEmpty)
                                  Text('Angkatan ${user.angkatan}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons for Buyers
                if (!_isOwner && !_product.isSold) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openInAppChat,
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat Mahasiswa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openWhatsApp,
                          icon: const Icon(Icons.phone_iphone_rounded, size: 18),
                          label: const Text('WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],

                // Owner Toggle Action
                if (_isOwner) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _toggleSold,
                      icon: Icon(_product.isSold ? Icons.replay_rounded : Icons.check_circle_rounded),
                      label: Text(_product.isSold ? 'Tandai Barang Tersedia Lagi' : 'Tandai Barang Sudah Terjual'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _product.isSold ? const Color(0xFF10B981) : Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // Deskripsi Detail
                const Text('Deskripsi & Kelengkapan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    _product.description.isEmpty ? 'Tidak ada deskripsi tambahan.' : _product.description,
                    style: const TextStyle(fontSize: 13.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
