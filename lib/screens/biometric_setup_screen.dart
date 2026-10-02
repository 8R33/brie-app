import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/app_lock_service.dart';
import 'main_navigation_screen.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isChecking = true;
  bool _isAuthenticating = false;
  bool _biometricsAvailable = false;
  bool _hasFingerprint = false;
  bool _hasFace = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();

      if (!mounted) return;

      setState(() {
        _biometricsAvailable = supported && available.isNotEmpty;
        _hasFingerprint = available.contains(BiometricType.fingerprint);
        _hasFace = available.contains(BiometricType.face);
        _isChecking = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _biometricsAvailable = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _enableBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Use your biometric to unlock brié.',
        biometricOnly: true,
      );

      if (!mounted) return;

      if (authenticated) {
        await AppLockService.instance.setBiometricEnabled(true);

        if (!mounted) return;

        _showMessage('Biometric unlock is now enabled.');

        await Future<void>.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        _goToHome();
      } else {
        _showMessage('Biometric verification was not completed.');
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Biometric unlock could not be enabled on this device.');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _skipBiometrics() {
    _goToHome();
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC75D83),
        ),
      );
  }

  String _biometricTitle() {
    if (_hasFingerprint && _hasFace) {
      return 'Use fingerprint or face';
    }

    if (_hasFingerprint) {
      return 'Use your fingerprint';
    }

    if (_hasFace) {
      return 'Use face unlock';
    }

    return 'Use biometric unlock';
  }

  String _biometricDescription() {
    if (_hasFingerprint && _hasFace) {
      return 'Unlock brié quickly with your fingerprint or face.';
    }

    if (_hasFingerprint) {
      return 'Unlock brié quickly with your fingerprint.';
    }

    if (_hasFace) {
      return 'Unlock brié quickly with face recognition.';
    }

    return 'Use your device biometric security to unlock brié.';
  }

  IconData _biometricIcon() {
    if (_hasFace && !_hasFingerprint) {
      return Icons.face_retouching_natural_rounded;
    }

    return Icons.fingerprint_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
          child: _isChecking
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC75D83)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 25),

                    Image.asset(
                      'assets/images/butterfly.png',
                      width: 78,
                      height: 78,
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Unlock brié faster',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E3035),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _biometricsAvailable ? _biometricDescription() : 'Your PIN or password will remain your main way to unlock brié.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF7D6B72),
                      ),
                    ),

                    const Spacer(),

                    if (_biometricsAvailable) ...[
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8DCE6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _biometricIcon(),
                          size: 58,
                          color: const Color(0xFFC75D83),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        _biometricTitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3940),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Your PIN or password will always remain available as a backup.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF9A858D),
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : _enableBiometrics,
                          icon: _isAuthenticating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_biometricIcon()),
                          label: Text(
                            _isAuthenticating
                                ? 'Checking...'
                                : 'Enable biometric unlock',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC75D83),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE1B8C7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 108,
                        height: 108,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8DCE6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 55,
                          color: Color(0xFFC75D83),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'Biometric unlock unavailable',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A3940),
                        ),
                      ),
                    ],

                    const Spacer(),

                    TextButton(
                      onPressed: _isAuthenticating ? null : _skipBiometrics,
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          color: Color(0xFF8A737B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
