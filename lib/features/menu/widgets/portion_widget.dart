
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';

class PortionWidget extends StatefulWidget {
  final String? icon;
  final IconData? iconData;
  final String title;
  final bool hideDivider;
  final String route;
  final String? suffix;
  final Function()? onTap;
  final String? tooltip;
  const PortionWidget({super.key, this.icon, this.iconData, required this.title, required this.route, this.hideDivider = false, this.suffix, this.onTap, this.tooltip});

  @override
  State<PortionWidget> createState() => _PortionWidgetState();
}

class _PortionWidgetState extends State<PortionWidget> {
  final tooltipController = JustTheController();

  @override
  void dispose() {
    tooltipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = InkWell(
      onTap: widget.onTap ?? () => Get.toNamed(widget.route),
      onLongPress: widget.tooltip != null ? () {
        tooltipController.showTooltip();
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
        child: Column(children: [
          Row(children: [
            widget.iconData != null
              ? Icon(widget.iconData, size: 16, color: Theme.of(context).textTheme.bodyMedium!.color)
              : Image.asset(widget.icon!, height: 16, width: 16, color: Theme.of(context).textTheme.bodyMedium!.color),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(child: Text(widget.title, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault))),

            widget.suffix != null ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall, horizontal: Dimensions.paddingSizeSmall),
              child: Text(widget.suffix!, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)),
            ) : const SizedBox(),
          ]),
          widget.hideDivider ? const SizedBox() : const Divider()
        ]),
      ),
    );

    if (widget.tooltip != null) {
      return JustTheTooltip(
        controller: tooltipController,
        preferredDirection: AxisDirection.up,
        tailLength: 10,
        tailBaseWidth: 15,
        backgroundColor: Theme.of(context).primaryColor,
        offset: 0,
        margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        content: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Text(
            widget.tooltip!,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white),
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
