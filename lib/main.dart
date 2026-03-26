import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart' hide Router;
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';

// Connection States
enum ConnectionState {
  idle,
  broadcasting,
  discovering,
  connecting,
  connected,
  failed,
}

// mDNS Service - Proper Bonsoir Implementation
class MDNSService {
  static final MDNSService _instance = MDNSService._internal();
  factory MDNSService() => _instance;
  MDNSService._internal();

  final Map<String, DiscoveredDevice> _discoveredDevices = {};
  final StreamController<Map<String, DiscoveredDevice>> _discoveryController = 
      StreamController<Map<String, DiscoveredDevice>>.broadcast();
  
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  bool _isRunning = false;

  Stream<Map<String, DiscoveredDevice>> get discoveredDevices => _discoveryController.stream;

  Future<void> startService() async {
    if (_isRunning) return;
    
    print("🚀 Starting Bonsoir mDNS service");
    _isRunning = true;

    try {
      _discovery = BonsoirDiscovery(type: "_hearlink._tcp");
      await _discovery!.ready;
      
      _discovery!.eventStream!.listen((event) {
        print("🔍 Discovery event: ${event.type}");

        if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
          event.service?.resolve(_discovery!.serviceResolver);
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
          final service = event.service as ResolvedBonsoirService?;
          if (service != null && service.attributes != null) {
            final code = service.attributes!['code'];
            final deviceName = service.name;
            final ipAddress = service.host;
            
            if (code != null && ipAddress != null) {
              final device = DiscoveredDevice(
                code: code,
                deviceName: deviceName,
                ipAddress: ipAddress,
                port: service.port,
                status: 'available',
                lastSeen: DateTime.now(),
              );
              
              _discoveredDevices[code] = device;
              _discoveryController.add(Map.from(_discoveredDevices));
              print("✅ Resolved mDNS service: $deviceName ($code) at $ipAddress:${service.port}");
            }
          }
        } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
          final service = event.service;
          if (service != null && service.attributes != null) {
            final code = service.attributes!['code'];
            if (code != null && _discoveredDevices.containsKey(code)) {
              _discoveredDevices.remove(code);
              _discoveryController.add(Map.from(_discoveredDevices));
              print("🗑️ Lost mDNS service: $code");
            }
          }
        }
      });
      
      await _discovery!.start();
      print("✅ Bonsoir discovery started");
    } catch (e) {
      print("❌ Failed to start Bonsoir discovery: $e");
    }
  }

  Future<void> startBroadcasting(String code, String deviceName, int port) async {
    print("📡 Starting Bonsoir broadcasting with code: $code on port $port");

    try {
      final service = BonsoirService(
        name: "hearlink-$code",
        type: "_hearlink._tcp",
        port: port,
        attributes: {
          'code': code,
          'deviceName': deviceName,
          'status': 'available',
        },
      );

      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.ready;
      await _broadcast!.start();

      print("✅ Bonsoir broadcasting started: hearlink-$code._hearlink._tcp");
    } catch (e) {
      print("❌ Failed to start Bonsoir broadcast: $e");
    }
  }

  void stopBroadcasting() {
    print("🛑 Stopping Bonsoir broadcasting");
    _broadcast?.stop();
    _broadcast = null;
  }

  void stopService() {
    print("🛑 Stopping Bonsoir service");
    _isRunning = false;
    _broadcast?.stop();
    _discovery?.stop();
    _discoveredDevices.clear();
  }

  DiscoveredDevice? findDeviceByCode(String code) {
    return _discoveredDevices[code];
  }
}

class DiscoveredDevice {
  final String code;
  final String deviceName;
  final String ipAddress;
  final int port;
  final String status;
  final DateTime lastSeen;

  DiscoveredDevice({
    required this.code,
    required this.deviceName,
    required this.ipAddress,
    required this.port,
    required this.status,
    required this.lastSeen,
  });

  @override
  String toString() => 'DiscoveredDevice(code: $code, device: $deviceName, ip: $ipAddress:$port)';
}

// WebRTC Service - Real Audio Transmission
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  final MDNSService _mdnsService = MDNSService();
  
  ConnectionState _state = ConnectionState.idle;
  String? _currentCode;
  String? _connectedDevice;
  DiscoveredDevice? _connectedDeviceInfo;
  final StreamController<ConnectionState> _stateController = StreamController<ConnectionState>.broadcast();
  
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  HttpServer? _signalingServer;

  static const platform = MethodChannel('com.wavelink/foreground_service');

  ConnectionState get state => _state;
  String? get currentCode => _currentCode;
  String? get connectedDevice => _connectedDevice;
  DiscoveredDevice? get connectedDeviceInfo => _connectedDeviceInfo;
  Stream<ConnectionState> get stateStream => _stateController.stream;

  void _setState(ConnectionState newState) {
    print("🔄 State change: $_state → $newState");
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> _initPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [],
      'sdpSemantics': 'unified-plan',
    };
    
    _peerConnection = await createPeerConnection(configuration);
    
    _peerConnection!.onConnectionState = (state) {
      print("🌐 WebRTC Connection State: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _setState(ConnectionState.connected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed || 
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _setState(ConnectionState.failed);
      }
    };

    _peerConnection!.onTrack = (event) {
      print("🔊 Received remote track: ${event.track.kind}");
      if (event.track.kind == 'audio') {
        Helper.setSpeakerphoneOn(true);
      }
    };

    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()..id = 1..negotiated = false;
    _dataChannel = await _peerConnection!.createDataChannel("sync", dataChannelDict);
    _dataChannel!.onMessage = _handleDataChannelMessage;

    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _dataChannel!.onMessage = _handleDataChannelMessage;
    };
  }

  void _handleDataChannelMessage(RTCDataChannelMessage message) {
    if (message.text == "disconnect") {
      print("🛑 Received disconnect signal from peer");
      if (_signalingServer != null) {
        stopBroadcast();
      } else {
        disconnect();
      }
    }
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> _waitForIceGathering() async {
    if (_peerConnection!.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final completer = Completer<void>();
    _peerConnection!.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        if (!completer.isCompleted) completer.complete();
      }
    };
    // Fallback timeout
    Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<String> startBroadcast(String code, String deviceName) async {
    print("🎙️ Starting broadcast with code: $code");
    _setState(ConnectionState.broadcasting);
    _currentCode = code;

    // 1. Request Microphone Permissions
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _setState(ConnectionState.failed);
      throw Exception("Microphone permission denied");
    }

    await _configureAudioSession();
    try { await platform.invokeMethod('startService'); } catch (e) { print(e); }

    // 2. Start Signaling Server (Shelf)
    final router = Router();
    router.post('/connect', (Request request) async {
      if (_state == ConnectionState.connecting || _state == ConnectionState.connected) {
        return Response.forbidden("Already connected or connecting");
      }
      _setState(ConnectionState.connecting);

      final body = await request.readAsString();
      final data = jsonDecode(body);
      final remoteOffer = data['sdp'];
      final remoteType = data['type'];
      final remoteDevice = data['deviceName'];

      print("🤝 Received connection request from $remoteDevice");

      await _initPeerConnection();
      
      // Add local audio stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      await _peerConnection!.setRemoteDescription(RTCSessionDescription(remoteOffer, remoteType));
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // Wait for ICE candidates (LAN host addresses)
      await _waitForIceGathering();

      final localDescription = await _peerConnection!.getLocalDescription();
      _connectedDevice = remoteDevice;
      
      // Stop broadcasting to other devices once paired
      _mdnsService.stopBroadcasting();

      return Response.ok(jsonEncode({
        'sdp': localDescription?.sdp,
        'type': localDescription?.type,
      }));
    });

    _signalingServer = await io.serve(router, InternetAddress.anyIPv4, 8888);
    print("📡 Signaling server listening on port ${_signalingServer!.port}");

    // 3. Start mDNS broadcasting
    await _mdnsService.startBroadcasting(code, deviceName, _signalingServer!.port);
    
    print("✅ Broadcast initialized and waiting for receiver");
    return code;
  }

  Future<bool> connectToDevice(String code, String deviceName) async {
    print("🔗 Connecting to device with code: $code");
    _setState(ConnectionState.connecting);

    await _configureAudioSession();
    try { await platform.invokeMethod('startService'); } catch (e) { print(e); }

    final device = _mdnsService.findDeviceByCode(code);
    if (device == null) {
      print("❌ Device not found for code: $code");
      _setState(ConnectionState.failed);
      return false;
    }
    
    try {
      await _initPeerConnection();

      // Receiver creates offer
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Wait for ICE candidates (LAN host addresses)
      await _waitForIceGathering();

      final localDescription = await _peerConnection!.getLocalDescription();

      // Send offer via signaling HTTP
      print("🤝 Sending offer to ${device.ipAddress}:${device.port}");
      final response = await http.post(
        Uri.parse('http://${device.ipAddress}:${device.port}/connect'),
        body: jsonEncode({
          'sdp': localDescription?.sdp,
          'type': localDescription?.type,
          'deviceName': deviceName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = RTCSessionDescription(data['sdp'], data['type']);
        await _peerConnection!.setRemoteDescription(answer);
        
        _currentCode = code;
        _connectedDevice = device.deviceName;
        _connectedDeviceInfo = device;
        print("✅ Handshake complete, awaiting WebRTC connection...");
        return true;
      } else {
        print("❌ Signaling failed: ${response.statusCode}");
        _setState(ConnectionState.failed);
        return false;
      }
    } catch (e) {
      print("❌ Connection error: $e");
      _setState(ConnectionState.failed);
      return false;
    }
  }

  void startAudioStreaming() {
    print("🎵 Audio streaming handled via WebRTC tracks");
  }

  void stopBroadcast() {
    print("🛑 Stopping broadcast");
    _sendStopSignal();
    _mdnsService.stopBroadcasting();
    _signalingServer?.close();
    _signalingServer = null;
    _cleanupWebRTC();
    try { platform.invokeMethod('stopService'); } catch (e) { print(e); }
    _setState(ConnectionState.idle);
  }

  void disconnect() {
    print("🔌 Disconnecting");
    _sendStopSignal();
    _cleanupWebRTC();
    try { platform.invokeMethod('stopService'); } catch (e) { print(e); }
    _setState(ConnectionState.idle);
  }
  
  void _sendStopSignal() {
    if (_dataChannel != null && _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      try { _dataChannel!.send(RTCDataChannelMessage("disconnect")); } catch(e) { print("Failed to send stop signal: $e"); }
    }
  }

  void _cleanupWebRTC() {
    _dataChannel?.close();
    _dataChannel = null;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _currentCode = null;
    _connectedDevice = null;
    _connectedDeviceInfo = null;
  }

  void dispose() {
    _stateController.close();
    _cleanupWebRTC();
    _signalingServer?.close();
  }
}

// Main App
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MDNSService().startService();
  runApp(const WaveLinkApp());
}

class WaveLinkApp extends StatelessWidget {
  const WaveLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaveLink Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00D4FF),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D4FF),
          secondary: Color(0xFF9945FF),
          surface: Color(0xFF1A2332),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1729), Color(0xFF1E293B), Color(0xFF1A2332)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00D4FF), Color(0xFF9945FF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.3), blurRadius: 30)],
                  ),
                  child: const Icon(Icons.wifi, color: Color(0xFF0A0E1A), size: 40),
                ),
                const SizedBox(height: 16),
                const Text('WaveLink', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0))),
                const SizedBox(height: 8),
                const Text('Real-time audio streaming over your local network.\nNo internet needed.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                const SizedBox(height: 48),
                _buildModeButton(context, 'Start Broadcasting', 'Stream audio from this device', Icons.radio, [Color(0xFF00E5CC), Color(0xFF00FFE5)], () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SenderScreen()))),
                const SizedBox(height: 16),
                _buildModeButton(context, 'Receive Audio', 'Listen from another device', Icons.headphones, [Color(0xFF9945FF), Color(0xFFFF6B9D)], () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ReceiverScreen()))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, String title, String sub, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Container(
      width: double.infinity, height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 30)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.black, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sender Screen
class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});
  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  bool _isLoading = false;
  String? _generatedCode;
  String _statusText = 'Ready to broadcast';
  late StreamSubscription<ConnectionState> _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _webrtcService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          switch (state) {
            case ConnectionState.idle: _statusText = 'Ready to broadcast'; break;
            case ConnectionState.broadcasting: _statusText = 'Waiting for receiver...'; break;
            case ConnectionState.connected: _statusText = 'Connected!'; _navigateToLiveScreen(); break;
            case ConnectionState.failed: _statusText = 'Connection failed'; break;
            default: break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    super.dispose();
  }

  void _navigateToLiveScreen() {
    if (_generatedCode != null && _webrtcService.connectedDevice != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SenderLiveScreen(code: _generatedCode!, receiverName: _webrtcService.connectedDevice!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F1729), Color(0xFF1E293B)])),
        child: SafeArea(
          child: Column(
            children: [
              _header(context, 'Sender'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_generatedCode == null) ...[
                          const Icon(Icons.mic, size: 80, color: Color(0xFF00D4FF)),
                          const SizedBox(height: 24),
                          const Text('Start Broadcasting', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 32),
                          _button('Start Broadcasting', _startBroadcast, const Color(0xFF00D4FF), _isLoading),
                        ] else ...[
                          const Icon(Icons.broadcast_on_personal, size: 80, color: Color(0xFF00D4FF)),
                          const SizedBox(height: 24),
                          const Text('Share this code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _codeDisplay(_generatedCode!),
                          const SizedBox(height: 16),
                          Text(_statusText, style: const TextStyle(color: Color(0xFF64748B))),
                          const SizedBox(height: 32),
                          _button('Stop Broadcasting', _stopBroadcast, const Color(0xFFEF4444), false),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _button(String text, VoidCallback? onPressed, Color color, bool loading) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _codeDisplay(String code) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1A2332).withOpacity(0.4), border: Border.all(color: const Color(0xFF334155), width: 2), borderRadius: BorderRadius.circular(16)),
      child: Text(code, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF00D4FF), letterSpacing: 8)),
    );
  }

  Future<void> _startBroadcast() async {
    setState(() => _isLoading = true);
    try {
      final code = (1000 + Random().nextInt(9000)).toString();
      final deviceName = "Sender-${Platform.localHostname}";
      await _webrtcService.startBroadcast(code, deviceName);
      setState(() { _generatedCode = code; _isLoading = false; });
    } catch (e) {
      setState(() { _isLoading = false; _statusText = 'Error: $e'; });
    }
  }

  void _stopBroadcast() {
    _webrtcService.stopBroadcast();
    setState(() => _generatedCode = null);
  }
}

// Receiver Screen
class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});
  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final WebRTCService _webrtcService = WebRTCService();
  final MDNSService _mdnsService = MDNSService();
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, DiscoveredDevice> _discoveredDevices = {};
  late StreamSubscription<Map<String, DiscoveredDevice>> _discoverySubscription;
  late StreamSubscription<ConnectionState> _stateSubscription;

  @override
  void initState() {
    super.initState();
    _discoverySubscription = _mdnsService.discoveredDevices.listen((devices) {
      if (mounted) setState(() => _discoveredDevices = devices);
    });
    _stateSubscription = _webrtcService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          if (state == ConnectionState.connected) {
            _isLoading = false;
            _navigateToListeningScreen();
          } else if (state == ConnectionState.failed) {
            _isLoading = false;
            _errorMessage = 'Connection failed.';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _discoverySubscription.cancel();
    _stateSubscription.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _navigateToListeningScreen() {
    if (_webrtcService.connectedDeviceInfo != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ReceiverListeningScreen(code: _webrtcService.currentCode!, senderName: _webrtcService.connectedDevice!, deviceInfo: _webrtcService.connectedDeviceInfo!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F1729), Color(0xFF1E293B)])),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.headphones, size: 80, color: Color(0xFF9945FF)),
                        const SizedBox(height: 24),
                        const Text('Enter Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        _pinInput(),
                        if (_errorMessage != null) ...[const SizedBox(height: 16), Text(_errorMessage!, style: const TextStyle(color: Colors.red))],
                        const SizedBox(height: 32),
                        _button(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 8),
        const Text('Receiver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_discoveredDevices.length} active', style: const TextStyle(color: Colors.green, fontSize: 12)),
      ]),
    );
  }

  Widget _pinInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) => Container(
        width: 60, height: 70,
        decoration: BoxDecoration(color: const Color(0xFF1A2332).withOpacity(0.4), border: Border.all(color: const Color(0xFF334155), width: 2), borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: _controllers[index], focusNode: _focusNodes[index],
          textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(counterText: '', border: InputBorder.none),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) _focusNodes[index + 1].requestFocus();
            if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          },
        ),
      )),
    );
  }

  Widget _button() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _connect,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9945FF), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: _isLoading ? const CircularProgressIndicator() : const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _connect() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    
    // Retry discovery
    DiscoveredDevice? device;
    for (int i = 0; i < 5; i++) {
      device = _mdnsService.findDeviceByCode(code);
      if (device != null) break;
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (device == null) {
      setState(() { _isLoading = false; _errorMessage = 'Device not found. Check WiFi and Code.'; });
      return;
    }

    final deviceName = "Receiver-${Platform.localHostname}";
    await _webrtcService.connectToDevice(code, deviceName);
  }
}

// Live Screens
class SenderLiveScreen extends StatefulWidget {
  final String code;
  final String receiverName;
  const SenderLiveScreen({super.key, required this.code, required this.receiverName});

  @override
  State<SenderLiveScreen> createState() => _SenderLiveScreenState();
}

class _SenderLiveScreenState extends State<SenderLiveScreen> {
  late StreamSubscription<ConnectionState> _stateSubscription;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = WebRTCService().stateStream.listen((state) {
      if (state == ConnectionState.idle && mounted && !_isPopping) {
        _isPopping = true;
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F1729), Color(0xFF1E293B)])),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, size: 80, color: Colors.red),
                      const SizedBox(height: 24),
                      Text('Live with ${widget.receiverName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Broadcasting audio...', style: TextStyle(color: Colors.green)),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () { 
                          if (!_isPopping) {
                            _isPopping = true;
                            WebRTCService().stopBroadcast(); 
                            if(mounted) Navigator.of(context).pop(); 
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        IconButton(onPressed: () { 
          if (!_isPopping) {
            _isPopping = true;
            WebRTCService().stopBroadcast(); 
            if(mounted) Navigator.of(context).pop(); 
          }
        }, icon: const Icon(Icons.arrow_back)),
        const Text('Live Broadcast'),
      ]),
    );
  }
}

class ReceiverListeningScreen extends StatefulWidget {
  final String code;
  final String senderName;
  final DiscoveredDevice deviceInfo;
  const ReceiverListeningScreen({super.key, required this.code, required this.senderName, required this.deviceInfo});

  @override
  State<ReceiverListeningScreen> createState() => _ReceiverListeningScreenState();
}

class _ReceiverListeningScreenState extends State<ReceiverListeningScreen> {
  late StreamSubscription<ConnectionState> _stateSubscription;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = WebRTCService().stateStream.listen((state) {
      if (state == ConnectionState.idle && mounted && !_isPopping) {
        _isPopping = true;
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F1729), Color(0xFF1E293B)])),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headphones, size: 80, color: Colors.green),
                      const SizedBox(height: 24),
                      Text('Listening to ${widget.senderName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Receiving audio stream...', style: TextStyle(color: Colors.green)),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () { 
                          if (!_isPopping) {
                            _isPopping = true;
                            WebRTCService().disconnect(); 
                            if(mounted) Navigator.of(context).pop(); 
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9945FF)),
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        IconButton(onPressed: () { 
          if (!_isPopping) {
            _isPopping = true;
            WebRTCService().disconnect(); 
            if(mounted) Navigator.of(context).pop(); 
          }
        }, icon: const Icon(Icons.arrow_back)),
        const Text('Listening'),
      ]),
    );
  }
}
