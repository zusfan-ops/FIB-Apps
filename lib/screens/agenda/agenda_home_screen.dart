import 'package:flutter/material.dart';

import 'jlpt_screen.dart';
import 'kanban_screen.dart';
import 'schedule_screen.dart';

class AgendaHomeScreen extends StatefulWidget {
  const AgendaHomeScreen({super.key});

  @override
  State<AgendaHomeScreen> createState() => _AgendaHomeScreenState();
}

class _AgendaHomeScreenState extends State<AgendaHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Jadwal'),
            Tab(text: 'JLPT'),
            Tab(text: 'Kanban'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          ScheduleScreen(),
          JlptScreen(),
          KanbanScreen(),
        ],
      ),
    );
  }
}
