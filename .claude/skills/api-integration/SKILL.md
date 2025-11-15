---
name: api-integration
description: Integrate REST APIs into GO App using ApiClient, implement repository pattern with caching, handle responses, and manage API endpoints. Use when adding new API calls or modifying existing API integration.
allowed-tools: Read, Edit, Write, Grep, Glob
---

# API Integration Expert

Implements REST API integration following GO App's patterns including ApiClient usage, repository pattern, response handling, caching, and error management.

## Instructions

### 1. Adding New API Endpoint

**Step 1: Add endpoint to AppConstants**

Location: `lib/util/app_constants.dart`

```dart
class AppConstants {
  // ... existing constants ...

  // [Feature] Endpoints
  static const String [feature]Uri = '/api/v1/[endpoint]';
  static const String [feature]DetailsUri = '/api/v1/[endpoint]/details';
  static const String [feature]CreateUri = '/api/v1/[endpoint]/create';
  static const String [feature]UpdateUri = '/api/v1/[endpoint]/update';
  static const String [feature]DeleteUri = '/api/v1/[endpoint]/delete';
}
```

**Best practices:**
- Group related endpoints together
- Use descriptive constant names ending with `Uri`
- Follow RESTful conventions

### 2. Repository Implementation

**Repository Interface:**
```dart
// lib/features/[feature]/domain/repositories/[feature]_repository_interface.dart

import 'package:efood_multivendor/interface/repository_interface.dart';
import 'package:get/get_connect/http/src/response/response.dart';

abstract class [Feature]RepositoryInterface extends RepositoryInterface {
  Future<Response> getList({DataSourceEnum? source});
  Future<Response> getDetails(String id);
  Future<Response> create(Map<String, dynamic> data);
  Future<Response> update(String id, Map<String, dynamic> data);
  Future<Response> delete(String id);
}
```

**Repository Implementation:**
```dart
// lib/features/[feature]/domain/repositories/[feature]_repository.dart

import 'package:efood_multivendor/api/api_client.dart';
import 'package:efood_multivendor/features/[feature]/domain/repositories/[feature]_repository_interface.dart';
import 'package:efood_multivendor/util/app_constants.dart';
import 'package:get/get.dart';

class [Feature]Repository implements [Feature]RepositoryInterface {
  final ApiClient apiClient;

  [Feature]Repository({required this.apiClient});

  @override
  Future<Response> getList({DataSourceEnum? source}) async {
    return await apiClient.getData(
      AppConstants.[feature]Uri,
      handleError: true,
      headers: _getCacheHeaders(source),
    );
  }

  @override
  Future<Response> getDetails(String id) async {
    return await apiClient.getData(
      '${AppConstants.[feature]DetailsUri}/$id',
      handleError: true,
    );
  }

  @override
  Future<Response> create(Map<String, dynamic> data) async {
    return await apiClient.postData(
      AppConstants.[feature]CreateUri,
      data,
      handleError: true,
    );
  }

  @override
  Future<Response> update(String id, Map<String, dynamic> data) async {
    return await apiClient.putData(
      '${AppConstants.[feature]UpdateUri}/$id',
      data,
      handleError: true,
    );
  }

  @override
  Future<Response> delete(String id) async {
    return await apiClient.deleteData(
      '${AppConstants.[feature]DeleteUri}/$id',
      handleError: true,
    );
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  // Private helper for cache headers
  Map<String, String>? _getCacheHeaders(DataSourceEnum? source) {
    switch (source) {
      case DataSourceEnum.client:
        return {'Content-Type': 'application/json; charset=UTF-8'};
      case DataSourceEnum.local:
        return {
          'Content-Type': 'application/json; charset=UTF-8',
          ApiClient.cacheControlHeader: 'only-if-cached',
        };
      default:
        return null;
    }
  }
}
```

### 3. API Client Methods

**GET Request:**
```dart
Response response = await apiClient.getData(
  AppConstants.[feature]Uri,
  handleError: true,  // Shows error snackbar automatically
  showToaster: false,  // Don't show success toast
  headers: {'Custom-Header': 'value'},
);
```

**GET with Query Parameters:**
```dart
Response response = await apiClient.getData(
  '${AppConstants.[feature]Uri}?offset=$offset&limit=$limit',
  handleError: true,
);
```

**POST Request:**
```dart
Map<String, dynamic> data = {
  'name': 'John',
  'email': 'john@example.com',
};

Response response = await apiClient.postData(
  AppConstants.[feature]CreateUri,
  data,
  handleError: true,
);
```

**POST Multipart (File Upload):**
```dart
import 'package:http/http.dart' as http;

Response response = await apiClient.postMultipartData(
  AppConstants.[feature]UploadUri,
  {
    'name': 'Product Name',
    'price': '29.99',
  },
  [
    MultipartBody('image', imageFile),  // File
    MultipartBody('thumbnail', thumbFile),
  ],
  handleError: true,
);
```

**PUT Request:**
```dart
Response response = await apiClient.putData(
  '${AppConstants.[feature]UpdateUri}/$id',
  {'name': 'Updated Name'},
  handleError: true,
);
```

**DELETE Request:**
```dart
Response response = await apiClient.deleteData(
  '${AppConstants.[feature]DeleteUri}/$id',
  handleError: true,
);
```

### 4. Response Handling

**Basic Response Handling:**
```dart
Future<void> fetchData() async {
  Response response = await repository.getList();

  if (response.statusCode == 200) {
    // Success
    _dataList = (response.body['data'] as List)
        .map((json) => DataModel.fromJson(json))
        .toList();
  } else {
    // Error already handled by ApiClient if handleError: true
  }
}
```

**With Model Parsing:**
```dart
Future<DataModel?> fetchData() async {
  Response response = await repository.getList();

  DataModel? model;
  if (response.statusCode == 200) {
    model = DataModel.fromJson(response.body);
  }
  return model;
}
```

**Pagination Response:**
```dart
Future<void> fetchList(int offset) async {
  Response response = await repository.getList(offset: offset);

  if (response.statusCode == 200) {
    _totalSize = response.body['total_size'];
    _offset = response.body['offset'];

    List<Item> items = (response.body['data'] as List)
        .map((json) => Item.fromJson(json))
        .toList();

    if (offset == 1) {
      _itemList = items;
    } else {
      _itemList?.addAll(items);
    }
  }
}
```

### 5. Caching Strategy

**Using DataSourceEnum:**
```dart
enum DataSourceEnum { client, local }

// Fetch from API (and cache)
Future<void> fetchFromApi() async {
  Response response = await repository.getList(
    source: DataSourceEnum.client,
  );
}

// Fetch from cache only
Future<void> fetchFromCache() async {
  Response response = await repository.getList(
    source: DataSourceEnum.local,
  );
}

// Fetch from API, fallback to cache
Future<void> fetchWithFallback() async {
  Response response = await repository.getList(
    source: DataSourceEnum.client,
  );

  if (response.statusCode != 200) {
    // Try cache
    response = await repository.getList(
      source: DataSourceEnum.local,
    );
  }
}
```

**Cache Headers:**
```dart
// Force fresh data from API
headers: {
  'Content-Type': 'application/json; charset=UTF-8',
  'Cache-Control': 'no-cache',
}

// Use cached data only
headers: {
  'Content-Type': 'application/json; charset=UTF-8',
  ApiClient.cacheControlHeader: 'only-if-cached',
}
```

### 6. Service Layer Integration

**Service Interface:**
```dart
// lib/features/[feature]/domain/services/[feature]_service_interface.dart

import 'package:get/get_connect/http/src/response/response.dart';

abstract class [Feature]ServiceInterface {
  Future<Response> get[Feature]List();
  Future<Response> get[Feature]Details(String id);
  Future<Response> create[Feature](Map<String, dynamic> data);
}
```

**Service Implementation:**
```dart
// lib/features/[feature]/domain/services/[feature]_service.dart

import 'package:efood_multivendor/features/[feature]/domain/repositories/[feature]_repository_interface.dart';
import 'package:efood_multivendor/features/[feature]/domain/services/[feature]_service_interface.dart';
import 'package:get/get.dart';

class [Feature]Service implements [Feature]ServiceInterface {
  final [Feature]RepositoryInterface [feature]Repository;

  [Feature]Service({required this.[feature]Repository});

  @override
  Future<Response> get[Feature]List() async {
    return await [feature]Repository.getList(source: DataSourceEnum.client);
  }

  @override
  Future<Response> get[Feature]Details(String id) async {
    return await [feature]Repository.getDetails(id);
  }

  @override
  Future<Response> create[Feature](Map<String, dynamic> data) async {
    // Add business logic validation here
    if (data['name']?.isEmpty ?? true) {
      return Response(statusCode: 400, statusText: 'Name is required');
    }

    return await [feature]Repository.create(data);
  }
}
```

### 7. Controller Integration

```dart
import 'package:get/get.dart';
import 'package:efood_multivendor/features/[feature]/domain/services/[feature]_service_interface.dart';

class [Feature]Controller extends GetxController implements GetxService {
  final [Feature]ServiceInterface [feature]Service;

  [Feature]Controller(this.[feature]Service);

  List<Item>? _itemList;
  List<Item>? get itemList => _itemList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> getItemList() async {
    _isLoading = true;
    update();

    Response response = await [feature]Service.get[Feature]List();

    if (response.statusCode == 200) {
      _itemList = (response.body['data'] as List)
          .map((json) => Item.fromJson(json))
          .toList();
    }

    _isLoading = false;
    update();
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    Response response = await [feature]Service.create[Feature](data);

    if (response.statusCode == 200) {
      showCustomSnackBar('Item created successfully', isError: false);
      getItemList(); // Refresh list
    }
  }
}
```

### 8. Error Handling

**ApiClient automatically handles errors when `handleError: true`:**
```dart
Response response = await apiClient.getData(
  url,
  handleError: true,  // Shows error snackbar
);
```

**Custom error handling:**
```dart
Response response = await apiClient.getData(
  url,
  handleError: false,  // Manual handling
);

if (response.statusCode == 200) {
  // Success
} else if (response.statusCode == 401) {
  // Unauthorized
  showCustomSnackBar('Please login', isError: true);
} else if (response.statusCode == 404) {
  // Not found
  showCustomSnackBar('Item not found', isError: true);
} else {
  // Other errors
  showCustomSnackBar(response.statusText ?? 'Error occurred', isError: true);
}
```

**Try-catch for network errors:**
```dart
try {
  Response response = await apiClient.getData(url);
  // Handle response
} catch (e) {
  showCustomSnackBar('Network error: $e', isError: true);
}
```

### 9. Authentication Headers

**ApiClient automatically includes:**
- Authorization header with bearer token
- Language code
- User location (lat/lng)
- Zone ID
- Custom app headers

**Access in repository:**
```dart
// Token automatically added by ApiClient
Response response = await apiClient.getData(
  AppConstants.protectedUri,
  handleError: true,
);

// apiClient handles:
// headers['Authorization'] = 'Bearer $token'
// headers['Accept-Language'] = currentLanguageCode
// etc.
```

### 10. API Request Examples

**List with Pagination:**
```dart
Future<Response> getRestaurantList(int offset, String type) async {
  return await apiClient.getData(
    '${AppConstants.restaurantUri}?offset=$offset&type=$type&limit=10',
    handleError: true,
  );
}
```

**Search:**
```dart
Future<Response> searchItems(String query) async {
  return await apiClient.getData(
    '${AppConstants.searchUri}?query=${Uri.encodeComponent(query)}',
    handleError: true,
  );
}
```

**Create with Form Data:**
```dart
Future<Response> createOrder(Map<String, String> data) async {
  return await apiClient.postData(
    AppConstants.placeOrderUri,
    data,
    handleError: true,
  );
}
```

**Update Profile with Image:**
```dart
Future<Response> updateProfile(
  Map<String, String> data,
  XFile? image,
) async {
  List<MultipartBody> multipartBody = [];
  if (image != null) {
    multipartBody.add(MultipartBody('image', image));
  }

  return await apiClient.postMultipartData(
    AppConstants.updateProfileUri,
    data,
    multipartBody,
    handleError: true,
  );
}
```

## Common Patterns

### Pattern: Reload with Cache Fallback
```dart
Future<void> getData(bool reload) async {
  if (reload) {
    _dataList = null;
  }

  if (_dataList == null) {
    _isLoading = true;
    update();

    // Try API first
    Response response = await service.getList();

    if (response.statusCode == 200) {
      _dataList = parseResponse(response);
    } else {
      // Fallback to cache
      response = await repository.getList(source: DataSourceEnum.local);
      if (response.statusCode == 200) {
        _dataList = parseResponse(response);
      }
    }

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
  if (!_hasMore || _isLoading) return;

  _isLoading = true;
  update();

  _offset++;
  Response response = await service.getList(offset: _offset);

  if (response.statusCode == 200) {
    List<Item> newItems = parseResponse(response);

    if (newItems.isEmpty) {
      _hasMore = false;
    } else {
      _itemList?.addAll(newItems);
    }
  }

  _isLoading = false;
  update();
}
```

### Pattern: Filter/Search
```dart
String _searchQuery = '';

Future<void> searchItems(String query) async {
  _searchQuery = query;
  _isLoading = true;
  update();

  Response response = await service.search(query);

  if (response.statusCode == 200) {
    _itemList = parseResponse(response);
  }

  _isLoading = false;
  update();
}
```

## Best Practices

1. **Always use AppConstants for endpoints**
   - Never hardcode URLs
   - Centralized endpoint management

2. **Follow repository pattern**
   - Repository handles API calls
   - Service handles business logic
   - Controller handles UI state

3. **Use handleError: true for user-facing calls**
   - Automatic error snackbars
   - Consistent error UX

4. **Implement caching where appropriate**
   - Use DataSourceEnum pattern
   - Provide offline experience

5. **Parse responses in controllers or services**
   - Don't pass raw Response objects to UI
   - Convert to models immediately

6. **Use proper HTTP methods**
   - GET for reading
   - POST for creating
   - PUT for updating
   - DELETE for deleting

7. **Handle loading states**
   - Set _isLoading before and after API calls
   - Call update() to rebuild UI

8. **Add query parameters safely**
   - Use Uri.encodeComponent() for user input
   - Prevent injection attacks

## Examples

**Add product search API:**
```
1. Add searchProductUri to AppConstants
2. Add search() method to ProductRepository
3. Add searchProducts() to ProductService
4. Add searchProducts() to ProductController
5. Call from search screen
```

**Implement order creation:**
```
1. Add placeOrderUri to AppConstants
2. Add create() to OrderRepository with postData
3. Add validateAndCreateOrder() to OrderService
4. Add placeOrder() to CheckoutController
5. Handle success/error in UI
```

## Troubleshooting

**401 Unauthorized:**
- Check if token is valid
- Verify AuthController.isLoggedIn()
- Token automatically added by ApiClient

**Network error:**
- Check internet connection
- Verify API endpoint is correct
- Check base URL in environment config

**Null response:**
- Add null checks: `response.body?['data']`
- Verify API returns expected structure

**Cache not working:**
- Ensure headers include cacheControlHeader
- Check ApiClient cache implementation
