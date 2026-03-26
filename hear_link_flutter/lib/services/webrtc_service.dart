import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:mdns_plus/mdns_plus.dart';

enum ConnectionState {
  idle,
  creatingOffer,
  waitingAnswer,
  connecting,
  connected,
  disconnected,
  failed,
}

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _remoteStreamController = StreamController<MediaStream>.broadcast();

  Stream<ConnectionState> get stateStream => _stateController.stream;
  Stream<MediaStream> get remoteStream => _remoteStreamController.stream;

  ConnectionState _currentState = ConnectionState.idle;
  ConnectionState get currentState => _currentState;

  void _setState(ConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> createPeerConnection() async {
    final configuration = RTCConfiguration(
      iceServers: [], // LAN only - no STUN/TURN servers
      iceCandidatePoolSize: 0,
    );

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _setState(ConnectionState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _setState(ConnectionState.failed);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _setState(ConnectionState.disconnected);
          break;
        default:
          break;
      }
    };

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      // For LAN connections, we typically don't need ICE candidates
      // as devices are on the same network
      if (kDebugMode) {
        print('ICE Candidate: ${candidate.candidate}');
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream!);
      }
    };
  }

  Future<MediaStream> getUserAudio() async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });
    _localStream = stream;
    return stream;
  }

  Future<String> createOffer() async {
    if (_peerConnection == null || _localStream == null) {
      throw Exception('PeerConnection or local stream not initialized');
    }

    _setState(ConnectionState.creatingOffer);

    // Add local stream tracks to peer connection
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Wait for ICE gathering to complete
    await _waitForIceGathering();

    return base64.encode(utf8.encode(
      jsonEncode(_peerConnection!.localDescription?.toMap()),
    ));
  }

  Future<String> createAnswer(String offerB64) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection not initialized');
    }

    final offerData = jsonDecode(utf8.decode(base64.decode(offerB64)));
    final offer = RTCSessionDescription(offerData['sdp'], offerData['type']);

    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Wait for ICE gathering to complete
    await _waitForIceGathering();

    return base64.encode(utf8.encode(
      jsonEncode(_peerConnection!.localDescription?.toMap()),
    ));
  }

  Future<void> acceptAnswer(String answerB64) async {
    if (_peerConnection == null) {
      throw Exception('PeerConnection not initialized');
    }

    final answerData = jsonDecode(utf8.decode(base64.decode(answerB64)));
    final answer = RTCSessionDescription(answerData['sdp'], answerData['type']);

    _setState(ConnectionState.connecting);
    await _peerConnection!.setRemoteDescription(answer);
  }

  Future<void> _waitForIceGathering() async {
    if (_peerConnection!.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }

    final completer = Completer<void>();
    late Timer timeoutTimer;

    void onIceGatheringStateChange() {
      if (_peerConnection!.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        timeoutTimer.cancel();
        _peerConnection!.off('iceGatheringStateChange', onIceGatheringStateChange);
        completer.complete();
      }
    }

    timeoutTimer = Timer(const Duration(seconds: 3), () {
      _peerConnection!.off('iceGatheringStateChange', onIceGatheringStateChange);
      completer.complete(); // Complete even if not finished to avoid hanging
    });

    _peerConnection!.on('iceGatheringStateChange', onIceGatheringStateChange);
    return completer.future;
  }

  void dispose() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _stateController.close();
    _remoteStreamController.close();
  }
}

class LANService {
  static const String _serviceName = 'wavelink';
  static const int _port = 8765;
  final MDNS _mdns = MDNS();
  final _sessionsController = StreamController<LANSession>.broadcast();

  Stream<LANSession> get sessions => _sessionsController.stream;

  Future<String> getLocalIPAddress() async {
    try {
      final info = await NetworkInfo().getWifiIP();
      return info ?? '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  Future<void> startDiscovery() async {
    await _mdns.start();

    _mdns.listenForService(_serviceName).listen((service) {
      final session = LANSession(
        name: service.name,
        host: service.host,
        port: service.port,
        txt: service.txt,
      );
      _sessionsController.add(session);
    });
  }

  Future<void> registerService(String pin) async {
    await _mdns.start();

    final txt = {
      'pin': pin,
      'type': 'sender',
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    await _mdns.registerService(
      name: 'wavelink-$pin',
      type: _serviceName,
      port: _port,
      txt: txt,
    );
  }

  Future<void> stopDiscovery() async {
    await _mdns.stop();
    await _sessionsController.close();
  }

  Future<void> unregisterService() async {
    await _mdns.stop();
  }
}

class LANSession {
  final String name;
  final String host;
  final int port;
  final Map<String, String> txt;

  LANSession({
    required this.name,
    required this.host,
    required this.port,
    required this.txt,
  });

  String? get pin => txt['pin'];
  String? get type => txt['type'];
}

class SignalingService {
  final Map<String, String> _offers = {};
  final Map<String, String> _answers = {};

  // Store offer for PIN
  void storeOffer(String pin, String offer) {
    _offers[pin] = offer;
    // Remove any existing answer for this PIN
    _answers.remove(pin);
  }

  // Get offer for PIN
  String? getOffer(String pin) {
    return _offers[pin];
  }

  // Store answer for PIN
  void storeAnswer(String pin, String answer) {
    _answers[pin] = answer;
  }

  // Get answer for PIN
  String? getAnswer(String pin) {
    return _answers[pin];
  }

  // Clean up session
  void cleanupSession(String pin) {
    _offers.remove(pin);
    _answers.remove(pin);
  }

  // Check if PIN exists
  bool hasPin(String pin) {
    return _offers.containsKey(pin);
  }
}
