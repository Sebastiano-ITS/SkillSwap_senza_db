import 'package:cloud_firestore/cloud_firestore.dart'; // Importato per il tipo DocumentSnapshot

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
    this.hourlyRate = 15.0, // Valore predefinito in €/ora
  });

  // Factory method per creare un UserProfile da un DocumentSnapshot di Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    // Usiamo Map<String, dynamic> per la massima sicurezza sul tipo di dato
    final data = doc.data() as Map<String, dynamic>?;

    // Se i dati sono nulli, restituisci un profilo di fallback minimo.
    if (data == null) {
      return UserProfile(
        userId: doc.id, 
        email: 'N/A', 
        name: 'Utente Sconosciuto', 
        canTeach: const [], // Usa const [] per liste vuote
        wantsToLearn: const []
      );
    }

    return UserProfile(
      // Usiamo data['uid'] come fallback doc.id se presente
      userId: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? 'N/A',
      name: data['name'] as String? ?? 'Utente Sconosciuto',
      // Ci assicuriamo che i campi lista siano list<String> con un fallback a lista vuota
      canTeach: List<String>.from(data['canTeach'] as List? ?? const []),
      wantsToLearn: List<String>.from(data['wantsToLearn'] as List? ?? const []),
      
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      
      // Gestisce double/int da Firestore con fallback sicuro
      hourlyRate: (data['hourlyRate'] is num) ? (data['hourlyRate'] as num).toDouble() : 15.0,
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
