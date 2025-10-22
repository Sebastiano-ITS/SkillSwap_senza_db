import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/models/user_profile.dart';
import 'package:skillswap/screens/profile/profile_cubit.dart';
import 'package:skillswap/screens/profile/profile_state.dart';
import 'package:skillswap/screens/profile/skill_category.dart';

void main() {
  late FakeProfileRepository repository;
  late FakeAuthService authService;
  late ProfileCubit cubit;

  UserProfile buildProfile({required String id, List<String>? teachSkills}) {
    return UserProfile(
      id: id,
      userId: id,
      email: '$id@example.com',
      name: 'User $id',
      canTeach: teachSkills ?? const ['UI Design'],
      wantsToLearn: const ['SwiftUI'],
    );
  }

  setUp(() {
    repository = FakeProfileRepository();
    authService = FakeAuthService();
    cubit = ProfileCubit(
      repository: repository,
      authService: authService,
    );
  });

  tearDown(() async {
    await cubit.close();
    repository.dispose();
  });

  test('emits failure when no user id can be resolved', () async {
    final states = <ProfileState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.load();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.status, ProfileStatus.failure);
    expect(cubit.state.errorMessage, contains('utente'));

    await sub.cancel();
  });

  test('loads profile stream and updates when repository emits changes', () async {
    const userId = 'user-123';
    authService.currentUserId = userId;
    final initialProfile = buildProfile(id: userId);

    final states = <ProfileState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.load(fallback: initialProfile);
    expect(cubit.state.profile, initialProfile);
    expect(cubit.state.status, ProfileStatus.loading);

    repository.emit(initialProfile);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.status, ProfileStatus.loaded);
    expect(cubit.state.profile, initialProfile);

    final updated = initialProfile.addTeachSkill('Leadership');
    repository.emit(updated);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(cubit.state.profile?.canTeach.contains('Leadership'), isTrue);

    await sub.cancel();
  });

  test('toggleSkill removes the skill and persists through repository', () async {
    const userId = 'user-456';
    final profile = buildProfile(id: userId, teachSkills: const ['UI Design', 'Figma']);

    await cubit.load(userId: userId, fallback: profile);
    repository.emit(profile);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await cubit.toggleSkill(SkillCategory.teach, 'UI Design');

    expect(repository.lastSaved?.canTeach.contains('UI Design'), isFalse);
    expect(cubit.state.profile?.canTeach.contains('UI Design'), isFalse);
  });
}

class FakeProfileRepository implements ProfileRepository {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? lastSaved;

  @override
  Stream<UserProfile?> watchProfile(String userId) {
    return _controller.stream;
  }

  @override
  Future<void> save(UserProfile profile) async {
    lastSaved = profile;
  }

  void emit(UserProfile? profile) {
    _controller.add(profile);
  }

  void dispose() {
    _controller.close();
  }
}

class FakeAuthService implements ProfileAuth {
  String? currentUserId;

  @override
  String? resolveCurrentUserId() => currentUserId;
}