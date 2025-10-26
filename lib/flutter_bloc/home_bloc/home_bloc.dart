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

  HomeBloc({
    required this.matchService,
    required this.authService,
    required this.usersRepository,
  }) : super(HomeInitial()) {
    on<LoadProfiles>(_onLoad);
    on<SwipeRight>(_onSwipeRight);
    on<SwipeLeft>(_onSwipeLeft);
  }

  Future<void> _onLoad(LoadProfiles event, Emitter<HomeState> emit) async {
    try {
      final profiles = await usersRepository.load();
      emit(HomeLoaded(profiles: profiles));
    } catch (e) {
      emit(HomeError(message: "Failed to load profiles: ${e.toString()}"));
    }
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
