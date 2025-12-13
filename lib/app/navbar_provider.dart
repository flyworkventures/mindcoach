import 'package:flutter_riverpod/flutter_riverpod.dart';

final bottomNavProvider =
NotifierProvider<BottomNavNotifier, int>(BottomNavNotifier.new);

class BottomNavNotifier extends Notifier<int> {
  @override
  int build() => 0; // default tab: Home

  void setTab(int index) => state = index;

  void reset() => state = 0;
}
