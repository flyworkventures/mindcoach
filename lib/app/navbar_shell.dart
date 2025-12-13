import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../features/calendar_screen/calendar_screen.dart';
import '../features/chat_screen/presentation/pages/chat_screen.dart';
import '../features/home_screen/home_screen.dart';
import '../features/profile_screen/presentation/profile_screen.dart';
import '../features/specialists_screen/specialists_screen.dart';
import 'navbar_provider.dart';

class NavbarShell extends ConsumerWidget {
  const NavbarShell({super.key});

  static const List<Widget> _pages = [
    HomeScreen(),
    SpecialistsScreen(),
    CalendarScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  static const List<String> _iconAssets = [
    'assets/svg/home_icon.svg',
    'assets/svg/specialists_icon.svg',
    'assets/svg/calendar_icon.svg',
    'assets/svg/chat_icon.svg',
    'assets/svg/profile_icon.svg',
  ];

  static const List<Size> _iconSizes = [
    Size(20, 20),
    Size(24, 24),
    Size(24, 24),
    Size(24, 24),
    Size(24, 24),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);

    return Scaffold(
      extendBody: true,
      body: _pages[selectedIndex],
      bottomNavigationBar: _bottomNavBar(ref, selectedIndex),
    );
  }

  Widget _bottomNavBar(WidgetRef ref, int selectedIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_iconAssets.length, (index) {
              final isSelected = selectedIndex == index;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      ref.read(bottomNavProvider.notifier).setTab(index),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SvgPicture.asset(
                      _iconAssets[index],
                      width: _iconSizes[index].width,
                      height: _iconSizes[index].height,
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.teal : Colors.grey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
