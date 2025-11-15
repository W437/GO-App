---
name: mobile-design-excellence
description: Design distinctive, polished mobile app interfaces that avoid generic Material defaults. Emphasizes bold typography, cohesive color systems, meaningful motion, and atmospheric depth. Use when creating new UI screens or improving existing designs.
---

# Mobile Design Excellence

Create memorable, distinctive mobile app interfaces that go beyond generic Material Design defaults. This skill helps you build polished, professional UIs with personality.

## Core Philosophy

Avoid distributional convergence—the tendency toward safe, generic mobile designs. Instead, create interfaces that are:
- **Distinctive**: Memorable visual identity beyond stock Material components
- **Cohesive**: Consistent design language across all screens
- **Polished**: Attention to micro-interactions and details
- **Contextual**: Design choices that match the app's purpose and brand

## 1. Typography: Bold Hierarchy & Distinctive Choices

### Go Beyond Basic Styles

**Avoid generic defaults:**
```dart
// ❌ Generic - everyone uses this
Text('Title', style: robotoMedium)
Text('Body', style: robotoRegular)
```

**Create distinctive hierarchy:**
```dart
// ✅ Distinctive - strong visual hierarchy
Text(
  'Featured Restaurant',
  style: GoogleFonts.playfairDisplay(  // Elegant serif for headings
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  ),
)

Text(
  'Authentic Italian cuisine in the heart of downtown',
  style: GoogleFonts.inter(  // Clean sans for body
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: Colors.black.withOpacity(0.7),
  ),
)
```

### High-Contrast Font Pairings

Pair extreme weights and styles for visual impact:

```dart
// Dramatic weight contrast
headline: GoogleFonts.montserrat(
  fontSize: 28,
  fontWeight: FontWeight.w900,  // Ultra bold
  letterSpacing: -1,
)

subheading: GoogleFonts.montserrat(
  fontSize: 14,
  fontWeight: FontWeight.w300,  // Light
  letterSpacing: 0.5,
)

// Serif + Sans pairing
title: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)
body: GoogleFonts.inter(fontWeight: FontWeight.w400)

// Geometric + Humanist
heading: GoogleFonts.poppins(fontWeight: FontWeight.w800)
caption: GoogleFonts.workSans(fontWeight: FontWeight.w300)
```

### Typography System

```dart
class AppTypography {
  // Display - for hero sections
  static TextStyle display = GoogleFonts.playfairDisplay(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1,
  );

  // Headline - for section titles
  static TextStyle headline = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Title - for card headers
  static TextStyle title = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body - for readable content
  static TextStyle body = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // Caption - for metadata
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.5,
  );
}
```

## 2. Color & Theme: Cohesive, Bold Aesthetics

### Avoid Timid Palettes

**Generic approach:**
```dart
// ❌ Safe but forgettable
primaryColor: Colors.blue
accentColor: Colors.blueAccent
```

**Bold, cohesive approach:**
```dart
// ✅ Distinctive color system
class AppColors {
  // Dominant color - own it completely
  static const primary = Color(0xFF0A0E27);  // Deep midnight blue
  static const primaryLight = Color(0xFF1A1F3A);

  // Sharp accent - high contrast
  static const accent = Color(0xFFFF6B6B);  // Vibrant coral
  static const accentGlow = Color(0xFFFF8787);

  // Atmosphere colors
  static const surface = Color(0xFF0F1419);
  static const surfaceElevated = Color(0xFF1A1F2E);

  // Semantic colors with personality
  static const success = Color(0xFF00D9A3);  // Bright mint
  static const warning = Color(0xFFFFB800);  // Bold amber
  static const error = Color(0xFFFF4757);    // Vivid red

  // Gradients for depth
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F3A), Color(0xFF0A0E27)],
  );
}
```

### Cultural & Thematic Palettes

Draw inspiration from context:

```dart
// Food delivery - warm, appetizing
static const foodPrimary = Color(0xFFE63946);    // Rich tomato red
static const foodAccent = Color(0xFFF77F00);     // Saffron orange
static const foodNeutral = Color(0xFF2B2D42);    // Charcoal

// Wellness app - calm, natural
static const wellnessPrimary = Color(0xFF2D6A4F);  // Forest green
static const wellnessAccent = Color(0xFF95D5B2);   // Sage
static const wellnessNeutral = Color(0xFF1B4332);  // Deep pine

// Finance - trust, premium
static const financePrimary = Color(0xFF1E3A8A);   // Royal blue
static const financeAccent = Color(0xFFFBBF24);    // Gold
static const financeNeutral = Color(0xFF1F2937);   // Slate
```

### Theme Implementation

```dart
ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,

    // Color scheme
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      background: AppColors.surface,
    ),

    // Card theme with elevated feel
    cardTheme: CardTheme(
      color: AppColors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
    ),

    // Typography system
    textTheme: TextTheme(
      displayLarge: AppTypography.display,
      headlineMedium: AppTypography.headline,
      titleMedium: AppTypography.title,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
    ),
  );
}
```

## 3. Motion: Meaningful, Orchestrated Animation

### Avoid Scattered Micro-animations

Focus on **high-impact moments** with orchestrated reveals rather than animating everything.

### Page Entry Choreography

```dart
class StaggeredPageEntry extends StatefulWidget {
  final Widget child;

  @override
  State<StaggeredPageEntry> createState() => _StaggeredPageEntryState();
}

class _StaggeredPageEntryState extends State<StaggeredPageEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    // Staggered timing
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
```

### Staggered List Reveals

```dart
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600),
          delay: Duration(milliseconds: 100 * index),  // Stagger delay
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: children[index],
        );
      },
    );
  }
}
```

### Gesture-Based Interactions

```dart
class SwipeableCard extends StatefulWidget {
  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
        });
      },
      onPanEnd: (details) {
        // Snap back with spring physics
        _controller.reset();
        _controller.forward().then((_) {
          setState(() => _dragOffset = Offset.zero);
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final offset = _dragOffset * (1 - _controller.value);
          final rotation = (offset.dx / 500) * (1 - _controller.value);

          return Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: rotation,
              child: child,
            ),
          );
        },
        child: Card(/* card content */),
      ),
    );
  }
}
```

### Hero Transitions

```dart
// Source screen
Hero(
  tag: 'restaurant-${restaurant.id}',
  child: RestaurantImage(restaurant),
)

// Destination screen
Hero(
  tag: 'restaurant-${restaurant.id}',
  child: RestaurantDetailImage(restaurant),
)

// With custom flight
Hero(
  tag: 'product-image',
  flightShuttleBuilder: (context, animation, direction, from, to) {
    return ScaleTransition(
      scale: animation.drive(
        Tween<double>(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
      ),
      child: to.widget,
    );
  },
  child: ProductImage(),
)
```

## 4. Backgrounds: Atmosphere & Depth

### Avoid Flat Solid Colors

Create depth through layering, gradients, and effects.

### Layered Gradients

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  ),
  child: Stack(
    children: [
      // Radial overlay for depth
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accent.withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Content
    ],
  ),
)
```

### Mesh Gradients

```dart
class MeshGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),

        // Mesh blobs
        Positioned(
          top: -150,
          left: -150,
          child: _GradientBlob(
            colors: [Color(0xFFFF6B6B), Colors.transparent],
            size: 400,
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _GradientBlob(
            colors: [Color(0xFF4ECDC4), Colors.transparent],
            size: 350,
          ),
        ),

        // Noise texture overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/noise.png',
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientBlob extends StatelessWidget {
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
```

### Glassmorphism

```dart
class GlassCard extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
```

### Geometric Patterns

```dart
class GeometricBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _GeometricPatternPainter(),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw diagonal lines
    for (double i = -size.height; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw circles
    for (double x = 0; x < size.width; x += 100) {
      for (double y = 0; y < size.height; y += 100) {
        canvas.drawCircle(Offset(x, y), 20, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

## 5. Layout & Composition: Beyond Standard Grids

### Asymmetric Layouts

```dart
// Instead of uniform grids
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
  ),
  // ...
)

// Try asymmetric masonry
MasonryGridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  itemBuilder: (context, index) {
    // Vary heights for visual interest
    final height = index.isEven ? 200.0 : 280.0;
    return Container(height: height, child: ItemCard());
  },
)
```

### Floating Elements

```dart
Stack(
  children: [
    // Main content
    ListView(...),

    // Floating action elements
    Positioned(
      top: 100,
      right: 20,
      child: FloatingBadge(count: 3),
    ),

    // Overlapping cards
    Positioned(
      bottom: -50,  // Intentional overflow
      left: 0,
      right: 0,
      child: Transform.scale(
        scale: 0.95,
        child: PreviewCard(),
      ),
    ),
  ],
)
```

### Z-axis Layering

```dart
class LayeredCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Shadow layer 2
        Positioned(
          top: 8,
          left: 4,
          right: 4,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Shadow layer 1
        Positioned(
          top: 4,
          left: 2,
          right: 2,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Main card
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: CardContent(),
        ),
      ],
    );
  }
}
```

## 6. Custom Components: Signature UI Elements

### Avoid Stock Material Widgets Everywhere

Create custom components that define your app's personality.

### Custom Bottom Navigation

```dart
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: 'Home', isSelected: selectedIndex == 0),
          _NavItem(icon: Icons.search, label: 'Explore', isSelected: selectedIndex == 1),
          _FloatingCenterButton(),  // Special center button
          _NavItem(icon: Icons.favorite, label: 'Saved', isSelected: selectedIndex == 2),
          _NavItem(icon: Icons.person, label: 'Profile', isSelected: selectedIndex == 3),
        ],
      ),
    );
  }
}

class _FloatingCenterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -20),  // Float above nav bar
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.accent, AppColors.accentGlow],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
```

### Custom Sliders

```dart
class CustomSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.accent.withOpacity(0.2),
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 12,
          elevation: 8,
        ),
        overlayColor: AppColors.accent.withOpacity(0.2),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
      ),
      child: Slider(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
```

### Signature Cards

```dart
class SignatureCard extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.accent.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

## Application Guidelines

### When to Apply This Skill

Use this skill when:
- Creating new screens or features
- Redesigning existing interfaces
- Building hero/landing screens
- Designing app onboarding
- Creating signature moments (checkout, success states, etc.)

### What to Avoid

Don't apply extreme design to:
- Settings screens (keep functional)
- Forms (prioritize usability)
- Error states (keep clear)
- Loading states (keep simple)

### Balance

- **80%** of your app: Clean, usable, conventional
- **20%** signature moments: Bold, memorable, distinctive

Focus design excellence on high-impact screens:
- Home/Dashboard
- Product/Restaurant details
- Onboarding
- Success/completion states
- Marketing/promotional content

## Implementation Checklist

When designing a new screen:

- [ ] Typography uses distinctive font pairing (not just robotoRegular/Medium)
- [ ] Color palette is cohesive with dominant color and sharp accents
- [ ] Entry animation is orchestrated (staggered reveals)
- [ ] Background has depth (gradients, layers, or effects)
- [ ] Layout breaks from standard grid where appropriate
- [ ] Custom components reflect app personality
- [ ] Micro-interactions add delight without distraction
- [ ] Design choices match app context and brand

## Examples

**Generic approach:**
```dart
// ❌ Forgettable
Scaffold(
  appBar: AppBar(title: Text('Restaurants')),
  body: ListView(
    children: [
      Card(child: ListTile(title: Text('Restaurant Name'))),
      Card(child: ListTile(title: Text('Restaurant Name'))),
    ],
  ),
)
```

**Distinctive approach:**
```dart
// ✅ Memorable
Scaffold(
  body: Stack(
    children: [
      // Atmospheric background
      MeshGradientBackground(),

      // Content with staggered entry
      SafeArea(
        child: Column(
          children: [
            // Custom header
            Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discover',
                    style: AppTypography.display,
                  ),
                  GlassCard(child: Icon(Icons.search)),
                ],
              ),
            ),

            // Staggered list
            Expanded(
              child: StaggeredListView(
                children: restaurants.map((r) =>
                  SignatureCard(
                    child: RestaurantCardContent(r),
                  ),
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
  bottomNavigationBar: CustomBottomNav(),
)
```

---

**Remember**: Design excellence is about intentional choices, not complexity. Every design decision should serve the user experience and reinforce your app's identity.
