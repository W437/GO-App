import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../config/story_creator_config.dart';
import '../models/story_media.dart';
import '../screens/story_editor_screen.dart';
import '../services/story_upload_service.dart';

class StoryCaptureScreen extends StatefulWidget {
  const StoryCaptureScreen({
    super.key,
    required this.config,
    required this.uploadService,
  });

  final StoryCreatorConfig config;
  final StoryUploadService uploadService;

  @override
  State<StoryCaptureScreen> createState() => _StoryCaptureScreenState();
}

class _StoryCaptureScreenState extends State<StoryCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _currentDescription;
  bool _isRecording = false;
  bool _initializingCamera = true;
  XFile? _lastMedia;
  Timer? _maxVideoTimer;
  DateTime? _recordingStart;
  final _picker = ImagePicker();
  static const _maxVideoDuration = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _maxVideoTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || _currentDescription == null) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed && _cameras.isNotEmpty) {
      _initController(_currentDescription!);
    }
  }

  Future<void> _setupCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!cameraStatus.isGranted) {
      setState(() => _initializingCamera = false);
      return;
    }

    if (!micStatus.isGranted) {
      // We can still allow photo capture if the mic was denied.
      debugPrint('Microphone permission denied - videos will be muted.');
    }

    try {
      final cameras = await availableCameras();
      _cameras = cameras;
      await _initController(cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      ));
    } on CameraException {
      setState(() => _initializingCamera = false);
    }
  }

  Future<void> _initController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.max,
      enableAudio: true,
    );
    _controller = controller;
    try {
      await controller.initialize();
      _currentDescription = description;
      if (!mounted) return;
      setState(() => _initializingCamera = false);
    } on CameraException {
      setState(() => _initializingCamera = false);
    }
  }

  Future<void> _toggleCamera({int? index}) async {
    if (_cameras.isEmpty) return;
    final current = _controller?.description;
    CameraDescription next;
    if (index != null && index < _cameras.length) {
      next = _cameras[index];
    } else {
      next = _cameras.firstWhere(
        (c) => c.lensDirection != current?.lensDirection,
        orElse: () => _cameras.first,
      );
    }
    await _controller?.dispose();
    setState(() => _initializingCamera = true);
    await _initController(next);
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return;
    }
    try {
      final file = await _controller!.takePicture();
      _lastMedia = file;
      if (!mounted) return;
      await _goToEditor(StoryMedia(file: File(file.path), type: StoryMediaType.image));
    } on CameraException {
      // TODO: add proper error handling/logging as needed.
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return;
    }
    try {
      await _controller!.prepareForVideoRecording();
    } catch (_) {}
    try {
      await _controller!.startVideoRecording();
      _recordingStart = DateTime.now();
      setState(() => _isRecording = true);
      _maxVideoTimer = Timer(_maxVideoDuration, _stopVideoRecording);
    } on CameraException {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording || _controller == null) {
      return;
    }
    _maxVideoTimer?.cancel();
    try {
      final file = await _controller!.stopVideoRecording();
      final duration = DateTime.now().difference(_recordingStart ?? DateTime.now());
      _lastMedia = file;
      if (!mounted) return;
      await _goToEditor(
        StoryMedia(
          file: File(file.path),
          type: StoryMediaType.video,
          duration: duration > _maxVideoDuration ? _maxVideoDuration : duration,
        ),
      );
    } on CameraException {
      setState(() => _isRecording = false);
    } finally {
      if (mounted) {
        setState(() => _isRecording = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final file = await _picker.pickMedia();
    if (file == null) return;
    File mediaFile = File(file.path);
    if (file.mimeType?.contains('video') ?? false) {
      final duration = await _loadVideoDuration(mediaFile);
      await _goToEditor(
        StoryMedia(
          file: mediaFile,
          type: StoryMediaType.video,
          duration: duration,
        ),
      );
    } else {
      await _goToEditor(
        StoryMedia(
          file: mediaFile,
          type: StoryMediaType.image,
        ),
      );
    }
    _lastMedia = file;
  }

  Future<Duration?> _loadVideoDuration(File file) async {
    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (_) {
      return null;
    }
  }

  Future<void> _goToEditor(StoryMedia media) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StoryEditorScreen(
          media: media,
          config: widget.config,
          uploadService: widget.uploadService,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _initializingCamera
        ? const Center(child: CircularProgressIndicator())
        : (_controller == null
            ? _MissingCamera(message: 'Camera unavailable')
            : CameraPreview(_controller!));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: preview),
            _buildTopBar(context),
            _buildBottomControls(),
            _buildModeSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).maybePop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
                image: _lastMedia == null
                    ? null
                    : DecorationImage(
                        image: FileImage(File(_lastMedia!.path)),
                        fit: BoxFit.cover,
                      ),
              ),
              child: _lastMedia == null
                  ? const Icon(Icons.photo, color: Colors.white70)
                  : null,
            ),
          ),
          GestureDetector(
            onTap: _takePhoto,
            onLongPress: _startVideoRecording,
            onLongPressUp: _stopVideoRecording,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? Colors.red : Colors.white,
                  width: 4,
                ),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleCamera,
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'STORY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingCamera extends StatelessWidget {
  const _MissingCamera({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.white54),
      ),
    );
  }
}
