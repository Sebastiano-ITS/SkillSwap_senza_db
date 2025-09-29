import 'package:cloud_firestore/cloud_firestore.dart';

// Modello dati per il profilo utente di SkillSwap
class UserProfile {
  final String userId;
  final String email;
  final String name;
  final List<String> canTeach; // Competenze che l'utente può insegnare
  final List<String> wantsToLearn; // Competenze che l'utente vuole imparare
  final String hourlyRate; // Tariffa oraria (es. "Gratis" o "15 €")

  UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    this.canTeach = const [],
    this.wantsToLearn = const [],
    this.hourlyRate = 'Gratis',
  });

  // Metodo per creare un UserProfile da un DocumentSnapshot di Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? 'SkillSwapper',
      canTeach: List<String>.from(data['canTeach'] ?? []),
      wantsToLearn: List<String>.from(data['wantsToLearn'] ?? []),
      hourlyRate: data['hourlyRate'] ?? 'Gratis',
    );
  }

  // Metodo per convertire UserProfile in un Map per Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'canTeach': canTeach,
      'wantsToLearn': wantsToLearn,
      'hourlyRate': hourlyRate,
    };
  }
}
