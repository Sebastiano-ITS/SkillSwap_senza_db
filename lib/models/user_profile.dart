class UserProfile {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? bio;
  final String? imageUrl;
  final List<String> canTeach;
  final List<String> wantsToLearn;
  final bool onboardingCompleted;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.bio,
    this.imageUrl,
    required this.canTeach,
    required this.wantsToLearn,
    this.onboardingCompleted = false,
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? bio,
    String? imageUrl,
    List<String>? canTeach,
    List<String>? wantsToLearn,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      canTeach: canTeach ?? List<String>.from(this.canTeach),
      wantsToLearn: wantsToLearn ?? List<String>.from(this.wantsToLearn),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? 'Email non disponibile',
      name: json['name'] as String? ?? 'Nuovo Utente',
      age: json['age'] as int?,
      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,
      canTeach: List<String>.from(json['canTeach'] ?? []),
      wantsToLearn: List<String>.from(json['wantsToLearn'] ?? []),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'imageUrl': imageUrl,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'onboardingCompleted': onboardingCompleted,
    };
  }
}
