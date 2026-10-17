import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
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

    _screens = [
      HomeScreen(
        onOpenSubsection: openSubsection,
        onCloseSubsection: _closeSubsection,
      ),
      const CreateScreen(),
      const ChatScreen(),
      const MeScreen(),
    ];
  }

  /// Opens a subsection, such as the breathing screen.
  void openSubsection(Widget screen) {
    if (!mounted) return;

    setState(() {
      _activeSubsection = screen;
    });
  }

  /// Handles taps on the bottom navigation bar.
  void _onNavigationTap(int index) {
    if (index == _currentIndex && _activeSubsection == null) {
      return;
    }

    setState(() {
      _currentIndex = index;
      _activeSubsection = null;
    });
  }

  /// Returns to Home from an open subsection.
  void _closeSubsection() {
    if (!mounted || _activeSubsection == null) return;

    setState(() {
      _activeSubsection = null;
      _currentIndex = 0;
    });
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BrieThemeController.instance,
      builder: (context, child) {
        final palette = BrieThemeController.instance.currentPalette;

        final showingSubsection = _activeSubsection != null;

        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            if (showingSubsection) {
              _closeSubsection();
            } else if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
            }
          },
          child: Scaffold(
            backgroundColor: palette.background,
            body: showingSubsection
                ? _activeSubsection!
                : IndexedStack(index: _currentIndex, children: _screens),
            bottomNavigationBar: showingSubsection
                ? null
                : BottomNavigationBar(
                    currentIndex: _currentIndex,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: palette.surface,
                    selectedItemColor: palette.accent,
                    unselectedItemColor: palette.muted,
                    elevation: 8,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    showUnselectedLabels: true,
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
      },
    );
  }
}
