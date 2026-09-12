import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';

class SyncService {
  final String _baseUrl = 'http://192.168.1.100:8080/api';

  Future<bool> isConnected() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncAttendance(List<Map<String, dynamic>> data) async {
    if (!await isConnected()) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/attendance/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
    } catch (e) {
      // Retry later
    }
  }

  Future<void> syncPrograms(List<Map<String, dynamic>> data) async {
    if (!await isConnected()) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/programs/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
    } catch (e) {
      // Retry later
    }
  }
}
