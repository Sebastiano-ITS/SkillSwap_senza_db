import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_data.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<LoadProfiles>((event, emit) async {
      try {
        // Chiama il metodo per ottenere i dati
        final profiles = LocalData().getAllUsers();
        // Emette lo stato HomeLoaded con i profili
        emit(HomeLoaded(profiles: profiles));
      } catch (e) {
        // Se si verifica un errore, emette lo stato HomeError
        emit(HomeError(message: e.toString()));
      }
    });

    on<SwipeRight>((event, emit) {
      emit(ProfileMatched(profile: event.profile));
    });

    on<SwipeLeft>((event, emit) {
      emit(ProfileRejected(profile: event.profile));
    });
  }
}