import 'package:flutter/material.dart';

import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _backgroundColor = Color(0xFFFFF4F7);
  static const Color _primaryColor = Color(0xFFC75D83);
  static const Color _textColor = Color(0xFF5A4050);
  static const Color _mutedColor = Color(0xFF9C8A92);
  static const Color _dividerColor = Color(0xFFEADDE2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _textColor,
            size: 27,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        title: const Text(
          'Settings',
          style: TextStyle(
            color: _textColor,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 35),
          children: [
            // =====================================================
            // ACCOUNT
            // =====================================================

            _buildSectionTitle('Account'),

            _buildSettingsTile(
              context: context,
              icon: Icons.person_outline_rounded,
              title: 'Account',
              subtitle: 'Manage your personal information and account',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // =====================================================
            // NOTIFICATIONS
            // =====================================================
            _buildSectionTitle('Preferences'),

            _buildSettingsTile(
              context: context,
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Choose what notifications you receive',
              onTap: () {
                // Notifications screen will be added here.
              },
            ),

            const SizedBox(height: 10),

            // =====================================================
            // APPEARANCE
            // =====================================================
            _buildSettingsTile(
              context: context,
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Theme, colours and display preferences',
              onTap: () {
                // Appearance screen will be added here.
              },
            ),

            const SizedBox(height: 10),

            // =====================================================
            // PRIVACY
            // =====================================================
            _buildSettingsTile(
              context: context,
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              subtitle: 'Control who can see you and interact with you',
              onTap: () {
                // Privacy screen will be added here.
              },
            ),

            const SizedBox(height: 10),

            // =====================================================
            // LANGUAGE
            // =====================================================
            _buildSettingsTile(
              context: context,
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'Choose the language used in brié',
              onTap: () {
                // Language screen will be added here.
              },
            ),

            const SizedBox(height: 10),

            // =====================================================
            // DATA & STORAGE
            // =====================================================
            _buildSettingsTile(
              context: context,
              icon: Icons.data_usage_rounded,
              title: 'Data & Storage',
              subtitle: 'Manage storage and data usage',
              onTap: () {
                // Data & Storage screen will be added here.
              },
            ),

            const SizedBox(height: 10),

            // =====================================================
            // ABOUT
            // =====================================================
            _buildSettingsTile(
              context: context,
              icon: Icons.info_outline_rounded,
              title: 'About brié',
              subtitle: 'App information, policies and legal',
              onTap: () {
                // About screen will be added here.
              },
            ),

            const SizedBox(height: 28),

            // =====================================================
            // ACCOUNT ACTIONS
            // =====================================================
            _buildSectionTitle('Account actions'),

            const SizedBox(height: 4),

            // LOG OUT
            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Log out',
              color: _textColor,
              onTap: () {
                _showLogoutDialog(context);
              },
            ),

            const SizedBox(height: 10),

            // DELETE ACCOUNT
            _buildActionTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete account',
              color: Colors.redAccent,
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),

            const SizedBox(height: 30),

            // =====================================================
            // APP VERSION
            // =====================================================
            const Center(
              child: Text(
                'brié',
                style: TextStyle(
                  color: _mutedColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 4),

            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: _mutedColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SECTION TITLE
  // =============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: _primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // =============================================================
  // SETTINGS TILE
  // =============================================================

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primaryColor, size: 23),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedColor,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedColor,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ACTION TILE
  // =============================================================

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 23),

              const SizedBox(width: 14),

              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.55),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // LOG OUT DIALOG
  // =============================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to log out of your brié account?',
            style: TextStyle(color: _mutedColor, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: _mutedColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Firebase logout will be connected here.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // DELETE ACCOUNT DIALOG
  // =============================================================

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete account?',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This will permanently delete your brié account and its data. This action cannot be undone.',
            style: TextStyle(color: _mutedColor, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: _mutedColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Account deletion will be connected here.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete account'),
            ),
          ],
        );
      },
    );
  }
}
