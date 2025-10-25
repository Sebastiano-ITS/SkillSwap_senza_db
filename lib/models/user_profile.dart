// lib/models/user_profile.dart
class UserProfile {
  final String id;
  final String email;
  final String name;

  // Campi opzionali aggiunti per allineamento con onboarding
  final int? age;
  final String? birthDateIso; // es. "1998-06-15"
  final String? phone;
  final String? city;
  final double? radiusKm;

  final String? bio;
  final String? imageUrl;

  final List<String> canTeach;
  final List<String> wantsToLearn;
  final bool onboardingCompleted;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.age,
    this.birthDateIso,
    this.phone,
    this.city,
    this.radiusKm,
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
    String? birthDateIso,
    String? phone,
    String? city,
    double? radiusKm,
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
      birthDateIso: birthDateIso ?? this.birthDateIso,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      radiusKm: radiusKm ?? this.radiusKm,
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
      age: json['age'] is int ? json['age'] as int : (json['age'] is String ? int.tryParse(json['age']) : null),
      birthDateIso: json['birthDateIso'] as String?,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      radiusKm: (json['radiusKm'] is num) ? (json['radiusKm'] as num).toDouble() : null,
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
      'birthDateIso': birthDateIso,
      'phone': phone,
      'city': city,
      'radiusKm': radiusKm,
      'bio': bio,
      'imageUrl': imageUrl,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'onboardingCompleted': onboardingCompleted,
    };
  }
}
