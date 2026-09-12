import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/stat_card.dart';
import '../../utils/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'مساء الخير';
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'director':
        return 'مدير';
      case 'head_of_department':
        return 'رئيس المصلحة';
      case 'bureau':
        return 'مكتب المستخدمين';
      case 'inspector':
        return 'مفتش';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final api = context.read<AuthService>().api;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.PrimaryColor,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              color: AppTheme.TextSecondary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            'مديرية التجارة — ولاية سطيف',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.TextPrimary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.AccentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRoleName(user?.role ?? ''),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.AccentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'الإحصائيات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.TextPrimary,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: api.getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final stats = snapshot.data ?? {};
                final total = (stats['totalInspectors'] ?? 0) as int;
                final present = (stats['presentToday'] ?? 0) as int;
                final absent = (stats['absentToday'] ?? 0) as int;
                final programs = (stats['activePrograms'] ?? 0) as int;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'المفتشين',
                            value: total,
                            icon: Icons.groups,
                            iconColor: AppTheme.PrimaryColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'حاضرون اليوم',
                            value: present,
                            icon: Icons.check_circle,
                            iconColor: AppTheme.SuccessColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'غائبين',
                            value: absent,
                            icon: Icons.cancel,
                            iconColor: AppTheme.DangerColor,
                            backgroundColor: AppTheme.BackgroundColor,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'برامج نشطة',
                            value: programs,
                            icon: Icons.calendar_month,
                            iconColor: AppTheme.AccentColor,
                          ),
                        ),
                      ],
                    ),
                    if (total > 0) ...[
                      SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نسبة الحضور اليوم',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  color: AppTheme.TextSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: present / total,
                                        minHeight: 12,
                                        backgroundColor:
                                            AppTheme.DangerColor.withValues(
                                              alpha: 0.15,
                                            ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              present / total > 0.7
                                                  ? AppTheme.SuccessColor
                                                  : present / total > 0.4
                                                  ? AppTheme.WarningColor
                                                  : AppTheme.DangerColor,
                                            ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '${(present / total * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.TextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              'آخر النشاطات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.TextPrimary,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: api.getRecentActivity(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final activities = snapshot.data ?? [];
                if (activities.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: AppTheme.BorderColor,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'لا توجد نشاطات اليوم',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                color: AppTheme.TextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      children: activities.take(5).map((a) {
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.SuccessColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.login,
                              color: AppTheme.SuccessColor,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            (a['employeeName'] ?? '') as String,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.TextPrimary,
                            ),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: a['checkIn'] != null
                                  ? AppTheme.SuccessColor.withValues(alpha: 0.1)
                                  : AppTheme.DangerColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a['checkIn'] != null ? 'حاضر' : 'غائب',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: a['checkIn'] != null
                                    ? AppTheme.SuccessColor
                                    : AppTheme.DangerColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
