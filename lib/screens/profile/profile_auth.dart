import 'package:skillswap/services/auth_service.dart';

import 'profile_cubit.dart';

class AuthServiceProfileAuth implements ProfileAuth {
  AuthServiceProfileAuth(this._authService);

  final AuthService _authService;

  @override
  String? resolveCurrentUserId() {
    return _authService.getCurrentUserId();
  }
}