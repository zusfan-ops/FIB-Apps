import 'package:flutter/material.dart';

import '../../models/grammar_pattern.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'grammar_form_screen.dart';
import 'grammar_detail_screen.dart';
import '../../widgets/global_bottom_nav_bar.dart';

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  List<GrammarPattern>? _patterns;
  Object? _error;
  final _search = TextEditingController();
  bool _bungoOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final query = <String>[];
      if (_search.text.trim().isNotEmpty) {
        query.add('q=${Uri.encodeQueryComponent(_search.text.trim())}');
      }
      if (_bungoOnly) query.add('bungo=1');
      final suffix = query.isEmpty ? '' : '?${query.join('&')}';

      final data = await ApiClient.instance.get('/grammar$suffix') as List;
      if (mounted) {
        setState(() => _patterns = data
            .map((e) => GrammarPattern.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GrammarFormScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar')),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Pola'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'Cari pola / arti...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _search.clear();
                          _load();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('文語\nbungo'),
                  labelStyle: const TextStyle(fontSize: 11),
                  selected: _bungoOnly,
                  onSelected: (v) {
                    setState(() => _bungoOnly = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_patterns == null) return const LoadingView();

    final patterns = _patterns!;
    if (patterns.isEmpty) {
      return const EmptyState(
          message: 'Belum ada catatan grammar.', icon: Icons.menu_book_outlined);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: patterns.length,
      itemBuilder: (context, i) {
        final p = patterns[i];
        return Card(
          child: ListTile(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (_) => GrammarDetailScreen(pattern: p)))
                .then((_) => _load()),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.isBungo
                    ? const Color(0xFFE8604C).withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  p.pattern.characters.take(2).toString(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            title: Text(p.pattern,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [
                if (p.meaning != null) p.meaning!,
                if (p.isBungo) 'bungo',
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: p.isBungo
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8604C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('文語',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  )
                : const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      },
    );
  }
}
