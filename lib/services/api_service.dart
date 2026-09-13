import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    const custom = String.fromEnvironment('API_URL', defaultValue: '');
    if (custom.isNotEmpty) return '$custom/api';
    return 'https://drh-setif-api.onrender.com/api';
  }

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

  void setToken(String? token) {
    _token = token;
  }

  Future<List<Map<String, dynamic>>> getEmployees({
    bool activeOnly = false,
    bool all = false,
    String? department,
    String? status,
    bool? brigadeOnly,
  }) async {
    final params = <String, String>{};
    if (activeOnly) params['active'] = '1';
    if (all) params['all'] = 'true';
    if (department != null) params['department'] = department;
    if (status != null) params['status'] = status;
    if (brigadeOnly == true) params['brigade'] = 'true';

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

  Future<List<String>> getAllDepartments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employees/all-departments'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<String>();
    }
    throw Exception('خطأ في جلب المصالح');
  }

  Future<void> updateEmployeeAdminStatus(
    int employeeId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/employees/$employeeId/admin-status'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'خطأ في تحديث البيانات الإدارية');
    }
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

  Future<void> checkIn(
    int employeeId, {
    double? latitude,
    double? longitude,
    String? photo,
    String? location,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/checkin'),
      headers: _headers,
      body: jsonEncode({
        'employeeId': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'photo': photo,
        'location': location,
        'notes': notes,
      }),
    );
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في تسجيل الحضور');
    }
  }

  Future<void> checkOut(
    int employeeId, {
    double? latitude,
    double? longitude,
    String? location,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/checkout'),
      headers: _headers,
      body: jsonEncode({
        'employeeId': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في تسجيل الانصراف');
    }
  }

  Future<void> cancelCheckOut(int employeeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/cancel-checkout'),
      headers: _headers,
      body: jsonEncode({'employeeId': employeeId}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في استئناف الدوام');
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

  Future<Map<String, dynamic>?> getTodayAttendance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/today-self'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPrograms({String? service, String? type}) async {
    final params = <String, String>{};
    if (service != null) params['service'] = service;
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$baseUrl/programs').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب البرامج');
  }

  Future<void> createProgram({
    required String title,
    String? description,
    String? type,
    String? weekDate,
    String? targetArea,
    String? targetType,
    String? focusPoints,
    String? serviceName,
    int? createdBy,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/programs'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'type': type ?? 'daily',
        'weekDate': weekDate,
        'targetArea': targetArea,
        'targetType': targetType,
        'focusPoints': focusPoints,
        'serviceName': serviceName,
        'createdBy': createdBy,
      }),
    );
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في إنشاء أمر المهمة');
    }
  }

  Future<List<Map<String, dynamic>>> getMapData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/map-data'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب بيانات الخريطة');
  }

  Future<List<Map<String, dynamic>>> getTodayVisits([int? employeeId]) async {
    final url = employeeId != null
        ? '$baseUrl/visits/today?employeeId=$employeeId'
        : '$baseUrl/visits/today';
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> recordVisit({
    required int employeeId,
    required double latitude,
    required double longitude,
    String? photo,
    String? shopName,
    String? shopType,
    String? notes,
    double? accuracy,
    String? locationName,
    int? assignmentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/visits'),
      headers: _headers,
      body: jsonEncode({
        'employeeId': employeeId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'locationName': locationName,
        'shopName': shopName,
        'shopType': shopType,
        'photo': photo,
        'assignmentId': assignmentId,
        'notes': notes,
      }),
    );
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في تسجيل الزيارة');
    }
  }

  Future<List<Map<String, dynamic>>> getDeductions({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;

    final uri = Uri.parse(
      '$baseUrl/deductions',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب طلبات الخصم');
  }

  Future<void> requestDeduction({
    required int employeeId,
    required int requestedBy,
    required String reason,
    int? daysCount,
    double? amount,
    String? evidence,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deductions'),
      headers: _headers,
      body: jsonEncode({
        'employeeId': employeeId,
        'requestedBy': requestedBy,
        'reason': reason,
        'daysCount': daysCount,
        'amount': amount,
        'evidence': evidence,
      }),
    );
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في إنشاء طلب الخصم');
    }
  }

  Future<void> approveDeduction({
    required int id,
    required int approvedBy,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deductions/$id/approve'),
      headers: _headers,
      body: jsonEncode({'approvedBy': approvedBy}),
    );
    if (response.statusCode != 200) {
      throw Exception('خطأ في الموافقة على الخصم');
    }
  }

  Future<void> rejectDeduction({
    required int id,
    required int approvedBy,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/deductions/$id/reject'),
      headers: _headers,
      body: jsonEncode({'approvedBy': approvedBy}),
    );
    if (response.statusCode != 200) {
      throw Exception('خطأ في رفض طلب الخصم');
    }
  }

  // Justifications API
  Future<List<Map<String, dynamic>>> getJustifications({String? status, int? employeeId}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (employeeId != null) params['employeeId'] = employeeId.toString();

    final uri = Uri.parse('$baseUrl/justifications').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('خطأ في جلب مبررات الغياب');
  }

  Future<void> submitJustification(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/justifications'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'خطأ في إرسال التبرير');
    }
  }

  Future<void> updateJustificationStatus(int id, String status, {String? reviewNotes}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/justifications/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status, 'reviewNotes': reviewNotes}),
    );
    if (response.statusCode != 200) {
      throw Exception('خطأ في تحديث حالة التبرير');
    }
  }
}
