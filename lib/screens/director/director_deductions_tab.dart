import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/screens/common/inquiry_letter_dialog.dart';

class DirectorDeductionsTab extends StatefulWidget {
  const DirectorDeductionsTab({super.key});

  @override
  State<DirectorDeductionsTab> createState() => _DirectorDeductionsTabState();
}

class _DirectorDeductionsTabState extends State<DirectorDeductionsTab> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _inquiries = [];
  List<Map<String, dynamic>> _delaysSummary = [];
  String _morningGraceTime = '08:45';
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
      final inqs = await api.getInquiries();
      final settings = await api.getSettings();
      final grace = (settings['morning_grace_time'] ?? '08:45').toString();
      final delays = await api.getDelaysSummary(graceTime: grace);

      if (mounted) {
        setState(() {
          _employees = emp;
          _inquiries = inqs;
          _morningGraceTime = grace;
          _delaysSummary = delays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGraceTime(String newTime) async {
    try {
      final api = context.read<AuthService>().api;
      await api.updateSetting('morning_grace_time', newTime);
      setState(() => _morningGraceTime = newTime);
      final delays = await api.getDelaysSummary(graceTime: newTime);
      if (mounted) {
        setState(() => _delaysSummary = delays);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تعديل فترة التسامح الصباحية إلى $newTime وتحديث حساب التأخرات'),
            backgroundColor: AppTheme.SuccessColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
        );
      }
    }
  }

  void _showDirectorOrderModal(Map<String, dynamic> employee) {
    final name = '${employee['NomAr'] ?? employee['Nom'] ?? ''} ${employee['PrenomAr'] ?? employee['Prenom'] ?? ''}';
    final empId = employee['Id'] ?? employee['id'];
    final subjectCtrl = TextEditingController(text: 'استفسار وأمر بالانضباط حول الحضور والمردودية');
    final detailsCtrl = TextEditingController(text: 'بناءً على المعطيات الرقابية، يُطلب من مكتب المستخدمين توجيه استفسار كتابي رسمي للموظف المذكور مع منحه 48 ساعة للرد.');

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16121E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.send_and_archive, color: Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'أمر بتوجيه استفسار — $name',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المدير الولائي يكلف مكتب المستخدمين بإصدار استفسار كتابي رسمي للموظف عبر التطبيق:',
              style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectCtrl,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الموضوع',
                labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: detailsCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'تعليمات وتفاصيل الاستفسار',
                labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (subjectCtrl.text.trim().isEmpty) return;
              try {
                final auth = context.read<AuthService>();
                final userId = auth.currentUser?.id ?? 1;
                await auth.api.createInquiry({
                  'employeeId': empId,
                  'type': 'unjustified_absence',
                  'subject': subjectCtrl.text.trim(),
                  'details': detailsCtrl.text.trim(),
                  'sentBy': userId,
                });
                if (dlgCtx.mounted) Navigator.pop(dlgCtx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ تم تكليف مكتب المستخدمين بإصدار الاستفسار لـ $name'),
                    backgroundColor: AppTheme.SuccessColor,
                  ),
                );
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('إصدار الأمر', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    final answeredInquiries = _inquiries.where((i) => i['Status'] == 'answered').toList();
    final decidedInquiries = _inquiries.where((i) => ['justified', 'warning', 'deduction_ordered', 'executed'].contains(i['Status'])).toList();
    final sentInquiries = _inquiries.where((i) => i['Status'] == 'sent').toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFD4AF37),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Morning Grace Time Setting Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1C0A), AppTheme.CardColor],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune, color: Color(0xFFD4AF37), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'فترة التسامح الصباحية (Tolérance)',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _morningGraceTime,
                          dropdownColor: const Color(0xFF1E1026),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD4AF37)),
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(value: '08:15', child: Text('08:15 ص')),
                            DropdownMenuItem(value: '08:30', child: Text('08:30 ص')),
                            DropdownMenuItem(value: '08:45', child: Text('08:45 ص (الموصى بها)')),
                            DropdownMenuItem(value: '09:00', child: Text('09:00 ص (مرونة قصوى)')),
                            DropdownMenuItem(value: '09:15', child: Text('09:15 ص')),
                          ],
                          onChanged: (val) {
                            if (val != null && val != _morningGraceTime) {
                              _updateGraceTime(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'التوقيت الحالي: $_morningGraceTime ص — التأخرات الصباحية تُحسب بعده مباشرة.',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Overview of accumulated delays
          if (_delaysSummary.any((d) => ((d['lateDaysCount'] as num?)?.toInt() ?? 0) > 0)) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.WarningColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.WarningColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppTheme.WarningColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'سجل النظام ${_delaysSummary.where((d) => ((d['lateDaysCount'] as num?)?.toInt() ?? 0) > 0).length} موظفين تجاوزوا موعد التسامح ($_morningGraceTime) هذا الشهر.',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 2. Button: Issue Inquiry Order
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showEmployeePicker(),
              icon: const Icon(Icons.person_search, color: Colors.black),
              label: const Text(
                'طلب توجيه استفسار كتابي لموظف محدد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 3. Urgent: Answered Inquiries Awaiting Director Sovereign Decision
          Row(
            children: [
              const Icon(Icons.rate_review, color: Colors.cyanAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'ملفات الاستفسارات التي تم الرد عليها وبانتظار قراركم السيادي (${answeredInquiries.length})',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (answeredInquiries.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Center(
                child: Text(
                  'لا توجد ردود جديدة معلقة — كافة الملفات تمت معالجتها واتخاذ القرارات بشأنها ✨',
                  style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.TextSecondary, fontSize: 12),
                ),
              ),
            )
          else
            ...answeredInquiries.map((inq) => _buildInquiryCard(inq, isActionable: true)),

          const SizedBox(height: 20),

          // 4. Sent Inquiries (Pending Employee Reply)
          if (sentInquiries.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.WarningColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'استفسارات موجهة بانتظار رد الموظف خلال 48 ساعة (${sentInquiries.length})',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...sentInquiries.map((inq) => _buildInquiryCard(inq, isActionable: false)),
            const SizedBox(height: 20),
          ],

          // 5. Decided / Past Inquiries History
          if (decidedInquiries.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.SuccessColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'سجل القرارات الصادرة والأوامر المنفذة (${decidedInquiries.length})',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...decidedInquiries.take(10).map((inq) => _buildInquiryCard(inq, isActionable: false)),
          ],
        ],
      ),
    );
  }

  Widget _buildInquiryCard(Map<String, dynamic> inq, {required bool isActionable}) {
    final nomAr = inq['NomAr'] ?? inq['nomar'] ?? inq['Nom'] ?? inq['nom'] ?? inq['name'] ?? inq['employeeName'] ?? '';
    final prenomAr = inq['PrenomAr'] ?? inq['prenomar'] ?? inq['Prenom'] ?? inq['prenom'] ?? '';
    final name = (nomAr.toString().trim().isNotEmpty || prenomAr.toString().trim().isNotEmpty)
        ? '$nomAr $prenomAr'.trim()
        : (inq['EmployeeName'] ?? inq['employee_name'] ?? 'عضو فرقة الرقابة والتفتيش').toString();
    final status = (inq['Status'] ?? inq['status'] ?? 'sent').toString();
    final service = (inq['Service'] ?? inq['service'] ?? 'مديرية التجارة لولاية سطيف').toString();
    final subject = (inq['Subject'] ?? inq['subject'] ?? inq['Details'] ?? inq['details'] ?? 'استفسار إداري حول الانضباط ومواقيت العمل').toString();

    Color statusColor = AppTheme.WarningColor;
    String statusText = 'بانتظار رد الموظف';
    if (status == 'answered') {
      statusColor = Colors.cyan;
      statusText = 'تم الرد — اضغط للفصل في الملف 👈';
    } else if (status == 'justified') {
      statusColor = AppTheme.SuccessColor;
      statusText = '✅ تم قبول التبرير وحفظ الملف';
    } else if (status == 'warning') {
      statusColor = Colors.orange;
      statusText = '⚠️ تم توجيه تنبيه إداري';
    } else if (status == 'deduction_ordered') {
      statusColor = AppTheme.DangerColor;
      statusText = '❌ قرار خصم (${inq['DeductionDays'] ?? inq['deductiondays'] ?? 1} يوم) محال للمستخدمين';
    } else if (status == 'executed') {
      statusColor = Colors.green;
      statusText = '✔️ تم الخصم في الراتب';
    }

    return GestureDetector(
      onTap: () => _showInquiryDossier(inq),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActionable
                ? Colors.cyan.withValues(alpha: 0.6)
                : AppTheme.BorderColor.withValues(alpha: 0.3),
            width: isActionable ? 1.5 : 1,
          ),
          boxShadow: [
            if (isActionable)
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActionable ? Icons.rate_review : Icons.folder_shared,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new, size: 12, color: AppTheme.TextSecondary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$service — $subject',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInquiryDossier(Map<String, dynamic> inq) {
    final nomAr = inq['NomAr'] ?? inq['nomar'] ?? inq['Nom'] ?? inq['nom'] ?? inq['name'] ?? inq['employeeName'] ?? '';
    final prenomAr = inq['PrenomAr'] ?? inq['prenomar'] ?? inq['Prenom'] ?? inq['prenom'] ?? '';
    final name = (nomAr.toString().trim().isNotEmpty || prenomAr.toString().trim().isNotEmpty)
        ? '$nomAr $prenomAr'.trim()
        : (inq['EmployeeName'] ?? inq['employee_name'] ?? 'عضو فرقة الرقابة والتفتيش').toString();
    final service = (inq['Service'] ?? inq['service'] ?? 'مديرية التجارة سطيف').toString();
    final status = (inq['Status'] ?? inq['status'] ?? 'sent').toString();
    final rawDate = (inq['IncidentDate'] ?? inq['incidentdate'] ?? inq['Date'] ?? inq['date'] ?? inq['CreatedAt'] ?? '').toString();
    final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : (rawDate.isNotEmpty ? rawDate : 'اليوم');
    final reply = inq['EmployeeReply'] ?? inq['employeereply'] ?? inq['Reply'] ?? inq['reply'];
    final int lateMins = ((inq['LateMinutes'] ?? inq['lateminutes'] ?? 0) as num).toInt();
    final bool hasLateMins = lateMins > 0;
    final bool hasReply = reply != null && reply.toString().trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Color(0xFF130F1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
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
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gavel, color: Color(0xFFD4AF37), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملف الاستفسار واتخاذ القرار السيادي للمدير',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Dossier Disciplinaire & Pouvoir d\'Appréciation - المدير الولائي الآمر بالصرف',
                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppTheme.TextSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Dossier Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Employee Header Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF261230), AppTheme.CardColor]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.PrimaryColor.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, size: 30, color: AppTheme.PrimaryColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service,
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'تاريخ الواقعة: $dateStr  ${hasLateMins ? " | تأخر: $lateMins دقيقة" : ""}',
                                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFD4AF37)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Employee Written Reply Section (The Core!)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasReply
                          ? Colors.cyan.withValues(alpha: 0.1)
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasReply
                            ? Colors.cyan.withValues(alpha: 0.4)
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hasReply ? Icons.reply_all : Icons.pending_actions,
                              color: hasReply ? Colors.cyanAccent : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasReply ? 'رد وتبريرات الموظف الرسمية:' : 'الموظف لم يرسل رده بعد (ضمن مهلة 48 ساعة)',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: hasReply ? Colors.cyanAccent : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasReply
                              ? '$reply'
                              : 'بانتظار إدخال الموظف لمبرراته عبر التطبيق أو تقديم وثيقة رسمية.',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 4 Digital Evidence Cards
                  const Text(
                    'أدلة وقرائن الإثبات الرقمية (GPS & الحضور):',
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
                    title: '1. موعد الانطلاق وفترة التسامح ($_morningGraceTime)',
                    desc: hasLateMins
                        ? 'تجاوز فترة التسامح الصباحية بمقدار $lateMins دقيقة تأخر.'
                        : 'عدم تسجيل حضور في النطاق الجغرافي المحدد.',
                    status: hasLateMins ? '$lateMins دقيقة تأخر ⚠️' : 'غير مسجل ❌',
                    statusColor: hasLateMins ? AppTheme.WarningColor : AppTheme.DangerColor,
                  ),
                  const SizedBox(height: 6),
                  _evidenceCard(
                    icon: Icons.storefront_outlined,
                    title: '2. المردودية والزيارات الميدانية',
                    desc: 'سجل الزيارات والمعاينات التجارية والمحاضر الرقابية في هذا التاريخ.',
                    status: '0 زيارات ❌',
                    statusColor: AppTheme.DangerColor,
                  ),

                  const SizedBox(height: 14),

                  // Printable Inquiry Sheet Button
                  OutlinedButton.icon(
                    onPressed: () => InquiryLetterDialog.show(context, inq),
                    icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37)),
                    label: const Text(
                      'معاينة استمارة الاستفسار الإداري الرسمية',
                      style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sovereign Decision Buttons for Director (if status == 'answered' or 'sent')
                  if (status == 'answered' || status == 'sent') ...[
                    const Text(
                      'القرار السيادي للمدير الولائي (صاحب السلطة والآمر بالصرف):',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Option 1: Justified (Classé sans suite)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _submitDecision(
                              inquiryId: inq['Id'] as int,
                              decision: 'justified',
                              name: name,
                              parentCtx: ctx,
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(
                              'قبول التبرير (حفظ)',
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.SuccessColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Option 2: Warning (Avertissement)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _submitDecision(
                              inquiryId: inq['Id'] as int,
                              decision: 'warning',
                              name: name,
                              parentCtx: ctx,
                            ),
                            icon: const Icon(Icons.warning_amber, size: 16),
                            label: const Text(
                              'توجيه إنذار',
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Option 3: Final Deduction Decision
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDeductionDaysDialog(
                              inquiryId: inq['Id'] as int,
                              name: name,
                              parentCtx: ctx,
                            ),
                            icon: const Icon(Icons.gavel, size: 16),
                            label: const Text(
                              'قرار خصم نافذ',
                              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.DangerColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showDeductionDaysDialog({required int inquiryId, required String name, required BuildContext parentCtx}) {
    double selectedDays = 1.0;
    final notesCtrl = TextEditingController(text: 'خصم من الراتب لعدم كفاية التبريرات المسجلة بناءً على المقتضيات القانونية');

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF16121E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppTheme.DangerColor, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.gavel, color: AppTheme.DangerColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'إصدار قرار خصم نهائي — $name',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.DangerColor,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حدد عدد أيام الخصم الواجب اقتطاعها رسمياً وإحالتها لمكتب المستخدمين لتنفيذها في كشف الراتب:',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('نصف يوم (0.5)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
                    selected: selectedDays == 0.5,
                    selectedColor: AppTheme.DangerColor,
                    onSelected: (val) => setDlgState(() => selectedDays = 0.5),
                  ),
                  ChoiceChip(
                    label: const Text('يوم كامل (1.0)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
                    selected: selectedDays == 1.0,
                    selectedColor: AppTheme.DangerColor,
                    onSelected: (val) => setDlgState(() => selectedDays = 1.0),
                  ),
                  ChoiceChip(
                    label: const Text('يومان (2.0)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
                    selected: selectedDays == 2.0,
                    selectedColor: AppTheme.DangerColor,
                    onSelected: (val) => setDlgState(() => selectedDays = 2.0),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'ملاحظات وتوجيهات المدير لمكتب المستخدمين',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final api = context.read<AuthService>().api;
                Navigator.pop(dlgCtx);
                Navigator.pop(parentCtx);
                try {
                  await api.submitDirectorDecision(
                    inquiryId,
                    'deduction',
                    notes: notesCtrl.text.trim(),
                    deductionDays: selectedDays,
                  );
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ تم إصدار قرار الخصم بمقدار $selectedDays يوم وإحالته لمكتب المستخدمين للتنفيذ الفوري'),
                      backgroundColor: AppTheme.SuccessColor,
                    ),
                  );
                  if (mounted) _load();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.DangerColor),
              child: const Text('تأكيد وإصدار القرار النافذ', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _submitDecision({
    required int inquiryId,
    required String decision,
    required String name,
    required BuildContext parentCtx,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<AuthService>().api;
    Navigator.pop(parentCtx);
    try {
      await api.submitDirectorDecision(inquiryId, decision);
      messenger.showSnackBar(
        SnackBar(
          content: Text(decision == 'justified' ? '✅ تم قبول تبرير $name وحفظ الملف' : '⚠️ تم توجيه تنبيه إداري لـ $name'),
          backgroundColor: decision == 'justified' ? AppTheme.SuccessColor : Colors.orange,
        ),
      );
      if (mounted) _load();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
      );
    }
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
        border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
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
                        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeePicker() {
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
              color: Color(0xFF130F1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.BorderColor.withValues(alpha: 0.3))),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'اختر موظفاً لإصدار أمر استفسار بشأنه',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
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
                      hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      final name = e['NomAr'] != null
                          ? '${e['NomAr']} ${e['PrenomAr'] ?? ''}'
                          : '${e['Nom'] ?? ''} ${e['Prenom'] ?? ''}';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.PrimaryColor.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppTheme.PrimaryColor, size: 18),
                        ),
                        title: Text(name, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('${e['Service'] ?? ''}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showDirectorOrderModal(e);
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
