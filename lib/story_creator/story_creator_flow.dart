import 'package:flutter/material.dart';

import 'config/story_creator_config.dart';
import 'screens/story_capture_screen.dart';
import 'services/story_upload_service.dart';

class StoryCreatorFlow extends StatefulWidget {
  const StoryCreatorFlow({
    super.key,
    required this.config,
    this.uploadService,
  });

  final StoryCreatorConfig config;
  final StoryUploadService? uploadService;

  @override
  State<StoryCreatorFlow> createState() => _StoryCreatorFlowState();
}

class _StoryCreatorFlowState extends State<StoryCreatorFlow> {
  late final StoryUploadService _uploadService;
  late final bool _ownsService;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.uploadService == null;
    _uploadService = widget.uploadService ?? StoryUploadService(config: widget.config);
  }

  @override
  void dispose() {
    if (_ownsService) {
      _uploadService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoryCaptureScreen(
      config: widget.config,
      uploadService: _uploadService,
    );
  }
}
