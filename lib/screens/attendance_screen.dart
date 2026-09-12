import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _employees = [
      {
        'id': 1,
        'name': 'أحمد',
        'first_name': 'بن علي',
        'rank': 'مفتش',
        'department': 'حماية المستهلك',
        'checked_in': false,
      },
      {
        'id': 2,
        'name': 'سارة',
        'first_name': 'بوزيد',
        'rank': 'مفتشة',
        'department': 'حماية المستهلك',
        'checked_in': false,
      },
      {
        'id': 3,
        'name': 'كريم',
        'first_name': 'مراد',
        'rank': 'مفتش',
        'department': 'الممارسات التجارية',
        'checked_in': false,
      },
      {
        'id': 4,
        'name': 'نور',
        'first_name': 'الهدى',
        'rank': 'مفتشة',
        'department': 'حماية المستهلك',
        'checked_in': false,
      },
      {
        'id': 5,
        'name': 'ياسين',
        'first_name': 'عماد',
        'rank': 'مفتش',
        'department': 'الممارسات التجارية',
        'checked_in': false,
      },
    ];

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: AppTheme.BackgroundColor,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.PrimaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'اضغط على حضور لتسجيل حضور المفتش',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: AppTheme.TextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _employees.length,
                itemBuilder: (context, index) {
                  final emp = _employees[index];
                  final isCheckedIn = emp['checked_in'] == true;
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCheckedIn
                            ? AppTheme.SuccessColor
                            : AppTheme.PrimaryColor,
                        child: Text(
                          '${(index + 1)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        '${emp['name']} ${emp['first_name']}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: AppTheme.TextPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      subtitle: Text(
                        '${emp['rank']} - ${emp['department']}',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppTheme.TextSecondary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            emp['checked_in'] = !emp['checked_in'];
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isCheckedIn
                                    ? 'تم تسجيل انصراف ${emp['name']}'
                                    : 'تم تسجيل حضور ${emp['name']}',
                              ),
                              backgroundColor: isCheckedIn
                                  ? AppTheme.WarningColor
                                  : AppTheme.SuccessColor,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCheckedIn
                              ? AppTheme.WarningColor
                              : AppTheme.SuccessColor,
                          foregroundColor: AppTheme.SidebarColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isCheckedIn ? 'انصراف' : 'حضور',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
