import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
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
  List<Map<String, dynamic>> _departmentInspectors = [];
  String _departmentName = '';
  String _inspectorSearchQuery = '';
  String _selectedBrigadeFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      final auth = context.read<AuthService>();
      final user = auth.currentUser;
      final api = auth.api;

      // Determine Department Name from user role or service
      if (user?.serviceName != null && user!.serviceName!.isNotEmpty) {
        _departmentName = user.serviceName!;
      } else if (user?.username == 'chef_concurrence') {
        _departmentName = 'مصلحة المنافسة والتحقيقات الاقتصادية';
      } else {
        _departmentName = 'مصلحة حماية المستهلك وقمع الغش';
      }

      // Fetch programs, visits and employees
      final progs = await api.getPrograms(service: _departmentName);
      final visits = await api.getTodayVisits();
      final allEmployees = await api.getEmployees(department: _departmentName);
      final mapData = await api.getMapData();

      // Build Map for fast attendance & visit lookup
      final mapLookup = {for (var m in mapData) m['id']: m};

      final List<Map<String, dynamic>> deptList = [];
      for (final emp in allEmployees) {
        final id = emp['Id'] as int;
        final liveInfo = mapLookup[id];
        final fullName = '${emp['NomAr'] ?? emp['Nom'] ?? ''} ${emp['PrenomAr'] ?? emp['Prenom'] ?? ''}'.trim();
        
        deptList.add({
          'id': id,
          'name': fullName.isNotEmpty ? fullName : 'مفتش #$id',
          'grade': emp['Grade'] ?? emp['FonctionExercee'] ?? 'مفتش رئيسي للرقابة',
          'service': emp['Service'] ?? _departmentName,
          'brigade': emp['BrigadeName'] ?? 'فرقة الرقابة والتفتيش 01',
          'isBrigadeLeader': emp['IsBrigadeLeader'] == true || emp['IsBrigadeLeader'] == 1,
          'administrativeStatus': emp['AdministrativeStatus'] ?? 'active',
          'hasCheckedIn': liveInfo != null ? (liveInfo['hasCheckedIn'] == true) : false,
          'isCheckedOut': liveInfo != null ? (liveInfo['isCheckedOut'] == true) : false,
          'visitsCount': liveInfo != null ? ((liveInfo['visitsCount'] as num?)?.toInt() ?? 0) : 0,
          'location': liveInfo?['location'] ?? 'المقر الرئيسي للمديرية',
          'checkInTime': liveInfo?['checkInTime'],
        });
      }

      if (mounted) {
        setState(() {
          _programs = progs;
          _todayVisits = visits.where((v) {
            final s = v['Service']?.toString() ?? '';
            return s.isEmpty || s.contains(_departmentName) || _departmentName.contains(s);
          }).toList();
          _departmentInspectors = deptList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditBrigadeDialog(Map<String, dynamic> inspector) {
    final name = (inspector['name'] ?? 'مفتش').toString();
    final int id = inspector['id'] as int;
    String currentBrigade = inspector['brigade']?.toString() ?? 'فرقة التدخل 01 (حي تبيانت والمركز)';
    bool isLeader = inspector['isBrigadeLeader'] == true;

    final defaultBrigades = [
      'فرقة التدخل 01 (حي تبيانت والمركز)',
      'فرقة التدخل 02 (المعبودة وسوق الجملة)',
      'فرقة التدخل 03 (الهضاب والقطاع الشرقي)',
      'فرقة التدخل 04 (المنطقة الحضرية الجديدة)',
      'فرقة التحقيقات والفوترة ومسارات التوزيع',
      'فرقة سحب العينات والمطابقة المخبرية',
      'فرقة المداومة والمناوبة المسائية',
      'احتياط المصلحة (بدون تعيين ميداني)',
    ];

    if (!defaultBrigades.contains(currentBrigade) && currentBrigade.isNotEmpty) {
      defaultBrigades.insert(0, currentBrigade);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.CardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.groups, color: AppTheme.AccentColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تعديل تشكيل الفرقة وتعيين الثنائي',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      name,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تعيين الفرقة الرقابية والقطاع الجغرافي:',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: defaultBrigades.contains(currentBrigade) ? currentBrigade : defaultBrigades.first,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.shield, color: AppTheme.AccentColor, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                    items: defaultBrigades.map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(b, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => currentBrigade = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تعيين كرئيس فرقة (Chef de brigade)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('يتولى قيادة الثنائي وتنسيق المحاضر الميدانية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary)),
                    value: isLeader,
                    activeThumbColor: AppTheme.AccentColor,
                    onChanged: (val) => setModalState(() => isLeader = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthService>();
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await auth.api.updateEmployeeAdminStatus(id, {
                    'brigadeName': currentBrigade,
                    'isBrigadeLeader': isLeader,
                    'assignedDepartment': _departmentName,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAllData();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ تم تحديث تشكيل الفرقة وتعيين $name بنجاح', style: const TextStyle(fontFamily: 'Tajawal')),
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
              icon: const Icon(Icons.check, size: 16),
              label: const Text('حفظ التشكيل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewMissionDialog() {
    final titleCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'بلديات سطيف والعلمة وعين ولمان');
    final focusCtrl = TextEditingController();
    
    // Official Algerian Program Categories
    String programCategory = 'برنامج قطاعي وطني مسطر (وزاري / ولائي)';
    String targetActivity = 'تجار التجزئة والسوبرماركت';
    String programDuration = 'daily';
    
    // Assignment Mode: 'brigade' (default), 'all', 'inspector'
    String assignmentMode = 'brigade';
    String? selectedBrigadeName;
    int? selectedInspectorId;

    // Build Brigade Map from department inspectors
    final Map<String, List<Map<String, dynamic>>> brigadesMap = {};
    for (final emp in _departmentInspectors) {
      final b = (emp['brigade'] ?? 'فرقة التدخل 01 (حي تبيانت والمركز)').toString().trim();
      if (b.isNotEmpty) brigadesMap.putIfAbsent(b, () => []).add(emp);
    }
    if (brigadesMap.isNotEmpty) {
      selectedBrigadeName = brigadesMap.keys.first;
    }

    if (_departmentName.contains('المنافسة')) {
      titleCtrl.text = 'مراقبة احترام الأسعار المقننة وهوامش الربح والفوترة';
      focusCtrl.text = 'التأكد من إشهار الأسعار، فواتير التوزيع لمادتي الزيت والحليب، ومكافحة المضاربة';
    } else {
      titleCtrl.text = 'مراقبة شروط النظافة الصحية ومطابقة المواد الغذائية الحساسة';
      focusCtrl.text = 'مراقبة سلسلة التبريد، شروط حفظ اللحوم والمشتقات اللبنية، وسحب عينات مخبرية';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.CardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.assignment_add, color: AppTheme.AccentColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إصدار أمر مهمة رقابية لفرق المفتشين',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _departmentName,
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program Category Dropdown
                  const Text(
                    'نوع البرنامج الرقابي القانوني:',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: programCategory,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category, color: AppTheme.AccentColor, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'برنامج قطاعي وطني مسطر (وزاري / ولائي)',
                        child: Text('برنامج قطاعي وطني مسطر (وزاري / ولائي)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'برنامج التدخل الميداني الدوري (مراقبة اعتيادية)',
                        child: Text('برنامج التدخل الميداني الدوري (مراقبة اعتيادية)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'تحقيقات اقتصادية وتتبع مسالك التوزيع والفوترة',
                        child: Text('تحقيقات اقتصادية وتتبع مسالك التوزيع', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'برنامج سحب العينات والتحاليل المخبرية (CACQE)',
                        child: Text('برنامج سحب العينات والتحاليل المخبرية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'تدخل استعجالي وشكاوى المستهلكين والإخطارات',
                        child: Text('تدخل استعجالي وشكاوى المستهلكين', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'لجنة ولائية مشتركة (بيطرة / أمن / صحة)',
                        child: Text('لجنة ولائية مشتركة (بيطرة / أمن / صحة)', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => programCategory = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Assignment Scope Mode Choice Chips
                  const Text(
                    'نطاق وتوجيه المهمة الرقابية:',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          avatar: const Icon(Icons.groups, size: 16),
                          label: const Text('تكليف فرقة كاملة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
                          selected: assignmentMode == 'brigade',
                          selectedColor: AppTheme.AccentColor,
                          backgroundColor: const Color(0xFF1E0B26),
                          onSelected: (sel) {
                            if (sel) setModalState(() => assignmentMode = 'brigade');
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          avatar: const Icon(Icons.public, size: 16),
                          label: const Text('تعميم شامل للمصلحة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
                          selected: assignmentMode == 'all',
                          selectedColor: AppTheme.AccentColor,
                          backgroundColor: const Color(0xFF1E0B26),
                          onSelected: (sel) {
                            if (sel) setModalState(() => assignmentMode = 'all');
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: const Text('تكليف مفتش فردي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11)),
                          selected: assignmentMode == 'inspector',
                          selectedColor: AppTheme.AccentColor,
                          backgroundColor: const Color(0xFF1E0B26),
                          onSelected: (sel) {
                            if (sel) setModalState(() => assignmentMode = 'inspector');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Assignment Dynamic Selector
                  if (assignmentMode == 'brigade') ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedBrigadeName,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2D1035),
                      decoration: InputDecoration(
                        labelText: 'اختر الفرقة الرقابية المكلفة بالتنفيذ',
                        prefixIcon: const Icon(Icons.shield, color: AppTheme.AccentColor, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFF1E0B26),
                      ),
                      items: brigadesMap.entries.map((entry) {
                        final bName = entry.key;
                        final members = entry.value;
                        final leader = members.firstWhere(
                          (m) => m['isBrigadeLeader'] == true,
                          orElse: () => members.first,
                        );
                        final leaderName = (leader['name'] ?? 'رئيس الفرقة').toString();
                        return DropdownMenuItem(
                          value: bName,
                          child: Text(
                            '$bName (${members.length} أعضاء • بقيادة: $leaderName)',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedBrigadeName = val),
                    ),
                  ] else if (assignmentMode == 'all') ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign, color: Color(0xFFD4AF37), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سيتم إرسال هذا الأمر إلى كافة الفرق الرقابية الـ (${brigadesMap.length} فرق) بالمصلحة دفعة واحدة.',
                              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFD4AF37)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<int?>(
                      initialValue: selectedInspectorId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2D1035),
                      decoration: InputDecoration(
                        labelText: 'اختر المفتش المكلف',
                        prefixIcon: const Icon(Icons.badge, color: AppTheme.AccentColor, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: const Color(0xFF1E0B26),
                      ),
                      items: _departmentInspectors.map((insp) {
                        final id = insp['id'] as int;
                        final name = insp['name'] as String;
                        final grade = insp['grade'] as String;
                        return DropdownMenuItem(
                          value: id,
                          child: Text('$name ($grade)', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12), overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedInspectorId = val),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Title
                  TextField(
                    controller: titleCtrl,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'موضوع المهمة وأمر التكليف *',
                      prefixIcon: const Icon(Icons.title, color: AppTheme.AccentColor, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Target Area
                  TextField(
                    controller: areaCtrl,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'الإقليم والبلديات المستهدفة *',
                      hintText: 'مثال: بلدية سطيف، العلمة، عين ولمان، بوقاعة',
                      prefixIcon: const Icon(Icons.location_on, color: AppTheme.AccentColor, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Target Activity
                  DropdownButtonFormField<String>(
                    initialValue: targetActivity,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    decoration: InputDecoration(
                      labelText: 'طبيعة الأنشطة المستهدفة بالمعاينة',
                      prefixIcon: const Icon(Icons.storefront, color: AppTheme.AccentColor, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'تجار التجزئة والسوبرماركت', child: Text('تجار التجزئة والمحلات التجارية', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'أسواق الجملة للخضر والفواكه والمواد الغذائية', child: Text('أسواق الجملة ومستودعات التخزين', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'المخابز ومحلات صناعة الحلويات', child: Text('المخابز ومحلات الحلويات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'المذابح وتجار اللحوم البيضاء والحمراء والقصابات', child: Text('المذابح وتجار اللحوم والقصابات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'وحدات الإنتاج والتحويل الصناعي للمواد الاستهلاكية', child: Text('وحدات الإنتاج والتحويل الصناعي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                      DropdownMenuItem(value: 'المستوردين والموزعين المعتمدين والمستودعات', child: Text('المستوردين والموزعين والمستودعات', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => targetActivity = val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Focus Instructions
                  TextField(
                    controller: focusCtrl,
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'النقاط البؤرية والتعليمات الرقابية الميدانية',
                      prefixIcon: const Icon(Icons.rule, color: AppTheme.AccentColor, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFF1E0B26),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Duration choice
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('أمر مهمة يومي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                          selected: programDuration == 'daily',
                          selectedColor: AppTheme.AccentColor,
                          onSelected: (selected) {
                            if (selected) setModalState(() => programDuration = 'daily');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('برنامج رقابي أسبوعي', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12))),
                          selected: programDuration == 'weekly',
                          selectedColor: AppTheme.AccentColor,
                          onSelected: (selected) {
                            if (selected) setModalState(() => programDuration = 'weekly');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final auth = context.read<AuthService>();
                final user = auth.currentUser;
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final api = auth.api;
                  String assignmentTag = '[تعميم على كافة الفرق]';
                  String successMessage = '✅ تم اعتماد وتعميم أمر المهمة الرقابية على كافة فرق المفتشين بنجاح';

                  if (assignmentMode == 'brigade') {
                    final bName = selectedBrigadeName ?? 'فرقة الرقابة';
                    final members = brigadesMap[bName] ?? [];
                    assignmentTag = '[المكلف: $bName (${members.length} أعضاء)]';
                    successMessage = '✅ تم إصدار أمر المهمة وتكليف $bName بكافة أعضائها بنجاح';
                  } else if (assignmentMode == 'inspector' && selectedInspectorId != null) {
                    final assignedEmp = _departmentInspectors.firstWhere(
                      (e) => e['id'] == selectedInspectorId,
                      orElse: () => {'name': 'المفتش #$selectedInspectorId'},
                    );
                    final String assignedName = (assignedEmp['name'] ?? 'المفتش').toString();
                    assignmentTag = '[المكلف: $assignedName]';
                    successMessage = '✅ تم إصدار أمر المهمة وتكليف المفتش: $assignedName بنجاح';
                  }

                  final fullTitle = '[$programCategory] $assignmentTag ${titleCtrl.text.trim()}';
                  await api.createProgram(
                    title: fullTitle,
                    targetArea: areaCtrl.text.trim(),
                    targetType: targetActivity,
                    focusPoints: focusCtrl.text.trim(),
                    type: programDuration,
                    serviceName: _departmentName,
                    createdBy: user?.id,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadAllData();

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        successMessage,
                        style: const TextStyle(fontFamily: 'Tajawal'),
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
              label: const Text('إصدار واعتماد الأمر', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showVisitDetailsModal(Map<String, dynamic> visit) {
    final String shop = (visit['ShopName'] ?? visit['TraderName'] ?? 'معاينة تفتيشية').toString();
    final String inspectorName = visit['NomAr'] != null ? '${visit['NomAr']} ${visit['PrenomAr'] ?? ''}'.trim() : (visit['EmployeeName']?.toString() ?? 'المفتش');
    final String time = visit['CheckInTime'] != null ? visit['CheckInTime'].toString() : '';
    final String? photoBase64 = visit['Photo']?.toString();
    final dynamic lat = visit['Latitude'];
    final dynamic lng = visit['Longitude'];
    final String notes = (visit['Notes'] ?? 'معاينة ميدانية ومطابقة الشروط').toString();
    final bool hasViolation = visit['ViolationFound'] == true || visit['ViolationFound'] == 1;
    final String? violationType = visit['ViolationType']?.toString();
    final String? violationNotes = visit['ViolationNotes']?.toString();
    final String? legalAction = visit['LegalAction']?.toString();
    final dynamic seizureVal = visit['SeizureValue'];
    final bool isApproved = visit['IsApproved'] == true || visit['IsApproved'] == 1;
    final int? visitId = (visit['Id'] as num?)?.toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.CardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
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
                      decoration: BoxDecoration(
                        color: hasViolation ? Colors.red.withValues(alpha: 0.15) : AppTheme.PrimaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasViolation ? Icons.warning_amber_rounded : Icons.verified_user,
                        color: hasViolation ? Colors.redAccent : AppTheme.PrimaryColor,
                        size: 24,
                      ),
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
                      decoration: BoxDecoration(
                        color: isApproved ? AppTheme.SuccessColor.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isApproved ? '✅ معتمدة ومؤشرة' : '⏳ قيد التأشير',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: isApproved ? AppTheme.SuccessColor : Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (photoBase64 != null && photoBase64.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(photoBase64),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                // Violation and Legal action card
                if (hasViolation) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gavel, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'طبيعة المخالفة: ${violationType ?? 'مخالفة مرصودة'}',
                                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                        if (legalAction != null && legalAction.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('الإجراء القانوني: $legalAction', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFF93C5FD), fontWeight: FontWeight.bold)),
                        ],
                        if (seizureVal != null && (double.tryParse(seizureVal.toString()) ?? 0) > 0) ...[
                          const SizedBox(height: 4),
                          Text('القيمة التقديرية للمحجوزات: $seizureVal د.ج', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFFFCD34D), fontWeight: FontWeight.bold)),
                        ],
                        if (violationNotes != null && violationNotes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('تفاصيل المخالفة: $violationNotes', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70)),
                        ],
                      ],
                    ),
                  ),
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
                              'violation': violationType ?? 'مطابقة',
                              'action': legalAction ?? 'مطابقة وتوعية',
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
                        onPressed: isApproved || visitId == null
                            ? null
                            : () async {
                                final user = context.read<AuthService>().currentUser;
                                final api = context.read<AuthService>().api;
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  await api.approveVisit(
                                    visitId: visitId,
                                    approvedBy: user?.fullName ?? _departmentName,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) _loadAllData();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ تم تأشير واعتماد تقرير المعاينة رسمياً بنجاح', style: TextStyle(fontFamily: 'Tajawal')),
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
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          isApproved ? 'معتمدة ومؤشرة' : 'تأشير واعتماد',
                          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isApproved ? Colors.grey.shade700 : AppTheme.SuccessColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.CardColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _departmentName,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'المسؤول: ${user?.fullName ?? user?.username ?? ''}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_task, color: AppTheme.AccentColor),
              tooltip: 'إصدار أمر مهمة جديد',
              onPressed: _showNewMissionDialog,
            ),
            IconButton(
              icon: const Icon(Icons.qr_code, color: AppTheme.AccentColor),
              tooltip: 'رمز الحضور الرسمي للمصلحة',
              onPressed: () {
                QRCodeScreen.show(
                  context,
                  record: {
                    'type': 'DCW_SETIF_OFFICIAL_CHECKPOINT',
                    'employeeName': _departmentName,
                    'date': DateTime.now().toIso8601String().split('T')[0],
                    'latitude': AppConstants.hqLatitude,
                    'longitude': AppConstants.hqLongitude,
                  },
                  title: 'رمز الحضور الرسمي — $_departmentName',
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
              Tab(icon: Icon(Icons.people_alt), text: 'مفتشو المصلحة'),
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
    return Column(
      children: [
        // Top Permanent Header Toolbar (Never disappears on any phone!)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1E0B26),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'أوامر المهمة والبرامج الميدانية',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'إجمالي الأوامر المسجلة: ${_programs.length}',
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showNewMissionDialog,
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text(
                  'أمر مهمة جديد',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.AccentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // List of Missions
        Expanded(
          child: _programs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined, size: 60, color: AppTheme.TextSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('لا توجد أوامر مهمة مسجلة لـ $_departmentName', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, color: AppTheme.TextSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showNewMissionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('إصدار أول أمر مهمة', style: TextStyle(fontFamily: 'Tajawal')),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.AccentColor, foregroundColor: Colors.black),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _programs.length,
                  itemBuilder: (ctx, i) {
                    final prog = _programs[i];
                    final String title = (prog['Title'] ?? 'برنامج رقابي').toString();
                    final String area = (prog['TargetArea'] ?? 'ولاية سطيف').toString();
                    final String type = prog['Type'] == 'daily' ? 'يومي' : 'أسبوعي';
                    final String focus = (prog['FocusPoints'] ?? 'مراقبة الممارسات التجارية').toString();

                    // Parse assigned badge if present in title
                    String? assignedBadge;
                    if (title.contains('[المكلف:')) {
                      final start = title.indexOf('[المكلف:');
                      final end = title.indexOf(']', start);
                      if (end != -1) {
                        assignedBadge = title.substring(start + 1, end).replaceAll('المكلف:', '').trim();
                      }
                    } else if (title.contains('[تعميم على كافة الفرق]')) {
                      assignedBadge = 'تعميم شامل على المصلحة';
                    }

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
                              if (assignedBadge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_pin, size: 12, color: Color(0xFFD4AF37)),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignedBadge,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 10,
                                          color: Color(0xFFD4AF37),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.AccentColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('القطاع المستهدف: $area', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis),
                              ),
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
                ),
        ),
      ],
    );
  }

  Widget _buildVisitsValidationTab() {
    if (_todayVisits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fact_check_outlined, size: 50, color: Colors.white24),
            const SizedBox(height: 12),
            Text('لم يتم رفع أي زيارات ميدانية بعد لـ $_departmentName اليوم', style: const TextStyle(fontFamily: 'Tajawal', color: AppTheme.TextSecondary)),
          ],
        ),
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
    if (_departmentInspectors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 50, color: Colors.white24),
            const SizedBox(height: 12),
            Text('لا يوجد مفتشون مسجلون تابعون لـ $_departmentName', style: const TextStyle(fontFamily: 'Tajawal', color: AppTheme.TextSecondary)),
          ],
        ),
      );
    }

    // Extract unique brigade names for quick filter
    final brigadesSet = <String>{'الكل'};
    for (final emp in _departmentInspectors) {
      final b = (emp['brigade'] ?? '').toString().trim();
      if (b.isNotEmpty) brigadesSet.add(b);
    }

    // Filter by search & brigade
    final filtered = _departmentInspectors.where((emp) {
      final name = (emp['name'] ?? '').toString().toLowerCase();
      final brigade = (emp['brigade'] ?? '').toString();
      final grade = (emp['grade'] ?? '').toString().toLowerCase();
      final matchesSearch = _inspectorSearchQuery.isEmpty ||
          name.contains(_inspectorSearchQuery.toLowerCase()) ||
          grade.contains(_inspectorSearchQuery.toLowerCase()) ||
          brigade.toLowerCase().contains(_inspectorSearchQuery.toLowerCase());
      final matchesBrigade = _selectedBrigadeFilter == 'الكل' || brigade == _selectedBrigadeFilter;
      return matchesSearch && matchesBrigade;
    }).toList();

    return Column(
      children: [
        // Top Toolbar: Search + Brigade Filter
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E0B26),
          child: Column(
            children: [
              TextField(
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'بحث عن مفتش بالاسم، الرتبة أو الفرقة...',
                  hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.AccentColor, size: 20),
                  suffixIcon: _inspectorSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16, color: Colors.white60),
                          onPressed: () => setState(() => _inspectorSearchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2D1035),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _inspectorSearchQuery = val),
              ),
              const SizedBox(height: 8),
              // Brigade Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: brigadesSet.map((b) {
                    final isSelected = _selectedBrigadeFilter == b;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ChoiceChip(
                        label: Text(
                          b,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.AccentColor,
                        backgroundColor: const Color(0xFF2D1035),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedBrigadeFilter = b);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Inspectors List
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد نتائج مطابقة للبحث أو التصفية',
                    style: TextStyle(fontFamily: 'Tajawal', color: AppTheme.TextSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final emp = filtered[i];
                    final bool isPresent = emp['hasCheckedIn'] == true;
                    final bool isOut = emp['isCheckedOut'] == true;
                    final bool isLeader = emp['isBrigadeLeader'] == true;
                    final String name = (emp['name'] ?? 'مفتش').toString();
                    final String grade = (emp['grade'] ?? 'مفتش رئيسي').toString();
                    final String brigade = (emp['brigade'] ?? 'فرقة الرقابة').toString();
                    final int visitsCount = (emp['visitsCount'] as num?)?.toInt() ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.CardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLeader
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
                              : (isPresent ? AppTheme.SuccessColor.withValues(alpha: 0.3) : AppTheme.BorderColor.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Stack(
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
                                  if (isLeader)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFD4AF37),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.star, size: 10, color: Colors.black),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isLeader) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                                            ),
                                            child: const Text(
                                              'رئيس فرقة',
                                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 9, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$grade • $brigade',
                                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: AppTheme.TextSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isPresent) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'الموقع: ${emp['location']} • $visitsCount معاينات',
                                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Color(0xFF10B981)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isOut
                                          ? const Color(0xFF6B7280).withValues(alpha: 0.2)
                                          : (isPresent ? AppTheme.SuccessColor.withValues(alpha: 0.2) : AppTheme.WarningColor.withValues(alpha: 0.2)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isOut ? 'انصرف' : (isPresent ? 'في الميدان' : 'غير ملتحق'),
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isOut ? Colors.grey : (isPresent ? AppTheme.SuccessColor : AppTheme.WarningColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () => _showEditBrigadeDialog(emp),
                                    borderRadius: BorderRadius.circular(6),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit_note, size: 14, color: AppTheme.AccentColor),
                                          SizedBox(width: 2),
                                          Text(
                                            'تعديل التشكيل',
                                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppTheme.AccentColor, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
