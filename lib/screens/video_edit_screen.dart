import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoEditScreen extends StatefulWidget {
  final File file;

  const VideoEditScreen({super.key, required this.file});

  @override
  State<VideoEditScreen> createState() => _VideoEditScreenState();
}

class _VideoEditScreenState extends State<VideoEditScreen> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      await _trimmer.loadVideo(videoFile: widget.file);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load this video.')),
        );
      }
    }
  }

  Future<void> _saveVideo() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      String? outputPath;
      await _trimmer.saveTrimmedVideo(
        startValue: _startValue,
        endValue: _endValue,
        onSave: (path) {
          outputPath = path;
        },
      );

      if (!mounted) return;

      setState(() => _saving = false);

      if (outputPath != null && outputPath!.isNotEmpty) {
        Navigator.of(context).pop(File(outputPath!));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the edited video.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the edited video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Edit video'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveVideo,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: VideoViewer(trimmer: _trimmer)),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              decoration: const BoxDecoration(
                color: Color(0xFF171317),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Trim your video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TrimViewer(
                    trimmer: _trimmer,
                    viewerHeight: 64,
                    viewerWidth: MediaQuery.of(context).size.width - 32,
                    maxVideoLength: const Duration(minutes: 5),
                    onChangeStart: (value) {
                      _startValue = value;
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                    },
                    onChangePlaybackState: (value) {
                      if (mounted) setState(() => _isPlaying = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  IconButton(
                    onPressed: () async {
                      final playing = await _trimmer.videoPlaybackControl(
                        startValue: _startValue,
                        endValue: _endValue,
                      );
                      if (mounted) setState(() => _isPlaying = playing);
                    },
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Drag the handles to choose the part to keep.',
                    style: TextStyle(color: Color(0xFFBBAEB5), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
