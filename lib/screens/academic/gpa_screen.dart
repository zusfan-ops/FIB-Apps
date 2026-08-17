import 'package:flutter/material.dart';

import '../../models/course_grade.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import 'course_grade_form_screen.dart';

class GpaScreen extends StatefulWidget {
  const GpaScreen({super.key});

  @override
  State<GpaScreen> createState() => _GpaScreenState();
}

class _GpaScreenState extends State<GpaScreen> {
  List<SemesterSummary>? _semesters;
  double _cumulativeGpa = 0;
  int _totalCredits = 0;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/course-grades') as Map<String, dynamic>;
      final rawBySemester = data['by_semester'];
      final Map<String, dynamic> bySemester = rawBySemester is Map<String, dynamic>
          ? rawBySemester
          : (rawBySemester is Map ? rawBySemester.cast<String, dynamic>() : {});
      final semesters = bySemester.entries
          .map((e) => SemesterSummary.fromJson(
              e.key, e.value is Map ? (e.value as Map).cast<String, dynamic>() : <String, dynamic>{}))
          .toList();
      if (mounted) {
        setState(() {
          _semesters = semesters;
          _cumulativeGpa = (data['cumulative_gpa'] as num?)?.toDouble() ?? 0;
          _totalCredits = data['total_credits'] as int? ?? 0;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _openForm({CourseGrade? grade}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseGradeFormScreen(grade: grade)),
    );
    if (result == true) _load();
  }

  Future<void> _delete(CourseGrade grade) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus nilai?'),
        content: Text('Nilai "${grade.courseName}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiClient.instance.delete('/course-grades/${grade.id}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalkulator IPK')),
      bottomNavigationBar: const GlobalBottomNavBar(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nilai'),
        onPressed: () => _openForm(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) return ErrorView(message: _error.toString(), onRetry: _load);
    if (_semesters == null) return const LoadingView();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6E7EF9)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IPK Kumulatif', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        _cumulativeGpa.toStringAsFixed(2),
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total SKS', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$_totalCredits', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_semesters!.isEmpty)
            const EmptyState(
              message: 'Belum ada nilai. Tambahkan nilai mata kuliahmu!',
              icon: Icons.school_outlined,
            )
          else
            ..._semesters!.map(_buildSemester),
        ],
      ),
    );
  }

  Widget _buildSemester(SemesterSummary summary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(summary.semester, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(
                'IP: ${summary.gpa.toStringAsFixed(2)} · ${summary.credits} SKS',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...summary.courses.map((g) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(g.courseName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${g.credits} SKS'),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(g.gradeLetter, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? _openForm(grade: g) : _delete(g),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
