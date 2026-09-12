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
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                StatCard(
                  title: 'إجمالي المفتشين',
                  value: 8,
                  icon: Icons.people,
                  iconColor: AppTheme.PrimaryColor,
                ),
                StatCard(
                  title: 'حاضرون اليوم',
                  value: 5,
                  icon: Icons.check_circle,
                  iconColor: AppTheme.SuccessColor,
                ),
                StatCard(
                  title: 'غائبين اليوم',
                  value: 3,
                  icon: Icons.cancel,
                  iconColor: AppTheme.DangerColor,
                  backgroundColor: AppTheme.BackgroundColor,
                ),
                StatCard(
                  title: 'برامج نشطة',
                  value: 2,
                  icon: Icons.list_alt,
                  iconColor: AppTheme.AccentColor,
                ),
              ],
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
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildActivityItem(
                      icon: Icons.login,
                      text: 'تفعيل النظام بنجاح',
                      time: 'الآن',
                      color: AppTheme.SuccessColor,
                    ),
                    Divider(height: 24),
                    _buildActivityItem(
                      icon: Icons.info,
                      text: 'مرحباً بك في نظام تتبع المفتشين',
                      time: 'اليوم',
                      color: AppTheme.AccentColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String text,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.fromARGB(
            26,
            color.r.toInt(),
            color.g.toInt(),
            color.b.toInt(),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          color: AppTheme.TextPrimary,
        ),
        textDirection: TextDirection.rtl,
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12,
          color: AppTheme.TextSecondary,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
