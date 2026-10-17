import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ------------------------------------------------------------
// NATURE COLOURS — independent of brié's global theme
// ------------------------------------------------------------

const Color _forestMist = Color(0xFFEAF2E6);
const Color _softSage = Color(0xFFD5E5D0);
const Color _leafGreen = Color(0xFF789878);
const Color _forestGreen = Color(0xFF365C46);
const Color _warmIvory = Color(0xFFF8F7EF);
const Color _mutedGreen = Color(0xFF718675);
const Color _ringBackground = Color(0xFFC9D8C6);

class BreatheScreen extends StatefulWidget {
  final VoidCallback onBack;

  const BreatheScreen({super.key, required this.onBack});

  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AudioPlayer _windPlayer;

  static const int _cycleSeconds = 16;

  static const double _inhaleEnd = 4 / 16;
  static const double _holdEnd = 6 / 16;
  static const double _exhaleEnd = 12 / 16;

  bool _isPaused = true;
  bool _windEnabled = true;
  bool _soundReady = false;
  bool _isLeaving = false;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();

    // Start at the beginning, but do not animate automatically.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _cycleSeconds),
    );

    _windPlayer = AudioPlayer();
    _prepareWind();
  }

  // ------------------------------------------------------------
  // BACK NAVIGATION
  // ------------------------------------------------------------

  void _handleBack() {
    if (_isLeaving || !mounted) return;

    _isLeaving = true;
    _controller.stop();

    // Pause audio immediately; disposal follows when the parent
    // removes this subsection from the widget tree.
    _windPlayer.pause();

    widget.onBack();
  }

  // ------------------------------------------------------------
  // WIND AUDIO
  // ------------------------------------------------------------

  Future<void> _prepareWind() async {
    try {
      await _windPlayer.setReleaseMode(ReleaseMode.loop);
      await _windPlayer.setVolume(0.22);
      await _windPlayer.setSource(AssetSource('audio/soft_wind.mp3'));

      if (!mounted) return;

      setState(() => _soundReady = true);

      // Intentionally remain silent until the user presses Play.
    } catch (error) {
      debugPrint('Unable to load wind sound: $error');

      if (mounted) {
        setState(() => _soundReady = false);
      }
    }
  }

  Future<void> _toggleWind() async {
    if (_isLeaving) return;

    setState(() {
      _windEnabled = !_windEnabled;
    });

    // Do not play wind before the exercise has started.
    if (!_hasStarted || _isPaused || !_soundReady) return;

    try {
      if (_windEnabled) {
        await _windPlayer.resume();
      } else {
        await _windPlayer.pause();
      }
    } catch (error) {
      debugPrint('Unable to change wind sound: $error');
    }
  }

  // ------------------------------------------------------------
  // PLAY / PAUSE / RESET
  // ------------------------------------------------------------

  Future<void> _togglePause() async {
    if (_isLeaving) return;

    if (_isPaused) {
      // Start or resume the breathing exercise.
      setState(() {
        _isPaused = false;
        _hasStarted = true;
      });

      _controller.repeat();

      if (_windEnabled && _soundReady) {
        try {
          await _windPlayer.resume();
        } catch (error) {
          debugPrint('Unable to resume wind sound: $error');
        }
      }
    } else {
      // Pause at the current breathing phase.
      setState(() {
        _isPaused = true;
      });

      _controller.stop();

      try {
        await _windPlayer.pause();
      } catch (error) {
        debugPrint('Unable to pause wind sound: $error');
      }
    }
  }

  Future<void> _resetExercise() async {
    if (_isLeaving) return;

    _controller
      ..stop()
      ..value = 0;

    setState(() {
      _isPaused = true;
      _hasStarted = false;
    });

    try {
      await _windPlayer.pause();
    } catch (error) {
      debugPrint('Unable to reset wind sound: $error');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _windPlayer.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BREATHING CYCLE
  // ------------------------------------------------------------

  String _getPhase(double progress) {
    if (progress < _inhaleEnd) return 'Breathe in';
    if (progress < _holdEnd) return 'Hold';
    if (progress < _exhaleEnd) return 'Breathe out';
    return 'Rest';
  }

  String _getInstruction(double progress) {
    if (progress < _inhaleEnd) {
      return 'Slowly fill your lungs';
    }

    if (progress < _holdEnd) {
      return 'Stay here for a moment';
    }

    if (progress < _exhaleEnd) {
      return 'Gently release your breath';
    }

    return 'Take a quiet moment to rest';
  }

  int _getRestDots(double progress) {
    if (progress < _exhaleEnd) return 0;

    final restProgress = (progress - _exhaleEnd) / (1 - _exhaleEnd);

    return (4 - (restProgress * 4).floor()).clamp(1, 4);
  }

  double _smooth(double value) {
    return Curves.easeInOut.transform(value.clamp(0.0, 1.0));
  }

  double _getCircleScale(double progress) {
    if (progress < _inhaleEnd) {
      return 0.72 + 0.28 * _smooth(progress / _inhaleEnd);
    }

    if (progress < _holdEnd) return 1.0;

    if (progress < _exhaleEnd) {
      final t = (progress - _holdEnd) / (_exhaleEnd - _holdEnd);

      return 1.0 - 0.28 * _smooth(t);
    }

    return 0.72;
  }

  double _getRingProgress(double progress) {
    if (progress < _inhaleEnd) {
      return progress / _inhaleEnd;
    }

    if (progress < _holdEnd) return 1.0;

    if (progress < _exhaleEnd) {
      return 1.0 - (progress - _holdEnd) / (_exhaleEnd - _holdEnd);
    }

    return 0.0;
  }

  // ------------------------------------------------------------
  // SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: _forestMist,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;

              final phase = !_hasStarted
                  ? 'Ready to breathe'
                  : _getPhase(progress);

              final instruction = !_hasStarted
                  ? 'Take a moment. Start when you feel ready.'
                  : _getInstruction(progress);

              final scale = !_hasStarted ? 0.72 : _getCircleScale(progress);

              final ringProgress = !_hasStarted
                  ? 0.0
                  : _getRingProgress(progress);

              final restDots = !_hasStarted ? 0 : _getRestDots(progress);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                child: Column(
                  children: [
                    // Top bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: _handleBack,
                          icon: const Icon(Icons.arrow_back_ios_new),
                          color: _forestGreen,
                          tooltip: 'Back to Home',
                        ),
                        const Expanded(
                          child: Text(
                            'Breathe',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              color: _forestGreen,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleWind,
                          tooltip: _windEnabled
                              ? 'Turn wind sound off'
                              : 'Turn wind sound on',
                          icon: Icon(
                            _windEnabled
                                ? Icons.air_rounded
                                : Icons.volume_off_rounded,
                          ),
                          color: _forestGreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Find your quiet place 🌿',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        color: _forestGreen,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Breathe gently. Let the noise of the day drift away.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: _mutedGreen,
                      ),
                    ),

                    const SizedBox(height: 34),

                    // Animated breathing circle and ring
                    SizedBox(
                      width: 310,
                      height: 310,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 285,
                            height: 285,
                            child: CustomPaint(
                              painter: _BreathingRingPainter(
                                progress: ringProgress,
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 210,
                              height: 210,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _softSage,
                                boxShadow: [
                                  BoxShadow(
                                    color: _leafGreen.withOpacity(0.18),
                                    blurRadius: 32,
                                    spreadRadius: 7,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _BreathingFace(phase: phase),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BreathingDotPainter(
                                progress: ringProgress,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Current breathing phase
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: phase == 'Rest'
                          ? Column(
                              key: const ValueKey('rest'),
                              children: [
                                const Text(
                                  'Rest',
                                  style: TextStyle(
                                    fontSize: 29,
                                    fontWeight: FontWeight.w600,
                                    color: _forestGreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(4, (index) {
                                    return AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      opacity: index < restDots ? 1.0 : 0.2,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: _leafGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            )
                          : Text(
                              phase,
                              key: ValueKey(phase),
                              style: const TextStyle(
                                fontSize: 29,
                                fontWeight: FontWeight.w600,
                                color: _forestGreen,
                              ),
                            ),
                    ),

                    const SizedBox(height: 10),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        instruction,
                        key: ValueKey(instruction),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: _mutedGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Sound status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _warmIvory,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _windEnabled
                                ? Icons.air_rounded
                                : Icons.volume_off_rounded,
                            size: 19,
                            color: _leafGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            !_windEnabled
                                ? 'Quiet mode · On'
                                : !_hasStarted
                                ? 'Wind ready · Starts with Play'
                                : _soundReady
                                ? 'Gentle wind · On'
                                : 'Wind sound unavailable',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Reset and Play/Pause controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _resetExercise,
                          tooltip: 'Reset exercise',
                          icon: const Icon(Icons.refresh_rounded),
                          iconSize: 27,
                          color: _forestGreen,
                        ),
                        const SizedBox(width: 22),
                        GestureDetector(
                          onTap: _togglePause,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _leafGreen,
                            ),
                            child: Icon(
                              _hasStarted && !_isPaused
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      !_hasStarted
                          ? 'Press play when you are ready'
                          : _isPaused
                          ? 'Paused · Resume when ready'
                          : 'You are doing beautifully',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: _mutedGreen),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'Be gentle with yourself. 🦋',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: _mutedGreen,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// BREATHING FACE
// ------------------------------------------------------------

class _BreathingFace extends StatelessWidget {
  final String phase;

  const _BreathingFace({required this.phase});

  @override
  Widget build(BuildContext context) {
    final eyeType =
        phase == 'Breathe in' || phase == 'Rest' || phase == 'Ready to breathe'
        ? _EyeType.closed
        : _EyeType.open;

    final mouthType = phase == 'Breathe out'
        ? _MouthType.breathingOut
        : phase == 'Hold'
        ? _MouthType.smile
        : _MouthType.smallSmile;

    return CustomPaint(
      size: const Size(110, 90),
      painter: _FacePainter(eyeType: eyeType, mouthType: mouthType),
    );
  }
}

enum _EyeType { open, closed }

enum _MouthType { smile, smallSmile, breathingOut }

// ------------------------------------------------------------
// FACE PAINTER
// ------------------------------------------------------------

class _FacePainter extends CustomPainter {
  final _EyeType eyeType;
  final _MouthType mouthType;

  _FacePainter({required this.eyeType, required this.mouthType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _forestGreen
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final leftEyeX = centerX - 25;
    final rightEyeX = centerX + 25;
    const eyeY = 28.0;

    if (eyeType == _EyeType.closed) {
      final leftEye = Path()
        ..moveTo(leftEyeX - 8, eyeY)
        ..quadraticBezierTo(leftEyeX, eyeY + 7, leftEyeX + 8, eyeY);

      final rightEye = Path()
        ..moveTo(rightEyeX - 8, eyeY)
        ..quadraticBezierTo(rightEyeX, eyeY + 7, rightEyeX + 8, eyeY);

      canvas.drawPath(leftEye, paint);
      canvas.drawPath(rightEye, paint);
    } else {
      final eyePaint = Paint()
        ..color = _forestGreen
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(leftEyeX, eyeY), 4, eyePaint);

      canvas.drawCircle(Offset(rightEyeX, eyeY), 4, eyePaint);
    }

    if (mouthType == _MouthType.smile) {
      final mouth = Path()
        ..moveTo(centerX - 15, 51)
        ..quadraticBezierTo(centerX, 67, centerX + 15, 51);

      canvas.drawPath(mouth, paint);
    } else if (mouthType == _MouthType.smallSmile) {
      final mouth = Path()
        ..moveTo(centerX - 11, 52)
        ..quadraticBezierTo(centerX, 61, centerX + 11, 52);

      canvas.drawPath(mouth, paint);
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX, 57), width: 15, height: 9),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.eyeType != eyeType || oldDelegate.mouthType != mouthType;
  }
}

// ------------------------------------------------------------
// BREATHING RING
// ------------------------------------------------------------

class _BreathingRingPainter extends CustomPainter {
  final double progress;

  _BreathingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 8;

    final backgroundPaint = Paint()
      ..color = _ringBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = _leafGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ------------------------------------------------------------
// MOVING DOT
// ------------------------------------------------------------

class _BreathingDotPainter extends CustomPainter {
  final double progress;

  _BreathingDotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 8;
    final angle = -math.pi / 2 + 2 * math.pi * progress;

    final dotPosition = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final paint = Paint()
      ..color = _leafGreen
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dotPosition, 7, paint);
  }

  @override
  bool shouldRepaint(covariant _BreathingDotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
