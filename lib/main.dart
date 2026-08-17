import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'services/session.dart';
import 'theme.dart';

void main() {
  runApp(const SakuraKotobaApp());
}

class SakuraKotobaApp extends StatelessWidget {
  const SakuraKotobaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIB UNDIP · 桜言葉',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeShell(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home' && !Session.instance.isLoggedIn) {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return null;
      },
    );
  }
}
