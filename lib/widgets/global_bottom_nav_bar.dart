import 'package:flutter/material.dart';
import '../services/tab_switcher.dart';

class GlobalBottomNavBar extends StatelessWidget {
  final int? selectedIndex;

  const GlobalBottomNavBar({super.key, this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: TabSwitcher.index,
      builder: (context, currentTab, _) {
        final activeIndex = selectedIndex ?? currentTab;

        return NavigationBar(
          selectedIndex: (activeIndex >= 0 && activeIndex < 5) ? activeIndex : 0,
          onDestinationSelected: (i) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            TabSwitcher.goTo(i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style),
              label: 'Review',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Baca',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Lainnya',
            ),
          ],
        );
      },
    );
  }
}
