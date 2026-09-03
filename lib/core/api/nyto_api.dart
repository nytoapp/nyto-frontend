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

  Future<Map<String, dynamic>> listRaw({
    String filter = 'this_week',
    String? city,
    String? area,
  }) {
    final query = <String, String>{'filter': filter};
    final trimmedCity = city?.trim();
    if (trimmedCity != null && trimmedCity.isNotEmpty) {
      query['city'] = trimmedCity;
    }
    final trimmedArea = area?.trim();
    if (trimmedArea != null && trimmedArea.isNotEmpty) {
      query['area'] = trimmedArea;
    }
    return _api.get('/tables', query: query);
  }

  Future<List<Map<String, dynamic>>> list({
    String filter = 'this_week',
    String? city,
    String? area,
  }) async {
    final json = await listRaw(filter: filter, city: city, area: area);
    final tables = json['tables'];
    if (tables is! List) return [];
    return tables.cast<Map<String, dynamic>>();
  }
}

class LocationsApi {
  LocationsApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> launch() => _api.get('/locations/launch');

  Future<Map<String, dynamic>> nearestArea({
    required double lat,
    required double lng,
  }) {
    return _api.post(
      '/locations/nearest-area',
      body: {'lat': lat, 'lng': lng},
    );
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

  Future<List<Map<String, dynamic>>> listMine() async {
    final json = await _api.get('/bookings/me', auth: true);
    final bookings = json['bookings'];
    if (bookings is! List) return [];
    return bookings.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> get(String bookingId) {
    return _api.get('/bookings/$bookingId', auth: true);
  }

  Future<Map<String, dynamic>> cancel(String bookingId) {
    return _api.post('/bookings/$bookingId/cancel', auth: true);
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
final locationsApi = LocationsApi(apiClient);
final bookingsApi = BookingsApi(apiClient);
final verificationApi = VerificationApi(apiClient);
