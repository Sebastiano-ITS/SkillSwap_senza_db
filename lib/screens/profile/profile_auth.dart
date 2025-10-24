import 'package:skillswap/services/auth_service.dart';
import 'profile_cubit.dart';

// Questa classe fa da ponte tra il ProfileCubit e l'AuthService.
class AuthServiceProfileAuth implements ProfileAuth {
  AuthServiceProfileAuth(this._authService);

  final AuthService _authService;

  @override
  String? resolveCurrentUserId() {
    // Il metodo getCurrentUserId() non esiste più.
    // È stato sostituito dal getter 'currentUserId'.
    return _authService.getCurrentUserId();
  }
}
