import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? get _user => _auth.currentUser;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPickingImage = false;

  XFile? _selectedImage;
  String? _currentPhotoPath;

  static const Color _backgroundColor = Color(0xFFFFF4F7);
  static const Color _primaryColor = Color(0xFFC75D83);
  static const Color _textColor = Color(0xFF5A4050);
  static const Color _mutedColor = Color(0xFF9C8A92);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = _user;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final document = await _firestore.collection('users').doc(user.uid).get();

      final data = document.data();

      // NAME
      final displayName = user.displayName?.trim() ?? '';

      _nameController.text = displayName;

      // USERNAME
      _usernameController.text = data?['username']?.toString().trim() ?? '';

      // BIO
      _bioController.text = data?['bio']?.toString() ?? '';

      // PHONE
      final savedPhone = data?['phoneNumber']?.toString().trim() ?? '';

      if (savedPhone.startsWith('+254') && savedPhone.length >= 13) {
        _phoneController.text = savedPhone.substring(4);
      } else if (savedPhone.isNotEmpty) {
        final digitsOnly = savedPhone.replaceAll(RegExp(r'[^0-9]'), '');

        if (digitsOnly.startsWith('254') && digitsOnly.length > 9) {
          _phoneController.text = digitsOnly.substring(3);
        } else if (digitsOnly.length > 9) {
          _phoneController.text = digitsOnly.substring(digitsOnly.length - 9);
        } else {
          _phoneController.text = digitsOnly;
        }
      }

      // LOCAL PROFILE PHOTO
      final firestorePhotoPath = data?['photoPath']?.toString().trim() ?? '';

      if (firestorePhotoPath.isNotEmpty) {
        final file = File(firestorePhotoPath);

        if (await file.exists()) {
          _currentPhotoPath = firestorePhotoPath;
        } else {
          _currentPhotoPath = null;
        }
      } else {
        _currentPhotoPath = null;
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'LOAD PROFILE FIREBASE ERROR: '
        'code=${e.code}, message=${e.message}',
      );

      if (mounted) {
        _showMessage('Could not load your profile.');
      }
    } catch (e) {
      debugPrint('LOAD PROFILE ERROR: $e');

      if (mounted) {
        _showMessage('Could not load your profile.');
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  // ============================================================
  // PICK + CROP PROFILE PICTURE
  // ============================================================

  Future<void> _pickProfilePicture() async {
    if (_isPickingImage || _isSaving) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      // STEP 1: Open gallery
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );

      if (pickedImage == null) {
        return;
      }

      // Make sure the selected file actually exists.
      final selectedFile = File(pickedImage.path);

      if (!await selectedFile.exists()) {
        if (mounted) {
          _showMessage('The selected picture could not be found.');
        }
        return;
      }

      // STEP 2: Open crop screen
      final CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: pickedImage.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: _primaryColor,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            lockAspectRatio: true,
          ),
        ],
      );

      // User pressed cancel.
      if (croppedImage == null) {
        return;
      }

      // Make sure cropped file exists.
      final croppedFile = File(croppedImage.path);

      if (!await croppedFile.exists()) {
        if (mounted) {
          _showMessage('The cropped picture could not be found.');
        }
        return;
      }

      if (!mounted) return;

      // STEP 3: Use cropped image as selected profile picture
      setState(() {
        _selectedImage = XFile(croppedImage.path);
      });
    } on PlatformException catch (e) {
      debugPrint(
        'IMAGE PICK/CROP PLATFORM ERROR: '
        'code=${e.code}, message=${e.message}',
      );

      if (mounted) {
        _showMessage('Could not open the image editor. Please try again.');
      }
    } catch (e, stackTrace) {
      debugPrint('IMAGE PICK/CROP ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (mounted) {
        _showMessage('Could not crop that picture. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  // ============================================================
  // SAVE PROFILE PICTURE LOCALLY
  // ============================================================

  Future<String?> _saveProfilePictureLocally() async {
    final user = _user;
    final selectedImage = _selectedImage;

    if (user == null || selectedImage == null) {
      return _currentPhotoPath;
    }

    final sourceFile = File(selectedImage.path);

    if (!await sourceFile.exists()) {
      throw Exception('The selected picture could not be found.');
    }

    final directory = await getApplicationDocumentsDirectory();

    final fileName =
        'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final savedFile = File('${directory.path}/$fileName');

    // Copy the cropped image from temporary/cache storage
    // into permanent app storage.
    await sourceFile.copy(savedFile.path);

    // Verify that the copy worked.
    if (!await savedFile.exists()) {
      throw Exception('The profile picture could not be saved.');
    }

    debugPrint('PROFILE PICTURE SAVED TO: ${savedFile.path}');

    return savedFile.path;
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    final form = _formKey.currentState;

    if (form == null) return;

    if (!form.validate()) {
      return;
    }

    final user = _user;

    if (user == null) {
      _showMessage('No signed-in user found.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();

    String username = _usernameController.text.trim().toLowerCase();

    if (username.startsWith('@')) {
      username = username.substring(1);
    }

    final bio = _bioController.text.trim();

    final phoneDigits = _phoneController.text.trim();

    final phoneNumber = '+254$phoneDigits';

    try {
      String? photoPath = _currentPhotoPath;

      // Save the newly cropped image locally.
      if (_selectedImage != null) {
        photoPath = await _saveProfilePictureLocally();
      }

      // Update Firebase Auth display name.
      await user.updateDisplayName(name);

      // Save profile information in Firestore.
      await _firestore.collection('users').doc(user.uid).set({
        'displayName': name,
        'username': username,
        'bio': bio,
        'phoneNumber': phoneNumber,
        'photoPath': photoPath,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('PROFILE SAVED SUCCESSFULLY');

      if (!mounted) return;

      Navigator.of(context).pop({
        'saved': true,
        'displayName': name,
        'username': username,
        'bio': bio,
        'phoneNumber': phoneNumber,
        'photoPath': photoPath,
      });
    } on FirebaseException catch (e) {
      debugPrint('================================');
      debugPrint('FIREBASE PROFILE SAVE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('PLUGIN: ${e.plugin}');
      debugPrint('================================');

      if (!mounted) return;

      _showMessage('Could not save your profile. Please try again.');
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('PROFILE SAVE ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('================================');

      if (!mounted) return;

      _showMessage('Could not save your profile. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Please enter your name';
    }

    if (name.length < 2) {
      return 'Name is too short';
    }

    return null;
  }

  String? _validateUsername(String? value) {
    String username = value?.trim() ?? '';

    if (username.startsWith('@')) {
      username = username.substring(1);
    }

    if (username.isEmpty) {
      return 'Please choose a username';
    }

    if (username.length < 3) {
      return 'Username is too short';
    }

    final validUsername = RegExp(r'^[a-zA-Z0-9._]+$');

    if (!validUsername.hasMatch(username)) {
      return 'Use only letters, numbers, . or _';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Please enter your phone number';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return 'Enter digits only';
    }

    if (phone.length != 9) {
      return 'Enter exactly 9 digits';
    }

    return null;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _textColor,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage() {
    Widget imageWidget;

    if (_selectedImage != null) {
      imageWidget = Image.file(
        File(_selectedImage!.path),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _defaultProfileIcon();
        },
      );
    } else if (_currentPhotoPath != null && _currentPhotoPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(_currentPhotoPath!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _defaultProfileIcon();
        },
      );
    } else {
      imageWidget = _defaultProfileIcon();
    }

    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFE9EF),
      ),
      child: ClipOval(
        child: SizedBox(width: 100, height: 100, child: imageWidget),
      ),
    );
  }

  Widget _defaultProfileIcon() {
    return const Center(
      child: Icon(Icons.person_rounded, size: 48, color: _primaryColor),
    );
  }

  // ============================================================
  // STANDARD FIELD
  // ============================================================

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textInputAction: maxLines > 1
              ? TextInputAction.newline
              : TextInputAction.next,
          style: const TextStyle(color: _textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _mutedColor),
            prefixIcon: Icon(icon, color: _primaryColor, size: 21),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: _primaryColor, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PHONE FIELD
  // ============================================================

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          validator: (_) => _validatePhone(_phoneController.text),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: field.hasError
                          ? Colors.redAccent
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 10),
                        child: Icon(
                          Icons.phone_outlined,
                          color: _primaryColor,
                          size: 21,
                        ),
                      ),

                      // PERMANENT KENYAN CODE
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F4),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Text(
                          '+254',
                          style: TextStyle(
                            color: _textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 9,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          onChanged: (value) {
                            field.didChange(value);

                            setState(() {});
                          },
                          style: const TextStyle(
                            color: _textColor,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            hintText: '111111111',
                            hintStyle: TextStyle(color: _mutedColor),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),
                    ],
                  ),
                ),

                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Text(
                      field.errorText ?? '',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: FractionallySizedBox(
        heightFactor: 0.78,
        alignment: Alignment.bottomCenter,
        child: Material(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: _primaryColor),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),

                    // HANDLE
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Color(0xFFD8C7CE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // TITLE
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 6, 14, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: _isSaving || _isPickingImage
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 29,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0xFFEADDE2)),

                    // FORM
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            22,
                            22,
                            22,
                            keyboardHeight + 35,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // PROFILE PICTURE
                              Center(
                                child: Column(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _buildProfileImage(),

                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: GestureDetector(
                                            onTap: _isPickingImage
                                                ? null
                                                : _pickProfilePicture,
                                            child: Container(
                                              width: 42,
                                              height: 42,
                                              decoration: const BoxDecoration(
                                                color: _primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: _isPickingImage
                                                  ? const Padding(
                                                      padding: EdgeInsets.all(
                                                        10,
                                                      ),
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.white,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.camera_alt_outlined,
                                                      color: Colors.white,
                                                      size: 22,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    GestureDetector(
                                      onTap: _isPickingImage
                                          ? null
                                          : _pickProfilePicture,
                                      child: const Text(
                                        'Change profile picture',
                                        style: TextStyle(
                                          color: _mutedColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // NAME
                              _buildField(
                                label: 'Name',
                                controller: _nameController,
                                icon: Icons.person_outline_rounded,
                                hintText: 'Your name',
                                validator: _validateName,
                              ),

                              const SizedBox(height: 17),

                              // USERNAME
                              _buildField(
                                label: 'Username',
                                controller: _usernameController,
                                icon: Icons.alternate_email_rounded,
                                hintText: 'username',
                                validator: _validateUsername,
                              ),

                              const SizedBox(height: 17),

                              // BIO
                              _buildField(
                                label: 'Bio',
                                controller: _bioController,
                                icon: Icons.info_outline_rounded,
                                hintText: 'Tell people a little about you',
                                maxLines: 3,
                              ),

                              const SizedBox(height: 17),

                              // PHONE
                              _buildPhoneField(),

                              const SizedBox(height: 25),

                              // SAVE BUTTON
                              Center(
                                child: ElevatedButton(
                                  onPressed: _isSaving || _isPickingImage
                                      ? null
                                      : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: _primaryColor
                                        .withValues(alpha: 0.55),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 27,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 19,
                                          height: 19,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
