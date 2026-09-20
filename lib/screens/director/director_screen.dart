import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/director/director_map_tab.dart';
import 'package:drh_setif_tracker/screens/director/director_analytics_tab.dart';
import 'package:drh_setif_tracker/screens/director/director_reports_tab.dart';
import 'package:drh_setif_tracker/screens/director/director_deductions_tab.dart';
import 'package:drh_setif_tracker/screens/common/change_password_dialog.dart';
import 'package:drh_setif_tracker/widgets/modern_executive_navbar.dart';


class DirectorScreen extends StatefulWidget {
  const DirectorScreen({super.key});

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Directionality(
      textDirection: loc.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: ModernExecutiveNavbar(
          title: loc.roleDirector,
          badgeText: loc.isArabic ? 'الآمر بالصرف' : 'Ordonnateur',
          subtitle: loc.isArabic ? 'مديرية التجارة — ولاية سطيف' : 'Direction du Commerce — Wilaya de Sétif',
          selectedIndex: _tabController.index,
          onTabSelected: (idx) {
            _tabController.animateTo(idx);
            setState(() {});
          },
          tabs: [
            ModernNavTabItem(
              icon: Icons.map_outlined,
              label: loc.navMap,
            ),
            ModernNavTabItem(
              icon: Icons.analytics_outlined,
              label: loc.isArabic ? 'الإحصائيات الرقابية' : 'Statistiques de Contrôle',
            ),
            ModernNavTabItem(
              icon: Icons.assessment_outlined,
              label: loc.navReports,
            ),
            ModernNavTabItem(
              icon: Icons.gavel_outlined,
              label: loc.navDeductions,
            ),
          ],
          onPasswordChange: () => ChangePasswordDialog.show(context),
          onLogout: _showLogoutDialog,
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            DirectorMapTab(),
            DirectorAnalyticsTab(),
            DirectorReportsTab(),
            DirectorDeductionsTab(),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.CardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          loc.logout,
          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
        ),
        content: Text(
          loc.logoutConfirm,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel, style: const TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.DangerColor,
            ),
            child: Text(loc.logout, style: const TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }
}
