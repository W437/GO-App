import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/custom_button_widget.dart';
import 'package:godelivery_user/common/widgets/emoji_profile_picture.dart';
import 'package:godelivery_user/features/profile/widgets/color_palette_selector.dart';
import 'package:godelivery_user/util/color_palette.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

class EmojiProfileEditor extends StatefulWidget {
  final String? currentEmoji;
  final String? currentBgColor;
  final Function(String emoji, String bgColor) onSave;

  const EmojiProfileEditor({
    super.key,
    this.currentEmoji,
    this.currentBgColor,
    required this.onSave,
  });

  @override
  State<EmojiProfileEditor> createState() => _EmojiProfileEditorState();
}

class _EmojiProfileEditorState extends State<EmojiProfileEditor> {
  late String selectedEmoji;
  late String selectedBgColor;

  @override
  void initState() {
    super.initState();
    selectedEmoji = widget.currentEmoji ?? ColorPalette.defaultEmoji;
    selectedBgColor = widget.currentBgColor ?? ColorPalette.colorToHex(ColorPalette.defaultBgColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusExtraLarge),
          topRight: Radius.circular(Dimensions.radiusExtraLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'customize_avatar'.tr,
                    style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Preview
            EmojiProfilePicture(
              emoji: selectedEmoji,
              bgColorHex: selectedBgColor,
              size: 100,
              borderWidth: 3,
              borderColor: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Color Palette Selector
            ColorPaletteSelector(
              selectedColorHex: selectedBgColor,
              onColorSelected: (colorHex) {
                setState(() {
                  selectedBgColor = colorHex;
                });
              },
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            // Emoji Picker Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
              child: Text(
                'choose_emoji'.tr,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Emoji Picker
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    selectedEmoji = emoji.emoji;
                  });
                },
                config: Config(
                  height: 250,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28,
                    columns: 8,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  skinToneConfig: const SkinToneConfig(
                    enabled: true,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: Theme.of(context).cardColor,
                    iconColorSelected: Theme.of(context).primaryColor,
                  ),
                  bottomActionBarConfig: BottomActionBarConfig(
                    backgroundColor: Theme.of(context).cardColor,
                    buttonIconColor: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: CustomButtonWidget(
                buttonText: 'save'.tr,
                onPressed: () {
                  widget.onSave(selectedEmoji, selectedBgColor);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
