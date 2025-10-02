import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory method per creare un UserProfile da un DocumentSnapshot di Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    // Se i dati sono null (documento non esiste), forniamo un profilo di fallback
    if (data == null) {
      return UserProfile(
          userId: doc.id,
          email: 'Email non disponibile', // Fallback
          name: 'Nuovo Utente', // Fallback
          canTeach: [],
          wantsToLearn: []
      );
    }

    // Estrazione dei campi con fallback se mancanti o null
    return UserProfile(
      // Usiamo l'ID del documento se 'uid' non è presente
      userId: data['uid'] as String? ?? doc.id,

      // Se il campo 'email' è null, usiamo 'Email non disponibile'.
      email: data['email'] as String? ?? 'Email non disponibile',

      // Se il campo 'name' è null o mancante, usiamo 'Nuovo Utente'.
      name: data['name'] as String? ?? 'Nuovo Utente',

      canTeach: List<String>.from(data['canTeach'] ?? []),
      wantsToLearn: List<String>.from(data['wantsToLearn'] ?? []),
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
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
