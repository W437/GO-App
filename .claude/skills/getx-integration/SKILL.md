---
name: getx-integration
description: Add GetX state management to existing code, create controllers, register dependencies, add reactive UI with GetBuilder, and implement GetX navigation. Use when working with state management or adding reactivity.
allowed-tools: Read, Edit, Write, Grep, Glob
---

# GetX Integration Expert

Implements GetX state management patterns used in GO App, including controllers, dependency injection, reactive UI updates, and navigation.

## Instructions

### 1. Creating a GetX Controller

When adding state management to a feature:

**Controller Structure:**
```dart
import 'package:get/get.dart';

class [Feature]Controller extends GetxController implements GetxService {
  final [Feature]ServiceInterface [feature]Service;
  [Feature]Controller(this.[feature]Service);

  // Private state with public getters
  List<Item>? _itemList;
  List<Item>? get itemList => _itemList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;

  // Methods that update state
  Future<void> getData() async {
    _isLoading = true;
    update(); // Trigger UI rebuild

    Response response = await [feature]Service.fetchData();
    if (response.statusCode == 200) {
      _itemList = // process response
    }

    _isLoading = false;
    update(); // Trigger UI rebuild
  }

  void selectItem(int index) {
    _selectedIndex = index;
    update(); // Always call update() after changing state
  }

  // Optional: lifecycle hooks
  @override
  void onInit() {
    super.onInit();
    getData(); // Load data when controller initializes
  }
}
```

**Key Rules:**
- Always extend `GetxController` and implement `GetxService`
- Use private variables with public getters
- Call `update()` after every state change
- Inject dependencies via constructor
- Use async/await for API calls

### 2. Registering in Dependency Injection

**Location:** `lib/helper/utilities/get_di.dart`

**Pattern:**
```dart
Future<void> init() async {
  // ... existing registrations ...

  // [Feature Name] - add in alphabetical order
  Get.lazyPut(() => [Feature]Controller(Get.find()));
  Get.lazyPut(() => [Feature]Service([feature]Repository: Get.find()));
  Get.lazyPut(() => [Feature]Repository(apiClient: Get.find()));
}
```

**Registration Types:**
- `Get.lazyPut()` - Creates instance only when first requested (preferred)
- `Get.put()` - Creates instance immediately
- `Get.find()` - Retrieves existing instance

**Order:** Add new registrations in alphabetical order by feature name

### 3. Using Controllers in Widgets

**Option A: GetBuilder (Recommended)**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<[Feature]Controller>(
      builder: ([feature]Controller) {
        return _isLoading
          ? CircularProgressIndicator()
          : ListView.builder(
              itemCount: [feature]Controller.itemList?.length ?? 0,
              itemBuilder: (context, index) {
                return Text([feature]Controller.itemList![index].name);
              },
            );
      },
    );
  }
}
```

**Option B: Get.find() (For simple access)**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<[Feature]Controller>();

    return ElevatedButton(
      onPressed: () => controller.selectItem(0),
      child: Text('Select'),
    );
  }
}
```

**Option C: Obx (For single reactive variables)**
```dart
// Only if using .obs variables
final count = 0.obs;

Obx(() => Text('Count: $count'))
```

**GO App Standard:** Use GetBuilder for most cases

### 4. GetX Navigation

**Pattern in GO App:**

**Define Routes:** `lib/helper/navigation/route_helper.dart`
```dart
class RouteHelper {
  static const String initial = '/';
  static const String [feature] = '/[feature]';

  static String get[Feature]Route(String? id) => '$[feature]?id=$id';

  static List<GetPage> routes = [
    GetPage(name: [feature], page: () => [Feature]Screen()),
  ];
}
```

**Navigate to screen:**
```dart
// Simple navigation
Get.toNamed(RouteHelper.[feature]);

// With parameters
Get.toNamed(RouteHelper.get[Feature]Route('123'));

// Replace current screen
Get.offNamed(RouteHelper.[feature]);

// Clear stack and navigate
Get.offAllNamed(RouteHelper.[feature]);

// Go back
Get.back();

// Go back with result
Get.back(result: {'success': true});
```

**Reading route parameters:**
```dart
class [Feature]Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? id = Get.parameters['id'];
    // Use id...
  }
}
```

### 5. GetX Dialogs and Snackbars

**Snackbar (GO App uses custom helper):**
```dart
// From helper/custom_snackbar_helper.dart
showCustomSnackBar('Error message', isError: true);
showCustomSnackBar('Success message');
```

**GetX Built-in Snackbar:**
```dart
Get.snackbar(
  'Title',
  'Message',
  snackPosition: SnackPosition.BOTTOM,
);
```

**Dialog:**
```dart
Get.dialog(
  AlertDialog(
    title: Text('Confirm'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(
        onPressed: () => Get.back(),
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          // Do action
          Get.back();
        },
        child: Text('OK'),
      ),
    ],
  ),
);
```

**Bottom Sheet:**
```dart
Get.bottomSheet(
  Container(
    color: Colors.white,
    child: // Your content
  ),
);
```

### 6. Reactive State Patterns

**Loading States:**
```dart
class [Feature]Controller extends GetxController {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    update();

    // API call

    _isLoading = false;
    update();
  }
}

// In widget
GetBuilder<[Feature]Controller>(
  builder: (controller) {
    if (controller.isLoading) {
      return ShimmerWidget(); // GO App pattern
    }
    return ContentWidget();
  },
)
```

**List Updates:**
```dart
void addItem(Item item) {
  _itemList?.add(item);
  update(); // Rebuilds UI
}

void removeItem(int index) {
  _itemList?.removeAt(index);
  update();
}

void updateItem(int index, Item item) {
  _itemList?[index] = item;
  update();
}
```

**Tab/Index Selection:**
```dart
int _selectedIndex = 0;
int get selectedIndex => _selectedIndex;

void selectTab(int index) {
  _selectedIndex = index;
  update();
}
```

### 7. Controller Lifecycle

```dart
class [Feature]Controller extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Called when controller is created
    // Use for initial data loading
    getData();
  }

  @override
  void onReady() {
    super.onReady();
    // Called after widget is rendered
  }

  @override
  void onClose() {
    super.onClose();
    // Called when controller is removed
    // Use for cleanup (dispose controllers, cancel subscriptions)
  }
}
```

### 8. Dependency Access in Controllers

```dart
class HomeController extends GetxController {
  final HomeServiceInterface homeService;
  HomeController(this.homeService);

  // Access other controllers
  void checkAuth() {
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn) {
      // Do something
    }
  }

  // Access shared preferences
  void saveData() {
    final sharedPreferences = Get.find<SharedPreferences>();
    sharedPreferences.setString('key', 'value');
  }
}
```

## Best Practices

1. **Always call `update()` after state changes**
   - Forgot `update()`? UI won't refresh

2. **Use GetBuilder for most cases**
   - GO App pattern: avoid `.obs` and `Obx` unless needed

3. **Keep controllers focused**
   - One controller per feature
   - Don't mix concerns (auth logic in cart controller)

4. **Inject dependencies in constructor**
   - Don't use `Get.find()` in constructor
   - Use in methods only

5. **Register in correct order**
   - Register repositories before services
   - Register services before controllers

6. **Use lazyPut for better performance**
   - Controllers only created when needed
   - Reduces memory usage

7. **Don't create controllers in widgets**
   - Always register in `get_di.dart`
   - Use `Get.find()` to access

## Common Patterns in GO App

### Pattern: Controller with Service & Repository
```dart
// Registration order matters!
Get.lazyPut(() => RestaurantRepository(apiClient: Get.find()));
Get.lazyPut(() => RestaurantService(restaurantRepository: Get.find()));
Get.lazyPut(() => RestaurantController(Get.find()));
```

### Pattern: Multiple Data Sources
```dart
Future<void> getData(bool reload) async {
  if (reload) {
    _dataList = null;
  }

  if (_dataList == null) {
    _isLoading = true;
    update();

    Response response = await service.getList();
    // Process response

    _isLoading = false;
    update();
  }
}
```

### Pattern: Pagination
```dart
int _offset = 1;
bool _hasMore = true;

Future<void> loadMore() async {
  if (_hasMore && !_isLoading) {
    _offset++;
    Response response = await service.getList(offset: _offset);

    if (response.body['data'].isEmpty) {
      _hasMore = false;
    } else {
      _dataList?.addAll(response.body['data']);
    }
    update();
  }
}
```

## Examples

**Add cart functionality:**
```
1. Create CartController with item list
2. Add methods: addItem(), removeItem(), calculateTotal()
3. Register in get_di.dart
4. Use GetBuilder in CartScreen
5. Call controller.addItem() from product screen
```

**Add authentication state:**
```
1. Create AuthController with login/logout methods
2. Store token in SharedPreferences
3. Register early in get_di.dart (other controllers depend on it)
4. Use Get.find<AuthController>() to check auth state
5. Navigate with Get.offAllNamed() after login
```

## Troubleshooting

**Error: "Controller not found"**
- Solution: Register in get_di.dart with Get.lazyPut()

**Error: "Null check operator used on null value"**
- Solution: Use null-safe operators (?., ??)

**UI not updating:**
- Solution: Call update() after state change

**Circular dependency:**
- Solution: Check registration order in get_di.dart
