import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/image_picker_helper.dart';
import '../../services/session.dart';
import '../../theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _universityController;
  late TextEditingController _bioController;
  String _jlptLevel = 'N3';
  String _studyProgram = 'S1 Bahasa dan Kebudayaan Jepang';

  AppPickedFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _saving = false;

  final List<String> _jlptOptions = ['N5', 'N4', 'N3', 'N2', 'N1'];

  static const List<String> _studyProgramOptions = [
    'S1 Bahasa dan Kebudayaan Jepang',
    'S1 Sastra Indonesia',
    'S1 Sastra Inggris',
    'S1 Sejarah',
    'S1 Ilmu Perpustakaan dan Informasi',
    'S1 Antropologi Sosial',
    'S2 Magister Ilmu Susastra',
    'S2 Magister Ilmu Linguistik',
    'S2 Magister Ilmu Sejarah',
    'S3 Doktor Sejarah',
  ];

  @override
  void initState() {
    super.initState();
    final user = Session.instance.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _universityController =
        TextEditingController(text: user?.university ?? 'FIB Universitas Diponegoro');
    _bioController = TextEditingController(text: user?.bio ?? '');
    if (user?.jlptLevel != null && _jlptOptions.contains(user!.jlptLevel)) {
      _jlptLevel = user.jlptLevel!;
    }
    if (user?.studyProgram != null && _studyProgramOptions.contains(user!.studyProgram)) {
      _studyProgram = user.studyProgram!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final picked = await AppImagePicker.pickImage(fromCamera: fromCamera);
      if (picked != null) {
        setState(() {
          _pickedFile = picked;
          _imageBytes = picked.bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  void _showImageSourceSheet() {
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
                'Pilih Foto Profil Mahasiswa',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Buka Galeri Foto'),
                subtitle: const Text('Pilih dari penyimpanan galeri perangkat'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(fromCamera: false);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Ambil Foto Kamera'),
                subtitle: const Text('Gunakan kamera langsung'),
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

    setState(() => _saving = true);

    try {
      final name = _nameController.text.trim();
      final university = _universityController.text.trim();
      final bio = _bioController.text.trim();

      dynamic responseData;

      if (_imageBytes != null && _pickedFile != null) {
        try {
          // 1. Coba Multipart File Upload
          final fields = <String, String>{
            'name': name,
            'university': university,
            'study_program': _studyProgram,
            'jlpt_level': _jlptLevel,
            if (bio.isNotEmpty) 'bio': bio,
          };

          responseData = await ApiClient.instance.postMultipart(
            '/auth/profile',
            fields: fields,
            fileField: 'avatar',
            fileBytes: _imageBytes!,
            filename: _pickedFile!.name,
          );
        } catch (_) {
          // 2. Fallback aman ke Base64 Data URI jika server storage direct tidak writeable
          final base64Image = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
          final payload = {
            'name': name,
            'university': university,
            'study_program': _studyProgram,
            'jlpt_level': _jlptLevel,
            'bio': bio.isEmpty ? null : bio,
            'avatar_url': base64Image,
          };
          responseData = await ApiClient.instance.post('/auth/profile', payload);
        }
      } else {
        final payload = {
          'name': name,
          'university': university,
          'study_program': _studyProgram,
          'jlpt_level': _jlptLevel,
          'bio': bio.isEmpty ? null : bio,
        };
        responseData = await ApiClient.instance.post('/auth/profile', payload);
      }

      if (responseData is Map<String, dynamic>) {
        final updatedUser = User.fromJson(responseData);
        await Session.instance.updateUser(updatedUser);
      } else {
        // Fallback fetch fresh user data
        final meData = await ApiClient.instance.get('/auth/me');
        if (meData is Map<String, dynamic>) {
          final updatedUser = User.fromJson(meData);
          await Session.instance.updateUser(updatedUser);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Profil mahasiswa & foto berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user;

    ImageProvider? avatarImageProvider;
    if (_imageBytes != null) {
      avatarImageProvider = MemoryImage(_imageBytes!);
    } else if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
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
        title: const Text('Edit Profil Mahasiswa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Edit Section with Badge Button
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.primary,
                      backgroundImage: avatarImageProvider,
                      child: avatarImageProvider == null
                          ? Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'M',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(
                          side: BorderSide(color: Colors.white, width: 2.5),
                        ),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showImageSourceSheet,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showImageSourceSheet,
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Ganti Foto Profil'),
              ),
              const SizedBox(height: 20),

              // Form fields
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap Mahasiswa *',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _studyProgram,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Program Studi FIB UNDIP *',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        items: _studyProgramOptions
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _studyProgram = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _universityController,
                        decoration: const InputDecoration(
                          labelText: 'Fakultas / Universitas',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Target JLPT:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _jlptOptions.map((lvl) {
                          final isSelected = _jlptLevel == lvl;
                          return ChoiceChip(
                            label: Text('JLPT $lvl'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            onSelected: (_) => setState(() => _jlptLevel = lvl),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio / Catatan Mahasiswa',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                          hintText: 'Tuliskan minat sastra, fokus riset, atau moto belajar...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Menyimpan Perubahan...' : 'Simpan Profil Mahasiswa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
