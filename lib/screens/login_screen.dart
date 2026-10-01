import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'home_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  bool _isSendingResetEmail = false;
  bool _isGoogleSigningIn = false;

  // Google Sign-In is initialized once when the screen starts.
  late final Future<void> _googleSignInInitialization;

  @override
  void initState() {
    super.initState();

    _googleSignInInitialization = GoogleSignIn.instance.initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return;
    }

    setState(() {
      _isLoggingIn = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account was found with this email.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = 'The email or password is incorrect.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'operation-not-allowed':
          message = 'Email and password sign-in is currently unavailable.';
          break;

        default:
          message = 'Something went wrong. Please try again.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ------------------------------------------------------------

  Future<void> _signInWithGoogle() async {
    if (_isLoggingIn || _isGoogleSigningIn) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      // Wait for the one-time initialization.
      await _googleSignInInitialization;

      final googleSignIn = GoogleSignIn.instance;

      // Show Google's account chooser.
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Get the Google authentication information.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a Firebase credential using Google's ID token.
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential.
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      // Go to Home after successful sign-in.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on GoogleSignInException catch (e) {
      if (!mounted) return;

      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showMessage('Google sign-in was cancelled.');
      } else {
        _showMessage('Unable to sign in with Google. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'An account already exists with this email. Please use your email and password.';
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
  // FORGOT PASSWORD
  // ------------------------------------------------------------

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter your email first, then tap Forgot password.');
      return;
    }

    setState(() {
      _isSendingResetEmail = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      _showMessage('Password reset email sent. Check your inbox.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account was found with this email.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection and try again.';
          break;

        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;

        default:
          message = 'Unable to send the reset email. Please try again.';
      }

      _showMessage(message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to send the reset email. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSendingResetEmail = false;
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
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool isBusy =
        _isLoggingIn || _isGoogleSigningIn || _isSendingResetEmail;

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

              const SizedBox(height: 15),

              // --------------------------------------------------
              // BUTTERFLY
              // --------------------------------------------------
              Center(
                child: Image.asset(
                  'assets/images/butterfly.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20),

              // --------------------------------------------------
              // TITLE
              // --------------------------------------------------
              const Center(
                child: Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
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
                  'Your little space is waiting for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF9B7886)),
                ),
              ),

              const SizedBox(height: 40),

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
                textInputAction: TextInputAction.next,
                enabled: !_isLoggingIn && !_isGoogleSigningIn,
                decoration: _inputDecoration(
                  hintText: 'you@example.com',
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 20),

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
                textInputAction: TextInputAction.done,
                enabled: !_isLoggingIn && !_isGoogleSigningIn,
                onSubmitted: (_) => _login(),
                decoration: _inputDecoration(
                  hintText: 'Enter your password',
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

              const SizedBox(height: 10),

              // --------------------------------------------------
              // FORGOT PASSWORD
              // --------------------------------------------------
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      _isLoggingIn || _isGoogleSigningIn || _isSendingResetEmail
                      ? null
                      : _forgotPassword,
                  child: _isSendingResetEmail
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE58BA7),
                          ),
                        )
                      : const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color(0xFFE58BA7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // --------------------------------------------------
              // LOGIN BUTTON
              // --------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoggingIn || _isGoogleSigningIn ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE58BA7),
                    disabledBackgroundColor: const Color(0xFFE5B5C4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoggingIn
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Log in',
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
                  onPressed: _isLoggingIn || _isGoogleSigningIn
                      ? null
                      : _signInWithGoogle,
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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.g_mobiledata,
                              size: 30,
                              color: Color(0xFF6D4A5B),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // --------------------------------------------------
              // CREATE ACCOUNT
              // --------------------------------------------------
              Center(
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAccountScreen(),
                            ),
                          );
                        },
                  child: const Text.rich(
                    TextSpan(
                      text: 'Don’t have an account? ',
                      style: TextStyle(color: Color(0xFF9B7886)),
                      children: [
                        TextSpan(
                          text: 'Create one',
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
