import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:godelivery_user/features/language/controllers/localization_controller.dart';
import 'package:godelivery_user/features/language/domain/models/language_model.dart';
import 'package:godelivery_user/util/app_constants.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class LanguageCardWidget extends StatefulWidget {
  final LanguageModel languageModel;
  final LocalizationController localizationController;
  final int index;
  final bool fromBottomSheet;
  final bool fromWeb;

  const LanguageCardWidget({
    super.key,
    required this.languageModel,
    required this.localizationController,
    required this.index,
    this.fromBottomSheet = false,
    this.fromWeb = false,
  });

  @override
  State<LanguageCardWidget> createState() => _LanguageCardWidgetState();
}

class _LanguageCardWidgetState extends State<LanguageCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut, reverseCurve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool get _isSelected => widget.localizationController.selectedLanguageIndex == widget.index;

  void _handleTap() {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Update language
    widget.localizationController.setSelectLanguageIndex(widget.index);
    widget.localizationController.setLanguage(
      Locale(
        AppConstants.languages[widget.index].languageCode!,
        AppConstants.languages[widget.index].countryCode,
      ),
      fromBottomSheet: widget.fromBottomSheet,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: _isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
              : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor.withValues(alpha: 0.3),
              width: _isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isSelected ? 6 : 4,
                offset: Offset(0, _isSelected ? 3 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Flag icon
              Image.asset(
                widget.languageModel.imageUrl!,
                width: 40,
                height: 40,
              ),

              const SizedBox(width: Dimensions.paddingSizeDefault),

              // Language name
              Expanded(
                child: Text(
                  widget.languageModel.languageName!,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    fontFamily: AppConstants.getFontFamily(widget.languageModel.languageCode ?? 'en'),
                    color: _isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Animated checkmark
              AnimatedOpacity(
                opacity: _isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
