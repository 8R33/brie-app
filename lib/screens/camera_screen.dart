import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  bool _isLoading = true;
  bool _isCapturing = false;
  bool _isRecording = false;
  bool _isVideoMode = false;

  bool _showFilters = false;
  bool _showGrid = true;

  double _zoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;

  Offset? _focusPoint;
  bool _showFocusBox = false;

  FlashMode _flashMode = FlashMode.off;

  final List<double> _aspectRatios = const [3 / 4, 1 / 1, 9 / 16];

  int _aspectIndex = 0;

  final List<_CameraFilter> _filters = const [
    _CameraFilter(name: 'Original', color: Colors.transparent, opacity: 0),
    _CameraFilter(name: 'Soft', color: Color(0xFFFFE8EF), opacity: 0.18),
    _CameraFilter(name: 'Warm', color: Color(0xFFFFC978), opacity: 0.16),
    _CameraFilter(name: 'Cool', color: Color(0xFF8FD3FF), opacity: 0.14),
    _CameraFilter(name: 'Rose', color: Color(0xFFFF8FB1), opacity: 0.16),
    _CameraFilter(name: 'Mono', color: Colors.grey, opacity: 0.42),
  ];

  int _selectedFilterIndex = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'No camera was found on this device.';
        });
        return;
      }

      final backIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (backIndex != -1) {
        _currentCameraIndex = backIndex;
      }

      await _startCamera(_cameras[_currentCameraIndex]);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cameraErrorMessage(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Something went wrong while opening the camera.';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final oldController = _controller;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    _controller = controller;

    await oldController?.dispose();

    try {
      await controller.initialize();

      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();

      await controller.setFlashMode(_flashMode);

      final safeZoom = _zoom.clamp(minZoom, maxZoom).toDouble();
      await controller.setZoomLevel(safeZoom);

      if (!mounted) return;

      setState(() {
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoom = safeZoom;
        _isLoading = false;
        _errorMessage = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cameraErrorMessage(e);
      });
    }
  }

  String _cameraErrorMessage(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Camera access was denied. Please allow brié to use your camera.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera access is disabled. Please enable it in your phone settings.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      case 'AudioAccessDenied':
        return 'Microphone access was denied. Please allow microphone access for video recording.';
      case 'AudioAccessDeniedWithoutPrompt':
        return 'Microphone access is disabled. Please enable it in your phone settings.';
      case 'AudioAccessRestricted':
        return 'Microphone access is restricted on this device.';
      default:
        return e.description ?? 'Unable to access the camera.';
    }
  }

  Future<void> _takePhoto() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _isRecording) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(photo);
    } on CameraException catch (e) {
      if (!mounted) return;
      _showMessage(_cameraErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      _showMessage("We couldn't take that photo.");
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        controller.value.isRecordingVideo) {
      return;
    }

    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);
    } on CameraException catch (e) {
      if (!mounted) return;
      _showMessage(_cameraErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      _showMessage("We couldn't start recording.");
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        !controller.value.isRecordingVideo) {
      return;
    }

    try {
      final video = await controller.stopVideoRecording();

      if (!mounted) return;

      setState(() => _isRecording = false);
      Navigator.of(context).pop(video);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      _showMessage(_cameraErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      _showMessage("We couldn't save that video.");
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isRecording || _isCapturing || _isLoading) {
      return;
    }

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;

    setState(() {
      _isLoading = true;
      _focusPoint = null;
      _showFocusBox = false;
    });

    await _startCamera(_cameras[_currentCameraIndex]);
  }

  void _changeMode(bool videoMode) {
    if (_isRecording || _isCapturing) return;

    setState(() => _isVideoMode = videoMode);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || _isRecording) {
      return;
    }

    FlashMode nextMode;

    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    try {
      await controller.setFlashMode(nextMode);
      if (!mounted) return;
      setState(() => _flashMode = nextMode);
    } catch (_) {
      _showMessage('Flash is not available on this camera.');
    }
  }

  IconData _flashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off_outlined;
      case FlashMode.auto:
        return Icons.flash_auto_outlined;
      case FlashMode.always:
        return Icons.flash_on_outlined;
      case FlashMode.torch:
        return Icons.flashlight_on_outlined;
    }
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
  }

  void _selectFilter(int index) {
    setState(() => _selectedFilterIndex = index);
  }

  void _toggleGrid() {
    setState(() => _showGrid = !_showGrid);
  }

  Future<void> _setZoom(double value) async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) return;

    final clamped = value.clamp(_minZoom, _maxZoom).toDouble();

    try {
      await controller.setZoomLevel(clamped);
      if (!mounted) return;
      setState(() => _zoom = clamped);
    } catch (_) {}
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseZoom = _zoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    _setZoom(_baseZoom * details.scale);
  }

  Future<void> _focusOnPoint(Offset localPosition, Size viewportSize) async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || _isRecording) {
      return;
    }

    final dx = (localPosition.dx / viewportSize.width).clamp(0.0, 1.0);
    final dy = (localPosition.dy / viewportSize.height).clamp(0.0, 1.0);
    final point = Offset(dx, dy);

    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _focusPoint = localPosition;
      _showFocusBox = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showFocusBox = false);
    });
  }

  String get _aspectLabel {
    switch (_aspectIndex) {
      case 0:
        return '3:4';
      case 1:
        return '1:1';
      case 2:
        return '9:16';
      default:
        return '3:4';
    }
  }

  void _changeAspectRatio() {
    setState(() {
      _aspectIndex = (_aspectIndex + 1) % _aspectRatios.length;
    });
  }

  // The selected ratio changes the viewfinder shape. The actual camera
  // preview is always fitted with BoxFit.cover, so it crops rather than
  // stretches or squeezes the camera image.
  Widget _buildCameraPreview(
    CameraController controller,
    BoxConstraints constraints,
  ) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    final targetRatio = _aspectRatios[_aspectIndex];

    double viewportWidth = screenWidth;
    double viewportHeight = viewportWidth / targetRatio;

    if (viewportHeight > screenHeight) {
      viewportHeight = screenHeight;
      viewportWidth = viewportHeight * targetRatio;
    }

    final cameraAspectRatio = controller.value.aspectRatio;
    final naturalPortraitRatio = 1 / cameraAspectRatio;

    double naturalWidth = viewportWidth;
    double naturalHeight = naturalWidth / naturalPortraitRatio;

    if (naturalHeight <= 0 || !naturalHeight.isFinite) {
      naturalHeight = viewportHeight;
    }

    return Center(
      child: SizedBox(
        width: viewportWidth,
        height: viewportHeight,
        child: ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              _focusOnPoint(
                details.localPosition,
                Size(viewportWidth, viewportHeight),
              );
            },
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: naturalWidth,
                    height: naturalHeight,
                    child: CameraPreview(controller),
                  ),
                ),

                if (_selectedFilterIndex != 0) _buildFilterOverlay(),

                if (_showGrid)
                  const IgnorePointer(
                    child: CustomPaint(painter: _GridPainter()),
                  ),

                if (_showFocusBox && _focusPoint != null)
                  Positioned(
                    left: _focusPoint!.dx - 28,
                    top: _focusPoint!.dy - 28,
                    child: IgnorePointer(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOverlay() {
    final filter = _filters[_selectedFilterIndex];

    if (filter.name == 'Mono') {
      return IgnorePointer(
        child: Container(color: Colors.grey.withOpacity(filter.opacity)),
      );
    }

    return IgnorePointer(
      child: Container(color: filter.color.withOpacity(filter.opacity)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    final cameraReady =
        !_isLoading &&
        _errorMessage == null &&
        controller != null &&
        controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                if (cameraReady) _buildCameraPreview(controller, constraints),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                if (_errorMessage != null) _buildError(),

                if (cameraReady)
                  Positioned(
                    top: 8,
                    left: 12,
                    right: 12,
                    child: _buildTopControls(),
                  ),

                if (cameraReady)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: _buildBottomControls(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Exact top layout:
  // X | Flash | Filter | Grid | Switch camera
  Widget _buildTopControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleButton(
          icon: Icons.close,
          onTap: () => Navigator.of(context).pop(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CircleButton(
              icon: _flashIcon(),
              onTap: _toggleFlash,
              selected: _flashMode != FlashMode.off,
            ),
            const SizedBox(width: 7),
            _CircleButton(
              icon: Icons.auto_awesome,
              onTap: _toggleFilters,
              selected: _showFilters,
            ),
            const SizedBox(width: 7),
            _CircleButton(
              icon: Icons.grid_3x3,
              onTap: _toggleGrid,
              selected: _showGrid,
            ),
            const SizedBox(width: 7),
            _CircleButton(
              icon: Icons.flip_camera_ios_outlined,
              onTap: _switchCamera,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: 18, left: 12, right: 12),
            child: _buildFilterStrip(),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomTool(
                label: '${_zoom.toStringAsFixed(1)}×',
                onTap: () => _setZoom(1.0),
              ),
              _BottomTool(label: _aspectLabel, onTap: _changeAspectRatio),
            ],
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: _isVideoMode ? _toggleVideoRecording : _takePhoto,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.redAccent : Colors.white,
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: _isRecording
                ? const Center(
                    child: Icon(Icons.stop, color: Colors.white, size: 30),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _changeMode(false),
              child: _ModeText(label: 'PHOTO', selected: !_isVideoMode),
            ),
            const SizedBox(width: 28),
            GestureDetector(
              onTap: () => _changeMode(true),
              child: _ModeText(label: 'VIDEO', selected: _isVideoMode),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = index == _selectedFilterIndex;

          return GestureDetector(
            onTap: () => _selectFilter(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filter.name == 'Original'
                        ? Colors.black.withOpacity(0.28)
                        : filter.color.withOpacity(0.32),
                    border: Border.all(
                      color: selected ? const Color(0xFFFFD84D) : Colors.white,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: Icon(
                    filter.name == 'Mono'
                        ? Icons.filter_b_and_w
                        : Icons.auto_awesome,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  filter.name,
                  style: TextStyle(
                    color: selected ? const Color(0xFFFFD84D) : Colors.white,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraFilter {
  final String name;
  final Color color;
  final double opacity;

  const _CameraFilter({
    required this.name,
    required this.color,
    required this.opacity,
  });
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFFFD84D)
          : Colors.black.withOpacity(0.32),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: selected ? Colors.black : Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }
}

class _BottomTool extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BottomTool({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ModeText extends StatelessWidget {
  final String label;
  final bool selected;

  const _ModeText({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 160),
      style: TextStyle(
        color: selected ? Colors.white : Colors.white.withOpacity(0.55),
        fontSize: 14,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        letterSpacing: 1.2,
      ),
      child: Text(label),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final verticalOne = size.width / 3;
    final verticalTwo = size.width * 2 / 3;
    final horizontalOne = size.height / 3;
    final horizontalTwo = size.height * 2 / 3;

    canvas.drawLine(
      Offset(verticalOne, 0),
      Offset(verticalOne, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(verticalTwo, 0),
      Offset(verticalTwo, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, horizontalOne),
      Offset(size.width, horizontalOne),
      paint,
    );
    canvas.drawLine(
      Offset(0, horizontalTwo),
      Offset(size.width, horizontalTwo),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
