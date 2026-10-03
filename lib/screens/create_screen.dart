import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'camera_screen.dart';
import 'video_edit_screen.dart';
import 'write_screen.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final ImagePicker _picker = ImagePicker();

  final List<_Creation> _creations = [];

  @override
  void initState() {
    super.initState();

    _creations.addAll([
      const _Creation(
        type: CreationType.image,
        title: 'Sunlit moment',
        description: 'A little image from the day.',
        comments: [],
        isSample: true,
      ),
      const _Creation(
        type: CreationType.text,
        title: 'A little thought',
        description: 'A short note to keep close.',
        comments: [],
        isSample: true,
      ),
      const _Creation(
        type: CreationType.image,
        title: 'Soft focus',
        description: 'A quiet frame worth keeping.',
        comments: [],
        isSample: true,
      ),
      const _Creation(
        type: CreationType.file,
        title: 'Shared file',
        description: 'A simple thing saved for later.',
        comments: [],
        isSample: true,
      ),
    ]);
  }

  // ===============================================================
  // CREATE MENU
  // ===============================================================

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8C7CE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5A4050),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose a little way to make something.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF8B727D)),
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CreateOption(
                      icon: Icons.edit_rounded,
                      label: 'Write',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openWrite();
                      },
                    ),
                    _CreateOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openCamera();
                      },
                    ),
                    _CreateOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickFromGallery();
                      },
                    ),
                    _CreateOption(
                      icon: Icons.folder_rounded,
                      label: 'File',
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _pickFile();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // WRITE
  // ===============================================================

  Future<void> _openWrite() async {
    final result = await Navigator.of(context)
        .push<String>(MaterialPageRoute(builder: (_) => const WriteScreen()));

    if (!mounted) return;

    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        _creations.insert(
          0,
          _Creation(
            type: CreationType.text,
            title: 'A little thought',
            description: result.trim(),
            comments: const [],
          ),
        );
      });
    }
  }

  // ===============================================================
  // CAMERA
  // ===============================================================

  Future<void> _openCamera() async {
    try {
      final XFile? media = await Navigator.of(context)
          .push<XFile>(MaterialPageRoute(builder: (_) => const CameraScreen()));

      if (media == null || !mounted) return;

      final isVideo = _looksLikeVideo(media.path);

      final draft = await _showCapturedMediaPreview(
        file: File(media.path),
        isVideo: isVideo,
      );

      if (!mounted || draft == null || !draft.post) return;

      setState(() {
        _creations.insert(
          0,
          _Creation(
            type: isVideo ? CreationType.video : CreationType.image,
            title: '',
            description: '',
            comment: draft.comment,
            comments: const [],
            filePath: draft.filePath,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;

      _showError('Could not open the camera.');
    }
  }

  // ===============================================================
  // GALLERY
  // ===============================================================

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> files = await _picker.pickMultipleMedia(
        imageQuality: 90,
      );

      if (files.isEmpty || !mounted) return;

      final List<_Creation> selected = [];

      for (final file in files) {
        if (!mounted) return;

        final bool isVideo = _looksLikeVideo(file.path);

        final draft = await _showCapturedMediaPreview(
          file: File(file.path),
          isVideo: isVideo,
        );

        if (draft != null && draft.post) {
          selected.add(
            _Creation(
              type: isVideo ? CreationType.video : CreationType.image,
              title: '',
              description: '',
              comment: draft.comment,
              comments: const [],
              filePath: draft.filePath,
            ),
          );
        }
      }

      if (!mounted || selected.isEmpty) return;

      setState(() {
        _creations.insertAll(0, selected);
      });
    } catch (_) {
      if (!mounted) return;

      _showError('We could not access the gallery. Please try again.');
    }
  }

  // ===============================================================
  // FILE
  // ===============================================================

  Future<void> _pickFile() async {
    try {
      final List<PlatformFile>? result = await FilePicker.pickFiles();

      if (result == null || result.isEmpty) {
        return;
      }

      final picked = result.first;

      if (picked.path == null) {
        if (!mounted) return;

        _showError('We could not access that file.');
        return;
      }

      if (!mounted) return;

      setState(() {
        _creations.insert(
          0,
          _Creation(
            type: CreationType.file,
            title: picked.name,
            description: 'A shared file.',
            comments: const [],
            filePath: picked.path,
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;

      _showError('Could not upload the file.');
    }
  }

  // ===============================================================
  // MEDIA HELPERS
  // ===============================================================

  bool _looksLikeVideo(String path) {
    final String lower = path.toLowerCase();

    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.m4v');
  }

  Future<_PostDraft?> _showCapturedMediaPreview({
    required File file,
    required bool isVideo,
  }) {
    return showDialog<_PostDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _CapturedMediaDialog(file: file, isVideo: isVideo);
      },
    );
  }

  // ===============================================================
  // CREATION DETAIL
  // ===============================================================

  void _openCreation(_Creation creation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreationDetailScreen(
          creation: creation,
          recommendations: _creations,
        ),
      ),
    );
  }

  // ===============================================================
  // ERROR
  // ===============================================================

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Create',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4050),
                        height: 1.1,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'A little space to make something yours.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF8B727D),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_creations.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nothing here yet.\nTap + to create something.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF8B727D),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final creation = _creations[index];

                    return _CreationCard(
                      creation: creation,
                      onTap: () {
                        _openCreation(creation);
                      },
                    );
                  }, childCount: _creations.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    childAspectRatio: 0.72,
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateMenu,
        backgroundColor: const Color(0xFFC75D83),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
      ),

      // IMPORTANT:
      // There is NO bottom navigation here.
      //
      // MainNavigationScreen owns the permanent
      // Home / Create / Me navigation.
    );
  }
}

// ===================================================================
// CREATION TYPES
// ===================================================================

enum CreationType { image, video, text, file }

class _Creation {
  final CreationType type;
  final String title;
  final String description;
  final String comment;
  final List<String> comments;
  final String? filePath;
  final bool isSample;

  const _Creation({
    required this.type,
    required this.title,
    required this.description,
    this.comment = '',
    this.comments = const [],
    this.filePath,
    this.isSample = false,
  });
}

class _PostDraft {
  final bool post;
  final String comment;
  final String filePath;

  const _PostDraft({
    required this.post,
    required this.comment,
    required this.filePath,
  });
}

// ===================================================================
// CREATE OPTION
// ===================================================================

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0EA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFC75D83), size: 27),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A4050)),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// CREATION CARD
// ===================================================================

class _CreationCard extends StatelessWidget {
  final _Creation creation;
  final VoidCallback onTap;

  const _CreationCard({required this.creation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (creation.type) {
      case CreationType.image:
        return _ImageCreationCard(creation: creation);

      case CreationType.video:
        return _VideoCreationCard(creation: creation);

      case CreationType.text:
        return _TextCreationCard(creation: creation);

      case CreationType.file:
        return _FileCreationCard(creation: creation);
    }
  }
}

// ===================================================================
// IMAGE CARD
// ===================================================================

class _ImageCreationCard extends StatelessWidget {
  final _Creation creation;

  const _ImageCreationCard({required this.creation});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: creation.filePath != null && !creation.isSample
          ? Image.file(
              File(creation.filePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _placeholder();
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFFFE8EF),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 42,
          color: Color(0xFFC75D83),
        ),
      ),
    );
  }
}

// ===================================================================
// VIDEO CARD
// ===================================================================

class _VideoCreationCard extends StatefulWidget {
  final _Creation creation;

  const _VideoCreationCard({required this.creation});

  @override
  State<_VideoCreationCard> createState() => _VideoCreationCardState();
}

class _VideoCreationCardState extends State<_VideoCreationCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    final path = widget.creation.filePath;

    if (path != null) {
      _controller = VideoPlayerController.file(File(path))
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (!mounted) return;

          setState(() {});

          _controller?.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: const Color(0xFFEFEAF5),
          child: const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 45,
              color: Color(0xFF9A82AE),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),

          const Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.volume_off_rounded,
              color: Colors.white,
              size: 20,
              shadows: [Shadow(blurRadius: 6)],
            ),
          ),

          const Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              color: Colors.white,
              size: 45,
              shadows: [Shadow(blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// TEXT CARD
// ===================================================================

class _TextCreationCard extends StatelessWidget {
  final _Creation creation;

  const _TextCreationCard({required this.creation});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE8EF),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Color(0xFFC75D83),
            size: 31,
          ),

          const SizedBox(height: 12),

          Text(
            creation.description,
            maxLines: 9,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
              color: Color(0xFF5A4050),
            ),
          ),

          const Spacer(),

          Text(
            creation.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A5868),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// FILE CARD
// ===================================================================

class _FileCreationCard extends StatelessWidget {
  final _Creation creation;

  const _FileCreationCard({required this.creation});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF5EF),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insert_drive_file_rounded,
              color: Color(0xFF5B9272),
              size: 27,
            ),
          ),

          const Spacer(),

          Text(
            creation.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF385A45),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            creation.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Color(0xFF6D8876),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// CAPTURED MEDIA DIALOG
// ===================================================================

class _CapturedMediaDialog extends StatefulWidget {
  final File file;
  final bool isVideo;

  const _CapturedMediaDialog({required this.file, required this.isVideo});

  @override
  State<_CapturedMediaDialog> createState() => _CapturedMediaDialogState();
}

class _CapturedMediaDialogState extends State<_CapturedMediaDialog> {
  late File _currentFile;

  VideoPlayerController? _videoController;

  late final TextEditingController _commentController;

  late final FocusNode _commentFocusNode;

  bool _muted = true;
  bool _loadingVideo = false;

  @override
  void initState() {
    super.initState();

    _currentFile = widget.file;

    _commentController = TextEditingController();

    _commentFocusNode = FocusNode();

    if (widget.isVideo) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    if (!mounted) return;

    setState(() {
      _loadingVideo = true;
    });

    await _videoController?.dispose();

    final controller = VideoPlayerController.file(_currentFile);

    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);

      if (!mounted) return;

      setState(() {
        _loadingVideo = false;
      });

      await controller.play();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingVideo = false;
      });
    }
  }

  Future<void> _editVideo() async {
    if (!widget.isVideo) return;

    final File? edited = await Navigator.of(context).push<File>(
      MaterialPageRoute(builder: (_) => VideoEditScreen(file: _currentFile)),
    );

    if (edited == null || !mounted) {
      return;
    }

    setState(() {
      _currentFile = edited;
    });

    await _loadVideo();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _videoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool ready =
        !widget.isVideo ||
        (!_loadingVideo &&
            _videoController != null &&
            _videoController!.value.isInitialized);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F7),
          borderRadius: BorderRadius.circular(28),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 14, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ready to share?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4050),
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF8B727D),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: ready && widget.isVideo
                            ? _videoController!.value.aspectRatio
                            : 1,
                        child: widget.isVideo
                            ? _buildVideoPreview(ready)
                            : Image.file(_currentFile, fit: BoxFit.cover),
                      ),
                    ),

                    if (widget.isVideo && ready) ...[
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          IconButton(
                            onPressed: _togglePlay,
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: const Color(0xFFC75D83),
                              size: 34,
                            ),
                          ),

                          Expanded(
                            child: VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: _toggleMute,
                            icon: Icon(
                              _muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: const Color(0xFFC75D83),
                            ),
                          ),
                        ],
                      ),

                      OutlinedButton.icon(
                        onPressed: _editVideo,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text('Edit video'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC75D83),
                          side: const BorderSide(color: Color(0xFFC75D83)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add a comment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A4050),
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      maxLines: 3,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Say something about this creation…',
                        hintStyle: const TextStyle(color: Color(0xFFB39EA8)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(15),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: const Color(0xFFC75D83),
                              side: const BorderSide(color: Color(0xFFC75D83)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton(
                            onPressed: !ready
                                ? null
                                : () {
                                    Navigator.pop(
                                      context,
                                      _PostDraft(
                                        post: true,
                                        comment: _commentController.text.trim(),
                                        filePath: _currentFile.path,
                                      ),
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: const Color(0xFFC75D83),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Post it'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(bool ready) {
    if (!ready) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFC75D83)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        VideoPlayer(_videoController!),

        if (!_videoController!.value.isPlaying)
          IconButton(
            onPressed: _togglePlay,
            icon: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 64,
            ),
          ),
      ],
    );
  }

  void _togglePlay() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _muted = !_muted;

      controller.setVolume(_muted ? 0 : 1);
    });
  }
}

// ===================================================================
// CREATION DETAIL
// ===================================================================

class CreationDetailScreen extends StatefulWidget {
  final _Creation creation;
  final List<_Creation> recommendations;

  const CreationDetailScreen({
    super.key,
    required this.creation,
    required this.recommendations,
  });

  @override
  State<CreationDetailScreen> createState() => _CreationDetailScreenState();
}

class _CreationDetailScreenState extends State<CreationDetailScreen> {
  late final TextEditingController _commentController;

  late final FocusNode _commentFocusNode;

  late final List<String> _comments;

  bool _liked = false;

  @override
  void initState() {
    super.initState();

    _commentController = TextEditingController();

    _commentFocusNode = FocusNode();

    _comments = List<String>.from(widget.creation.comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();

    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _comments.add(text);
      _commentController.clear();
    });
  }

  void _shareCreation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing will be connected later.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final related = widget.recommendations
        .where((item) => !identical(item, widget.creation))
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF4F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5A4050)),
        title: const Text(
          'Creation',
          style: TextStyle(
            color: Color(0xFF5A4050),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadCreation(context),
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _buildMainCreation(),

          // Pinterest-style action row.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _liked = !_liked;
                    });
                  },
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked
                        ? const Color(0xFFC75D83)
                        : const Color(0xFF5A4050),
                  ),
                  tooltip: 'Like',
                ),

                const SizedBox(width: 4),

                IconButton(
                  onPressed: () {
                    FocusScope.of(context).requestFocus(_commentFocusNode);
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF5A4050),
                  ),
                  tooltip: 'Comments',
                ),

                const SizedBox(width: 4),

                IconButton(
                  onPressed: _shareCreation,
                  icon: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFF5A4050),
                  ),
                  tooltip: 'Share',
                ),

                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF5A4050),
                  ),
                  tooltip: 'More',
                ),
              ],
            ),
          ),

          // The post's own comment/note appears only after opening it.
          if (widget.creation.comment.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 4),
              child: Text(
                widget.creation.comment,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF5A4050),
                ),
              ),
            ),

          if (widget.creation.type == CreationType.text)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
              child: Text(
                widget.creation.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF5A4050),
                ),
              ),
            ),

          _buildCommentsSection(),

          if (related.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 30, 22, 14),
              child: Text(
                'More like this',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A4050),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: related.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final item = related[index];

                  return _CreationCard(
                    creation: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreationDetailScreen(
                            creation: item,
                            recommendations: widget.recommendations,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _comments.isEmpty ? 'Comments' : 'Comments (${_comments.length})',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A4050),
            ),
          ),

          const SizedBox(height: 12),

          if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Be the first to leave a little thought.',
                style: TextStyle(fontSize: 14, color: Color(0xFF8B727D)),
              ),
            )
          else
            ..._comments.map((comment) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF5A4050),
                  ),
                ),
              );
            }),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: const TextStyle(color: Color(0xFF9C8A92)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(
                        color: Color(0xFFC75D83),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                onPressed: _addComment,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFC75D83),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCreation() {
    switch (widget.creation.type) {
      case CreationType.image:
        if (widget.creation.filePath != null) {
          return Image.file(
            File(widget.creation.filePath!),
            width: double.infinity,
            fit: BoxFit.contain,
          );
        }

        return Container(
          height: 380,
          color: const Color(0xFFFFE8EF),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 70,
            color: Color(0xFFC75D83),
          ),
        );

      case CreationType.video:
        if (widget.creation.filePath != null) {
          return _DetailVideoPlayer(file: File(widget.creation.filePath!));
        }

        return Container(
          height: 380,
          color: const Color(0xFFEFEAF5),
          child: const Icon(
            Icons.play_circle_fill_rounded,
            size: 70,
            color: Color(0xFF9A82AE),
          ),
        );

      case CreationType.text:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          color: const Color(0xFFFFE8EF),
          child: Text(
            widget.creation.description,
            style: const TextStyle(
              fontSize: 22,
              height: 1.55,
              color: Color(0xFF5A4050),
            ),
          ),
        );

      case CreationType.file:
        return Container(
          height: 300,
          color: const Color(0xFFEAF5EF),
          child: const Center(
            child: Icon(
              Icons.insert_drive_file_rounded,
              size: 85,
              color: Color(0xFF5B9272),
            ),
          ),
        );
    }
  }

  // ===============================================================
  // DOWNLOAD
  // ===============================================================

  Future<void> _downloadCreation(BuildContext context) async {
    try {
      Uint8List bytes;
      String fileName;
      String mimeType;

      if (widget.creation.type == CreationType.text) {
        bytes = Uint8List.fromList(utf8.encode(widget.creation.description));

        fileName = '${_safeFileName(widget.creation.title)}.txt';

        mimeType = 'text/plain';
      } else {
        final path = widget.creation.filePath;

        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This sample creation cannot be downloaded yet.'),
            ),
          );
          return;
        }

        final file = File(path);

        if (!await file.exists()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('The original file could not be found.'),
            ),
          );
          return;
        }

        bytes = await file.readAsBytes();

        fileName = _fileNameWithExtension(widget.creation.title, path);

        mimeType = _mimeTypeForPath(path);
      }

      final Uri? savedLocation = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );

      if (!context.mounted) return;

      if (savedLocation != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creation saved successfully.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download this creation.')),
      );
    }
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _fileNameWithExtension(String title, String originalPath) {
    final originalName = originalPath.split(Platform.pathSeparator).last;

    final dotIndex = originalName.lastIndexOf('.');

    final safeTitle = _safeFileName(title.trim());

    if (safeTitle.isEmpty) {
      return originalName;
    }

    if (dotIndex != -1) {
      final extension = originalName.substring(dotIndex);

      return '$safeTitle$extension';
    }

    return safeTitle;
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lower.endsWith('.mp4')) {
      return 'video/mp4';
    }

    if (lower.endsWith('.mov')) {
      return 'video/quicktime';
    }

    if (lower.endsWith('.webm')) {
      return 'video/webm';
    }

    if (lower.endsWith('.pdf')) {
      return 'application/pdf';
    }

    if (lower.endsWith('.doc')) {
      return 'application/msword';
    }

    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    return 'application/octet-stream';
  }
}

// ===================================================================
// DETAIL VIDEO PLAYER
// ===================================================================

class _DetailVideoPlayer extends StatefulWidget {
  final File file;

  const _DetailVideoPlayer({required this.file});

  @override
  State<_DetailVideoPlayer> createState() => _DetailVideoPlayerState();
}

class _DetailVideoPlayerState extends State<_DetailVideoPlayer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(widget.file)
      ..setLooping(false)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 350,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),

              if (!_controller.value.isPlaying)
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 70,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 8)],
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: const Color(0xFFC75D83),
                  size: 34,
                ),
              ),

              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    final volume = _controller.value.volume;

                    _controller.setVolume(volume == 0 ? 1 : 0);
                  });
                },
                icon: Icon(
                  _controller.value.volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: const Color(0xFFC75D83),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
