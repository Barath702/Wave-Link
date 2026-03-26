import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// Glass Card with backdrop filter blur effect - matches CSS glass-card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final BoxBorder? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme._glassBg,
        border: border ?? Border.all(color: AppTheme._glassBorder, width: 1),
        borderRadius: borderRadius ?? AppTheme.radiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? AppTheme.radiusLg,
        child: card,
      );
    }

    return card;
  }
}

/// Animated gradient button with hover effects
class GradientButton extends StatefulWidget {
  final Widget child;
  final Gradient gradient;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool enabled;
  final List<BoxShadow>? glowEffect;

  const GradientButton({
    super.key,
    required this.child,
    required this.gradient,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.enabled = true,
    this.glowEffect,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: widget.borderRadius ?? AppTheme.radiusLg,
              boxShadow: widget.glowEffect ?? [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? widget.onPressed : null,
                borderRadius: widget.borderRadius ?? AppTheme.radiusLg,
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) => _controller.reverse(),
                onTapCancel: () => _controller.reverse(),
                child: Container(
                  padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sender styled button
class SenderButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const SenderButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      gradient: AppTheme.senderGradient,
      onPressed: onPressed,
      padding: padding,
      width: width,
      height: height,
      glowEffect: AppTheme.primaryGlow,
      child: DefaultTextStyle(
        style: const TextStyle(
          color: AppTheme._primaryForeground,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        child: child,
      ),
    );
  }
}

/// Receiver styled button
class ReceiverButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const ReceiverButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      gradient: AppTheme.receiverGradient,
      onPressed: onPressed,
      padding: padding,
      width: width,
      height: height,
      glowEffect: AppTheme.accentGlow,
      child: DefaultTextStyle(
        style: const TextStyle(
          color: AppTheme._secondaryForeground,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        child: child,
      ),
    );
  }
}

/// Floating microphone button with glow and pulse animations
class FloatingMicButton extends StatefulWidget {
  final bool isMuted;
  final bool isConnected;
  final VoidCallback? onTap;
  final double size;

  const FloatingMicButton({
    super.key,
    this.isMuted = false,
    this.isConnected = false,
    this.onTap,
    this.size = 64,
  });

  @override
  State<FloatingMicButton> createState() => _FloatingMicButtonState();
}

class _FloatingMicButtonState extends State<FloatingMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(widget.size / 2),
            boxShadow: widget.isConnected
                ? [
                    BoxShadow(
                      color: AppTheme._destructive.withOpacity(_pulseAnimation.value),
                      blurRadius: 20 + (1 - _pulseAnimation.value) * 15,
                      spreadRadius: 0,
                    ),
                  ]
                : AppTheme.accentGlow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: Icon(
                widget.isMuted ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated blob background - matches CSS blob animations
class AnimatedBlobs extends StatefulWidget {
  const AnimatedBlobs({super.key});

  @override
  State<AnimatedBlobs> createState() => _AnimatedBlobsState();
}

class _AnimatedBlobsState extends State<AnimatedBlobs>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  late Animation<Offset> _animation1;
  late Animation<Offset> _animation2;
  late Animation<Offset> _animation3;

  late Animation<double> _scale1;
  late Animation<double> _scale2;
  late Animation<double> _scale3;

  @override
  void initState() {
    super.initState();

    // Blob 1 - 8s animation
    _controller1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _animation1 = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.15, -0.25),
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeInOut,
    ));

    _scale1 = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeInOut,
    ));

    // Blob 2 - 10s animation
    _controller2 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animation2 = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0.15),
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOut,
    ));

    _scale2 = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOut,
    ));

    // Blob 3 - 12s animation
    _controller3 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _animation3 = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.1, 0.2),
    ).animate(CurvedAnimation(
      parent: _controller3,
      curve: Curves.easeInOut,
    ));

    _scale3 = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller3,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blob 1
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            return Positioned.fill(
              child: Transform.translate(
                offset: _animation1.value * 200,
                child: Transform.scale(
                  scale: _scale1.value,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            width: 384,
            height: 384,
            decoration: BoxDecoration(
              color: AppTheme._primary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme._primary.withOpacity(0.3),
                  blurRadius: 96,
                ),
              ],
            ),
          ),
        ),

        // Blob 2
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            return Positioned.fill(
              child: Transform.translate(
                offset: _animation2.value * 200,
                child: Transform.scale(
                  scale: _scale2.value,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: AppTheme._secondary.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme._secondary.withOpacity(0.3),
                  blurRadius: 96,
                ),
              ],
            ),
          ),
        ),

        // Blob 3
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            return Positioned.fill(
              child: Transform.translate(
                offset: _animation3.value * 200,
                child: Transform.scale(
                  scale: _scale3.value,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            width: 288,
            height: 288,
            decoration: BoxDecoration(
              color: AppTheme._accent.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme._accent.withOpacity(0.3),
                  blurRadius: 96,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
