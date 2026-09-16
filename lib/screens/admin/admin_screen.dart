import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/director/director_screen.dart';
import 'package:drh_setif_tracker/screens/head/head_screen.dart';
import 'package:drh_setif_tracker/screens/bureau/bureau_screen.dart';
import 'package:drh_setif_tracker/screens/inspector/inspector_screen.dart';
import 'package:drh_setif_tracker/screens/common/change_password_dialog.dart';
import 'package:drh_setif_tracker/screens/common/app_footer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drh_setif_tracker/utils/constants.dart';
import 'package:drh_setif_tracker/services/inspectorate_service.dart';
import 'package:drh_setif_tracker/screens/common/qr_code_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _employees = [];
  String _morningGraceTime = '08:45';
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _tabIndex = _tabController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthService>().api;
      List<Map<String, dynamic>> usersList = [];
      List<Map<String, dynamic>> employeesList = [];
      Map<String, dynamic> settingsMap = {};

      try {
        usersList = await api.getSystemUsers();
      } catch (_) {}

      try {
        employeesList = await api.getEmployees(all: true);
      } catch (_) {}

      try {
        settingsMap = await api.getSettings();
      } catch (_) {}

      try {
        await InspectorateService.instance.loadInspectorates(api: api);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _users = usersList;
          _employees = employeesList;
          _morningGraceTime = (settingsMap['morning_grace_time'] ?? '08:45').toString();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final effectiveUsers = _users.isNotEmpty
        ? _users
        : _employees.map((e) {
            final id = e['Id'] ?? e['id'] ?? 0;
            final nomAr = e['NomAr'] ?? e['nomar'] ?? e['Nom'] ?? '';
            final prenomAr = e['PrenomAr'] ?? e['prenomar'] ?? e['Prenom'] ?? '';
            final nom = (e['Nom'] ?? e['nom'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            final prenom = (e['Prenom'] ?? e['prenom'] ?? '').toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            final username = prenom.isNotEmpty && nom.isNotEmpty ? '$prenom.$nom' : 'emp.$id';
            final fonction = (e['FonctionExercee'] ?? e['fonctionexercee'] ?? '').toString().trim();
            final service = (e['Service'] ?? e['service'] ?? '').toString();
            final grade = (e['Grade'] ?? e['grade'] ?? '').toString();

            // Accurate administrative role mapping:
            // - "رئيس مصلحة" -> Head of Department
            // - "رئيس مكتب" -> Bureau Chief
            // - "مدير ولائي" / "مدير التجارة" -> Director
            // - "رئيس فرقة" / "عضو فرقة" / "مفتش رئيسي" / "مفتش رئيسي لقمع الغش" -> Inspector (مفتش ميداني)
            String role = 'inspector';
            if (fonction.contains('رئيس مصلحة') || fonction.contains('chef de service')) {
              role = 'head_of_department';
            } else if (fonction.contains('رئيس مكتب') || fonction.contains('chef de bureau')) {
              role = 'bureau_chief';
            } else if (fonction.contains('مدير ولائي') || fonction.contains('مدير التجارة') || fonction == 'مدير') {
              role = 'director';
            }

            return {
              'id': id,
              'username': username,
              'fullName': '$nomAr $prenomAr'.trim().isNotEmpty ? '$nomAr $prenomAr'.trim() : 'موظف $id',
              'role': role,
              'isActive': true,
              'employeeId': id,
              'empNom': e['Nom'] ?? e['nom'],
              'empPrenom': e['Prenom'] ?? e['prenom'],
              'empService': service,
              'empGrade': grade,
              'fonction': fonction,
            };
          }).toList();

    return effectiveUsers.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          (u['username'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['fullName'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['empNom'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['empPrenom'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _filterRole == 'all' ||
          u['role'] == _filterRole ||
          (_filterRole == 'inactive' && u['isActive'] == false);

      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showAddUserDialog() {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: '123456');
    final fullNameCtrl = TextEditingController();
    String selectedRole = 'inspector';
    int? selectedEmpId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF240D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4A2050)),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFFD4AF37)),
              SizedBox(width: 10),
              Text(
                'إضافة مستخدم جديد للنظام',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'اسم المستخدم (Login Username)',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.account_circle, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور الابتدائية',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.lock, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fullNameCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'الاسم واللقب الكامل',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.badge, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'صلاحية / دور المستخدم',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.security, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'inspector', child: Text('مفتش ميداني (Inspector)')),
                      DropdownMenuItem(value: 'head_of_department', child: Text('رئيس مصلحة (Head of Service)')),
                      DropdownMenuItem(value: 'bureau_chief', child: Text('رئيس مكتب المستخدمين (Bureau Chief)')),
                      DropdownMenuItem(value: 'director', child: Text('المدير الولائي (Director)')),
                      DropdownMenuItem(value: 'admin', child: Text('مسؤول النظام (Admin)')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val ?? 'inspector'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedEmpId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'ربط بالموظف من القائمة (اختياري)',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.link, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بدون ربط (حساب إداري عام)')),
                      ..._employees.map((e) {
                        final id = e['Id'] as int;
                        final name = '${e['Nom'] ?? ''} ${e['Prenom'] ?? ''}'.trim();
                        final service = e['Service'] ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text('$name ($service)', overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        selectedEmpId = val;
                        if (val != null) {
                          final emp = _employees.firstWhere((e) => e['Id'] == val, orElse: () => {});
                          if (emp.isNotEmpty && fullNameCtrl.text.isEmpty) {
                            fullNameCtrl.text = '${emp['Nom'] ?? ''} ${emp['Prenom'] ?? ''}'.trim();
                          }
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF881337),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (usernameCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final api = context.read<AuthService>().api;
                Navigator.pop(ctx);
                try {
                  final res = await api.createSystemUser(
                    username: usernameCtrl.text.trim(),
                    password: passwordCtrl.text.trim(),
                    fullName: fullNameCtrl.text.trim().isNotEmpty ? fullNameCtrl.text.trim() : usernameCtrl.text.trim(),
                    role: selectedRole,
                    employeeId: selectedEmpId,
                  );
                  _loadData();
                  messenger.showSnackBar(
                    SnackBar(content: Text(res['message']?.toString() ?? 'تم الحفظ'), backgroundColor: const Color(0xFF10B981)),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              },
              child: const Text('إنشاء الحساب', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final fullNameCtrl = TextEditingController(text: user['fullName']?.toString() ?? '');
    String selectedRole = user['role']?.toString() ?? 'inspector';
    bool isActive = user['isActive'] == true;
    int? selectedEmpId = user['employeeId'] is int ? user['employeeId'] as int : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF240D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF4A2050)),
          ),
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFFD4AF37)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'تعديل حساب: ${user['username']}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: fullNameCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'الاسم واللقب الكامل',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.badge, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'صلاحية / دور المستخدم',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.security, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'inspector', child: Text('مفتش ميداني (Inspector)')),
                      DropdownMenuItem(value: 'head_of_department', child: Text('رئيس مصلحة (Head of Service)')),
                      DropdownMenuItem(value: 'bureau_chief', child: Text('رئيس مكتب المستخدمين (Bureau Chief)')),
                      DropdownMenuItem(value: 'director', child: Text('المدير الولائي (Director)')),
                      DropdownMenuItem(value: 'admin', child: Text('مسؤول النظام (Admin)')),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val ?? 'inspector'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedEmpId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2D1035),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'ربط بالموظف من القائمة',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.link, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بدون ربط (حساب عام)')),
                      ..._employees.map((e) {
                        final id = e['Id'] as int;
                        final name = '${e['Nom'] ?? ''} ${e['Prenom'] ?? ''}'.trim();
                        final service = e['Service'] ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text('$name ($service)', overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ],
                    onChanged: (val) => setDialogState(() => selectedEmpId = val),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text(
                      isActive ? 'الحساب نشط (Active)' : 'الحساب موقوف / مجمّد (Suspended)',
                      style: TextStyle(
                         fontFamily: 'Tajawal',
                        color: isActive ? const Color(0xFF10B981) : AppTheme.DangerColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    inactiveThumbColor: AppTheme.DangerColor,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF881337),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final api = context.read<AuthService>().api;
                Navigator.pop(ctx);
                try {
                  final res = await api.updateSystemUser(
                    id: user['id'] as int,
                    fullName: fullNameCtrl.text.trim().isNotEmpty ? fullNameCtrl.text.trim() : (user['username']?.toString() ?? ''),
                    role: selectedRole,
                    isActive: isActive,
                    employeeId: selectedEmpId,
                  );
                  _loadData();
                  messenger.showSnackBar(
                    SnackBar(content: Text(res['message']?.toString() ?? 'تم تحديث الحساب بنجاح'), backgroundColor: const Color(0xFF10B981)),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              },
              child: const Text('حفظ التعديلات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    if (user['username'] == 'tracker_admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف الحساب الرئيسي لمدير النظام'),
          backgroundColor: AppTheme.DangerColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.DangerColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppTheme.DangerColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'حذف الحساب نهائياً: ${user['username']}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف حساب (${user['fullName'] ?? user['username']}) نهائياً من النظام؟ لا يمكن التراجع عن هذه الخطوة.',
          style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.DangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = context.read<AuthService>().api;
                final res = await api.deleteSystemUser(user['id'] as int);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message']?.toString() ?? 'تم حذف الحساب بنجاح'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              }
            },
            child: const Text('نعم، حذف الحساب', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final newPassCtrl = TextEditingController(text: '123456');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4A2050)),
        ),
        title: Row(
          children: [
            const Icon(Icons.key, color: Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'إعادة تعيين كلمة مرور: ${user['username']}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المستخدم: ${user['fullName'] ?? user['username']}',
              style: const TextStyle(color: Colors.white70, fontFamily: 'Tajawal', fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Color(0xFF1E0B26),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF881337),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (newPassCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                final api = context.read<AuthService>().api;
                final res = await api.resetUserPassword(
                  id: user['id'] as int,
                  newPassword: newPassCtrl.text.trim(),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message']?.toString() ?? 'تم التعيين بنجاح'), backgroundColor: const Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              }
            },

            child: const Text('حفظ كلمة المرور', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBulkGenerateDialog() {
    final passCtrl = TextEditingController(text: 'Setif@2025');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text(
              'توليد حسابات لجميع الموظفين الـ 267',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تقوم هذه الميزة بالتحقق من جميع الموظفين في قاعدة البيانات وإنشاء اسم مستخدم وكلمة مرور تلقائية لكل موظف ليس لديه حساب بعد.',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الافتراضية الموحدة',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.password, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Color(0xFF1E0B26),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF1A0A1F),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final api = context.read<AuthService>().api;
                final res = await api.generateAllEmployeeAccounts(defaultPassword: passCtrl.text.trim());
                await _loadData();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF240D2D),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('تمت العملية بنجاح', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
                        ],
                      ),
                      content: Text(
                        res['message']?.toString() ?? 'تم إنشاء الحسابات بنجاح',
                        style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('حسناً', style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFFD4AF37))),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              }
            },
            child: const Text('بدء التوليد التلقائي', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCleanDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.DangerColor),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.DangerColor),
            SizedBox(width: 10),
            Text(
              'تصفير سجلات الاختبار والتجارب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف جميع سجلات الحضور، الانصراف، المعاينات، والخصومات التجريبية السابقة للبدء الميداني النظيف؟ (لن يتم المساس بقائمة الموظفين أو الحسابات).',
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.DangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final api = context.read<AuthService>().api;
                final res = await api.cleanTestData();
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message']?.toString() ?? 'تم تصفير السجلات بنجاح'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                  );
                }
              }
            },
            child: const Text('نعم، تصفير السجلات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageProvider>().isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF260D2E), Color(0xFF16061D)],
              ),
              border: const Border(
                bottom: BorderSide(
                  color: Color(0x33D4AF37),
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          titleSpacing: 12,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/gold_coin_floating.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/images/gold_emblem.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Flexible(
                          child: Text(
                            'الإدارة التقنية للمنظومة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'Admin',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'التحكم في الخوادم وقواعد البيانات والمستخدمين',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37), size: 18),
                    tooltip: 'تحديث البيانات',
                    onPressed: _loadData,
                  ),
                  Container(width: 1, height: 16, color: Colors.white12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37), size: 18),
                    tooltip: 'تغيير كلمة المرور',
                    onPressed: () => ChangePasswordDialog.show(context),
                  ),
                  Container(width: 1, height: 16, color: Colors.white12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.language, color: Colors.white70, size: 18),
                    tooltip: 'تغيير اللغة',
                    onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
                  ),
                  Container(width: 1, height: 16, color: Colors.white12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () {
                      context.read<AuthService>().logout();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            onTap: (index) {
              setState(() => _tabIndex = index);
            },
            tabs: const [
              Tab(icon: Icon(Icons.people_alt, size: 18), text: 'المستخدمين والحسابات'),
              Tab(icon: Icon(Icons.location_on, size: 18), text: 'المقرات والبصمة الجغرافية'),
              Tab(icon: Icon(Icons.dns, size: 18), text: 'حالة النظام والسيرفر'),
              Tab(icon: Icon(Icons.preview, size: 18), text: 'معاينة شاشات الأدوار'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              )
            : _buildActiveTab(),
        bottomNavigationBar: const AppFooter(),
      ),
    );
  }

  Widget _buildActiveTab() {
    switch (_tabIndex) {
      case 0:
        return _buildUsersTab();
      case 1:
        return _buildInspectoratesTab();
      case 2:
        return _buildSystemHealthTab();
      case 3:
        return _buildRolePreviewTab();
      default:
        return _buildUsersTab();
    }
  }

  Widget _buildUsersTab() {
    final activeCount = _users.where((u) => u['isActive'] == true).length;
    final inspectorsCount = _users.where((u) => u['role'] == 'inspector').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row (Horizontally scrollable for all screens)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatCard('إجمالي الحسابات', '${_users.length}', Icons.account_circle, const Color(0xFF881337)),
                  const SizedBox(width: 8),
                  _buildStatCard('الحسابات النشطة', '$activeCount', Icons.check_circle, const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildStatCard('المفتشون الميدانيون', '$inspectorsCount', Icons.explore, const Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  _buildStatCard('إجمالي الموظفين', '${_employees.length}', Icons.badge, const Color(0xFF3B82F6)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons Bar (Responsive Wrap)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _showBulkGenerateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1A0A1F),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text(
                    'توليد حسابات لجميع الـ 267 موظفاً',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF881337),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'إضافة مستخدم جديد',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search and Filter
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'بحث باسم المستخدم أو الاسم أو اللقب...',
                          hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Tajawal', fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37), size: 18),
                          filled: true,
                          fillColor: const Color(0xFF240D2D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF4A2050)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF4A2050)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF240D2D),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF4A2050)),
                        ),
                        child: DropdownButton<String>(
                          value: _filterRole,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2D1035),
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontSize: 12),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('جميع الأدوار')),
                            DropdownMenuItem(value: 'inspector', child: Text('المفتشون فقط')),
                            DropdownMenuItem(value: 'head_of_department', child: Text('رؤساء المصالح')),
                            DropdownMenuItem(value: 'bureau_chief', child: Text('رئيس مكتب المستخدمين')),
                            DropdownMenuItem(value: 'director', child: Text('المدير الولائي')),
                            DropdownMenuItem(value: 'admin', child: Text('مسؤولو النظام')),
                            DropdownMenuItem(value: 'inactive', child: Text('الحسابات المعطلة')),
                          ],
                          onChanged: (val) => setState(() => _filterRole = val ?? 'all'),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                        decoration: InputDecoration(
                          hintText: 'بحث باسم المستخدم أو الاسم أو اللقب...',
                          hintStyle: const TextStyle(color: Colors.white38, fontFamily: 'Tajawal'),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                          filled: true,
                          fillColor: const Color(0xFF240D2D),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF4A2050)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF4A2050)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF240D2D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF4A2050)),
                      ),
                      child: DropdownButton<String>(
                        value: _filterRole,
                        dropdownColor: const Color(0xFF2D1035),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('جميع الأدوار')),
                          DropdownMenuItem(value: 'inspector', child: Text('المفتشون فقط')),
                          DropdownMenuItem(value: 'head_of_department', child: Text('رؤساء المصالح')),
                          DropdownMenuItem(value: 'bureau_chief', child: Text('رئيس مكتب المستخدمين')),
                          DropdownMenuItem(value: 'director', child: Text('المدير الولائي')),
                          DropdownMenuItem(value: 'admin', child: Text('مسؤولو النظام')),
                          DropdownMenuItem(value: 'inactive', child: Text('الحسابات المعطلة')),
                        ],
                        onChanged: (val) => setState(() => _filterRole = val ?? 'all'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Users List
            Text(
              'قائمة المستخدمين (${_filteredUsers.length}):',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 8),

            if (_filteredUsers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF240D2D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A2050)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off, size: 36, color: Colors.white38),
                    SizedBox(height: 8),
                    Text(
                      'لا توجد حسابات مطابقة لمعايير البحث الحالية',
                      style: TextStyle(fontFamily: 'Tajawal', color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final u = _filteredUsers[idx];
                final isActive = u['isActive'] == true;
                final roleStr = _formatRole(u['role']);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF240D2D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4A2050)
                          : AppTheme.DangerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name + Role Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getRoleColor(u['role']).withValues(alpha: 0.2),
                              border: Border.all(color: _getRoleColor(u['role'])),
                            ),
                            child: Center(
                              child: Icon(
                                _getRoleIcon(u['role']),
                                color: _getRoleColor(u['role']),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Full Name & Service
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        u['fullName']?.toString() ?? u['username']?.toString() ?? 'مستخدم',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(u['role']).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _getRoleColor(u['role']).withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        roleStr,
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getRoleColor(u['role']),
                                        ),
                                      ),
                                    ),
                                    if (!isActive) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.DangerColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'معطل',
                                          style: TextStyle(fontFamily: 'Tajawal', fontSize: 9, color: AppTheme.DangerColor),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (u['empService'] != null && u['empService'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    u['empService'].toString(),
                                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white54),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF381544), height: 1),
                      const SizedBox(height: 6),

                      // Bottom Row: Username + Compact Action Buttons
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.login, size: 12, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 4),
                                Text(
                                  'اسم الدخول: ${u['username']}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Color(0xFFFCD34D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Actions
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 18),
                            tooltip: 'تعديل الحساب والصلاحية',
                            onPressed: () => _showEditUserDialog(u),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.key_outlined, color: Color(0xFFD4AF37), size: 18),
                            tooltip: 'إعادة تعيين كلمة المرور',
                            onPressed: () => _showResetPasswordDialog(u),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isActive ? Icons.block_outlined : Icons.check_circle_outline,
                              color: isActive ? Colors.orangeAccent : const Color(0xFF10B981),
                              size: 18,
                            ),
                            tooltip: isActive ? 'تجميد / إيقاف الحساب' : 'تفعيل الحساب',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                final api = context.read<AuthService>().api;
                                await api.updateSystemUser(
                                  id: u['id'] as int,
                                  fullName: u['fullName']?.toString() ?? u['username']?.toString() ?? '',
                                  role: u['role']?.toString() ?? 'inspector',
                                  isActive: !isActive,
                                  employeeId: u['employeeId'] is int ? u['employeeId'] as int : null,
                                );
                                _loadData();
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('خطأ: $e'), backgroundColor: AppTheme.DangerColor),
                                );
                              }
                            },
                          ),
                          if (u['username'] != 'tracker_admin') ...[
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline, color: AppTheme.DangerColor, size: 18),
                              tooltip: 'حذف الحساب نهائياً',
                              onPressed: () => _showDeleteUserDialog(u),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSystemHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حالة الخادم وقاعدة البيانات السحابية:',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF240D2D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4A2050)),
            ),
            child: Column(
              children: [
                _buildHealthRow('حالة الخادم (API Status)', 'متصل ويعمل (Online)', Icons.check_circle, const Color(0xFF10B981)),
                const Divider(color: Color(0xFF3D1A45)),
                _buildHealthRow('بيئة الخادم السحابي', 'Render Web Service (Node.js Express)', Icons.cloud, const Color(0xFF3B82F6)),
                const Divider(color: Color(0xFF3D1A45)),
                _buildHealthRow('قاعدة البيانات النشطة', 'PostgreSQL Cloud Database', Icons.storage, const Color(0xFFD4AF37)),
                const Divider(color: Color(0xFF3D1A45)),
                _buildHealthRow('المنطقة الزمنية الرسمية', 'Africa/Algiers (UTC+1)', Icons.schedule, Colors.white70),
                const Divider(color: Color(0xFF3D1A45)),
                _buildHealthRow('إجمالي الموظفين المسجلين', '${_employees.length} موظف', Icons.people, Colors.white),
                const Divider(color: Color(0xFF3D1A45)),
                _buildHealthRow('إجمالي حسابات النظام', '${_users.length} حساب', Icons.account_box, Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Morning Grace Setting Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E1C0A), Color(0xFF240D2D)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_filled, color: Color(0xFFD4AF37), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'فترة التسامح الصباحية المعتمدة (Morning Grace Threshold)',
                        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD4AF37)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الحضور بين 08:00 و $_morningGraceTime ص يُعتبر حضوراً نظامياً، والتأخر يُحسب بعده.',
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFFD4AF37), fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: '08:15', child: Text('08:15 ص')),
                        DropdownMenuItem(value: '08:30', child: Text('08:30 ص')),
                        DropdownMenuItem(value: '08:45', child: Text('08:45 ص (الموصى بها)')),
                        DropdownMenuItem(value: '09:00', child: Text('09:00 ص (مرونة قصوى)')),
                        DropdownMenuItem(value: '09:15', child: Text('09:15 ص')),
                      ],
                      onChanged: (val) async {
                        if (val != null && val != _morningGraceTime) {
                          try {
                            final api = context.read<AuthService>().api;
                            await api.updateSetting('morning_grace_time', val);
                            setState(() => _morningGraceTime = val);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('✅ تم تعديل فترة التسامح الصباحية للنظام إلى $val'), backgroundColor: const Color(0xFF10B981)),
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
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'إجراءات الصيانة والتجهيز الميداني:',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.DangerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.DangerColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cleaning_services, color: AppTheme.DangerColor, size: 32),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصفير سجلات الاختبار والتجارب السابقة',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'تفريغ سجلات الحضور والمعاينات الوهمية السابقة لبدء التشغيل الميداني الفعلي من الصفر.',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.DangerColor, foregroundColor: Colors.white),
                  onPressed: _showCleanDataDialog,
                  child: const Text('تصفير الآن', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معاينة الشاشات بمختلف الأدوار والصلاحيات:',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 6),
          const Text(
            'تتيح لك هذه الميزة معاينة وتجربة أي واجهة في التطبيق كأنك سجلت الدخول بذلك الدور مباشرة:',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          _buildPreviewCard(
            title: 'شاشة المدير الولائي (Director View)',
            desc: 'الخريطة الجغرافية الحية، تقارير الحضور والغياب، وجداول الخصم.',
            icon: Icons.shield_outlined,
            color: const Color(0xFFD4AF37),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DirectorScreen())),
          ),
          const SizedBox(height: 12),

          _buildPreviewCard(
            title: 'شاشة رئيس المصلحة (Head of Service View)',
            desc: 'أوامر المهمة، تأشير ومصادقة المعاينات الميدانية، ومتابعة فرق التفتيش.',
            icon: Icons.admin_panel_settings,
            color: const Color(0xFF3B82F6),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HeadScreen())),
          ),
          const SizedBox(height: 12),

          _buildPreviewCard(
            title: 'شاشة رئيس مكتب المستخدمين (Bureau Chief View)',
            desc: 'تسيير الـ 267 موظفاً، متابعة الغيابات والتبريرات، واستيراد وتحديث القوائم.',
            icon: Icons.badge,
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BureauScreen())),
          ),
          const SizedBox(height: 12),

          _buildPreviewCard(
            title: 'شاشة المفتش الميداني (Inspector View)',
            desc: 'تسجيل الحضور بالكاميرا والـ GPS، توثيق الزيارات الميدانية، وتوليد بطاقات الـ QR.',
            icon: Icons.explore,
            color: const Color(0xFFE11D48),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectorScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF240D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.white70)),
          const Spacer(),
          Text(value, style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPreviewCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF240D2D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  String _formatRole(dynamic role) {
    switch (role) {
      case 'admin':
        return 'مسؤول النظام (Admin)';
      case 'director':
        return 'المدير الولائي';
      case 'head_of_department':
        return 'رئيس مصلحة';
      case 'bureau_chief':
        return 'رئيس مكتب';
      case 'inspector':
      default:
        return 'مفتش ميداني';
    }
  }

  Widget _buildInspectoratesTab() {
    final list = InspectorateService.instance.inspectorates;

    return RefreshIndicator(
      onRefresh: () async {
        final api = context.read<AuthService>().api;
        await InspectorateService.instance.loadInspectorates(api: api);
        setState(() {});
      },
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Information & Control Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E103A), Color(0xFF1E0B26)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.satellite_alt, color: Color(0xFFD4AF37), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إدارة وضبط البصمات الجغرافية للمقرات والملحقات',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'تحديد إحداثيات GPS بدقة السنتيمتر وتعيين نطاق التسامح (نصف القطر) لكل ملحقة',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Text(
                          '${list.length} مقرات معتمدة',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF3D1645)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showEditInspectorateDialog(null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: const Color(0xFF1A0A1F),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_location_alt, size: 16),
                        label: const Text(
                          'إضافة مقر / ملحقة رقابية جديدة',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showResetInspectoratesDialog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF87171),
                          side: const BorderSide(color: Color(0xFFF87171)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.restore, size: 16),
                        label: const Text(
                          'استعادة الإحداثيات الافتراضية الأصلية',
                          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // List of Inspectorates Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final insp = list[index];
                return _buildInspectorateCard(insp);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorateCard(InspectorateHQ insp) {
    IconData iconData = Icons.account_balance;
    Color iconColor = const Color(0xFFD4AF37);
    String typeLabel = 'مفتشية إقليمية';

    if (insp.isMainDirectorate || insp.id == 'hq_setif') {
      iconData = Icons.domain;
      iconColor = const Color(0xFFD4AF37);
      typeLabel = 'المقر الرئيسي للمديرية الولائية';
    } else if (insp.id.contains('airport')) {
      iconData = Icons.local_airport;
      iconColor = const Color(0xFF38BDF8);
      typeLabel = 'مفتشية حدودية لمراقبة الجودة';
    } else if (insp.id.startsWith('annex_')) {
      iconData = Icons.storefront;
      iconColor = const Color(0xFF34D399);
      typeLabel = 'ملحقة تجارية إقليمية';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: insp.isMainDirectorate ? const Color(0xFFD4AF37).withValues(alpha: 0.5) : const Color(0xFF3D1645),
          width: insp.isMainDirectorate ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insp.nameAr,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (insp.nameFr.isNotEmpty)
                      Text(
                        insp.nameFr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Coordinates and Radius details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14071A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2D1035)),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore, size: 14, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 4),
                    Text(
                      'خط العرض (Lat): ${insp.latitude.toStringAsFixed(6)}°',
                      style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation, size: 14, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 4),
                    Text(
                      'خط الطول (Lng): ${insp.longitude.toStringAsFixed(6)}°',
                      style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radar, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'نطاق البصمة: ${insp.radiusMeters.round()} متر',
                      style: const TextStyle(fontFamily: 'Tajawal', color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => QRCodeScreen.showOfficialBadge(context, insp),
                icon: const Icon(Icons.qr_code, size: 15, color: Color(0xFFD4AF37)),
                label: const Text(
                  'شهادة QR المقر',
                  style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFFD4AF37), fontSize: 11),
                ),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () => _showEditInspectorateDialog(insp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E103A),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD4AF37)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.edit_location_alt, size: 14, color: Color(0xFFD4AF37)),
                label: const Text(
                  'تعديل الإحداثيات والبصمة',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (!insp.isMainDirectorate) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF87171)),
                  tooltip: 'حذف الملحقة',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showDeleteInspectorateDialog(insp),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showEditInspectorateDialog(InspectorateHQ? insp) {
    final isNew = insp == null;
    final nameArCtrl = TextEditingController(text: insp?.nameAr ?? '');
    final nameFrCtrl = TextEditingController(text: insp?.nameFr ?? '');
    final latCtrl = TextEditingController(text: insp != null ? insp.latitude.toString() : '36.190057');
    final lngCtrl = TextEditingController(text: insp != null ? insp.longitude.toString() : '5.399013');
    final radiusCtrl = TextEditingController(text: insp != null ? insp.radiusMeters.round().toString() : '600');
    bool isFetchingGps = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF240D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4AF37)),
          ),
          title: Row(
            children: [
              Icon(isNew ? Icons.add_location : Icons.edit_location_alt, color: const Color(0xFFD4AF37)),
              const SizedBox(width: 10),
              Text(
                isNew ? 'إضافة ملحقة / مقر رقابي جديد' : 'تعديل إحداثيات: ${insp.nameAr}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Button to capture real-time GPS location on site
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: isFetchingGps
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)))
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(
                        isFetchingGps ? 'جاري التقاط إحداثيات GPS...' : '📍 التقاط إحداثيات موقعي الحالي (GPS)',
                        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: isFetchingGps
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setDialogState(() => isFetchingGps = true);
                              try {
                                LocationPermission perm = await Geolocator.checkPermission();
                                if (perm == LocationPermission.denied) {
                                  perm = await Geolocator.requestPermission();
                                }
                                final pos = await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );
                                setDialogState(() {
                                  latCtrl.text = pos.latitude.toStringAsFixed(7);
                                  lngCtrl.text = pos.longitude.toStringAsFixed(7);
                                  isFetchingGps = false;
                                });
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('تم جلب موقعك الدقيق: (${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)})'),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              } catch (e) {
                                setDialogState(() => isFetchingGps = false);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('تعذر جلب GPS: $e'), backgroundColor: AppTheme.DangerColor),
                                );
                              }
                            },
                    ),
                  ),
                  TextField(
                    controller: nameArCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'الاسم الرسمي بالعربية (مثال: الملحقة التجارية — عين الكبيرة)',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                      prefixIcon: Icon(Icons.business, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameFrCtrl,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'الاسم بالفرنسية (Nom en Français)',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                      prefixIcon: Icon(Icons.translate, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                          decoration: const InputDecoration(
                            labelText: 'خط العرض (Latitude)',
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: Icon(Icons.explore, color: Color(0xFFD4AF37)),
                            filled: true,
                            fillColor: Color(0xFF1E0B26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                          decoration: const InputDecoration(
                            labelText: 'خط الطول (Longitude)',
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                            prefixIcon: Icon(Icons.navigation, color: Color(0xFFD4AF37)),
                            filled: true,
                            fillColor: Color(0xFF1E0B26),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: radiusCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                    decoration: const InputDecoration(
                      labelText: 'نطاق الحضور الجغرافي بالأمتار (Radius: 150، 250، 500، 1000)',
                      labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                      prefixIcon: Icon(Icons.radar, color: Color(0xFF10B981)),
                      filled: true,
                      fillColor: Color(0xFF1E0B26),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF1A0A1F),
              ),
              onPressed: () async {
                if (nameArCtrl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final lat = double.tryParse(latCtrl.text.trim()) ?? 36.190057;
                final lng = double.tryParse(lngCtrl.text.trim()) ?? 5.399013;
                final rad = double.tryParse(radiusCtrl.text.trim()) ?? 600.0;

                final updated = InspectorateHQ(
                  id: insp?.id ?? 'insp_${DateTime.now().millisecondsSinceEpoch}',
                  nameAr: nameArCtrl.text.trim(),
                  nameFr: nameFrCtrl.text.trim(),
                  latitude: lat,
                  longitude: lng,
                  radiusMeters: rad,
                  isMainDirectorate: insp?.isMainDirectorate ?? false,
                );

                Navigator.pop(ctx);
                final api = context.read<AuthService>().api;
                await InspectorateService.instance.updateInspectorate(updated, api: api);
                setState(() {});

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('تم حفظ وتحديث الإحداثيات والبصمة الجغرافية بنجاح 📍'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: Text(isNew ? 'إضافة المقر' : 'حفظ التعديلات', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteInspectorateDialog(InspectorateHQ insp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.DangerColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.DangerColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'حذف الملحقة: ${insp.nameAr}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف ${insp.nameAr} من قائمة المقرات المعتمدة للبصمة الجغرافية؟',
          style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.DangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = context.read<AuthService>().api;
              await InspectorateService.instance.deleteInspectorate(insp.id, api: api);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الملحقة بنجاح'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('نعم، تأكيد الحذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetInspectoratesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF240D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text(
              'استعادة الإحداثيات الأصلية',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: const Text(
          'هل تريد إعادة ضبط جميع إحداثيات ونطاقات المقرات والملحقات الثمانية إلى القيم الافتراضية الأصلية؟',
          style: TextStyle(fontFamily: 'Tajawal', color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white60, fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: const Color(0xFF1A0A1F),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final api = context.read<AuthService>().api;
              await InspectorateService.instance.resetToDefaults(api: api);
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت استعادة الإحداثيات الافتراضية بنجاح'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            child: const Text('نعم، استعادة الافتراضي', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(dynamic role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFD4AF37);
      case 'director':
        return const Color(0xFFF59E0B);
      case 'head_of_department':
        return const Color(0xFF3B82F6);
      case 'bureau_chief':
        return const Color(0xFF10B981);
      case 'inspector':
      default:
        return const Color(0xFFE11D48);
    }
  }

  IconData _getRoleIcon(dynamic role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'director':
        return Icons.shield;
      case 'head_of_department':
        return Icons.business_center;
      case 'bureau_chief':
        return Icons.badge;
      case 'inspector':
      default:
        return Icons.explore;
    }
  }
}
