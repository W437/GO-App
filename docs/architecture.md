# GO Multivendor - Architecture Documentation

## Project Overview
GO Multivendor is a Flutter-based food delivery application supporting multiple vendors, built with a modular architecture pattern. The app provides a comprehensive platform for ordering food from various restaurants with features like cart management, order tracking, user authentication, and real-time notifications.

## Architecture Pattern
The project follows a **Feature-Based Clean Architecture** with clear separation of concerns:

### Core Layers
1. **API Layer** (`/lib/api/`) - HTTP communication and data fetching
2. **Data Source Layer** (`/lib/data_source/`) - Local caching and data persistence
3. **Feature Layer** (`/lib/features/`) - Business logic organized by features
4. **Helper Layer** (`/lib/helper/`) - Utility functions and dependency injection
5. **Common Layer** (`/lib/common/`) - Shared widgets and components

## Feature Modules
The application is organized into 34 feature modules, each containing:
- **Controllers** - Business logic and state management (GetX)
- **Screens** - UI components and page layouts
- **Domain/Models** - Data models and entities
- **Domain/Repositories** - Data access interfaces

### Feature List
- **Address** - Location and delivery address management
- **Auth** - User authentication and authorization
- **Business** - Business/restaurant registration and management
- **Cart** - Shopping cart functionality
- **Category** - Food category management
- **Chat** - Customer support messaging
- **Checkout** - Order placement and payment
- **Coupon** - Discount and coupon system
- **Cuisine** - Cuisine type filtering
- **Dashboard** - Main navigation hub
- **Dine In** - Table booking and dine-in services
- **Favourite** - User favorites management
- **Home** - Main landing page and featured content
- **HTML** - Static content pages
- **Interest** - User preference tracking
- **Language** - Multi-language support
- **Location** - GPS and location services
- **Loyalty** - Rewards and loyalty program
- **Menu** - Restaurant menu display
- **Notification** - Push notifications and alerts
- **Onboard** - App introduction and setup
- **Order** - Order management and tracking
- **Product** - Food item details and variants
- **Profile** - User profile management
- **Refer and Earn** - Referral program
- **Restaurant** - Restaurant listings and details
- **Review** - Rating and review system
- **Search** - Food and restaurant search
- **Splash** - App initialization and loading
- **Support** - Customer service
- **Update** - App version management
- **Verification** - Account verification
- **Wallet** - Digital wallet and payment

## Technology Stack

### Frontend
- **Flutter** (3.4.4) - Cross-platform mobile framework
- **GetX** - State management and dependency injection
- **Dart** - Programming language

### Backend Integration
- **HTTP** - REST API communication
- **Firebase Core** - Backend services integration
- **Firebase Messaging** - Push notifications
- **Firebase Auth** - User authentication

### Database & Storage
- **Drift** - Local SQLite database ORM
- **SharedPreferences** - Local key-value storage
- **Local Caching** - Offline data persistence

### Location & Maps
- **Geolocator** - GPS location services
- **Google Maps Flutter** - Interactive maps

### UI Components
- **Material Design** - UI framework
- **Cached Network Image** - Optimized image loading
- **Shimmer Animation** - Loading placeholders
- **Carousel Slider** - Image carousels

### Authentication
- **Google Sign In** - Google OAuth
- **Facebook Auth** - Facebook login
- **Apple Sign In** - Apple ID authentication

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
├── api/                 # HTTP client and API utilities
├── common/              # Shared widgets and enums
├── data_source/         # Local caching infrastructure
├── features/            # Feature-based modules
├── helper/              # Utilities and dependency injection
├── interface/           # Repository interfaces
├── theme/               # App theming
├── util/                # Constants and resources
└── main.dart           # Application entry point
```

## Configuration Files
- **pubspec.yaml** - Dependencies and app configuration
- **analysis_options.yaml** - Code quality rules
- **firebase_options.dart** - Firebase configuration
- **devtools_options.yaml** - Development tools settings

## Platform Support
- **Android** - Native Android support
- **iOS** - Native iOS support  
- **Web** - Progressive Web App capabilities

## Key Design Decisions
1. **Modular Architecture** - Each feature is self-contained
2. **GetX State Management** - Reactive programming with minimal boilerplate
3. **Repository Pattern** - Abstracted data access layer
4. **Clean Architecture** - Separation of concerns and testability
5. **Offline-First** - Local caching with API fallback
6. **Multi-Platform** - Single codebase for mobile and web