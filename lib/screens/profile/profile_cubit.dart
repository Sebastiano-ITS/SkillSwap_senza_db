import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../models/user_profile.dart';

// --------- INTERFACCE --------- //

// Definisce l'interfaccia per un servizio di autenticazione.
abstract class ProfileAuth {
  String? resolveCurrentUserId();
}

// Definisce l'interfaccia per un repository di profili utente.
abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile(String userId);
  Future<void> save(UserProfile profile);
}

// --------- CUBIT --------- //

class ProfileCubit extends Cubit<UserProfile?> {
  ProfileCubit({
    required this.auth,
    required this.repository,
  }) : super(null) {
    _init();
  }

  final ProfileAuth auth;
  final ProfileRepository repository;
  StreamSubscription? _profileSubscription;

  void _init() {
    final userId = auth.resolveCurrentUserId();
    if (userId == null) {
      return;
    }

    _profileSubscription?.cancel();
    _profileSubscription = repository.watchProfile(userId).listen(emit);
  }

  Future<void> updateProfile(UserProfile profile) async {
    await repository.save(profile);
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}
