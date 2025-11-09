import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration class that manages all app environment variables
/// Provides type-safe access to configuration values from .env file
class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  /// Initialize environment variables from .env file
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  // API Configuration
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get webHostedUrl => dotenv.env['WEB_HOSTED_URL'] ?? '';

  // Firebase Configuration
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? 'AIzaSyCc3OCd5I2xSlnftZ4bFAbuCzMhgQHLivA';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '1:491987943015:android:fe79b69339834d5c8f1ec2';
  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '491987943015';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? 'stackmart-500c7';

  // Facebook Configuration
  static String get facebookAppId => dotenv.env['FACEBOOK_APP_ID'] ?? '452131619626499';

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Hopa!';
  static double get appVersion => double.tryParse(dotenv.env['APP_VERSION'] ?? '8.3') ?? 8.3;
  static String get yourScheme => dotenv.env['YOUR_SCHEME'] ?? 'Hopa';
  static String get yourHost => dotenv.env['YOUR_HOST'] ?? 'hopa.delivery';

  // Google Maps Configuration
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Check if running in development mode
  static bool get isDevelopment => baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');

  /// Check if running in production mode
  static bool get isProduction => !isDevelopment;
}