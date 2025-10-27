import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

// Stato iniziale (prima del caricamento)
class HomeInitial extends HomeState {}

// Stato di caricamento dei profili
class HomeLoading extends HomeState {}

// Stato quando i profili sono stati caricati correttamente
class HomeLoaded extends HomeState {
  final List<UserProfile> profiles;
  const HomeLoaded({required this.profiles});

  @override
  List<Object?> get props => [profiles];
}

// Stato quando avviene un match
class ProfileMatched extends HomeState {
  final UserProfile profile;
  const ProfileMatched({required this.profile});

  @override
  List<Object?> get props => [profile];
}

// Stato quando un profilo viene rifiutato
class ProfileRejected extends HomeState {
  final UserProfile profile;
  const ProfileRejected({required this.profile});

  @override
  List<Object?> get props => [profile];
}

// Stato di errore
class HomeError extends HomeState {
  final String message;
  const HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}