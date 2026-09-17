import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/theme.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/screens/auth/login_screen.dart';
import 'package:drh_setif_tracker/screens/director/director_map_tab.dart';
import 'package:drh_setif_tracker/screens/director/director_reports_tab.dart';
import 'package:drh_setif_tracker/screens/director/director_deductions_tab.dart';
import 'package:drh_setif_tracker/screens/common/change_password_dialog.dart';
import 'package:drh_setif_tracker/widgets/golden_emblem_coin.dart';


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
    _tabController = TabController(length: 3, vsync: this);
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF260D2E),
          elevation: 4,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Official Golden 3D Medallion Avatar
              const GoldenEmblemCoin(
                size: 38,
                showOuterGlow: false,
                enableFloating: false,
                animateGleam: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            loc.roleDirector,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'الآمر بالصرف',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    const Text(
                      'مديرية التجارة — ولاية سطيف',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10.5,
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
            // Quick Action Buttons in sleek glassmorphic capsules
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37), size: 18),
                    tooltip: loc.isArabic ? 'تغيير كلمة المرور' : 'Changer mot de passe',
                    onPressed: () => ChangePasswordDialog.show(context),
                  ),
                  Container(width: 1, height: 16, color: Colors.white12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.language, color: Colors.white70, size: 18),
                    tooltip: loc.isArabic ? 'تغيير اللغة' : 'Changer de langue',
                    onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
                  ),
                  Container(width: 1, height: 16, color: Colors.white12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                    tooltip: loc.isArabic ? 'تسجيل الخروج' : 'Déconnexion',
                    onPressed: () => _showLogoutDialog(),
                  ),
                ],
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: const Color(0xFFD4AF37),
            indicatorWeight: 3.0,
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white60,
            labelStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.map_outlined, size: 20),
                text: loc.navMap,
              ),
              Tab(
                icon: const Icon(Icons.assessment_outlined, size: 20),
                text: loc.navReports,
              ),
              Tab(
                icon: const Icon(Icons.gavel_outlined, size: 20),
                text: loc.navDeductions,
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            DirectorMapTab(),
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
