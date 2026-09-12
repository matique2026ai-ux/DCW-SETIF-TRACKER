import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';

class DirectorReportsTab extends StatefulWidget {
  const DirectorReportsTab({super.key});

  @override
  State<DirectorReportsTab> createState() => _DirectorReportsTabState();
}

class _DirectorReportsTabState extends State<DirectorReportsTab> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthService>().api;
      final emp = await api.getEmployees();
      final att = await api.getAttendance();
      if (mounted)
        setState(() {
          _employees = emp;
          _attendance = att;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_isLoading)
      return Center(
        child: CircularProgressIndicator(color: AppTheme.AccentColor),
      );

    final checkedInIds = _attendance.map((a) => a['EmployeeId']).toSet();
    final present = _employees
        .where((e) => checkedInIds.contains(e['Id']))
        .toList();
    final absent = _employees
        .where((e) => !checkedInIds.contains(e['Id']))
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat(
                loc.totalEmployees,
                _employees.length,
                AppTheme.AccentColor,
                Icons.people,
              ),
              SizedBox(width: 10),
              _stat(
                loc.presentToday,
                present.length,
                AppTheme.SuccessColor,
                Icons.check_circle,
              ),
              SizedBox(width: 10),
              _stat(
                loc.absentToday,
                absent.length,
                AppTheme.DangerColor,
                Icons.cancel,
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            loc.absentToday,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          absent.isEmpty
              ? Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.CardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.BorderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppTheme.SuccessColor,
                        ),
                        SizedBox(height: 12),
                        Text(
                          loc.noAbsence,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.SuccessColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: absent.asMap().entries.map((entry) {
                    final e = entry.value;
                    final name = e['NomAr'] != null
                        ? '${e['NomAr']} ${e['PrenomAr']}'
                        : '${e['Nom']} ${e['Prenom']}';
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.CardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.BorderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.DangerColor.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_off,
                              color: AppTheme.DangerColor,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${e['Service'] ?? ''}',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.warning_amber,
                            color: AppTheme.WarningColor,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: AppTheme.TextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
