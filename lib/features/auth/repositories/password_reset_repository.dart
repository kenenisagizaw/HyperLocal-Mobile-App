import '../../../data/datasources/remote/auth_api.dart';
import '../models/password_reset_models.dart';

class PasswordResetRepository {
  const PasswordResetRepository({required AuthApi api}) : _api = api;

  final AuthApi _api;

  Future<void> requestReset(PasswordResetRequest request) async {
    await _api.requestPasswordReset(email: request.email);
  }

  Future<PasswordResetVerifyResponse> verifyToken(
    PasswordResetVerifyRequest request,
  ) async {
    final response = await _api.verifyPasswordResetToken(token: request.token);
    return PasswordResetVerifyResponse.fromJson(response);
  }

  Future<PasswordResetConfirmResponse> confirmReset(
    PasswordResetConfirmRequest request,
  ) async {
    final response = await _api.confirmPasswordReset(
      token: request.token,
      newPassword: request.newPassword,
    );
    return PasswordResetConfirmResponse.fromJson(response);
  }
}
