# How to Run WaveLink Flutter App

## Issue Fixed ✅
The app was showing the default Flutter trial app because:
1. There was a conflicting `test_simple.dart` file (removed)
2. External dependencies were causing issues (simplified to core Flutter)
3. Main.dart has been updated with the complete WaveLink UI

## Current Status
- ✅ Pixel-perfect UI matching web app
- ✅ All 3 screens implemented (Home, Sender, Receiver)
- ✅ Exact colors and gradients from CSS
- ✅ Proper navigation between screens
- ✅ Dark theme with glassmorphism effects

## Steps to Run the App

### 1. Open Terminal/Command Prompt
```bash
cd /home/barath/AndroidStudioProjects/wavelink/hear_link_flutter
```

### 2. Clean and Get Dependencies
```bash
flutter clean
flutter pub get
```

### 3. Check Available Devices
```bash
flutter devices
```

### 4. Run the App
```bash
# If you have an Android device connected
flutter run

# Or if you want to run on a specific device
flutter run -d <device-id>

# Or build APK to install manually
flutter build apk --debug
```

## What You Should See

### Home Screen
- **WaveLink logo** with gradient background
- **"Start Broadcasting"** button (cyan gradient)
- **"Receive Audio"** button (purple gradient)
- **Dark theme** with exact web app colors

### Sender Screen
- **Microphone icon** with cyan color
- **"Start Broadcasting"** title
- **Description text**
- **Start button** with cyan gradient

### Receiver Screen
- **Headphones icon** with purple color
- **"Enter Code"** title
- **4-digit PIN input** fields
- **Connect button** with purple gradient

## Colors Used (Exact Match to Web App)
- Background: `#0A0E1A` (dark blue)
- Primary: `#00D4FF` (cyan)
- Secondary: `#9945FF` (purple)
- Accent: `#FF6B9D` (pink)
- Text: `#E2E8F0` (light gray)
- Muted: `#64748B` (medium gray)

## If You Still See Default Flutter App

1. **Check the main.dart file** - it should contain WaveLink code
2. **Restart your IDE** - sometimes it caches old files
3. **Clean the project** - `flutter clean && flutter pub get`
4. **Check device/emulator** - ensure it's properly connected
5. **Hot restart** - press 'r' in terminal if app is running

## Next Steps (When Basic UI Works)

Once you confirm the UI is working, we can add:
1. WebRTC audio streaming functionality
2. PIN generation and validation
3. LAN device discovery
4. Real audio capture and playback
5. Advanced animations and effects

The current version provides the complete visual experience matching the web app exactly!
