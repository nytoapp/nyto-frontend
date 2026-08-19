import 'package:nyto_app/core/api/api_client.dart';

class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  static const timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String dateOfBirth,
    required String phone,
  }) {
    return _api.post(
      '/auth/register',
      body: {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'phone': phone,
      },
    );
  }

  Future<Map<String, dynamic>> requestOtp(String phone) {
    return _api.post('/auth/otp/request', body: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final json = await _api.post(
      '/auth/otp/verify',
      body: {'phone': phone, 'code': code},
    );
    final token = json['token'] as String?;
    if (token != null) await _api.saveToken(token);
    return json;
  }

  Future<Map<String, dynamic>> requestEmailOtp(String email) {
    return _api
        .post('/auth/email/otp/request', body: {'email': email})
        .timeout(timeout);
  }

  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    final json = await _api
        .post('/auth/email/otp/verify', body: {'email': email, 'code': code})
        .timeout(timeout);
    final token = json['token'] as String?;
    if (token != null) await _api.saveToken(token);
    return json;
  }

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final json = await _api
        .post('/auth/google', body: {'idToken': idToken})
        .timeout(timeout);
    final token = json['token'] as String?;
    if (token != null) await _api.saveToken(token);
    return json;
  }

  Future<Map<String, dynamic>> me() =>
      _api.get('/auth/me', auth: true).timeout(timeout);

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) {
    return _api.patch('/auth/me', auth: true, body: body).timeout(timeout);
  }
}

class TablesApi {
  TablesApi(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String filter = 'this_week'}) async {
    final json = await _api.get('/tables', query: {'filter': filter});
    final tables = json['tables'];
    if (tables is! List) return [];
    return tables.cast<Map<String, dynamic>>();
  }
}

class BookingsApi {
  BookingsApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> create({
    required String tableId,
    required String bookingType,
    required int seatsBooked,
  }) {
    return _api.post(
      '/bookings',
      auth: true,
      body: {
        'tableId': tableId,
        'bookingType': bookingType,
        'seatsBooked': seatsBooked,
      },
    );
  }

  Future<Map<String, dynamic>> pay({
    required String bookingId,
    required String method,
  }) {
    return _api.post(
      '/bookings/$bookingId/pay',
      auth: true,
      body: {'method': method},
    );
  }
}

class VerificationApi {
  VerificationApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> submitId({
    required String documentType,
    String documentUrl = 'local://id-upload',
  }) {
    return _api.post(
      '/verification/id',
      auth: true,
      body: {
        'documentType': documentType,
        'documentUrl': documentUrl,
      },
    );
  }

  Future<Map<String, dynamic>> submitSelfie({
    String selfieUrl = 'local://selfie-capture',
  }) {
    return _api.post(
      '/verification/selfie',
      auth: true,
      body: {'selfieUrl': selfieUrl},
    );
  }
}

final authApi = AuthApi(apiClient);
final tablesApi = TablesApi(apiClient);
final bookingsApi = BookingsApi(apiClient);
final verificationApi = VerificationApi(apiClient);
