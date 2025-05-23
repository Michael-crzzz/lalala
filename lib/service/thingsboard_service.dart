// lib/services/thingsboard_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ThingsBoardService {
  static const String baseUrl = 'https://thingsboard.cloud';

  String? _jwtToken;
  String? _deviceId;

  // Login and get JWT token
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwtToken = data['token'];

        // Save token for future use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _jwtToken!);

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Get device ID by name
  Future<String?> getDeviceId(String deviceName) async {
    if (_jwtToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tenant/devices?deviceName=$deviceName'),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _deviceId = data['id']['id'];
        return _deviceId;
      }
      return null;
    } catch (e) {
      print('Device ID fetch error: $e');
      return null;
    }
  }

  // Get latest telemetry data
  Future<Map<String, dynamic>?> getLatestTelemetry(List<String> keys) async {
    if (_jwtToken == null || _deviceId == null) return null;

    try {
      final keysParam = keys.join(',');
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/plugins/telemetry/DEVICE/$_deviceId/values/timeseries?keys=$keysParam',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Telemetry fetch error: $e');
      return null;
    }
  }

  // Send telemetry data (if needed)
  Future<bool> sendTelemetry(
    String deviceToken,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/$deviceToken/telemetry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Send telemetry error: $e');
      return false;
    }
  }

  // Get device attributes
  Future<Map<String, dynamic>?> getAttributes() async {
    if (_jwtToken == null || _deviceId == null) return null;

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/plugins/telemetry/DEVICE/$_deviceId/values/attributes',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Attributes fetch error: $e');
      return null;
    }
  }

  // Check if token is still valid
  Future<bool> isTokenValid() async {
    if (_jwtToken == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/user'),
        headers: {
          'Content-Type': 'application/json',
          'X-Authorization': 'Bearer $_jwtToken',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Load saved token
  Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwt_token');
  }

  // Clear stored token
  Future<void> logout() async {
    _jwtToken = null;
    _deviceId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
