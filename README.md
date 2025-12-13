# Styleto iOS App

[![Swift](https://img.shields.io/badge/Swift-5.9-orange)](https://swift.org/)
[![iOS](https://img.shields.io/badge/iOS-17.0+-lightgrey)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-blue)](./LICENSE)

A modern iOS application for **Styleto**, a fashion e-commerce platform powered by AI. Built with Swift, SwiftUI, and Combine, delivering a beautiful and intuitive shopping experience with AI-powered clothing detection, personalized outfit recommendations, and a vibrant marketplace.

---

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Building the App](#-building-the-app)
- [Project Structure](#-project-structure)
- [Key Features Implementation](#-key-features-implementation)
- [API Integration](#-api-integration)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)

---

## ✨ Features

### 🔐 Authentication & Security
- **Email/Password authentication** with secure JWT token management
- **Google Sign-In** integration
- **Apple Sign-In** (Sign in with Apple)
- **Forgot password** flow with OTP verification via email
- **Automatic token refresh** mechanism
- **Secure keychain storage** for credentials

### 👕 Dressing (Wardrobe Management)
- **AI-powered clothing detection** from photos
- **Clothing categorization** (Top, Bottom, Dress, Shoes, Accessory, Jacket)
- **Style and season classification** (Casual, Formal, Summer, Winter, etc.)
- **Color detection** using AI models
- **Photo guide** with tips for optimal photo capture
- **Clothing detail editing** and management
- **Grid and list view** options
- **Search and filter** functionality

### 🎨 Outfits & Recommendations
- **AI-powered outfit suggestions** based on user preferences
- **Style-based recommendations** (Casual, Formal, Sporty, Elegant, etc.)
- **Weather-aware suggestions** (temperature-based)
- **Location-based recommendations** (city-specific)
- **Favorites management** for preferred outfits
- **Outfit visualization** with clothing items
- **Personalized recommendations** engine

### 🛍️ Store & Marketplace
- **Browse store items** (Discover tab)
- **My store items** management
- **Add items to store** with images, sizes, prices, and descriptions
- **Shopping cart** with CoreData persistence
- **Real-time chat** with sellers using Socket.IO
- **Stripe payment integration** for secure transactions
- **Order history** and tracking
- **Item search and filtering**

### 💳 Subscriptions & Payments
- **Subscription plans** (Free, Premium, Pro Seller)
- **Usage statistics** and quota tracking
- **Stripe checkout** integration
- **Balance top-up** functionality
- **Subscription management** and cancellation
- **Paywall screens** for premium features

### 👤 Profile & Settings
- **User profile** management with avatar
- **Avatar upload** via Cloudinary
- **Theme customization** (Light/Dark/System)
- **Color theme** selection (Pink/Blue based on gender)
- **Settings** and preferences
- **Account management** (change password, delete account)
- **Balance management**

### 📸 Camera & Media
- **Native camera integration** for photo capture
- **Photo library** access
- **Image picker** with multiple selection
- **Image upload** to Cloudinary
- **Avatar 3D** capture and management

### 💬 Real-Time Chat
- **WebSocket-based messaging** using Socket.IO
- **Real-time conversations** with sellers
- **Typing indicators**
- **Message history** persistence
- **Conversation list** management

---

## 🛠 Tech Stack

### Core
- **Swift 5.9** - Modern programming language
- **iOS 17.0+** - Minimum deployment target
- **Xcode 15+** - Development environment

### UI Framework
- **SwiftUI** - Declarative UI framework
- **Combine** - Reactive programming framework
- **UIKit** (minimal) - For specific components

### Architecture
- **MVVM (Model-View-ViewModel)** - Architecture pattern
- **ObservableObject** - State management
- **@Published** - Property wrappers for reactivity
- **Combine Publishers** - Reactive data streams

### Networking
- **URLSession** - Native networking
- **Async/Await** - Modern concurrency
- **Socket.IO Client** - WebSocket communication
- **JSONDecoder** - JSON parsing

### Local Storage
- **CoreData** - Local database
- **UserDefaults** - Simple key-value storage
- **Keychain** - Secure credential storage

### Image Processing
- **Cloudinary SDK** - Cloud image management
- **UIImage** - Native image handling
- **AVFoundation** - Camera and media capture

### Payment
- **Stripe iOS SDK** - Payment processing
- **WebView** - Stripe checkout integration

### Authentication
- **Google Sign-In SDK** - Google authentication
- **AuthenticationServices** - Apple Sign-In
- **JWT** - Token-based authentication

### Other Libraries
- **SwiftUI Navigation** - Navigation handling
- **Custom Components** - Reusable UI components

---

## 🏗 Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture with SwiftUI and Combine:

```
Labasniios/
├── Models/                    # Data models
│   ├── DTOs/                  # Data transfer objects
│   │   ├── AuthDTO.swift
│   │   └── SubscriptionDTO.swift
│   └── Entities/              # Domain entities
│       ├── User.swift
│       ├── Clothe.swift
│       ├── Outfit.swift
│       └── ...
│
├── Services/                  # Service layer
│   ├── Auth/                  # Authentication services
│   ├── Clothes/               # Clothing services
│   ├── Outfits/               # Outfit services
│   ├── Store/                 # Store services
│   ├── Subscriptions/         # Subscription services
│   └── Profile/               # Profile services
│
├── ViewModels/                # View models
│   ├── Auth/                  # Auth view models
│   ├── Dressing/              # Dressing view models
│   ├── Outfits/               # Outfits view models
│   ├── Store/                 # Store view models
│   └── ...
│
├── Views/                     # SwiftUI views
│   ├── Auth/                  # Authentication screens
│   ├── Dressing/              # Wardrobe screens
│   ├── Outfits/               # Outfits screens
│   ├── Store/                 # Store screens
│   ├── Settings/              # Settings screens
│   └── Components/            # Reusable components
│
└── Utils/                     # Utilities
    ├── APIConstants.swift
    ├── TokenManager.swift
    ├── ThemeManager.swift
    └── ...
```

### Design Patterns
- **MVVM**: Separation of concerns
- **Repository Pattern**: Data access abstraction
- **Service Layer**: Business logic encapsulation
- **Observer Pattern**: Combine publishers
- **Singleton Pattern**: Shared managers

---

## 📦 Prerequisites

Before you begin, ensure you have:

- **macOS** 13.0 or later
- **Xcode 15.0** or later
- **iOS 17.0+** SDK installed
- **CocoaPods** (if using pod dependencies)
- **Apple Developer Account** (for device testing and App Store)
- **Backend API** running (see Backend README)

### Optional
- **Physical iOS device** for testing
- **Google Cloud Console** account (for Google Sign-In)
- **Stripe account** (for payment testing)

---

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Labasni-IOS
   ```

2. **Open in Xcode**
   ```bash
   open Labasniios.xcodeproj
   ```

3. **Install dependencies** (if using CocoaPods)
   ```bash
   pod install
   open Labasniios.xcworkspace
   ```

4. **Configure project settings**
   - Select your development team in Signing & Capabilities
   - Update bundle identifier if needed
   - Configure API endpoints (see [Configuration](#-configuration))

5. **Build the project**
   - Press `Cmd + B` or select Product > Build

---

## ⚙️ Configuration

### API Configuration
Edit `Utils/APIConstants.swift`:

```swift
struct APIConstants {
    static let baseURL = "http://localhost:3000" // Development
    // static let baseURL = "https://api.styleto.com" // Production
}
```

### Google Sign-In
1. Add your `GoogleService-Info.plist` to the project
2. Configure URL schemes in `Info.plist`
3. Update `GOOGLE_CLIENT_ID` in project settings

### Apple Sign-In
1. Enable "Sign in with Apple" capability in Xcode
2. Configure in Apple Developer Portal
3. Update bundle identifier

### Stripe Configuration
Edit `Utils/StripeConfig.swift`:

```swift
struct StripeConfig {
    static let publishableKey = "pk_test_your-stripe-publishable-key"
}
```

### Cloudinary Configuration
Configure in `Services/` where Cloudinary is used:

```swift
let cloudinaryConfig = CloudinaryConfig(
    cloudName: "your-cloud-name",
    apiKey: "your-api-key",
    apiSecret: "your-api-secret"
)
```

---

## 🔨 Building the App

### Debug Build
1. Select your target device/simulator
2. Press `Cmd + R` or select Product > Run

### Release Build
1. Select "Any iOS Device" or specific device
2. Select Product > Archive
3. Distribute via App Store or Ad Hoc

### Build for Testing
```bash
xcodebuild -scheme Labasniios -configuration Debug -sdk iphonesimulator
```

---

## 📁 Project Structure

```
Labasniios/
├── Models/
│   ├── DTOs/
│   │   ├── AuthDTO.swift              # Authentication DTOs
│   │   ├── SubscriptionDTO.swift      # Subscription DTOs
│   │   └── JSONDecoder+ISO8601.swift  # Date decoding
│   └── Entities/
│       ├── User.swift                 # User model
│       ├── Clothe.swift               # Clothing item model
│       ├── Outfit.swift               # Outfit model
│       ├── Store.swift                # Store item model
│       ├── Conversation.swift         # Chat conversation
│       └── ChatMessage.swift          # Chat message
│
├── Services/
│   ├── Auth/
│   │   ├── AuthService.swift          # Authentication service
│   │   ├── GoogleSignInHelper.swift   # Google Sign-In
│   │   └── AppleSignInHelper.swift    # Apple Sign-In
│   ├── Clothes/
│   │   └── ClothesService.swift       # Clothing operations
│   ├── Outfits/
│   │   ├── OutfitsService.swift       # Outfit operations
│   │   └── FavoritesService.swift     # Favorites management
│   ├── Store/
│   │   ├── StoreService.swift         # Store operations
│   │   ├── CartService.swift          # Shopping cart
│   │   ├── PaymentService.swift       # Stripe payments
│   │   └── ChatService.swift          # Chat service
│   ├── Subscriptions/
│   │   ├── SubscriptionService.swift  # Subscription management
│   │   └── StripeCheckoutService.swift # Stripe checkout
│   └── Profile/
│       └── ProfileService.swift       # Profile operations
│
├── ViewModels/
│   ├── Auth/
│   │   ├── LoginViewModel.swift
│   │   ├── SignupViewModel.swift
│   │   └── ForgotPasswordViewModel.swift
│   ├── Dressing/
│   │   └── DressingViewModel.swift
│   ├── Outfits/
│   │   └── OutfitsViewModel.swift
│   ├── Store/
│   │   ├── StoreViewModel.swift
│   │   ├── PaymentViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── ChatDetailViewModel.swift
│   └── Subscription/
│       └── SubscriptionViewModel.swift
│
├── Views/
│   ├── Auth/
│   │   ├── LabasniLoginView.swift
│   │   ├── LabasniSignupView.swift
│   │   └── LabasniForgotPasswordView.swift
│   ├── Dressing/
│   │   ├── DressingView.swift
│   │   ├── DetectionResultView.swift
│   │   └── PhotoGuidePopupView.swift
│   ├── Outfits/
│   │   ├── OutfitsView.swift
│   │   └── FavoritesView.swift
│   ├── Store/
│   │   ├── StoreView.swift
│   │   ├── CartView.swift
│   │   └── ChatDetailView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       └── (Reusable components)
│
└── Utils/
    ├── APIConstants.swift             # API configuration
    ├── TokenManager.swift             # JWT token management
    ├── ThemeManager.swift             # Theme management
    ├── SocketManager.swift            # WebSocket manager
    ├── CoreDataManager.swift          # CoreData stack
    └── ...
```

---

## 🔑 Key Features Implementation

### Authentication Flow
1. User enters credentials or uses OAuth (Google/Apple)
2. API call to backend `/auth/signin` or `/auth/google` or `/auth/apple`
3. JWT tokens received and stored securely in Keychain via `TokenManager`
4. `TokenRefreshHelper` handles automatic token refresh
5. User redirected to main tab view

### Clothing Detection
1. User navigates to Dressing screen
2. User taps "+" to add clothing
3. Photo guide shown with tips (`PhotoGuidePopupView`)
4. User captures/selects photo
5. Image uploaded to backend `/clothes/detect` endpoint (multipart)
6. AI processes image and returns detection results
7. `DetectionResultView` displays results
8. User can edit category, style, season, and color
9. Clothing item saved to backend via `/clothes` POST

### Outfit Recommendations
1. User navigates to Outfits screen
2. `OutfitsViewModel` fetches recommendations
3. API call to `/outfits/recommend` with user preferences
4. AI generates outfit suggestions
5. User can favorite outfits
6. Outfits displayed with clothing items in cards

### Store & Shopping
1. Browse store items in Discover tab
2. View item details in `DiscoverItemDetailSheet`
3. Add to cart (stored in CoreData via `CartService`)
4. Real-time chat with seller via `ChatService` (Socket.IO)
5. Proceed to checkout with Stripe (`PaymentService`)
6. Order created via `/orders` endpoint
7. Order history tracked in `OrdersHistoryView`

### Real-Time Chat
1. WebSocket connection established via `SocketManager`
2. Join conversation via Socket.IO events
3. Messages sent/received in real-time
4. Typing indicators shown
5. Message history persisted
6. Conversations list updated

### Subscriptions
1. User views current subscription in `PackProfileCard`
2. Usage statistics displayed (clothesDetection, outfitSuggestions, storeSelling)
3. User can upgrade via `SubscriptionPlansView`
4. Stripe checkout via `StripeCheckoutWebView`
5. Webhook updates subscription status
6. Quota checks before premium features

---

## 🔌 API Integration

### Base Configuration
- **Base URL**: Configured in `APIConstants.swift`
- **URLSession**: Native networking with async/await
- **JSON Decoding**: Custom `JSONDecoder` with ISO8601 date support

### API Endpoints Used

#### Authentication
- `POST /auth/signin` - Email/password login
- `POST /auth/signup` - User registration
- `POST /auth/google` - Google Sign-In
- `POST /auth/apple` - Apple Sign-In
- `POST /auth/forgot-password` - Password reset request
- `POST /auth/reset-password` - Reset password

#### Clothes
- `GET /clothes` - Get user's clothes
- `POST /clothes` - Add clothing item
- `POST /clothes/detect` - AI clothing detection
- `DELETE /clothes/:id` - Delete clothing item

#### Outfits
- `GET /outfits` - Get user's outfits
- `POST /outfits` - Create outfit
- `POST /outfits/recommend` - Get AI recommendations
- `POST /outfits/:id/favorite` - Favorite outfit

#### Store
- `GET /store` - Get store items
- `POST /store` - Create store item
- `PUT /store/:id` - Update store item
- `DELETE /store/:id` - Delete store item

#### Cart & Orders
- `GET /cart` - Get cart
- `POST /cart` - Add to cart
- `POST /orders` - Create order
- `GET /orders` - Get order history

#### Chat
- `GET /chat/conversations` - Get conversations
- `GET /chat/messages/:conversationId` - Get messages
- WebSocket: `/chat` namespace for real-time messaging

#### Subscriptions
- `GET /subscriptions/my` - Get user's subscription
- `POST /subscriptions/purchase` - Purchase subscription
- `POST /subscriptions/cancel` - Cancel subscription

---

## 🎨 UI/UX Features

### Theme System
- **Light/Dark Mode**: System-based or manual selection
- **Color Themes**: Pink (Female) / Blue (Male) variants
- **Dynamic Colors**: Adapts to user preferences
- **Custom Navigation**: Themed navigation bars

### SwiftUI Components
- **Modern Design**: Material Design principles
- **Smooth Animations**: Native SwiftUI animations
- **Custom Components**: Reusable UI elements
- **Sheets and Modals**: Native presentation styles

### User Experience
- **Intuitive Navigation**: Tab-based navigation
- **Loading States**: Progress indicators
- **Error Handling**: User-friendly error messages
- **Empty States**: Helpful empty state views

---

## 🧪 Testing

### Unit Tests
```bash
xcodebuild test -scheme Labasniios -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
- Create UI tests in `LabasniiosUITests/`
- Test user flows and interactions

### Manual Testing
- Test on multiple iOS versions
- Test on different device sizes
- Test with various network conditions

---

## 🚢 Deployment

### App Store Deployment

1. **Update Version**
   - Update version and build number in Xcode
   - Update `Info.plist` if needed

2. **Archive**
   - Select Product > Archive
   - Wait for archive to complete

3. **Distribute**
   - Click "Distribute App"
   - Select "App Store Connect"
   - Follow the distribution wizard

4. **App Store Connect**
   - Upload build via Xcode or Transporter
   - Complete App Store listing
   - Submit for review

### TestFlight
1. Upload build to App Store Connect
2. Add internal/external testers
3. Distribute via TestFlight

### Ad Hoc Distribution
1. Create provisioning profile
2. Archive with Ad Hoc distribution
3. Export and distribute to testers

---

## 🔒 Security

### Token Management
- Secure storage in Keychain
- Automatic token refresh
- Token expiration handling

### Network Security
- HTTPS for all API calls
- Certificate pinning (optional)
- Secure credential storage

### Data Protection
- Keychain for sensitive data
- Secure password handling
- OAuth 2.0 for third-party auth

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Swift style guide
- Use SwiftLint for code formatting
- Write unit tests for new features
- Update documentation

---

## 📝 License

This project is licensed under the MIT License.

---

## 📞 Support

For support, email support@styleto.com or open an issue in the repository.

---

## 🙏 Acknowledgments

- SwiftUI team at Apple
- Combine framework contributors
- All open-source library maintainers
- The iOS developer community

---

**Built with ❤️ for Styleto**
