import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class RoutingService {
  static const String _baseUrl = 'http://localhost:8080/api/routing';
  final AuthService _authService = AuthService();

  static const Map<String, String> _categoryMap = {
    'Restaurant': 'RESTAURANT',
    'Gas station': 'FUEL',
    'Park': 'PARK',
    'Parking': 'PARKING',
    'Supermarket': 'SUPERMARKET',
    'Mosque': 'MOSQUE',
  };

  String? toCategoryEnum(String label) => _categoryMap[label];

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns a list of H3PlaceWrapper objects as raw JSON maps.
  /// Each map has: { "h3Index": int, "place": { "name": str, "category": str,
  ///   "center": {"lat": double, "lon": double}, "points": [...] } }
  Future<Map<String, dynamic>> getNearbyPlaces(
    double lat,
    double lon,
    String categoryLabel,
  ) async {
    final categoryEnum = toCategoryEnum(categoryLabel);
    if (categoryEnum == null) {
      return {'success': false, 'message': 'Unknown category: $categoryLabel', 'data': null};
    }
    try {
      final uri = Uri.parse('$_baseUrl/places').replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'category': categoryEnum,
      });
      final response = await http.get(uri, headers: await _authHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Failed to load nearby places.', 'data': null};
    } catch (_) {
      return {'success': false, 'message': 'Could not connect to server.', 'data': null};
    }
  }

  /// Returns a RoutingPath as raw JSON:
  /// { "pathNodes": [{"id": int, "latitude": double, "longitude": double, "order": int}],
  ///   "distance": double }
  Future<Map<String, dynamic>> getRoute(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/route').replace(queryParameters: {
        'lat1': lat1.toString(),
        'lon1': lon1.toString(),
        'lat2': lat2.toString(),
        'lon2': lon2.toString(),
      });
      final response = await http.post(uri, headers: await _authHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Failed to calculate route.', 'data': null};
    } catch (_) {
      return {'success': false, 'message': 'Could not connect to server.', 'data': null};
    }
  }
}
