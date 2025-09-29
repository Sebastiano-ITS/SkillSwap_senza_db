import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Profilo', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text('Email: ${user?.email ?? 'N/A'}'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              Navigator.pop(context);
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
