# iOS Authentication Setup

## Google Sign-In Configuration

**Status:** Currently commented out in `ios/Runner/Info.plist` (line 32-33)

### To Enable Google Sign-In on iOS:

1. **Get Google OAuth iOS Client ID:**
   - Go to https://console.cloud.google.com
   - Select your project
   - Navigate to: APIs & Services → Credentials
   - Find or create an iOS OAuth 2.0 Client ID
   - Copy the client ID (format: `123456789-abcdefg.apps.googleusercontent.com`)

2. **Update Info.plist:**
   - Open `ios/Runner/Info.plist`
   - Uncomment line 33:
     ```xml
     <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
     ```
   - Replace `YOUR_CLIENT_ID` with the part before `.apps.googleusercontent.com`
   - Example: If your client ID is `123456789-abcdefg.apps.googleusercontent.com`
   - The URL scheme should be: `com.googleusercontent.apps.123456789-abcdefg`

3. **Rebuild the IPA:**
   ```bash
   flutter build ipa --release
   ```

4. **Enable in Backend:**
   - Ensure Google Sign-In is enabled in your backend configuration

## Facebook Sign-In

**Status:** Active and configured

- Facebook App ID: `452131619626499`
- URL Scheme: `fb452131619626499`
- Location: `ios/Runner/Info.plist` lines 32, 38-44

## Apple Sign-In

Apple Sign-In is automatically available for iOS 13+ and doesn't require additional URL scheme configuration.

## Notes

- If a sign-in method is disabled in the backend, you can leave the iOS configuration in place (it won't cause issues)
- Invalid URL schemes (like placeholders) will cause App Store validation to fail
- When in doubt, comment out unused URL schemes rather than deleting them
