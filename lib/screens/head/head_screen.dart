import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/common/qr_code_screen.dart';
import 'package:drh_setif_tracker/utils/constants.dart';



class HeadScreen extends StatefulWidget {
  const HeadScreen({super.key});

  @override
  State<HeadScreen> createState() => _HeadScreenState();
}

class _HeadScreenState extends State<HeadScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _todayVisits = [];
  List<Map<String, dynamic>> _inspectors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthService>().api;
      final progs = await api.getPrograms();
      final visits = await api.getTodayVisits();
      final mapData = await api.getMapData();

      if (mounted) {
        setState(() {
          _programs = progs;
          _todayVisits = visits;
          _inspectors = mapData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewMissionDialog() {
    final titleCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'سطيف والعلمة');
    final focusCtrl = TextEditingController(text: 'إشهار الأسعار والفوترة وتتبع مسار المنتجات');
    String targetType = 'تجار التجزئة والسوبرماركت';
    String programType = 'daily';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.CardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.assignment_add, color: AppTheme.AccentColor, size: 24),
              SizedBox(width: 10),
              Text(
                'إصدار أمر مهمة رقابية لفرق المفتشين',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: 'موضوع المهمة / البرنامج الرقابي',
                    hintText: 'مثال: مراقبة أسعار المواد واسعة الاستهلاك',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: 'القطاع الجغرافي المستهدف',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: targetType,
                  dropdownColor: AppTheme.CardColor,
                  decoration: InputDecoration(
                    labelText: 'الأنشطة المستهدفة',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'تجار التجزئة والسوبرماركت', child: Text('تجار التجزئة والسوبرماركت', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                    DropdownMenuItem(value: 'أسواق الجملة للخضر والفواكه', child: Text('أسواق الجملة للخضر والفواكه', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                    DropdownMenuItem(value: 'المخابز ومحلات الحلويات', child: Text('المخابز ومحلات الحلويات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                    DropdownMenuItem(value: 'المذابح وتجار اللحوم البيضاء والحمراء', child: Text('المذابح وتجار اللحوم', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                    DropdownMenuItem(value: 'وحدات الإنتاج والتحويل الصناعي', child: Text('وحدات الإنتاج والتحويل', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => targetType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: focusCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'النقاط البؤرية والتعليمات الرقابية',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('أمر مهمة يومي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        selected: programType == 'daily',
                        onSelected: (selected) {
                          if (selected) setModalState(() => programType = 'daily');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('برنامج أسبوعي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        selected: programType == 'weekly',
                        onSelected: (selected) {
                          if (selected) setModalState(() => programType = 'weekly');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final auth = context.read<AuthService>();
                final user = auth.currentUser;
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final api = auth.api;
                  await api.createProgram(
                    title: titleCtrl.text.trim(),
                    targetArea: areaCtrl.text.trim(),
                    targetType: targetType,
                    focusPoints: focusCtrl.text.trim(),
                    type: programType,
                    serviceName: user?.serviceName,
                    createdBy: user?.id,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAllData();

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ تم إصدار أمر المهمة وتعميمه على فرق المفتشين بنجاح',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      backgroundColor: AppTheme.SuccessColor,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('⚠️ خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
                      backgroundColor: AppTheme.WarningColor,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('تعميم وتأشير الأمر', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitDetailsModal(Map<String, dynamic> visit) {
    final String shop = (visit['ShopName'] ?? visit['TraderName'] ?? 'معاينة تفتيشية').toString();
    final String inspectorName = visit['NomAr'] != null ? '${visit['NomAr']} ${visit['PrenomAr']}' : (visit['EmployeeName']?.toString() ?? 'المفتش');
    final String time = visit['CheckInTime'] != null ? visit['CheckInTime'].toString() : '';
    final String? photoBase64 = visit['Photo']?.toString();
    final dynamic lat = visit['Latitude'];
    final dynamic lng = visit['Longitude'];
    final String notes = (visit['Notes'] ?? 'معاينة ميدانية ومطابقة الشروط').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.PrimaryColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user, color: AppTheme.PrimaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('المفتش المحرر: $inspectorName', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: AppTheme.TextSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.SuccessColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('محررة اليوم', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.SuccessColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (photoBase64 != null && photoBase64.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(photoBase64),
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ملاحظات المفتش: $notes', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white)),
                  if (lat != null && lng != null) ...[
                    const SizedBox(height: 6),
                    Text('الموقع: $lat, $lng', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      QRCodeScreen.show(
                        context,
                        record: {
                          'type': 'visit_verified',
                          'inspector': inspectorName,
                          'shop': shop,
                          'time': time,
                          'latitude': lat,
                          'longitude': lng,
                          'status': 'APPROVED_BY_HEAD',
                        },
                        title: 'الإثبات الرقمي وتأشير رئيس المصلحة',
                      );
                    },
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('إثبات الـ QR', style: TextStyle(fontFamily: 'Tajawal')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ تم تأشير واعتماد تقرير المعاينة رسمياً', style: TextStyle(fontFamily: 'Tajawal')),
                          backgroundColor: AppTheme.SuccessColor,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('تأشير واعتماد', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.SuccessColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final user = context.watch<AuthService>().currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D1035),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFF92400E)]),
                ),
                child: const Center(child: Icon(Icons.admin_panel_settings, size: 18, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? loc.roleHead,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.serviceName ?? 'رئاسة المصلحة الرقابية',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_2, color: Color(0xFFD4AF37)),
              tooltip: 'رمز الحضور الرسمي للمصلحة (QR)',
              onPressed: () {
                QRCodeScreen.show(
                  context,
                  record: {
                    'type': 'DCW_SETIF_OFFICIAL_CHECKPOINT',
                    'employeeName': user?.serviceName ?? 'مصلحة الرقابة — سطيف',
                    'date': DateTime.now().toIso8601String().split('T')[0],
                    'latitude': AppConstants.hqLatitude,
                    'longitude': AppConstants.hqLongitude,
                  },
                  title: 'رمز الحضور الرسمي — ${user?.serviceName ?? 'مصلحة الرقابة'}',
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.AccentColor),
              onPressed: _loadAllData,
            ),
            IconButton(
              icon: const Icon(Icons.language, color: Color(0xFFD4AF37)),
              onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () {
                context.read<AuthService>().logout();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: 'أوامر المهمة والبرامج'),
              Tab(icon: Icon(Icons.fact_check), text: 'تأشير المعاينات'),
              Tab(icon: Icon(Icons.people_alt), text: 'متابعة الأعوان'),
            ],
          ),
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _showNewMissionDialog,
                backgroundColor: AppTheme.AccentColor,
                foregroundColor: Colors.black,
                icon: const Icon(Icons.add_task),
                label: const Text('أمر مهمة جديد', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.AccentColor))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMissionsTab(),
                  _buildVisitsValidationTab(),
                  _buildInspectorsPresenceTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildMissionsTab() {
    if (_programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: AppTheme.TextSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('لا توجد أوامر مهمة مسجلة حالياً', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, color: AppTheme.TextSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showNewMissionDialog,
              icon: const Icon(Icons.add),
              label: const Text('إصدار أول أمر مهمة', style: TextStyle(fontFamily: 'Tajawal')),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _programs.length,
      itemBuilder: (ctx, i) {
        final prog = _programs[i];
        final String title = (prog['Title'] ?? 'برنامج رقابي').toString();
        final String area = (prog['TargetArea'] ?? 'ولاية سطيف').toString();
        final String type = prog['Type'] == 'daily' ? 'يومي' : 'أسبوعي';
        final String focus = (prog['FocusPoints'] ?? 'مراقبة الممارسات التجارية').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.CardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: prog['Type'] == 'daily' ? const Color(0xFF0284C7).withValues(alpha: 0.2) : const Color(0xFFD97706).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'أمر مهمة $type',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: prog['Type'] == 'daily' ? const Color(0xFF38BDF8) : const Color(0xFFFCD34D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    prog['WeekDate']?.toString() ?? 'اليوم',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.AccentColor),
                  const SizedBox(width: 4),
                  Text('القطاع المستهدف: $area', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'التعليمات: $focus',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisitsValidationTab() {
    if (_todayVisits.isEmpty) {
      return const Center(
        child: Text('لم يتم رفع أي زيارات ميدانية بعد لليوم', style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.TextSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _todayVisits.length,
      itemBuilder: (ctx, i) {
        final v = _todayVisits[i];
        final String shop = (v['ShopName'] ?? v['TraderName'] ?? 'محل تجاري').toString();
        final String inspector = v['NomAr'] != null ? '${v['NomAr']} ${v['PrenomAr']}' : (v['EmployeeName']?.toString() ?? 'مفتش ميداني');
        final String time = v['CheckInTime'] != null ? v['CheckInTime'].toString() : '';

        return InkWell(
          onTap: () => _showVisitDetailsModal(v),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.CardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.BorderColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.PrimaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, color: AppTheme.PrimaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('بواسطة: $inspector', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time.length >= 16 ? time.substring(11, 16) : time,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.AccentColor),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInspectorsPresenceTab() {
    if (_inspectors.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات أعوان مسجلة', style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.TextSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inspectors.length,
      itemBuilder: (ctx, i) {
        final emp = _inspectors[i];
        final bool isPresent = emp['hasCheckedIn'] == true;
        final bool isOut = emp['isCheckedOut'] == true;
        final String name = (emp['name'] ?? 'مفتش').toString();
        final String grade = (emp['grade'] ?? 'مفتش رئيسي').toString();
        final int visitsCount = (emp['visitsCount'] as num?)?.toInt() ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.CardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPresent
                  ? AppTheme.SuccessColor.withValues(alpha: 0.3)
                  : AppTheme.BorderColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isPresent ? AppTheme.SuccessColor : Colors.grey).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: isPresent ? AppTheme.SuccessColor : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('$grade • $visitsCount معاينات منجزة', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOut
                      ? const Color(0xFF6B7280).withValues(alpha: 0.2)
                      : (isPresent ? AppTheme.SuccessColor.withValues(alpha: 0.2) : AppTheme.WarningColor.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOut ? 'انصرف' : (isPresent ? 'في الميدان' : 'غير ملتحق'),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOut ? Colors.grey : (isPresent ? AppTheme.SuccessColor : AppTheme.WarningColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
