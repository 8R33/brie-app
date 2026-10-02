import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login_screen.dart';
import 'security_setup_screen.dart';
import '../services/app_lock_service.dart';
import 'main_navigation_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCreatingAccount = false;
  bool _isGoogleSigningIn = false;

  // Google Sign-In is initialized once when this screen opens.
  late final Future<void> _googleSignInInitialization;

  @override
  void initState() {
    super.initState();

    _googleSignInInitialization = GoogleSignIn.instance.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // AFTER AUTHENTICATION
  // ------------------------------------------------------------

  Future<void> _goAfterAuthentication() async {
    final hasLock = await AppLockService.instance.hasLock();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => hasLock
            ? const MainNavigationScreen()
            : const SecuritySetupScreen(),
      ),
    );
  }

  // ------------------------------------------------------------
  // CREATE ACCOUNT WITH EMAIL AND PASSWORD
  // ------------------------------------------------------------

  Future<void> _createAccount() async {
    if (_isCreatingAccount || _isGoogleSigningIn) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Basic validation
    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please create a password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Your password needs at least 6 characters.');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('Please confirm your password.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('The passwords do not match.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isCreatingAccount = true;
    });

    try {
      // Create the Firebase account.
      final UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Save the user's chosen name.
      await credential.user?.updateDisplayName(name);

      // Refresh Firebase user information.
      await credential.user?.reload();

      if (!mounted) return;

      // Account created successfully.
      // The user must now create their brié app lock.
      await _goAfterAuthentication();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message;

      switch (error.code) {
        case 'email-already-in-use':
          message =
              'An account with this email already exists. '
              'Try logging in instead.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
              'That password is too weak. Please choose a stronger password.';
          break;

        case 'operation-not-allowed':
          message =
              'Email and password sign-in is not enabled in Firebase yet.';
          break;

        case 'network-request-failed':
          message =
              'We could not connect to Firebase. '
              'Please check your internet connection.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please wait a little and try again.';
          break;

        default:
          message =
              error.message ??
              'Something went wrong while creating your account.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingAccount = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ------------------------------------------------------------

  Future<void> _signInWithGoogle() async {
    if (_isCreatingAccount || _isGoogleSigningIn) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      // Wait for the one-time initialization.
      await _googleSignInInitialization;

      final googleSignIn = GoogleSignIn.instance;

      // Open Google's account chooser.
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Get Google's authentication information.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google sign-in did not return an ID token.');
      }

      // Create a Firebase credential using Google's ID token.
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // Sign in to Firebase.
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      // Google sign-in successful.
      // Check whether brié security has already been configured.
      await _goAfterAuthentication();
    } on GoogleSignInException catch (error) {
      if (!mounted) return;

      if (error.code == GoogleSignInExceptionCode.canceled) {
        _showMessage('Google sign-in was cancelled.');
      } else {
        _showMessage('Unable to sign in with Google. Please try again.');
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      String message;

      switch (error.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with this email. '
              'Please use your email and password.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        default:
          message = 'Unable to sign in with Google. Please try again.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to sign in with Google. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isCreatingAccount || _isGoogleSigningIn;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------------------------
              // BACK BUTTON
              // --------------------------------------------------

              IconButton(
                onPressed: isBusy
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF6D4A5B),
                ),
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // BUTTERFLY
              // --------------------------------------------------
              Center(
                child: Image.asset(
                  'assets/images/butterfly.png',
                  width: 85,
                  height: 85,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // TITLE
              // --------------------------------------------------
              const Center(
                child: Text(
                  'Create your brié space',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4A5B),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // --------------------------------------------------
              // SUBTITLE
              // --------------------------------------------------
              const Center(
                child: Text(
                  'A little space that belongs to you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF9B7886)),
                ),
              ),

              const SizedBox(height: 35),

              // --------------------------------------------------
              // NAME
              // --------------------------------------------------
              const Text(
                'What should we call you?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D4A5B),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                enabled: !isBusy,
                decoration: _inputDecoration(
                  hintText: 'Your name',
                  icon: Icons.person_outline,
                ),
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // EMAIL
              // --------------------------------------------------
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D4A5B),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isBusy,
                decoration: _inputDecoration(
                  hintText: 'you@example.com',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // PASSWORD
              // --------------------------------------------------
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D4A5B),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !isBusy,
                decoration: _inputDecoration(
                  hintText: 'Create a password',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9B7886),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // CONFIRM PASSWORD
              // --------------------------------------------------
              const Text(
                'Confirm password',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6D4A5B),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                enabled: !isBusy,
                decoration: _inputDecoration(
                  hintText: 'Enter your password again',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9B7886),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // --------------------------------------------------
              // CREATE ACCOUNT BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isBusy ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE58BA7),
                    disabledBackgroundColor: const Color(0xFFE8B6C5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isCreatingAccount
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Create my account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // DIVIDER
              // --------------------------------------------------
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or continue with',
                      style: TextStyle(fontSize: 13, color: Color(0xFF9B7886)),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // GOOGLE BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: isBusy ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6D4A5B),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isGoogleSigningIn
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFFE58BA7),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/google_g.png',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // LOGIN LINK
              // --------------------------------------------------
              Center(
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Color(0xFF9B7886)),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: Color(0xFFE58BA7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INPUT DECORATION
  // ------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFB99DA8)),
      prefixIcon: Icon(icon, color: const Color(0xFF9B7886)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        borderSide: const BorderSide(color: Color(0xFFE5A9BA), width: 1.5),
      ),
    );
  }
}
