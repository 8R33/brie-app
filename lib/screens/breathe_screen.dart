import 'dart:math' as math;

import 'package:flutter/material.dart';

class BreatheScreen extends StatefulWidget {
  const BreatheScreen({super.key});

  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // ---------------------------------------------------------------
  // BREATHING TIMING
  // ---------------------------------------------------------------
  //
  // One complete breathing cycle:
  //
  // 4 seconds - Breathe in
  // 2 seconds - Hold
  // 6 seconds - Breathe out
  // 4 seconds - Rest
  //
  // Total: 16 seconds
  //

  static const double inhaleEnd = 4 / 16;
  static const double holdEnd = 6 / 16;
  static const double exhaleEnd = 12 / 16;

  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // PAUSE / RESUME
  // ---------------------------------------------------------------

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _controller.repeat();
        _isPaused = false;
      } else {
        _controller.stop();
        _isPaused = true;
      }
    });
  }

  // ---------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------

  void _resetExercise() {
    _controller
      ..stop()
      ..value = 0
      ..repeat();

    setState(() {
      _isPaused = false;
    });
  }

  // ---------------------------------------------------------------
  // GET CURRENT BREATHING PHASE
  // ---------------------------------------------------------------

  String _getPhase(double progress) {
    if (progress < inhaleEnd) {
      return 'Breathe in';
    } else if (progress < holdEnd) {
      return 'Hold';
    } else if (progress < exhaleEnd) {
      return 'Breathe out';
    } else {
      return 'Rest';
    }
  }

  // ---------------------------------------------------------------
  // GET CURRENT INSTRUCTION
  // ---------------------------------------------------------------

  String _getInstruction(double progress) {
    if (progress < inhaleEnd) {
      return 'Slowly fill your lungs';
    } else if (progress < holdEnd) {
      return 'Stay here for a moment';
    } else if (progress < exhaleEnd) {
      return 'Gently release your breath';
    } else {
      return 'Take a quiet moment to rest';
    }
  }

  // ---------------------------------------------------------------
  // REST DOTS
  // ---------------------------------------------------------------

  int _getRestDots(double progress) {
    if (progress < exhaleEnd) {
      return 0;
    }

    final restProgress = (progress - exhaleEnd) / (1 - exhaleEnd);

    final dotsRemaining = 4 - (restProgress * 4).floor();

    return dotsRemaining.clamp(1, 4);
  }

  // ---------------------------------------------------------------
  // CIRCLE SIZE
  // ---------------------------------------------------------------

  double _getCircleScale(double progress) {
    // BREATHE IN
    if (progress < inhaleEnd) {
      final t = progress / inhaleEnd;

      return 0.72 + (0.28 * _smooth(t));
    }

    // HOLD
    if (progress < holdEnd) {
      return 1.0;
    }

    // BREATHE OUT
    if (progress < exhaleEnd) {
      final t = (progress - holdEnd) / (exhaleEnd - holdEnd);

      return 1.0 - (0.28 * _smooth(t));
    }

    // REST
    return 0.72;
  }

  // ---------------------------------------------------------------
  // RING PROGRESS
  // ---------------------------------------------------------------

  double _getRingProgress(double progress) {
    // BREATHE IN
    if (progress < inhaleEnd) {
      return progress / inhaleEnd;
    }

    // HOLD
    if (progress < holdEnd) {
      return 1.0;
    }

    // BREATHE OUT
    if (progress < exhaleEnd) {
      final t = (progress - holdEnd) / (exhaleEnd - holdEnd);

      return 1.0 - t;
    }

    // REST
    return 0.0;
  }

  // ---------------------------------------------------------------
  // SMOOTH ANIMATION
  // ---------------------------------------------------------------

  double _smooth(double value) {
    return Curves.easeInOut.transform(value.clamp(0.0, 1.0));
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value;

            final phase = _getPhase(progress);
            final instruction = _getInstruction(progress);
            final scale = _getCircleScale(progress);
            final ringProgress = _getRingProgress(progress);
            final restDots = _getRestDots(progress);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              child: Column(
                children: [
                  // -------------------------------------------------
                  // TOP BAR
                  // -------------------------------------------------

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back_ios_new, size: 21),
                        color: const Color(0xFF5A4050),
                      ),

                      const Expanded(
                        child: Center(
                          child: Text(
                            'Breathe',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5A4050),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // -------------------------------------------------
                  // INTRODUCTION
                  // -------------------------------------------------
                  const Text(
                    'Take a moment for yourself 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF806873),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Follow the circle and let your breathing slow down.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Color(0xFF9A8991),
                    ),
                  ),

                  const SizedBox(height: 45),

                  // -------------------------------------------------
                  // BREATHING CIRCLE
                  // -------------------------------------------------
                  SizedBox(
                    width: 310,
                    height: 310,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer breathing progress ring
                        SizedBox(
                          width: 285,
                          height: 285,
                          child: CustomPaint(
                            painter: _BreathingRingPainter(
                              progress: ringProgress,
                            ),
                          ),
                        ),

                        // Animated breathing circle
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE7F4EA),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC7DCCB)
                                      .withOpacity(0.45),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(child: _BreathingFace(phase: phase)),
                          ),
                        ),

                        // Moving marker around the ring
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

                  const SizedBox(height: 30),

                  // -------------------------------------------------
                  // BREATHING PHASE / REST DOTS
                  // -------------------------------------------------
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: phase == 'Rest'
                        ? Column(
                            key: const ValueKey('rest-dots'),
                            children: [
                              const Text(
                                'Rest',
                                style: TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5A4050),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  final isVisible = index < restDots;

                                  return AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: isVisible ? 1.0 : 0.18,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFC75D83),
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
                              color: Color(0xFF5A4050),
                            ),
                          ),
                  ),

                  const SizedBox(height: 8),

                  // -------------------------------------------------
                  // INSTRUCTION
                  // -------------------------------------------------
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      instruction,
                      key: ValueKey(instruction),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF806873),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  // -------------------------------------------------
                  // CONTROLS
                  // -------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset
                      IconButton(
                        onPressed: _resetExercise,
                        icon: const Icon(Icons.refresh),
                        iconSize: 26,
                        color: const Color(0xFF806873),
                      ),

                      const SizedBox(width: 20),

                      // Pause / Resume
                      GestureDetector(
                        onTap: _togglePause,
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFC75D83),
                          ),
                          child: Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // -------------------------------------------------
                  // FOOTER
                  // -------------------------------------------------
                  const Text(
                    'Be gentle with yourself. 🦋',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF9A8991),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// BREATHING FACE
// ================================================================

class _BreathingFace extends StatelessWidget {
  final String phase;

  const _BreathingFace({required this.phase});

  @override
  Widget build(BuildContext context) {
    // BREATHE IN
    if (phase == 'Breathe in') {
      return const _Face(
        eyeType: _EyeType.closed,
        mouthType: _MouthType.smallSmile,
      );
    }

    // HOLD
    if (phase == 'Hold') {
      return const _Face(eyeType: _EyeType.open, mouthType: _MouthType.smile);
    }

    // REST
    if (phase == 'Rest') {
      return const _Face(
        eyeType: _EyeType.closed,
        mouthType: _MouthType.smallSmile,
      );
    }

    // BREATHE OUT
    return const _Face(
      eyeType: _EyeType.open,
      mouthType: _MouthType.breathingOut,
    );
  }
}

// ================================================================
// FACE TYPES
// ================================================================

enum _EyeType { open, closed }

enum _MouthType { smile, smallSmile, breathingOut }

// ================================================================
// FACE
// ================================================================

class _Face extends StatelessWidget {
  final _EyeType eyeType;
  final _MouthType mouthType;

  const _Face({required this.eyeType, required this.mouthType});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 90,
      child: CustomPaint(
        painter: _FacePainter(eyeType: eyeType, mouthType: mouthType),
      ),
    );
  }
}

// ================================================================
// FACE PAINTER
// ================================================================

class _FacePainter extends CustomPainter {
  final _EyeType eyeType;
  final _MouthType mouthType;

  _FacePainter({required this.eyeType, required this.mouthType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5A4050)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    final leftEyeX = centerX - 25;
    final rightEyeX = centerX + 25;

    const eyeY = 28.0;

    // ------------------------------------------------------------
    // EYES
    // ------------------------------------------------------------

    if (eyeType == _EyeType.closed) {
      // Left closed eye
      final leftEye = Path()
        ..moveTo(leftEyeX - 8, eyeY)
        ..quadraticBezierTo(leftEyeX, eyeY + 7, leftEyeX + 8, eyeY);

      canvas.drawPath(leftEye, paint);

      // Right closed eye
      final rightEye = Path()
        ..moveTo(rightEyeX - 8, eyeY)
        ..quadraticBezierTo(rightEyeX, eyeY + 7, rightEyeX + 8, eyeY);

      canvas.drawPath(rightEye, paint);
    } else {
      // Open eyes
      final eyePaint = Paint()
        ..color = const Color(0xFF5A4050)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(leftEyeX, eyeY), 4, eyePaint);

      canvas.drawCircle(Offset(rightEyeX, eyeY), 4, eyePaint);
    }

    // ------------------------------------------------------------
    // MOUTH
    // ------------------------------------------------------------

    // Normal smile
    if (mouthType == _MouthType.smile) {
      final mouth = Path()
        ..moveTo(centerX - 15, 51)
        ..quadraticBezierTo(centerX, 67, centerX + 15, 51);

      canvas.drawPath(mouth, paint);
    }

    // Small relaxed smile
    if (mouthType == _MouthType.smallSmile) {
      final mouth = Path()
        ..moveTo(centerX - 11, 52)
        ..quadraticBezierTo(centerX, 61, centerX + 11, 52);

      canvas.drawPath(mouth, paint);
    }

    // Breathing out
    if (mouthType == _MouthType.breathingOut) {
      final mouthPaint = Paint()
        ..color = const Color(0xFF5A4050)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(centerX, 57), width: 15, height: 9),
        mouthPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.eyeType != eyeType || oldDelegate.mouthType != mouthType;
  }
}

// ================================================================
// BREATHING RING
// ================================================================

class _BreathingRingPainter extends CustomPainter {
  final double progress;

  _BreathingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 8;

    // Background ring
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE3D8DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Active breathing ring
    final activePaint = Paint()
      ..color = const Color(0xFFC75D83)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ================================================================
// MOVING DOT
// ================================================================

class _BreathingDotPainter extends CustomPainter {
  final double progress;

  _BreathingDotPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 8;

    final angle = (-math.pi / 2) + (2 * math.pi * progress);

    final dotX = center.dx + radius * math.cos(angle);

    final dotY = center.dy + radius * math.sin(angle);

    final paint = Paint()
      ..color = const Color(0xFFC75D83)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 7, paint);
  }

  @override
  bool shouldRepaint(covariant _BreathingDotPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
