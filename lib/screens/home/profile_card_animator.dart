import 'package:flutter/material.dart';

/// Classe helper che gestisce tutta l'animazione "spring back"
/// e il movimento fluido della card.
///
/// Viene usata dentro `ProfileCard` per mantenere il codice pulito.
class ProfileCardAnimator {
  final TickerProvider vsync;
  final void Function(Offset) onUpdate;

  late final AnimationController _controller;
  late Animation<Offset> _animation;
  VoidCallback? _listener;

  ProfileCardAnimator({
    required this.vsync,
    required this.onUpdate,
  }) {
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 250),
    );
    _animation = const AlwaysStoppedAnimation(Offset.zero);
  }

  /// Ferma qualsiasi animazione in corso.
  void stop() => _controller.stop();

  /// Fa tornare la card al centro con una bella animazione "spring".
  void springBack({required Offset from}) {
    _removeListener();
    _animation = Tween<Offset>(
      begin: from,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _listener = () => onUpdate(_animation.value);
    _animation.addListener(_listener!);
    _controller.forward(from: 0);
  }

  /// Pulisce le risorse quando la card viene distrutta.
  void dispose() {
    _removeListener();
    _controller.dispose();
  }

  void _removeListener() {
    if (_listener != null) {
      _animation.removeListener(_listener!);
      _listener = null;
    }
  }
}