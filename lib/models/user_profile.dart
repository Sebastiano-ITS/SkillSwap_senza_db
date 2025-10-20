class UserProfile {
  final String userId;
  final String email;
  final String name;
  final List<String> canTeach;
  final List<String> wantsToLearn;
  final bool onboardingCompleted;
  final double hourlyRate;

  UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.canTeach,
    required this.wantsToLearn,
    this.onboardingCompleted = false,
    this.hourlyRate = 15.0,
  });

  // Factory method per creare un UserProfile da un oggetto JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? 'Email non disponibile',
      name: json['name'] as String? ?? 'Nuovo Utente',
      canTeach: List<String>.from(json['canTeach'] ?? []),
      wantsToLearn: List<String>.from(json['wantsToLearn'] ?? []),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      hourlyRate: (json['hourlyRate'] is num) ? json['hourlyRate'].toDouble() : 15.0,
    );
  }

  // Metodo per convertire UserProfile in Map per il salvataggio su JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': userId,
      'email': email,
      'name': name,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'onboardingCompleted': onboardingCompleted,
      'hourlyRate': hourlyRate,
    };
  }
}
