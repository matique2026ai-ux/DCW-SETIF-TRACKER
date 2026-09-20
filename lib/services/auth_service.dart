import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drh_setif_tracker/models/user.dart';
import 'package:drh_setif_tracker/models/employee.dart';
import 'package:drh_setif_tracker/services/api_service.dart';

class AuthService extends ChangeNotifier {
  static const String _authUserKey = 'auth_cached_user';
  static const String _authTokenKey = 'auth_cached_token';

  final ApiService _api = ApiService();
  User? _currentUser;
  Employee? _currentEmployee;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  ApiService get api => _api;

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_authUserKey);
      final token = prefs.getString(_authTokenKey);
      if (userStr != null && token != null) {
        final userData = jsonDecode(userStr);
        _currentUser = User(
          id: userData['id'] as int?,
          username: (userData['username'] ?? '') as String,
          passwordHash: '',
          role: (userData['role'] ?? 'inspector') as String,
          employeeId: userData['employeeId'] as int?,
          fullName: (userData['fullName'] ?? userData['full_name'] ?? '') as String?,
        );
        _api.setToken(token);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static const String _deviceIdKey = 'device_unique_security_id';

  static Future<String> getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString(_deviceIdKey);
      if (id == null || id.isEmpty) {
        id = 'DCW-DEV-${DateTime.now().millisecondsSinceEpoch}-${1000 + (DateTime.now().microsecond % 9000)}';
        await prefs.setString(_deviceIdKey, id);
      }
      return id;
    } catch (_) {
      return 'DCW-DEV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> login(String username, String password, {String? adminOverrideCode, String? masterPin}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final devId = await getOrCreateDeviceId();
      final result = await _api.login(
        username,
        password,
        deviceId: devId,
        deviceName: 'هاتف معتمد',
        adminOverrideCode: adminOverrideCode,
        masterPin: masterPin,
        isWeb: kIsWeb,
      );
      final userData = result['user'];
      final token = result['token'] as String;

      _currentUser = User(
        id: userData['id'] as int?,
        username: (userData['username'] ?? '') as String,
        passwordHash: '',
        role: (userData['role'] ?? 'inspector') as String,
        employeeId: userData['employeeId'] as int?,
        fullName:
            (userData['fullName'] ?? userData['full_name'] ?? '') as String?,
        deviceId: userData['deviceId'] as String? ?? devId,
      );

      // Save for offline session persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authUserKey, jsonEncode(userData));
      await prefs.setString(_authTokenKey, token);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _api.logout();
    _currentUser = null;
    _currentEmployee = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authUserKey);
    await prefs.remove(_authTokenKey);
    notifyListeners();
  }

  void setCurrentEmployee(Employee employee) {
    _currentEmployee = employee;
    notifyListeners();
  }
}
