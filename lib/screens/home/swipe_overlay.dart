import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../flutter_bloc/home_bloc/home_bloc.dart';
import '../../flutter_bloc/home_bloc/home_state.dart';

class SwipeOverlay extends StatelessWidget {
  const SwipeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeBloc>().state;

    if (state is ProfileMatched) {
      return Positioned(
        top: 100,
        left: 50,
        child: Icon(Icons.check_circle, color: Colors.green, size: 80),
      );
    } else if (state is ProfileRejected) {
      return Positioned(
        top: 100,
        right: 50,
        child: Icon(Icons.cancel, color: Colors.red, size: 80),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}