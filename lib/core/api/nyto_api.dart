import 'package:nyto_app/core/api/api_client.dart';

/// Profile endpoints for the signed-in user.
///
/// Sign-in and session handling live in `AuthRepository` — this class never
/// issues or stores tokens.
class AuthApi {
  AuthApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> me() => _api.get('/auth/me', auth: true);

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) {
    return _api.patch('/auth/me', auth: true, body: body);
  }

  Future<Map<String, dynamic>> deleteMe() {
    return _api.delete('/auth/me', auth: true);
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
      body: {'documentType': documentType, 'documentUrl': documentUrl},
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
