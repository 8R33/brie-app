import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'email_address_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FB),
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
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text(
                'No account is currently signed in.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                _buildSectionTitle('Account details'),

                _buildSettingTile(
                  icon: Icons.email_outlined,
                  title: 'Email address',
                  subtitle: user.email ?? 'No email address',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmailAddressScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildSettingTile(
                  icon: Icons.link,
                  title: 'Connected accounts',
                  subtitle: _getConnectedAccounts(user),
                  onTap: () {
                    _showConnectedAccounts(context, user);
                  },
                ),

                const SizedBox(height: 28),

                _buildSectionTitle('Account information'),

                _buildSettingTile(
                  icon: Icons.info_outline,
                  title: 'Account information',
                  subtitle: 'View information about your brié account',
                  onTap: () {
                    _showAccountInformation(context, user);
                  },
                ),
              ],
            ),
    );
  }

  static String _getConnectedAccounts(User user) {
    final providers = user.providerData;

    if (providers.isEmpty) {
      return 'No connected accounts';
    }

    final names = <String>[];

    for (final provider in providers) {
      switch (provider.providerId) {
        case 'google.com':
          names.add('Google');
          break;

        case 'password':
          names.add('Email & password');
          break;

        case 'phone':
          names.add('Phone');
          break;

        default:
          names.add(provider.providerId);
      }
    }

    return names.join(', ');
  }

  static void _showConnectedAccounts(BuildContext context, User user) {
    final providers = user.providerData;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Connected accounts',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Accounts currently connected to your brié account.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 20),

                if (providers.isEmpty)
                  const Text(
                    'No connected accounts.',
                    style: TextStyle(fontSize: 15),
                  )
                else
                  ...providers.map(
                    (provider) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE4EC),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          'assets/images/google_g.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                      title: Text(
                        _providerName(provider.providerId),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        provider.email ?? user.email ?? 'Connected account',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showAccountInformation(BuildContext context, User user) {
    final creationDate = user.metadata.creationTime;
    final lastSignIn = user.metadata.lastSignInTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Account information',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 20),

                _infoRow('Account created', _formatDate(creationDate)),

                const SizedBox(height: 16),

                _infoRow('Last sign-in', _formatDate(lastSignIn)),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFD81B60),
        ),
      ),
    );
  }

  static Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFD81B60), size: 22),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(Icons.chevron_right, color: Colors.black38),
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
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  static String _providerName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email & password';
      case 'phone':
        return 'Phone';
      default:
        return providerId;
    }
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }
}
