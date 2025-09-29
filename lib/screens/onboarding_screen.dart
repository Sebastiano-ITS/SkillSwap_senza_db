import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String email;
  const OnboardingScreen({super.key, required this.userId, required this.name, required this.email});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  List<String> _canTeach = [];
  List<String> _wantsToLearn = [];
  bool _isLoading = false;

  final List<String> _availableSkills = const [
    'Cucina', 'Pianoforte', 'Programmazione', 'Lingua Spagnola',
    'Fotografia', 'Yoga', 'Montaggio Video', 'Giardinaggio', 'Scacchi',
    'Disegno', 'Falegnameria', 'Marketing Digitale'
  ];

  void _toggleSkill(String skill, bool isTeach) {
    setState(() {
      if (isTeach) {
        _canTeach.contains(skill) ? _canTeach.remove(skill) : _canTeach.add(skill);
      } else {
        _wantsToLearn.contains(skill) ? _wantsToLearn.remove(skill) : _wantsToLearn.add(skill);
      }
    });
  }

  Future<void> _completeOnboarding(FirestoreService firestoreService) async {
    if (_canTeach.isEmpty && _wantsToLearn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una competenza da insegnare o da imparare!')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final newProfile = UserProfile(
      userId: widget.userId,
      email: widget.email,
      name: widget.name,
      canTeach: _canTeach,
      wantsToLearn: _wantsToLearn,
    );

    try {
      await firestoreService.saveUserProfile(newProfile);
      // Il MainLayout vedrà l'aggiornamento e cambierà schermata automaticamente
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel salvataggio del profilo: $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Benvenuto in SkillSwap!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Passaggio ${_currentStep + 1} di 2',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  
                  // Step 1: Competenze da Insegnare
                  if (_currentStep == 0) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.zap, color: Colors.yellow, size: 28),
                        SizedBox(width: 8),
                        Text('Cosa sai INSEGNARE?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableSkills.map((skill) {
                        final isSelected = _canTeach.contains(skill);
                        return ChoiceChip(
                          label: Text(skill),
                          selected: isSelected,
                          selectedColor: Colors.yellow.shade100,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) => _toggleSkill(skill, true),
                          labelStyle: TextStyle(color: isSelected ? Colors.yellow.shade900 : Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.yellow.shade600 : Colors.grey.shade300)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => setState(() => _currentStep = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Avanti: Cosa vuoi imparare?', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],

                  // Step 2: Competenze da Imparare
                  if (_currentStep == 1) ...[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bookOpen, color: Colors.indigo, size: 28),
                        SizedBox(width: 8),
                        Text('Cosa vuoi IMPARARE?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableSkills.map((skill) {
                        final isSelected = _wantsToLearn.contains(skill);
                        return ChoiceChip(
                          label: Text(skill),
                          selected: isSelected,
                          selectedColor: Colors.indigo.shade100,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (selected) => _toggleSkill(skill, false),
                          labelStyle: TextStyle(color: isSelected ? Colors.indigo.shade900 : Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.indigo.shade600 : Colors.grey.shade300)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _completeOnboarding(firestoreService),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('COMPLETA IL PROFILO', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: Text('Torna indietro', style: TextStyle(color: Colors.indigo.shade500)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
