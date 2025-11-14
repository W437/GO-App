import 'package:flutter/material.dart';
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radiusExtraLarge),
            topRight: Radius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
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

/// Helper function to show the draggable bottom sheet with smooth bounce animation
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
      builder: (context) => _BounceWrapper(
        child: _WrapContentBottomSheet(
          maxChildSize: maxChildSize,
          child: child,
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BounceWrapper(
        child: DraggableBottomSheetWidget(
          initialChildSize: initialChildSize ?? 0.9,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          child: child,
        ),
      ),
    );
  }
}

/// Wrapper widget that adds bounce animation to bottom sheet
class _BounceWrapper extends StatefulWidget {
  final Widget child;

  const _BounceWrapper({required this.child});

  @override
  State<_BounceWrapper> createState() => _BounceWrapperState();
}

class _BounceWrapperState extends State<_BounceWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_animation),
      child: widget.child,
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
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
