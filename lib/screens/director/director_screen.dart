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
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.roleDirector,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'DCW SETIF',
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
              icon: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
              tooltip: loc.isArabic ? 'تغيير كلمة المرور' : 'Changer mot de passe',
              onPressed: () => ChangePasswordDialog.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.language, color: Colors.white70),
              tooltip: loc.isArabic ? 'تغيير اللغة' : 'Changer de langue',
              onPressed: () =>
                  context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              onPressed: () => _showLogoutDialog(),
            ),
          ],

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
