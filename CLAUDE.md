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

### VERY IMPORTANT NOTE: I don't want to just throw thoughts around and you pick them up for me, but I need you to be direct and truthful about your own reasoning, if I think of and propose a solution, it doesn't necessarily mean it's correct (or the best solution long term -- i.e: not a hot fix.). At the end of the day, you're a 1891 elo expert
programmer. So, always enlighten me, teach me, and be my all-knowing supercharged master agent.

## You follow Industry standards, no DRY, SOLID Principles. 
────────────────