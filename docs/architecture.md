# GO Multivendor - Architecture Documentation

## Project Overview
GO Multivendor is a Flutter-based food delivery application supporting multiple vendors, built with a modular architecture pattern. The app provides a comprehensive platform for ordering food from various restaurants with features like cart management, order tracking, user authentication, real-time notifications, gamification, advanced exploration with maps and voice search, and story-based promotions.

## Architecture Pattern
The project follows a **Feature-Based Clean Architecture** with clear separation of concerns:

### Core Layers
1. **API Layer** (`/lib/api/`) - HTTP communication and data management
   - `api_client.dart` - REST API client for server communication
   - `local_client.dart` - Local data caching and offline storage
   - `api_checker.dart` - API response validation and error handling

2. **Data Source Layer** (`/lib/data_source/`) - Local caching infrastructure
   - `cache_response.dart` - Cache response models using Drift ORM
   - Implements offline-first architecture with local persistence

3. **Feature Layer** (`/lib/features/`) - Business logic organized by features
   - 37 feature modules with self-contained functionality
   - Each feature contains controllers, screens, domain models, and widgets

4. **Helper Layer** (`/lib/helper/`) - Utility functions and dependency injection
   - 23+ helper modules for cross-cutting concerns
   - Includes DI container (`get_di.dart`), routing, validation, and converters

5. **Common Layer** (`/lib/common/`) - Shared components
   - `widgets/` - 40+ reusable UI components
   - `models/` - Shared data models
   - `enums/` - Application-wide enumerations

6. **Configuration Layer** (`/lib/config/`) - App environment configuration
   - `environment.dart` - Environment-specific settings

7. **Utilities Layer** (`/lib/util/`) - Constants and resources
   - App constants, dimensions, color palettes, images, styles, and messages

8. **Interface Layer** (`/lib/interface/`) - Repository abstractions
   - `repository_interface.dart` - Generic repository pattern interface

## Feature Modules
The application is organized into **37 feature modules**, each containing:
- **Controllers** - Business logic and state management (GetX)
- **Screens** - UI components and page layouts
- **Domain/Models** - Data models and entities
- **Domain/Repositories** - Data access interfaces
- **Widgets** - Feature-specific reusable components

### Complete Feature List
1. **Address** - Location and delivery address management
2. **Auth** - User authentication and authorization (Google, Facebook, Apple)
3. **Business** - Business/restaurant registration and management
4. **Cart** - Shopping cart functionality with item management
5. **Category** - Food category management and filtering
6. **Chat** - Customer support messaging with emoji support
7. **Checkout** - Order placement, payment processing, and scheduling
8. **Coupon** - Discount codes and promotional offers
9. **Cuisine** - Cuisine type filtering and preferences
10. **Dashboard** - Main navigation hub with bottom navigation
11. **Dine In** - Table booking and in-restaurant dining services
12. **Explore** - Advanced restaurant exploration with map view, filters, and voice search
13. **Favourite** - User favorites and wishlist management
14. **Game** - Gamification with Flappy Bird mini-game for rewards
15. **Home** - Main landing page with featured content and carousels
16. **HTML** - Static content pages and webview integration
17. **Interest** - User preference tracking and personalization
18. **Language** - Multi-language support (English, Arabic, Hebrew, Russian)
19. **Location** - GPS services, location picker, and address autocomplete
20. **Loyalty** - Rewards program and loyalty points system
21. **Menu** - Restaurant menu display with categories
22. **Notification** - Push notifications and in-app alerts
23. **Onboard** - App introduction, tutorial, and first-time setup
24. **Order** - Order management, tracking, and history
25. **Product** - Food item details, variants, addons, and customization
26. **Profile** - User profile management and settings
27. **Refer and Earn** - Referral program with sharing capabilities
28. **Restaurant** - Restaurant listings, details, and reviews
29. **Review** - Rating and review system for restaurants and food
30. **Search** - Food and restaurant search with filters
31. **Splash** - App initialization, loading, and configuration
32. **Story** - Instagram-style stories feature for promotions
33. **Support** - Customer service and help center
34. **Update** - App version management and forced updates
35. **Verification** - Account verification (phone, email, OTP)
36. **Wallet** - Digital wallet, payment methods, and transaction history

### New & Enhanced Features
- **Game Module**: Flappy Bird mini-game with custom assets and sound effects for user engagement
- **Explore Module**: Advanced map-based restaurant discovery with category filters, voice search capabilities
- **Story Module**: Instagram-style story viewing for restaurant promotions and deals

## Technology Stack

### Frontend Framework
- **Flutter** (SDK ^3.4.4) - Cross-platform mobile framework
- **Dart** - Programming language
- **GetX** (^4.6.6) - State management, routing, and dependency injection

### Backend Integration
- **HTTP** (^1.2.2) - REST API communication
- **Firebase Core** (^3.8.0) - Backend services integration
- **Firebase Messaging** (^15.1.5) - Push notifications
- **Firebase Auth** (^5.3.1) - User authentication

### Database & Storage
- **Drift** (^2.21.0) + Drift Flutter - Local SQLite database ORM with type-safe queries
- **SharedPreferences** (^2.3.4) - Local key-value storage
- **Path Provider** (^2.1.4) - File system access
- **Local Caching** - Offline-first data persistence

### Location & Maps
- **Geolocator** (^13.0.1) - GPS location services and permissions
- **Google Maps Flutter** (^2.9.0) - Interactive maps for Android/iOS
- **Google Maps Flutter Web** (^0.5.10) - Web map support
- **Location** (^7.0.0) - Additional location services
- **Custom Map Markers** (^0.0.2+1) - Custom marker support

### UI Components & Animations
- **Material Design** - Primary UI framework
- **Cupertino Icons** (^1.0.8) - iOS-style icons
- **Cached Network Image** (^3.4.1) - Optimized image loading with caching
- **Shimmer Animation** (^2.2.1) - Loading placeholders
- **Carousel Slider** (^5.0.0) - Image/content carousels
- **Card Swiper** (^3.0.1) - Card-based swiping UI
- **Lottie** (^3.1.0) - JSON-based animations
- **Flutter SVG** (^2.0.10+1) - SVG rendering
- **Photo View** (^0.15.0) - Image zoom and pan
- **Smooth Page Indicator** (^1.2.0+3) - Page indicators
- **Animated Flip Counter** (^0.3.4) - Number animations
- **Marquee** (^2.2.3) - Scrolling text
- **Expandable Bottom Sheet** (^1.1.1+1) - Draggable sheets

### Authentication & Social
- **Google Sign In** (^6.2.1) + Web (^0.12.4+2) - Google OAuth
- **Flutter Facebook Auth** (^6.0.4) - Facebook login
- **Sign In with Apple** (^6.1.1) - Apple ID authentication
- **Phone Numbers Parser** (^9.0.1) - Phone validation
- **Country Code Picker** (^3.0.0) - Country selection

### Media & Files
- **Image Picker** (^1.1.2) - Camera/gallery access
- **File Picker** (^8.1.2) - File selection
- **Video Player** (^2.9.3) + Chewie (^1.11.0) - Video playback
- **Get Thumbnail Video** (^0.7.3) - Video thumbnails
- **Audioplayers** (^6.0.0) - Audio playback for game sounds

### Communication & Input
- **Flutter Local Notifications** (^17.2.3) - Local push notifications
- **Speech to Text** (^7.0.0) - Voice search and input
- **Emoji Picker Flutter** (^2.2.0) - Emoji selector for chat
- **URL Launcher** (^6.3.0) - Deep linking and external URLs
- **Share Plus** (^10.0.2) - Native sharing

### UI Utilities
- **Pin Code Fields** (^8.0.1) - OTP input
- **Dotted Border** (^2.1.0) - Decorative borders
- **Flutter Slidable** (^3.1.2) - Swipe actions
- **Just The Tooltip** (^0.0.12) - Tooltips
- **Flex Color Picker** (^3.5.1) - Color selection
- **Syncfusion Flutter Datepicker** (^27.1.51) - Advanced date picker
- **Pointer Interceptor** (^0.10.1+2) - Web pointer events

### Web & HTML
- **Universal HTML** (^2.2.4) - Cross-platform HTML
- **Flutter Inappwebview** (^6.1.4) - Webview integration
- **Flutter Widget from HTML Core** (^0.15.2) - HTML rendering
- **Meta SEO** (^3.0.9) - Web SEO optimization
- **URL Strategy** (^0.3.0) - Web URL handling

### Utilities
- **Connectivity Plus** (^6.0.5) - Network connectivity monitoring
- **Permission Handler** (^11.3.1) - Runtime permissions
- **Intl** (^0.19.0) - Internationalization and formatting
- **Path** (^1.9.0) - File path manipulation
- **HTTP Parser** (^4.1.0) - HTTP utilities
- **Flutter Dotenv** (^5.1.0) - Environment variables
- **Custom Info Window** (^1.0.1) - Map info windows

## Data Flow
1. **UI Layer** triggers actions through controllers
2. **Controllers** manage state using GetX reactive programming
3. **Repository Pattern** abstracts data sources
4. **API Client** handles HTTP requests with authentication
5. **Local Client** manages offline caching
6. **Database** provides persistent storage

## File Organization
```
lib/
├── api/                    # HTTP client and API utilities
│   ├── api_client.dart     # REST API client
│   ├── local_client.dart   # Local cache client
│   └── api_checker.dart    # API validation
├── common/                 # Shared components
│   ├── enums/             # App-wide enumerations
│   ├── models/            # Shared data models
│   └── widgets/           # 40+ reusable UI components
├── config/                 # Configuration
│   └── environment.dart    # Environment settings
├── data_source/            # Local caching infrastructure
│   ├── cache_response.dart # Drift cache models
│   └── cache_response.g.dart
├── features/               # 37 feature modules
│   ├── address/
│   ├── auth/
│   ├── business/
│   ├── cart/
│   ├── category/
│   ├── chat/
│   ├── checkout/
│   ├── coupon/
│   ├── cuisine/
│   ├── dashboard/
│   ├── dine_in/
│   ├── explore/           # Map view, filters, voice search
│   ├── favourite/
│   ├── game/              # Flappy Bird mini-game
│   ├── home/
│   ├── html/
│   ├── interest/
│   ├── language/
│   ├── location/
│   ├── loyalty/
│   ├── menu/
│   ├── notification/
│   ├── onboard/
│   ├── order/
│   ├── product/
│   ├── profile/
│   ├── refer and earn/
│   ├── restaurant/
│   ├── review/
│   ├── search/
│   ├── splash/
│   ├── story/             # Instagram-style stories
│   ├── support/
│   ├── update/
│   ├── verification/
│   └── wallet/
│   └── [each feature contains]
│       ├── controllers/   # GetX state management
│       ├── domain/        # Models and repositories
│       ├── screens/       # UI pages
│       └── widgets/       # Feature-specific widgets
├── helper/                # Utilities and helpers
│   ├── get_di.dart        # Dependency injection
│   ├── route_helper.dart  # App routing
│   ├── auth_helper.dart
│   ├── cart_helper.dart
│   ├── checkout_helper.dart
│   ├── db_helper.dart
│   ├── notification_helper.dart
│   └── [20+ other helpers]
├── interface/             # Repository abstractions
│   └── repository_interface.dart
├── theme/                 # App theming
├── util/                  # Constants and resources
│   ├── app_constants.dart
│   ├── color_palette.dart
│   ├── dimensions.dart
│   ├── images.dart
│   ├── messages.dart
│   └── styles.dart
└── main.dart             # Application entry point

assets/
├── game/                  # Game assets
│   ├── assets/           # Graphics (bird, pipes, background)
│   └── sfx/              # Sound effects
├── image/                # Image assets (22+ categories)
├── language/             # i18n translations (ar, en, he, ru)
├── *.json                # Lottie animations
└── .env                  # Environment variables
```

## Configuration Files
- **pubspec.yaml** - Dependencies and app configuration (80+ packages)
- **analysis_options.yaml** - Code quality rules and linting
- **firebase_options.dart** - Firebase configuration
- **.env** - Environment variables (API keys, endpoints)
- **devtools_options.yaml** - Development tools settings

## Platform Support
- **Android** - Native Android support
- **iOS** - Native iOS support  
- **Web** - Progressive Web App capabilities

## Key Design Decisions

### Architectural Principles
1. **Feature-Based Modularity** - 37 self-contained feature modules
   - Each feature has its own controllers, screens, models, repositories, and widgets
   - Enables parallel development and easier maintenance
   - Clear domain boundaries reduce coupling

2. **GetX State Management** - Reactive programming with minimal boilerplate
   - Centralized dependency injection via `get_di.dart`
   - Route management through `route_helper.dart`
   - Reactive state updates without StatefulWidgets
   - Built-in navigation and snackbar handling

3. **Repository Pattern** - Abstracted data access layer
   - Generic `RepositoryInterface` for consistency
   - Separation between API and local data sources
   - Enables easy testing and mocking

4. **Clean Architecture** - Separation of concerns
   - Domain layer (models, repositories)
   - Presentation layer (screens, widgets, controllers)
   - Data layer (API client, local cache)

5. **Offline-First Strategy** - Local caching with API fallback
   - Drift ORM for structured local database
   - SharedPreferences for simple key-value storage
   - Cache invalidation and sync strategies

6. **Multi-Platform Support** - Single codebase for mobile and web
   - Platform-specific implementations for maps, authentication
   - Web-specific packages (google_maps_flutter_web, google_sign_in_web)
   - Responsive design helpers

### Key Technical Choices
- **Lottie Animations** - Used for loading states, empty screens, and engagement
- **Voice Search** - Speech-to-text integration in explore feature
- **Gamification** - Custom-built Flappy Bird game using Flutter's Canvas API
- **Stories Feature** - Instagram-style promotions for restaurants
- **Advanced Maps** - Custom markers, clustering, and interactive overlays
- **Multi-Language** - Support for RTL (Arabic, Hebrew) and LTR (English, Russian)

### Helper Utilities (23+ modules)
Critical helpers that support cross-cutting concerns:
- **get_di.dart** - Dependency injection container
- **route_helper.dart** - Centralized routing
- **db_helper.dart** - Database operations
- **auth_helper.dart** - Authentication state
- **cart_helper.dart** - Cart calculations
- **checkout_helper.dart** - Order processing
- **notification_helper.dart** - Push notification handling
- **responsive_helper.dart** - Responsive layouts
- **date_converter.dart** - Date formatting
- **price_converter.dart** - Currency formatting
- **custom_validator.dart** - Form validation
- **extensions.dart** - Dart extensions