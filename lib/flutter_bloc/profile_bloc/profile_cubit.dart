import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/user_profile.dart';
import '../../screens/profile/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(ProfileState.initial());

  final ProfileRepository _repository;
  String? _userId;

  Future<void> loadProfile(String userId) async {
    _userId = userId;
    emit(
      state.copyWith(
        status: ProfileStatus.loading,
        clearError: true,
        clearFeedback: true,
      ),
    );

    try {
      final profile = await _repository.fetchProfile(userId);
      if (profile == null) {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            errorMessage: 'Profilo non trovato.',
            clearProfile: true,
            hasUnsavedChanges: false,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
          hasUnsavedChanges: false,
          clearError: true,
          clearFeedback: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Impossibile caricare il profilo.',
          clearProfile: true,
          hasUnsavedChanges: false,
        ),
      );
    }
  }

  void updateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _updateProfileIfChanged((profile) =>
    trimmed == profile.name ? profile : profile.copyWith(name: trimmed));
  }

  void updateEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _updateProfileIfChanged((profile) =>
    trimmed == profile.email ? profile : profile.copyWith(email: trimmed));
  }

  void updateHourlyRate(String value) {
    final sanitized = value.replaceAll(',', '.');
    final parsed = double.tryParse(sanitized);
    if (parsed == null) {
      return;
    }
  }

  void addSkillToTeach(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    _updateProfileIfChanged((profile) {
      final skills = List<String>.from(profile.canTeach);
      if (skills.contains(trimmed)) {
        return profile;
      }
      skills.add(trimmed);
      skills.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return profile.copyWith(canTeach: skills);
    });
  }

  void removeSkillToTeach(String skill) {
    _updateProfileIfChanged((profile) {
      final skills = List<String>.from(profile.canTeach);
      final removed = skills.remove(skill);
      if (!removed) {
        return profile;
      }
      return profile.copyWith(canTeach: skills);
    });
  }

  void addSkillToLearn(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    _updateProfileIfChanged((profile) {
      final skills = List<String>.from(profile.wantsToLearn);
      if (skills.contains(trimmed)) {
        return profile;
      }
      skills.add(trimmed);
      skills.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return profile.copyWith(wantsToLearn: skills);
    });
  }

  void removeSkillToLearn(String skill) {
    _updateProfileIfChanged((profile) {
      final skills = List<String>.from(profile.wantsToLearn);
      final removed = skills.remove(skill);
      if (!removed) {
        return profile;
      }
      return profile.copyWith(wantsToLearn: skills);
    });
  }

  Future<void> saveProfile() async {
    final profile = state.profile;
    final userId = _userId;
    if (profile == null || userId == null) {
      return;
    }

    emit(
      state.copyWith(
        status: ProfileStatus.saving,
        clearError: true,
        clearFeedback: true,
      ),
    );

    try {
      final saved = await _repository.saveProfile(profile);
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          profile: saved,
          hasUnsavedChanges: false,
          feedbackMessage: 'Profilo salvato con successo.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Errore durante il salvataggio del profilo.',
        ),
      );
    }
  }

  void clearMessages() {
    if (state.errorMessage == null && state.feedbackMessage == null) {
      return;
    }
    emit(state.copyWith(clearError: true, clearFeedback: true));
  }

  void _updateProfileIfChanged(UserProfile Function(UserProfile) updater) {
    final profile = state.profile;
    if (profile == null) return;

    final updatedProfile = updater(profile);
    if (identical(updatedProfile, profile)) {
      return;
    }

    emit(
      state.copyWith(
        status: ProfileStatus.loaded,
        profile: updatedProfile,
        hasUnsavedChanges: true,
        clearError: true,
        clearFeedback: true,
      ),
    );
  }
}