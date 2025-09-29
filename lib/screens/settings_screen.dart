import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  const SettingsScreen({super.key, required this.userProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _rateController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(text: widget.userProfile.hourlyRate);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _updateHourlyRate(FirestoreService firestoreService) async {
    setState(() {
      _isLoading = true;
    });

    final newRate = _rateController.text.trim().isEmpty ? 'Gratis' : _rateController.text.trim();
    
    final updatedProfile = UserProfile(
      userId: widget.userProfile.userId,
      email: widget.userProfile.email,
      name: widget.userProfile.name,
      canTeach: widget.userProfile.canTeach,
      wantsToLearn: widget.userProfile.wantsToLearn,
      hourlyRate: newRate,
    );

    try {
      await firestoreService.saveUserProfile(updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tariffa oraria aggiornata con successo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante l\'aggiornamento.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sezione Tariffa Oraria
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tariffa Oraria Lezioni',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Imposta quanto costano le tue lezioni all\'ora (es. "20 €" o "Gratis").',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _rateController,
                            decoration: const InputDecoration(
                              labelText: 'Tariffa (es. 15 €)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () => _updateHourlyRate(firestoreService),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade600,
                                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Salva', style: TextStyle(color: Colors.white)),
                              ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Attuale: ${widget.userProfile.hourlyRate}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // Pulsante Logout
            ElevatedButton.icon(
              onPressed: () async {
                await authService.signOut();
                // Dopo il logout, l'AuthWrapper reindirizzerà a AuthScreen
              },
              icon: const Icon(LucideIcons.logOut, color: Colors.white),
              label: const Text('Esci', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
