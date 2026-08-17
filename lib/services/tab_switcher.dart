import 'package:flutter/foundation.dart';

class TabSwitcher {
  static final ValueNotifier<int> index = ValueNotifier(0);

  static void goTo(int index) {
    TabSwitcher.index.value = index;
  }

  static int get srs => 1;
  static int get reading => 2;
  static int get agenda => 3;
  static int get more => 4;
}
