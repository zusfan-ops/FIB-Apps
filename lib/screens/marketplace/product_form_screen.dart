import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../models/marketplace_product.dart';
import '../../services/api_client.dart';
import '../../services/image_picker_helper.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../../widgets/smart_image_view.dart';

class ProductFormScreen extends StatefulWidget {
  final MarketplaceProduct? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _location;
  late final TextEditingController _contactWhatsapp;
  late final TextEditingController _imageUrlController;

  String _category = 'buku';
  String _condition = 'bekas_seperti_baru';
  AppPickedFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _loading = false;

  static const List<Map<String, String>> _categories = [
    {'value': 'buku', 'label': '📚 Buku & Modul Kuliah'},
    {'value': 'merchandise', 'label': '🎨 Merchandise & Kriya'},
    {'value': 'elektronik', 'label': '💻 Elektronik & Gadget'},
    {'value': 'fashion', 'label': '👕 Pakaian & Aksesoris'},
    {'value': 'makanan', 'label': '🍱 Kuliner & Snack Kampus'},
    {'value': 'jasa', 'label': '💼 Jasa / Proofreading / Les'},
    {'value': 'lainnya', 'label': '📦 Lainnya'},
  ];

  static const List<Map<String, String>> _conditions = [
    {'value': 'bekas_seperti_baru', 'label': '✨ Bekas Seperti Baru'},
    {'value': 'baru', 'label': '🆕 Baru (Gress)'},
    {'value': 'bekas_layak', 'label': '📖 Bekas Masih Layak'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final user = Session.instance.user;

    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(text: p != null ? p.price.toString() : '');
    _description = TextEditingController(text: p?.description ?? '');
    _location = TextEditingController(text: p?.location ?? 'Gedung A FIB UNDIP');
    _contactWhatsapp = TextEditingController(text: p?.contactWhatsapp ?? user?.phoneNumber ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _category = p?.category ?? 'buku';
    _condition = p?.condition ?? 'bekas_seperti_baru';
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _description.dispose();
    _location.dispose();
    _contactWhatsapp.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final picked = await AppImagePicker.pickImage(fromCamera: fromCamera);

      if (picked != null) {
        setState(() {
          _pickedFile = picked;
          _imageBytes = picked.bytes;
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
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
              const Text('Unggah Foto Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Pilih dari Galeri Foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Ambil Foto dengan Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(fromCamera: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final priceVal = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      String? finalImageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();

      if (_imageBytes != null && _pickedFile != null) {
        try {
          final fields = <String, String>{
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'price': priceVal.toString(),
            'category': _category,
            'condition': _condition,
            'location': _location.text.trim(),
            if (_contactWhatsapp.text.trim().isNotEmpty)
              'contact_whatsapp': _contactWhatsapp.text.trim(),
          };

          if (widget.product == null) {
            await ApiClient.instance.postMultipart(
              '/marketplace-products',
              fields: fields,
              fileField: 'image',
              fileBytes: _imageBytes!,
              filename: _pickedFile!.name,
            );
          } else {
            await ApiClient.instance.postMultipart(
              '/marketplace-products/${widget.product!.id}?_method=PUT',
              fields: fields,
              fileField: 'image',
              fileBytes: _imageBytes!,
              filename: _pickedFile!.name,
            );
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.product == null
                  ? '🛍️ Barang berhasil dipasang di Toko Mahasiswa/i!'
                  : '✨ Data barang berhasil diperbarui!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.of(context).pop(true);
          return;
        } catch (_) {
          // Fallback to Base64
          finalImageUrl = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
        }
      }

      final payload = {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'price': priceVal,
        'category': _category,
        'condition': _condition,
        'image_url': finalImageUrl,
        'location': _location.text.trim().isEmpty ? 'FIB UNDIP Tembalang' : _location.text.trim(),
        'contact_whatsapp': _contactWhatsapp.text.trim().isEmpty ? null : _contactWhatsapp.text.trim(),
      };

      if (widget.product == null) {
        await ApiClient.instance.post('/marketplace-products', payload);
      } else {
        await ApiClient.instance.put('/marketplace-products/${widget.product!.id}', payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null
              ? '🛍️ Barang berhasil dipasang di Toko Mahasiswa/i!'
              : '✨ Data barang berhasil diperbarui!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Jual Barang / Jasa' : 'Edit Barang Jualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Simpan',
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Image Picker Box
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _showImageSourceDialog,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(_imageBytes!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                  onPressed: _showImageSourceDialog,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _imageUrlController.text.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SmartImageView(imageUrl: _imageUrlController.text, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 18,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                      onPressed: _showImageSourceDialog,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              const Text('Unggah Foto Barang / Jasa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('Sentuh untuk memilih dari Galeri atau Kamera', style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 16),

            // Nama Barang
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Nama Barang / Jasa *',
                hintText: 'cth: Kamus Kanji Modern / Modul Nihonshi',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama barang wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            // Harga
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga (Rupiah) *',
                hintText: 'cth: 35000 (Isi 0 jika Gratis/Nego)',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: 'Rp ',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Harga wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            // Kategori & Kondisi
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!, style: const TextStyle(fontSize: 12.5))))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'buku'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'Kondisi Barang',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
              items: _conditions
                  .map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!)))
                  .toList(),
              onChanged: (v) => setState(() => _condition = v ?? 'bekas_seperti_baru'),
            ),
            const SizedBox(height: 14),

            // Lokasi COD
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Lokasi COD / Kampus',
                hintText: 'cth: Gedung A FIB UNDIP / Sekitar Tembalang',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Kontak WhatsApp
            TextFormField(
              controller: _contactWhatsapp,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp Penjual (Opsional)',
                hintText: 'cth: 081234567890',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),

            // Deskripsi
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Barang / Kelengkapan *',
                hintText: 'Jelaskan kondisi buku/barang, alasan dijual, atau ketentuan jasa...',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.storefront_rounded),
              label: Text(_loading ? 'Menyimpan...' : 'Pasang di Toko Mahasiswa/i'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
