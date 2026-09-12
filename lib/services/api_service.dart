import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['token'] as String;
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في تسجيل الدخول');
    }
  }

  void logout() {
    _token = null;
  }

  Future<List<Map<String, dynamic>>> getEmployees({
    String? department,
    bool activeOnly = true,
  }) async {
    final params = <String, String>{};
    if (activeOnly) params['active'] = '1';
    if (department != null) params['department'] = department;

    final uri = Uri.parse(
      '$baseUrl/employees',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب الموظفين');
  }

  Future<List<String>> getDepartments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employees/departments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<String>();
    }
    throw Exception('خطأ في جلب الأقسام');
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data as Map);
    }
    throw Exception('خطأ في جلب الإحصائيات');
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/recent-activity'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب النشاطات');
  }

  Future<void> checkIn(int employeeId, {String? location}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/checkin'),
      headers: _headers,
      body: jsonEncode({'employeeId': employeeId, 'location': location}),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في تسجيل الحضور');
    }
  }

  Future<void> checkOut(int employeeId, {String? location}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/checkout'),
      headers: _headers,
      body: jsonEncode({'employeeId': employeeId, 'location': location}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في تسجيل الانصراف');
    }
  }

  Future<List<Map<String, dynamic>>> getAttendance({
    String? date,
    int? employeeId,
  }) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (employeeId != null) params['employeeId'] = employeeId.toString();

    final uri = Uri.parse(
      '$baseUrl/attendance',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب بيانات الحضور');
  }

  Future<List<Map<String, dynamic>>> getPrograms() async {
    final response = await http.get(
      Uri.parse('$baseUrl/programs'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب البرامج');
  }
}
