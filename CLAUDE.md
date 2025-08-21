# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Running the app
```bash
flutter run
```

### Building
```bash
# Debug build
flutter build apk --debug
flutter build web --debug

# Release build
flutter build apk --release
flutter build web --release
flutter build ios --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests (if any)
flutter drive --target=test_driver/app.dart
```

### Linting and Analysis
```bash
# Run static analysis
flutter analyze

# Format code
flutter format lib/
```

### Development Tools
```bash
# Get dependencies
flutter pub get

# Clean build artifacts
flutter clean

# Check for outdated packages
flutter pub outdated

# Generate code (JSON serialization)
flutter packages pub run build_runner build
```

## Project Architecture

### Current State
This is a fully implemented Flutter application for Wikipedia racing:
- **Entry Point**: `lib/main.dart` initializes storage services, theme services, and renders the home screen
- **Multi-platform**: Supports Android, iOS, Web, Windows, Linux, and macOS
- **Full Features**: Complete Wikipedia racing game with tournaments, groups, achievements, and more

### Project Structure
- `lib/main.dart`: Application entry point with theme and service initialization
- `lib/models/`: Data models with JSON serialization (Player, Group, Tournament, Race Results, etc.)
- `lib/screens/`: All UI screens including home, race, tournaments, groups, achievements
- `lib/services/`: Business logic services (Wikipedia API, storage, themes, achievements, etc.)
- `lib/themes/`: Custom theme system with multiple color schemes
- `lib/widgets/`: Reusable UI components
- `assets/images/`: Application assets and splash screen

### Dependencies
Core dependencies include:
- `http`: API calls to Wikipedia
- `shared_preferences`: Local data storage
- `json_annotation/json_serializable`: JSON serialization
- `uuid`: Unique ID generation
- `share_plus`: Social sharing functionality
- `morphable_shape`: Advanced UI animations
- `flutter_native_splash`: Native splash screen
- `file_picker`: File selection for data import/export

### Code Quality
- Uses `flutter_lints` package with strict linting rules
- JSON serialization with code generation
- Comprehensive error handling and loading states
- Responsive design supporting all screen sizes

## Application Features

### Core Functionality
- **Wikipedia Racing**: Race from one Wikipedia page to another through link navigation
- **Multiple Game Modes**: Quick races, group competitions, and tournaments
- **Player Management**: Create and manage player profiles with persistent storage
- **Profile Integration**: Use saved profiles in quick races and custom lists
- **Group System**: Create groups and compete with friends
- **Tournament System**: Bracket-style tournaments with multiple rounds
- **Achievement System**: Unlock achievements based on racing performance
- **History Tracking**: Complete race history and statistics
- **Data Management**: Export/import all app data for backup and sharing

### UI/UX Features
- **Responsive Design**: Adapts to all screen sizes from mobile to desktop
- **Multiple Themes**: 8+ built-in themes with light/dark mode support
- **Smooth Animations**: Custom animations and transitions throughout
- **Accessibility**: Screen reader support and keyboard navigation
- **Cross-Platform**: Native feel on all supported platforms

### Recent Improvements
- **Enhanced Race Path Display**: Horizontal layout with icons, labels, and descriptions
- **Responsive Countdown Screen**: Simplified design that adapts to all screen sizes
- **Improved Racing Interface**: Better visual hierarchy and user experience
- **Theme System**: Complete theme customization with color schemes
- **Profile System**: Persistent player profiles with creation, selection, and statistics
- **Data Export/Import**: Full backup and restore functionality for all user data
- **Custom List Management**: Copy functionality and profile integration
- **Quick Race Enhancement**: Dialog-based profile selection for streamlined setup
- **Performance**: Optimized for smooth operation across all platforms

## Player Profile Management

### Profile Creation
- **Location**: User Selector Screen (accessible from achievements/profile page)
- **Storage**: Profiles are saved persistently using `StorageService.savePlayer()`
- **Validation**: Duplicate name checking prevents conflicts
- **UI**: Icon-only create button for streamlined interface

### Profile Usage
- **Quick Race Setup**: "Add Profile" button opens dialog for multi-selection
- **Custom Lists**: Profiles can be selected alongside custom player names
- **Mixed Mode**: Both text input and saved profiles work together in the same race
- **Visual Distinction**: Profile players display as cards, text players as input fields

### Data Management
- **Export**: Full app data export from achievements screen menu
- **Import**: JSON file import with confirmation dialog
- **Backup**: Timestamped backup files with app version info
- **Copy Lists**: Custom lists can be copied to clipboard with paste functionality

### Profile Storage Architecture
- **Service**: `StorageService` handles all profile CRUD operations
- **Models**: `Player` model with JSON serialization for persistence
- **Deduplication**: Automatic duplicate removal by player ID
- **Statistics**: Integration with race results for win/loss tracking

## Development Guidelines

### Architecture Patterns
- **Service Layer**: Business logic separated from UI
- **Model-View Pattern**: Clean separation of data and presentation
- **State Management**: Local state with StatefulWidget and service pattern
- **Responsive Design**: Layout builders and media queries for adaptive UI

### Code Conventions
- Follow standard Dart/Flutter conventions
- Use meaningful variable and function names
- Keep widgets focused and composable
- Implement proper error handling
- Use const constructors where possible

### UI Development
- All layouts must be responsive and work on mobile, tablet, and desktop
- Use theme colors and avoid hardcoded colors
- Follow Material Design 3 principles
- Implement proper loading and error states
- Consider accessibility in all UI components

### Testing
- Write unit tests for services and business logic
- Test responsive layouts on different screen sizes
- Verify cross-platform compatibility
- Test edge cases and error conditions

## Project Status
This is a complete, production-ready Wikipedia racing application with comprehensive features, responsive design, and cross-platform support.