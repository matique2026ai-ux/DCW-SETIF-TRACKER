import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';

class DirectorDeductionsTab extends StatefulWidget {
  const DirectorDeductionsTab({super.key});

  @override
  State<DirectorDeductionsTab> createState() => _DirectorDeductionsTabState();
}

class _DirectorDeductionsTabState extends State<DirectorDeductionsTab> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _deductions = [];
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
      final ded = await api.getDeductions();
      if (mounted) {
        setState(() {
          _employees = emp;
          _deductions = ded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _requestDeduction(Map<String, dynamic> employee) {
    final loc = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    final daysCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.CardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.requestDeduction,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.AccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppTheme.AccentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${employee['NomAr'] ?? employee['Nom']} ${employee['PrenomAr'] ?? employee['Prenom']}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: loc.deductionReason,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: loc.deductionDays,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel, style: const TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.isEmpty) return;
              try {
                final api = context.read<AuthService>().api;
                final user = context.read<AuthService>().currentUser;
                await api.requestDeduction(
                  employeeId: employee['Id'] as int,
                  requestedBy: user!.id!,
                  reason: reasonCtrl.text,
                  daysCount: int.tryParse(daysCtrl.text),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم إنشاء طلب الخصم بنجاح'),
                    backgroundColor: AppTheme.SuccessColor,
                  ),
                );
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$e'),
                    backgroundColor: AppTheme.DangerColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.DangerColor,
            ),
            child: Text(loc.submit, style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.AccentColor),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEmployeePicker(),
              icon: const Icon(Icons.person_remove),
              label: Text(
                loc.requestDeduction,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.DangerColor,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                loc.pendingDeductions,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Text(
                'اضغط للمعاينة والمواجهة 👈',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _deductions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppTheme.SuccessColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.noDeductions,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _deductions.length,
                  itemBuilder: (context, index) {
                    final d = _deductions[index];
                    final name = d['NomAr'] != null
                        ? '${d['NomAr']} ${d['PrenomAr']}'
                        : '${d['Nom']} ${d['Prenom']}';
                    final status = d['Status'] ?? 'pending';
                    final statusColor = status == 'approved'
                        ? AppTheme.SuccessColor
                        : status == 'rejected'
                        ? AppTheme.DangerColor
                        : AppTheme.WarningColor;
                    final statusText = status == 'approved'
                        ? loc.approved
                        : status == 'rejected'
                        ? loc.rejected
                        : loc.pending;
                    return GestureDetector(
                      onTap: () => _showDeductionFile(d),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.CardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: status == 'pending'
                                ? const Color(0xFFD4AF37).withValues(alpha: 0.4)
                                : AppTheme.BorderColor.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            if (status == 'pending')
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.folder_shared,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 13,
                                        color: AppTheme.TextSecondary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d['Reason']}',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 11,
                                      color: AppTheme.TextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 10,
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'انقر للاطلاع على الأدلة',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 10,
                                          color: Color(0xFFD4AF37),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (d['DaysCount'] != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.DangerColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${d['DaysCount']} ${loc.days}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.DangerColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeductionFile(Map<String, dynamic> d) {
    final loc = AppLocalizations.of(context);
    final String name = d['NomAr'] != null
        ? '${d['NomAr']} ${d['PrenomAr']}'
        : '${d['Nom']} ${d['Prenom']}';
    final String service = (d['Service'] ?? 'مصلحة حماية المستهلك وقمع الغش').toString();
    final status = d['Status'] ?? 'pending';
    final statusColor = status == 'approved'
        ? AppTheme.SuccessColor
        : status == 'rejected'
        ? AppTheme.DangerColor
        : AppTheme.WarningColor;
    final statusText = status == 'approved'
        ? loc.approved
        : status == 'rejected'
        ? loc.rejected
        : loc.pending;
    final days = d['DaysCount'] ?? 1;
    final String reason = (d['Reason'] ?? 'غياب غير مبرر').toString();
    final String requestedBy = (d['RequestedByName'] ?? 'رئيس المصلحة').toString();
    final String dateStr = d['Date'] != null ? d['Date'].toString().substring(0, 10) : 'اليوم';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
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
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.AccentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_shared,
                      color: AppTheme.AccentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملف الإثبات الرقمي والمواجهة الإدارية',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dossier de Preuves & Confrontation - الأمر 06-03',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            color: AppTheme.TextSecondary,
                          ),
                        ),
                      ],
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
            // Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Employee Profile Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D1035), AppTheme.CardColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.BorderColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.PrimaryColor.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: AppTheme.PrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                service,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: AppTheme.TextSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.DangerColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppTheme.DangerColor.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'خصم $days يوم',
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.DangerColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Metadata Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.calendar_today, 'تاريخ الواقعة', dateStr),
                        const SizedBox(height: 6),
                        _infoRow(Icons.description, 'السبب المسجل', reason),
                        const SizedBox(height: 6),
                        _infoRow(Icons.person_pin, 'مقدم الطلب', requestedBy),
                        if (d['ApprovedByName'] != null) ...[
                          const SizedBox(height: 6),
                          _infoRow(Icons.check_circle, 'المعالج', (d['ApprovedByName'] ?? '').toString()),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4 Digital Evidence Pillars
                  const Text(
                    'أدلة وقرائن الإثبات الرقمية (لا تحتمل الإنكار)',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _evidenceCard(
                    icon: Icons.timer_off_outlined,
                    title: '1. الانطلاق الصباحي (08:00 - 08:30)',
                    desc: 'غياب تام عن مقر المديرية — لم تسجل بصمة الوجه/الصورة ولم تدخل في النطاق الجغرافي 500m.',
                    status: 'غير مسجل ❌',
                    statusColor: AppTheme.DangerColor,
                  ),
                  const SizedBox(height: 8),
                  _evidenceCard(
                    icon: Icons.storefront_outlined,
                    title: '2. التدخلات والزيارات الميدانية',
                    desc: '0 زيارات تجارية مسجلة (لا توجد صور معاينة، لا مسح QR كود للمحلات، لا محاضر رقابية).',
                    status: '0 زيارات ❌',
                    statusColor: AppTheme.DangerColor,
                  ),
                  const SizedBox(height: 8),
                  _evidenceCard(
                    icon: Icons.location_off_outlined,
                    title: '3. التموضع الجغرافي ونظام GPS',
                    desc: 'انقطاع تام عن المنصة الرقمية وعدم إرسال أي إحداثيات تواجد طيلة فترة العمل القانونية.',
                    status: 'لا يوجد أثر GPS ❌',
                    statusColor: AppTheme.DangerColor,
                  ),
                  const SizedBox(height: 8),
                  _evidenceCard(
                    icon: Icons.history_edu_outlined,
                    title: '4. السوابق الإدارية والتكرار',
                    desc: 'تم تسجيل غيابات وتأخرات سابقة لنفس العون خلال هذا الشهر دون مبرر مقبول قانوناً.',
                    status: 'حالة تكرار ⚠️',
                    statusColor: AppTheme.WarningColor,
                  ),

                  const SizedBox(height: 16),

                  // Button: View Written Explanation (Demande d'Explications)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showExplanationLetter(d),
                      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37)),
                      label: const Text(
                        'معاينة الاستفسار الكتابي القانوني (48 ساعة للرد)',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD4AF37)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons for Director (if status == 'pending')
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmAction(
                              deductionId: d['Id'] as int,
                              isApprove: true,
                              name: name,
                              parentCtx: ctx,
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text(
                              'اعتماد الخصم',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.SuccessColor,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmAction(
                              deductionId: d['Id'] as int,
                              isApprove: false,
                              name: name,
                              parentCtx: ctx,
                            ),
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text(
                              'قبول التبرير',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.TextSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: AppTheme.TextSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _evidenceCard({
    required IconData icon,
    required String title,
    required String desc,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.BackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.BorderColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: AppTheme.TextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExplanationLetter(Map<String, dynamic> d) {
    final name = d['NomAr'] != null
        ? '${d['NomAr']} ${d['PrenomAr']}'
        : '${d['Nom']} ${d['Prenom']}';
    final service = d['Service'] ?? 'مصلحة حماية المستهلك وقمع الغش';
    final dateStr = d['Date'] != null ? d['Date'].toString().substring(0, 10) : 'اليوم';

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
                    'الجمهورية الجزائرية الديمقراطية الشعبية\nوزارة التجارة وترقية الصادرات\nمديرية التجارة لولاية سطيف',
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
                Text(
                  'بناءً على المعطيات المسجلة عبر المنصة الرقمية للرقابة والتفتيش بتاريخ $dateStr، تبيّن عدم التحاقكم بنقطة الانطلاق وعدم تسجيل أي نشاط أو زيارة رقابية ميدانية.\n\nوعليه، يُطلب منكم موافاة الإدارة بمبررات غيابكم مدعمة بالوثائق الثبوتية، في أجل أقصاه 48 ساعة من استلامكم هذا الاستفسار، وإلا ستُتخذ ضدكم الإجراءات القانونية المترتبة عن الخصم من الراتب.',
                  style: const TextStyle(
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

  void _confirmAction({
    required int deductionId,
    required bool isApprove,
    required String name,
    required BuildContext parentCtx,
  }) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppTheme.CardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isApprove ? 'تأكيد اعتماد الخصم' : 'تأكيد قبول التبرير',
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Text(
          isApprove
              ? 'هل أنت متأكد من اعتماد الخصم للعون "$name" وإحالة الملف رسمياً إلى مكتب المستخدمين لتنفيذه في الراتب؟'
              : 'هل أنت متأكد من قبول التبرير المقدم من العون "$name" وحفظ الملف؟',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              Navigator.pop(parentCtx);
              try {
                final api = context.read<AuthService>().api;
                final user = context.read<AuthService>().currentUser;
                final userId = user?.id ?? 1;
                if (isApprove) {
                  await api.approveDeduction(id: deductionId, approvedBy: userId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم اعتماد الخصم وإحالة ملف $name لمكتب المستخدمين'),
                      backgroundColor: AppTheme.SuccessColor,
                    ),
                  );
                } else {
                  await api.rejectDeduction(id: deductionId, approvedBy: userId);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم قبول تبرير $name وحفظ الملف'),
                      backgroundColor: AppTheme.WarningColor,
                    ),
                  );
                }
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: AppTheme.DangerColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.SuccessColor : AppTheme.DangerColor,
            ),
            child: Text(
              isApprove ? 'نعم، اعتماد وإحالة' : 'نعم، حفظ الملف',
              style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeePicker() {
    final loc = AppLocalizations.of(context);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = _employees.where((e) {
            final name = '${e['NomAr'] ?? e['Nom'] ?? ''} ${e['PrenomAr'] ?? e['Prenom'] ?? ''}'.toLowerCase();
            final service = (e['Service'] ?? '').toString().toLowerCase();
            final q = searchQuery.trim().toLowerCase();
            return name.contains(q) || service.contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: AppTheme.CardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.BorderColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        loc.selectEmployee,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onChanged: (val) => setSheetState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مفتش بالاسم أو المصلحة...',
                      hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final name = e['NomAr'] != null
                          ? '${e['NomAr']} ${e['PrenomAr']}'
                          : '${e['Nom']} ${e['Prenom']}';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.PrimaryColor.withValues(alpha: 0.2),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.PrimaryColor,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${e['Service'] ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            color: AppTheme.TextSecondary,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _requestDeduction(e);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
