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
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

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

    setState(() => _isLoading = true);

    final finalName = widget.name.isNotEmpty ? widget.name : widget.email.split('@')[0];
    final finalEmail = widget.email;
    final bio = _bioController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    final newProfile = UserProfile(
      userId: widget.userId,
      email: finalEmail,
      name: finalName,
      canTeach: _canTeach,
      wantsToLearn: _wantsToLearn,
      onboardingCompleted: true,
      bio: bio,
      age: age,
      imageUrl: '', uid: '',
    );

    try {
      await firestoreService.saveUserProfile(newProfile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel salvataggio del profilo: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() => setState(() => _currentStep++);

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final welcomeName = widget.name.isNotEmpty ? widget.name : widget.email.split('@')[0];

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
                  Text('Benvenuto in SkillSwap, $welcomeName!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo.shade600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text('Passaggio ${_currentStep + 1} di 3', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

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
                          onSelected: (_) => _toggleSkill(skill, true),
                          labelStyle: TextStyle(color: isSelected ? Colors.yellow.shade900 : Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Avanti: Cosa vuoi imparare?', style: TextStyle(color: Colors.white)),
                    ),
                  ],

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
                          onSelected: (_) => _toggleSkill(skill, false),
                          labelStyle: TextStyle(color: isSelected ? Colors.indigo.shade900 : Colors.black),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Avanti: Bio e Età', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: Text('Torna indietro', style: TextStyle(color: Colors.indigo.shade500)),
                    ),
                  ],

                  if (_currentStep == 2) ...[
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Scrivi una breve bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Età'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: () => _completeOnboarding(firestoreService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Completa il profilo', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => setState(() => _currentStep = 1),
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