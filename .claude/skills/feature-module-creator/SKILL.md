---
name: feature-module-creator
description: Create new feature modules following GO App's clean architecture pattern with GetX controllers, services, repositories, models, screens, and widgets. Use when adding new features to the app.
allowed-tools: Read, Write, Bash, Glob, Grep
---

# Feature Module Creator

Creates complete feature modules following the GO App's established clean architecture pattern with proper GetX integration, repository pattern, and consistent file structure.

## Instructions

When creating a new feature module:

1. **Verify Feature Name**
   - Ask user for feature name in snake_case (e.g., `loyalty_program`, `table_booking`)
   - Check if feature already exists in `lib/features/`

2. **Create Feature Directory Structure**
   ```
   lib/features/[feature_name]/
   ├── controllers/
   │   └── [feature_name]_controller.dart
   ├── domain/
   │   ├── models/
   │   │   └── [feature_name]_model.dart
   │   ├── repositories/
   │   │   ├── [feature_name]_repository.dart
   │   │   └── [feature_name]_repository_interface.dart
   │   └── services/
   │       ├── [feature_name]_service.dart
   │       └── [feature_name]_service_interface.dart
   ├── screens/
   │   └── [feature_name]_screen.dart
   └── widgets/
       └── [custom_widgets].dart
   ```

3. **Generate Controller**
   - Extends `GetxController` and implements `GetxService`
   - Private variables with public getters
   - Loading states with `_isLoading` boolean
   - Use `update()` to trigger UI rebuilds
   - Inject service via constructor

4. **Generate Repository Interface & Implementation**
   - Interface extends `RepositoryInterface<T>`
   - Implementation uses `ApiClient` for network calls
   - Support both `DataSourceEnum.client` and `DataSourceEnum.local`
   - Handle caching with proper headers

5. **Generate Service Interface & Implementation**
   - Service depends on repository interface
   - Business logic layer between controller and repository
   - Return `Response` objects for API calls

6. **Generate Model**
   - Include `fromJson` and `toJson` methods
   - Handle nullable fields properly
   - List parsing for nested objects

7. **Generate Screen**
   - Use `GetBuilder<[Feature]Controller>` for state management
   - Import `responsive_helper.dart` for platform detection
   - Use `Dimensions` class for responsive sizing
   - Apply theme styles (robotoRegular, robotoMedium, etc.)

8. **Register in Dependency Injection**
   - Add to `lib/helper/utilities/get_di.dart` in the `init()` method:
     ```dart
     // [Feature Name]
     Get.lazyPut(() => [Feature]Controller([Feature]Service(
       [feature]Repository: Get.find(),
     )));
     Get.lazyPut(() => [Feature]Service([feature]Repository: Get.find()));
     Get.lazyPut(() => [Feature]Repository(apiClient: Get.find()));
     ```

9. **Add Route**
   - Add route constant to `RouteHelper` class
   - Create static route getter method
   - Add route to `GetPages` list in main.dart

10. **Add API Endpoint**
    - Add endpoint constant to `AppConstants` class
    - Follow naming: `[feature]Uri = '/api/v1/[endpoint]'`

## File Templates

### Controller Template
```dart
import 'package:get/get.dart';
import 'package:efood_multivendor/features/[feature]/domain/services/[feature]_service_interface.dart';

class [Feature]Controller extends GetxController implements GetxService {
  final [Feature]ServiceInterface [feature]Service;
  [Feature]Controller(this.[feature]Service);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // TODO: Add feature-specific state variables

  Future<void> get[Feature]Data() async {
    _isLoading = true;
    update();

    Response response = await [feature]Service.get[Feature]List();
    if (response.statusCode == 200) {
      // TODO: Process response
    }

    _isLoading = false;
    update();
  }
}
```

### Repository Interface Template
```dart
import 'package:efood_multivendor/interface/repository_interface.dart';
import 'package:get/get_connect/http/src/response/response.dart';

abstract class [Feature]RepositoryInterface extends RepositoryInterface {
  Future<Response> getList({DataSourceEnum? source});
}
```

### Service Interface Template
```dart
import 'package:get/get_connect/http/src/response/response.dart';

abstract class [Feature]ServiceInterface {
  Future<Response> get[Feature]List();
}
```

## Best Practices

- Always follow snake_case for file and directory names
- Use PascalCase for class names
- Keep controllers focused on UI state management
- Put business logic in services
- Use repositories only for data access
- Add proper error handling with try-catch
- Use `showCustomSnackBar()` from `helper.dart` for user feedback
- Follow existing patterns from similar features (check `home`, `restaurant`, `order`)

## Examples

**Create a new notifications feature:**
```
User: "Create a notifications feature to display push notifications"

Steps:
1. Create lib/features/notification/ directory structure
2. Generate NotificationController with notification list state
3. Generate NotificationRepository with API client
4. Generate NotificationService with business logic
5. Generate NotificationModel with fromJson/toJson
6. Generate NotificationScreen with GetBuilder
7. Register in get_di.dart
8. Add route in route_helper.dart
9. Add notificationUri to app_constants.dart
```

**Add booking feature for tables:**
```
User: "Add table booking functionality"

Creates:
- lib/features/booking/
- BookingController with date/time/party size state
- BookingRepository for API calls
- BookingService for validation logic
- BookingModel with restaurant and time slot data
- BookingScreen with date picker and restaurant selection
- Registers all in GetX DI container
```

## Validation Checklist

Before completing, verify:
- [ ] All files use correct naming convention
- [ ] Controller registered in get_di.dart
- [ ] Route added to route_helper.dart
- [ ] API endpoint in app_constants.dart
- [ ] Imports are correct and no circular dependencies
- [ ] Model has proper JSON serialization
- [ ] Service interface matches implementation
- [ ] Repository follows DataSourceEnum pattern
- [ ] Screen uses GetBuilder for reactivity
- [ ] Responsive design with Dimensions class
