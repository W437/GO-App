import 'package:flutter/material.dart';
import 'package:godelivery_user/common/widgets/rounded_icon_button_widget.dart';
import 'package:godelivery_user/util/dimensions.dart';

/// Reusable draggable bottom sheet with handle and close button
/// Similar to modern bottom sheet designs with drag indicator and X button
class DraggableBottomSheetWidget extends StatefulWidget {
  final Widget child;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  const DraggableBottomSheetWidget({
    super.key,
    required this.child,
    this.initialChildSize = 0.9,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.95,
  });

  @override
  State<DraggableBottomSheetWidget> createState() => _DraggableBottomSheetWidgetState();
}

class _DraggableBottomSheetWidgetState extends State<DraggableBottomSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize,
      minChildSize: widget.minChildSize,
      maxChildSize: widget.maxChildSize,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Top section with handle and close button
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeDefault,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Drag handle centered
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Close button on the right
                  Align(
                    alignment: Alignment.centerRight,
                    child: RoundedIconButtonWidget(
                      icon: Icons.close,
                      onPressed: () => Navigator.of(context).pop(),
                      backgroundColor: Theme.of(context).hintColor.withValues(alpha: 0.1),
                      pressedColor: Theme.of(context).hintColor.withValues(alpha: 0.25),
                      iconColor: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show the draggable bottom sheet
void showDraggableBottomSheet({
  required BuildContext context,
  required Widget child,
  double? initialChildSize,
  double minChildSize = 0.3,
  double maxChildSize = 0.95,
  bool wrapContent = false,
}) {
  if (wrapContent) {
    // Use a dynamic sheet that wraps content
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WrapContentBottomSheet(
        maxChildSize: maxChildSize,
        child: child,
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableBottomSheetWidget(
        initialChildSize: initialChildSize ?? 0.9,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        child: child,
      ),
    );
  }
}

class _WrapContentBottomSheet extends StatefulWidget {
  final double maxChildSize;
  final Widget child;

  const _WrapContentBottomSheet({
    required this.maxChildSize,
    required this.child,
  });

  @override
  State<_WrapContentBottomSheet> createState() => _WrapContentBottomSheetState();
}

class _WrapContentBottomSheetState extends State<_WrapContentBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * widget.maxChildSize,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top section with handle and close button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Drag handle centered
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Close button on the right
                Align(
                  alignment: Alignment.centerRight,
                  child: RoundedIconButtonWidget(
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
