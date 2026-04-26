import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Connects to:
///   POST  /api/report/create  — submit a new road issue report
///   GET   /api/report/all     — fetch all existing reports
///   POST  /api/report/vote    — vote on a report (Still / Fixed)
///
/// Note: the backend methods are currently stubs (empty bodies).
/// The frontend still makes the proper HTTP calls so that everything
/// works automatically once the backend is implemented.
class ReportService {
  static const String _baseUrl = 'http://localhost:8080/api/report';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // -------------------------------------------------------------------------
  // POST /api/report/create
  //
  // Params (multipart/form-data):
  //   image        — MultipartFile  (required by backend signature)
  //   category     — ReportCategory enum value, e.g. "pothole"
  //   description  — String
  //   lat          — double
  //   lon          — double
  //
  // [imageBytes] is optional; an empty placeholder is sent when null so the
  // required `image` request-part is always present.
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> createReport({
    required String category,
    required String description,
    required double lat,
    required double lon,
    List<int>? imageBytes,
  }) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/create'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['category'] = category;
      request.fields['description'] = description;
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();

      // Always include the image field (backend marks it @RequestParam required).
      // An empty placeholder satisfies the parameter presence check.
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes ?? [],
          filename: 'report.jpg',
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Report submitted successfully.'};
      }
      return {
        'success': false,
        'message': 'Failed to submit report (${response.statusCode}).',
      };
    } catch (_) {
      return {'success': false, 'message': 'Could not connect to server.'};
    }
  }

  // -------------------------------------------------------------------------
  // GET /api/report/all
  //
  // Returns a list of report JSON maps. The backend is currently a stub that
  // returns void/empty, so an empty list is returned in that case and the
  // caller falls back to local dummy data.
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> getAllReports() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/all'),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') {
          return {'success': true, 'data': <dynamic>[]};
        }
        final decoded = jsonDecode(body);
        if (decoded is List) {
          return {'success': true, 'data': decoded};
        }
        return {'success': true, 'data': <dynamic>[]};
      }
      return {
        'success': false,
        'message': 'Failed to load reports.',
        'data': null,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not connect to server.',
        'data': null,
      };
    }
  }

  // -------------------------------------------------------------------------
  // POST /api/report/vote
  //
  // Params (query):
  //   reportId  — String
  //   voteType  — VoteType enum value: "Still" | "Fixed"
  // -------------------------------------------------------------------------
  Future<Map<String, dynamic>> voteReport({
    required String reportId,
    required String voteType,
  }) async {
    try {
      final uri =
          Uri.parse('$_baseUrl/vote').replace(queryParameters: {
        'reportId': reportId,
        'voteType': voteType,
      });
      final response = await http.post(uri, headers: await _authHeaders());

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {
        'success': false,
        'message': 'Failed to submit vote (${response.statusCode}).',
      };
    } catch (_) {
      return {'success': false, 'message': 'Could not connect to server.'};
    }
  }
}
