import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/audio_widgets.dart';

enum SenderStep { setup, pin, live }

class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  SenderStep _currentStep = SenderStep.setup;
  String _pin = '';
  bool _isMuted = false;
  bool _isConnected = false;
  String _statusText = 'Waiting for receiver...';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.heroGradient,
        ),
        child: Stack(
          children: [
            // Animated blobs background
            const Positioned.fill(
              child: AnimatedBlobs(),
            ),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _Header(
                    onBackPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  // Content based on current step
                  Expanded(
                    child: _buildStepContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case SenderStep.setup:
        return _SetupStep(
          onStartBroadcast: _startBroadcast,
          errorMessage: _errorMessage,
        );
      case SenderStep.pin:
        return _PinStep(
          pin: _pin,
          statusText: _statusText,
        );
      case SenderStep.live:
        return _LiveStep(
          isMuted: _isMuted,
          isConnected: _isConnected,
          onToggleMute: () => setState(() => _isMuted = !_isMuted),
        );
    }
  }

  void _startBroadcast() async {
    // Simulate broadcast start
    setState(() {
      _errorMessage = null;
      _pin = _generatePin();
      _currentStep = SenderStep.pin;
      _statusText = 'Waiting for receiver...';
    });

    // Simulate connection after delay
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isConnected = true;
        _currentStep = SenderStep.live;
        _statusText = 'Connected';
      });
    }
  }

  String _generatePin() {
    return (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBackPressed;

  const _Header({
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.md),
      child: Row(
        children: [
          GlassCard(
            onTap: onBackPressed,
            width: 40,
            height: 40,
            borderRadius: AppTheme.radiusLg,
            child: const Icon(
              LucideIcons.chevronLeft,
              color: AppTheme._foreground,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.sm),
          Text(
            'Sender',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w600,
              color: AppTheme._foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final VoidCallback onStartBroadcast;
  final String? errorMessage;

  const _SetupStep({
    required this.onStartBroadcast,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Microphone icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.senderGradient,
                borderRadius: BorderRadius.circular(60),
                boxShadow: AppTheme.primaryGlow,
              ),
              child: const Icon(
                LucideIcons.mic,
                color: AppTheme._primaryForeground,
                size: 60,
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600))
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1))
              .then()
              .shimmer(duration: const Duration(milliseconds: 1500)),
            
            const SizedBox(height: AppTheme.xl),
            
            // Title
            Text(
              'Start Broadcasting',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 100)),
            
            const SizedBox(height: AppTheme.md),
            
            // Description
            Text(
              'Share your audio with devices on the same network',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme._mutedForeground,
              ),
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200)),
            
            const SizedBox(height: AppTheme.xl),
            
            // Error message
            if (errorMessage != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(AppTheme.md),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      color: AppTheme._destructive,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme._destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate()
                .fadeIn(duration: const Duration(milliseconds: 300))
                .shake(),
              
              const SizedBox(height: AppTheme.md),
            ],
            
            // Start button
            SenderButton(
              onPressed: onStartBroadcast,
              width: double.infinity,
              height: 56,
              child: const Text(
                'Start Broadcasting',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300))
              .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}

class _PinStep extends StatelessWidget {
  final String pin;
  final String statusText;

  const _PinStep({
    required this.pin,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              'Share this code',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600)),
            
            const SizedBox(height: AppTheme.xl),
            
            // PIN display
            PinDisplay(
              pin: pin,
              status: statusText,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 100)),
            
            const SizedBox(height: AppTheme.xl),
            
            // Instructions
            GlassCard(
              padding: const EdgeInsets.all(AppTheme.lg),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.users,
                    color: AppTheme._primary,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.md),
                  Text(
                    'Waiting for receiver...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme._foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.sm),
                  Text(
                    'Make sure the receiver is on the same WiFi network',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme._mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200)),
          ],
        ),
      ),
    );
  }
}

class _LiveStep extends StatefulWidget {
  final bool isMuted;
  final bool isConnected;
  final VoidCallback onToggleMute;

  const _LiveStep({
    required this.isMuted,
    required this.isConnected,
    required this.onToggleMute,
  });

  @override
  State<_LiveStep> createState() => _LiveStepState();
}

class _LiveStepState extends State<_LiveStep> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Live indicator
        Container(
          margin: const EdgeInsets.all(AppTheme.md),
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
          decoration: AppTheme.glassDecoration(
            borderRadius: AppTheme.radiusLg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme._destructive,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.liveGlow,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1, end: 1.2, duration: const Duration(milliseconds: 1000)),
              const SizedBox(width: AppTheme.sm),
              Text(
                'LIVE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme._destructive,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600)),
        
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Waveform
                  WaveformWidget(
                    isActive: widget.isConnected,
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 100)),
                  
                  const SizedBox(height: AppTheme.xl),
                  
                  // Sound level
                  SoundLevelWidget(
                    level: widget.isMuted ? 0.0 : 0.7,
                    isActive: widget.isConnected,
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200)),
                  
                  const SizedBox(height: AppTheme.xl),
                  
                  // Floating mic button
                  FloatingMicButton(
                    isMuted: widget.isMuted,
                    isConnected: widget.isConnected,
                    onTap: widget.onToggleMute,
                    size: 80,
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300))
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
