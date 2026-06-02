// Camera Service - Provide a shared CameraController singleton to avoid repeated initialization

import 'package:camera/camera.dart';

class CameraService {
  CameraService._();

  static CameraController? _controller;
  static Future<CameraController>? _initFuture;

  // Return an initialized CameraController, reusing the existing instance if already ready.
  // Concurrent calls are handled safely by sharing the in-flight initialization future.
  static Future<CameraController> getController() async {
    if (_controller != null && _controller!.value.isInitialized) {
      return _controller!;
    }

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

  // Initialize the back-facing camera at medium resolution
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