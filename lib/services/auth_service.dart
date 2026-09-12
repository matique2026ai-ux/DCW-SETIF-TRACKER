import 'package:flutter/material.dart';
import 'package:drh_setif_tracker/models/user.dart';
import 'package:drh_setif_tracker/models/employee.dart';
import 'package:drh_setif_tracker/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  User? _currentUser;
  Employee? _currentEmployee;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  ApiService get api => _api;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _api.login(username, password);
      final userData = result['user'];

      _currentUser = User(
        id: userData['id'] as int?,
        username: (userData['username'] ?? '') as String,
        passwordHash: '',
        role: (userData['role'] ?? 'inspector') as String,
        employeeId: userData['employeeId'] as int?,
        fullName:
            (userData['fullName'] ?? userData['full_name'] ?? '') as String?,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void logout() {
    _api.logout();
    _currentUser = null;
    _currentEmployee = null;
    notifyListeners();
  }

  void setCurrentEmployee(Employee employee) {
    _currentEmployee = employee;
    notifyListeners();
  }
}
