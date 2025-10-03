import 'package:flutter/material.dart';
import 'package:godelivery_user/util/color_palette.dart';

class EmojiProfilePicture extends StatelessWidget {
  final String? emoji;
  final String? bgColorHex;
  final double size;
  final double? borderWidth;
  final Color? borderColor;

  const EmojiProfilePicture({
    super.key,
    this.emoji,
    this.bgColorHex,
    this.size = 50,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayEmoji = emoji ?? ColorPalette.defaultEmoji;
    final backgroundColor = bgColorHex != null
        ? ColorPalette.hexToColor(bgColorHex!)
        : ColorPalette.defaultBgColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderWidth != null
            ? Border.all(
                color: borderColor ?? Colors.white,
                width: borderWidth!,
              )
            : null,
      ),
      child: Center(
        child: Text(
          displayEmoji,
          style: TextStyle(
            fontSize: size * 0.5, // Emoji size is 50% of container
          ),
        ),
      ),
    );
  }
}
