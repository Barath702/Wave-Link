# WaveLink Flutter - Offline Audio Streaming

A fully native Flutter Android application that converts the WaveLink web app into a premium offline audio streaming solution.

## 🎯 Project Overview

WaveLink Flutter enables real-time audio streaming between devices on the same local network without requiring internet connectivity. This is a pixel-perfect recreation of the original web application with native performance.

## ✨ Features

### 🎨 UI/UX
- **Pixel-perfect design** matching the original web app
- **Glassmorphism effects** with backdrop blur
- **Animated gradients** and glow effects
- **Smooth animations** and transitions
- **Dark theme** with exact color matching
- **Responsive design** for all Android screen sizes

### 🎵 Audio Features
- **Real-time audio streaming** via WebRTC
- **Low latency** (<300ms target)
- **Audio visualization** with waveform display
- **Sound level indicators**
- **Mute/unmute controls**
- **Live connection status**

### 🔗 Connection System
- **4-digit PIN pairing** - simple and secure
- **LAN-only discovery** using mDNS/Bonjour
- **Peer-to-peer WebRTC** connections
- **Automatic device discovery**
- **Connection state management**

### 📱 Android Native
- **Offline-first** architecture
- **Microphone permissions** handling
- **Network access** for LAN communication
- **Material Design 3** integration
- **Production-ready** build configuration

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── theme/                   # Design system
│   └── app_theme.dart       # Colors, gradients, styles
├── screens/                 # UI screens
│   ├── home_screen.dart     # Main menu
│   ├── sender_screen.dart   # Broadcasting UI
│   └── receiver_screen.dart # Receiving UI
├── widgets/                # Reusable components
│   ├── common_widgets.dart  # Glass cards, buttons, blobs
│   └── audio_widgets.dart   # PIN input, waveform
├── services/               # Business logic
│   └── webrtc_service.dart # Audio streaming & LAN discovery
├── providers/              # State management
│   └── connection_providers.dart # Riverpod providers
└── models/                # Data models
    └── connection_state.dart  # Connection enums & classes
```

## 🎨 Design System

### Colors (Exact CSS Match)
- **Background**: `#0A0E1A` (hsl(225 30% 6%))
- **Primary**: `#00D4FF` (hsl(200 100% 50%))
- **Secondary**: `#9945FF` (hsl(270 60% 55%))
- **Accent**: `#FF6B9D` (hsl(330 80% 60%))

### Gradients
- **Hero**: Dark blue gradient background
- **Sender**: Cyan to turquoise gradient
- **Receiver**: Purple to pink gradient
- **Accent**: Primary to secondary blend

### Effects
- **Glass cards**: 20% blur with subtle borders
- **Glow effects**: Dynamic shadows on interactive elements
- **Blob animations**: Floating background elements
- **Pulse effects**: Live status indicators

## 🔧 Setup & Installation

### Prerequisites
- Flutter SDK (>=3.11.3)
- Android SDK with API level 21+
- Android Studio or VS Code with Flutter extension

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd hear_link_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Android**
   ```bash
   flutter doctor --android-licenses
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## 🔐 Permissions

The app requires these Android permissions:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

## 🌐 Network Architecture

### LAN Discovery (mDNS)
- **Service Name**: `wavelink`
- **Port**: `8765`
- **Protocol**: UDP/TCP hybrid
- **Data**: PIN, device info, timestamp

### WebRTC Signaling
- **Offer/Answer Exchange**: Base64 encoded SDP
- **ICE Gathering**: LAN-only (no STUN/TURN)
- **Codec**: Opus (default WebRTC audio codec)
- **Encryption**: DTLS-SRTP (WebRTC standard)

## 📱 Usage Instructions

### As Sender (Broadcast)
1. Open WaveLink Flutter
2. Tap "Start Broadcasting"
3. Grant microphone permission
4. Note the 4-digit PIN displayed
5. Wait for receiver connection

### As Receiver (Listen)
1. Open WaveLink Flutter
2. Tap "Receive Audio"
3. Enter the 4-digit PIN from sender
4. Wait for connection to establish
5. Audio will play automatically

## 🚀 Performance Optimizations

### Target Metrics
- **Connection Time**: <3 seconds
- **Audio Latency**: <300ms
- **UI Frame Rate**: 60fps
- **Memory Usage**: <100MB
- **Battery Impact**: Minimal

### Optimizations Implemented
- **Efficient animations** with Flutter's built-in engine
- **WebRTC optimizations** for LAN environments
- **State management** with Riverpod for minimal rebuilds
- **Lazy loading** of heavy components
- **Memory management** with proper disposal

## 🔧 Development

### Adding Features
1. Create widgets in `lib/widgets/`
2. Add screens in `lib/screens/`
3. Update state in `lib/providers/`
4. Follow the existing design system

### Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### Code Style
- Follow Dart official style guide
- Use Riverpod for state management
- Implement proper disposal patterns
- Add documentation for public APIs

## 🐛 Troubleshooting

### Common Issues

**Microphone Permission Denied**
- Go to Settings > Apps > WaveLink > Permissions
- Enable Microphone permission
- Restart the app

**Devices Not Discovering Each Other**
- Ensure both devices are on the same WiFi network
- Check that firewall allows mDNS traffic
- Restart both apps and try again

**Audio Quality Issues**
- Check microphone distance and volume
- Ensure stable WiFi connection
- Restart the streaming session

**Connection Drops**
- Verify WiFi signal strength
- Check for network interference
- Re-establish the connection

## 📄 License

This project is proprietary and confidential. All rights reserved.

## 🤝 Contributing

This is a closed-source project. Please do not submit pull requests.

---

**WaveLink Flutter** - Premium offline audio streaming for Android 🎵
