import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/profile/user_repository.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/match_services.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final MatchService matchService;
  final AuthService authService;
  final UsersRepository usersRepository;

  List<UserProfile> _profiles = const [];

  HomeBloc({
    required this.matchService,
    required this.authService,
    required this.usersRepository,
  }) : super(HomeInitial()) {
    on<LoadProfiles>(_onLoad);
    on<SwipeRight>(_onSwipeRight);
    on<SwipeLeft>(_onSwipeLeft);
    on<DialogClosed>(_onDialogClosed); // nuovo evento
  }

  Future<void> _onLoad(LoadProfiles event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final all = await usersRepository.load();

      final me = authService.getCurrentUserProfile();
      final filtered = me == null
          ? List<UserProfile>.from(all)
          : all.where((u) => u.id != me.id).toList();

      _profiles = filtered;
      emit(HomeLoaded(profiles: _profiles));
    } catch (e) {
      emit(HomeError(message: "Failed to load profiles: ${e.toString()}"));
    }
  }

  Future<void> _onSwipeRight(SwipeRight event, Emitter<HomeState> emit) async {
    final currentUser = authService.getCurrentUserProfile();
    final target = event.profile;

    try {
      await matchService.saveMatch(target.id);
    } catch (_) {}

    emit(ProfileMatched(profile: target));
  }

  void _onSwipeLeft(SwipeLeft event, Emitter<HomeState> emit) {
    final target = event.profile;
    emit(ProfileRejected(profile: target));
    _removeAndRefresh(target, emit);
  }

  void _onDialogClosed(DialogClosed event, Emitter<HomeState> emit) {
    // Dopo la chiusura del dialog rimuove la card e aggiorna UI
    if (state is ProfileMatched) {
      final matched = (state as ProfileMatched).profile;
      _removeAndRefresh(matched, emit);
    } else {
      emit(HomeLoaded(profiles: _profiles));
    }
  }

  void _removeAndRefresh(UserProfile target, Emitter<HomeState> emit) {
    _profiles = _profiles.where((p) => p.id != target.id).toList();
    emit(HomeLoaded(profiles: _profiles));
  }
}