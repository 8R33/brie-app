import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import 'security_lock_screen.dart';
import 'security_setup_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _slideAnimation = Tween<double>(
      begin: -70,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    Timer(const Duration(seconds: 3), _checkSession);
  }

  Future<void> _checkSession() async {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    // No Firebase user → Welcome
    if (user == null) {
      _goToWelcome();
      return;
    }

    // Firebase user exists.
    // Now check whether the brié app lock has been configured.
    final hasLock = await AppLockService.instance.hasLock();

    if (!mounted) return;

    // No app lock yet → Security Setup
    if (!hasLock) {
      _goToSecuritySetup();
      return;
    }

    // App lock exists → Lock Screen
    _goToLockScreen();
  }

  void _goToWelcome() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
  }

  void _goToSecuritySetup() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SecuritySetupScreen()),
    );
  }

  void _goToLockScreen() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SecurityLockScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.translate(
                offset: Offset(_slideAnimation.value, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              ),
            );
          },
          child: Image.asset(
            'assets/images/brie_logo.png',
            width: 310,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
