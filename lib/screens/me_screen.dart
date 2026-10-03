import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_screen.dart';

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
  bool _refreshing = false;

  int _selectedTab = 0;

  // ===============================================================
  // PROFILE DATA
  // ===============================================================

  String _displayName = '';
  String _username = '';
  String _bio = '';

  String? _photoUrl;
  String? _photoPath;

  // ===============================================================
  // LOAD PROFILE
  // ===============================================================

  Future<void> _loadProfileData({bool showLoading = true}) async {
    final user = _auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _profileLoading = false;
        _refreshing = false;
        _displayName = '';
        _username = '';
        _bio = '';
        _photoUrl = null;
        _photoPath = null;
      });

      return;
    }

    if (showLoading && mounted) {
      setState(() {
        _profileLoading = true;
      });
    }

    try {
      await user.reload();

      final refreshedUser = _auth.currentUser;

      final document = await _firestore.collection('users').doc(user.uid).get();

      final data = document.data();

      // =============================================================
      // NAME
      // =============================================================

      String name = '';

      final firestoreName =
          data?['name']?.toString().trim() ??
          data?['displayName']?.toString().trim() ??
          '';

      if (firestoreName.isNotEmpty) {
        name = firestoreName;
      } else {
        final authName = refreshedUser?.displayName?.trim() ?? '';

        if (authName.isNotEmpty) {
          name = authName;
        }
      }

      // =============================================================
      // USERNAME
      // =============================================================

      String username = data?['username']?.toString().trim() ?? '';

      if (username.isNotEmpty && !username.startsWith('@')) {
        username = '@$username';
      }

      // =============================================================
      // BIO
      // =============================================================

      String bio = data?['bio']?.toString().trim() ?? '';

      // =============================================================
      // LOCAL PROFILE PHOTO
      // =============================================================

      String? localPhotoPath;

      final firestorePhotoPath = data?['photoPath']?.toString().trim() ?? '';

      if (firestorePhotoPath.isNotEmpty) {
        final file = File(firestorePhotoPath);

        if (await file.exists()) {
          localPhotoPath = firestorePhotoPath;
        }
      }

      // =============================================================
      // ONLINE PROFILE PHOTO
      // =============================================================

      String? photoUrl = data?['photoUrl']?.toString().trim();

      if (photoUrl == null || photoUrl.isEmpty) {
        photoUrl = refreshedUser?.photoURL;
      }

      // =============================================================
      // UPDATE SCREEN
      // =============================================================

      if (!mounted) return;

      setState(() {
        _displayName = name;
        _username = username;
        _bio = bio;

        _photoPath = localPhotoPath;

        _photoUrl = photoUrl != null && photoUrl.isNotEmpty ? photoUrl : null;

        _profileLoading = false;
        _refreshing = false;
      });
    } catch (e) {
      debugPrint('Error loading Me profile: $e');

      if (!mounted) return;

      setState(() {
        _profileLoading = false;
        _refreshing = false;
      });
    }
  }

  // ===============================================================
  // PULL TO REFRESH
  // ===============================================================

  Future<void> _refreshProfile() async {
    if (!mounted) return;

    setState(() {
      _refreshing = true;
    });

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

    // =============================================================
    // IMMEDIATE UPDATE
    // =============================================================

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

    // =============================================================
    // RELOAD FROM FIREBASE
    // =============================================================

    await _loadProfileData(showLoading: false);
  }

  // ===============================================================
  // MENU
  // ===============================================================

  void _openMenu() {
    setState(() {
      _menuOpen = true;
    });
  }

  void _closeMenu() {
    if (!mounted) return;

    setState(() {
      _menuOpen = false;
    });
  }

  void _showComingSoon(String title) {
    _closeMenu();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be added next 💗'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===============================================================
  // PROFILE IMAGE
  // ===============================================================

  Widget _buildProfileImage() {
    if (_profileLoading) {
      return Container(
        width: 110,
        height: 110,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF3D9E2),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFC75D83),
            ),
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
          color: const Color(0xFFF3D9E2),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A4050).withValues(alpha: 0.10),
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

  // ===============================================================
  // PROFILE PHOTO CONTENT
  // ===============================================================

  Widget _buildProfilePhotoContent({
    required double width,
    required double height,
  }) {
    // =============================================================
    // LOCAL PHOTO
    // =============================================================

    if (_photoPath != null && _photoPath!.trim().isNotEmpty) {
      final file = File(_photoPath!);

      return Image.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkOrDefaultPhoto(width: width, height: height);
        },
      );
    }

    // =============================================================
    // ONLINE PHOTO
    // =============================================================

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
        errorBuilder: (context, error, stackTrace) {
          return _defaultProfileIcon();
        },
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return const Center(
      child: Icon(Icons.person, size: 48, color: Color(0xFFC75D83)),
    );
  }

  // ===============================================================
  // VIEW PROFILE IMAGE
  // ===============================================================

  void _showProfileImage() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (context) {
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
                color: Colors.white,
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
                  // =================================================
                  // LARGE IMAGE
                  // =================================================

                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _buildPopupImage(),
                    ),
                  ),

                  // =================================================
                  // CLOSE BUTTON
                  // =================================================
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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

  // ===============================================================
  // POPUP IMAGE
  // ===============================================================

  Widget _buildPopupImage() {
    // =============================================================
    // LOCAL IMAGE
    // =============================================================

    if (_photoPath != null && _photoPath!.trim().isNotEmpty) {
      final file = File(_photoPath!);

      return Image.file(
        file,
        width: 310,
        height: 310,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPopupNetworkOrDefault();
        },
      );
    }

    // =============================================================
    // NETWORK IMAGE
    // =============================================================

    return _buildPopupNetworkOrDefault();
  }

  Widget _buildPopupNetworkOrDefault() {
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
      return Image.network(
        _photoUrl!,
        width: 310,
        height: 310,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPopupDefault();
        },
      );
    }

    return _buildPopupDefault();
  }

  Widget _buildPopupDefault() {
    return Container(
      color: const Color(0xFFF3D9E2),
      child: const Center(
        child: Icon(Icons.person, size: 100, color: Color(0xFFC75D83)),
      ),
    );
  }

  // ===============================================================
  // FOLLOWERS / FOLLOWING
  // ===============================================================

  Widget _buildFollowStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '0 Followers',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A4050),
            ),
          ),
          SizedBox(width: 20),
          Text(
            '0 Following',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A4050),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // TABS
  // ===============================================================

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = 0;
              });
            },
            child: _buildTab(title: 'Mine', selected: _selectedTab == 0),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedTab = 1;
              });
            },
            child: _buildTab(title: 'Saved', selected: _selectedTab == 1),
          ),
        ),
      ],
    );
  }

  Widget _buildTab({required String title, required bool selected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? const Color(0xFFC75D83) : const Color(0xFFEADDE2),
            width: selected ? 2 : 1,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? const Color(0xFFC75D83) : const Color(0xFF9C8A92),
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

    return _buildSavedContent();
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
              color: const Color(0xFFF3D9E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFFC75D83),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your creations will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A4050),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create something beautiful and it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF9C8A92)),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF3D9E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.bookmark_border,
              color: Color(0xFFC75D83),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Nothing saved yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A4050),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Content you save will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF9C8A92)),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SIDE MENU
  // ===============================================================

  Widget _buildSideMenu() {
    final screenWidth = MediaQuery.of(context).size.width;

    final panelWidth = (screenWidth * 0.25).clamp(210.0, 260.0);

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
          top: 0,
          bottom: 0,
          child: Material(
            elevation: 8,
            color: Colors.white,
            child: SizedBox(
              width: panelWidth,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 22, 12, 18),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A4050),
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
                      onTap: () {
                        _showComingSoon('Settings');
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Security',
                      onTap: () {
                        _showComingSoon('Security');
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        _showComingSoon('Help & Support');
                      },
                    ),
                  ],
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 21, color: const Color(0xFFC75D83)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A4050),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // PROFILE TEXT
  // ===============================================================

  Widget _buildProfileText() {
    if (_profileLoading) {
      return Column(
        children: [
          const SizedBox(height: 2),

          Container(
            width: 130,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF3D9E2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            width: 80,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFFF3D9E2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(height: 8),

          Container(
            width: 170,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFFF3D9E2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_displayName.isNotEmpty)
          Text(
            _displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A4050),
            ),
          ),

        if (_displayName.isNotEmpty && _username.isNotEmpty)
          const SizedBox(height: 4),

        if (_username.isNotEmpty)
          Text(
            _username,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9C8A92)),
          ),

        if (_bio.isNotEmpty) const SizedBox(height: 8),

        if (_bio.isNotEmpty)
          Text(
            _bio,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7C6A72)),
          ),
      ],
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),

      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFFC75D83),
              backgroundColor: Colors.white,
              onRefresh: _refreshProfile,

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    // =================================================
                    // MENU BUTTON
                    // =================================================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _openMenu,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        icon: const Icon(
                          Icons.menu,
                          color: Color(0xFF5A4050),
                          size: 27,
                        ),
                      ),
                    ),

                    // Reduced from 10px.
                    // This moves the profile picture upward.
                    const SizedBox(height: 2),

                    // =================================================
                    // PROFILE PHOTO
                    // =================================================
                    _buildProfileImage(),

                    const SizedBox(height: 12),

                    // =================================================
                    // NAME / USERNAME / BIO
                    // =================================================
                    _buildProfileText(),

                    const SizedBox(height: 16),

                    // =================================================
                    // FOLLOWERS / FOLLOWING
                    // =================================================
                    _buildFollowStats(),

                    const SizedBox(height: 25),

                    // =================================================
                    // TABS
                    // =================================================
                    _buildTabs(),

                    // =================================================
                    // TAB CONTENT
                    // =================================================
                    _buildTabContent(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // =========================================================
          // SIDE MENU
          // =========================================================
          _buildSideMenu(),
        ],
      ),
    );
  }

  // ===============================================================
  // INIT
  // ===============================================================

  @override
  void initState() {
    super.initState();

    _loadProfileData();
  }
}
