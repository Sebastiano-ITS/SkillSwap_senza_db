import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth_wrapper.dart';
import '../screens/login_screen.dart';
import '../features/main_shell.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/chat_list_screen.dart';
import '../screens/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/explore', builder: (context, state) => const ExploreScreen()),
        GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);