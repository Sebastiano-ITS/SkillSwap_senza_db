import '../../models/user_profile.dart';
import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

// Caricamento profili
class LoadProfiles extends HomeEvent {
  const LoadProfiles();
}

// Swipe destra (like)
class SwipeRight extends HomeEvent {
  final UserProfile profile;
  const SwipeRight(this.profile);
  @override
  List<Object?> get props => [profile];
}

// Swipe sinistra (nope)
class SwipeLeft extends HomeEvent {
  final UserProfile profile;
  const SwipeLeft(this.profile);
  @override
  List<Object?> get props => [profile];
}

// evento: viene emesso dopo la chiusura del dialog
class DialogClosed extends HomeEvent {
  const DialogClosed();
}