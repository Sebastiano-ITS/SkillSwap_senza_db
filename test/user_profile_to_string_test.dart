import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/models/user_profile.dart';

void main() {
  test('UserProfile toString highlights meaningful non-empty attributes', () {
    const profile = UserProfile(
      id: 'id-42',
      userId: 'user-99',
      email: 'alex@example.com',
      name: 'Alex Morgan',
      languages: ['IT', 'EN'],
      canTeach: ['UI Design', 'Figma'],
      wantsToLearn: ['SwiftUI'],
      badges: ['Mentor'],
    );

    final description = profile.toString();

    expect(description, contains('UserProfile✨'));
    expect(description, contains('id=id-42'));
    expect(description, contains('userId=user-99'));
    expect(description, contains('name=Alex Morgan'));
    expect(description, contains('languages=IT/EN'));
    expect(description, contains('teach=UI Design, Figma'));
    expect(description, contains('learn=SwiftUI'));
    expect(description, contains('remote'));
    expect(description, isNot(contains('inPerson')));
    expect(description, contains('badges=Mentor'));
  });
}