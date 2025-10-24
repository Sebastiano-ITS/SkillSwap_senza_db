import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/flutter_bloc/profile_bloc/profile_cubit.dart';
import 'package:skillswap/flutter_bloc/profile_bloc/profile_state.dart';

import 'package:skillswap/models/user_profile.dart';
import 'package:skillswap/screens/profile/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  UserProfile? profile;
  bool throwOnFetch = false;
  bool throwOnSave = false;

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    if (throwOnFetch) {
      throw Exception('fetch error');
    }
    return profile;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    if (throwOnSave) {
      throw Exception('save error');
    }
    this.profile = profile;
    return profile;
  }
}

void main() {
  group('ProfileCubit', () {
    late FakeProfileRepository repository;
    late ProfileCubit cubit;
    const userId = 'user_1';

    setUp(() {
      repository = FakeProfileRepository();
      cubit = ProfileCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is ProfileState.initial', () {
      expect(cubit.state, ProfileState.initial());
    });

    test('loadProfile success updates state with profile data', () async {
      repository.profile = UserProfile(
        id: userId,
        email: 'user@example.com',
        name: 'Test User',
        canTeach: const ['Dart'],
        wantsToLearn: const ['Flutter'],
        onboardingCompleted: true,
      );

      await cubit.loadProfile(userId);

      expect(cubit.state.status, ProfileStatus.loaded);
      expect(cubit.state.profile?.name, 'Test User');
      expect(cubit.state.hasUnsavedChanges, isFalse);
    });

    test('loadProfile failure emits failure state when profile is missing', () async {
      await cubit.loadProfile(userId);

      expect(cubit.state.status, ProfileStatus.failure);
      expect(cubit.state.profile, isNull);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('updateName marks state as dirty', () async {
      repository.profile = UserProfile(
        id: userId,
        email: 'user@example.com',
        name: 'Old Name',
        canTeach: const [],
        wantsToLearn: const [],
      );

      await cubit.loadProfile(userId);
      cubit.updateName('New Name');

      expect(cubit.state.profile?.name, 'New Name');
      expect(cubit.state.hasUnsavedChanges, isTrue);
    });

    test('saveProfile success clears dirty flag and stores profile', () async {
      repository.profile = UserProfile(
        id: userId,
        email: 'user@example.com',
        name: 'User',
        canTeach: const [],
        wantsToLearn: const [],
      );

      await cubit.loadProfile(userId);
      cubit.addSkillToTeach('Bloc');

      await cubit.saveProfile();

      expect(cubit.state.status, ProfileStatus.loaded);
      expect(cubit.state.hasUnsavedChanges, isFalse);
      expect(repository.profile?.canTeach.contains('Bloc'), isTrue);
      expect(cubit.state.feedbackMessage, isNotNull);
    });

    test('saveProfile failure preserves dirty state and sets error', () async {
      repository.profile = UserProfile(
        id: userId,
        email: 'user@example.com',
        name: 'User',
        canTeach: const [],
        wantsToLearn: const [],
      );
      repository.throwOnSave = true;

      await cubit.loadProfile(userId);
      cubit.updateEmail('updated@example.com');

      await cubit.saveProfile();

      expect(cubit.state.status, ProfileStatus.failure);
      expect(cubit.state.hasUnsavedChanges, isTrue);
      expect(cubit.state.errorMessage, isNotNull);
    });
  });
}
