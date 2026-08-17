import 'package:flutter/material.dart';

import '../../models/campus_diary.dart';
import '../../services/api_client.dart';

class CampusDiaryFormScreen extends StatefulWidget {
  final CampusDiary? diary;

  const CampusDiaryFormScreen({super.key, this.diary});

  @override
  State<CampusDiaryFormScreen> createState() => _CampusDiaryFormScreenState();
}

class _CampusDiaryFormScreenState extends State<CampusDiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _tags;

  DateTime _entryDate = DateTime.now();
  String _mood = 'semangat';
  String _category = 'kuliah';
  bool _isPinned = false;
  bool _loading = false;

  final _moodOptions = [
    {'key': 'semangat', 'label': 'Semangat 🔥'},
    {'key': 'fokus', 'label': 'Fokus 📚'},
    {'key': 'santai', 'label': 'Santai ☕'},
    {'key': 'produktif', 'label': 'Produktif 🎯'},
    {'key': 'lelah', 'label': 'Lelah 😴'},
  ];

  final _categoryOptions = [
    {'key': 'kuliah', 'label': 'Perkuliahan'},
    {'key': 'bimbingan', 'label': 'Bimbingan Dosen'},
    {'key': 'organisasi', 'label': 'Kegiatan Organisasi / Himpunan'},
    {'key': 'belajar', 'label': 'Belajar Mandiri / JLPT'},
    {'key': 'refleksi', 'label': 'Refleksi / Diary Pribadi'},
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.diary;
    _title = TextEditingController(text: d?.title ?? '');
    _content = TextEditingController(text: d?.content ?? '');
    _tags = TextEditingController(text: d?.tags.join(', ') ?? '');
    if (d?.entryDate != null) {
      _entryDate = DateTime.tryParse(d!.entryDate) ?? DateTime.now();
    }
    _mood = d?.mood ?? 'semangat';
    _category = d?.category ?? 'kuliah';
    _isPinned = d?.isPinned ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final tagList = _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final payload = {
        'title': _title.text.trim(),
        'content': _content.text.trim(),
        'entry_date': _entryDate.toIso8601String().substring(0, 10),
        'mood': _mood,
        'category': _category,
        'tags': tagList,
        'is_pinned': _isPinned,
      };

      if (widget.diary == null) {
        await ApiClient.instance.post('/campus-diaries', payload);
      } else {
        await ApiClient.instance.put('/campus-diaries/${widget.diary!.id}', payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.diary == null
              ? 'Catatan diary berhasil disimpan'
              : 'Catatan diary berhasil diperbarui'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan diary: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diary == null ? 'Tulis Catatan Kampus' : 'Edit Catatan Kampus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _loading ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Judul Catatan / Diary *',
                hintText: 'cth: Diskusi Sastra di Perpustakaan FIB',
                prefixIcon: Icon(Icons.edit_note),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Kegiatan',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categoryOptions
                        .map((c) => DropdownMenuItem(
                              value: c['key']!,
                              child: Text(c['label']!),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'kuliah'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Suasana Hati (Mood) Hari Ini:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _moodOptions.map((m) {
                final selected = _mood == m['key'];
                return ChoiceChip(
                  label: Text(m['label']!),
                  selected: selected,
                  onSelected: (val) {
                    if (val) setState(() => _mood = m['key']!);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _content,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan / Diary *',
                hintText: 'Tuliskan pengalaman perkuliahan, poin bimbingan, atau refleksi hari ini...',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi catatan wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(
                labelText: 'Tag / Label (Pisahkan dengan koma)',
                hintText: 'sastra, bimbingan, skripsi, bunkasai',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Sematkan Catatan (Pin to Top)'),
              subtitle: const Text('Tampilkan di bagian paling atas daftar catatan'),
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_loading ? 'Menyimpan...' : 'Simpan Catatan'),
              onPressed: _loading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
