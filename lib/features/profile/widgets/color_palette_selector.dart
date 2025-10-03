import 'package:flutter/material.dart';
import 'package:godelivery_user/util/color_palette.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';
import 'package:get/get.dart';

class ColorPaletteSelector extends StatefulWidget {
  final String? selectedColorHex;
  final Function(String colorHex) onColorSelected;

  const ColorPaletteSelector({
    super.key,
    this.selectedColorHex,
    required this.onColorSelected,
  });

  @override
  State<ColorPaletteSelector> createState() => _ColorPaletteSelectorState();
}

class _ColorPaletteSelectorState extends State<ColorPaletteSelector> {
  int? selectedColorGroupIndex;
  Color? selectedColor;

  @override
  void initState() {
    super.initState();
    if (widget.selectedColorHex != null) {
      selectedColor = ColorPalette.hexToColor(widget.selectedColorHex!);
      _findSelectedColorGroup();
    }
  }

  void _findSelectedColorGroup() {
    for (int i = 0; i < ColorPalette.profileColors.length; i++) {
      final shades = ColorPalette.profileColors[i]['shades'] as List<Color>;
      if (shades.contains(selectedColor)) {
        selectedColorGroupIndex = i;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: Text(
            'choose_background_color'.tr,
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Color groups grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: Dimensions.paddingSizeSmall,
              crossAxisSpacing: Dimensions.paddingSizeSmall,
              childAspectRatio: 1,
            ),
            itemCount: ColorPalette.profileColors.length,
            itemBuilder: (context, index) {
              final colorGroup = ColorPalette.profileColors[index];
              final mainColor = (colorGroup['shades'] as List<Color>)[0];
              final isSelected = selectedColorGroupIndex == index;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedColorGroupIndex = index;
                    selectedColor = mainColor;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: mainColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : null,
                ),
              );
            },
          ),
        ),

        // Shades of selected color
        if (selectedColorGroupIndex != null) ...[
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Text(
              'select_shade'.tr,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Row(
              children: (ColorPalette.profileColors[selectedColorGroupIndex!]['shades']
                      as List<Color>)
                  .map((shade) {
                final isSelectedShade = selectedColor == shade;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = shade;
                        });
                        widget.onColorSelected(ColorPalette.colorToHex(shade));
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: shade,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelectedShade
                                ? Theme.of(context).primaryColor
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelectedShade ? 3 : 1,
                          ),
                        ),
                        child: isSelectedShade
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
