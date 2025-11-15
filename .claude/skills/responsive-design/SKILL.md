---
name: responsive-design
description: Create responsive layouts for mobile, tablet, web, and desktop platforms using ResponsiveHelper, Dimensions class, and adaptive widgets. Use when building UI that needs to work across different screen sizes.
allowed-tools: Read, Edit, Write, Grep
---

# Responsive Design Expert

Implements responsive and adaptive designs for GO App across mobile, tablet, web, and desktop platforms using established patterns and utilities.

## Instructions

### 1. Platform Detection with ResponsiveHelper

**Import:**
```dart
import 'package:efood_multivendor/helper/responsive_helper.dart';
```

**Detection Methods:**
```dart
// Check if mobile phone (any mobile device)
if (ResponsiveHelper.isMobilePhone()) {
  // Mobile-specific code
}

// Check if tablet (650px - 1300px)
if (ResponsiveHelper.isTab(context)) {
  // Tablet-specific code
}

// Check if desktop (> 1300px)
if (ResponsiveHelper.isDesktop(context)) {
  // Desktop-specific code
}

// Check if web platform (any screen size on web)
if (ResponsiveHelper.isWeb()) {
  // Web-specific code
}

// Check if mobile web (mobile screen size on web)
if (ResponsiveHelper.isMobile(context)) {
  // Mobile web code
}
```

**Breakpoints:**
- Mobile: < 650px
- Tablet: 650px - 1300px
- Desktop: > 1300px
- `webMaxWidth`: 1170px (max content width on web)

### 2. Responsive Layout Patterns

**Pattern A: Conditional Widget Rendering**
```dart
@override
Widget build(BuildContext context) {
  return ResponsiveHelper.isMobilePhone()
    ? _buildMobileLayout()
    : ResponsiveHelper.isTab(context)
      ? _buildTabletLayout()
      : _buildDesktopLayout();
}

Widget _buildMobileLayout() {
  return ListView(
    children: [
      // Mobile UI
    ],
  );
}

Widget _buildTabletLayout() {
  return Row(
    children: [
      Expanded(child: _buildSidebar()),
      Expanded(flex: 2, child: _buildContent()),
    ],
  );
}

Widget _buildDesktopLayout() {
  return Row(
    children: [
      SizedBox(width: 250, child: _buildSidebar()),
      Expanded(child: _buildContent()),
      SizedBox(width: 250, child: _buildRightPanel()),
    ],
  );
}
```

**Pattern B: Adaptive Container Width**
```dart
Container(
  width: ResponsiveHelper.isMobilePhone()
    ? double.infinity
    : Dimensions.webMaxWidth,  // 1170px max on web
  child: // Content
)
```

**Pattern C: Center Content on Web**
```dart
Center(
  child: Container(
    width: Dimensions.webMaxWidth,
    child: // Content constrained to max width
  ),
)
```

### 3. Using Dimensions Class

**Import:**
```dart
import 'package:efood_multivendor/util/dimensions.dart';
```

**Responsive Font Sizes:**
```dart
// Automatically adjusts based on screen width
fontSize: Dimensions.fontSizeExtraSmall   // 10px
fontSize: Dimensions.fontSizeSmall        // 12px
fontSize: Dimensions.fontSizeDefault      // 14px (16px on desktop)
fontSize: Dimensions.fontSizeLarge        // 16px (18px on desktop)
fontSize: Dimensions.fontSizeExtraLarge   // 18px (20px on desktop)
fontSize: Dimensions.fontSizeOverLarge    // 24px
```

**Static Padding/Margin Values:**
```dart
padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall)  // 5px
padding: EdgeInsets.all(Dimensions.paddingSizeSmall)       // 10px
padding: EdgeInsets.all(Dimensions.paddingSizeDefault)     // 15px
padding: EdgeInsets.all(Dimensions.paddingSizeLarge)       // 20px
padding: EdgeInsets.all(Dimensions.paddingSizeExtraLarge)  // 25px
```

**Border Radius:**
```dart
borderRadius: BorderRadius.circular(Dimensions.radiusSmall)       // 5px
borderRadius: BorderRadius.circular(Dimensions.radiusDefault)     // 10px
borderRadius: BorderRadius.circular(Dimensions.radiusLarge)       // 15px
borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)  // 20px
```

**Web Max Width:**
```dart
width: Dimensions.webMaxWidth  // 1170px - max content width on web
```

### 4. Responsive Grid Layouts

**Adaptive Column Count:**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ResponsiveHelper.isMobilePhone()
      ? 2  // 2 columns on mobile
      : ResponsiveHelper.isTab(context)
        ? 3  // 3 columns on tablet
        : 4,  // 4 columns on desktop
    crossAxisSpacing: Dimensions.paddingSizeSmall,
    mainAxisSpacing: Dimensions.paddingSizeSmall,
    childAspectRatio: ResponsiveHelper.isMobilePhone() ? 0.7 : 0.8,
  ),
  itemBuilder: (context, index) {
    return ProductCard(product: products[index]);
  },
)
```

**Responsive SliverGrid:**
```dart
SliverGrid(
  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: ResponsiveHelper.isDesktop(context) ? 300 : 200,
    mainAxisSpacing: Dimensions.paddingSizeDefault,
    crossAxisSpacing: Dimensions.paddingSizeDefault,
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) => ItemWidget(),
  ),
)
```

### 5. Responsive Spacing

**Adaptive Padding:**
```dart
padding: EdgeInsets.all(
  ResponsiveHelper.isDesktop(context)
    ? Dimensions.paddingSizeExtraLarge
    : Dimensions.paddingSizeDefault,
)
```

**Responsive SizedBox:**
```dart
SizedBox(
  height: ResponsiveHelper.isMobilePhone() ? 10 : 20,
)
```

**Adaptive Margins:**
```dart
margin: EdgeInsets.symmetric(
  horizontal: ResponsiveHelper.isMobilePhone()
    ? Dimensions.paddingSizeSmall
    : Dimensions.paddingSizeLarge,
  vertical: Dimensions.paddingSizeDefault,
)
```

### 6. Mobile vs Web Widget Patterns

**Pattern: Show Different Widgets**
```dart
ResponsiveHelper.isWeb()
  ? WebMenuBarWidget()
  : MobileAppBarWidget()
```

**Pattern: Conditional Features**
```dart
Column(
  children: [
    HeaderWidget(),
    ContentWidget(),

    // Desktop-only sidebar
    if (ResponsiveHelper.isDesktop(context))
      SidebarWidget(),

    // Mobile-only bottom nav
    if (ResponsiveHelper.isMobilePhone())
      BottomNavigationWidget(),
  ],
)
```

**Pattern: Platform-Specific Widgets**
```dart
// lib/common/widgets/mobile/mobile_header_widget.dart
// lib/common/widgets/web/web_header_widget.dart

ResponsiveHelper.isMobilePhone()
  ? MobileHeaderWidget()
  : WebHeaderWidget()
```

### 7. Responsive Lists and Scrolling

**Adaptive List Layout:**
```dart
ResponsiveHelper.isMobilePhone()
  ? ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ItemWidget(items[index]),
    )
  : GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) => ItemWidget(items[index]),
    )
```

**Scrollable Content with Max Width:**
```dart
SingleChildScrollView(
  child: Center(
    child: Container(
      width: ResponsiveHelper.isMobilePhone()
        ? double.infinity
        : Dimensions.webMaxWidth,
      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        children: [
          // Content
        ],
      ),
    ),
  ),
)
```

### 8. Responsive Images

**Adaptive Image Size:**
```dart
CustomImageWidget(
  image: imageUrl,
  height: ResponsiveHelper.isMobilePhone() ? 150 : 200,
  width: ResponsiveHelper.isMobilePhone() ? double.infinity : 300,
  fit: BoxFit.cover,
)
```

**Responsive Aspect Ratio:**
```dart
AspectRatio(
  aspectRatio: ResponsiveHelper.isDesktop(context) ? 16 / 9 : 4 / 3,
  child: CustomImageWidget(image: imageUrl),
)
```

### 9. Responsive Dialogs and Bottom Sheets

**Adaptive Dialog Size:**
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
    ),
    child: Container(
      width: ResponsiveHelper.isMobilePhone()
        ? double.infinity
        : 500,  // Fixed width on desktop
      padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: // Dialog content
    ),
  ),
)
```

**Mobile Bottom Sheet, Desktop Dialog:**
```dart
void showOptions(BuildContext context) {
  if (ResponsiveHelper.isMobilePhone()) {
    showModalBottomSheet(
      context: context,
      builder: (context) => OptionsWidget(),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: OptionsWidget(),
      ),
    );
  }
}
```

### 10. Web-Specific Patterns

**Web Menu Bar (Desktop only):**
```dart
if (ResponsiveHelper.isWeb())
  WebMenuBarWidget(
    isDesktop: ResponsiveHelper.isDesktop(context),
  ),
```

**Hover Effects (Web only):**
```dart
import 'package:efood_multivendor/helper/responsive_helper.dart';

class HoverableCard extends StatefulWidget {
  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: ResponsiveHelper.isWeb() ? (_) => setState(() => _isHovered = true) : null,
      onExit: ResponsiveHelper.isWeb() ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: _isHovered ? Matrix4.translationValues(0, -5, 0) : Matrix4.identity(),
        decoration: BoxDecoration(
          boxShadow: _isHovered
            ? [BoxShadow(color: Colors.black26, blurRadius: 10)]
            : [],
        ),
        child: // Card content
      ),
    );
  }
}
```

**Constrained Web Layout:**
```dart
Scaffold(
  body: SafeArea(
    child: Center(
      child: Container(
        width: Dimensions.webMaxWidth,
        child: Row(
          children: [
            // Desktop: Sidebar + Content
            if (ResponsiveHelper.isDesktop(context)) ...[
              SizedBox(width: 250, child: SidebarWidget()),
              SizedBox(width: Dimensions.paddingSizeLarge),
            ],
            Expanded(child: ContentWidget()),
          ],
        ),
      ),
    ),
  ),
)
```

### 11. Responsive Text

**Adaptive Text Sizing:**
```dart
Text(
  'Title',
  style: robotoMedium.copyWith(
    fontSize: ResponsiveHelper.isDesktop(context)
      ? Dimensions.fontSizeExtraLarge
      : Dimensions.fontSizeLarge,
  ),
)
```

**Responsive MaxLines:**
```dart
Text(
  longText,
  maxLines: ResponsiveHelper.isMobilePhone() ? 2 : 3,
  overflow: TextOverflow.ellipsis,
)
```

### 12. Navigation Patterns

**Bottom Navigation (Mobile) vs Side Menu (Desktop):**
```dart
Scaffold(
  body: Row(
    children: [
      // Desktop sidebar
      if (ResponsiveHelper.isDesktop(context))
        SizedBox(
          width: 250,
          child: NavigationSidebarWidget(),
        ),

      // Main content
      Expanded(child: _pages[_selectedIndex]),
    ],
  ),

  // Mobile bottom navigation
  bottomNavigationBar: ResponsiveHelper.isMobilePhone()
    ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [/* nav items */],
      )
    : null,
)
```

## Common Responsive Patterns in GO App

### Pattern: Home Screen Layout
```dart
// Mobile: Vertical scroll
// Desktop: Max width container with side padding

SingleChildScrollView(
  child: Center(
    child: Container(
      width: Dimensions.webMaxWidth,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.isMobilePhone()
          ? Dimensions.paddingSizeSmall
          : Dimensions.paddingSizeLarge,
      ),
      child: Column(
        children: [
          BannerWidget(),
          CategoriesWidget(),
          RestaurantsWidget(),
        ],
      ),
    ),
  ),
)
```

### Pattern: Restaurant List
```dart
// Mobile: ListView
// Desktop: GridView with max width

Container(
  width: ResponsiveHelper.isMobilePhone()
    ? double.infinity
    : Dimensions.webMaxWidth,
  child: ResponsiveHelper.isMobilePhone()
    ? ListView.builder(
        itemBuilder: (context, index) => RestaurantCard(),
      )
    : GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: Dimensions.paddingSizeDefault,
          mainAxisSpacing: Dimensions.paddingSizeDefault,
        ),
        itemBuilder: (context, index) => RestaurantCard(),
      ),
)
```

### Pattern: Details Screen
```dart
// Mobile: Full screen
// Desktop: Centered card with max width

Container(
  width: ResponsiveHelper.isDesktop(context) ? 800 : double.infinity,
  child: Card(
    margin: EdgeInsets.all(
      ResponsiveHelper.isMobilePhone()
        ? 0
        : Dimensions.paddingSizeLarge,
    ),
    child: // Details content
  ),
)
```

## Best Practices

1. **Always use ResponsiveHelper for platform detection**
   - Don't use MediaQuery.of(context).size.width directly
   - Centralized breakpoint logic

2. **Use Dimensions class for all sizing**
   - Automatic font size adjustments
   - Consistent spacing across app

3. **Design mobile-first, then adapt for larger screens**
   - Ensure mobile experience is solid
   - Add features for desktop (hover, multi-column, etc.)

4. **Test on all platforms**
   - Mobile phones (small and large)
   - Tablets
   - Web (desktop and mobile)

5. **Constrain content width on web**
   - Use Dimensions.webMaxWidth
   - Prevents overly wide layouts

6. **Use adaptive layouts, not just scaled mobile**
   - Desktop should leverage space (multi-column, sidebars)
   - Don't just make mobile UI bigger

7. **Consider touch vs mouse interactions**
   - Hover effects only on web
   - Larger touch targets on mobile

8. **Handle orientation changes**
   - Portrait vs landscape layouts
   - Responsive to screen rotation

## Examples

**Create responsive product grid:**
```dart
GridView.builder(
  padding: EdgeInsets.all(
    ResponsiveHelper.isMobilePhone()
      ? Dimensions.paddingSizeSmall
      : Dimensions.paddingSizeLarge,
  ),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ResponsiveHelper.isMobilePhone()
      ? 2
      : ResponsiveHelper.isTab(context)
        ? 3
        : 4,
    childAspectRatio: 0.75,
    crossAxisSpacing: Dimensions.paddingSizeSmall,
    mainAxisSpacing: Dimensions.paddingSizeSmall,
  ),
  itemCount: products.length,
  itemBuilder: (context, index) {
    return ProductCardWidget(product: products[index]);
  },
)
```

**Responsive restaurant details:**
```dart
SingleChildScrollView(
  child: Center(
    child: Container(
      width: ResponsiveHelper.isMobilePhone()
        ? double.infinity
        : Dimensions.webMaxWidth,
      child: Column(
        children: [
          // Hero image
          CustomImageWidget(
            image: restaurant.coverPhoto,
            height: ResponsiveHelper.isMobilePhone() ? 200 : 300,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(
              ResponsiveHelper.isDesktop(context)
                ? Dimensions.paddingSizeExtraLarge
                : Dimensions.paddingSizeDefault,
            ),
            child: ResponsiveHelper.isDesktop(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: RestaurantInfoWidget(restaurant),
                    ),
                    SizedBox(width: Dimensions.paddingSizeLarge),
                    Expanded(
                      child: RestaurantMenuWidget(restaurant),
                    ),
                  ],
                )
              : Column(
                  children: [
                    RestaurantInfoWidget(restaurant),
                    SizedBox(height: Dimensions.paddingSizeDefault),
                    RestaurantMenuWidget(restaurant),
                  ],
                ),
          ),
        ],
      ),
    ),
  ),
)
```

## Troubleshooting

**Layout overflow on mobile:**
- Use SingleChildScrollView
- Check for fixed widths that exceed screen size
- Use Expanded/Flexible in Rows/Columns

**Content too wide on web:**
- Wrap with Center and constrain to Dimensions.webMaxWidth
- Use Container with max width

**Inconsistent spacing:**
- Use Dimensions constants instead of hardcoded values
- Check responsive conditions for padding

**Wrong platform detection:**
- Use correct ResponsiveHelper method
- Remember: isWeb() checks platform, not screen size
- Use isDesktop(context) for large screens

**GridView not responsive:**
- Use crossAxisCount based on ResponsiveHelper
- Adjust childAspectRatio for different screens
