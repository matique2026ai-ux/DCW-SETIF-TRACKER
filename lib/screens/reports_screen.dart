import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = true;
  String _selectedReport = 'daily';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = context.read<AuthService>().api;
      final employees = await api.getEmployees();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final attendance = await api.getAttendance(date: today);
      if (mounted) {
        setState(() {
          _employees = employees;
          _attendance = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          color: AppTheme.BackgroundColor,
          child: Row(
            children: [
              Expanded(child: _reportTab('غياب اليوم', 'daily', Icons.cancel)),
              SizedBox(width: 8),
              Expanded(
                child: _reportTab(
                  'ملخص الأقسام',
                  'departments',
                  Icons.business,
                ),
              ),
              SizedBox(width: 8),
              Expanded(child: _reportTab('حسب الرتبة', 'grades', Icons.star)),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _selectedReport == 'daily'
              ? _buildDailyReport()
              : _selectedReport == 'departments'
              ? _buildDepartmentReport()
              : _buildGradeReport(),
        ),
      ],
    );
  }

  Widget _reportTab(String label, String type, IconData icon) {
    final isSelected = _selectedReport == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedReport = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.PrimaryColor : AppTheme.CardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.PrimaryColor : AppTheme.BorderColor,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.TextSecondary,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.TextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReport() {
    final checkedInIds = _attendance.map((a) => a['EmployeeId']).toSet();
    final absentees = _employees
        .where((e) => !checkedInIds.contains(e['Id']))
        .toList();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _reportStat('الإجمالي', _employees.length, AppTheme.PrimaryColor),
              SizedBox(width: 12),
              _reportStat('حاضرون', checkedInIds.length, AppTheme.SuccessColor),
              SizedBox(width: 12),
              _reportStat('غائبين', absentees.length, AppTheme.DangerColor),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.TextSecondary),
              SizedBox(width: 6),
              Text(
                'قائمة الغائبين عن العمل اليوم',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: AppTheme.TextSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: absentees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 48,
                        color: AppTheme.SuccessColor,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'جميع المفتشين حاضرون!',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.SuccessColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: absentees.length,
                  itemBuilder: (context, index) {
                    final emp = absentees[index];
                    final name = emp['NomAr'] != null
                        ? '${emp['NomAr']} ${emp['PrenomAr']}'
                        : '${emp['Nom']} ${emp['Prenom']}';
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.DangerColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.DangerColor,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          (emp['Service'] ?? '') as String,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            color: AppTheme.TextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDepartmentReport() {
    final Map<String, int> deptCount = {};
    for (final emp in _employees) {
      final dept = (emp['Service'] ?? 'غير محدد') as String;
      deptCount[dept] = (deptCount[dept] ?? 0) + 1;
    }
    final sortedDepts = deptCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedDepts.length,
      itemBuilder: (context, index) {
        final entry = sortedDepts[index];
        final percent = entry.value / _employees.length;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.TextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.PrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.value} مفتش',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.PrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: AppTheme.BorderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent > 0.3
                          ? AppTheme.PrimaryColor
                          : AppTheme.AccentColor,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}% من الإجمالي',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppTheme.TextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradeReport() {
    final Map<String, int> gradeCount = {};
    for (final emp in _employees) {
      final grade = emp['Grade']?.toString() ?? 'غير محدد';
      gradeCount[grade] = (gradeCount[grade] ?? 0) + 1;
    }
    final sortedGrades = gradeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sortedGrades.length,
      itemBuilder: (context, index) {
        final entry = sortedGrades[index];
        final percent = entry.value / _employees.length;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الرتبة ${entry.key}',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.TextPrimary,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.AccentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.value} مفتش',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.AccentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: AppTheme.BorderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.AccentColor,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${(percent * 100).toStringAsFixed(1)}% من الإجمالي',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppTheme.TextSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
