- DigitalOcean deployment server ip: 138.197.188.120 - use for SSH'ing in.

## Navigation & Transitions

- **3D Transitions**: Any route using `customTransition: _ThreeDGetTransition()` MUST have `popGesture: false` set
  - The interactive gesture (finger-following animation) causes freezing with complex 3D transforms
  - Instead, `_ThreeDGetTransition` automatically wraps screens with `SwipeBackWrapper` which provides a simple trigger-based swipe (detects swipe → calls `Get.back()` → plays normal animation)
  - Example:
    ```dart
    GetPage(
      name: myRoute,
      page: () => MyScreen(),
      customTransition: _ThreeDGetTransition(),
      transitionDuration: const Duration(milliseconds: 500),
      opaque: false,
      popGesture: false, // REQUIRED for 3D transitions
    )
    ```