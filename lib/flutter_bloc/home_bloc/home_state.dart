import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<UserProfile> profiles;
  const HomeLoaded({required this.profiles});

  @override
  List<Object?> get props => [profiles];
}

class ProfileMatched extends HomeState {
  final UserProfile profile;
  const ProfileMatched({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileRejected extends HomeState {
  final UserProfile profile;
  const ProfileRejected({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}