import 'package:flutter/foundation.dart';

class UserProfile {
  final String uid;
  final String userId;
  final String email;
  final String name;
  final int? age;
  final String imageUrl;
  final String bio;
  final List<String> canTeach;
  final List<String> wantsToLearn;
  final List<String> skills;
  final List<String> skillsToLearn;
  final bool onboardingCompleted;

  const UserProfile({
    required this.uid,
    required this.userId,
    required this.email,
    required this.name,
    this.age,
    this.imageUrl = 'https://via.placeholder.com/600x400',
    this.bio = '',
    this.canTeach = const [],
    this.wantsToLearn = const [],
    this.skills = const [],
    this.skillsToLearn = const [],
    this.onboardingCompleted = false,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['id'] ?? '',
      userId: map['userId'] ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] is int ? map['age'] : (map['age'] != null ? int.tryParse(map['age'].toString()) : null),
      imageUrl: map['imageUrl'] ?? '',
      bio: map['bio'] ?? '',
      canTeach: List<String>.from(map['canTeach'] ?? []),
      wantsToLearn: List<String>.from(map['wantsToLearn'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      skillsToLearn: List<String>.from(map['skillsToLearn'] ?? []),
      onboardingCompleted: map['onboardingCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'userId': userId,
      'email': email,
      'name': name,
      'age': age,
      'imageUrl': imageUrl,
      'bio': bio,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'skills': skills,
      'skillsToLearn': skillsToLearn,
      'onboardingCompleted': onboardingCompleted,
    };
  }
}