import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر نوع التقرير',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.TextPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 16),
          _reportCard(
            context: context,
            icon: Icons.calendar_today,
            title: 'التقرير اليومي',
            subtitle: 'حضور وانصراف كل مفتش اليوم',
            color: AppTheme.PrimaryColor,
          ),
          SizedBox(height: 12),
          _reportCard(
            context: context,
            icon: Icons.calendar_view_week,
            title: 'التقرير الأسبوعي',
            subtitle: 'ملخص برنامج الأسبوع',
            color: AppTheme.AccentColor,
          ),
          SizedBox(height: 12),
          _reportCard(
            context: context,
            icon: Icons.calendar_month,
            title: 'التقرير الشهري',
            subtitle: 'إحصائيات شهرية كاملة',
            color: AppTheme.DangerColor,
          ),
          SizedBox(height: 12),
          _reportCard(
            context: context,
            icon: Icons.account_balance,
            title: 'تقرير الخصومات',
            subtitle: 'قرارات الخصم المعتمدة',
            color: AppTheme.WarningColor,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('جاري تحميل التقرير...'),
                backgroundColor: AppTheme.SuccessColor,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.PrimaryColor,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'تصدير التقارير',
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

  Widget _reportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color.fromARGB(
              26,
              color.r.toInt(),
              color.g.toInt(),
              color.b.toInt(),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: AppTheme.TextPrimary,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            color: AppTheme.TextSecondary,
          ),
          textDirection: TextDirection.rtl,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.TextSecondary,
        ),
      ),
    );
  }
}
