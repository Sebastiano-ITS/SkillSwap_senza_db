import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/local_data.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/match_services.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final MatchService matchService;
  final AuthService authService;

  HomeBloc({
    required this.matchService,
    required this.authService,
  }) : super(HomeInitial()) {
    on<LoadProfiles>(_onLoad);
    on<SwipeRight>(_onSwipeRight);
    on<SwipeLeft>(_onSwipeLeft);
  }

  void _onLoad(LoadProfiles event, Emitter<HomeState> emit) async {
    final profiles = LocalData().getAllUsers();
    emit(HomeLoaded(profiles: profiles));
  }

  void _onSwipeRight(SwipeRight event, Emitter<HomeState> emit) async {
    final currentUser = authService.getCurrentUserProfile();
    if (currentUser == null) return;

    final target = event.profile;

    final isReciprocal = target.wantsToLearn.any((skill) => currentUser.canTeach.contains(skill));

    if (isReciprocal) {
      await matchService.saveMatch(target.id);
      emit(ProfileMatched(profile: target));
    } else {
      emit(ProfileMatched(profile: target));
    }
  }

  void _onSwipeLeft(SwipeLeft event, Emitter<HomeState> emit) {
    emit(ProfileRejected(profile: event.profile));
  }
}