import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../models/user.dart';
import '../home_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _university = TextEditingController(text: 'FIB Universitas Diponegoro');
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _jlptLevel = 'N3';
  String _studyProgram = 'S1 Bahasa dan Kebudayaan Jepang';
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const _levels = ['N5', 'N4', 'N3', 'N2', 'N1'];

  static const _studyPrograms = [
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
  void dispose() {
    _name.dispose();
    _email.dispose();
    _university.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = await ApiClient.instance.post('/auth/register', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'password_confirmation': _confirm.text,
        'study_program': _studyProgram,
        'jlpt_level': _jlptLevel,
        'university': _university.text.trim().isEmpty ? null : _university.text.trim(),
      });

      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await Session.instance.save(token, user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registrasi berhasil! Selamat datang, ${user.name}'),
          backgroundColor: const Color(0xFF166534),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (e.errors != null && e.errors!.isNotEmpty) {
        final list = <String>[];
        for (final val in e.errors!.values) {
          if (val is List) {
            list.addAll(val.map((x) => x.toString()));
          } else if (val != null) {
            list.add(val.toString());
          }
        }
        if (list.isNotEmpty) {
          msg = list.join('\n');
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendaftar: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mahasiswa Baru'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/sakura_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Registrasi Mahasiswa FIB UNDIP',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Bergabung dalam portal pembelajaran Sastra Jepang',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap *',
                        hintText: 'cth: Mahasiswa Sastra Jepang',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama lengkap wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Mahasiswa *',
                        hintText: 'nama@students.undip.ac.id',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _studyProgram,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Program Studi FIB UNDIP *',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      items: _studyPrograms
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
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _jlptLevel,
                            decoration: const InputDecoration(
                              labelText: 'Target JLPT',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            items: _levels
                                .map((l) => DropdownMenuItem(
                                      value: l,
                                      child: Text('$l ${l == 'N3' ? '(Menengah)' : ''}'),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _jlptLevel = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _university,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Fakultas / Universitas',
                        hintText: 'FIB Universitas Diponegoro',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password (min. 8 karakter) *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password *',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                        if (v != _password.text) return 'Konfirmasi password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _register,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Daftarkan Akun',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun?'),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Masuk ke Portal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
