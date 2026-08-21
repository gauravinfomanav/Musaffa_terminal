import 'dart:convert';

import 'package:musaffa_terminal/models/auth_models.dart';
import 'package:musaffa_terminal/web_service.dart';

class AuthService {
  Future<EmailCheckResult> checkEmail(String email) async {
    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['auth', 'check-email'],
      body: {
        'email': email.trim(),
      },
      attachAuthToken: false,
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      return EmailCheckResult.fromJson(json);
    }

    throw AuthException(
      _messageFromResponse(response) ?? 'Unable to verify email',
      statusCode: response.statusCode,
    );
  }

  Future<RegisterResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final trimmedEmail = email.trim();
    final resolvedName = (name?.trim().isNotEmpty == true)
        ? name!.trim()
        : trimmedEmail.split('@').first;

    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['auth', 'register'],
      body: {
        'email': trimmedEmail,
        'password': password,
        'name': resolvedName,
      },
      attachAuthToken: false,
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      return RegisterResult.fromJson(json);
    }

    throw AuthException(
      _messageFromResponse(response) ?? 'Registration failed',
      statusCode: response.statusCode,
    );
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['auth', 'login'],
      body: {
        'email': email.trim(),
        'password': password,
      },
      attachAuthToken: false,
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      final result = LoginResult.fromJson(json);
      if (result.token.isEmpty) {
        throw const AuthException('Login succeeded but no token was returned');
      }
      return result;
    }

    throw AuthException(
      _messageFromResponse(response) ?? 'Login failed',
      statusCode: response.statusCode,
    );
  }

  Future<void> logout({String? bearerToken}) async {
    final response = await WebService.callApi(
      method: HttpMethod.POST,
      path: ['auth', 'logout'],
      attachAuthToken: bearerToken == null,
      bearerToken: bearerToken,
    );

    // Local session is cleared by AuthController regardless of API result.
    if (response.status != ApiStatus.SUCCESS &&
        response.statusCode != 401) {
      // Soft-fail: still allow local logout.
      return;
    }
  }

  Future<AuthUser> me() async {
    final response = await WebService.callApi(
      method: HttpMethod.GET,
      path: ['auth', 'me'],
      attachAuthToken: true,
    );

    if (response.status == ApiStatus.SUCCESS && response.data != null) {
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? {};
      return AuthUser.fromJson(data);
    }

    throw AuthException(
      _messageFromResponse(response) ?? 'Authentication required',
      statusCode: response.statusCode,
    );
  }

  String? _messageFromResponse(ApiResponse response) {
    if (response.data == null || response.data!.isEmpty) {
      return response.errorMessage;
    }
    try {
      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      final message = json['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {}
    return response.errorMessage;
  }
}
