import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../models/user.dart';
import 'register_screen.dart';
import '../home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = await ApiClient.instance.post('/auth/login', {
        'email': _email.text.trim(),
        'password': _password.text,
      });

      final token = data['token'] as String;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      await Session.instance.save(token, user);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal masuk: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(20),
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
                        'SakuraKotoba · 桜言葉',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Japanese Literature & SRS Study Suite',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.flash_on, size: 16, color: Color(0xFFF43F5E)),
                        label: const Text(
                          'Gunakan Akun Demo (1-Click)',
                          style: TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFB7C5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: _loading
                            ? null
                            : () {
                                _email.text = 'demo@nihon.test';
                                _password.text = 'password';
                                _login();
                              },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Email: demo@nihon.test · Pass: password',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
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
