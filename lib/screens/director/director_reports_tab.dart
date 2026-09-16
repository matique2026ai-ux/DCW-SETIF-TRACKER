import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:drh_setif_tracker/services/pdf_report_service.dart';
import 'package:drh_setif_tracker/screens/common/justifications_review_screen.dart';

class DirectorReportsTab extends StatefulWidget {
  const DirectorReportsTab({super.key});

  @override
  State<DirectorReportsTab> createState() => _DirectorReportsTabState();
}

class _DirectorReportsTabState extends State<DirectorReportsTab> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _deductions = [];
  List<Map<String, dynamic>> _programs = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthService>().api;
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final emp = await api.getEmployees();
      final att = await api.getAttendance(date: todayStr);
      final ded = await api.getDeductions();
      final progs = await api.getPrograms();
      if (mounted) {
        setState(() {
          _employees = emp;
          _attendance = att;
          _deductions = ded;
          _programs = progs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProgramsDialog() {
    final checkedInIds = _attendance.map((a) => a['EmployeeId']).toSet();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF4A2050)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment, color: Color(0xFF38BDF8), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'البرامج الرقابية وأوامر المهمة السارية',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'متابعة برامج مصالح الرقابة الاقتصادية وقمع الغش',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          width: double.maxFinite,
          child: _programs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'لا توجد برامج رقابية مسجلة حالياً',
                      style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _programs.map((p) {
                      final title = p['Title']?.toString() ?? 'برنامج رقابي';
                      final service = p['ServiceName']?.toString() ?? 'مصلحة الرقابة';
                      final targetArea = p['TargetArea']?.toString() ?? 'ولاية سطيف';
                      final focus = p['FocusPoints']?.toString() ?? '';
                      final isConcurrence = service.contains('المنافسة');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E0B26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConcurrence
                                ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                                : const Color(0xFF10B981).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isConcurrence ? const Color(0xFF3B82F6) : const Color(0xFF10B981))
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    service,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isConcurrence ? const Color(0xFF60A5FA) : const Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'أمر مهمة ساري',
                                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 13, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'القطاع الإقليمي: $targetArea',
                                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFFCD34D)),
                                  ),
                                ),
                              ],
                            ),
                            if (focus.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.center_focus_strong, size: 13, color: Colors.white54),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'أهداف المداهمة والرقابة: $focus',
                                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            // Inspectors working on this department/program
                            Builder(
                              builder: (_) {
                                final deptInspectors = _employees.where((e) {
                                  final s = (e['Service'] ?? '').toString();
                                  return s.contains(service) || service.contains(s);
                                }).toList();

                                if (deptInspectors.isEmpty) return const SizedBox.shrink();

                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.groups, size: 13, color: Color(0xFF38BDF8)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'الفرق المفتشية المسندة للمهمة (${deptInspectors.length} مفتشاً):',
                                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: deptInspectors.take(8).map((emp) {
                                          final isAttended = checkedInIds.contains(emp['Id']);
                                          final name = '${emp['NomAr'] ?? emp['Nom'] ?? ''} ${emp['PrenomAr'] ?? emp['Prenom'] ?? ''}'.trim();
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isAttended ? const Color(0xFF10B981).withValues(alpha: 0.2) : Colors.white10,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: isAttended ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.white24),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isAttended ? Icons.check_circle : Icons.circle_outlined,
                                                  size: 10,
                                                  color: isAttended ? const Color(0xFF10B981) : Colors.white38,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  name.isNotEmpty ? name : 'مفتش #${emp['Id']}',
                                                  style: TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 10,
                                                    color: isAttended ? Colors.white : Colors.white60,
                                                    fontWeight: isAttended ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showNewProgramDialog();
            },
            icon: const Icon(Icons.add_task, size: 16),
            label: const Text(
              '+ تسطير برنامج ولائي جديد',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF1E0B26),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewProgramDialog() {
    final titleCtrl = TextEditingController(text: 'برنامج ولائي لمراقبة الممارسات التجارية وقمع الغش');
    final areaCtrl = TextEditingController(text: 'بلديات سطيف، العلمة، وعين ولمان');
    final focusCtrl = TextEditingController(text: 'مراقبة الأسعار المقننة، الفوترة، ومطابقة المواد الاستهلاكية الحساسة');
    String selectedService = 'مصلحة حماية المستهلك وقمع الغش';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF240D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFD4AF37)),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_task, color: Color(0xFFD4AF37), size: 22),
              SizedBox(width: 10),
              Text(
                'تسطير برنامج رقابي ولائي جديد',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المصلحة المكلفة بالتنفيذ:', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedService,
                    dropdownColor: const Color(0xFF2D1035),
                    isExpanded: true,
                    style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'مصلحة حماية المستهلك وقمع الغش',
                        child: Text('مصلحة حماية المستهلك وقمع الغش'),
                      ),
                      DropdownMenuItem(
                        value: 'مصلحة المنافسة والتحقيقات الاقتصادية',
                        child: Text('مصلحة المنافسة والتحقيقات الاقتصادية'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedService = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'عنوان البرنامج الرقابي / أمر المهمة *',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'القطاع الجغرافي المستهدف *',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: focusCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'محاور التفتيش والأهداف الرئيسية',
                      labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final area = areaCtrl.text.trim();
                final focus = focusCtrl.text.trim();
                if (title.isEmpty) return;

                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                final messenger = ScaffoldMessenger.of(context);
                try {
                  final api = context.read<AuthService>().api;
                  final user = context.read<AuthService>().currentUser;
                  await api.createProgram(
                    title: title,
                    targetArea: area,
                    focusPoints: focus,
                    serviceName: selectedService,
                    createdBy: user?.id ?? 1,
                    type: 'provincial_mission',
                  );
                  await _load();
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ تم تسطير وإسناد البرنامج الرقابي الولائي بنجاح', style: TextStyle(fontFamily: 'Tajawal')),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    messenger.showSnackBar(
                      SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: const Text('تأكيد وإصدار البرنامج', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF1E0B26),
              ),
            ),
          ],
        ),
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

    final checkedInIds = _attendance.map((a) => a['EmployeeId']).toSet();
    final present = _employees
        .where((e) => checkedInIds.contains(e['Id']))
        .toList();
    final absent = _employees
        .where((e) => !checkedInIds.contains(e['Id']))
        .toList();

    final q = _searchQuery.trim().toLowerCase();
    final filteredAbsent = absent.where((e) {
      if (q.isEmpty) return true;
      final nameAr = '${e['NomAr'] ?? ''} ${e['PrenomAr'] ?? ''}'.toLowerCase();
      final nameFr = '${e['Nom'] ?? ''} ${e['Prenom'] ?? ''}'.toLowerCase();
      final service = (e['Service'] ?? '').toString().toLowerCase();
      return nameAr.contains(q) || nameFr.contains(q) || service.contains(q);
    }).toList();

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
          const SizedBox(height: 16),

          // Action Buttons: PDF Export, Programs Review, Justifications Review
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    PdfReportService.generateAndPrintDailyReport(
                      employees: _employees,
                      attendance: _attendance,
                      visits: [],
                      directorName: 'السيد المدير الولائي',
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.black, size: 16),
                  label: const Text(
                    'تصدير محضر PDF',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showProgramsDialog,
                  icon: const Icon(Icons.assignment, color: Colors.white, size: 16),
                  label: const Text(
                    'البرامج الرقابية',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => JustificationsReviewScreen.show(context),
                  icon: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF38BDF8), size: 16),
                  label: const Text(
                    'مبررات الغياب',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${loc.absentToday} (${absent.length})',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'لم يسجلوا الحضور اليوم',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Live Search Bar for Absent Employees
          TextField(
            textDirection: TextDirection.rtl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم، اللقب أو المصلحة بين الموظفين...',
              hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
              filled: true,
              fillColor: AppTheme.CardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 14),

          filteredAbsent.isEmpty
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
                        Icon(
                          absent.isEmpty ? Icons.check_circle : Icons.search_off,
                          size: 48,
                          color: absent.isEmpty ? AppTheme.SuccessColor : AppTheme.TextSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          absent.isEmpty
                              ? loc.noAbsence
                              : 'لم يتم العثور على أي موظف يطابق البحث',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.TextSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: filteredAbsent.asMap().entries.map((entry) {
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
                    'القرائن والوضعية الحالية المسجلة بالنظام',
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
                    title: 'تسجيل الحضور اليومي',
                    status: 'لم يسجل الحضور اليوم عبر التطبيق ❌',
                  ),
                  const SizedBox(height: 8),
                  _proofTile(
                    icon: Icons.storefront_outlined,
                    title: 'المهام والمعاينات الميدانية',
                    status: '0 زيارات تجارية مسجلة اليوم',
                  ),
                  const SizedBox(height: 8),
                  _proofTile(
                    icon: Icons.history_edu_outlined,
                    title: 'السوابق الإدارية والخصومات',
                    status: _deductions.where((d) => d['EmployeeId'] == emp['Id']).isEmpty
                        ? 'السجل الإداري نظيف (0 سوابق خصم) ✔️'
                        : 'يوجد ${_deductions.where((d) => d['EmployeeId'] == emp['Id']).length} طلبات خصم سابقة في النظام ⚠️',
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
