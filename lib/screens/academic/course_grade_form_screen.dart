import 'package:flutter/material.dart';

import '../../models/course_grade.dart';
import '../../services/api_client.dart';

class CourseGradeFormScreen extends StatefulWidget {
  final CourseGrade? grade;

  const CourseGradeFormScreen({super.key, this.grade});

  @override
  State<CourseGradeFormScreen> createState() => _CourseGradeFormScreenState();
}

class _CourseGradeFormScreenState extends State<CourseGradeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseName;
  late final TextEditingController _semester;
  int _credits = 2;
  String _gradeLetter = 'A';
  bool _loading = false;

  static const _letters = ['A', 'AB', 'B', 'BC', 'C', 'D', 'E'];

  bool get _isEdit => widget.grade != null;

  @override
  void initState() {
    super.initState();
    _courseName = TextEditingController(text: widget.grade?.courseName ?? '');
    _semester = TextEditingController(text: widget.grade?.semester ?? '');
    _credits = widget.grade?.credits ?? 2;
    _gradeLetter = widget.grade?.gradeLetter ?? 'A';
  }

  @override
  void dispose() {
    _courseName.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'course_name': _courseName.text.trim(),
      'credits': _credits,
      'semester': _semester.text.trim(),
      'grade_letter': _gradeLetter,
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/course-grades/${widget.grade!.id}', body);
      } else {
        await ApiClient.instance.post('/course-grades', body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Nilai' : 'Tambah Nilai Mata Kuliah')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _courseName,
                decoration: const InputDecoration(labelText: 'Nama mata kuliah'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _semester,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  hintText: 'cth: Ganjil 2025/2026',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('SKS', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(6, (i) => i + 1)
                    .map((c) => ChoiceChip(
                          label: Text('$c'),
                          selected: _credits == c,
                          onSelected: (_) => setState(() => _credits = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('Nilai', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _letters
                    .map((l) => ChoiceChip(
                          label: Text(l),
                          selected: _gradeLetter == l,
                          onSelected: (_) => setState(() => _gradeLetter = l),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Tambah Nilai'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
