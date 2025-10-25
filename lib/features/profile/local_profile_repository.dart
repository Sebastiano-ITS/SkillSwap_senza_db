// lib/features/profile/local_profile_repository.dart
import 'dart:async';
import '../../models/user_profile.dart';
import '../../screens/profile/profile_cubit.dart';
import '../../services/firestore_service.dart';


/// Implementazione locale di [ProfileRepository] usando FirestoreService (locale).
class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._service);

  final FirestoreService _service;

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _service.streamUserProfile(userId);
  }

  @override
  Future<void> save(UserProfile profile) {
    return _service.saveUserProfile(profile);
  }
}
