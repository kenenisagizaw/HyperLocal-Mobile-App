class PasswordResetDeepLinkService {
  const PasswordResetDeepLinkService();

  String? extractToken(Uri uri) {
    final isHttpsReset =
        uri.scheme == 'https' &&
        uri.host == 'myapp.com' &&
        uri.path == '/reset-password';
    final isCustomReset =
        uri.scheme == 'myapp' &&
        (uri.host == 'reset-password' || uri.path == '/reset-password');

    if (!isHttpsReset && !isCustomReset) {
      return null;
    }

    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }
}
