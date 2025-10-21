import '../../models/user_profile.dart';

abstract class HomeEvent {}

class LoadProfiles extends HomeEvent {}

class SwipeRight extends HomeEvent {
  final UserProfile profile;
  SwipeRight(this.profile);
}

class SwipeLeft extends HomeEvent {
  final UserProfile profile;
  SwipeLeft(this.profile);
}
