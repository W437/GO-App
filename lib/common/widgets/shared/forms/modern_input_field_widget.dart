/// Modern unified input field widget with pill-shaped design
/// Supports text input, simple dropdowns, searchable dropdowns, and phone input
/// Features: validation, country picker, password toggle, modern design

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:godelivery_user/common/widgets/adaptive/forms/code_picker_widget.dart';
import 'package:godelivery_user/common/widgets/shared/images/custom_asset_image_widget.dart';
import 'package:godelivery_user/features/splash/controllers/splash_controller.dart';
import 'package:godelivery_user/helper/ui/responsive_helper.dart';
import 'package:godelivery_user/util/dimensions.dart';
import 'package:godelivery_user/util/styles.dart';

enum ModernInputType { text, dropdown, searchableDropdown }

class ModernInputFieldWidget<T> extends StatefulWidget {
  // Common properties
  final String? labelText;
  final String hintText;
  final bool required;
  final bool enabled;
  final String? Function(String?)? validator;
  final Function()? onTap;

  // Text input properties
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool isPassword;
  final Function(String)? onChanged;
  final Function? onSubmit;
  final int maxLines;
  final TextCapitalization capitalization;
  final bool isAmount;
  final bool isNumber;
  final bool isPhone;
  final String? countryDialCode;
  final Function(CountryCode)? onCountryChanged;

  // Icon properties
  final String? prefixImage;
  final IconData? prefixIcon;
  final Widget? suffixChild;
  final IconData? suffixIcon;
  final String? suffixImage;
  final Function()? suffixOnPressed;

  // Dropdown properties
  final ModernInputType inputFieldType;
  final List<DropdownItem<T>>? dropdownItems;
  final T? selectedValue;
  final Function(T?)? onDropdownChanged;
  final bool searchable;

  const ModernInputFieldWidget({
    super.key,
    this.labelText,
    this.hintText = '',
    this.required = false,
    this.enabled = true,
    this.validator,
    this.onTap,
    // Text input
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.isPassword = false,
    this.onChanged,
    this.onSubmit,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.none,
    this.isAmount = false,
    this.isNumber = false,
    this.isPhone = false,
    this.countryDialCode,
    this.onCountryChanged,
    // Icons
    this.prefixImage,
    this.prefixIcon,
    this.suffixChild,
    this.suffixIcon,
    this.suffixImage,
    this.suffixOnPressed,
    // Dropdown
    this.inputFieldType = ModernInputType.text,
    this.dropdownItems,
    this.selectedValue,
    this.onDropdownChanged,
    this.searchable = false,
  });

  @override
  State<ModernInputFieldWidget<T>> createState() => _ModernInputFieldWidgetState<T>();
}

class _ModernInputFieldWidgetState<T> extends State<ModernInputFieldWidget<T>> with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_handleFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label above field
        if (widget.labelText != null) ...[
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: widget.labelText,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (widget.required)
                  TextSpan(
                    text: ' *',
                    style: robotoRegular.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ],

        // Input field based on type
        _buildInputField(context),
      ],
    );
  }

  Widget _buildInputField(BuildContext context) {
    switch (widget.inputFieldType) {
      case ModernInputType.dropdown:
        return _buildDropdownField(context);
      case ModernInputType.searchableDropdown:
        return _buildSearchableDropdownField(context);
      case ModernInputType.text:
      default:
        return _buildTextField(context);
    }
  }

  Widget _buildTextField(BuildContext context) {
    return TextFormField(
      maxLines: widget.maxLines,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
      textInputAction: widget.inputAction,
      keyboardType: widget.isAmount ? TextInputType.number : widget.inputType,
      cursorColor: Theme.of(context).primaryColor,
      textCapitalization: widget.capitalization,
      enabled: widget.enabled,
      autofocus: false,
      obscureText: widget.isPassword ? _obscureText : false,
      inputFormatters: _getInputFormatters(),
      decoration: _buildInputDecoration(context),
      onFieldSubmitted: (text) => widget.nextFocus != null
          ? FocusScope.of(context).requestFocus(widget.nextFocus)
          : widget.onSubmit != null
              ? widget.onSubmit!(text)
              : null,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    final selectedItem = widget.dropdownItems?.firstWhereOrNull(
      (item) => item.value == widget.selectedValue,
    );

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: widget.enabled ? () => _showDropdownOverlay(context) : null,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? Theme.of(context).cardColor
                : Theme.of(context).disabledColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            border: Border.all(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null || widget.prefixImage != null) ...[
                _buildPrefixIcon(context) ?? const SizedBox.shrink(),
                const SizedBox(width: Dimensions.paddingSizeSmall),
              ],
              Expanded(
                child: Text(
                  selectedItem?.label ?? widget.hintText,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: selectedItem != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).hintColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).hintColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableDropdownField(BuildContext context) {
    final selectedItem = widget.dropdownItems?.firstWhereOrNull(
      (item) => item.value == widget.selectedValue,
    );

    return InkWell(
      onTap: widget.enabled ? () => _showSearchableDropdown(context) : null,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeDefault,
        ),
        decoration: BoxDecoration(
          color: widget.enabled
              ? Theme.of(context).cardColor
              : Theme.of(context).disabledColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null || widget.prefixImage != null) ...[
              _buildPrefixIcon(context) ?? const SizedBox.shrink(),
              const SizedBox(width: Dimensions.paddingSizeSmall),
            ],
            Expanded(
              child: Text(
                selectedItem?.label ?? widget.hintText,
                style: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: selectedItem != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Theme.of(context).hintColor.withValues(alpha: 0.7),
                ),
              ),
            ),
            Icon(
              Icons.search,
              color: Theme.of(context).hintColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.inputType == TextInputType.phone) {
      return [FilteringTextInputFormatter.allow(RegExp('[0-9]'))];
    } else if (widget.isAmount) {
      return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
    } else if (widget.isNumber) {
      return [FilteringTextInputFormatter.allow(RegExp(r'\d'))];
    }
    return null;
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      errorMaxLines: 2,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        borderSide: BorderSide(
          width: 2,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        borderSide: BorderSide(
          width: 2,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.6),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        borderSide: BorderSide(
          width: 2,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        borderSide: BorderSide(
          width: 2,
          color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
        ),
      ),
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeDefault,
      ),
      hintText: widget.hintText,
      fillColor: !widget.enabled
          ? Theme.of(context).disabledColor.withValues(alpha: 0.1)
          : Theme.of(context).cardColor,
      hintStyle: robotoRegular.copyWith(
        fontSize: Dimensions.fontSizeLarge,
        color: Theme.of(context).hintColor.withValues(alpha: 0.7),
      ),
      filled: true,
      errorStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
      prefixIcon: _buildPrefixIcon(context),
      suffixIcon: _buildSuffixIcon(context),
    );
  }

  Widget? _buildPrefixIcon(BuildContext context) {
    if (widget.isPhone || widget.countryDialCode != null) {
      return SizedBox(
        width: 95,
        child: Row(
          children: [
            Container(
              width: 85,
              height: 45,
              margin: const EdgeInsets.only(right: 0),
              padding: const EdgeInsets.only(left: 5),
              child: Center(
                child: CodePickerWidget(
                  flagWidth: 25,
                  padding: EdgeInsets.zero,
                  onChanged: widget.onCountryChanged,
                  initialSelection: widget.countryDialCode,
                  favorite: [widget.countryDialCode ?? ''],
                  countryFilter: const ['IL'],
                  enabled: Get.find<SplashController>().configModel?.countryPickerStatus,
                  dialogBackgroundColor: Theme.of(context).cardColor,
                  textStyle: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
            ),
            Container(
              height: 20,
              width: 2,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      );
    } else if (widget.prefixImage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
        ),
        child: CustomAssetImageWidget(
          widget.prefixImage!,
          height: 25,
          width: 25,
          fit: BoxFit.scaleDown,
          color: widget.focusNode?.hasFocus == true
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Theme.of(context).hintColor.withValues(alpha: 0.7),
        ),
      );
    } else if (widget.prefixIcon != null) {
      return Icon(
        widget.prefixIcon,
        size: 18,
        color: widget.focusNode?.hasFocus == true
            ? Theme.of(context).textTheme.bodyLarge?.color
            : Theme.of(context).hintColor.withValues(alpha: 0.7),
      );
    }
    return null;
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).hintColor.withValues(alpha: 0.3),
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      );
    } else if (widget.suffixImage != null) {
      return InkWell(
        onTap: widget.suffixOnPressed,
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveHelper.isDesktop(context)
                ? Dimensions.paddingSizeSmall
                : Dimensions.paddingSizeDefault,
          ),
          child: Image.asset(
            widget.suffixImage!,
            height: 10,
            width: 10,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (widget.suffixChild != null) {
      return widget.suffixChild;
    } else if (widget.suffixIcon != null) {
      return Icon(
        widget.suffixIcon,
        color: Theme.of(context).hintColor.withValues(alpha: 0.7),
      );
    }
    return null;
  }

  void _showDropdownOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    _animationController.reset();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Transparent background
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Dropdown menu
            Positioned(
              width: _getDropdownWidth(),
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, _getDropdownOffset()),
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.topCenter,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: widget.dropdownItems?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = widget.dropdownItems![index];
                        final isSelected = item.value == widget.selectedValue;

                        return InkWell(
                          onTap: () {
                            widget.onDropdownChanged?.call(item.value);
                            _removeOverlay();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeSmall,
                            ),
                            color: isSelected
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                : null,
                            child: Row(
                              children: [
                                if (item.icon != null) ...[
                                  item.icon!,
                                  const SizedBox(width: Dimensions.paddingSizeSmall),
                                ],
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: robotoRegular.copyWith(
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _showSearchableDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchableDropdownSheet<T>(
        items: widget.dropdownItems ?? [],
        selectedValue: widget.selectedValue,
        onChanged: (value) {
          widget.onDropdownChanged?.call(value);
        },
        hintText: widget.hintText,
      ),
    );
  }

  double _getDropdownWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 200;
  }

  double _getDropdownOffset() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return (renderBox?.size.height ?? 50) - 20;
  }
}

class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? icon;

  DropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

class SearchableDropdownSheet<T> extends StatefulWidget {
  final List<DropdownItem<T>> items;
  final T? selectedValue;
  final Function(T?) onChanged;
  final String hintText;

  const SearchableDropdownSheet({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.hintText,
  });

  @override
  State<SearchableDropdownSheet<T>> createState() => _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T> extends State<SearchableDropdownSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.label.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusLarge),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.6),
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),

          // List
          Flexible(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: Text(
                        'no_data_found'.tr,
                        style: robotoRegular.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item.value == widget.selectedValue;

                      return InkWell(
                        onTap: () {
                          widget.onChanged(item.value);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeSmall,
                          ),
                          color: isSelected
                              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                              : null,
                          child: Row(
                            children: [
                              if (item.icon != null) ...[
                                item.icon!,
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                              ],
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: robotoRegular.copyWith(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
