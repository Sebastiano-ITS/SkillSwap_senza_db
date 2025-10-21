import '../../models/user_profile.dart';

abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoaded extends HomeState {
  final List<UserProfile> profiles;
  HomeLoaded({required this.profiles});
}

class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});
}

class ProfileMatched extends HomeState {
  final UserProfile profile;
  ProfileMatched({required this.profile});
}

class ProfileRejected extends HomeState {
  final UserProfile profile;
  ProfileRejected({required this.profile});
}
