import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _submitAuthForm(AuthService authService) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await authService.signIn(_emailController.text, _passwordController.text);
      } else {
        await authService.signUp(_emailController.text, _passwordController.text, _nameController.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Errore di autenticazione sconosciuto.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Si è verificato un errore inatteso.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SkillSwap',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Accedi per scambiare competenze' : 'Crea il tuo account SkillSwap',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // Campo Nome (solo per Signup)
                  if (!_isLogin)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                    ),

                  // Campo Email
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                  ),

                  // Campo Password
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  ),

                  // Messaggio di errore
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Bottone principale
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () => _submitAuthForm(authService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade600,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      _isLogin ? 'ACCEDI' : 'REGISTRATI',
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Toggle tra Login e Signup
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = ''; // Resetta l'errore
                      });
                    },
                    child: Text(
                      _isLogin ? 'Non hai un account? Registrati qui' : 'Hai già un account? Accedi qui',
                      style: TextStyle(color: Colors.indigo.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
