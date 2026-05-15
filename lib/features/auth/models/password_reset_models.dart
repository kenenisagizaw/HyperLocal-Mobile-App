class PasswordResetRequest {
  const PasswordResetRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}

class PasswordResetVerifyRequest {
  const PasswordResetVerifyRequest({required this.token});

  final String token;

  Map<String, dynamic> toJson() => {'token': token};
}

class PasswordResetVerifyResponse {
  const PasswordResetVerifyResponse({required this.valid});

  final bool valid;

  factory PasswordResetVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetVerifyResponse(valid: json['valid'] == true);
  }
}

class PasswordResetConfirmRequest {
  const PasswordResetConfirmRequest({
    required this.token,
    required this.password,
  });

  final String token;
  final String password;

  Map<String, dynamic> toJson() => {
    'token': token,
    'password': password,
  };
}

class PasswordResetConfirmResponse {
  const PasswordResetConfirmResponse({required this.message});

  final String message;

  factory PasswordResetConfirmResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetConfirmResponse(
      message: json['message']?.toString() ?? 'Password reset successful',
    );
  }
}
