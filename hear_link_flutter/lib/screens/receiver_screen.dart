import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/audio_widgets.dart';

enum ReceiverStep { pin, live }

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  ReceiverStep _currentStep = ReceiverStep.pin;
  bool _isConnecting = false;
  bool _isConnected = false;
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
      case ReceiverStep.pin:
        return _PinStep(
          onPinSubmit: _connectToSender,
          isLoading: _isConnecting,
          error: _errorMessage,
        );
      case ReceiverStep.live:
        return _LiveStep(
          isConnected: _isConnected,
        );
    }
  }

  void _connectToSender(String pin) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    // Simulate connection
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _currentStep = ReceiverStep.live;
      });
    }
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
            'Receiver',
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

class _PinStep extends StatelessWidget {
  final Function(String) onPinSubmit;
  final bool isLoading;
  final String? error;

  const _PinStep({
    required this.onPinSubmit,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Headphones icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.receiverGradient,
                borderRadius: BorderRadius.circular(60),
                boxShadow: AppTheme.accentGlow,
              ),
              child: const Icon(
                LucideIcons.headphones,
                color: AppTheme._secondaryForeground,
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
              'Enter Code',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 100)),
            
            const SizedBox(height: AppTheme.md),
            
            // Description
            Text(
              'Enter the 4-digit code from the broadcaster',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme._mutedForeground,
              ),
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200)),
            
            const SizedBox(height: AppTheme.xl),
            
            // PIN input
            PinInput(
              onSubmit: onPinSubmit,
              isLoading: isLoading,
              error: error,
            ).animate()
              .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300)),
          ],
        ),
      ),
    );
  }
}

class _LiveStep extends StatelessWidget {
  final bool isConnected;

  const _LiveStep({
    required this.isConnected,
  });

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
                'RECEIVING',
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
                  // Volume icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: AppTheme.accentGlow,
                    ),
                    child: const Icon(
                      LucideIcons.volume2,
                      color: AppTheme._secondaryForeground,
                      size: 40,
                    ),
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 100))
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                  
                  const SizedBox(height: AppTheme.xl),
                  
                  // Waveform
                  WaveformWidget(
                    isActive: isConnected,
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200)),
                  
                  const SizedBox(height: AppTheme.xl),
                  
                  // Sound level
                  SoundLevelWidget(
                    level: 0.6,
                    isActive: isConnected,
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300)),
                  
                  const SizedBox(height: AppTheme.xl),
                  
                  // Status text
                  GlassCard(
                    padding: const EdgeInsets.all(AppTheme.lg),
                    child: Column(
                      children: [
                        const Icon(
                          LucideIcons.wifi,
                          color: AppTheme._primary,
                          size: 32,
                        ),
                        const SizedBox(height: AppTheme.md),
                        Text(
                          'Connected to broadcaster',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme._foreground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.sm),
                        Text(
                          'Audio is streaming from the sender device',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme._mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
