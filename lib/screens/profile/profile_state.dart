import 'package:equatable/equatable.dart';
import 'package:skillswap/models/user_profile.dart';

enum ProfileStatus { initial, loading, loaded, failure }

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
    this.isPublic = true,
    this.acceptsMatches = true,
  });

  factory ProfileState.initial() => const ProfileState(status: ProfileStatus.initial);

  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isPublic;
  final bool acceptsMatches;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool? isPublic,
    bool? acceptsMatches, required bool clearFeedback,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isPublic: isPublic ?? this.isPublic,
      acceptsMatches: acceptsMatches ?? this.acceptsMatches,
    );
  }

  factory ProfileState.failure(String message) {
    return ProfileState(
      status: ProfileStatus.failure,
      errorMessage: message,
      profile: null,
    );
  }

  ProfileState withProfile(UserProfile profile) {
    return copyWith(
      status: ProfileStatus.loaded,
      profile: profile,
      errorMessage: null, clearFeedback: true,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, isPublic, acceptsMatches];
}