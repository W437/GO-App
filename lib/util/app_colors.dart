import 'package:flutter/material.dart';

class AppColors {
  // Brand colors - Official Hopa! Brand Guidelines
  static const Color brandPrimary = Color(0xFF0acaf0);      // Hopa Blue - primary buttons, highlights, icons
  static const Color brandPrimaryHover = Color(0xFF08b4d6); // Darker Hopa Blue for hover states
  static const Color brandPrimaryLight = Color(0xFF3dd6f5); // Lighter Hopa Blue variant
  static const Color brandPrimaryDark = Color(0xFF0790b4);  // Darker Hopa Blue variant
  static const Color brandSecondary = Color(0xFF003a5b);    // Hopa Deep Blue - titles, headers, strong text
  static const Color brandSecondaryHover = Color(0xFF002d47); // Darker Deep Blue for hover states
  static const Color brandSecondaryLight = Color(0xFF004d73); // Lighter Deep Blue variant
  static const Color brandSecondaryDark = Color(0xFF001f33);  // Darkest Deep Blue variant
  static const Color brandAccent = Color(0xFF55b15c);       // Fresh Green - success states, badges

  // Background colors
  static const Color backgroundPrimary = Color(0xFFffffff);      // Main white background
  static const Color backgroundSecondary = Color(0xFFf9fafb);    // Light gray background
  static const Color backgroundTertiary = Color(0xFFf3f4f6);    // Slightly darker gray
  static const Color backgroundDark = Color(0xFF003a5b);         // Hopa Deep Blue (header/footer)
  static const Color backgroundDarkLight = Color(0xFF334a52);    // Deep Slate - dark mode backgrounds
  static const Color backgroundDarkGray = Color(0xFF334a52);     // Deep Slate - navigation bars, cards

  // Text colors
  static const Color textPrimary = Color(0xFF111827);      // Main dark text
  static const Color textSecondary = Color(0xFF6b7280);    // Gray text
  static const Color textTertiary = Color(0xFF9ca3af);     // Light gray text
  static const Color textInverse = Color(0xFFffffff);      // White text on dark backgrounds
  static const Color textMuted = Color(0xFFd1d5db);        // Muted text

  // Semantic colors
  static const Color semanticSuccess = Color(0xFF55b15c);      // Fresh Green for success states
  static const Color semanticError = Color(0xFFFF4D4D);        // Error Red (from guidelines)
  static const Color semanticWarning = Color(0xFFFFC233);      // Warning Amber (from guidelines)
  static const Color semanticInfo = Color(0xFF0acaf0);         // Hopa Blue for info states

  // Border colors
  static const Color borderLight = Color(0xFFe5e7eb);        // Light border
  static const Color borderMedium = Color(0xFF96afb8);       // Soft Steel - borders, dividers
  static const Color borderDark = Color(0xFF334a52);         // Deep Slate - dark borders
  static const Color borderFocus = Color(0xFF0acaf0);        // Focus border (Hopa Blue)

  // Shadow colors (for consistency)
  static const Color shadowLight = Color.fromRGBO(0, 0, 0, 0.05);
  static const Color shadowMedium = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color shadowDark = Color.fromRGBO(0, 0, 0, 0.25);
  static const Color shadowBrand = Color.fromRGBO(10, 202, 240, 0.2); // Hopa Blue shadow

  // Official Hopa Gradients (from brand guidelines)
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0ACAF0), Color(0xFF24B1F2), Color(0xFF5E94E6)],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient gradientPrimaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0ACAF0), Color(0xFF24B1F2), Color(0xFF5E94E6)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient gradientEmotional = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0ACAF0), Color(0xFF5E94E6), Color(0xFF8974CA), Color(0xFFA3509F)],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  static const LinearGradient gradientEmotionalVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0ACAF0), Color(0xFF5E94E6), Color(0xFF8974CA), Color(0xFFA3509F)],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0ACAF0), Color(0xFF88F9BA), Color(0xFF4EBF85)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient gradientSuccessVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0ACAF0), Color(0xFF88F9BA), Color(0xFF4EBF85)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient gradientFrost = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE6FDFF), Color(0xFFE6F4F1)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient gradientFrostVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6FDFF), Color(0xFFE6F4F1)],
    stops: [0.0, 1.0],
  );
}
