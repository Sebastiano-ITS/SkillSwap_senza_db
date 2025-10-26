// lib/screens/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _gifPath = 'assets/images/splash_art.gif';

  Timer? _timer;
  bool _didPrecache = false;

  late final Image _gifImage = Image.asset(
    _gifPath,
    fit: BoxFit.cover, // 👈 adatta la GIF a tutto lo schermo (senza deformarla)
    alignment: Alignment.center, // centrata perfettamente
    filterQuality: FilterQuality.high,
  );

  @override
  void initState() {
    super.initState();

    // Naviga dopo 6 secondi
    _timer = Timer(const Duration(seconds: 6), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecache) {
      precacheImage(_gifImage.image, context);
      _didPrecache = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _gifImage,
      ),
    );
  }
}
