import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'create_screen.dart';
import 'chat_screen.dart';
import 'me_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  Widget? _activeSubsection;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = const [HomeScreen(), CreateScreen(), ChatScreen(), MeScreen()];
  }

  // ===============================================================
  // MAIN NAVIGATION
  // ===============================================================

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
      _activeSubsection = null;
    });
  }

  // ===============================================================
  // CLOSE SUBSECTION
  // ===============================================================

  void _closeSubsection() {
    setState(() {
      _activeSubsection = null;
    });
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    final bool showingSubsection = _activeSubsection != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (showingSubsection) {
          _closeSubsection();
          return;
        }
      },
      child: Scaffold(
        body: showingSubsection
            ? _activeSubsection!
            : IndexedStack(index: _currentIndex, children: _screens),

        // =========================================================
        // BOTTOM NAVIGATION
        //
        // Exists ONLY on:
        // Home / Create / Chat / Me
        //
        // It disappears completely inside subsections.
        // =========================================================
        bottomNavigationBar: showingSubsection
            ? null
            : BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFFC75D83),
                unselectedItemColor: const Color(0xFF9C8A92),
                elevation: 8,
                onTap: _onNavigationTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.auto_awesome_outlined),
                    activeIcon: Icon(Icons.auto_awesome),
                    label: 'Create',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline),
                    activeIcon: Icon(Icons.chat_bubble),
                    label: 'Chat',
                  ),

                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Me',
                  ),
                ],
              ),
      ),
    );
  }
}
