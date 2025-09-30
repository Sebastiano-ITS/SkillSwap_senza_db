import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userId;
  final String email;
  final String name;
  final List<String> canTeach;
  final List<String> wantsToLearn;
  final bool onboardingCompleted;
  final double hourlyRate; // Necessario per la MatchScreen

  UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.canTeach,
    required this.wantsToLearn,
    this.onboardingCompleted = false,
    this.hourlyRate = 15.0, // Valore predefinito in €/ora
  });

  // Factory method per creare un UserProfile da un DocumentSnapshot di Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      // Fornisci un profilo di fallback se i dati sono mancanti o vuoti
      return UserProfile(
        userId: doc.id, 
        email: 'N/A', 
        name: 'Utente Sconosciuto', 
        canTeach: [], 
        wantsToLearn: []
      );
    }

    return UserProfile(
      userId: data['uid'] ?? doc.id,
      email: data['email'] ?? 'N/A',
      name: data['name'] ?? 'Utente Sconosciuto',
      canTeach: List<String>.from(data['canTeach'] ?? []),
      wantsToLearn: List<String>.from(data['wantsToLearn'] ?? []),
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      // Gestisce sia int che double per la tariffa
      hourlyRate: (data['hourlyRate'] is num) ? data['hourlyRate'].toDouble() : 15.0,
    );
  }

  // Metodo per convertire UserProfile in Map per il salvataggio su Firestore
  Map<String, dynamic> toMap() {
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
