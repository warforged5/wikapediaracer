# Wikipedia Racer 🏁

A fast-paced multiplayer racing game where players compete to navigate from one Wikipedia page to another using only internal links. Built with Flutter for cross-platform compatibility.

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Material%20Design%203-757575?style=for-the-badge&logo=material-design&logoColor=white" alt="Material Design">
</div>

## 🎯 What is Wikipedia Racing?

Wikipedia racing is a popular online game where players start on one Wikipedia page and race to reach a target page using only the hyperlinks within articles. The challenge is finding the shortest path through the interconnected web of knowledge!

## ✨ Features

### 🏃‍♂️ Core Gameplay
- **Multi-round races** with customizable round counts
- **Real-time race timer** with precise millisecond tracking
- **Multiple players support** with colorful player identification
- **Custom Lists** - create and save your own curated Wikipedia page collections (30+ pages)
- **Configurable options** - choose how many page options appear during races (3-8 choices)
- **Custom page input** - add individual Wikipedia pages to any race
- **Winner tracking** across rounds with leaderboard
- **Enhanced race path display** with page descriptions and copy functionality

### 👥 Group Management
- **Create and manage racing groups** for organized competitions
- **Track win/loss statistics** for each group member
- **Race history** with detailed round breakdowns
- **Export race data** for sharing results

### 🏆 Tournament System
- **Multiple tournament formats**: Single Elimination, Double Elimination, Round Robin, Swiss
- **Bracket visualization** with real-time match progress
- **Player profile integration** - select from existing players or create new ones
- **One-click match starting** directly from bracket view
- **Tournament result tracking** with champion celebrations
- **Flexible participant management** (4-32 players)

### 🎖️ Achievement System
- **Unlockable achievements** based on racing performance and milestones
- **Progress tracking** with detailed achievement descriptions
- **Achievement categories** covering different aspects of gameplay
- **Visual achievement display** with icons and completion status

### 🎨 Modern Design
- **Material Design 3** with expressive theming
- **Many beautiful themes** including light and dark options
- **Responsive design** optimized for mobile, tablet, and web
- **Clean, intuitive interface** with delightful micro-interactions
- **Accessibility-focused** with proper contrast and navigation

### 📱 Social Sharing
- **Share race results** with formatted statistics and emojis
- **Challenge friends** with custom race invitations
- **Tournament announcements** and result sharing
- **Personal statistics sharing** with win rates and achievements
- **Cross-platform sharing** on mobile and web

### 🌐 Cross-Platform
- **Android** - Native mobile experience with native sharing
- **iOS** - Seamless Apple integration with share sheet
- **Web** - Play directly in your browser with web sharing API
- **Windows/macOS/Linux** - Desktop applications

## 📱 Screenshots

*[Add screenshots here showing different screens and themes]*

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- An internet connection (for Wikipedia API access)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/wikapediaracer.git
   cd wikapediaracer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For web
   flutter run -d chrome
   
   # For mobile (with device/emulator connected)
   flutter run
   
   # For desktop
   flutter run -d windows  # or macos/linux
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Desktop
flutter build windows --release  # or macos/linux
```

## 🎮 How to Play

### 🏃‍♂️ Quick Race Mode
1. **Start a Quick Race** for immediate gameplay
2. **Add players** to the race (2-8 players supported)
3. **Choose race type**:
   - **Random Pages**: Use Wikipedia's API for random page suggestions
   - **Custom Lists**: Create or select from saved lists of 30+ Wikipedia pages
4. **Configure options**: Choose how many page options to show (3-8 choices)
5. **Choose starting page** from suggestions or enter a custom page
6. **Select target page** - this is where everyone needs to reach
7. **Race begins!** Players navigate Wikipedia using only internal links
8. **First to reach the target wins** the round
9. **Multiple rounds** determine the overall winner

### 👥 Group Mode
1. **Create a Group** for organized competitions with friends
2. **Add players** and track statistics over time
3. **Start group races** with your established roster
4. **Export results** and view detailed race history

### 🏆 Tournament Mode
1. **Create Tournament** with custom name and format
2. **Select organizer** from existing players or create new profile
3. **Choose format**: Single Elimination, Round Robin, etc.
4. **Players join** using the player selector dialog
5. **Start tournament** to generate bracket
6. **Start matches** directly from the bracket view
7. **Tournament progresses** automatically as matches complete

### 🏆 Pro Tips
- Look for common linking patterns (dates, countries, categories)
- Popular pages often have more incoming links
- Use the browser's back button if you hit a dead end
- Think about logical connections between topics

## 🛠 Development

### Project Structure
```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── player.dart               # Player profiles
│   ├── race_result.dart          # Race results and rounds
│   ├── tournament.dart           # Tournament system
│   ├── group.dart                # Group management
│   ├── custom_list.dart          # Custom Wikipedia page lists
│   └── wikipedia_page.dart       # Wikipedia page data
├── screens/                       # UI screens
│   ├── home_screen.dart          # Main navigation hub
│   ├── race_screen.dart          # Live race interface
│   ├── race_results_screen.dart  # Results with sharing
│   ├── tournament_screen.dart    # Tournament browser
│   ├── tournament_detail_screen.dart
│   ├── tournament_bracket_screen.dart
│   ├── custom_list_screen.dart   # Custom list management
│   └── ...
├── services/                      # Business logic
│   ├── wikipedia_service.dart    # Wikipedia API integration
│   ├── storage_service.dart      # Local data persistence
│   ├── tournament_service.dart   # Tournament management
│   └── sharing_service.dart      # Social sharing functionality
├── widgets/                       # Reusable UI components
│   └── player_selector_dialog.dart
└── themes/                        # App theming
    └── app_theme.dart
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Material 3**: Google's latest design system
- **Wikipedia API**: Real-time page data and suggestions
- **SharedPreferences**: Local data persistence
- **HTTP**: API communication
- **JSON Serialization**: Data modeling and persistence
- **Share Plus**: Native sharing capabilities

### Development Commands

```bash
# Run with hot reload
flutter run

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code quality
flutter analyze

# Format code
flutter format lib/

# Clean build artifacts
flutter clean

# Check for outdated packages
flutter pub outdated
```

## 🎨 Themes

The app includes 10 carefully crafted themes:

- **Classic Blue** - Clean and professional
- **Ocean Breeze** - Calm ocean vibes
- **Forest Green** - Natural and refreshing
- **Sunset Orange** - Warm and energetic
- **Royal Purple** - Elegant and luxurious
- **Cherry Red** - Bold and passionate
- **Midnight Dark** - Sleek dark mode
- **Cyber Neon** - Futuristic and electric
- **Coffee Brown** - Warm and cozy
- **Arctic Blue** - Cool and minimal

## 🌐 API Usage

This app uses the Wikipedia API to:
- Fetch random page suggestions
- Validate custom page entries
- Get page extracts for previews

**Rate Limiting**: The app implements respectful API usage with appropriate delays and caching.

## 📱 Responsive Design

The app automatically adapts to different screen sizes:

- **Mobile** (< 600px): Single-column layouts, touch-optimized
- **Tablet** (600-800px): Mixed layouts with more content
- **Desktop/Web** (> 800px): Two-column layouts, larger text, more spacing

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

### Contribution Guidelines
- Follow the existing code style and patterns
- Add tests for new features
- Update documentation as needed
- Ensure all platforms build successfully

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Wikipedia** for providing the amazing free knowledge platform
- **Flutter team** for the excellent cross-platform framework
- **Material Design team** for the beautiful design system
- **The open source community** for inspiration and resources

## 📞 Support

Having issues? Here are some resources:

- **GitHub Issues**: [Report bugs or request features](https://github.com/yourusername/wikapediaracer/issues)
- **Flutter Documentation**: [flutter.dev](https://flutter.dev)
- **Wikipedia API Docs**: [mediawiki.org](https://www.mediawiki.org/wiki/API:Main_page)

## 🗺 Roadmap

### Upcoming Features
- [ ] **Multiplayer online races** with real-time synchronization
- [ ] **Custom Wikipedia sources** (other language editions)
- [ ] **Race replay system** to review navigation paths
- [ ] **Advanced statistics** and performance analytics
- [ ] **Tournament live streaming** and spectator mode
- [ ] **AI opponents** for single-player practice

### Recently Added ✅
- [x] **Custom Lists Feature** - create, save, and manage curated Wikipedia page collections
- [x] **Animated UI Components** - morphing buttons with squircle-to-circle transitions and elastic bounces
- [x] **Interactive Page Cards** - staggered entrance animations with hover effects and tap feedback
- [x] **Enhanced race path display** with horizontal layouts, icons, and page descriptions
- [x] **Simplified countdown screen** optimized for all screen sizes and orientations
- [x] **Improved responsive design** with 4 breakpoints (mobile, small, medium, large screens)
- [x] **Better racing interface** with cleaner visual hierarchy and user experience
- [x] **Copy page names functionality** with toast notifications for easy sharing
- [x] **Advanced layout system** with tablet-specific designs and orientation handling

### Core Features ✅
- [x] Multi-round racing system with real-time timers
- [x] Group management and comprehensive statistics
- [x] **Tournament system** with multiple formats (Single/Double Elimination, Round Robin, Swiss)
- [x] **Social sharing** of race results, challenges, and tournament announcements
- [x] **Player profile system** with advanced selection dialogs
- [x] **Interactive tournament brackets** with one-click match starting
- [x] **Achievement system** with unlockable achievements and progress tracking
- [x] 10 beautiful themes with Material 3 design system
- [x] **Complete cross-platform support** (Android, iOS, Web, Windows, macOS, Linux)
- [x] **Fully responsive design** adapting from mobile to ultra-wide displays
- [x] **Custom Lists System** - create, save, and manage Wikipedia page collections
- [x] **Advanced Animations** - morphing UI components with elastic bounces and smooth transitions
- [x] Custom page input functionality with validation
- [x] Comprehensive race history and data export capabilities

---

<div align="center">
  <p><strong>Ready to race through Wikipedia? Let's go! 🏁</strong></p>
  
  <p>Made with ❤️ and ☕ using Flutter</p>
</div>
