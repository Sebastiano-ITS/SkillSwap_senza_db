import '../../data/local_data.dart';
import '../../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> fetchProfile(String userId);
  Future<UserProfile> saveProfile(UserProfile profile);
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({LocalData? localData}) : _localData = localData ?? LocalData();

  final LocalData _localData;

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    await _localData.initialize();
    return _localData.getUserById(userId);
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    await _localData.saveUser(profile);
    return profile;
  }
}