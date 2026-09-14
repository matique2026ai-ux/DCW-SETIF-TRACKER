import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:drh_setif_tracker/utils/theme.dart';

class QRCodeScreen extends StatelessWidget {
  final String data;
  final String title;
  final String subtitle;
  final Map<String, dynamic>? badgeDetails;

  const QRCodeScreen({
    super.key,
    required this.data,
    required this.title,
    this.subtitle = '',
    this.badgeDetails,
  });

  @override
  Widget build(BuildContext context) {
    final details = badgeDetails;

    return Scaffold(
      backgroundColor: AppTheme.BackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1035),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.AccentColor.withValues(alpha: 0.35),
                      blurRadius: 25,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  errorStateBuilder: (cxt, err) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'تعذر عرض رمز الاستجابة السريعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.DangerColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Official Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.CardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.AccentColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: AppTheme.AccentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.TextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.BackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (details != null && details['name'] != null) ...[
                            _buildInfoRow('الاسم واللقب:', details['name'].toString()),
                            if (details['service'] != null && details['service'].toString().isNotEmpty)
                              _buildInfoRow('المصلحة:', details['service'].toString()),
                            if (details['dateTime'] != null)
                              _buildInfoRow('التوقيت:', details['dateTime'].toString()),
                            _buildInfoRow('الوضعية:', 'معتمد بنظام التتبع الميداني الرسمي ✅', valueColor: AppTheme.SuccessColor),
                          ] else ...[
                            Text(
                              data,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                color: AppTheme.TextPrimary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: AppTheme.AccentColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'امسح الرمز بكاميرا الهاتف لقراءة بيانات الهوية مباشرة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: AppTheme.AccentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppTheme.TextPrimary,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              color: AppTheme.TextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required Map<String, dynamic> record,
    required String title,
  }) {
    final String type = (record['type'] ?? 'badge').toString();
    final String empName = (record['employeeName'] ?? record['employee'] ?? 'مفتش').toString();
    final String service = (record['service'] ?? 'مديرية التجارة الداخلية وضبط السوق — سطيف').toString();
    final String date = (record['date'] ?? DateTime.now().toString().split(' ')[0]).toString();
    final String time = (record['time'] ?? record['checkInTime'] ?? DateTime.now().toString().substring(11, 16)).toString();

    // Human-readable official Arabic badge text
    final String qrText = type == 'checkout'
        ? '''🏛️ الجمهورية الجزائرية الديمقراطية الشعبية
وزارة التجارة الداخلية وضبط السوق الوطنية
مديرية التجارة لولاية سطيف
----------------------------------------
إثبات الانصراف الميداني الرسمي
• الاسم واللقب: $empName
• المصلحة: $service
• توثيق الانصراف: $date | الساعة: $time
• الحالة: تم تسجيل الانصراف الميداني النظامي بنجاح ✅
• رمز التوثيق: DCW-SETIF-CHECKOUT
----------------------------------------
نظام تتبع المفتشين والرقابة الميدانية'''
        : '''🏛️ الجمهورية الجزائرية الديمقراطية الشعبية
وزارة التجارة الداخلية وضبط السوق الوطنية
مديرية التجارة لولاية سطيف
----------------------------------------
بطاقة إثبات الهوية الرقمية للمفتش الميداني
• الاسم واللقب: $empName
• المصلحة: $service
• تاريخ الحضور: $date | الساعة: $time
• الوضعية: موظف رسمي معتمد بنظام التتبع الميداني ✅
• رمز الاعتماد: DCW-SETIF-VERIFIED
----------------------------------------
نظام تتبع المفتشين والرقابة الميدانية''';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRCodeScreen(
          data: qrText,
          title: title,
          subtitle: '$empName • $date',
          badgeDetails: {
            'name': empName,
            'service': service,
            'dateTime': '$date | $time',
          },
        ),
      ),
    );
  }
}
