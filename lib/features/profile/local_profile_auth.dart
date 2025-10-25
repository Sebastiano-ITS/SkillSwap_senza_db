// lib/features/profile/local_profile_auth.dart
import '../../data/local_data.dart';
import '../../screens/profile/profile_cubit.dart';

class LocalProfileAuth implements ProfileAuth {
  final LocalData _local = LocalData();

  @override
  String? resolveCurrentUserId() {
    return _local.currentUserId;
  }
}
