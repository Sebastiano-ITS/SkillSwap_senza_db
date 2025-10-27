import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';


enum ProfileStatus { initial, loading, loaded, saving, failure }

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    this.profile,
    this.errorMessage,
    this.feedbackMessage,
    this.hasUnsavedChanges = false,
  });

  factory ProfileState.initial() => const ProfileState(status: ProfileStatus.initial);

  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;
  final String? feedbackMessage;
  final bool hasUnsavedChanges;

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    bool clearProfile = false,
    bool? hasUnsavedChanges,
    String? errorMessage,
    bool clearError = false,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage, feedbackMessage, hasUnsavedChanges];
}
