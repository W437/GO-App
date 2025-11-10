# Google Maps API SHA-1 Certificate Configuration

## Current SHA-1 Certificate Fingerprint (Debug)

```
99:A5:F3:C3:07:76:33:B2:7E:88:4B:ED:D4:24:33:F1:94:AD:F1:61
```

## Package Name

```
com.hopa.user
```

## Current Google Maps API Key

```
AIzaSyDOLhHbuoKsj4qrcM8jRhP4evXgljDQW94
```

**Configured in:**
- Android: `android/app/src/main/AndroidManifest.xml` (line 38)
- iOS: `ios/Runner/AppDelegate.swift` (line 13)

## Configuration Steps

1. **Google Maps Console Configuration:**
   - Package name: `com.hopa.user`
   - SHA-1 certificate fingerprint: `99:A5:F3:C3:07:76:33:B2:7E:88:4B:ED:D4:24:33:F1:94:AD:F1:61`

2. **Important Note:**
   - This SHA-1 is from your debug keystore
   - Valid for development and testing
   - Currently being used for both debug and release builds (as per build.gradle configuration)

## How to Get SHA-1 Certificates

### For Debug Certificate (Current):
```bash
cd android
./gradlew signingReport
```

### For Release Certificate (When needed):

1. **Generate a release keystore:**
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. **Get SHA-1 from release keystore:**
```bash
keytool -list -v -keystore ~/key.jks -alias key
```

3. **Create key.properties file in android folder:**
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=key
storeFile=/Users/[your-username]/key.jks
```

4. **Update android/app/build.gradle:**
Change line 73 from:
```gradle
signingConfig signingConfigs.debug
```
To:
```gradle
signingConfig signingConfigs.release
```

## Multiple SHA-1 Certificates

Google Maps API allows multiple SHA-1 certificates for the same package name. This means you can add:
- Debug SHA-1 (for development)
- Release SHA-1 (for production)
- CI/CD SHA-1 (if using continuous integration)

## Current Build Configuration Status

- **Package Name:** `com.hopa.user`
- **Application ID:** `com.hopa.user`
- **Signing Config:** Debug keys for both debug and release builds
- **Certificate Valid Until:** Friday, 25 June 2055

## Troubleshooting

If Google Maps doesn't work in your app:

1. **Verify package name matches exactly:** `com.hopa.user`
2. **Ensure SHA-1 is copied correctly** (including colons)
3. **Check API key restrictions** in Google Cloud Console
4. **Enable required Google Maps APIs:**
   - Maps SDK for Android
   - Places API (if using places)
   - Directions API (if using directions)
   - Geocoding API (if using geocoding)

## Security Note

- Never commit `key.properties` or keystore files to version control
- Keep production keystore files backed up securely
- Use different API keys for debug and production if possible

---

*Last Updated: November 10, 2025*