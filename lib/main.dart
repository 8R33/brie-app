import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await BrieThemeController.instance.initialize();

  try {
    await NotificationService.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('brié notification initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const BrieApp());
}

class BrieApp extends StatelessWidget {
  const BrieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BrieThemeController.instance,
      builder: (context, child) {
        final palette = BrieThemeController.instance.currentPalette;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'brié',
          theme: palette.toThemeData(),
          home: const BrieAppLifecycle(child: SplashScreen()),
        );
      },
    );
  }
}

class BrieAppLifecycle extends StatefulWidget {
  final Widget child;

  const BrieAppLifecycle({super.key, required this.child});

  @override
  State<BrieAppLifecycle> createState() => _BrieAppLifecycleState();
}

class _BrieAppLifecycleState extends State<BrieAppLifecycle>
    with WidgetsBindingObserver {
  Timer? _notificationTimer;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _startNotificationCleanup();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startNotificationCleanup();
    } else {
      _stopNotificationCleanup();
    }
  }

  void _startNotificationCleanup() {
    if (_notificationTimer != null) return;

    _dismissNotifications();

    _notificationTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _dismissNotifications(),
    );
  }

  void _stopNotificationCleanup() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  Future<void> _dismissNotifications() async {
    if (_isClearing) return;

    _isClearing = true;

    try {
      await NotificationService.instance.dismissDisplayedNotifications();
    } catch (error) {
      debugPrint('Could not dismiss brié notifications: $error');
    } finally {
      _isClearing = false;
    }
  }

  @override
  void dispose() {
    _stopNotificationCleanup();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
