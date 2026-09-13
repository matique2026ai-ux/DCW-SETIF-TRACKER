import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/common/justifications_review_screen.dart';

class BureauScreen extends StatefulWidget {
  const BureauScreen({super.key});

  @override
  State<BureauScreen> createState() => _BureauScreenState();
}

class _BureauScreenState extends State<BureauScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _deductions = [];
  List<String> _departments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, active, sick_leave, annual_leave, brigade

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<AuthService>().api;
      final emps = await api.getEmployees(all: true);
      final deds = await api.getDeductions();
      final depts = await api.getAllDepartments();

      if (mounted) {
        setState(() {
          _employees = emps;
          _deductions = deds;
          _departments = depts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDeduction(int id) async {
    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.id ?? 1;
      await auth.api.approveDeduction(id: id, approvedBy: userId);
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تمت الموافقة على الخصم بنجاح',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: AppTheme.SuccessColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: AppTheme.DangerColor,
          ),
        );
      }
    }
  }

  Future<void> _rejectDeduction(int id) async {
    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.id ?? 1;
      await auth.api.rejectDeduction(id: id, approvedBy: userId);
      _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم رفض الخصم بنجاح',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: AppTheme.WarningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: AppTheme.DangerColor,
          ),
        );
      }
    }
  }

  void _openEditEmployeeModal(Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditEmployeeStatusModal(
        employee: emp,
        departments: _departments,
        onSaved: () {
          Navigator.pop(ctx);
          _loadAll();
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredEmployees {
    return _employees.where((e) {
      final nom = (e['Nom'] ?? '').toString().toLowerCase();
      final prenom = (e['Prenom'] ?? '').toString().toLowerCase();
      final nomAr = (e['NomAr'] ?? '').toString().toLowerCase();
      final prenomAr = (e['PrenomAr'] ?? '').toString().toLowerCase();
      final matricule = (e['NumeroMatricule'] ?? '').toString().toLowerCase();
      final grade = (e['Grade'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesSearch =
          q.isEmpty ||
          nom.contains(q) ||
          prenom.contains(q) ||
          nomAr.contains(q) ||
          prenomAr.contains(q) ||
          matricule.contains(q) ||
          grade.contains(q);

      if (!matchesSearch) return false;

      final status = (e['AdministrativeStatus'] ?? 'active').toString().toLowerCase();
      final isBrigade =
          e['IsBrigadeLeader'] == true || e['IsBrigadeLeader'] == 1;

      if (_statusFilter == 'active') return status == 'active';
      if (_statusFilter == 'sick_leave') return status == 'sick_leave';
      if (_statusFilter == 'annual_leave') return status == 'annual_leave';
      if (_statusFilter == 'brigade') return isBrigade;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pendingDeds =
        _deductions.where((d) => d['Status'] == 'pending').toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E102F),
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
                    colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.badge, size: 20, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.roleBureau,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'تسيير الموظفين والوضعيات الإدارية',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              tooltip: 'تحديث البيانات',
              onPressed: _loadAll,
            ),
            IconButton(
              icon: const Icon(Icons.language, color: Color(0xFFD4AF37)),
              onPressed: () =>
                  context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
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
            indicatorWeight: 3,
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.people_alt, size: 20),
                text: 'الموظفون (${_employees.length})',
              ),
              Tab(
                icon: Badge(
                  isLabelVisible: pendingDeds.isNotEmpty,
                  label: Text('${pendingDeds.length}'),
                  child: const Icon(Icons.gavel, size: 20),
                ),
                text: 'الخصومات (${pendingDeds.length})',
              ),
              const Tab(
                icon: Icon(Icons.assignment_turned_in, size: 20),
                text: 'التبريرات والشهادات',
              ),
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
                  _buildEmployeesTab(),
                  _buildDeductionsTab(pendingDeds),
                  const JustificationsReviewScreen(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmployeesTab() {
    final activeCount = _employees
        .where((e) => (e['AdministrativeStatus'] ?? 'active') == 'active')
        .length;
    final sickCount = _employees
        .where((e) => e['AdministrativeStatus'] == 'sick_leave')
        .length;
    final annualCount = _employees
        .where((e) => e['AdministrativeStatus'] == 'annual_leave')
        .length;
    final brigadeCount = _employees
        .where((e) => e['IsBrigadeLeader'] == true || e['IsBrigadeLeader'] == 1)
        .length;

    final filtered = _filteredEmployees;

    return Column(
      children: [
        // KPI Mini Stats Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E102F).withValues(alpha: 0.6),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.BorderColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              _buildMiniStat('الإجمالي', '${_employees.length}', Colors.white70),
              const SizedBox(width: 8),
              _buildMiniStat('مباشر', '$activeCount', AppTheme.SuccessColor),
              const SizedBox(width: 8),
              _buildMiniStat('عطلة مرضية', '$sickCount', const Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              _buildMiniStat('عطلة سنوية', '$annualCount', const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _buildMiniStat('رؤساء فرق', '$brigadeCount', const Color(0xFFD4AF37)),
            ],
          ),
        ),

        // Search Bar & Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم، اللقب، الرتبة، أو رقم التسجيل...',
              hintStyle: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white38,
                fontSize: 13,
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
              filled: true,
              fillColor: AppTheme.CardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.BorderColor.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
              ),
            ),
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterChip('الكل (${_employees.length})', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('🟢 مباشرون ($activeCount)', 'active'),
              const SizedBox(width: 8),
              _buildFilterChip('🩺 عطلة مرضية ($sickCount)', 'sick_leave'),
              const SizedBox(width: 8),
              _buildFilterChip('🏖️ عطلة سنوية ($annualCount)', 'annual_leave'),
              const SizedBox(width: 8),
              _buildFilterChip('🎖️ رؤساء الفرق ($brigadeCount)', 'brigade'),
            ],
          ),
        ),

        // Employees List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد نتائج مطابقة للبحث',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final emp = filtered[i];
                    return _buildEmployeeCard(emp);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Colors.white60,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF37)
              : AppTheme.CardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF37)
                : AppTheme.BorderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF1E102F) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> emp) {
    final nomAr = emp['NomAr'] ?? '';
    final prenomAr = emp['PrenomAr'] ?? '';
    final name = nomAr.toString().isNotEmpty ? '$nomAr $prenomAr' : '${emp['Nom']} ${emp['Prenom']}';
    final matricule = emp['NumeroMatricule'] ?? '-';
    final grade = emp['Grade'] ?? 'غير محدد';
    final service = emp['Service'] ?? 'غير محدد';
    final function = (emp['FonctionExercee'] ?? '').toString();
    final status = emp['AdministrativeStatus'] ?? 'active';
    final isBrigade = emp['IsBrigadeLeader'] == true || emp['IsBrigadeLeader'] == 1;
    final brigadeName = (emp['BrigadeName'] ?? '').toString();

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'sick_leave':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'عطلة مرضية';
        statusIcon = Icons.medical_services;
        break;
      case 'annual_leave':
        statusColor = const Color(0xFF3B82F6);
        statusLabel = 'عطلة سنوية';
        statusIcon = Icons.beach_access;
        break;
      case 'maternity_leave':
        statusColor = const Color(0xFFEC4899);
        statusLabel = 'عطلة أمومة';
        statusIcon = Icons.child_friendly;
        break;
      case 'special_mission':
        statusColor = const Color(0xFF8B5CF6);
        statusLabel = 'تكليف بمهمة';
        statusIcon = Icons.assignment_ind;
        break;
      case 'detached':
        statusColor = const Color(0xFF6B7280);
        statusLabel = 'انتداب';
        statusIcon = Icons.swap_horiz;
        break;
      default:
        statusColor = AppTheme.SuccessColor;
        statusLabel = 'مباشر للعمل';
        statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.CardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBrigade
              ? const Color(0xFFD4AF37).withValues(alpha: 0.5)
              : AppTheme.BorderColor.withValues(alpha: 0.25),
          width: isBrigade ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isBrigade
                        ? const Color(0xFFD4AF37).withValues(alpha: 0.2)
                        : const Color(0xFF1E102F),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBrigade
                          ? const Color(0xFFD4AF37)
                          : AppTheme.BorderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isBrigade ? Icons.military_tech : Icons.person,
                      color: isBrigade ? const Color(0xFFD4AF37) : Colors.white70,
                      size: 22,
                    ),
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
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'رقم التسجيل: $matricule | $grade',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Colors.white10),
            const SizedBox(height: 8),

            // Service & Function
            Row(
              children: [
                const Icon(Icons.business, size: 14, color: Color(0xFFD4AF37)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$service',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (function.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.work_outline, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'المنصب الممارس: $function',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Brigade Badge
            if (isBrigade) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 6),
                    Text(
                      'رئيس فرقة: ${brigadeName.isNotEmpty ? brigadeName : "فرقة تفتيش ومراقبة"}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openEditEmployeeModal(emp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D1035),
                  foregroundColor: const Color(0xFFD4AF37),
                  elevation: 0,
                  side: BorderSide(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text(
                  'تعديل الوضعية الإدارية والتكليف (رئيس فرقة / عطلة / منصب)',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeductionsTab(List<Map<String, dynamic>> pending) {
    final loc = AppLocalizations.of(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pending.isEmpty
                ? AppTheme.SuccessColor.withValues(alpha: 0.1)
                : AppTheme.WarningColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (pending.isEmpty
                      ? AppTheme.SuccessColor
                      : AppTheme.WarningColor)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                pending.isEmpty ? Icons.check_circle : Icons.info_outline,
                color: pending.isEmpty
                    ? AppTheme.SuccessColor
                    : AppTheme.WarningColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '${loc.pendingDeductions}: ${pending.length}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (pending.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.SuccessColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.noPendingDeductions,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: AppTheme.TextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: pending.length,
              itemBuilder: (ctx, i) {
                final d = pending[i];
                final name = d['NomAr'] != null
                    ? '${d['NomAr']} ${d['PrenomAr']}'
                    : '${d['Nom']} ${d['Prenom']}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.CardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.BorderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.WarningColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppTheme.WarningColor,
                              size: 22,
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
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${d['Service'] ?? ''}',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 11,
                                    color: AppTheme.TextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (d['DaysCount'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.DangerColor.withValues(alpha: 0.15),
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
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.BackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${d['Reason']}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${loc.from}: ${d['RequestedByName'] ?? '-'}',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: AppTheme.TextSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveDeduction(d['Id'] as int),
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(
                                loc.approve,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.SuccessColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rejectDeduction(d['Id'] as int),
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(
                                loc.reject,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.DangerColor,
                                side: const BorderSide(
                                  color: AppTheme.DangerColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
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

class _EditEmployeeStatusModal extends StatefulWidget {
  final Map<String, dynamic> employee;
  final List<String> departments;
  final VoidCallback onSaved;

  const _EditEmployeeStatusModal({
    required this.employee,
    required this.departments,
    required this.onSaved,
  });

  @override
  State<_EditEmployeeStatusModal> createState() =>
      _EditEmployeeStatusModalState();
}

class _EditEmployeeStatusModalState extends State<_EditEmployeeStatusModal> {
  late String _status;
  late bool _isBrigadeLeader;
  late TextEditingController _brigadeNameCtrl;
  late TextEditingController _functionCtrl;
  late TextEditingController _notesCtrl;
  String? _selectedDept;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final emp = widget.employee;
    _status = (emp['AdministrativeStatus'] ?? 'active').toString();
    _isBrigadeLeader =
        emp['IsBrigadeLeader'] == true || emp['IsBrigadeLeader'] == 1;
    _brigadeNameCtrl = TextEditingController(text: (emp['BrigadeName'] ?? '').toString());
    _functionCtrl = TextEditingController(text: (emp['FonctionExercee'] ?? '').toString());
    _notesCtrl = TextEditingController(text: (emp['StatusNotes'] ?? '').toString());
    _selectedDept = emp['Service']?.toString();

    if (emp['StatusStartDate'] != null) {
      _startDate = DateTime.tryParse(emp['StatusStartDate'].toString());
    }
    if (emp['StatusEndDate'] != null) {
      _endDate = DateTime.tryParse(emp['StatusEndDate'].toString());
    }
  }

  @override
  void dispose() {
    _brigadeNameCtrl.dispose();
    _functionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final api = context.read<AuthService>().api;
      final empId = widget.employee['Id'] as int;

      await api.updateEmployeeAdminStatus(empId, {
        'administrativeStatus': _status,
        'statusStartDate': _startDate?.toIso8601String().split('T')[0],
        'statusEndDate': _endDate?.toIso8601String().split('T')[0],
        'statusNotes': _notesCtrl.text.trim(),
        'isBrigadeLeader': _isBrigadeLeader,
        'brigadeName': _brigadeNameCtrl.text.trim(),
        'assignedDepartment': _selectedDept,
        'assignedPosition': _functionCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حفظ التعديلات الإدارية وتحديث وضعية الموظف بنجاح',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: AppTheme.SuccessColor,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: AppTheme.DangerColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = widget.employee;
    final name = emp['NomAr'] != null && emp['NomAr'].toString().isNotEmpty
        ? '${emp['NomAr']} ${emp['PrenomAr']}'
        : '${emp['Nom']} ${emp['Prenom']}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E102F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تعديل الوضعية الإدارية: $name',
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
              const SizedBox(height: 4),
              Text(
                'الرتبة: ${emp['Grade'] ?? '-'} | رقم التسجيل: ${emp['NumeroMatricule'] ?? '-'}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: AppTheme.TextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Administrative Status Dropdown
              const Text(
                'الوضعية الإدارية الحالية:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.CardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.BorderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    dropdownColor: const Color(0xFF2D1035),
                    isExpanded: true,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('🟢 مباشر للعمل (في الخدمة الفعلية)'),
                      ),
                      DropdownMenuItem(
                        value: 'sick_leave',
                        child: Text('🩺 عطلة مرضية (قصيرة / طويلة المدى)'),
                      ),
                      DropdownMenuItem(
                        value: 'annual_leave',
                        child: Text('🏖️ عطلة سنوية / راحة قانونية'),
                      ),
                      DropdownMenuItem(
                        value: 'maternity_leave',
                        child: Text('👶 عطلة أمومة'),
                      ),
                      DropdownMenuItem(
                        value: 'special_mission',
                        child: Text('📜 تكليف بمهمة تفتيش خاصة / خارج الولاية'),
                      ),
                      DropdownMenuItem(
                        value: 'detached',
                        child: Text('🔄 انتداب لدى هيئة أخرى'),
                      ),
                      DropdownMenuItem(
                        value: 'disponibilite',
                        child: Text('⏸️ إحالة على الاستيداع'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                ),
              ),

              // Dates if on leave
              if (_status != 'active') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _startDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.CardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تاريخ البداية:',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                _startDate != null
                                    ? _startDate!.toIso8601String().split('T')[0]
                                    : 'اختر التاريخ',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.CardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تاريخ النهاية:',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                _endDate != null
                                    ? _endDate!.toIso8601String().split('T')[0]
                                    : 'اختر التاريخ',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 18),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              // Team Leader Assignment (رئيس فرقة)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isBrigadeLeader
                      ? const Color(0xFFD4AF37).withValues(alpha: 0.1)
                      : AppTheme.CardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isBrigadeLeader
                        ? const Color(0xFFD4AF37)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFFD4AF37)
                            : Colors.white60,
                      ),
                      title: const Text(
                        '🎖️ تعيين الموظف كرئيس فرقة تفتيش ومراقبة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: const Text(
                        'يمنحه شارة رئيس فرقة وتظهر إدارته للفرقة على الخريطة واللوحة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                      value: _isBrigadeLeader,
                      onChanged: (v) => setState(() => _isBrigadeLeader = v),
                    ),
                    if (_isBrigadeLeader) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _brigadeNameCtrl,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          labelText: 'اسم أو رقم الفرقة التفتيشية',
                          labelStyle: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Color(0xFFD4AF37),
                          ),
                          hintText: 'مثال: فرقة العلمة 01 / فرقة قمع الغش المناوبة',
                          hintStyle: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white30,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E102F),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              // Department Transfer & Position Change
              const Text(
                '🔄 تحويل المصلحة أو المنصب الممارس:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 8),

              if (widget.departments.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.CardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.departments.contains(_selectedDept)
                          ? _selectedDept
                          : null,
                      hint: Text(
                        _selectedDept ?? 'اختر المصلحة / المكتب',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white70,
                        ),
                      ),
                      dropdownColor: const Color(0xFF2D1035),
                      isExpanded: true,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.white,
                      ),
                      items: widget.departments.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(d),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedDept = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              TextField(
                controller: _functionCtrl,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: 'المنصب الممارس الفعلي',
                  labelStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white70,
                  ),
                  filled: true,
                  fillColor: AppTheme.CardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _notesCtrl,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                ),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'ملاحظات إدارية / رقم القرار الإداري',
                  labelStyle: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white70,
                  ),
                  filled: true,
                  fillColor: AppTheme.CardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF1E102F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1E102F),
                          ),
                        )
                      : const Icon(Icons.check_circle, size: 20),
                  label: Text(
                    _isSaving ? 'جارٍ الحفظ والتحديث...' : 'حفظ التعديلات الإدارية',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
