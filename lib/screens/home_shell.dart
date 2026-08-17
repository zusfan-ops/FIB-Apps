import 'package:flutter/material.dart';

import '../screens/agenda/agenda_home_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/reading/reading_home_screen.dart';
import '../screens/srs/srs_home_screen.dart';
import '../services/tab_switcher.dart';
import '../widgets/global_bottom_nav_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    SrsHomeScreen(),
    ReadingHomeScreen(),
    AgendaHomeScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    TabSwitcher.index.addListener(_onTabChange);
  }

  @override
  void dispose() {
    TabSwitcher.index.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() {
    if (!mounted) return;
    setState(() => _index = TabSwitcher.index.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: const GlobalBottomNavBar(),
    );
  }
}
