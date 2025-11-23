import 'package:flutter/material.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class CheckoutSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const CheckoutSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    const Color surfaceTint = Color(0xFFF2F4F7);
    final Color borderColor = const Color(0xFFE1E4E8);

    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: padding ?? const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: surfaceTint,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          child,
        ],
      ),
    );
  }
}
