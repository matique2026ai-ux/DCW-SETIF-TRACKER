import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../screens/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  String _getDepartmentName(String role) {
    switch (role) {
      case 'director':
        return 'مديرية التجارة';
      case 'head_of_department':
      case 'bureau':
      case 'inspector':
        return 'حماية المستهلك وقمع الغش';
      default:
        return 'مديرية التجارة لولاية سطيف';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.PrimaryColor,
                    child: Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user?.username ?? 'المستخدم',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.TextPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getRoleName(user?.role ?? ''),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: AppTheme.AccentColor,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _profileInfo('الرتبة', _getRoleName(user?.role ?? '')),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppTheme.BorderColor,
                      ),
                      _profileInfo(
                        'القسم',
                        _getDepartmentName(user?.role ?? ''),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          _settingsTile(
            icon: Icons.notifications,
            title: 'الإشعارات',
            onTap: () {},
          ),
          _settingsTile(
            icon: Icons.language,
            title: 'اللغة',
            subtitle: 'العربية',
            onTap: () {},
          ),
          _settingsTile(
            icon: Icons.security,
            title: 'تغيير كلمة المرور',
            onTap: () {},
          ),
          _settingsTile(
            icon: Icons.info,
            title: 'حول التطبيق',
            subtitle: 'v${Constants.appVersion}',
            onTap: () {},
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.DangerColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: AppTheme.TextSecondary,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.TextPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.PrimaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
            color: AppTheme.TextPrimary,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppTheme.TextSecondary,
                ),
                textDirection: TextDirection.rtl,
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.TextSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
