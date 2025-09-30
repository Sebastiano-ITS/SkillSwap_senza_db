import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Istanza di Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Istanza di Firestore per il database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stato di caricamento iniziale per l'AuthWrapper
  bool _isInitialLoading = true;

  // Getter per lo stato di caricamento (utilizzato in main.dart)
  bool? get isInitialLoading => _isInitialLoading;

  // Stream per ascoltare i cambiamenti dello stato di autenticazione dell'utente
  Stream<User?> get userStream {
    // Quando lo stream emette il primo valore, impostiamo isInitialLoading a false
    _auth.authStateChanges().listen((user) {
      if (_isInitialLoading) {
        // Usiamo un piccolo ritardo per assicurarci che l'UI abbia il tempo di aggiornarsi
        Future.delayed(Duration(milliseconds: 50), () {
          _isInitialLoading = false;
        });
      }
    });
    return _auth.authStateChanges();
  }

  /// ----------------------------------------------------------------------
  /// Metodi di Autenticazione (Utilizzati in auth_screen.dart)
  /// ----------------------------------------------------------------------

  // 1. Metodo di Registrazione (Sign Up)
  // Questo metodo è chiamato da AuthScreen e include la creazione del record utente su Firestore.
  Future<void> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Salva i dati iniziali dell'utente in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': Timestamp.now(),
          'onboardingCompleted': false, // Flag iniziale per l'onboarding
        });
      }
    } on FirebaseAuthException {
      rethrow; // Rilancia l'eccezione per la gestione in AuthScreen
    } catch (e) {
      // Rilancia qualsiasi altro errore
      throw Exception('Errore sconosciuto durante la registrazione: $e');
    }
  }

  // 2. Metodo di Accesso (Sign In)
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow; // Rilancia l'eccezione per la gestione in AuthScreen
    } catch (e) {
      throw Exception('Errore sconosciuto durante l\'accesso: $e');
    }
  }

  User? get currentUser {
  return _auth.currentUser;
}

  // 3. Metodo di Disconnessione (Sign Out)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}