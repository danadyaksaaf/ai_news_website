# Dana AI News Hub

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-blue.svg" alt="Flutter Version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-blueviolet.svg" alt="Platform">
</p>

Your ultimate destination for the latest news and updates in Artificial Intelligence. Dana AI News Hub curates the most recent breakthroughs in AI for coding, designing, and writing to keep you informed about the rapidly evolving world of technology.

## 📱 Features

### Core Features
- **AI News Aggregation** - Real-time AI news from various sources
- **Three Category Sections**:
  - 🤖 **AI for Coding** - GitHub Copilot, AI programming tools, code assistants
  - 🎨 **AI for Designing** - Midjourney, DALL-E, AI art generators
  - ✍️ **AI for Writing** - ChatGPT, Claude, research tools, content generation
- **Smart Search** - Search AI news with debounce, popular suggestions, and recent searches
- **Personalized Recommendations** - Categories are prioritized based on your reading history

### UI/UX Features
- **Responsive Design** - Optimized for mobile, tablet, and desktop
- **Material Design 3** - Modern and clean interface
- **Custom Theming** - Beautiful gradient designs with Poppins font
- **Image Caching** - Fast loading with cached network images
- **Dark/Light Mode Ready** - Color scheme foundation for theming

### Technical Features
- **Offline Support** - Fallback sample data when API is unavailable
- **Reading History Tracking** - Persistent storage using SharedPreferences
- **API Error Handling** - Graceful degradation with user-friendly error messages

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.10+ |
| **Language** | Dart |
| **State Management** | setState |
| **API** | NewsAPI |
| **Local Storage** | SharedPreferences |
| **UI** | Material Design 3, Google Fonts |

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  google_fonts: ^6.1.0
  http: ^1.1.0
  cached_network_image: ^3.3.0
  shared_preferences: ^2.2.2
```

## 📂 Project Structure

```
ai_news_website/
├── lib/
│   ├── main.dart                    # App entry point and configuration
│   ├── home_page.dart               # Home page with news feed and search
│   ├── category_page.dart           # Category browsing with personalization
│   ├── about_page.dart              # About the app
│   ├── news_api_service.dart        # NewsAPI integration
│   └── reading_history_service.dart # Reading history tracking
├── pubspec.yaml                     # Project dependencies
└── README.md                        # This file
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.10 or higher
- **Dart SDK** 3.10 or higher
- **NewsAPI Key** (free at [newsapi.org](https://newsapi.org/register))

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ai_news_website
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Key**
   
   Open `lib/main.dart` and replace the API key:
   ```dart
   const String newsApiKey = 'YOUR_API_KEY_HERE';
   ```
   
   Get your free API key at: https://newsapi.org/register

4. **Run the app**
   ```bash
   flutter run
   ```

### Running on Different Platforms

```bash
# Run on iOS simulator
flutter run -d "iPhone 15"

# Run on Android emulator
flutter run -d emulator-5554

# Run on web
flutter run -d chrome

# Build for iOS
flutter build ios

# Build for Android
flutter build apk --release
```

## 🔧 Configuration

### News API Setup

The app uses [NewsAPI](https://newsapi.org/) to fetch real-time AI news.

1. Register for a free account at [newsapi.org](https://newsapi.org/register)
2. Get your API key from the dashboard
3. Update the API key in `lib/main.dart`:
   ```dart
   const String newsApiKey = 'your-api-key-here';
   ```

### Sample Data

If no API key is configured, the app will automatically use sample news data for demonstration purposes.

## 📱 App Screens

### Home Screen
- Trending AI news banner with stats
- Topic filter chips (All, AI for Coding, AI for Designing, AI for Writing)
- News grid with responsive layout
- Search functionality with suggestions

### Category Screen
- Personalized category ordering based on reading history
- Reading statistics per category
- Article grid view

### Search
- Real-time search with debounce (500ms)
- Popular search suggestions
- Recent searches history

### About Screen
- App information
- Tech stack details
- Copyright information

## 🎨 Design System

### Colors

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #6366F1 | Main brand color (Indigo) |
| Secondary | #8B5CF6 | Accent gradient |
| Coding | #6366F1 | AI for Coding category |
| Designing | #EC4899 | AI for Designing category |
| Writing | #10B981 | AI for Writing category |
| Background | #FAFAFA | Scaffold background |
| Surface | #FFFFFF | Card backgrounds |
| Text Primary | #1F2937 | Headlines |
| Text Secondary | #6B7280 | Body text |

### Typography

- **Font Family**: Poppins (via Google Fonts)
- **Headlines**: Bold, 20-32px
- **Body**: Regular/Medium, 12-16px

**Dyaksa_Software**

- GitHub: [github.com/dyaksa](https://github.com/dyaksa)
- Email: contact@dyaksa.com

---

<p align="center">Made with ❤️ using Flutter</p>

