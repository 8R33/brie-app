import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import 'biometric_setup_screen.dart';

class ReinstallSecurityScreen extends StatefulWidget {
  const ReinstallSecurityScreen({super.key});

  @override
  State<ReinstallSecurityScreen> createState() =>
      _ReinstallSecurityScreenState();
}

class _ReinstallSecurityScreenState extends State<ReinstallSecurityScreen> {
  final TextEditingController _credentialController = TextEditingController();

  final TextEditingController _confirmCredentialController =
      TextEditingController();

  String _selectedType = 'pin';

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _continue() async {
    final credential = _credentialController.text.trim();
    final confirmation = _confirmCredentialController.text.trim();

    // ------------------------------------------------------------
    // VALIDATION
    // ------------------------------------------------------------

    if (credential.isEmpty) {
      _showMessage(
        _selectedType == 'pin'
            ? 'Please create a new PIN.'
            : 'Please create a new password.',
      );
      return;
    }

    if (_selectedType == 'pin') {
      if (!RegExp(r'^\d{4}$').hasMatch(credential)) {
        _showMessage('Your PIN must contain exactly 4 digits.');
        return;
      }
    } else {
      if (credential.length < 6) {
        _showMessage('Your password must contain at least 6 characters.');
        return;
      }
    }

    if (confirmation.isEmpty) {
      _showMessage(
        _selectedType == 'pin'
            ? 'Please confirm your new PIN.'
            : 'Please confirm your new password.',
      );
      return;
    }

    if (credential != confirmation) {
      _showMessage(
        _selectedType == 'pin'
            ? 'Your PINs do not match.'
            : 'Your passwords do not match.',
      );
      return;
    }

    // ------------------------------------------------------------
    // SAVE NEW SECURITY CREDENTIAL
    // ------------------------------------------------------------

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AppLockService.instance.setLock(
        type: _selectedType,
        credential: credential,
      );

      // Biometrics must be set up again on a newly installed device.
      await AppLockService.instance.setBiometricEnabled(false);

      if (!mounted) return;

      _credentialController.clear();
      _confirmCredentialController.clear();

      // ----------------------------------------------------------
      // MOVE TO BIOMETRIC SETUP
      // ----------------------------------------------------------

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BiometricSetupScreen()),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        'We could not save your security settings. Please try again.',
      );
    }
  }

  void _switchSecurityType(String type) {
    if (_isSubmitting) return;

    if (_selectedType == type) return;

    setState(() {
      _selectedType = type;

      _credentialController.clear();
      _confirmCredentialController.clear();

      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF6D4A5B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _confirmCredentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPin = _selectedType == 'pin';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                // --------------------------------------------------
                // BUTTERFLY
                // --------------------------------------------------

                Image.asset(
                  'assets/images/butterfly.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 22),

                // --------------------------------------------------
                // TITLE
                // --------------------------------------------------
                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4A5B),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Your brié account is ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF9B7886)),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Let’s secure this device with a new PIN or password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF9B7886),
                  ),
                ),

                const SizedBox(height: 35),

                // --------------------------------------------------
                // SECURITY CARD
                // --------------------------------------------------
                Container(
                  width: double.infinity,
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
                        isPin ? Icons.pin_rounded : Icons.lock_outline_rounded,
                        size: 42,
                        color: const Color(0xFFE58BA7),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Create your new security',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6D4A5B),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ------------------------------------------------
                      // PIN / PASSWORD SELECTOR
                      // ------------------------------------------------
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _switchSecurityType('pin'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPin
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: isPin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'PIN',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isPin
                                          ? const Color(0xFFE58BA7)
                                          : const Color(0xFF9B7886),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _switchSecurityType('password'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isPin
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: !isPin
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    'Password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: !isPin
                                          ? const Color(0xFFE58BA7)
                                          : const Color(0xFF9B7886),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ------------------------------------------------
                      // FIRST CREDENTIAL
                      // ------------------------------------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isPin ? 'Create a 4-digit PIN' : 'Create a password',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D4A5B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

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
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFFE58BA7),
                                  ),
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ------------------------------------------------
                      // CONFIRM CREDENTIAL
                      // ------------------------------------------------
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isPin ? 'Confirm your PIN' : 'Confirm your password',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6D4A5B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      TextField(
                        controller: _confirmCredentialController,
                        obscureText: isPin || _obscureConfirmPassword,
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
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFFE58BA7),
                                  ),
                                )
                              : null,
                        ),
                        onSubmitted: (_) => _continue(),
                      ),

                      const SizedBox(height: 22),

                      // ------------------------------------------------
                      // CONTINUE BUTTON
                      // ------------------------------------------------
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE58BA7),
                            disabledBackgroundColor: const Color(0xFFE5B5C4),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --------------------------------------------------
                // EXTRA SECURITY SETUP
                // --------------------------------------------------
                const SizedBox(height: 10),

                const Text(
                  'You’ll be able to enable fingerprint or face unlock next.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF9B7886),
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
