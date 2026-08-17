import 'package:flutter/material.dart';

import '../services/session.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final restored = await Session.instance.restore();

    if (!mounted) return;

    if (restored) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141926),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2638),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/sakura_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '桜言葉',
              style: TextStyle(
                color: Color(0xFFFFAFC7),
                fontSize: 16,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'SakuraKotoba',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Japanese Literature & SRS Mastery',
              style: TextStyle(color: Colors.white60, fontSize: 13, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
