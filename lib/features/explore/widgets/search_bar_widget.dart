import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/features/explore/controllers/explore_controller.dart';
import 'package:godelivery_user/features/explore/widgets/search_dropdown_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchBarWidget extends StatefulWidget {
  final ExploreController exploreController;

  const SearchBarWidget({
    super.key,
    required this.exploreController,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _showDropdown = false;
  String _currentQuery = '';

  // Voice search
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.exploreController.searchQuery;
    _focusNode.addListener(_onFocusChange);

    // Initialize speech recognition
    _speech = stt.SpeechToText();
    _initSpeech();

    // Initialize pulse animation for listening indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      _speechAvailable = false;
    }
  }

  void _onFocusChange() {
    setState(() {
      _showDropdown = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentQuery = value;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer with 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.exploreController.searchRestaurants(value, saveToHistory: false);
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _currentQuery = suggestion;
    widget.exploreController.searchRestaurants(suggestion, saveToHistory: true);
    _focusNode.unfocus();
  }

  void _onClearHistory() {
    widget.exploreController.clearSearchHistory();
  }

  Future<void> _toggleVoiceSearch() async {
    if (!_speechAvailable) {
      Get.snackbar(
        'voice_search_unavailable'.tr,
        'speech_recognition_not_available'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (_isListening) {
      // Stop listening
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      // Start listening
      HapticFeedback.mediumImpact();
      setState(() {
        _isListening = true;
        _showDropdown = false; // Hide dropdown while listening
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _currentQuery = result.recognizedWords;
          });

          // If the user has finished speaking (finalResult)
          if (result.finalResult) {
            widget.exploreController.searchRestaurants(
              result.recognizedWords,
              saveToHistory: true,
            );
            setState(() {
              _isListening = false;
            });
            HapticFeedback.lightImpact();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
        children: [
          // Search Icon or Listening Indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
            ),
            child: _isListening
                ? ScaleTransition(
                    scale: _pulseAnimation,
                    child: Icon(
                      Icons.graphic_eq,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  )
                : Icon(
                    Icons.search,
                    color: Theme.of(context).disabledColor,
                    size: 20,
                  ),
          ),

          // Search Input
          Expanded(
            child: Semantics(
              label: 'search_restaurants_label'.tr,
              hint: 'search_restaurants_hint'.tr,
              textField: true,
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
                decoration: InputDecoration(
                  hintText: 'search_restaurants_cuisines'.tr,
                  hintStyle: robotoRegular.copyWith(
                    color: Theme.of(context).disabledColor,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: Dimensions.paddingSizeDefault,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  widget.exploreController.searchRestaurants(value, saveToHistory: true);
                  _focusNode.unfocus();
                },
              ),
            ),
          ),

          // Voice Search Button
          if (_speechAvailable)
            Semantics(
              label: _isListening ? 'stop_voice_search'.tr : 'start_voice_search'.tr,
              hint: 'voice_search_hint'.tr,
              button: true,
              child: IconButton(
                onPressed: _toggleVoiceSearch,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).disabledColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),

          // Clear Button
          GetBuilder<ExploreController>(
            builder: (controller) {
              if (controller.searchQuery.isEmpty) {
                return const SizedBox(width: Dimensions.paddingSizeDefault);
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Semantics(
                    label: 'clear_search'.tr,
                    hint: 'clear_search_hint'.tr,
                    button: true,
                    child: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        controller.clearSearch();
                        _focusNode.unfocus();
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).disabledColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                ],
              );
            },
          ),
            ],
          ),
        ),
        // Search Dropdown
        if (_showDropdown)
          GetBuilder<ExploreController>(
            builder: (controller) {
              return SearchDropdownWidget(
                controller: controller,
                currentQuery: _currentQuery,
                onSuggestionTap: _onSuggestionTap,
                onClearHistory: _onClearHistory,
              );
            },
          ),
      ],
    );
  }
}
