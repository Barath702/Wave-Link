import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'sender_screen.dart';
import 'receiver_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      
                      // Logo section
                      _LogoSection(),
                      
                      const SizedBox(height: AppTheme.xl),
                      
                      // Mode buttons
                      _ModeButtons(),
                      
                      const SizedBox(height: AppTheme.lg),
                      
                      // Footer
                      _Footer(),
                      
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: AppTheme.radiusXl,
            boxShadow: AppTheme.primaryGlow,
          ),
          child: const Icon(
            LucideIcons.wifi,
            color: AppTheme._primaryForeground,
            size: 40,
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600))
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        
        const SizedBox(height: AppTheme.sm),
        
        // App title
        Text(
          'WaveLink',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            foreground: Paint()
              ..shader = AppTheme.accentGradient.createShader(
                const Rect.fromLTWH(0, 0, 200, 50),
              ),
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 100)),
        
        const SizedBox(height: AppTheme.sm),
        
        // Tagline
        Text(
          'Real-time audio streaming over your local network. No internet needed.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme._mutedForeground,
          ),
          textAlign: TextAlign.center,
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200)),
      ],
    );
  }
}

class _ModeButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sender button
        SenderButton(
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const SenderScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
          width: double.infinity,
          height: 80,
          child: Row(
            children: [
              // Icon background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme._primary.withOpacity(0.2),
                  borderRadius: AppTheme.radiusMd,
                ),
                child: const Icon(
                  LucideIcons.radio,
                  size: 28,
                  color: AppTheme._primaryForeground,
                ),
              ),
              
              const SizedBox(width: AppTheme.md),
              
              // Button text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Broadcasting',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Stream audio from this device',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme._primaryForeground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 300))
          .slideY(begin: 0.2, end: 0),
        
        const SizedBox(height: AppTheme.md),
        
        // Receiver button
        ReceiverButton(
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const ReceiverScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
          width: double.infinity,
          height: 80,
          child: Row(
            children: [
              // Icon background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme._secondary.withOpacity(0.2),
                  borderRadius: AppTheme.radiusMd,
                ),
                child: const Icon(
                  LucideIcons.headphones,
                  size: 28,
                  color: AppTheme._secondaryForeground,
                ),
              ),
              
              const SizedBox(width: AppTheme.md),
              
              // Button text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Receive Audio',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Listen from another device',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme._secondaryForeground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate()
          .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400))
          .slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Works offline after first load • WebRTC over LAN',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme._mutedForeground,
      ),
      textAlign: TextAlign.center,
    ).animate()
      .fadeIn(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 500));
  }
}
