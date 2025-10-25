// lib/services/auth_service.dart
import 'dart:async';
import '../data/local_data.dart';
import '../models/user_profile.dart';

class User {
  final String uid;
  final String email;
  final String displayName;

  User({required this.uid, required this.email, required this.displayName});
}

class AuthService {
  final LocalData _localData = LocalData();
  final StreamController<User?> _userStreamController = StreamController<User?>.broadcast();
  bool _isInitialLoading = true;

  bool? get isInitialLoading => _isInitialLoading;

  Stream<User?> get userStream {
    _initializeLocalData();
    return _userStreamController.stream;
  }

  Future<void> _initializeLocalData() async {
    if (_isInitialLoading) {
      await _localData.initialize();

      if (_localData.currentUserId != null) {
        final userProfile = _localData.getUserById(_localData.currentUserId!);
        if (userProfile != null) {
          _userStreamController.add(User(
            uid: userProfile.id,
            email: userProfile.email,
            displayName: userProfile.name,
          ));
        } else {
          _userStreamController.add(null);
        }
      } else {
        _userStreamController.add(null);
      }

      // Piccolo delay per evitare frame jank su splash
      Future.delayed(const Duration(milliseconds: 50), () {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    await _localData.initialize();
    final userId = await _localData.registerUser(email, password, name);
    if (userId != null) {
      final userProfile = _localData.getUserById(userId);
      if (userProfile != null) {
        _userStreamController.add(User(
          uid: userProfile.id,
          email: userProfile.email,
          displayName: userProfile.name,
        ));
      }
    } else {
      throw Exception('Email già in uso');
    }
  }

  Future<void> signIn(String email, String password) async {
    await _localData.initialize();
    final success = await _localData.authenticateUser(email, password);
    if (success && _localData.currentUserId != null) {
      final userProfile = _localData.getUserById(_localData.currentUserId!);
      if (userProfile != null) {
        _userStreamController.add(User(
          uid: userProfile.id,
          email: userProfile.email,
          displayName: userProfile.name,
        ));
      } else {
        throw Exception('Profilo utente non trovato dopo il login.');
      }
    } else {
      throw Exception('Email o password non validi');
    }
  }

  Future<void> signOut() async {
    _localData.signOut();
    _userStreamController.add(null);
  }

  User? get currentUser {
    if (!_localData.isReady || _localData.currentUserId == null) {
      return null;
    }
    final userProfile = _localData.getUserById(_localData.currentUserId!);
    if (userProfile != null) {
      return User(
        uid: userProfile.id,
        email: userProfile.email,
        displayName: userProfile.name,
      );
    }
    return null;
  }

  String? getCurrentUserId() {
    return _localData.currentUserId;
  }

  UserProfile? getCurrentUserProfile() {
    final id = _localData.currentUserId;
    return id != null ? _localData.getUserById(id) : null;
  }
}
