import 'dart:async';

import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/shared/feedback/custom_toast_widget.dart';
import 'package:video_player/video_player.dart';

import '../config/story_creator_config.dart';
import '../models/story_media.dart';
import '../models/story_text_overlay.dart';
import '../models/story_text_style_preset.dart';
import '../services/story_upload_service.dart';
import '../widgets/story_color_palette.dart';
import '../widgets/story_text_overlay_widget.dart';
import '../widgets/story_text_style_palette.dart';
import '../widgets/story_text_toolbar.dart';

class StoryEditorScreen extends StatefulWidget {
  const StoryEditorScreen({
    super.key,
    required this.media,
    required this.config,
    required this.uploadService,
  });

  final StoryMedia media;
  final StoryCreatorConfig config;
  final StoryUploadService uploadService;

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final List<StoryTextOverlay> _overlays = [];
  String? _activeOverlayId;
  bool _isTextEditingMode = false;
  bool _showColorPalette = false;
  bool _isUploading = false;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  VideoPlayerController? _videoController;
  bool _isVideoMuted = true;
  bool _videoReady = false;
  double _sliderValue = 1.0;

  static const double _baseFontSize = 32;

  @override
  void initState() {
    super.initState();
    if (widget.media.type == StoryMediaType.video) {
      _initVideoController();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initVideoController() async {
    final controller = VideoPlayerController.file(widget.media.file);
    _videoController = controller;
    await controller.initialize();
    controller
      ..setLooping(true)
      ..setVolume(_isVideoMuted ? 0 : 1)
      ..play();
    if (!mounted) return;
    setState(() => _videoReady = true);
  }

  StoryTextOverlay? get _activeOverlay {
    if (_activeOverlayId == null) return null;
    try {
      return _overlays.firstWhere((element) => element.id == _activeOverlayId);
    } catch (_) {
      return null;
    }
  }

  void _enterTextMode({StoryTextOverlay? overlay}) {
    StoryTextOverlay target;
    if (overlay != null) {
      target = overlay;
    } else {
      target = _createOverlay();
    }
    setState(() {
      _activeOverlayId = target.id;
      _isTextEditingMode = true;
      _sliderValue = target.scale;
      _textController.text = target.text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    unawaited(Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_textFocusNode);
      }
    }));
  }

  StoryTextOverlay _createOverlay() {
    final overlay = StoryTextOverlay(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: '',
      position: StoryOverlayPosition(x: 0.5, y: 0.5),
      scale: 1,
      backgroundColor: Colors.black54,
      zIndex: _overlays.length,
    );
    setState(() {
      _overlays.add(overlay);
      _overlays.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    });
    return overlay;
  }

  void _updateActiveOverlay(StoryTextOverlay Function(StoryTextOverlay overlay) update) {
    final overlay = _activeOverlay;
    if (overlay == null) return;
    final updated = update(overlay);
    final index = _overlays.indexWhere((element) => element.id == overlay.id);
    if (index == -1) return;
    setState(() {
      _overlays[index] = updated;
    });
  }

  void _handleDrag(StoryTextOverlay overlay, DragUpdateDetails details, BoxConstraints constraints) {
    final dx = details.delta.dx / constraints.maxWidth;
    final dy = details.delta.dy / constraints.maxHeight;
    final newX = (overlay.position.x + dx).clamp(0.05, 0.95);
    final newY = (overlay.position.y + dy).clamp(0.05, 0.95);
    setState(() {
      final index = _overlays.indexWhere((element) => element.id == overlay.id);
      if (index != -1) {
        _overlays[index] = overlay.copyWith(
          position: overlay.position.copyWith(x: newX, y: newY),
        );
      }
      _activeOverlayId = overlay.id;
    });
  }

  void _exitTextMode() {
    final overlay = _activeOverlay;
    if (overlay != null) {
      _updateActiveOverlay((_) => overlay.copyWith(text: _textController.text));
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isTextEditingMode = false;
      _showColorPalette = false;
    });
  }

  Future<void> _shareStory() async {
    setState(() => _isUploading = true);
    try {
      await widget.uploadService.uploadAndCreate(
        media: widget.media,
        overlays: _overlays,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showCustomSnackBar('Failed to upload story: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() => _isVideoMuted = !_isVideoMuted);
    _videoController!.setVolume(_isVideoMuted ? 0 : 1);
  }

  void _applyPreset(StoryTextStylePreset preset) {
    _updateActiveOverlay((overlay) {
      return overlay.copyWith(
        stylePreset: preset.name,
        fontFamily: preset.fontFamily,
        fontWeight: preset.fontWeight,
        backgroundMode: preset.backgroundMode,
        backgroundColor: preset.backgroundColor ?? overlay.backgroundColor,
        textCase: preset.defaultTextCase,
        color: preset.defaultColor,
      );
    });
  }

  void _toggleCase() {
    _updateActiveOverlay((overlay) {
      final next = {
        StoryTextCase.normal: StoryTextCase.uppercase,
        StoryTextCase.uppercase: StoryTextCase.lowercase,
        StoryTextCase.lowercase: StoryTextCase.normal,
      };
      return overlay.copyWith(textCase: next[overlay.textCase]);
    });
  }

  void _toggleBackground() {
    _updateActiveOverlay((overlay) {
      return overlay.copyWith(
        backgroundMode: overlay.backgroundMode == StoryBackgroundMode.none
            ? StoryBackgroundMode.pill
            : StoryBackgroundMode.none,
      );
    });
  }

  void _changeAlignment(StoryTextAlignment alignment) {
    _updateActiveOverlay((overlay) => overlay.copyWith(alignment: alignment));
  }

  void _deleteActiveOverlay() {
    if (_activeOverlay == null) return;
    setState(() {
      _overlays.removeWhere((element) => element.id == _activeOverlayId);
      _activeOverlayId = null;
      _isTextEditingMode = false;
    });
  }

  void _setColor(Color color) {
    _updateActiveOverlay((overlay) => overlay.copyWith(color: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            Positioned.fill(child: _buildOverlays()),
            _buildTopControls(),
            if (_isTextEditingMode) ...[
              _buildLeftSlider(),
              _buildTextControls(),
            ] else
              _buildShareBar(),
            if (_isUploading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (widget.media.type == StoryMediaType.video)
              Positioned(
                top: 80,
                right: 20,
                child: AnimatedOpacity(
                  opacity: _videoController?.value.isPlaying == true ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.media.type == StoryMediaType.image) {
      return Image.file(
        widget.media.file,
        fit: BoxFit.cover,
      );
    }
    if (!_videoReady || _videoController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: _toggleMute,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildOverlays() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _overlays.map((overlay) {
            final alignment = Alignment(
              overlay.position.x * 2 - 1,
              overlay.position.y * 2 - 1,
            );
            final isActive = overlay.id == _activeOverlayId;
            if (isActive && _isTextEditingMode) {
              return Positioned.fill(
                child: Align(
                  alignment: alignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.9,
                    ),
                    child: TextField(
                      controller: _textController,
                      focusNode: _textFocusNode,
                      maxLines: null,
                      textAlign: _textAlignFromOverlay(overlay.alignment),
                      style: TextStyle(
                        color: overlay.color,
                        fontFamily: overlay.fontFamily,
                        fontWeight: overlay.fontWeight,
                        fontSize: _baseFontSize * overlay.scale,
                      ),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(border: InputBorder.none),
                      onChanged: (value) => _updateActiveOverlay(
                        (current) => current.copyWith(text: value),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Positioned.fill(
              child: Align(
                alignment: alignment,
                child: GestureDetector(
                  onTap: () => _enterTextMode(overlay: overlay),
                  onPanUpdate: (details) => _handleDrag(overlay, details, constraints),
                  child: StoryTextOverlayWidget(
                    overlay: overlay,
                    isActive: isActive,
                    baseFontSize: _baseFontSize,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (_isTextEditingMode) {
                _exitTextMode();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          if (_isTextEditingMode)
            TextButton(
              onPressed: _exitTextMode,
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              onPressed: () => _enterTextMode(),
              icon: const Icon(Icons.text_fields, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildShareBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black54],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Add a caption...'.toUpperCase(),
                hintStyle: const TextStyle(color: Colors.white54, letterSpacing: 1.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _shareStory,
                    child: const Text('Share to Your Story'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSlider() {
    final overlay = _activeOverlay;
    if (overlay == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 60,
      bottom: 180,
      left: 8,
      child: RotatedBox(
        quarterTurns: -1,
        child: Slider(
          value: _sliderValue,
          onChanged: (value) {
            setState(() => _sliderValue = value);
            _updateActiveOverlay((current) => current.copyWith(scale: value));
          },
          min: 0.5,
          max: 3,
        ),
      ),
    );
  }

  Widget _buildTextControls() {
    final overlay = _activeOverlay;
    if (overlay == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 16, top: 12),
        decoration: const BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StoryTextStylePalette(
              selectedPreset: overlay.stylePreset,
              onPresetSelected: _applyPreset,
            ),
            const SizedBox(height: 12),
            StoryTextToolbar(
              alignment: overlay.alignment,
              onAlignmentChanged: _changeAlignment,
              onToggleCase: _toggleCase,
              onToggleBackground: _toggleBackground,
              onToggleColorPalette: () => setState(() => _showColorPalette = !_showColorPalette),
              onDelete: _deleteActiveOverlay,
            ),
            if (_showColorPalette)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: StoryColorPalette(
                  selectedColor: overlay.color,
                  onColorSelected: _setColor,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Row(
                children: [
                  _StubButton(label: '@ Mention'),
                  const SizedBox(width: 12),
                  _StubButton(label: 'Location'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextAlign _textAlignFromOverlay(StoryTextAlignment alignment) {
    switch (alignment) {
      case StoryTextAlignment.left:
        return TextAlign.left;
      case StoryTextAlignment.center:
        return TextAlign.center;
      case StoryTextAlignment.right:
        return TextAlign.right;
    }
  }
}

class _StubButton extends StatelessWidget {
  const _StubButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
