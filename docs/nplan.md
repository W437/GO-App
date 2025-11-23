You’re running into a Navigator limitation that your GetX helper is kind of hiding from you:
you’re only animating the **foreground** page, but for a Wolt-style effect you *must* also animate the **background** page via `secondaryAnimation`.

That “white empty bg” you see while swiping? That’s because the previous route isn’t being painted/animated at all during the gesture – only the top route is.

Let’s fix that properly.

---

## Mental model (what Wolt is doing)

When you tap a restaurant:

* **Restaurant page (top route)**:

  * Slides in from the right
  * Rotates slightly in 3D (Y axis) as it comes in

* **Home page (route below)**:

  * Scales down slightly
  * Shifts a bit to the left (parallax)
  * When you swipe the restaurant page back, it moves smoothly back into place

To do this cleanly in Flutter:

* You **cannot** use a transition API that only gives you the “child” of the **new** route (like GetX’s `CustomTransition`).
* You need something that:

  * Animates the **top route** using `animation`
  * Animates the **previous route** using `secondaryAnimation`

Flutter’s own `PageTransitionsTheme` + `PageTransitionsBuilder` are exactly for this.

---

## Step 1 – Create a Wolt-style `PageTransitionsBuilder`

This builder will be applied to **every route**, both foreground and background.
It will:

* Detect whether it’s the **top route** or **a route under another**
* For the top route -> apply the 3D slide effect
* For the route under it -> apply the parallax/scale using `secondaryAnimation`

```dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class WoltLikePageTransitionsBuilder extends PageTransitionsBuilder {
  const WoltLikePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // If this route has no transition (e.g. initial route), just return it.
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    // Heuristic: if secondaryAnimation is not dismissed, this route
    // is *under* another route that’s animating on top of it.
    final bool isBelowTop =
        secondaryAnimation.status != AnimationStatus.dismissed ||
        secondaryAnimation.value != 0.0;

    final Size size = MediaQuery.of(context).size;

    if (isBelowTop) {
      // BACKGROUND (home when restaurant is on top)
      return AnimatedBuilder(
        animation: secondaryAnimation,
        builder: (context, _) {
          final double t = Curves.easeOut.transform(secondaryAnimation.value);

          // Shift a bit to the left and scale down slightly.
          final double dx = -size.width * 0.08 * t;  // ~8% to the left
          final double scale = 1.0 - 0.05 * t;       // 5% smaller at max

          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      );
    } else {
      // FOREGROUND (restaurant page)
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final double t = Curves.easeOutCubic.transform(animation.value);

          // Slide from right
          final double dx = (1.0 - t) * size.width;

          // Small Y-axis rotation for 3D feel
          const double maxAngle = 0.10; // ~6 degrees in radians
          final double angle = (1.0 - t) * maxAngle;

          final Matrix4 transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..translate(dx)
            ..rotateY(-angle);

          return Transform(
            alignment: Alignment.centerLeft,
            transform: transform,
            child: child,
          );
        },
      );
    }
  }
}
```

Key bits:

* **Foreground** uses `animation.value` → handles push + interactive pop.
* **Background** uses `secondaryAnimation.value` → moves/scales as the new page enters or leaves.
* This automatically works with interactive back swipe (on iOS) because Flutter drives the same `animation` during the drag.

---

## Step 2 – Plug it into your `MaterialApp` (or `GetMaterialApp`)

You now tell Flutter: use this transition for all pages.

If you’re using plain Flutter:

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: WoltLikePageTransitionsBuilder(),
        TargetPlatform.iOS: WoltLikePageTransitionsBuilder(),
      },
    ),
  ),
  // routes / onGenerateRoute / home...
);
```

If you’re using **GetX** (`GetMaterialApp`), do this:

```dart
GetMaterialApp(
  // Important: disable GetX’s built-in transitions for pages
  defaultTransition: Transition.noTransition,
  // and let Flutter’s PageTransitionsTheme handle it.
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: WoltLikePageTransitionsBuilder(),
        TargetPlatform.iOS: WoltLikePageTransitionsBuilder(),
      },
    ),
  ),
  // getPages: [...],
);
```

Then navigate normally:

```dart
// With Navigator:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const RestaurantScreen(),
    settings: const RouteSettings(name: '/restaurant'),
  ),
);

// Or with GetX:
Get.to(() => const RestaurantScreen(), routeName: '/restaurant');
```

Now the **same custom transition** is used for:

* The restaurant screen (foreground)
* The home screen when it’s underneath (background parallax)

No more white void on drag.

---

## Step 3 – Why your GetX `CustomTransition` failed

> "CustomTransition only exposes the foreground widget"

That’s the core issue.

For a Wolt-style transition you **must** affect the previous page. With GetX’s `CustomTransition`, you only get a `child` = the new page. The Navigator keeps animating the previous page with its *own* default transition, and you can't hook into that.

By moving the logic to `PageTransitionsTheme` / `PageTransitionsBuilder` you get:

* The new page’s `animation`
* The previous page’s `secondaryAnimation`
* Control over **both** via the same transition definition
* Interactive swipe support out of the box (iOS)

---

## Step 4 – Performance / RAM concerns

Good news: this approach is efficient and “Navigator-native”.

* You’re still using one widget tree per route.
* No extra overlay or off-screen clones.
* The GPU handles the 3D transforms; the cost is basically:

  * some `AnimatedBuilder` rebuilds
  * a single `Transform` per page
* Navigator already keeps previous pages in memory; this doesn’t change that.
* You’re not stacking extra Routes or using nested Navigators for the effect.

If you want to be extra safe:

* Keep your pages split into smaller widgets so only parts that depend on animations rebuild.
* Use `const` constructors where possible in content widgets.
* Avoid heavy rebuild work inside the `AnimatedBuilder` (only transforms, no complex layouts).

---

## Bonus: making it feel even more “Wolt”

You can tweak inside the builder:

* Increase `maxAngle` for more dramatic 3D.
* Add a tiny shadow/blur or dark overlay on the background page:

```dart
return Transform.translate(
  offset: Offset(dx, 0),
  child: Transform.scale(
    scale: scale,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05 * t),
      ),
      child: child,
    ),
  ),
);
```
