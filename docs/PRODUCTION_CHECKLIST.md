# Production Release Checklist for Hopa App

## ⚠️ CRITICAL - Security & Signing

### 1. **REPLACE UNRESTRICTED GOOGLE MAPS API KEY** ⚠️
   - [ ] **Currently using unrestricted API key for development** (Application restrictions: None)
   - [ ] **MUST create separate restricted keys before release:**

   **Android Production Key:**
   - [ ] Create new Android-restricted API key in Google Cloud Console
   - [ ] Restriction type: Android apps
   - [ ] Package name: `com.hopa.user`
   - [ ] Generate production keystore: `keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key`
   - [ ] Extract production SHA-1: `keytool -list -v -keystore ~/key.jks -alias key`
   - [ ] Add production SHA-1 to Android API key restrictions
   - [ ] Enable: Maps SDK for Android
   - [ ] Update key in `android/app/src/main/AndroidManifest.xml`

   **iOS Production Key:**
   - [ ] Create new iOS-restricted API key in Google Cloud Console
   - [ ] Restriction type: iOS apps
   - [ ] Bundle ID: `com.hopa.user`
   - [ ] Enable: Maps SDK for iOS
   - [ ] Update key in `ios/Runner/AppDelegate.swift`

   - [ ] Current debug SHA-1: `99:A5:F3:C3:07:76:33:B2:7E:88:4B:ED:D4:24:33:F1:94:AD:F1:61`
   - [ ] Reference: `/android/SHA1_CERTIFICATE_INFO.md`

### 2. **App Signing Configuration**
   - [ ] Create production keystore: `keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key`
   - [ ] Create `android/key.properties` file with keystore credentials
   - [ ] Update `android/app/build.gradle` line 73 from `signingConfigs.debug` to `signingConfigs.release`
   - [ ] Backup keystore file securely (CRITICAL - losing this means you can't update your app)
   - [ ] Never commit keystore or key.properties to Git

## 📱 App Configuration

### 3. **Version & Build Numbers**
   - [ ] Update version in `pubspec.yaml` (e.g., 1.0.0+1)
   - [ ] Ensure version code is incremented for Play Store

### 4. **App Identity**
   - [ ] Verify package name: `com.hopa.user`
   - [ ] Update app name if needed
   - [ ] Update app icons for all densities
   - [ ] Update splash screen

### 5. **API Configuration**
   - [ ] Update base URL to production server (currently: 138.197.188.120)
   - [ ] Remove all debug/development API endpoints
   - [ ] Ensure all API keys are production keys
   - [ ] Enable API rate limiting and security

## 🔥 Firebase Configuration

### 6. **Firebase Setup**
   - [ ] Download production `google-services.json` from Firebase Console
   - [ ] Place in `android/app/` directory
   - [ ] Uncomment Firebase plugins in `android/app/build.gradle`:
     ```gradle
     id "com.google.gms.google-services"
     id "com.google.firebase.crashlytics"
     ```
   - [ ] Configure Firebase Cloud Messaging for production
   - [ ] Set up Crashlytics for production error tracking

## 🧪 Testing

### 7. **Pre-Release Testing**
   - [ ] Run `flutter analyze` - fix all issues
   - [ ] Run `flutter test` - ensure all tests pass
   - [ ] Test on physical devices (not just emulators)
   - [ ] Test on different Android versions (minimum API level to latest)
   - [ ] Test all critical user flows:
     - [ ] User registration/login
     - [ ] Restaurant browsing
     - [ ] Order placement
     - [ ] Payment processing
     - [ ] Delivery tracking
     - [ ] Chat functionality

### 8. **Performance**
   - [ ] Run in release mode: `flutter run --release`
   - [ ] Check app size: `flutter build apk --analyze-size`
   - [ ] Profile performance for lag/jank
   - [ ] Optimize images and assets

## 🚀 Build & Deploy

### 9. **Build Generation**
   - [ ] Clean build: `flutter clean`
   - [ ] Get dependencies: `flutter pub get`
   - [ ] Build AAB for Play Store: `flutter build appbundle --release`
   - [ ] Build APK for testing: `flutter build apk --release`

### 10. **Google Play Console**
   - [ ] Create app listing
   - [ ] Add app description, screenshots, feature graphic
   - [ ] Set up pricing and distribution
   - [ ] Configure content rating
   - [ ] Set up app signing by Google Play
   - [ ] Upload AAB file
   - [ ] Complete store listing questionnaire

## 🔒 Security Checklist

### 11. **Security Review**
   - [ ] Remove all console.log/print statements
   - [ ] Disable debugging tools
   - [ ] Enable ProGuard/R8 for code obfuscation
   - [ ] Review all permissions in AndroidManifest.xml
   - [ ] Ensure HTTPS is used for all network requests
   - [ ] Implement certificate pinning for critical APIs
   - [ ] Remove any hardcoded secrets/API keys

## 📋 Legal & Compliance

### 12. **Legal Requirements**
   - [ ] Privacy Policy URL active and updated
   - [ ] Terms of Service URL active and updated
   - [ ] GDPR compliance (if applicable)
   - [ ] Data deletion policy implemented
   - [ ] Age restrictions configured properly

## 🔄 Post-Release

### 13. **After Publishing**
   - [ ] Monitor Crashlytics for errors
   - [ ] Check Play Console for user feedback
   - [ ] Set up release notes for updates
   - [ ] Plan regular update schedule
   - [ ] Keep keystore backup in multiple secure locations

## 📝 Important Notes

- **NEVER** lose your production keystore - you won't be able to update your app
- Always test the release build on real devices before publishing
- Keep SHA-1 certificates updated in all third-party services (Google Maps, Firebase, etc.)
- Consider using Google Play's app signing for additional security

## 🚨 Emergency Contacts

- Google Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com
- Google Cloud Console: https://console.cloud.google.com

---

*Last Updated: November 10, 2025*
*Critical Item: SHA-1 certificate MUST be updated for production*