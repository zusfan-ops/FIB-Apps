import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/image_picker_helper.dart';

class CampusPhotoUploadScreen extends StatefulWidget {
  const CampusPhotoUploadScreen({super.key});

  @override
  State<CampusPhotoUploadScreen> createState() => _CampusPhotoUploadScreenState();
}

class _CampusPhotoUploadScreenState extends State<CampusPhotoUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _photoUrl = TextEditingController();
  final _location = TextEditingController(text: 'FIB Universitas Diponegoro');

  String _category = 'kegiatan';
  bool _isPublic = true;
  bool _loading = false;

  AppPickedFile? _pickedFile;
  Uint8List? _imageBytes;

  final _presets = [
    {
      'name': 'Bunkasai & Festival Budaya',
      'url': 'https://images.unsplash.com/photo-1528164344705-475426879c0d?w=800&q=80',
    },
    {
      'name': 'Seminar & Teater Lingkar FIB',
      'url': 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&q=80',
    },
    {
      'name': 'Belajar Bersama Gazebo FIB',
      'url': 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=800&q=80',
    },
    {
      'name': 'Perpustakaan & Riset Sastra',
      'url': 'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800&q=80',
    },
    {
      'name': 'Wisuda & Kelulusan Sarjana',
      'url': 'https://images.unsplash.com/photo-1627556704302-624286467c65?w=800&q=80',
    },
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _photoUrl.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final picked = await AppImagePicker.pickImage(fromCamera: fromCamera);

      if (picked != null) {
        setState(() {
          _pickedFile = picked;
          _imageBytes = picked.bytes;
          _photoUrl.clear();
          if (_title.text.isEmpty) {
            _title.text = 'Dokumentasi Kampus ${DateTime.now().year}';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar: $e')),
      );
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _photoUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto dari galeri atau masukkan tautan foto')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_imageBytes != null && _pickedFile != null) {
        try {
          // 1. Coba Multipart File Upload
          final fields = <String, String>{
            'title': _title.text.trim(),
            if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
            'location': _location.text.trim().isEmpty ? 'FIB UNDIP' : _location.text.trim(),
            'category': _category,
            'is_public': _isPublic ? '1' : '0',
          };

          await ApiClient.instance.postMultipart(
            '/campus-photos',
            fields: fields,
            fileField: 'photo',
            fileBytes: _imageBytes!,
            filename: _pickedFile!.name,
          );
        } catch (_) {
          // 2. Fallback aman ke Base64 Data URI jika permission storage server terbatas
          final base64Image = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
          final payload = {
            'title': _title.text.trim(),
            'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
            'photo_url': base64Image,
            'location': _location.text.trim().isEmpty ? 'FIB UNDIP' : _location.text.trim(),
            'category': _category,
            'is_public': _isPublic,
          };
          await ApiClient.instance.post('/campus-photos', payload);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diunggah ke Timeline Kampus!')),
        );
        Navigator.of(context).pop(true);
      } else {
        // Upload Menggunakan URL / Preset
        final payload = {
          'title': _title.text.trim(),
          'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
          'photo_url': _photoUrl.text.trim(),
          'location': _location.text.trim().isEmpty ? 'FIB UNDIP' : _location.text.trim(),
          'category': _category,
          'is_public': _isPublic,
        };

        await ApiClient.instance.post('/campus-photos', payload);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto dokumentasi berhasil dibagikan ke timeline!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membagikan foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Momen FIB UNDIP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _loading ? null : _upload,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview & Picker Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                children: [
                  if (_imageBytes != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else if (_photoUrl.text.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _photoUrl.text,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Container(
                          height: 120,
                          color: Colors.grey.shade200,
                          child: const Center(child: Text('Tautan gambar tidak dapat dimuat')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else ...[
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 42, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Pilih foto dokumentasi dari HP atau komputer',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Tombol Picker Galeri & Kamera (Bekerja di Web / PWA dan Android/iOS)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeri HP / File'),
                          onPressed: () => _pickImage(fromCamera: false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Kamera'),
                          onPressed: () => _pickImage(fromCamera: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Judul Kegiatan / Momen *',
                hintText: 'cth: Penampilan Bunkasai Sastra Jepang 2026',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            // Opsi Alternatif URL
            ExpansionTile(
              title: const Text('Atau gunakan URL / Contoh Template Foto', style: TextStyle(fontSize: 13)),
              leading: const Icon(Icons.link, size: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _photoUrl,
                        decoration: const InputDecoration(
                          labelText: 'URL Foto Gambar Eksternal',
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: Icon(Icons.link_outlined),
                        ),
                        onChanged: (_) {
                          if (_photoUrl.text.isNotEmpty) {
                            setState(() {
                              _pickedFile = null;
                              _imageBytes = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _presets.map((p) {
                          return ActionChip(
                            avatar: const Icon(Icons.photo_camera_back, size: 14),
                            label: Text(p['name']!, style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              setState(() {
                                _pickedFile = null;
                                _imageBytes = null;
                                _photoUrl.text = p['url']!;
                                if (_title.text.isEmpty) _title.text = p['name']!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Acara',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bunkasai', child: Text('Bunkasai & Kebudayaan')),
                      DropdownMenuItem(value: 'seminar', child: Text('Seminar / Kuliah Umum')),
                      DropdownMenuItem(value: 'kuliah', child: Text('Perkuliahan / Praktikum')),
                      DropdownMenuItem(value: 'organisasi', child: Text('Himpunan / Organisasi')),
                      DropdownMenuItem(value: 'wisuda', child: Text('Wisuda / Kelulusan')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? 'kegiatan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Lokasi Kegiatan',
                hintText: 'cth: Teater Lingkar FIB UNDIP',
                prefixIcon: Icon(Icons.place),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Keterangan / Cerita Momen',
                hintText: 'Ceritakan keseruan acara atau penjelasan foto ini...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Publikasikan ke Timeline Mahasiswa'),
              subtitle: const Text('Foto dapat dilihat, disukai, dan dikomentari oleh sesama mahasiswa'),
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_loading ? 'Mengunggah Foto...' : 'Bagikan ke Timeline'),
              onPressed: _loading ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }
}
