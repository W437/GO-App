---
name: widget-builder
description: Create Flutter widgets following GO App conventions including naming patterns, responsive design, theme integration, and proper file organization. Use when building UI components or refactoring widgets.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Widget Builder Expert

Creates Flutter widgets following GO App's established patterns including naming conventions, responsive design, theme integration, and proper component structure.

## Instructions

### 1. Widget File Naming Convention

**Location:**
- Feature-specific: `lib/features/[feature]/widgets/[widget_name]_widget.dart`
- Shared: `lib/common/widgets/[category]/[widget_name]_widget.dart`

**Naming Pattern:**
- All widget files end with `_widget.dart`
- Use descriptive snake_case names
- Class name in PascalCase

**Examples:**
```
banner_view_widget.dart → BannerViewWidget
popular_restaurants_view_widget.dart → PopularRestaurantsViewWidget
category_pop_up_widget.dart → CategoryPopUpWidget
custom_button_widget.dart → CustomButtonWidget
```

### 2. Widget Structure Template

**Stateless Widget (Preferred):**
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:efood_multivendor/util/dimensions.dart';
import 'package:efood_multivendor/util/styles.dart';

class [Name]Widget extends StatelessWidget {
  final String? title;
  final VoidCallback? onTap;

  const [Name]Widget({
    Key? key,
    this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Text(
        title ?? '',
        style: robotoMedium.copyWith(
          fontSize: Dimensions.fontSizeDefault,
        ),
      ),
    );
  }
}
```

**Stateful Widget (When needed):**
```dart
class [Name]Widget extends StatefulWidget {
  final String? data;

  const [Name]Widget({Key? key, this.data}) : super(key: key);

  @override
  State<[Name]Widget> createState() => _[Name]WidgetState();
}

class _[Name]WidgetState extends State<[Name]Widget> {
  @override
  void initState() {
    super.initState();
    // Initialize state
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(widget.data ?? ''),
    );
  }
}
```

### 3. Responsive Design Integration

**Import ResponsiveHelper:**
```dart
import 'package:efood_multivendor/helper/responsive_helper.dart';
```

**Platform Detection:**
```dart
@override
Widget build(BuildContext context) {
  return ResponsiveHelper.isMobilePhone()
    ? _buildMobileLayout()
    : ResponsiveHelper.isTab(context)
      ? _buildTabletLayout()
      : _buildDesktopLayout();
}
```

**Common Patterns:**
```dart
// Check if mobile
if (ResponsiveHelper.isMobilePhone()) {
  // Mobile-specific UI
}

// Check if web
if (ResponsiveHelper.isWeb()) {
  // Web-specific UI
}

// Check if desktop (width > 1300px)
if (ResponsiveHelper.isDesktop(context)) {
  // Desktop layout
}

// Check if tablet (650px - 1300px)
if (ResponsiveHelper.isTab(context)) {
  // Tablet layout
}
```

**Adaptive Sizing:**
```dart
Container(
  width: ResponsiveHelper.isMobilePhone()
    ? double.infinity
    : Dimensions.webMaxWidth,
  padding: EdgeInsets.all(
    ResponsiveHelper.isDesktop(context)
      ? Dimensions.paddingSizeLarge
      : Dimensions.paddingSizeDefault,
  ),
)
```

### 4. Using Dimensions Class

**Import:**
```dart
import 'package:efood_multivendor/util/dimensions.dart';
```

**Font Sizes:**
```dart
fontSize: Dimensions.fontSizeExtraSmall  // 10px
fontSize: Dimensions.fontSizeSmall       // 12px
fontSize: Dimensions.fontSizeDefault     // 14px
fontSize: Dimensions.fontSizeLarge       // 16px
fontSize: Dimensions.fontSizeExtraLarge  // 18px
fontSize: Dimensions.fontSizeOverLarge   // 24px
```

**Padding/Margin:**
```dart
padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall)  // 5px
padding: EdgeInsets.all(Dimensions.paddingSizeSmall)       // 10px
padding: EdgeInsets.all(Dimensions.paddingSizeDefault)     // 15px
padding: EdgeInsets.all(Dimensions.paddingSizeLarge)       // 20px
padding: EdgeInsets.all(Dimensions.paddingSizeExtraLarge)  // 25px
```

**Border Radius:**
```dart
borderRadius: BorderRadius.circular(Dimensions.radiusSmall)    // 5px
borderRadius: BorderRadius.circular(Dimensions.radiusDefault)  // 10px
borderRadius: BorderRadius.circular(Dimensions.radiusLarge)    // 15px
borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge) // 20px
```

**Spacing:**
```dart
SizedBox(height: Dimensions.paddingSizeSmall)
SizedBox(width: Dimensions.paddingSizeDefault)
```

### 5. Theme Integration

**Import Styles:**
```dart
import 'package:efood_multivendor/util/styles.dart';
```

**Text Styles:**
```dart
// Regular (400 weight)
Text('Hello', style: robotoRegular)

// Medium (500 weight)
Text('Hello', style: robotoMedium)

// Bold (700 weight)
Text('Hello', style: robotoBold)

// Black (900 weight)
Text('Hello', style: robotoBlack)
```

**Customizing Styles:**
```dart
Text(
  'Custom Text',
  style: robotoMedium.copyWith(
    fontSize: Dimensions.fontSizeLarge,
    color: Theme.of(context).primaryColor,
  ),
)
```

**Theme Colors:**
```dart
// Primary color
color: Theme.of(context).primaryColor

// Background
color: Theme.of(context).cardColor

// Text colors
color: Theme.of(context).textTheme.bodyLarge?.color

// Disabled
color: Theme.of(context).disabledColor

// Error
color: Theme.of(context).colorScheme.error

// Hint text
color: Theme.of(context).hintColor
```

### 6. Common Widget Patterns

**List Item Widget:**
```dart
class [Name]ItemWidget extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;

  const [Name]ItemWidget({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(
          children: [
            // Item content
          ],
        ),
      ),
    );
  }
}
```

**Card Widget:**
```dart
class [Name]CardWidget extends StatelessWidget {
  final Widget child;

  const [Name]CardWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: child,
    );
  }
}
```

**Shimmer Loading Widget:**
```dart
import 'package:shimmer_animation/shimmer_animation.dart';

class [Name]ShimmerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer(
      duration: Duration(seconds: 2),
      enabled: true,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
      ),
    );
  }
}
```

### 7. GetX Integration in Widgets

**Using GetBuilder:**
```dart
import 'package:get/get.dart';

class [Name]Widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<[Feature]Controller>(
      builder: ([feature]Controller) {
        return [feature]Controller.isLoading
          ? [Name]ShimmerWidget()
          : ListView.builder(
              itemCount: [feature]Controller.dataList?.length ?? 0,
              itemBuilder: (context, index) {
                return [Name]ItemWidget(
                  item: [feature]Controller.dataList![index],
                );
              },
            );
      },
    );
  }
}
```

**Accessing Controller:**
```dart
final controller = Get.find<[Feature]Controller>();

ElevatedButton(
  onPressed: () => controller.performAction(),
  child: Text('Action'),
)
```

### 8. Image Handling

**Cached Network Image:**
```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:efood_multivendor/common/widgets/custom_image_widget.dart';

CustomImageWidget(
  image: '${AppConstants.baseUrl}/storage/app/public/$imagePath',
  height: 80,
  width: 80,
  fit: BoxFit.cover,
)
```

**Placeholder & Error:**
```dart
CustomImageWidget(
  image: imageUrl,
  placeholder: Images.placeholder,  // From util/images.dart
  fit: BoxFit.cover,
)
```

### 9. Common Shared Widgets to Use

**Instead of building from scratch, use existing widgets:**

**Buttons:**
```dart
import 'package:efood_multivendor/common/widgets/custom_button_widget.dart';

CustomButtonWidget(
  buttonText: 'Submit',
  onPressed: () {},
)
```

**Text Fields:**
```dart
import 'package:efood_multivendor/common/widgets/modern_input_field_widget.dart';

ModernInputFieldWidget(
  hintText: 'Enter name',
  controller: _controller,
)
```

**App Bar:**
```dart
import 'package:efood_multivendor/common/widgets/custom_app_bar_widget.dart';

CustomAppBarWidget(
  title: 'Page Title',
  onBackPressed: () => Get.back(),
)
```

**Loading Indicator:**
```dart
import 'package:efood_multivendor/common/widgets/custom_loader_widget.dart';

CustomLoaderWidget()
```

### 10. Widget Organization

**Feature-Specific Widgets:**
```
lib/features/restaurant/widgets/
├── restaurant_card_widget.dart
├── restaurant_info_widget.dart
└── restaurant_shimmer_widget.dart
```

**Shared Widgets:**
```
lib/common/widgets/
├── buttons/
│   └── custom_button_widget.dart
├── forms/
│   └── modern_input_field_widget.dart
├── images/
│   └── custom_image_widget.dart
└── layout/
    └── custom_app_bar_widget.dart
```

## Best Practices

1. **Always use const constructors when possible**
   - Improves performance
   - `const [Name]Widget({Key? key}) : super(key: key);`

2. **Use Dimensions class for all sizing**
   - Never hardcode pixel values
   - Ensures consistency and responsiveness

3. **Apply theme colors from context**
   - Don't hardcode colors
   - Use `Theme.of(context).primaryColor`

4. **Name widgets descriptively**
   - `RestaurantCardWidget` not `CardWidget`
   - `BannerViewWidget` not `BannerWidget`

5. **Keep widgets focused and small**
   - Extract complex parts into separate widgets
   - Single responsibility principle

6. **Use existing shared widgets**
   - Check `lib/common/widgets/` before creating new
   - Promotes consistency

7. **Add proper key parameter**
   - Always include `Key? key` parameter
   - Pass to super constructor

8. **Make widgets reusable**
   - Accept data through parameters
   - Use callbacks for actions

## Common Widget Categories

### View Widgets
Display data in scrollable views:
- `banner_view_widget.dart`
- `popular_restaurants_view_widget.dart`
- `categories_view_widget.dart`

### Item Widgets
Individual list items:
- `restaurant_item_widget.dart`
- `product_item_widget.dart`
- `order_item_widget.dart`

### Card Widgets
Standalone cards:
- `restaurant_card_widget.dart`
- `offer_card_widget.dart`

### Shimmer Widgets
Loading states:
- `restaurant_shimmer_widget.dart`
- `product_shimmer_widget.dart`

### Pop-up Widgets
Dialogs and bottom sheets:
- `category_pop_up_widget.dart`
- `filter_pop_up_widget.dart`

## Examples

**Create a restaurant card:**
```dart
// lib/features/restaurant/widgets/restaurant_card_widget.dart

class RestaurantCardWidget extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCardWidget({
    Key? key,
    required this.restaurant,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        child: Row(
          children: [
            CustomImageWidget(
              image: restaurant.logo,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
            SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name ?? '',
                    style: robotoMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(
                    restaurant.address ?? '',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).disabledColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Create a responsive banner:**
```dart
class BannerWidget extends StatelessWidget {
  final String imageUrl;

  const BannerWidget({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ResponsiveHelper.isMobilePhone()
        ? double.infinity
        : Dimensions.webMaxWidth,
      height: ResponsiveHelper.isDesktop(context) ? 200 : 150,
      child: CustomImageWidget(
        image: imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}
```

## Validation Checklist

Before committing widget code:
- [ ] File named with `_widget.dart` suffix
- [ ] Uses Dimensions class for sizing
- [ ] Uses theme colors (no hardcoded colors)
- [ ] Applies text styles (robotoRegular, robotoMedium, etc.)
- [ ] Includes responsive design if needed
- [ ] Has const constructor when possible
- [ ] Includes Key? key parameter
- [ ] Reuses existing shared widgets
- [ ] Follows naming conventions
- [ ] Properly organized in features/ or common/
