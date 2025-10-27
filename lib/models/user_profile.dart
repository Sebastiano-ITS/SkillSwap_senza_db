// Modello che rappresenta un profilo utente
class UserProfile {
  final String id;
  final String email;
  final String name;
  final int? age;
  final String? birthDateIso;
  final String? phone;
  final String? location;
  final double? distanceKm;
  final String? city;
  final double? radiusKm;
  final String? bio;
  final String? imageUrl;
  final List<String> media;
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
    this.location,
    this.distanceKm,
    this.city,
    this.radiusKm,
    this.bio,
    this.imageUrl,
    this.media = const [],
    required this.canTeach,
    required this.wantsToLearn,
    this.onboardingCompleted = false,
  });

  // Crea una copia del profilo con eventuali modifiche
  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? birthDateIso,
    String? phone,
    String? location,
    double? distanceKm,
    String? city,
    double? radiusKm,
    String? bio,
    String? imageUrl,
    List<String>? media,
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
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      city: city ?? this.city,
      radiusKm: radiusKm ?? this.radiusKm,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      media: media ?? List<String>.from(this.media),
      canTeach: canTeach ?? List<String>.from(this.canTeach),
      wantsToLearn: wantsToLearn ?? List<String>.from(this.wantsToLearn),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  // Crea un oggetto UserProfile a partire da un JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? 'Email non disponibile',
      name: json['name'] as String? ?? 'Utente senza nome',

      // Converte l'età da int o da stringa se serve
      age: json['age'] is int
          ? json['age'] as int
          : (json['age'] is String ? int.tryParse(json['age']) : null),

      birthDateIso: json['birthDateIso'] as String?,
      phone: json['phone'] as String?,

      // Se location non è disponibile, usa city come fallback
      location: json['location'] as String? ?? json['city'] as String?,

      // Calcola la distanza disponibile, compatibile con vecchi campi
      distanceKm: (json['distanceKm'] is num)
          ? (json['distanceKm'] as num).toDouble()
          : (json['radiusKm'] is num)
          ? (json['radiusKm'] as num).toDouble()
          : null,

      city: json['city'] as String?,
      radiusKm: (json['radiusKm'] is num)
          ? (json['radiusKm'] as num).toDouble()
          : null,

      bio: json['bio'] as String?,
      imageUrl: json['imageUrl'] as String?,

      // Media: supporta sia "media" che "localImages"
      media: _readStringList(json['media'] ?? json['localImages']),

      canTeach: List<String>.from(json['canTeach'] ?? []),
      wantsToLearn: List<String>.from(json['wantsToLearn'] ?? []),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  // Converte l'oggetto UserProfile in una mappa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'birthDateIso': birthDateIso,
      'phone': phone,
      'location': location,
      'distanceKm': distanceKm,
      'city': city,
      'radiusKm': radiusKm,
      'bio': bio,
      'imageUrl': imageUrl,
      'media': media,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'onboardingCompleted': onboardingCompleted,
    };
  }
}

// Funzione di supporto per convertire una lista dinamica in List<String>
List<String> _readStringList(dynamic jsonValue) {
  if (jsonValue is List) {
    return List<String>.from(jsonValue.map((item) => item.toString()));
  }
  return [];
}