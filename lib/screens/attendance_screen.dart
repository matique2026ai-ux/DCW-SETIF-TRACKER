import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final api = context.read<AuthService>().api;
      final employees = await api.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkIn(Map<String, dynamic> emp) async {
    try {
      final api = context.read<AuthService>().api;
      await api.checkIn(emp['Id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل حضور ${emp['NomAr'] ?? emp['Nom']}'),
            backgroundColor: AppTheme.SuccessColor,
          ),
        );
        _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.DangerColor,
          ),
        );
      }
    }
  }

  Future<void> _checkOut(Map<String, dynamic> emp) async {
    try {
      final api = context.read<AuthService>().api;
      await api.checkOut(emp['Id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تسجيل انصراف ${emp['NomAr'] ?? emp['Nom']}'),
            backgroundColor: AppTheme.WarningColor,
          ),
        );
        _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.DangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: AppTheme.BackgroundColor,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.PrimaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_employees.length} مفتش في المصلحتين',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: AppTheme.TextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppTheme.DangerColor,
                      ),
                      SizedBox(height: 16),
                      Text(_error!, style: TextStyle(fontFamily: 'Tajawal')),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadEmployees();
                        },
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEmployees,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final emp = _employees[index];
                      final name = emp['NomAr'] != null
                          ? '${emp['NomAr']} ${emp['PrenomAr']}'
                          : '${emp['Nom']} ${emp['Prenom']}';
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.PrimaryColor,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.TextPrimary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            (emp['Service'] ?? '') as String,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: AppTheme.TextSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _checkIn(emp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.SuccessColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'حضور',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: () => _checkOut(emp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.WarningColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'انصراف',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
