// lib/screens/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _gifPath = 'assets/images/splash_art.gif';
  final AssetImage _gif = const AssetImage(_gifPath);

  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;

  late final AnimationController _glowCtrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Preleva dimensioni reali della GIF
    _stream = _gif.resolve(const ImageConfiguration());
    _listener = ImageStreamListener((info, _) {
      if (mounted) setState(() => _info = info);
    });
    _stream!.addListener(_listener!);

    // Animazione glow bordo
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // 10 secondi -> /auth
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  void dispose() {
    if (_listener != null && _stream != null) {
      _stream!.removeListener(_listener!);
    }
    _glowCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    // Fallback mentre carichiamo la size: mostro comunque la GIF centrata con un frame “fluido”
    if (_info == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B0B),
        body: Center(
          child: _GlassFrame(
            width: screen.width * 0.86,
            height: screen.height * 0.72,
            radius: 24,
            controller: _glowCtrl,
            child: Image(image: _gif, fit: BoxFit.contain, filterQuality: FilterQuality.high),
          ),
        ),
      );
    }

    // Calcolo dimensioni frame rispettando l'aspect ratio della GIF
    final double imgW = _info!.image.width.toDouble();
    final double imgH = _info!.image.height.toDouble();
    final double maxW = screen.width * 0.86;
    final double maxH = screen.height * 0.80;

    final double scale = _min(maxW / imgW, maxH / imgH);
    final double frameW = imgW * scale;
    final double frameH = imgH * scale;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: _GlassFrame(
          width: frameW,
          height: frameH,
          radius: 24,
          controller: _glowCtrl,
          // NIENTE background: solo la gif, così non c'è “stacco” interno
          child: SizedBox(
            width: frameW,
            height: frameH,
            child: Image(
              image: _gif,
              fit: BoxFit.fill, // riempie esattamente il frame (stesso AR), quindi NON deforma
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }

  double _min(double a, double b) => a < b ? a : b;
}

/// Cornice glass con bagliore animato.
/// - Il bordo è un gradiente che si muove (glow).
/// - Il contenuto NON ha colore di sfondo: solo child (la GIF).
class _GlassFrame extends StatelessWidget {
  const _GlassFrame({
    required this.width,
    required this.height,
    required this.radius,
    required this.controller,
    required this.child,
  });

  final double width;
  final double height;
  final double radius;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const double borderWidth = 4.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value; // 0..1
        final gradient = LinearGradient(
          colors: [
            const Color(0xFFD91656).withOpacity(0.95),
            const Color(0xFFEB5B00).withOpacity(0.95),
            const Color(0xFF640D5F).withOpacity(0.95),
            const Color(0xFFD91656).withOpacity(0.95),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
          begin: Alignment(-1 + t, -1),
          end: Alignment(1 - t, 1),
        );

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            // Glow esterno soft
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD91656).withOpacity(0.2),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF640D5F).withOpacity(0.2),
                blurRadius: 44,
                spreadRadius: 4,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _AnimatedBorderPainter(
              gradient: gradient,
              radius: radius,
              strokeWidth: borderWidth,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius - 4),
              // Effetto "vetro" leggerissimo sulla cornice interna
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Nessun colore sotto: mostriamo solo il child
                  child,
                  // Un velo trasparente ai bordi interni per effetto glass
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius - 4),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.04),
                            Colors.transparent,
                            Colors.white.withOpacity(0.03),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Disegna il bordo animato (gradiente) come se fosse un frame luminoso.
class _AnimatedBorderPainter extends CustomPainter {
  _AnimatedBorderPainter({
    required this.gradient,
    required this.radius,
    required this.strokeWidth,
  });

  final Gradient gradient;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // bordo luminoso
    canvas.drawRRect(rrect, paint);

    // alone glow interno sottilissimo
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect.deflate(2), innerPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
