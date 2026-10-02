import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';
import '../services/security_status_service.dart';

import 'biometric_setup_screen.dart';
import 'main_navigation_screen.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  String? _selectedType;

  final _credentialController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCredential = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _credentialController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _saveLock() async {
    FocusScope.of(context).unfocus();

    if (_selectedType == null) {
      _showMessage('Please choose PIN or Password.');
      return;
    }

    final credential = _credentialController.text.trim();
    final confirmation = _confirmController.text.trim();

    if (_selectedType == 'pin') {
      if (credential.length != 4) {
        _showMessage('Your PIN must contain exactly 4 digits.');
        return;
      }

      if (!RegExp(r'^\d{4}$').hasMatch(credential)) {
        _showMessage('Your PIN can only contain numbers.');
        return;
      }
    } else {
      if (credential.length < 6) {
        _showMessage('Your password must contain at least 6 characters.');
        return;
      }
    }

    if (credential != confirmation) {
      _showMessage('The two entries do not match.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Save the actual PIN/password securely on the device.
      await AppLockService.instance.setLock(
        type: _selectedType!,
        credential: credential,
      );

      // Save only the non-sensitive security status to Firebase.
      // The actual PIN/password is NEVER stored in Firestore.
      await SecurityStatusService.instance.saveSecurityStatus(
        lockType: _selectedType!,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BiometricSetupScreen()),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'We could not save your security settings. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _skipForNow() {
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

  @override
  Widget build(BuildContext context) {
    final isPin = _selectedType == 'pin';
    final isPassword = _selectedType == 'password';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/butterfly.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Protect your brié space',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E3035),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose how you would like to unlock brié when you return.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF7D6B72),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Choose your lock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A3940),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _LockChoiceCard(
                      icon: Icons.pin_outlined,
                      title: 'PIN',
                      subtitle: '4 digits',
                      selected: _selectedType == 'pin',
                      onTap: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _selectedType = 'pin';
                                _credentialController.clear();
                                _confirmController.clear();
                              });
                            },
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: _LockChoiceCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'Password',
                      subtitle: '6+ characters',
                      selected: _selectedType == 'password',
                      onTap: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _selectedType = 'password';
                                _credentialController.clear();
                                _confirmController.clear();
                              });
                            },
                    ),
                  ),
                ],
              ),

              if (_selectedType != null) ...[
                const SizedBox(height: 28),

                Text(
                  isPin ? 'Create your 4-digit PIN' : 'Create your password',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3940),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _credentialController,
                  enabled: !_isSaving,
                  obscureText: _obscureCredential,
                  keyboardType: isPin
                      ? TextInputType.number
                      : TextInputType.text,
                  maxLength: isPin ? 4 : null,
                  decoration: InputDecoration(
                    hintText: isPin ? 'Enter PIN' : 'Enter password',
                    counterText: '',
                    prefixIcon: Icon(
                      isPin ? Icons.pin_outlined : Icons.lock_outline_rounded,
                      color: const Color(0xFFC75D83),
                    ),
                    suffixIcon: IconButton(
                      tooltip: _obscureCredential ? 'Show' : 'Hide',
                      onPressed: () {
                        setState(() {
                          _obscureCredential = !_obscureCredential;
                        });
                      },
                      icon: Icon(
                        _obscureCredential
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFC75D83),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: _confirmController,
                  enabled: !_isSaving,
                  obscureText: _obscureConfirm,
                  keyboardType: isPin
                      ? TextInputType.number
                      : TextInputType.text,
                  maxLength: isPin ? 4 : null,
                  decoration: InputDecoration(
                    hintText: isPin ? 'Confirm PIN' : 'Confirm password',
                    counterText: '',
                    prefixIcon: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFFC75D83),
                    ),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirm ? 'Show' : 'Hide',
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: Color(0xFFC75D83),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC75D83),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE1B8C7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save security',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : _skipForNow,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Color(0xFF8A737B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (isPassword) ...[
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'You can use fingerprint or face unlock later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9A858D)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LockChoiceCard extends StatelessWidget {
  const _LockChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF8DCE6) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFC75D83) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: selected
                    ? const Color(0xFFC75D83)
                    : const Color(0xFF8F7B83),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? const Color(0xFFC75D83)
                      : const Color(0xFF4A3940),
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9A858D)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
