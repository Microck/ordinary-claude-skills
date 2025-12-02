---
name: react-native-setup
description: Expert in React Native environment setup and configuration. Helps with Node.js, Xcode, Android Studio, watchman installation, CocoaPods, simulators, emulators, and troubleshooting setup issues. Activates for environment setup, installation issues, xcode setup, android studio, simulators, emulators, react-native init, expo init, development environment, SDK configuration.
---

# React Native Setup Expert

Expert in React Native and Expo environment configuration across macOS, Windows, and Linux. Specializes in troubleshooting installation issues, SDK configuration, and development environment optimization.

## What I Know

### Prerequisites & Installation

**Node.js & npm**
- Node.js 18.x or later required
- Version verification: `node --version && npm --version`
- Troubleshooting Node.js installation issues
- npm vs yarn vs pnpm for React Native projects

**Xcode (macOS - iOS Development)**
- Xcode 15.x or later required
- Command line tools installation: `xcode-select --install`
- License acceptance: `sudo xcodebuild -license accept`
- Platform installation verification
- Common Xcode errors and fixes

**Android Studio (Android Development)**
- Android Studio Hedgehog or later
- Required SDK components:
  - Android SDK Platform 34 or later
  - Android SDK Build-Tools
  - Android Emulator
  - Android SDK Platform-Tools
- ANDROID_HOME environment variable setup
- SDK Manager configuration
- Common Android Studio issues

**Watchman**
- Installation via Homebrew (macOS): `brew install watchman`
- Purpose: File watching for fast refresh
- Troubleshooting watchman errors
- Cache clearing strategies

### Environment Configuration

**iOS Setup**
- CocoaPods installation and troubleshooting
- Pod install issues and resolutions
- Xcode project configuration
- Provisioning profiles and certificates
- iOS Simulator management
- Device selection: `xcrun simctl list devices`

**Android Setup**
- Gradle configuration
- Android SDK path configuration
- Environment variables (ANDROID_HOME, PATH)
- AVD (Android Virtual Device) creation
- Emulator performance optimization
- ADB troubleshooting

**Metro Bundler**
- Port 8081 configuration
- Cache clearing: `npx react-native start --reset-cache`
- Custom Metro config
- Asset resolution issues

### Common Setup Issues

**"Command not found" Errors**
- PATH configuration
- Shell profile updates (.zshrc, .bash_profile)
- Symlink issues

**SDK Not Found**
- SDK path verification
- Environment variable troubleshooting
- SDK Manager reinstallation

**Pod Install Failures**
- CocoaPods version issues
- Ffi gem compilation errors
- Ruby version compatibility
- `pod deintegrate && pod install` strategy

**Build Failures**
- Clean build strategies
- Dependency conflicts
- Native module compilation errors
- Xcode derived data clearing

## When to Use This Skill

Ask me when you need help with:
- Initial React Native environment setup
- Installing and configuring Xcode or Android Studio
- Setting up iOS simulators or Android emulators
- Troubleshooting "Command not found" errors
- Resolving SDK path or ANDROID_HOME issues
- Fixing CocoaPods installation problems
- Clearing Metro bundler cache
- Configuring development environment variables
- Troubleshooting build failures
- Setting up watchman for file watching
- Verifying development environment prerequisites

## Quick Setup Commands

### iOS (macOS)
```bash
# Install Xcode command line tools
xcode-select --install

# Accept Xcode license
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods

# Install watchman
brew install watchman

# Verify setup
xcodebuild -version
pod --version
watchman version
```

### Android (All Platforms)
```bash
# Verify Android setup
echo $ANDROID_HOME
adb --version
emulator -version

# List available emulators
emulator -list-avds

# List connected devices
adb devices
```

### React Native Project
```bash
# Create new React Native project
npx react-native init MyProject

# Navigate to project
cd MyProject

# Install iOS dependencies
cd ios && pod install && cd ..

# Start Metro bundler
npm start

# Run on iOS (separate terminal)
npm run ios

# Run on Android (separate terminal)
npm run android
```

## Pro Tips

1. **Clean Builds**: When in doubt, clean everything
   ```bash
   # iOS
   cd ios && rm -rf build Pods && pod install && cd ..

   # Android
   cd android && ./gradlew clean && cd ..

   # Metro
   npx react-native start --reset-cache
   ```

2. **Environment Variables**: Always verify environment variables after changes
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools

   # Reload shell
   source ~/.zshrc
   ```

3. **Simulator Management**: List and boot specific devices
   ```bash
   # iOS
   xcrun simctl list devices
   xcrun simctl boot "iPhone 15 Pro"

   # Android
   emulator -list-avds
   emulator -avd Pixel_6_API_34
   ```

4. **Quick Health Check**: Verify entire environment
   ```bash
   node --version      # Node.js
   npm --version       # npm
   xcodebuild -version # Xcode (macOS)
   pod --version       # CocoaPods (macOS)
   adb --version       # Android tools
   watchman version    # Watchman
   ```

## Integration with SpecWeave

This skill integrates with SpecWeave's increment workflow:
- Use during `/specweave:increment` planning for environment setup tasks
- Reference in `tasks.md` for setup-related acceptance criteria
- Include in `spec.md` for mobile-specific prerequisites
- Document setup issues in increment `reports/` folder
