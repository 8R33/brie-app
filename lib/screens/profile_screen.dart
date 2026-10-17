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
  bool _isLoading = true;
  bool _isEditing = false;

  String _name = 'Your name';
  String _username = '@username';
  String _bio = '';
  String _email = '';
  String _phoneNumber = '';
  String? _photoPath;
  String? _photoUrl;

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get _primaryColor => Theme.of(context).colorScheme.primary;

  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get _surfaceColor => Theme.of(context).colorScheme.surface;

  Color get _textColor => Theme.of(context).colorScheme.onSurface;

  Color get _mutedColor =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60);

  Color get _borderColor =>
      Theme.of(context).colorScheme.outline.withValues(alpha: 0.25);

  Color get _softPrimaryColor =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE FROM FIREBASE
  // ============================================================

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _name = 'Guest';
          _username = '@guest';
          _bio = '';
          _email = '';
          _phoneNumber = '';
          _photoPath = null;
          _photoUrl = null;
          _isLoading = false;
        });

        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? <String, dynamic>{};

      final name =
          (data['displayName'] ?? data['name'] ?? user.displayName ?? '')
              .toString()
              .trim();

      final username = (data['username'] ?? '').toString().trim();

      final photoPath = (data['photoPath'] ?? '').toString().trim();

      final photoUrl = (data['photoUrl'] ?? user.photoURL ?? '')
          .toString()
          .trim();

      if (!mounted) return;

      setState(() {
        _name = name.isEmpty ? 'Your name' : name;

        _username = username.isEmpty
            ? '@username'
            : username.startsWith('@')
            ? username
            : '@$username';

        _bio = (data['bio'] ?? '').toString().trim();

        _email = (data['email'] ?? user.email ?? '').toString().trim();

        _phoneNumber = (data['phoneNumber'] ?? '').toString().trim();

        _photoPath = photoPath.isEmpty ? null : photoPath;

        _photoUrl = photoUrl.isEmpty ? null : photoUrl;

        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('ProfileScreen loading error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Could not load your profile.');
      }
    }
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  ImageProvider<Object>? _getProfileImage() {
    final path = _photoPath;

    if (path != null && path.isNotEmpty) {
      if (path.startsWith('https://') || path.startsWith('http://')) {
        return NetworkImage(path);
      }

      final file = File(path);

      if (file.existsSync()) {
        return FileImage(file);
      }
    }

    final url = _photoUrl;

    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  Widget _buildAvatar() {
    final image = _getProfileImage();

    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _softPrimaryColor,
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.25),
          width: 3,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: ClipOval(
        child: image == null
            ? Icon(Icons.person_rounded, size: 68, color: _primaryColor)
            : Image(
                image: image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person_rounded,
                    size: 68,
                    color: _primaryColor,
                  );
                },
              ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _editProfile() async {
    if (_isEditing) return;

    setState(() => _isEditing = true);

    try {
      final result = await showModalBottomSheet<dynamic>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EditProfileScreen(),
      );

      if (!mounted) return;

      if (result is Map && result['saved'] == true) {
        await _loadProfile();

        if (!mounted) return;

        _showMessage('Profile updated successfully.');
      }
    } catch (e, stackTrace) {
      debugPrint('Opening EditProfileScreen failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        _showMessage('Could not open profile editing.');
      }
    } finally {
      if (mounted) {
        setState(() => _isEditing = false);
      }
    }
  }

  // ============================================================
  // SNACKBAR MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // PERSONAL INFORMATION CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final displayValue = value.trim().isEmpty ? 'Not added yet' : value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _softPrimaryColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _primaryColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  displayValue,
                  style: TextStyle(
                    color: value.trim().isEmpty ? _mutedColor : _textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CONTENT
  //
  // Layout:
  // 1. Profile picture
  // 2. Edit Profile button
  // 3. Personal information
  // ============================================================

  Widget _buildProfileContent() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        children: [
          // PROFILE PICTURE
          Center(child: _buildAvatar()),

          const SizedBox(height: 16),

          // EDIT PROFILE BUTTON DIRECTLY BELOW THE PICTURE
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isEditing ? null : _editProfile,
              icon: _isEditing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit_outlined, size: 19),
              label: Text(_isEditing ? 'Opening editor...' : 'Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                disabledBackgroundColor: _primaryColor.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // PERSONAL INFORMATION HEADING
          Text(
            'Personal information',
            style: TextStyle(
              color: _textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          // FULL NAME
          _buildInfoCard(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            value: _name == 'Your name' ? '' : _name,
          ),

          // USERNAME
          _buildInfoCard(
            icon: Icons.alternate_email_rounded,
            label: 'Username',
            value: _username == '@username' ? '' : _username,
          ),

          // BIO
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            label: 'Bio',
            value: _bio,
          ),

          // PHONE NUMBER
          _buildInfoCard(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: _phoneNumber,
          ),

          // EMAIL ADDRESS
          _buildInfoCard(
            icon: Icons.email_outlined,
            label: 'Email address',
            value: _email,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_rounded, color: _textColor),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : _buildProfileContent(),
    );
  }
}
