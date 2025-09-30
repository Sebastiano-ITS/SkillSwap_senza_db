import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart'; // Importa per input numerico
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
  bool _isFree = false;

  @override
  void initState() {
    super.initState();
    
    // Assumendo che widget.userProfile.hourlyRate sia double
    final rate = widget.userProfile.hourlyRate;
    
    if (rate == 0.0) {
      _rateController = TextEditingController(text: '');
      _isFree = true;
    } else {
      // Usa .toString() per convertire il double in testo
      _rateController = TextEditingController(text: rate.toString());
      _isFree = false;
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  // Il metodo ora calcola un double per risolvere l'errore di assegnazione.
  Future<void> _updateHourlyRate(FirestoreService firestoreService) async {
    setState(() {
      _isLoading = true;
    });

    double newRateValue;

    if (_isFree) {
      // 0.0 rappresenta "Gratis" nel modello di dati double
      newRateValue = 0.0; 
    } else {
      final input = _rateController.text.trim();
      // Tenta il parsing, se non è un numero valido o è vuoto, usa 0.0
      newRateValue = double.tryParse(input) ?? 0.0;
    }

    // Assicurati che newRateValue sia coerente con il tipo richiesto dal costruttore UserProfile
    final updatedProfile = UserProfile(
      userId: widget.userProfile.userId,
      email: widget.userProfile.email,
      name: widget.userProfile.name,
      canTeach: widget.userProfile.canTeach,
      wantsToLearn: widget.userProfile.wantsToLearn,
      hourlyRate: newRateValue, // Questo ora è un double
    );

    try {
      await firestoreService.saveUserProfile(updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tariffa oraria aggiornata con successo a ${newRateValue == 0.0 ? "Gratis" : "$newRateValue €"}!')),
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
  
  // Funzione helper per visualizzare il rate correttamente nel Text widget
  String _displayRate(dynamic rate) {
    if (rate == null) return 'Non impostato';
    
    // Convertiamo in String nel caso in cui il modello sia stato cambiato e non aggiornato
    final rateValue = double.tryParse(rate.toString()) ?? 0.0; 
    
    if (rateValue == 0.0) {
      return 'Gratis';
    }
    // Formattazione semplice per il double
    return '${rateValue.toStringAsFixed(2)} €'; 
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
                      'Imposta quanto costano le tue lezioni all\'ora. Se lasci 0 o attivi "Gratuite", verrà visualizzato "Gratis".',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),

                    // Toggle per Gratis
                    SwitchListTile(
                      title: const Text('Lezioni Gratuite'),
                      value: _isFree,
                      onChanged: (bool value) {
                        setState(() {
                          _isFree = value;
                          if (value) {
                            _rateController.clear();
                          }
                        });
                      },
                      secondary: Icon(
                        _isFree ? LucideIcons.checkCircle : LucideIcons.euro,
                        color: _isFree ? Colors.green : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Campo Tariffa
                    Row(
                      children: [
                        const Text('€', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              // Permette numeri interi o decimali (con punto)
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), 
                            ],
                            enabled: !_isFree,
                            decoration: InputDecoration(
                              labelText: 'Importo orario',
                              hintText: 'es. 15.00',
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              filled: _isFree,
                              fillColor: _isFree ? Colors.grey.shade100 : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _isLoading ? null : () => _updateHourlyRate(firestoreService),
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
                      'Attuale: ${_displayRate(widget.userProfile.hourlyRate)}',
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