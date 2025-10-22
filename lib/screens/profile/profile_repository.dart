import 'package:skillswap/models/user_profile.dart';
import 'package:skillswap/services/firestore_service.dart';

import 'profile_cubit.dart';

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._service);

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