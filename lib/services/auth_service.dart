import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 10.0.2.2 = localhost from Android emulator; change to your machine's IP for a real device
  static const String _baseUrl = 'http://10.0.2.2:8080/api/auth';
  static const String _tokenKey = 'auth_token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token'] as String);
        return {'success': true, 'message': 'Logged in successfully.', 'data': data};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Incorrect email or password.',
        'data': null,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not connect to server. Please try again.',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phoneNumber,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'phoneNumber': phoneNumber.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Account created! Please sign in.', 'data': data};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed.',
        'data': null,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Could not connect to server. Please try again.',
        'data': null,
      };
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
