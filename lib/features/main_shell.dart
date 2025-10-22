import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<String> _routes = [
    '/home',
    '/explore',
    '/chat',
    '/profile',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go(_routes[index]);
  }