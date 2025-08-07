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

# Generate platform-specific code
flutter create --platforms=android,ios,web,windows,linux,macos .
```

## Project Architecture

### Current State
This is a freshly created Flutter project with minimal implementation:
- **Entry Point**: `lib/main.dart` contains a basic MaterialApp with "Hello World" text
- **Dependencies**: Only core Flutter dependencies and flutter_lints for code analysis
- **Platforms**: Configured for all Flutter platforms (Android, iOS, Web, Windows, Linux, macOS)

### Project Structure
- `lib/`: Main Dart source code directory (currently contains only main.dart)
- `android/`: Android-specific configuration and native code
- `ios/`: iOS-specific configuration and native code
- `web/`: Web-specific assets and configuration
- `windows/`: Windows-specific configuration and native code
- `linux/`: Linux-specific configuration and native code  
- `macos/`: macOS-specific configuration and native code

### Code Quality
- Uses `flutter_lints` package with default Flutter linting rules
- Analysis options configured in `analysis_options.yaml`
- Follows standard Flutter project conventions

## Development Notes

### Project
This project is a wikapeadia racer which makes it easy for people to race there friends from one wikapedia page to another and supports that with a variety of features.

### Project Name
The project is named "wikapediaracer" - appears to be intended as a Wikipedia-related racing/speed game or application.

### Current Development Phase
This is a skeleton Flutter project that needs implementation. The basic structure is in place but the actual application logic needs to be developed.