import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/bottom_nav.dart';
import 'dashboard_screen.dart';
import 'attendance_screen.dart';
import 'program_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    AttendanceScreen(),
    ProgramScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: _getTitle(_currentIndex)),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  String _getTitle(int index) {
    List<String> titles = [
      'لوحة القيادة',
      'الحضور والانصراف',
      'البرنامج',
      'التقارير',
      'الملف الشخصي',
    ];
    return titles[index];
  }
}
