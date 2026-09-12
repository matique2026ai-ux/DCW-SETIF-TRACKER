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
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.AccentColor,
                  child: Icon(Icons.person, color: AppTheme.SidebarColor),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: AppTheme.TextSecondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    Text(
                      _getRoleName(user?.role ?? ''),
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.TextPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'الإحصائيات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.TextPrimary,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: api.getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data ?? {};
                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    StatCard(
                      title: 'إجمالي المفتشين',
                      value: stats['totalInspectors'] ?? 0,
                      icon: Icons.people,
                      iconColor: AppTheme.PrimaryColor,
                    ),
                    StatCard(
                      title: 'حاضرون اليوم',
                      value: stats['presentToday'] ?? 0,
                      icon: Icons.check_circle,
                      iconColor: AppTheme.SuccessColor,
                    ),
                    StatCard(
                      title: 'غائبين اليوم',
                      value: stats['absentToday'] ?? 0,
                      icon: Icons.cancel,
                      iconColor: AppTheme.DangerColor,
                      backgroundColor: AppTheme.BackgroundColor,
                    ),
                    StatCard(
                      title: 'برامج نشطة',
                      value: stats['activePrograms'] ?? 0,
                      icon: Icons.list_alt,
                      iconColor: AppTheme.AccentColor,
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              'آخر النشاطات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.TextPrimary,
              ),
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: api.getRecentActivity(),
              builder: (context, snapshot) {
                final activities = snapshot.data ?? [];
                if (activities.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'لا توجد نشاطات بعد',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.TextSecondary,
                          ),
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
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: activities.take(5).map((a) {
                        return Column(
                          children: [
                            ListTile(
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
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                a['employeeName'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  color: AppTheme.TextPrimary,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              trailing: Text(
                                a['checkIn'] != null ? 'حاضر' : 'غائب',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: a['checkIn'] != null
                                      ? AppTheme.SuccessColor
                                      : AppTheme.DangerColor,
                                ),
                              ),
                            ),
                            if (activities.indexOf(a) < activities.length - 1)
                              Divider(height: 1),
                          ],
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
