enum ConnectionStep {
  setup,
  pin,
  live,
}

enum AppMode {
  sender,
  receiver,
}

class AudioLevel {
  final double level;
  final DateTime timestamp;

  AudioLevel({
    required this.level,
    required this.timestamp,
  });
}

class ConnectionInfo {
  final String pin;
  final String deviceId;
  final String deviceName;
  final DateTime timestamp;

  ConnectionInfo({
    required this.pin,
    required this.deviceId,
    required this.deviceName,
    required this.timestamp,
  });
}
