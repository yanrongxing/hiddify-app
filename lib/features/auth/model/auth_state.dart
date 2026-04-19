import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/auth/model/user_model.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  /// User is not logged in.
  const factory AuthState.unauthenticated() = Unauthenticated;

  /// Login/register is in progress.
  const factory AuthState.loading() = AuthLoading;

  /// User is logged in.
  const factory AuthState.authenticated({
    required UserModel user,
    required String authToken,
  }) = Authenticated;

  /// Auth failed with an error.
  const factory AuthState.error({
    required String message,
  }) = AuthError;
}
