import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_data.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<LoadProfiles>((event, emit) async {
      final profiles = LocalData().getAllUsers();
      emit(HomeLoaded(profiles: profiles));
    });

    on<SwipeRight>((event, emit) {
      emit(ProfileMatched(profile: event.profile));
    });

    on<SwipeLeft>((event, emit) {
      emit(ProfileRejected(profile: event.profile));
    });
  }
}