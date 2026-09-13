import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';

class DirectorReportsTab extends StatefulWidget {
  const DirectorReportsTab({super.key});

  @override
  State<DirectorReportsTab> createState() => _DirectorReportsTabState();
}

class _DirectorReportsTabState extends State<DirectorReportsTab> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthService>().api;
      final emp = await api.getEmployees();
      final att = await api.getAttendance();
      if (mounted) {
        setState(() {
          _employees = emp;
          _attendance = att;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.AccentColor),
      );
    }

    final checkedInIds = _attendance.map((a) => a['EmployeeId']).toSet();
    final present = _employees
        .where((e) => checkedInIds.contains(e['Id']))
        .toList();
    final absent = _employees
        .where((e) => !checkedInIds.contains(e['Id']))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat(
                loc.totalEmployees,
                _employees.length,
                AppTheme.AccentColor,
                Icons.people,
              ),
              const SizedBox(width: 10),
              _stat(
                loc.presentToday,
                present.length,
                AppTheme.SuccessColor,
                Icons.check_circle,
              ),
              const SizedBox(width: 10),
              _stat(
                loc.absentToday,
                absent.length,
                AppTheme.DangerColor,
                Icons.cancel,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            loc.absentToday,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          absent.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.CardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.BorderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppTheme.SuccessColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.noAbsence,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.SuccessColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: absent.asMap().entries.map((entry) {
                    final e = entry.value;
                    final name = e['NomAr'] != null
                        ? '${e['NomAr']} ${e['PrenomAr']}'
                        : '${e['Nom']} ${e['Prenom']}';
                    return GestureDetector(
                      onTap: () => _showAbsentEmployeeOptions(e),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.CardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.BorderColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppTheme.DangerColor.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_off,
                                color: AppTheme.DangerColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e['Service'] ?? ''}',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 11,
                                      color: AppTheme.TextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppTheme.TextSecondary,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  void _showAbsentEmployeeOptions(Map<String, dynamic> emp) {
    final name = emp['NomAr'] != null
        ? '${emp['NomAr']} ${emp['PrenomAr']}'
        : '${emp['Nom']} ${emp['Prenom']}';
    final service = (emp['Service'] ?? 'مصلحة حماية المستهلك وقمع الغش').toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_off, color: AppTheme.DangerColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ملف الغياب والقرائن الرقمية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.BackgroundColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.DangerColor.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppTheme.DangerColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: AppTheme.TextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'القرائن الرقمية المسجلة اليوم',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _proofTile(
                    icon: Icons.timer_off_outlined,
                    title: 'نقطة الانطلاق (08:00 - 08:30)',
                    status: 'لم يسجل الحضور بمقر المديرية ❌',
                  ),
                  const SizedBox(height: 8),
                  _proofTile(
                    icon: Icons.storefront_outlined,
                    title: 'المهام الميدانية',
                    status: '0 زيارات / 0 صور مسجلة ❌',
                  ),
                  const SizedBox(height: 8),
                  _proofTile(
                    icon: Icons.location_off_outlined,
                    title: 'تحديد الموقع GPS',
                    status: 'الهاتف غير متصل بالنظام ❌',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showExplanationLetterForAbsent(emp);
                      },
                      icon: const Icon(Icons.description, color: Colors.black87),
                      label: const Text(
                        'معاينة الاستفسار الكتابي (48 ساعة للتبرير)',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proofTile({required IconData icon, required String title, required String status}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.DangerColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  status,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.DangerColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExplanationLetterForAbsent(Map<String, dynamic> emp) {
    final name = emp['NomAr'] != null ? '${emp['NomAr']} ${emp['PrenomAr']}' : '${emp['Nom']} ${emp['Prenom']}';
    final service = (emp['Service'] ?? 'مصلحة حماية المستهلك وقمع الغش').toString();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1026),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.description, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'استفسار كتابي - Demande d\'Explications',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'الجمهورية الجزائرية الديمقراطية الشعبية\nوزارة التجارة الداخلية وضبط السوق الوطنية\nمديرية التجارة الداخلية وضبط السوق الوطنية لولاية سطيف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFD4AF37), height: 18),
                Text(
                  'إلى السيد(ة): $name',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'الرتبة والمصلحة: $service',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppTheme.TextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'الموضوع: استفسار كتابي حول الغياب عن العمل الميداني\nالمرجع: الأمر رقم 06-03 المتضمن القانون الأساسي للوظيفة العمومية.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'بناءً على المعطيات المسجلة عبر المنصة الرقمية للرقابة والتفتيش اليوم، تبيّن عدم التحاقكم بنقطة الانطلاق وعدم تسجيل أي نشاط أو زيارة رقابية ميدانية.\n\nوعليه، يُطلب منكم موافاة الإدارة بمبررات غيابكم مدعمة بالوثائق الثبوتية، في أجل أقصاه 48 ساعة من استلامكم هذا الاستفسار، وإلا ستُتخذ ضدكم الإجراءات القانونية المترتبة عن الخصم من الراتب.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'المدير الولائي للتجارة\nولاية سطيف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: AppTheme.TextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
