import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/utils/constants.dart';

class DirectorAnalyticsTab extends StatefulWidget {
  const DirectorAnalyticsTab({super.key});

  @override
  State<DirectorAnalyticsTab> createState() => _DirectorAnalyticsTabState();
}

class _DirectorAnalyticsTabState extends State<DirectorAnalyticsTab> {
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({DateTime? date, bool silent = false}) async {
    final targetDate = date ?? _selectedDate;
    if (!silent) {
      setState(() {
        _isLoading = true;
        _selectedDate = targetDate;
      });
    }

    try {
      final api = context.read<AuthService>().api;
      final dateStr = DateFormat('yyyy-MM-dd').format(targetDate);
      final data = await api.getDirectorAnalytics(date: dateStr);

      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF240D2D),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1E0B26)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && !DateUtils.isSameDay(picked, _selectedDate)) {
      _loadData(date: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc.isArabic;

    if (_isLoading && _analyticsData.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      );
    }

    final attendance = (_analyticsData['attendance'] as Map<String, dynamic>?) ?? {};
    final inspections = (_analyticsData['todayInspections'] as Map<String, dynamic>?) ?? {};
    final cumulative = (_analyticsData['cumulativeTotals'] as Map<String, dynamic>?) ?? {};
    final deptBreakdown = (_analyticsData['departmentBreakdown'] as Map<String, dynamic>?) ?? {};
    final fraudRep = (deptBreakdown['fraudRepression'] as Map<String, dynamic>?) ?? {};
    final competition = (deptBreakdown['competition'] as Map<String, dynamic>?) ?? {};
    final topInspectors = (_analyticsData['topInspectors'] as List<dynamic>?) ?? [];
    final recentVisits = (_analyticsData['recentVisits'] as List<dynamic>?) ?? [];

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateStr = DateFormat('yyyy/MM/dd').format(_selectedDate);

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF240D2D),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Executive Control Bar
            _buildExecutiveHeader(isArabic, isToday, dateStr),
            const SizedBox(height: 16),

            // 2. Primary KPI Metric Cards (Interactive on Tap)
            _buildKpiDeck(isArabic, inspections, attendance, recentVisits),
            const SizedBox(height: 20),

            // 3. Department Breakdown (Fraud Repression vs Competition)
            _buildDepartmentsSection(isArabic, fraudRep, competition),
            const SizedBox(height: 20),

            // 4. Macro Cumulative Ledger & Quality Indicators
            _buildCumulativeMacroCard(isArabic, cumulative),
            const SizedBox(height: 20),

            // 5. Territorial Inspectorates & Top Inspectors Deck
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 850) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildInspectoratesDistribution(isArabic),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: _buildTopInspectorsCard(isArabic, topInspectors),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildInspectoratesDistribution(isArabic),
                    const SizedBox(height: 16),
                    _buildTopInspectorsCard(isArabic, topInspectors),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 6. Recent Verified Inspections Log
            _buildRecentInspectionsLog(isArabic, recentVisits),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveHeader(bool isArabic, bool isToday, String dateStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D1037), Color(0xFF1E0A25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                ),
                child: const Icon(Icons.analytics_outlined, color: Color(0xFFD4AF37), size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'لوحة القيادة والمؤشرات الرقابية الميدانية' : 'Tableau de Bord & Indicateurs de Contrôle',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    isToday
                      ? (isArabic ? 'بيانات حية ومباشرة من قاعدة البيانات (انقر على أي بطاقة لعرض تفاصيلها 👆)' : 'Données réelles et directes (Cliquez sur une carte)')
                      : (isArabic ? 'أرشيف الرقابة والتفتيش ليوم: $dateStr' : 'Archive du: $dateStr'),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: isToday ? const Color(0xFF10B981) : const Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month, color: Color(0xFFD4AF37), size: 18),
                label: Text(
                  dateStr,
                  style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4A2050)),
                  backgroundColor: const Color(0xFF1A0A20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _exportExecutivePdf(),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.black, size: 18),
                label: Text(
                  isArabic ? 'تصدير التقرير' : 'Exporter PDF',
                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiDeck(
    bool isArabic,
    Map<String, dynamic> ins,
    Map<String, dynamic> att,
    List<dynamic> recentVisits,
  ) {
    final totalVisits = ins['totalVisits'] ?? recentVisits.length;
    final violations = ins['violationsCount'] ?? recentVisits.where((v) => v['ViolationFound'] == true || v['violationfound'] == true || v['ViolationFound'] == 1).length;
    
    // Robust calculation for Seizure Value
    double seizureVal = (ins['totalSeizureValue'] as num?)?.toDouble() ?? double.tryParse(ins['totalSeizureValue']?.toString() ?? '0') ?? 0.0;
    if (seizureVal == 0.0 && recentVisits.isNotEmpty) {
      for (final v in recentVisits) {
        final val = (v['SeizureValue'] as num?)?.toDouble() ?? double.tryParse(v['SeizureValue']?.toString() ?? '0') ?? 0.0;
        seizureVal += val;
        // Text parsing fallback if needed
        if (val == 0.0) {
          final notes = '${v['ViolationNotes'] ?? ''} ${v['Notes'] ?? ''}';
          final match = RegExp(r'(\d+[\d,.]*)\s*دج').firstMatch(notes);
          if (match != null) {
            final parsed = double.tryParse(match.group(1)!.replaceAll(',', '').replaceAll('.', ''));
            if (parsed != null && parsed > 0) seizureVal += parsed;
          }
        }
      }
    }

    final closures = ins['closureProposalsCount'] ?? recentVisits.where((v) => (v['LegalAction']?.toString().contains('غلق') ?? false) || (v['ViolationNotes']?.toString().contains('غلق') ?? false)).length;
    final samples = ins['samplesCount'] ?? recentVisits.where((v) => (v['LegalAction']?.toString().contains('عين') ?? false) || (v['ViolationNotes']?.toString().contains('عين') ?? false)).length;
    final int courtReferrals = (ins['courtReferralsCount'] as num?)?.toInt() ?? recentVisits.where((v) => (v['LegalAction']?.toString().contains('محضر') ?? false) || (v['ViolationNotes']?.toString().contains('محضر') ?? false)).length;
    final readinessRate = att['readinessRate']?.toString() ?? '0.0';

    final formatter = NumberFormat('#,###', 'fr_DZ');
    final seizureText = '${formatter.format(seizureVal)} دج';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildMetricTile(
              title: isArabic ? 'إجمالي التدخلات والمعاينات' : 'Visites de Contrôle',
              value: '$totalVisits',
              icon: Icons.storefront_outlined,
              accentColor: const Color(0xFF38BDF8),
              subtitle: isArabic ? 'معاينة ميدانية (انقر للتفاصيل)' : 'Interventions (Cliquez)',
              onTap: () => _showVisitsDetailsSheet(context, recentVisits, isArabic),
            ),
            _buildMetricTile(
              title: isArabic ? 'المخالفات والمحاضر' : 'Infractions & PVs',
              value: '$violations',
              icon: Icons.gavel_outlined,
              accentColor: const Color(0xFFEF4444),
              subtitle: courtReferrals > 0 ? (isArabic ? '$courtReferrals محضر قضائي (انقر)' : '$courtReferrals PVs justice') : (isArabic ? 'مخالفات محررة (انقر)' : 'Infractions (Cliquez)'),
              onTap: () => _showViolationsDetailsSheet(context, recentVisits, isArabic),
            ),
            _buildMetricTile(
              title: isArabic ? 'المحجوزات والسلع' : 'Valeur des Saisies',
              value: seizureVal > 0 ? seizureText : '0.00 دج',
              icon: Icons.inventory_2_outlined,
              accentColor: const Color(0xFFF59E0B),
              subtitle: isArabic ? 'قيمة السلع المحجوزة (انقر)' : 'Marchandises saisies',
              onTap: () => _showSeizuresDetailsSheet(context, recentVisits, isArabic, seizureVal),
            ),
            _buildMetricTile(
              title: isArabic ? 'الجاهزية والانتشار' : 'Taux de Déploiement',
              value: '$readinessRate%',
              icon: Icons.people_alt_outlined,
              accentColor: const Color(0xFF10B981),
              subtitle: isArabic ? '${att['presentToday'] ?? 0} حاضر من ${att['totalInspectors'] ?? 5} (انقر)' : '${att['presentToday'] ?? 0} présents / ${att['totalInspectors'] ?? 5}',
              onTap: () => _showReadinessDetailsSheet(context, att, isArabic),
            ),
            _buildMetricTile(
              title: isArabic ? 'اقتراحات الغلق الإداري' : 'Fermetures Proposées',
              value: '$closures',
              icon: Icons.block_outlined,
              accentColor: const Color(0xFFEC4899),
              subtitle: isArabic ? 'اقتراح غلق رسمي (انقر)' : 'Propositions Wali (Cliquez)',
              onTap: () => _showClosuresDetailsSheet(context, recentVisits, isArabic),
            ),
            _buildMetricTile(
              title: isArabic ? 'العينات للتحاليل' : 'Échantillons Labo',
              value: '$samples',
              icon: Icons.science_outlined,
              accentColor: const Color(0xFFA855F7),
              subtitle: isArabic ? 'عينة مقتطعة للمخبر (انقر)' : 'Analyses labo (Cliquez)',
              onTap: () => _showSamplesDetailsSheet(context, recentVisits, isArabic),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accentColor.withValues(alpha: 0.2),
        highlightColor: accentColor.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF240D2D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white24),
                ],
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentsSection(bool isArabic, Map<String, dynamic> fraud, Map<String, dynamic> comp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF240D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A2050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'المقارنة الرقابية بين المصالح الميدانية' : 'Performance par Service de Contrôle',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  children: [
                    Expanded(child: _buildDepartmentCard(isArabic, fraud, const Color(0xFF10B981), Icons.verified_user_outlined)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildDepartmentCard(isArabic, comp, const Color(0xFF38BDF8), Icons.balance_outlined)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildDepartmentCard(isArabic, fraud, const Color(0xFF10B981), Icons.verified_user_outlined),
                  const SizedBox(height: 12),
                  _buildDepartmentCard(isArabic, comp, const Color(0xFF38BDF8), Icons.balance_outlined),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(bool isArabic, Map<String, dynamic> data, Color color, IconData icon) {
    final name = data['name']?.toString() ?? '';
    final visits = data['visits'] ?? 0;
    final violations = data['violations'] ?? 0;
    final seizures = (data['seizuresValue'] as num?)?.toDouble() ?? 0.0;
    final int samples = (data['samples'] as num?)?.toInt() ?? 0;
    final int courtRef = (data['courtReferrals'] as num?)?.toInt() ?? 0;
    final int closures = (data['closures'] as num?)?.toInt() ?? 0;

    final formatter = NumberFormat('#,###', 'fr_DZ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMiniPill(isArabic ? 'معاينات: $visits' : 'Visites: $visits', color),
              _buildMiniPill(isArabic ? 'مخالفات: $violations' : 'Infractions: $violations', const Color(0xFFEF4444)),
              if (seizures > 0) _buildMiniPill(isArabic ? 'محجوزات: ${formatter.format(seizures)} دج' : 'Saisies: ${formatter.format(seizures)} DZD', const Color(0xFFF59E0B)),
              if (samples > 0) _buildMiniPill(isArabic ? 'عينات مخبر: $samples' : 'Labo: $samples', const Color(0xFFA855F7)),
              if (courtRef > 0) _buildMiniPill(isArabic ? 'محاضر قضائية: $courtRef' : 'PV Justice: $courtRef', const Color(0xFF38BDF8)),
              if (closures > 0) _buildMiniPill(isArabic ? 'اقتراح غلق: $closures' : 'Fermetures: $closures', const Color(0xFFEC4899)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCumulativeMacroCard(bool isArabic, Map<String, dynamic> cum) {
    final totalVisits = cum['totalVisits'] ?? 0;
    final violations = cum['violationsCount'] ?? 0;
    final seizures = (cum['totalSeizureValue'] as num?)?.toDouble() ?? 0.0;
    final closures = cum['closureProposalsCount'] ?? 0;
    final samples = cum['samplesCount'] ?? 0;
    final courtRef = cum['courtReferralsCount'] ?? 0;

    final formatter = NumberFormat('#,###', 'fr_DZ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E0A25),
            Color(0xFF15071A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_edu_outlined, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'الحصيلة الإجمالية التراكمية لنشاط الرقابة (سجل المديرية)' : 'Bilan Cumulé Global du Contrôle Économique',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isArabic ? 'سجل رسمي معتمد' : 'Registre Officiel',
                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFD4AF37)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildCumulativeMetric(isArabic ? 'إجمالي التدخلات التراكمية' : 'Total Visites', '$totalVisits', const Color(0xFF38BDF8)),
              _buildCumulativeMetric(isArabic ? 'إجمالي المخالفات المسجلة' : 'Total Infractions', '$violations', const Color(0xFFEF4444)),
              _buildCumulativeMetric(isArabic ? 'إجمالي قيمة المحجوزات' : 'Valeur Totale Saisies', '${formatter.format(seizures)} دج', const Color(0xFFF59E0B)),
              _buildCumulativeMetric(isArabic ? 'المحاضر القضائية' : 'PVs Transmis Justice', '$courtRef', const Color(0xFF10B981)),
              _buildCumulativeMetric(isArabic ? 'اقتراحات الغلق الإداري' : 'Fermetures Notifiées', '$closures', const Color(0xFFEC4899)),
              _buildCumulativeMetric(isArabic ? 'عينات التحاليل' : 'Analyses Labo', '$samples', const Color(0xFFA855F7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCumulativeMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInspectoratesDistribution(bool isArabic) {
    const list = AppConstants.defaultInspectorates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF240D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A2050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_outlined, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'شبكة المفتشيات والمقرات الرقابية الـ 8 بولاية سطيف' : 'Réseau des 8 Inspections Territoriales',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(color: Color(0xFF3B1A40), height: 12),
            itemBuilder: (context, idx) {
              final item = list[idx];
              final name = isArabic ? item.nameAr : item.nameFr;
              final radius = item.radiusMeters.toInt();
              final isHq = item.isMainDirectorate;

              return Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isHq ? const Color(0xFFD4AF37) : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: isHq ? FontWeight.bold : FontWeight.normal,
                        color: isHq ? const Color(0xFFD4AF37) : Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A20),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF4A2050)),
                    ),
                    child: Text(
                      '${radius}m',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopInspectorsCard(bool isArabic, List<dynamic> inspectors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF240D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A2050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech_outlined, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'المفتشون الأكثر تدخلاً اليوم' : 'Inspecteurs les Plus Actifs',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (inspectors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  isArabic ? 'لا توجد تدخلات مسجلة للمفتشين لهذا اليوم' : 'Aucune intervention enregistrée',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inspectors.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF3B1A40), height: 10),
              itemBuilder: (context, idx) {
                final insp = inspectors[idx] as Map<String, dynamic>;
                final name = insp['name']?.toString() ?? 'مفتش';
                final visits = insp['visitsCount'] ?? 0;
                final violations = insp['violationsCount'] ?? 0;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: idx == 0
                          ? const Color(0xFFD4AF37)
                          : idx == 1
                              ? Colors.grey.shade400
                              : const Color(0xFF4A2050),
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.white),
                      ),
                    ),
                    Text(
                      isArabic ? '$visits زيارة | $violations مخالفة' : '$visits v. | $violations inf.',
                      style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF38BDF8)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentInspectionsLog(bool isArabic, List<dynamic> visits) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF240D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A2050)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isArabic ? 'سجل التدخلات والمعاينات الميدانية الأحدث' : 'Dernières Visites de Contrôle',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                isArabic ? '${visits.length} معاينة مسجلة' : '${visits.length} visites',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFFD4AF37)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.shade600),
                    const SizedBox(height: 8),
                    Text(
                      isArabic ? 'لم تسجل أي معاينات ميدانية في التاريخ المحدد' : 'Aucune visite enregistrée à cette date',
                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visits.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF3B1A40), height: 16),
              itemBuilder: (context, idx) {
                final v = visits[idx] as Map<String, dynamic>;
                final shopName = v['ShopName'] ?? v['shopname'] ?? (isArabic ? 'محل تجاري' : 'Commerce');
                final shopType = v['ShopType'] ?? v['shoptype'] ?? (isArabic ? 'نشاط تجاري' : 'Activité');
                final location = v['LocationName'] ?? v['locationname'] ?? (isArabic ? 'سطيف' : 'Sétif');
                final hasViol = v['ViolationFound'] == true || v['violationfound'] == true || v['ViolationFound'] == 1;
                final violNotes = v['ViolationNotes'] ?? v['violationnotes'] ?? '';
                final isApproved = v['IsApproved'] == true || v['isapproved'] == true || v['IsApproved'] == 1;
                final checkInTime = v['CheckInTime'] ?? v['checkintime'] ?? '';
                final empName = (v['NomAr'] ?? v['nomar']) != null
                    ? '${v['NomAr'] ?? v['nomar']} ${v['PrenomAr'] ?? v['prenomar'] ?? ''}'.trim()
                    : (isArabic ? 'مفتش رقابة' : 'Inspecteur');

                String timeFormatted = '';
                try {
                  if (checkInTime.toString().isNotEmpty) {
                    final dt = DateTime.parse(checkInTime.toString());
                    timeFormatted = DateFormat('HH:mm').format(dt);
                  }
                } catch (_) {}

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasViol
                          ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                          : const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasViol
                              ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                              : const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasViol ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          color: hasViol ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$shopName ($shopType)',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (timeFormatted.isNotEmpty)
                                  Text(
                                    timeFormatted,
                                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFD4AF37)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic ? '📍 $location • بواسطة: $empName' : '📍 $location • Par: $empName',
                              style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey.shade400),
                            ),
                            if (hasViol && violNotes.toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⚠️ $violNotes',
                                  style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFFCA5A5)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isApproved ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isApproved ? (isArabic ? 'مؤشرة ✔️' : 'Visé') : (isArabic ? 'قيد المراجعة' : 'En cours'),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MODAL DETAILS SHEETS ON CARD CLICK
  // -------------------------------------------------------------

  void _showVisitsDetailsSheet(BuildContext context, List<dynamic> visits, bool isArabic) {
    _showDetailsModal(
      title: isArabic ? 'قائمة المعاينات والتدخلات الميدانية المسجلة' : 'Toutes les interventions terrain',
      icon: Icons.storefront_outlined,
      accentColor: const Color(0xFF38BDF8),
      items: visits,
      isArabic: isArabic,
    );
  }

  void _showViolationsDetailsSheet(BuildContext context, List<dynamic> visits, bool isArabic) {
    final filtered = visits.where((v) => v['ViolationFound'] == true || v['violationfound'] == true || v['ViolationFound'] == 1).toList();
    _showDetailsModal(
      title: isArabic ? 'المخالفات والمحاضر القضائية المحررة' : 'Infractions & Procès-Verbaux',
      icon: Icons.gavel_outlined,
      accentColor: const Color(0xFFEF4444),
      items: filtered,
      isArabic: isArabic,
    );
  }

  void _showSeizuresDetailsSheet(BuildContext context, List<dynamic> visits, bool isArabic, double totalSeizureVal) {
    final filtered = visits.where((v) {
      final val = (v['SeizureValue'] as num?)?.toDouble() ?? double.tryParse(v['SeizureValue']?.toString() ?? '0') ?? 0.0;
      final notes = '${v['ViolationNotes'] ?? ''} ${v['Notes'] ?? ''}';
      return val > 0 || notes.contains('حجز');
    }).toList();

    final formatter = NumberFormat('#,###', 'fr_DZ');

    _showDetailsModal(
      title: isArabic ? 'تفاصيل السلع والمحجوزات (الإجمالي: ${formatter.format(totalSeizureVal)} دج)' : 'Détails des Marchandises Saisies',
      icon: Icons.inventory_2_outlined,
      accentColor: const Color(0xFFF59E0B),
      items: filtered,
      isArabic: isArabic,
    );
  }

  void _showClosuresDetailsSheet(BuildContext context, List<dynamic> visits, bool isArabic) {
    final filtered = visits.where((v) {
      final notes = '${v['LegalAction'] ?? ''} ${v['ViolationNotes'] ?? ''}';
      return notes.contains('غلق') || notes.contains('إغلاق');
    }).toList();

    _showDetailsModal(
      title: isArabic ? 'اقتراحات الغلق الإداري للمحلات التجارية' : 'Propositions de Fermeture Administrative',
      icon: Icons.block_outlined,
      accentColor: const Color(0xFFEC4899),
      items: filtered,
      isArabic: isArabic,
    );
  }

  void _showSamplesDetailsSheet(BuildContext context, List<dynamic> visits, bool isArabic) {
    final filtered = visits.where((v) {
      final notes = '${v['LegalAction'] ?? ''} ${v['ViolationNotes'] ?? ''}';
      return notes.contains('عين') || notes.contains('تحليل') || notes.contains('مخبر');
    }).toList();

    _showDetailsModal(
      title: isArabic ? 'العينات المقتطعة للتحاليل المخبرية وقمع الغش' : 'Échantillons Prélevés pour Analyse',
      icon: Icons.science_outlined,
      accentColor: const Color(0xFFA855F7),
      items: filtered,
      isArabic: isArabic,
    );
  }

  void _showReadinessDetailsSheet(BuildContext context, Map<String, dynamic> att, bool isArabic) {
    final total = att['totalInspectors'] ?? 5;
    final present = att['presentToday'] ?? 0;
    final absent = att['absentToday'] ?? (total - present);
    final rate = att['readinessRate']?.toString() ?? '0.0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E0A25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF4A2050)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_alt_outlined, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'تقرير الجاهزية والانتشار الميداني للمفتشين' : 'Rapport de Déploiement Opérationnel',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            isArabic ? 'نسبة الجاهزية الكلية: $rate%' : 'Taux global: $rate%',
                            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildMiniStatBox(isArabic ? 'إجمالي المفتشين' : 'Total', '$total', const Color(0xFF38BDF8))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMiniStatBox(isArabic ? 'حاضرون بالميدان' : 'Présents', '$present', const Color(0xFF10B981))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildMiniStatBox(isArabic ? 'غياب / لم يسجل' : 'Absents', '$absent', const Color(0xFFEF4444))),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isArabic ? 'إغلاق' : 'Fermer',
                    style: const TextStyle(fontFamily: 'Tajawal', color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF240D2D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Tajawal', fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _showDetailsModal({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<dynamic> items,
    required bool isArabic,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E0A25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF4A2050)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF4A2050), height: 24),
                if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade600),
                          const SizedBox(height: 12),
                          Text(
                            isArabic ? 'لا توجد سجلات مسجلة لهذا المؤشر في التاريخ المحدد' : 'Aucun enregistrement pour cet indicateur',
                            style: TextStyle(fontFamily: 'Tajawal', fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(color: Color(0xFF3B1A40), height: 16),
                      itemBuilder: (context, idx) {
                        final v = items[idx] as Map<String, dynamic>;
                        final shopName = v['ShopName'] ?? v['shopname'] ?? (isArabic ? 'محل تجاري' : 'Commerce');
                        final shopType = v['ShopType'] ?? v['shoptype'] ?? (isArabic ? 'نشاط تجاري' : 'Activité');
                        final location = v['LocationName'] ?? v['locationname'] ?? (isArabic ? 'سطيف' : 'Sétif');
                        final violNotes = v['ViolationNotes'] ?? v['violationnotes'] ?? '';
                        final legalAction = v['LegalAction'] ?? v['legalaction'] ?? '';
                        final empName = (v['NomAr'] ?? v['nomar']) != null
                            ? '${v['NomAr'] ?? v['nomar']} ${v['PrenomAr'] ?? v['prenomar'] ?? ''}'.trim()
                            : (isArabic ? 'مفتش رقابة' : 'Inspecteur');

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF240D2D),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$shopName ($shopType)',
                                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#${idx + 1}',
                                      style: TextStyle(fontFamily: 'Tajawal', fontSize: 10, color: accentColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('📍 $location • بواسطة: $empName', style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.grey.shade400)),
                              if (violNotes.toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('⚠️ المخالفة: $violNotes', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFFFCA5A5))),
                              ],
                              if (legalAction.toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('⚖️ الإجراء: $legalAction', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Color(0xFF38BDF8))),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportExecutivePdf() {
    final isArabic = AppLocalizations.of(context).isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? '📄 جاري استخراج الحصيلة الإحصائية الرسمية للمديرية...' : 'Génération du rapport PDF...',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: const Color(0xFF240D2D),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
