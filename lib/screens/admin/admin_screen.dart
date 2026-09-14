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

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _employees = [];
  String _searchQuery = '';
  String _filterRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthService>().api;
      final results = await Future.wait([
        api.getSystemUsers(),
        api.getEmployees(all: true),
      ]);
      if (mounted) {
        setState(() {
          _users = results[0];
          _employees = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((u) {
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
            child: SizedBox(
              width: 400,
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
            child: SizedBox(
              width: 400,
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
    final loc = AppLocalizations.of(context);
    final isAr = loc.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF240D2D),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF881337)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.admin_panel_settings, size: 22, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة تحكم مدير النظام (Admin Dashboard)',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'إدارة الحسابات، الصلاحيات، وحالة السيرفر',
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.AccentColor),
              tooltip: 'تحديث البيانات',
              onPressed: _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
              tooltip: 'تغيير كلمة المرور',
              onPressed: () => ChangePasswordDialog.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white70),
              tooltip: 'تغيير اللغة',
              onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            tabs: const [
              Tab(icon: Icon(Icons.people_alt), text: 'إدارة المستخدمين والحسابات'),
              Tab(icon: Icon(Icons.dns), text: 'حالة النظام والسيرفر'),
              Tab(icon: Icon(Icons.preview), text: 'معاينة شاشات الأدوار'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildUsersTab(),
                  _buildSystemHealthTab(),
                  _buildRolePreviewTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildUsersTab() {
    final activeCount = _users.where((u) => u['isActive'] == true).length;
    final inspectorsCount = _users.where((u) => u['role'] == 'inspector').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFD4AF37),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                _buildStatCard('إجمالي الحسابات', '${_users.length}', Icons.account_circle, const Color(0xFF881337)),
                const SizedBox(width: 10),
                _buildStatCard('الحسابات النشطة', '$activeCount', Icons.check_circle, const Color(0xFF10B981)),
                const SizedBox(width: 10),
                _buildStatCard('المفتشون الميدانيون', '$inspectorsCount', Icons.explore, const Color(0xFFD4AF37)),
                const SizedBox(width: 10),
                _buildStatCard('إجمالي الموظفين', '${_employees.length}', Icons.badge, const Color(0xFF3B82F6)),
              ],
            ),
            const SizedBox(height: 18),

            // Action Buttons Bar
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showBulkGenerateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1A0A1F),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text(
                    'توليد حسابات لجميع الـ 267 موظفاً',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF881337),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'إضافة مستخدم جديد',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Search and Filter
            Row(
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
            ),
            const SizedBox(height: 16),

            // Users List
            Text(
              'قائمة المستخدمين (${_filteredUsers.length}):',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 10),

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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF240D2D),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4A2050)
                          : AppTheme.DangerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getRoleColor(u['role']).withValues(alpha: 0.2),
                          border: Border.all(color: _getRoleColor(u['role'])),
                        ),
                        child: Center(
                          child: Icon(
                            _getRoleIcon(u['role']),
                            color: _getRoleColor(u['role']),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u['fullName']?.toString() ?? u['username']?.toString() ?? 'مستخدم',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(u['role']).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _getRoleColor(u['role']).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    roleStr,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _getRoleColor(u['role']),
                                    ),
                                  ),
                                ),
                                if (!isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.DangerColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'معطل',
                                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: AppTheme.DangerColor),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.login, size: 12, color: Colors.white38),
                                const SizedBox(width: 4),
                                Text(
                                  'اسم الدخول: ${u['username']}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (u['empService'] != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.business, size: 12, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      u['empService'].toString(),
                                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.white54),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF3B82F6), size: 20),
                        tooltip: 'تعديل الحساب والصلاحية',
                        onPressed: () => _showEditUserDialog(u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.key, color: Color(0xFFD4AF37), size: 20),
                        tooltip: 'إعادة تعيين كلمة المرور',
                        onPressed: () => _showResetPasswordDialog(u),
                      ),
                      IconButton(
                        icon: Icon(
                          isActive ? Icons.block : Icons.check_circle_outline,
                          color: isActive ? Colors.orangeAccent : const Color(0xFF10B981),
                          size: 20,
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
                      if (u['username'] != 'tracker_admin')
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.DangerColor, size: 20),
                          tooltip: 'حذف الحساب نهائياً',
                          onPressed: () => _showDeleteUserDialog(u),
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
    return Expanded(
      child: Container(
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
                const Spacer(),
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
        return 'رئيس مكتب المستخدمين';
      case 'inspector':
      default:
        return 'مفتش ميداني';
    }
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
