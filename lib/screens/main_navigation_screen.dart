import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'create_screen.dart';

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
      HomeScreen(onOpenSubsection: _openSubsection),
      const CreateScreen(),
      const MeScreen(),
    ];
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
  // OPEN SUBSECTION
  // ===============================================================

  void _openSubsection(Widget screen) {
    setState(() {
      _activeSubsection = screen;
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
      canPop: !showingSubsection,

      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (showingSubsection) {
          _closeSubsection();
        }
      },

      child: Scaffold(
        body: showingSubsection
            ? _SubsectionContainer(
                child: _activeSubsection!,
                onClose: _closeSubsection,
              )
            : IndexedStack(index: _currentIndex, children: _screens),

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

// ===================================================================
// SUBSECTION CONTAINER
// ===================================================================
//
// This is used for Breathe, Listening, Security, Settings, etc.
//
// The main bottom navigation disappears while a subsection is open.
// ===================================================================

class _SubsectionContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;

  const _SubsectionContainer({required this.child, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),

        // Back button for subsection screens.
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 8),
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back, color: Color(0xFF5A4050)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// ME SCREEN
// ===================================================================

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),

      body: SafeArea(
        child: Center(
          child: Text(
            'Me screen coming next 💗',
            style: const TextStyle(fontSize: 18, color: Color(0xFF5A4050)),
          ),
        ),
      ),
    );
  }
}
