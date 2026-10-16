import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login_screen.dart';
import 'create_account_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const Color background = Color(0xFFFFF8FB);
  static const Color pink = Color(0xFFC42C69);
  static const Color iconBackground = Color(0xFFFBE4EC);
  static const Color cardBackground = Colors.white;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('No account is currently signed in.'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              children: [
                _sectionTitle('Account details'),
                const SizedBox(height: 14),

                _emailCard(user),

                const SizedBox(height: 12),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'This is the email address currently used to sign in to your brié account.',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.black54,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                _sectionTitle('Account information'),
                const SizedBox(height: 14),

                _settingTile(
                  icon: Icons.info_outline,
                  title: 'Account information',
                  subtitle: 'View details about your brié account',
                  onTap: () => _showAccountInformation(context, user),
                ),

                const SizedBox(height: 30),

                _sectionTitle('Accounts'),
                const SizedBox(height: 14),

                _settingTile(
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Add account',
                  subtitle: 'Sign in or create another brié account',
                  onTap: () => _showAddAccountOptions(context),
                ),
              ],
            ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: pink,
      ),
    );
  }

  static Widget _emailCard(User user) {
    final email = user.email ?? 'No email address available';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.email_outlined, color: pink, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email address',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  email,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      user.emailVerified ? Icons.verified : Icons.error_outline,
                      size: 18,
                      color: user.emailVerified
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE67E22),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        user.emailVerified
                            ? 'Email verified'
                            : 'Email not verified',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: user.emailVerified
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE67E22),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBackground,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: pink, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.black38, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  static void _showAccountInformation(BuildContext context, User user) {
    final created = user.metadata.creationTime;
    final lastSignIn = user.metadata.lastSignInTime;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account information',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              _infoRow('Account created', _formatDate(created)),
              const SizedBox(height: 16),
              _infoRow('Last sign-in', _formatDate(lastSignIn)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  static void _showAddAccountOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add account',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose how you want to continue. You will leave the currently signed-in account first, but its data will not be deleted.',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 22),
              _optionTile(
                context: sheetContext,
                icon: Icons.login,
                title: 'Sign in to an existing account',
                subtitle: 'Use another brié account',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _switchToLogin(context);
                },
              ),
              const SizedBox(height: 12),
              _optionTile(
                context: sheetContext,
                icon: Icons.person_add_alt_1,
                title: 'Create a new account',
                subtitle: 'Start with a new brié account',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _switchToCreateAccount(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _optionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFFFF8FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: pink, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _switchToLogin(BuildContext context) async {
    await _signOutCurrentAccount();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static Future<void> _switchToCreateAccount(BuildContext context) async {
    await _signOutCurrentAccount();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
      (route) => false,
    );
  }

  static Future<void> _signOutCurrentAccount() async {
    // Clear the Firebase session and Google sign-in selection.
    await FirebaseAuth.instance.signOut();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Email/password accounts may not have an active Google session.
    }
  }
}
