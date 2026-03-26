import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import '../models/connection_state.dart';

// WebRTC Service Provider
final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final service = WebRTCService();
  ref.onDispose(() => service.dispose());
  return service;
});

// LAN Service Provider
final lanServiceProvider = Provider<LANService>((ref) {
  final service = LANService();
  ref.onDispose(() {
    service.stopDiscovery();
    service.unregisterService();
  });
  return service;
});

// Signaling Service Provider
final signalingServiceProvider = Provider<SignalingService>((ref) {
  return SignalingService();
});

// Connection State Provider
final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  final webrtcService = ref.watch(webrtcServiceProvider);
  return webrtcService.stateStream;
});

// Remote Stream Provider
final remoteStreamProvider = StreamProvider<MediaStream?>((ref) {
  final webrtcService = ref.watch(webrtcServiceProvider);
  return webrtcService.remoteStream;
});

// PIN Provider for Sender
final pinProvider = StateProvider<String>((ref) => '');

// Sender State Provider
class SenderState {
  final String pin;
  final bool isBroadcasting;
  final bool isConnected;
  final bool isMuted;
  final String statusText;
  final String? error;

  SenderState({
    this.pin = '',
    this.isBroadcasting = false,
    this.isConnected = false,
    this.isMuted = false,
    this.statusText = 'Ready to broadcast',
    this.error,
  });

  SenderState copyWith({
    String? pin,
    bool? isBroadcasting,
    bool? isConnected,
    bool? isMuted,
    String? statusText,
    String? error,
  }) {
    return SenderState(
      pin: pin ?? this.pin,
      isBroadcasting: isBroadcasting ?? this.isBroadcasting,
      isConnected: isConnected ?? this.isConnected,
      isMuted: isMuted ?? this.isMuted,
      statusText: statusText ?? this.statusText,
      error: error,
    );
  }
}

final senderStateProvider = StateNotifierProvider<SenderNotifier, SenderState>((ref) {
  return SenderNotifier(ref);
});

class SenderNotifier extends StateNotifier<SenderState> {
  final Ref ref;
  Timer? _answerPollTimer;

  SenderNotifier(this.ref) : super(SenderState());

  Future<void> startBroadcast() async {
    try {
      state = state.copyWith(
        isBroadcasting: true,
        error: null,
        statusText: 'Initializing...',
      );

      final webrtcService = ref.read(webrtcServiceProvider);
      final lanService = ref.read(lanServiceProvider);
      final signalingService = ref.read(signalingServiceProvider);

      // Initialize WebRTC
      await webrtcService.createPeerConnection();
      final localStream = await webrtcService.getUserAudio();
      
      // Generate PIN
      final pin = _generatePin();
      state = state.copyWith(pin: pin);

      // Create offer
      final offer = await webrtcService.createOffer();
      
      // Store offer in signaling
      signalingService.storeOffer(pin, offer);

      // Register with mDNS
      await lanService.registerService(pin);

      state = state.copyWith(
        statusText: 'Waiting for receiver...',
      );

      // Start polling for answer
      _startAnswerPolling(pin);

    } catch (e) {
      state = state.copyWith(
        error: _getErrorMessage(e),
        isBroadcasting: false,
      );
    }
  }

  void _startAnswerPolling(String pin) {
    _answerPollTimer?.cancel();
    _answerPollTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final signalingService = ref.read(signalingServiceProvider);
      final answer = signalingService.getAnswer(pin);
      
      if (answer != null) {
        timer.cancel();
        await _handleAnswer(answer);
      }
    });
  }

  Future<void> _handleAnswer(String answer) async {
    try {
      state = state.copyWith(
        statusText: 'Receiver found! Connecting...',
      );

      final webrtcService = ref.read(webrtcServiceProvider);
      await webrtcService.acceptAnswer(answer);

      state = state.copyWith(
        isConnected: true,
        statusText: 'Connected',
      );

    } catch (e) {
      state = state.copyWith(
        error: 'Connection failed. Try again.',
        isConnected: false,
      );
    }
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void stopBroadcast() {
    _answerPollTimer?.cancel();
    
    final lanService = ref.read(lanServiceProvider);
    final signalingService = ref.read(signalingServiceProvider);
    
    lanService.unregisterService();
    signalingService.cleanupSession(state.pin);
    
    state = SenderState();
  }

  String _generatePin() {
    return (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Permission denied')) {
      return 'Microphone access denied. Please grant permission in settings.';
    } else if (error.toString().contains('NotFound')) {
      return 'No microphone found on this device.';
    } else {
      return 'Failed to start broadcasting. Please try again.';
    }
  }

  @override
  void dispose() {
    _answerPollTimer?.cancel();
    super.dispose();
  }
}

// Receiver State Provider
class ReceiverState {
  final bool isConnecting;
  final bool isConnected;
  final String? error;

  ReceiverState({
    this.isConnecting = false,
    this.isConnected = false,
    this.error,
  });

  ReceiverState copyWith({
    bool? isConnecting,
    bool? isConnected,
    String? error,
  }) {
    return ReceiverState(
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}

final receiverStateProvider = StateNotifierProvider<ReceiverNotifier, ReceiverState>((ref) {
  return ReceiverNotifier(ref);
});

class ReceiverNotifier extends StateNotifier<ReceiverState> {
  final Ref ref;

  ReceiverNotifier(this.ref) : super(ReceiverState());

  Future<void> connectToSender(String pin) async {
    try {
      state = state.copyWith(
        isConnecting: true,
        error: null,
      );

      final webrtcService = ref.read(webrtcServiceProvider);
      final lanService = ref.read(lanServiceProvider);
      final signalingService = ref.read(signalingServiceProvider);

      // Initialize WebRTC
      await webrtcService.createPeerConnection();

      // Check if PIN exists
      if (!signalingService.hasPin(pin)) {
        state = state.copyWith(
          error: 'Device not found. Check the code and try again.',
          isConnecting: false,
        );
        return;
      }

      // Get offer
      final offer = signalingService.getOffer(pin);
      if (offer == null) {
        state = state.copyWith(
          error: 'Device not found. Check the code and try again.',
          isConnecting: false,
        );
        return;
      }

      // Create answer
      final answer = await webrtcService.createAnswer(offer);
      
      // Store answer
      signalingService.storeAnswer(pin, answer);

      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
      );

    } catch (e) {
      state = state.copyWith(
        error: 'Connection failed. Please try again.',
        isConnecting: false,
      );
    }
  }

  void disconnect() {
    state = ReceiverState();
  }
}
