import 'package:camera/camera.dart';

/// Optimization 5: Camera singleton — keeps CameraController alive between
/// navigations so the camera initializes only once per app session.
class CameraService {
  CameraService._();

  static CameraController? _controller;
  static Future<CameraController>? _initFuture;

  /// Returns an initialized CameraController.
  /// First call initializes the controller; subsequent calls return instantly.
  /// Handles concurrent calls safely by reusing the in-flight Future.
  static Future<CameraController> getController() async {
    // Already initialized — return immediately
    if (_controller != null && _controller!.value.isInitialized) {
      return _controller!;
    }

    // Initialization already in progress — await the same future
    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _initialize();
    try {
      final controller = await _initFuture!;
      return controller;
    } finally {
      _initFuture = null;
    }
  }

  static Future<CameraController> _initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception('No cameras available');

    final backCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    _controller = controller;
    return controller;
  }
}
