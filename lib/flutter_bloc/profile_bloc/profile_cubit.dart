// lib/profile/profile_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/user_profile.dart';

import '../../screens/profile/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository repository})
      : _repository = repository,
        super(ProfileState.initial());

  final ProfileRepository _repository;
  String? _userId;

  // ---------- Load ----------
  Future<void> loadProfile(String userId) async {
    _userId = userId;
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true, clearFeedback: true));

    try {
      final profile = await _repository.fetchProfile(userId);
      if (profile == null) {
        emit(state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Profilo non trovato.',
          clearProfile: true,
          hasUnsavedChanges: false,
        ));
        return;
      }
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        hasUnsavedChanges: false,
        clearError: true,
        clearFeedback: true,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Impossibile caricare il profilo.',
        clearProfile: true,
        hasUnsavedChanges: false,
      ));
    }
  }

  // ---------- Update base fields ----------
  void updateName(String value) {
    final t = value.trim();
    _updateProfileIfChanged((p) => t.isEmpty || t == p.name ? p : p.copyWith(name: t));
  }

  void updateEmail(String value) {
    final t = value.trim();
    _updateProfileIfChanged((p) => t.isEmpty || t == p.email ? p : p.copyWith(email: t));
  }

  void updatePhone(String value) {
    final t = value.trim();
    _updateProfileIfChanged(
          (p) => (t.isEmpty && p.phone == null) || t == (p.phone ?? '') ? p : p.copyWith(phone: t.isEmpty ? null : t),
    );
  }

  void updateCity(String value) {
    final t = value.trim();
    _updateProfileIfChanged(
          (p) => (t.isEmpty && p.city == null) || t == (p.city ?? '') ? p : p.copyWith(city: t.isEmpty ? null : t),
    );
  }

  void updateRadiusKm(double value) {
    _updateProfileIfChanged((p) => (p.radiusKm ?? 0) == value ? p : p.copyWith(radiusKm: value));
  }

  void updateBirthDateIso(String? iso) {
    _updateProfileIfChanged((p) => p.birthDateIso == iso ? p : p.copyWith(birthDateIso: iso));
  }

  void updateBio(String value) {
    final t = value.trim();
    _updateProfileIfChanged(
          (p) => (t.isEmpty && p.bio == null) || t == (p.bio ?? '') ? p : p.copyWith(bio: t.isEmpty ? null : t),
    );
  }

  /// Avatar / immagine profilo
  void updateImageUrl(String path) {
    _updateProfileIfChanged((p) => p.imageUrl == path ? p : p.copyWith(imageUrl: path));
  }

  // ---------- Skills ----------
  void addSkillToTeach(String skill) {
    final t = skill.trim();
    if (t.isEmpty) return;
    _updateProfileIfChanged((p) {
      final list = List<String>.from(p.canTeach);
      if (list.contains(t)) return p;
      list..add(t)..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return p.copyWith(canTeach: list);
    });
  }

  void removeSkillToTeach(String skill) {
    _updateProfileIfChanged((p) {
      final list = List<String>.from(p.canTeach);
      final removed = list.remove(skill);
      return removed ? p.copyWith(canTeach: list) : p;
    });
  }

  void addSkillToLearn(String skill) {
    final t = skill.trim();
    if (t.isEmpty) return;
    _updateProfileIfChanged((p) {
      final list = List<String>.from(p.wantsToLearn);
      if (list.contains(t)) return p;
      list..add(t)..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return p.copyWith(wantsToLearn: list);
    });
  }

  void removeSkillToLearn(String skill) {
    _updateProfileIfChanged((p) {
      final list = List<String>.from(p.wantsToLearn);
      final removed = list.remove(skill);
      return removed ? p.copyWith(wantsToLearn: list) : p;
    });
  }

  // ---------- Save ----------
  Future<void> saveProfile() async {
    final profile = state.profile;
    final userId = _userId;
    if (profile == null || userId == null) return;

    emit(state.copyWith(status: ProfileStatus.saving, clearError: true, clearFeedback: true));
    try {
      final saved = await _repository.saveProfile(profile);
      emit(state.copyWith(
        status: ProfileStatus.loaded,
        profile: saved,
        hasUnsavedChanges: false,
        feedbackMessage: 'Profilo salvato con successo.',
      ));
    } catch (_) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorMessage: 'Errore durante il salvataggio del profilo.',
      ));
    }
  }

  void clearMessages() {
    if (state.errorMessage == null && state.feedbackMessage == null) return;
    emit(state.copyWith(clearError: true, clearFeedback: true));
  }

  // ---------- Util ----------
  void _updateProfileIfChanged(UserProfile Function(UserProfile) updater) {
    final p = state.profile;
    if (p == null) return;
    final updated = updater(p);
    if (identical(updated, p)) return;
    emit(state.copyWith(
      status: ProfileStatus.loaded,
      profile: updated,
      hasUnsavedChanges: true,
      clearError: true,
      clearFeedback: true,
    ));
  }
}
