# API Key Authentication Implementation

**Date**: 2025-01-21
**Status**: ✅ Complete

## Summary

Added X-API-Key header authentication to all API requests as required by the backend.

---

## Changes Made

### 1. Environment Configuration (`lib/config/environment.dart`)

**Added API key getter:**
```dart
// API Authentication
static String get apiKey => dotenv.env['API_KEY'] ?? '';
```

**Location**: Line 36-37

This reads the API key from `.env` file where it's defined as:
```
API_KEY='uaP5scKlFAXtDBtj5a8DB40LO2vqJfsvh22EuERUfOg='
```

---

### 2. API Client (`lib/api/api_client.dart`)

**Added import:**
```dart
import 'package:godelivery_user/config/environment.dart';
```

**Location**: Line 8

**Updated `updateHeader()` method:**
```dart
Map<String, String> header = {};
header.addAll({
  'Content-Type': 'application/json; charset=UTF-8',
  'X-API-Key': Environment.apiKey,  // ← ADDED THIS LINE
  AppConstants.zoneId: zoneIDs != null ? jsonEncode(zoneIDs) : '',
  AppConstants.localizationKey: languageCode ?? AppConstants.languages[0].languageCode!,
  AppConstants.latitude: latitude ?? '',
  AppConstants.longitude: longitude ?? '',
  'Authorization': 'Bearer $token'
});
```

**Location**: Line 48-63

---

## How It Works

### Request Flow:

1. **App Initialization**
   - `.env` file is loaded via `Environment.init()`
   - API key is read from environment variables

2. **ApiClient Initialization**
   - `ApiClient` constructor calls `updateHeader()`
   - `updateHeader()` creates headers map with X-API-Key from `Environment.apiKey`
   - Headers stored in `_mainHeaders`

3. **Every API Request**
   - All methods (`getData`, `postData`, `putData`, `deleteData`, `postMultipartData`)
   - Use `_mainHeaders` which includes X-API-Key
   - Header sent with every request automatically

### Example Request Headers:
```
Content-Type: application/json; charset=UTF-8
X-API-Key: uaP5scKlFAXtDBtj5a8DB40LO2vqJfsvh22EuERUfOg=
zoneId: [1]
X-localization: en
latitude: 32.977340
longitude: 35.153717
Authorization: Bearer <token>
```

---

## Coverage

### ✅ All API Requests Include X-API-Key:

- **GET requests** - `getData()`
- **POST requests** - `postData()`
- **PUT requests** - `putData()`
- **DELETE requests** - `deleteData()`
- **Multipart uploads** - `postMultipartData()`

### ✅ All Features Covered:

- Config fetching (startup)
- User authentication (login/signup)
- Restaurant browsing
- Product browsing
- Cart operations
- Order placement
- Profile management
- Address management
- All other features using ApiClient

### ℹ️ Not Affected (No Changes Needed):

- **NotificationHelper** - Downloads images from external URLs
- **ChatController** - Downloads PDFs from storage URLs
- **LocalClient** - Only handles local caching, no HTTP requests

---

## Testing Checklist

Run through these scenarios to verify everything works:

### 1. App Launch
- [ ] App launches without crashes
- [ ] Config loads successfully
- [ ] No 401 errors in console
- [ ] Home screen displays restaurants

### 2. Browse Features
- [ ] Browse restaurants
- [ ] View restaurant details
- [ ] Browse products/menu items
- [ ] View product details

### 3. Authentication
- [ ] Guest login works
- [ ] User login works
- [ ] User registration works
- [ ] OTP verification works

### 4. Cart & Checkout
- [ ] Add items to cart
- [ ] View cart
- [ ] Proceed to checkout
- [ ] Place order

### 5. Profile Features
- [ ] View profile
- [ ] Edit profile
- [ ] Manage addresses
- [ ] View order history

### 6. Console Verification
- [ ] No "401 Unauthorized" errors
- [ ] No "API key required" errors
- [ ] All API calls return 200 OK

---

## Verification Commands

### Check if API key is in .env:
```bash
grep API_KEY .env
```

**Expected output:**
```
API_KEY='uaP5scKlFAXtDBtj5a8DB40LO2vqJfsvh22EuERUfOg='
```

### Check API requests in logs:
When running the app, you should see in console:
```
====> API Call: /api/v1/config
Header: {Content-Type: application/json; charset=UTF-8, X-API-Key: uaP5scKlFAXtDBtj5a8DB40LO2vqJfsvh22EuERUfOg=, ...}
====> API Response: [200] /api/v1/config
```

Look for:
- ✅ `X-API-Key: uaP5scKlFAXtDBtj5a8DB40LO2vqJfsvh22EuERUfOg=` in headers
- ✅ `[200]` status codes
- ❌ NO `[401]` status codes

---

## Troubleshooting

### Issue: Still getting 401 errors

**Possible causes:**
1. `.env` file not loaded
   - **Fix**: Ensure `Environment.init()` is called in `main.dart` before `runApp()`

2. Wrong API key value
   - **Fix**: Verify `.env` has correct `API_KEY` value from backend team

3. Header not being sent
   - **Fix**: Check console logs to verify `X-API-Key` appears in request headers

### Issue: App crashes on startup

**Possible cause**: Environment variable not found

**Fix**: Add fallback in `environment.dart`:
```dart
static String get apiKey => dotenv.env['API_KEY'] ?? 'default-key-here';
```

### Issue: Some requests work, others don't

**Possible cause**: Some code bypassing ApiClient

**Solution**: Search for direct `http.get()`, `http.post()` calls:
```bash
grep -r "http\.(get|post|put|delete)" lib/ --exclude-dir={api,chat,notification}
```

All API calls should go through `ApiClient`.

---

## Security Notes

⚠️ **Important:**
- The API key is stored in `.env` which is in `.gitignore`
- Never commit `.env` file to version control
- Never hardcode API keys in source code
- API key is client-side - still use server-side authentication (JWT tokens) for user-specific actions

---

## Backend Requirements

Ensure your backend accepts the X-API-Key header:

**Expected header:**
```
X-API-Key: uaP5scKlFAXtDBtj5a8DB40LO2vqJfsvh22EuERUfOg=
```

**Backend should:**
- Check for presence of X-API-Key header
- Validate key matches server-side value
- Return 401 if missing or invalid
- Return 200 and process request if valid

---

## Rollback Instructions

If you need to remove API key authentication:

1. **Remove from Environment:**
   ```dart
   // Delete lines 36-37 in lib/config/environment.dart
   ```

2. **Remove from ApiClient:**
   ```dart
   // Delete line 52 in lib/api/api_client.dart:
   'X-API-Key': Environment.apiKey,
   ```

3. **Remove import:**
   ```dart
   // Delete line 8 in lib/api/api_client.dart:
   import 'package:godelivery_user/config/environment.dart';
   ```

---

## Related Files

**Modified:**
- `lib/config/environment.dart` - Added apiKey getter
- `lib/api/api_client.dart` - Added X-API-Key header to all requests

**Unchanged but relevant:**
- `.env` - Contains API_KEY value
- `lib/api/local_client.dart` - Caching only, no HTTP
- `lib/helper/utilities/notification_helper.dart` - External URL downloads
- `lib/features/chat/controllers/chat_controller.dart` - External file downloads

---

**Implementation complete! Test the app now - all API requests will include the X-API-Key header.** ✅
