import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/app_lock_service.dart';
import 'main_navigation_screen.dart';

class SecurityLockScreen extends StatefulWidget {
  const SecurityLockScreen({super.key});

  @override
  State<SecurityLockScreen> createState() => _SecurityLockScreenState();
}

class _SecurityLockScreenState extends State<SecurityLockScreen> {
  final TextEditingController _credentialController = TextEditingController();

  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _lockType;

  bool _isLoading = true;
  bool _isAuthenticating = false;
  bool _isUnlocking = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

  int _failedAttempts = 0;

  @override
  void initState() {
    super.initState();
    _loadLockSettings();
  }

  Future<void> _loadLockSettings() async {
    final service = AppLockService.instance;

    final lockType = await service.getLockType();
    final biometricEnabled = await service.isBiometricEnabled();

    bool biometricAvailable = false;

    if (biometricEnabled) {
      try {
        biometricAvailable = await _localAuth.isDeviceSupported();
      } catch (_) {
        biometricAvailable = false;
      }
    }

    if (!mounted) return;

    setState(() {
      _lockType = lockType;
      _biometricAvailable = biometricAvailable;
      _isLoading = false;
    });

    if (biometricAvailable) {
      await _unlockWithBiometric();
    }
  }

  Future<void> _unlockWithBiometric() async {
    if (_isAuthenticating || !_biometricAvailable) {
      return;
    }

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
        _goToHome();
      }
    } catch (_) {
      // If biometric authentication fails or is cancelled,
      // the user can still enter their PIN or password.
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _unlockWithCredential() async {
    if (_isUnlocking) return;

    final credential = _credentialController.text.trim();

    if (credential.isEmpty) {
      _showMessage(
        _lockType == 'pin'
            ? 'Please enter your PIN.'
            : 'Please enter your password.',
      );
      return;
    }

    if (_failedAttempts >= 5) {
      _showMessage('Too many incorrect attempts. Please try again shortly.');
      return;
    }

    setState(() {
      _isUnlocking = true;
    });

    final isCorrect = await AppLockService.instance.verifyCredential(
      credential,
    );

    if (!mounted) return;

    setState(() {
      _isUnlocking = false;
    });

    if (isCorrect) {
      _failedAttempts = 0;
      _goToHome();
      return;
    }

    _failedAttempts++;

    _credentialController.clear();

    if (_failedAttempts >= 5) {
      _showMessage(
        'Too many incorrect attempts. Please use biometric unlock or wait.',
      );
    } else {
      final remaining = 5 - _failedAttempts;

      _showMessage(
        'Incorrect ${_lockType == 'pin' ? 'PIN' : 'password'}. '
        '$remaining attempt${remaining == 1 ? '' : 's'} remaining.',
      );
    }
  }

  void _goToHome() {
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFC75D83),
      ),
    );
  }

  @override
  void dispose() {
    _credentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPin = _lockType == 'pin';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFC75D83)),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/butterfly.png',
                        width: 75,
                        height: 75,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2933),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Unlock brié to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          color: Color(0xFF765D67),
                        ),
                      ),

                      const SizedBox(height: 36),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isPin
                                  ? Icons.lock_outline_rounded
                                  : Icons.password_rounded,
                              size: 42,
                              color: const Color(0xFFC75D83),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              isPin
                                  ? 'Enter your 4-digit PIN'
                                  : 'Enter your password',
                              style: const TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3D2933),
                              ),
                            ),

                            const SizedBox(height: 20),

                            TextField(
                              controller: _credentialController,
                              obscureText: isPin || _obscurePassword,
                              keyboardType: isPin
                                  ? TextInputType.number
                                  : TextInputType.text,
                              maxLength: isPin ? 4 : null,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isPin ? 28 : 18,
                                letterSpacing: isPin ? 10 : 1,
                              ),
                              decoration: InputDecoration(
                                hintText: isPin ? '••••' : 'Password',
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFFFF4F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: !isPin
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFFC75D83),
                                        ),
                                      )
                                    : null,
                              ),
                              onSubmitted: (_) => _unlockWithCredential(),
                            ),

                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isUnlocking
                                    ? null
                                    : _unlockWithCredential,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC75D83),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFFE3B7C7,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isUnlocking
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Unlock',
                                        style: TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_biometricAvailable) ...[
                        const SizedBox(height: 24),

                        const Text(
                          'or',
                          style: TextStyle(color: Color(0xFF765D67)),
                        ),

                        const SizedBox(height: 12),

                        OutlinedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : _unlockWithBiometric,
                          icon: const Icon(
                            Icons.fingerprint_rounded,
                            color: Color(0xFFC75D83),
                          ),
                          label: Text(
                            _isAuthenticating
                                ? 'Checking...'
                                : 'Use biometric unlock',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              color: Color(0xFFC75D83),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            side: const BorderSide(color: Color(0xFFC75D83)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      const Text(
                        'Your account stays securely signed in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9A7E88),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
