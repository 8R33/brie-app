import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'settings_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Help and support is not available in this build.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Security settings are not available in this build.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _menuOpen = false;
  bool _profileLoading = true;
  int _selectedTab = 0;

  String _displayName = '';
  String _username = '';
  String _bio = '';

  String? _photoUrl;
  String? _photoPath;

  // Follow counts remain at zero until real follow functionality is added.
  int _followersCount = 0;
  int _followingCount = 0;
  int _profileViews = 0;

  ColorScheme get _colors => Theme.of(context).colorScheme;
  Color get _primary => _colors.primary;
  Color get _textColor => _colors.onSurface;
  Color get _mutedColor => _colors.onSurfaceVariant;
  Color get _surfaceColor => _colors.surface;
  Color get _softSurfaceColor => _colors.surfaceContainerHighest;

  // ===============================================================
  // LOAD PROFILE
  // ===============================================================

  Future<void> _loadProfileData({bool showLoading = true}) async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _profileLoading = false;
        _displayName = '';
        _username = '';
        _bio = '';
        _photoUrl = null;
        _photoPath = null;
      });

      return;
    }

    if (showLoading && mounted) {
      setState(() => _profileLoading = true);
    }

    try {
      await user.reload();

      final refreshedUser = _auth.currentUser;
      final document = await _firestore.collection('users').doc(user.uid).get();
      final data = document.data();
      final profileViews = (data?['profileViews'] as num?)?.toInt() ?? 0;

      final firestoreName =
          data?['name']?.toString().trim() ??
          data?['displayName']?.toString().trim() ??
          '';

      final authName = refreshedUser?.displayName?.trim() ?? '';
      final name = firestoreName.isNotEmpty ? firestoreName : authName;

      String username = data?['username']?.toString().trim() ?? '';

      if (username.isNotEmpty && !username.startsWith('@')) {
        username = '@$username';
      }

      final bio = data?['bio']?.toString().trim() ?? '';

      String? localPhotoPath;
      final storedPath = data?['photoPath']?.toString().trim() ?? '';

      // Only use a local file path if it is an actual local path.
      if (storedPath.isNotEmpty &&
          !storedPath.startsWith('http://') &&
          !storedPath.startsWith('https://')) {
        if (await File(storedPath).exists()) {
          localPhotoPath = storedPath;
        }
      }

      String? photoUrl = data?['photoUrl']?.toString().trim();

      if (photoUrl == null || photoUrl.isEmpty) {
        photoUrl = refreshedUser?.photoURL;
      }

      if (!mounted) return;

      setState(() {
        _displayName = name;
        _username = username;
        _bio = bio;
        _photoPath = localPhotoPath;
        _photoUrl = photoUrl != null && photoUrl.isNotEmpty ? photoUrl : null;
        _profileLoading = false;
        _profileViews = profileViews;
      });
    } catch (e) {
      debugPrint('Error loading Me profile: $e');

      if (!mounted) return;

      setState(() => _profileLoading = false);
    }
  }

  // ===============================================================
  // PULL TO REFRESH
  // ===============================================================

  Future<void> _refreshProfile() async {
    await _loadProfileData(showLoading: false);
  }

  // ===============================================================
  // OPEN PROFILE
  // ===============================================================

  Future<void> _openProfile() async {
    _closeMenu();

    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));

    if (!mounted) return;

    if (result is Map) {
      final returnedName =
          result['name']?.toString().trim() ??
          result['displayName']?.toString().trim() ??
          '';

      String returnedUsername = result['username']?.toString().trim() ?? '';

      final returnedBio = result['bio']?.toString().trim() ?? '';
      final returnedPhotoPath = result['photoPath']?.toString().trim() ?? '';

      if (returnedUsername.isNotEmpty && !returnedUsername.startsWith('@')) {
        returnedUsername = '@$returnedUsername';
      }

      setState(() {
        if (returnedName.isNotEmpty) {
          _displayName = returnedName;
        }

        if (returnedUsername.isNotEmpty) {
          _username = returnedUsername;
        }

        _bio = returnedBio;

        if (returnedPhotoPath.isNotEmpty) {
          _photoPath = returnedPhotoPath;
        }
      });
    }

    await _loadProfileData(showLoading: false);
  }

  Future<void> _openSettings() async {
    _closeMenu();

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openSecurity() async {
    _closeMenu();

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SecurityScreen()));
  }

  Future<void> _openHelpSupport() async {
    _closeMenu();

    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
  }

  // ===============================================================
  // MENU
  // ===============================================================

  void _openMenu() {
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    if (!mounted) return;
    setState(() => _menuOpen = false);
  }

  // ===============================================================
  // PROFILE IMAGE
  // ===============================================================

  Widget _buildProfileImage() {
    if (_profileLoading) {
      return Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _softSurfaceColor,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _showProfileImage,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _softSurfaceColor,
          border: Border.all(color: _surfaceColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: _textColor.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildProfilePhotoContent(width: 105, height: 105),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoContent({
    required double width,
    required double height,
  }) {
    if (_photoPath != null && _photoPath!.trim().isNotEmpty) {
      return Image.file(
        File(_photoPath!),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildNetworkOrDefaultPhoto(width: width, height: height);
        },
      );
    }

    return _buildNetworkOrDefaultPhoto(width: width, height: height);
  }

  Widget _buildNetworkOrDefaultPhoto({
    required double width,
    required double height,
  }) {
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
      return Image.network(
        _photoUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultProfileIcon(),
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return Center(child: Icon(Icons.person, size: 48, color: _primary));
  }

  // ===============================================================
  // ENLARGED PROFILE IMAGE
  // ===============================================================

  void _showProfileImage() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 35,
            vertical: 24,
          ),
          child: Center(
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _buildPopupImage(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton.filled(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.50),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupImage() {
    if (_photoPath != null && _photoPath!.trim().isNotEmpty) {
      return Image.file(
        File(_photoPath!),
        width: 310,
        height: 310,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPopupNetworkOrDefault(),
      );
    }

    return _buildPopupNetworkOrDefault();
  }

  Widget _buildPopupNetworkOrDefault() {
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
      return Image.network(
        _photoUrl!,
        width: 310,
        height: 310,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPopupDefault(),
      );
    }

    return _buildPopupDefault();
  }

  Widget _buildPopupDefault() {
    return Container(
      color: _softSurfaceColor,
      child: Center(child: Icon(Icons.person, size: 100, color: _primary)),
    );
  }

  // ===============================================================
  // PROFILE HEADER
  // Picture on the left, text on the right.
  // ===============================================================

  Widget _buildProfileHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileImage(),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: _buildProfileText(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileText() {
    if (_profileLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonLine(width: 135, height: 22),
          const SizedBox(height: 9),
          _skeletonLine(width: 85, height: 14),
          const SizedBox(height: 12),
          _skeletonLine(width: 155, height: 13),
          const SizedBox(height: 6),
          _skeletonLine(width: 115, height: 13),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayName.isNotEmpty ? _displayName : 'Your name',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        if (_username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: _mutedColor),
          ),
        ],
        if (_bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _bio,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, height: 1.4, color: _textColor),
          ),
        ],
      ],
    );
  }

  Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _softSurfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  // ===============================================================
  // ===============================================================
  // FOLLOWERS / FOLLOWING
  // Slim, centred statistic containers.
  // ===============================================================

  Widget _buildFollowStats() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        _buildStatText(_followersCount, 'Followers'),
        Text('·', style: TextStyle(color: _mutedColor)),
        _buildStatText(_followingCount, 'Following'),
        Text('·', style: TextStyle(color: _mutedColor)),
        _buildStatText(_profileViews, 'Views'),
      ],
    );
  }

  Widget _buildStatText(int count, String label) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$count ',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: label,
            style: TextStyle(color: _mutedColor),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  // ===============================================================
  // MINE / SHARED TABS
  // ===============================================================

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildTab(
            title: 'Mine',
            icon: Icons.person_outline_rounded,
            selected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
        ),
        Expanded(
          child: _buildTab(
            title: 'Shared',
            icon: Icons.share_outlined,
            selected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _primary : _softSurfaceColor,
              width: selected ? 2.5 : 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? _primary : _mutedColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? _primary : _mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // TAB CONTENT
  // ===============================================================

  Widget _buildTabContent() {
    if (_selectedTab == 0) {
      return _buildMineContent();
    }

    return _buildSharedContent();
  }

  Widget _buildMineContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _softSurfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.auto_awesome_outlined, color: _primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Your creations will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create something beautiful and it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _softSurfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.share_outlined, color: _primary, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Nothing shared yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Content you share will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _mutedColor),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SIDE MENU
  // ===============================================================

  Widget _buildSideMenu() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;

    final panelWidth = (screenWidth * 0.50).clamp(220.0, 360.0);
    final panelHeight = screenHeight * 0.50;

    return Stack(
      children: [
        if (_menuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          left: _menuOpen ? 0 : -panelWidth,
          top: topPadding,
          width: panelWidth,
          height: panelHeight,
          child: Material(
            elevation: 10,
            color: _surfaceColor,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 24, 16, 18),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: _openProfile,
                  ),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: _openSettings,
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Security',
                    onTap: _openSecurity,
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: _openHelpSupport,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _softSurfaceColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: _primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 23, color: _mutedColor),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: _primary,
              backgroundColor: _surfaceColor,
              onRefresh: _refreshProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // MENU BUTTON
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _openMenu,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: Icon(Icons.menu, color: _textColor, size: 27),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // PROFILE HEADER
                    _buildProfileHeader(),

                    const SizedBox(height: 22),

                    // CENTRED FOLLOWER STATISTICS
                    _buildFollowStats(),

                    const SizedBox(height: 26),

                    // MINE / SHARED
                    _buildTabs(),

                    // SELECTED TAB CONTENT
                    _buildTabContent(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // SIDE MENU
          _buildSideMenu(),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }
}
