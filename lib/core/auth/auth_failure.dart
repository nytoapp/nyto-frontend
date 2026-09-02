import 'dart:async';
import 'dart:io';

import 'package:nyto_app/core/api/api_client.dart';

/// Why an authentication attempt did not succeed.
///
/// Every provider funnels into this enum so the UI never has to interpret raw
/// provider exceptions, HTTP status codes, or platform error strings.
enum AuthFailureKind {
  /// The user backed out of a provider sheet. Not an error — show nothing.
  cancelled,
  network,
  timeout,
  invalidCode,
  expiredCode,
  tooManyAttempts,
  rateLimited,
  invalidPhone,
  providerUnavailable,
  providerRejected,
  notConfigured,
  server,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, this.message);

  final AuthFailureKind kind;

  /// Human-readable and safe to show. Never contains tokens, codes or traces.
  final String message;

  bool get isCancellation => kind == AuthFailureKind.cancelled;

  /// Retrying the same action could plausibly succeed.
  bool get isRetryable =>
      kind == AuthFailureKind.network ||
      kind == AuthFailureKind.timeout ||
      kind == AuthFailureKind.server ||
      kind == AuthFailureKind.unknown;

  static const cancelled = AuthFailure(AuthFailureKind.cancelled, '');

  static const offline = AuthFailure(
    AuthFailureKind.network,
    "Couldn't connect. Check your internet connection and try again.",
  );

  static const timedOut = AuthFailure(
    AuthFailureKind.timeout,
    'That took too long. Try again.',
  );

  static const unexpected = AuthFailure(
    AuthFailureKind.unknown,
    'Something went wrong. Please try again.',
  );

  @override
  String toString() => message;
}

/// Maps transport and server errors onto [AuthFailure].
///
/// The server already returns human-readable copy for OTP and rate-limit
/// cases, so those messages are passed through; everything else is replaced
/// with app copy so internal details never reach the screen.
AuthFailure describeAuthError(Object error) {
  if (error is AuthFailure) return error;

  if (error is TimeoutException) return AuthFailure.timedOut;

  if (error is SocketException || error is HttpException) {
    return AuthFailure.offline;
  }

  if (error is ApiException) {
    final message = error.message.trim();
    switch (error.statusCode) {
      case 400:
        return AuthFailure(
          AuthFailureKind.invalidPhone,
          message.isEmpty ? 'Check the details and try again.' : message,
        );
      case 401:
        final expired = message.toLowerCase().contains('expired');
        return AuthFailure(
          expired ? AuthFailureKind.expiredCode : AuthFailureKind.invalidCode,
          message.isEmpty ? 'That code is not right.' : message,
        );
      case 403:
        return AuthFailure(
          AuthFailureKind.providerRejected,
          message.isEmpty ? 'That is not allowed.' : message,
        );
      case 429:
        final attempts = message.toLowerCase().contains('attempt');
        return AuthFailure(
          attempts
              ? AuthFailureKind.tooManyAttempts
              : AuthFailureKind.rateLimited,
          message.isEmpty ? 'Too many attempts. Try again later.' : message,
        );
      case 502:
      case 503:
        return AuthFailure(
          AuthFailureKind.providerUnavailable,
          message.isEmpty
              ? "We couldn't send that right now. Try again shortly."
              : message,
        );
      default:
        if ((error.statusCode ?? 0) >= 500) {
          return const AuthFailure(
            AuthFailureKind.server,
            'Our servers are having a moment. Try again shortly.',
          );
        }
        return AuthFailure(
          AuthFailureKind.unknown,
          message.isEmpty ? AuthFailure.unexpected.message : message,
        );
    }
  }

  return AuthFailure.unexpected;
}
