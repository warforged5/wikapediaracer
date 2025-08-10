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
- **Custom page input** - add your own Wikipedia pages to the race
- **Winner tracking** across rounds with leaderboard

### 👥 Group Management
- **Create and manage racing groups** for organized competitions
- **Track win/loss statistics** for each group member
- **Race history** with detailed round breakdowns
- **Export race data** for sharing results

### 🎨 Modern Design
- **Material Design 3** with expressive theming
- **10 beautiful themes** including light and dark options
- **Responsive design** optimized for mobile, tablet, and web
- **Clean, intuitive interface** with smooth animations
- **Accessibility-focused** with proper contrast and navigation

### 🌐 Cross-Platform
- **Android** - Native mobile experience
- **iOS** - Seamless Apple integration
- **Web** - Play directly in your browser
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

1. **Start a Quick Race** or create a **Group** for organized play
2. **Add players** to the race (2-6 players recommended)
3. **Choose starting page** from suggestions or enter a custom page
4. **Select target page** - this is where everyone needs to reach
5. **Race begins!** Players navigate Wikipedia using only internal links
6. **First to reach the target wins** the round
7. **Multiple rounds** determine the overall winner

### 🏆 Pro Tips
- Look for common linking patterns (dates, countries, categories)
- Popular pages often have more incoming links
- Use the browser's back button if you hit a dead end
- Think about logical connections between topics

## 🛠 Development

### Project Structure
```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── player.dart
│   ├── race_result.dart
│   └── wikipedia_page.dart
├── screens/                     # UI screens
│   ├── home_screen.dart
│   ├── race_screen.dart
│   ├── race_results_screen.dart
│   └── ...
├── services/                    # API and storage services
│   ├── wikipedia_service.dart
│   └── storage_service.dart
└── themes/                      # App theming
    └── app_theme.dart
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Material 3**: Google's latest design system
- **Wikipedia API**: Real-time page data and suggestions
- **SharedPreferences**: Local data persistence
- **HTTP**: API communication

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
- [ ] **Tournament mode** with bracket-style competitions
- [ ] **Achievement system** with unlockable badges
- [ ] **Custom Wikipedia sources** (other language editions)
- [ ] **Race replay system** to review navigation paths
- [ ] **Social sharing** of race results
- [ ] **Advanced statistics** and performance analytics

### Completed ✅
- [x] Multi-round racing system
- [x] Group management and statistics
- [x] 10 beautiful themes with Material 3 design
- [x] Cross-platform support (mobile, web, desktop)
- [x] Responsive design for all screen sizes
- [x] Custom page input functionality
- [x] Race history and data export

---

<div align="center">
  <p><strong>Ready to race through Wikipedia? Let's go! 🏁</strong></p>
  
  <p>Made with ❤️ and ☕ using Flutter</p>
</div>
