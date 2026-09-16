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
import 'package:drh_setif_tracker/screens/common/app_footer.dart';


class DirectorScreen extends StatefulWidget {
  const DirectorScreen({super.key});

  @override
  State<DirectorScreen> createState() => _DirectorScreenState();
}

class _DirectorScreenState extends State<DirectorScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
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
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Official Golden 3D Medallion Avatar
                  const GoldenEmblemCoin(
                    size: 36,
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
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            DirectorMapTab(),
            DirectorReportsTab(),
            DirectorDeductionsTab(),
          ],
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D1035),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.BorderColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(0, Icons.map_outlined, Icons.map, loc.navMap),
                      _navItem(
                        1,
                        Icons.assessment_outlined,
                        Icons.assessment,
                        loc.navReports,
                      ),
                      _navItem(
                        2,
                        Icons.money_off_outlined,
                        Icons.money_off,
                        loc.navDeductions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? const Color(0xFFD4AF37) : AppTheme.TextSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: isSelected ? const Color(0xFFD4AF37) : AppTheme.TextSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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
