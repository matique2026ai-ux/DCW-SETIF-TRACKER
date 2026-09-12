import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';

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
      if (mounted) {
        setState(() {
          _employees = emp;
          _attendance = att;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.AccentColor),
      );
    }

    final checkedInIds = _attendance.map((a) => a['EmployeeId']).toSet();
    final present = _employees
        .where((e) => checkedInIds.contains(e['Id']))
        .toList();
    final absent = _employees
        .where((e) => !checkedInIds.contains(e['Id']))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 10),
              _stat(
                loc.presentToday,
                present.length,
                AppTheme.SuccessColor,
                Icons.check_circle,
              ),
              const SizedBox(width: 10),
              _stat(
                loc.absentToday,
                absent.length,
                AppTheme.DangerColor,
                Icons.cancel,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            loc.absentToday,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          absent.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
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
                        const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppTheme.SuccessColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.noAbsence,
                          style: const TextStyle(
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
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
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
                            child: const Icon(
                              Icons.person_off,
                              color: AppTheme.DangerColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${e['Service'] ?? ''}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
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
