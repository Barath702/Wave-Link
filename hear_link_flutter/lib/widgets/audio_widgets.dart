import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// 4-digit PIN display widget - matches PinDisplay.tsx
class PinDisplay extends StatelessWidget {
  final String pin;
  final String status;

  const PinDisplay({
    super.key,
    required this.pin,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Enter this code on the receiving device',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme._mutedForeground,
          ),
        ),
        const SizedBox(height: AppTheme.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _PinDigit(
                digit: pin.length > index ? pin[index] : '',
                delay: Duration(milliseconds: index * 100),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme._primary,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fadeIn(duration: const Duration(milliseconds: 500))
              .scaleXY(begin: 1, end: 1.2, duration: const Duration(milliseconds: 1000)),
            const SizedBox(width: AppTheme.sm),
            Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme._mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinDigit extends StatefulWidget {
  final String digit;
  final Duration delay;

  const _PinDigit({
    required this.digit,
    required this.delay,
  });

  @override
  State<_PinDigit> createState() => _PinDigitState();
}

class _PinDigitState extends State<_PinDigit> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 80,
      decoration: AppTheme.glassDecoration(
        boxShadow: AppTheme.primaryGlow,
      ),
      child: Center(
        child: Text(
          widget.digit,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppTheme._primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ).animate(delay: widget.delay)
      .fadeIn(duration: const Duration(milliseconds: 300))
      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300));
  }
}

/// 4-digit PIN input widget - matches PinInput.tsx
class PinInput extends StatefulWidget {
  final Function(String) onSubmit;
  final bool isLoading;
  final String? error;

  const PinInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.error,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<String> _digits = ['', '', '', ''];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isEmpty || value.length > 1) return;
    
    setState(() {
      _digits[index] = value;
    });

    // Auto-advance to next field
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all 4 digits are filled
    if (_digits.every((d) => d.isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSubmit(_digits.join());
      });
    }
  }

  void _onKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_digits[index].isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          setState(() {
            _digits[index - 1] = '';
          });
        }
      }
    }
  }

  void _onPaste() {
    // Handle paste if needed
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Enter the 4-digit code shown on the broadcaster\'s screen',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme._mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _PinInputField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                digit: _digits[index],
                index: index,
                onChanged: (value) => _onChanged(index, value),
                onKeyDown: (event) => _onKeyDown(index, event),
                isLoading: widget.isLoading,
                delay: Duration(milliseconds: index * 80),
              ),
            ),
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: AppTheme.md),
          Text(
            widget.error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme._destructive,
            ),
          ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
        ],
        if (widget.isLoading) ...[
          const SizedBox(height: AppTheme.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme._primary,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                .fadeIn(duration: const Duration(milliseconds: 500))
                .scaleXY(begin: 1, end: 1.2, duration: const Duration(milliseconds: 1000)),
              const SizedBox(width: AppTheme.sm),
              Text(
                'Connecting...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme._mutedForeground,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppTheme.lg),
        ReceiverButton(
          onPressed: _digits.every((d) => d.isNotEmpty) && !widget.isLoading
              ? () => widget.onSubmit(_digits.join())
              : null,
          width: double.infinity,
          child: Text(widget.isLoading ? 'Connecting...' : 'Connect'),
        ),
      ],
    );
  }
}

class _PinInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String digit;
  final int index;
  final Function(String) onChanged;
  final Function(RawKeyEvent) onKeyDown;
  final bool isLoading;
  final Duration delay;

  const _PinInputField({
    required this.controller,
    required this.focusNode,
    required this.digit,
    required this.index,
    required this.onChanged,
    required this.onKeyDown,
    required this.isLoading,
    required this.delay,
  });

  @override
  State<_PinInputField> createState() => _PinInputFieldState();
}

class _PinInputFieldState extends State<_PinInputField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 80,
      decoration: AppTheme.glassDecoration(
        borderRadius: AppTheme.radiusMd,
        border: Border.all(
          color: widget.focusNode.hasFocus
              ? AppTheme._primary
              : AppTheme._glassBorder,
          width: 2,
        ),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: widget.onKeyDown,
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: !widget.isLoading,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppTheme._foreground,
            fontWeight: FontWeight.w700,
            fontFamily: 'SpaceGrotesk',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    ).animate(delay: widget.delay)
      .fadeIn(duration: const Duration(milliseconds: 300))
      .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 300));
  }
}

/// Waveform visualization widget - matches Waveform.tsx
class WaveformWidget extends StatefulWidget {
  final bool isActive;
  final List<double>? audioData;

  const WaveformWidget({
    super.key,
    this.isActive = false,
    this.audioData,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _waveAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_waveController);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      width: double.infinity,
      decoration: AppTheme.glassDecoration(
        borderRadius: AppTheme.radiusMd,
      ),
      child: CustomPaint(
        painter: WaveformPainter(
          isActive: widget.isActive,
          animation: _waveAnimation,
          audioData: widget.audioData,
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final bool isActive;
  final Animation<double> animation;
  final List<double>? audioData;

  WaveformPainter({
    required this.isActive,
    required this.animation,
    this.audioData,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Create gradient
    final gradient = LinearGradient(
      colors: [
        AppTheme._primary,
        AppTheme._secondary,
        AppTheme._accent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paint.shader = gradient;

    // Add glow effect
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final path = Path();
    final centerY = size.height / 2;

    if (isActive && audioData != null) {
      // Draw actual audio data
      final barWidth = size.width / audioData!.length;
      for (int i = 0; i < audioData!.length; i++) {
        final x = i * barWidth;
        final barHeight = audioData![i] * size.height * 0.4;
        final y1 = centerY - barHeight;
        final y2 = centerY + barHeight;

        if (i == 0) {
          path.moveTo(x, centerY);
        }
        path.lineTo(x, y1);
        path.lineTo(x + barWidth, y1);
        path.lineTo(x + barWidth, y2);
        path.lineTo(x, y2);
      }
    } else {
      // Draw idle wave
      path.moveTo(0, centerY);
      for (double x = 0; x <= size.width; x += 2) {
        final y = centerY + 
            (x * 0.02 + animation.value * 0.002) * 5;
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Sound level indicator widget
class SoundLevelWidget extends StatelessWidget {
  final double level;
  final bool isActive;

  const SoundLevelWidget({
    super.key,
    required this.level,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: double.infinity,
      decoration: AppTheme.glassDecoration(
        borderRadius: AppTheme.radiusSm,
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: AppTheme.radiusSm,
            ),
          ),
          // Sound level
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity * level,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: AppTheme.radiusSm,
            ),
          ),
        ],
      ),
    );
  }
}
