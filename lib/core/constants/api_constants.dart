class ApiConstants {
  static const String baseUrl = 'http://192.168.137.133:5000';

  static const String authBase = '/api/auth';
  static const String register = '$authBase/register';
  static const String login = '$authBase/login';
  static const String me = '$authBase/me';
  static const String refreshToken = '$authBase/refresh-token';
  static const String logout = '$authBase/logout';
  static const String verifyEmailToken = '$authBase/verify-email';
  static const String sendEmailVerificationCode =
      '$authBase/send-email-verification-code';
  static const String verifyEmailCode = '$authBase/verify-email-code';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String resetPassword = '$authBase/reset-password';
  static const String googleLogin = '$authBase/google';
  static const String identityUpload = '$authBase/identity/upload';
  static const String identityStatus = '$authBase/identity/status';

  static const String userProfile = '/api/users/profile';
  static const String userProfileAvatar = '/api/users/profile/avatar';
  static const String users = '/api/users';
  static const String userPublicProfile = '/api/users';

  static const String providerProfile = '/api/providers/profile';
  static const String providerPortfolio = '/api/providers/profile/portfolio';
  static const String providerCertifications =
      '/api/providers/profile/certifications';
  static const String providers = '/api/providers';

  static const String serviceRequests = '/api/service-requests';
  static const String serviceRequestsMine = '/api/service-requests/mine';

  static const String quotes = '/api/quotes';
  static const String quotesMine = '/api/quotes/mine';
  static const String quotesForRequest = '/api/quotes/service-request';
  static const String quotesAccept = '/api/quotes/requests';

  static const String bookings = '/api/bookings';
  static const String bookingsMine = '/api/bookings/mine';
  static const String bookingSlots = '/api/bookings/slots';

  static const String reviews = '/api/reviews';
  static const String providerReviews = '/api/providers';
}
