import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/employee.dart';
import '../../utils/constants.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  Employee? _currentEmployee;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  Employee? get currentEmployee => _currentEmployee;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  static final Map<String, Map<String, String>> _users = {
    'admin': {'username': 'admin', 'password': 'admin123', 'role': 'director'},
    'chef': {
      'username': 'chef',
      'password': 'chef123',
      'role': 'head_of_department',
    },
    'agent': {'username': 'agent', 'password': 'agent123', 'role': 'inspector'},
  };

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = _users[username];
      if (userData != null && userData['password'] == password) {
        _currentUser = User(
          id: 1,
          username: userData['username']!,
          passwordHash: userData['password']!,
          role: userData['role']!,
          employeeId: 1,
        );
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        notifyListeners();
        throw Exception('خطأ في اسم المستخدم أو كلمة المرور');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void logout() {
    _currentUser = null;
    _currentEmployee = null;
    notifyListeners();
  }

  void setCurrentEmployee(Employee employee) {
    _currentEmployee = employee;
    notifyListeners();
  }
}
