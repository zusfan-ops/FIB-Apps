import 'package:flutter/material.dart';

import '../../models/campus_diary.dart';
import '../../services/api_client.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import 'campus_diary_form_screen.dart';

class CampusDiaryScreen extends StatefulWidget {
  const CampusDiaryScreen({super.key});

  @override
  State<CampusDiaryScreen> createState() => _CampusDiaryScreenState();
}

class _CampusDiaryScreenState extends State<CampusDiaryScreen> {
  List<CampusDiary> _diaries = [];
  bool _loading = true;
  String? _selectedCategory;
  final TextEditingController _searchCtrl = TextEditingController();

  final _categories = [
    {'key': 'all', 'label': 'Semua'},
    {'key': 'kuliah', 'label': 'Kuliah'},
    {'key': 'bimbingan', 'label': 'Bimbingan'},
    {'key': 'organisasi', 'label': 'Organisasi'},
    {'key': 'belajar', 'label': 'Belajar'},
    {'key': 'refleksi', 'label': 'Refleksi'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final queryParams = <String, String>{};
      if (_selectedCategory != null && _selectedCategory != 'all') {
        queryParams['category'] = _selectedCategory!;
      }
      if (_searchCtrl.text.trim().isNotEmpty) {
        queryParams['search'] = _searchCtrl.text.trim();
      }

      final uri = Uri(path: '/campus-diaries', queryParameters: queryParams.isEmpty ? null : queryParams);
      final res = await ApiClient.instance.get(uri.toString());

      List<CampusDiary> list = [];
      if (res is Map<String, dynamic> && res['data'] is List) {
        list = (res['data'] as List)
            .map((e) => CampusDiary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (res is List) {
        list = res.map((e) => CampusDiary.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (mounted) {
        setState(() {
          _diaries = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat diary: $e')),
        );
      }
    }
  }

  Future<void> _deleteDiary(CampusDiary diary) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Hapus "${diary.title}" dari diary kampus Anda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await ApiClient.instance.delete('/campus-diaries/${diary.id}');
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Kampus & Diary'),
      ),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.edit),
        label: const Text('Tulis Diary'),
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CampusDiaryFormScreen()),
          );
          if (res == true) _load();
        },
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari catatan perkuliahan, bimbingan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = (_selectedCategory == null && cat['key'] == 'all') ||
                    _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat['key'] == 'all' ? null : cat['key'];
                      });
                      _load();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Diary List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _diaries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_stories_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada catatan diary di kategori ini',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Tulis Diary Pertama'),
                              onPressed: () async {
                                final res = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const CampusDiaryFormScreen()),
                                );
                                if (res == true) _load();
                              },
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _diaries.length,
                          itemBuilder: (context, i) {
                            final diary = _diaries[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: diary.isPinned
                                      ? Colors.amber.shade400
                                      : Colors.grey.shade200,
                                  width: diary.isPinned ? 1.5 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          diary.moodEmoji,
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                diary.entryDate,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                diary.category.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFFF43F5E),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (diary.isPinned)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.push_pin,
                                                    size: 12, color: Colors.amber),
                                                SizedBox(width: 4),
                                                Text(
                                                  'PINNED',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.amber),
                                                ),
                                              ],
                                            ),
                                          ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, size: 20),
                                          onSelected: (action) async {
                                            if (action == 'edit') {
                                              final res = await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CampusDiaryFormScreen(diary: diary),
                                                ),
                                              );
                                              if (res == true) _load();
                                            } else if (action == 'delete') {
                                              _deleteDiary(diary);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                                value: 'edit', child: Text('Edit')),
                                            const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Hapus',
                                                    style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      diary.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      diary.content,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    if (diary.tags.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 6,
                                        children: diary.tags
                                            .map(
                                              (t) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '#$t',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ],
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
