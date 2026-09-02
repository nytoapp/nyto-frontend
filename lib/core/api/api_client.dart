import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nyto_app/core/auth/token_store.dart';
import 'package:nyto_app/core/config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Raised when the session is gone and the user has to sign in again.
class SessionExpiredException extends ApiException {
  SessionExpiredException() : super('Session expired', statusCode: 401);
}

class ApiClient {
  ApiClient({http.Client? client, TokenStore? tokenStore})
    : _client = client ?? http.Client(),
      _tokens = tokenStore ?? TokenStore();

  final http.Client _client;
  final TokenStore _tokens;

  static const requestTimeout = Duration(seconds: 15);

  /// Serializes refreshes. Refresh tokens rotate server-side, so two parallel
  /// refreshes would make the second look like a stolen token and kill the
  /// session. Every 401 waits on the same in-flight attempt.
  Future<AuthTokens?>? _refreshInFlight;

  Future<AuthTokens?> currentTokens() => _tokens.read();

  Future<bool> hasSession() async => (await _tokens.read()) != null;

  Future<void> saveTokens(AuthTokens tokens) => _tokens.write(tokens);

  Future<void> clearTokens() => _tokens.clear();

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) {
    return _send(
      auth: auth,
      run: (headers) => _client.get(_uri(path, query), headers: headers),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _send(
      auth: auth,
      run: (headers) => _client.post(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _send(
      auth: auth,
      run: (headers) => _client.patch(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? const {}),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path, {bool auth = false}) {
    return _send(
      auth: auth,
      allowEmptyBody: true,
      run: (headers) => _client.delete(_uri(path), headers: headers),
    );
  }

  Future<Map<String, dynamic>> _send({
    required Future<http.Response> Function(Map<String, String> headers) run,
    required bool auth,
    bool allowEmptyBody = false,
    bool isRetry = false,
  }) async {
    final response = await _perform(run, auth: auth);

    // One transparent refresh-and-retry, then give up.
    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _refreshTokens();
      if (refreshed == null) throw SessionExpiredException();
      return _send(
        run: run,
        auth: auth,
        allowEmptyBody: allowEmptyBody,
        isRetry: true,
      );
    }

    if (response.statusCode == 401 && auth) throw SessionExpiredException();

    return _decode(response, allowEmptyBody: allowEmptyBody);
  }

  Future<http.Response> _perform(
    Future<http.Response> Function(Map<String, String> headers) run, {
    required bool auth,
  }) async {
    try {
      return await run(await _headers(auth: auth)).timeout(requestTimeout);
    } on TimeoutException {
      throw ApiException('That took too long. Try again.');
    } on SocketException {
      throw ApiException("Couldn't reach NYTO. Check your connection.");
    } on http.ClientException {
      throw ApiException("Couldn't reach NYTO. Check your connection.");
    }
  }

  Future<AuthTokens?> _refreshTokens() {
    return _refreshInFlight ??= _performRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthTokens?> _performRefresh() async {
    final current = await _tokens.read();
    if (current == null) return null;

    http.Response response;
    try {
      response = await _client
          .post(
            _uri('/auth/refresh'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': current.refreshToken}),
          )
          .timeout(requestTimeout);
    } catch (_) {
      // Offline: keep the tokens so the session survives once connectivity is
      // back. Only an explicit server rejection clears them.
      return null;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _tokens.clear();
      return null;
    }
    if (response.statusCode >= 400) return null;

    try {
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) return null;
      final next = AuthTokens.fromJson(json);
      if (next == null) return null;
      await _tokens.write(next);
      return next;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final tokens = await _tokens.read();
      if (tokens != null) {
        headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    return headers;
  }

  Map<String, dynamic> _decode(
    http.Response res, {
    bool allowEmptyBody = false,
  }) {
    if (res.body.isEmpty) {
      if (allowEmptyBody && res.statusCode < 400) return {'ok': true};
      throw ApiException('Bad server response', statusCode: res.statusCode);
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(res.body);
      json = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (_) {
      throw ApiException('Bad server response', statusCode: res.statusCode);
    }

    if (res.statusCode >= 400) {
      throw ApiException(
        (json['error'] as String?) ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
    return json;
  }
}

final apiClient = ApiClient();
