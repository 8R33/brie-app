import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final Map<String, String> _localPhotoCache = {};

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;

  String _displayName = '';
  String _username = '';
  String _bio = '';
  String? _photoUrl;
  String? _photoPath;

  String _email = '';
  String _phoneNumber = '';

  User? get _user => _auth.currentUser;

  // ===============================================================
  // INIT
  // ===============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ===============================================================
  // LOAD PROFILE
  // ===============================================================

  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _displayName = '';
        _username = '';
        _bio = '';
        _email = '';
        _phoneNumber = '';
        _photoUrl = null;
        _photoPath = null;
      });

      return;
    }

    try {
      // -----------------------------------------------------------
      // Refresh Firebase Authentication
      // -----------------------------------------------------------

      await user.reload();

      final refreshedUser = _auth.currentUser;

      // -----------------------------------------------------------
      // Get Firestore profile
      // -----------------------------------------------------------

      final document = await _firestore.collection('users').doc(user.uid).get();

      final data = document.data();

      // -----------------------------------------------------------
      // NAME
      // -----------------------------------------------------------

      String displayName =
          data?['name']?.toString().trim() ??
          data?['displayName']?.toString().trim() ??
          '';

      if (displayName.isEmpty) {
        displayName = refreshedUser?.displayName?.trim() ?? '';
      }

      // -----------------------------------------------------------
      // USERNAME
      // -----------------------------------------------------------

      String username = data?['username']?.toString().trim() ?? '';

      if (username.isNotEmpty && !username.startsWith('@')) {
        username = '@$username';
      }

      // -----------------------------------------------------------
      // BIO
      // -----------------------------------------------------------

      final bio = data?['bio']?.toString().trim() ?? '';

      // -----------------------------------------------------------
      // PHONE NUMBER
      // -----------------------------------------------------------

      final phoneNumber = data?['phoneNumber']?.toString().trim() ?? '';

      // -----------------------------------------------------------
      // EMAIL
      // -----------------------------------------------------------

      final email = refreshedUser?.email?.trim() ?? '';

      // -----------------------------------------------------------
      // LOCAL PROFILE PHOTO
      // -----------------------------------------------------------

      String? localPhotoPath;

      final savedLocalPath = _localPhotoCache[user.uid];

      if (savedLocalPath != null && savedLocalPath.trim().isNotEmpty) {
        final file = File(savedLocalPath);

        if (await file.exists()) {
          localPhotoPath = savedLocalPath;
        }
      }

      // -----------------------------------------------------------
      // CHECK FIRESTORE PHOTO PATH
      // -----------------------------------------------------------

      if (localPhotoPath == null) {
        final firestorePhotoPath = data?['photoPath']?.toString().trim() ?? '';

        if (firestorePhotoPath.isNotEmpty) {
          final file = File(firestorePhotoPath);

          if (await file.exists()) {
            localPhotoPath = firestorePhotoPath;
          }
        }
      }

      // -----------------------------------------------------------
      // ONLINE PHOTO
      // -----------------------------------------------------------

      String? photoUrl = data?['photoUrl']?.toString().trim();

      if (photoUrl == null || photoUrl.isEmpty) {
        photoUrl = refreshedUser?.photoURL;
      }

      // -----------------------------------------------------------
      // UPDATE SCREEN
      // -----------------------------------------------------------

      if (!mounted) return;

      setState(() {
        _displayName = displayName;
        _username = username;
        _bio = bio;
        _phoneNumber = phoneNumber;
        _email = email;

        _photoPath = localPhotoPath;

        _photoUrl = photoUrl != null && photoUrl.isNotEmpty ? photoUrl : null;

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ===============================================================
  // OPEN EDIT PROFILE
  // ===============================================================

  Future<void> _openEditProfile() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return const EditProfileScreen();
      },
    );

    if (!mounted) return;

    // =============================================================
    // IMMEDIATE PROFILE UPDATE
    // =============================================================

    if (result is Map) {
      final returnedName =
          result['name']?.toString().trim() ??
          result['displayName']?.toString().trim() ??
          '';

      String returnedUsername = result['username']?.toString().trim() ?? '';

      final returnedBio = result['bio']?.toString().trim() ?? '';

      final returnedPhone = result['phoneNumber']?.toString().trim() ?? '';

      final returnedPhotoPath = result['photoPath']?.toString().trim() ?? '';

      final returnedPhotoUrl = result['photoUrl']?.toString().trim() ?? '';

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

        if (returnedPhone.isNotEmpty) {
          _phoneNumber = returnedPhone;
        }

        // ---------------------------------------------------------
        // MOST IMPORTANT PART:
        // Immediately replace the profile picture.
        // ---------------------------------------------------------

        if (returnedPhotoPath.isNotEmpty) {
          final currentUserId = _user?.uid;
          if (currentUserId != null) {
            _localPhotoCache[currentUserId] = returnedPhotoPath;
          }

          _photoPath = returnedPhotoPath;
          _photoUrl = null;
        }

        if (returnedPhotoUrl.isNotEmpty) {
          final currentUserId = _user?.uid;
          if (currentUserId != null) {
            _localPhotoCache.remove(currentUserId);
          }

          _photoUrl = returnedPhotoUrl;
          _photoPath = null;
        }
      });
    }

    // =============================================================
    // LOAD AGAIN FROM FIREBASE / LOCAL STORAGE
    // =============================================================

    await _loadProfile();
  }

  // ===============================================================
  // PROFILE IMAGE
  // ===============================================================

  Widget _buildProfileImage() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF3D9E2),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A4050).withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(child: _buildProfilePhotoContent()),
    );
  }

  // ===============================================================
  // PROFILE PHOTO CONTENT
  // ===============================================================

  Widget _buildProfilePhotoContent() {
    // -------------------------------------------------------------
    // LOCAL PHOTO
    // -------------------------------------------------------------

    if (_photoPath != null && _photoPath!.trim().isNotEmpty) {
      final file = File(_photoPath!);

      return Image.file(
        file,
        width: 130,
        height: 130,
        fit: BoxFit.cover,
        key: ValueKey(_photoPath),
        errorBuilder: (context, error, stackTrace) {
          return _buildNetworkOrDefaultPhoto();
        },
      );
    }

    // -------------------------------------------------------------
    // NETWORK PHOTO
    // -------------------------------------------------------------

    return _buildNetworkOrDefaultPhoto();
  }

  Widget _buildNetworkOrDefaultPhoto() {
    if (_photoUrl != null && _photoUrl!.trim().isNotEmpty) {
      return Image.network(
        _photoUrl!,
        width: 130,
        height: 130,
        fit: BoxFit.cover,
        key: ValueKey(_photoUrl),
        errorBuilder: (context, error, stackTrace) {
          return _defaultProfileIcon();
        },
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return const Center(
      child: Icon(Icons.person, size: 62, color: Color(0xFFC75D83)),
    );
  }

  // ===============================================================
  // EDIT BUTTON
  // ===============================================================

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _openEditProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC75D83),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ===============================================================
  // INFORMATION ROW
  // ===============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final displayValue = value.trim().isEmpty ? 'Not added' : value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFFC75D83)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9C8A92),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  displayValue,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: displayValue == 'Not added'
                        ? const Color(0xFFB19FA7)
                        : const Color(0xFF5A4050),
                    fontStyle: displayValue == 'Not added'
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // PROFILE INFORMATION SECTION
  // ===============================================================

  Widget _buildProfileInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A4050),
          ),
        ),

        const SizedBox(height: 12),

        // NAME
        _buildInfoRow(
          icon: Icons.person_outline,
          title: 'Name',
          value: _displayName,
        ),

        const SizedBox(height: 10),

        // USERNAME
        _buildInfoRow(
          icon: Icons.alternate_email,
          title: 'Username',
          value: _username,
        ),

        const SizedBox(height: 10),

        // BIO
        _buildInfoRow(icon: Icons.info_outline, title: 'Bio', value: _bio),

        const SizedBox(height: 10),

        // PHONE
        _buildInfoRow(
          icon: Icons.phone_outlined,
          title: 'Phone number',
          value: _phoneNumber,
        ),

        const SizedBox(height: 10),

        // EMAIL
        _buildInfoRow(
          icon: Icons.email_outlined,
          title: 'Email',
          value: _email,
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

      // =============================================================
      // APP BAR
      // =============================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4F7),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A4050)),
        ),

        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF5A4050),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =============================================================
      // BODY
      // =============================================================
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFC75D83)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // =================================================
                    // PROFILE PICTURE ONLY
                    // =================================================

                    _buildProfileImage(),

                    const SizedBox(height: 24),

                    // =================================================
                    // EDIT BUTTON
                    // =================================================
                    _buildEditButton(),

                    const SizedBox(height: 30),

                    // =================================================
                    // PROFILE INFORMATION
                    // =================================================
                    _buildProfileInformation(),
                  ],
                ),
              ),
      ),
    );
  }
}
