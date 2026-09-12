import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  static const List<Map<String, dynamic>> _items = [
    {'icon': Icons.dashboard, 'label': 'لوحة القيادة'},
    {'icon': Icons.check_circle, 'label': 'الحضور'},
    {'icon': Icons.list_alt, 'label': 'البرنامج'},
    {'icon': Icons.report, 'label': 'التقارير'},
    {'icon': Icons.person, 'label': 'الملف'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.CardColor,
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.CardColor,
        selectedItemColor: AppTheme.PrimaryColor,
        unselectedItemColor: AppTheme.TextSecondary,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 11),
        items: _items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item['icon'] as IconData, size: 24),
                label: item['label'] as String,
              ),
            )
            .toList(),
      ),
    );
  }
}
