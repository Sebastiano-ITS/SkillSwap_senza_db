import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/models/user_profile.dart';

void main() {
  const baseProfile = UserProfile(
    id: 'id-1',
    userId: 'user-1',
    email: 'user@example.com',
    name: 'Alex',
  );

  group('UserProfile skill toggles', () {
    test('toggling off a teaching skill removes it instead of archiving it', () {
      final profile = baseProfile.copyWith(
        canTeach: const ['UI Design'],
        archivedTeachSkills: const ['SwiftUI'],
      );

      final updated = profile.toggleTeachSkill('UI Design');

      expect(updated.canTeach, isEmpty);
      expect(updated.archivedTeachSkills, equals(const ['SwiftUI']));
    });

    test('toggling off a learning skill removes it instead of archiving it', () {
      final profile = baseProfile.copyWith(
        wantsToLearn: const ['Motion Design'],
        archivedLearnSkills: const ['Spanish'],
      );

      final updated = profile.toggleLearnSkill('Motion Design');

      expect(updated.wantsToLearn, isEmpty);
      expect(updated.archivedLearnSkills, equals(const ['Spanish']));
    });

    test('adding a teaching skill brings it back after removal', () {
      final profile = baseProfile.copyWith(canTeach: const ['Figma']);

      final removed = profile.toggleTeachSkill('Figma');
      final updated = removed.addTeachSkill('Figma');

      expect(updated.canTeach, equals(const ['Figma']));
    });

    test('adding a learning skill brings it back after removal', () {
      final profile = baseProfile.copyWith(wantsToLearn: const ['SwiftUI']);

      final removed = profile.toggleLearnSkill('SwiftUI');
      final updated = removed.addLearnSkill('SwiftUI');

      expect(updated.wantsToLearn, equals(const ['SwiftUI']));
    });
  });
}