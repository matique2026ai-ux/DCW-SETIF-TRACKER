import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../auth/login_screen.dart';

class HeadScreen extends StatefulWidget {
  const HeadScreen({super.key});

  @override
  State<HeadScreen> createState() => _HeadScreenState();
}

class _HeadScreenState extends State<HeadScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.BackgroundColor,
        appBar: AppBar(
          backgroundColor: Color(0xFF2D1035),
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFF92400E)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.work_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                loc.roleHead,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.language, color: Color(0xFFD4AF37)),
              onPressed: () =>
                  context.read<LanguageProvider>().toggleLanguage(),
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white70),
              onPressed: () {
                context.read<AuthService>().logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: _currentIndex == 0 ? _programTab(loc) : _employeesTab(loc),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Color(0xFF2D1035),
            border: Border(
              top: BorderSide(
                color: AppTheme.BorderColor.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.calendar_month, loc.navProgram),
                  _navItem(1, Icons.people, loc.navEmployees),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Color(0xFFD4AF37).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? Color(0xFFD4AF37) : AppTheme.TextSecondary,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: isSelected ? Color(0xFFD4AF37) : AppTheme.TextSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _programTab(AppLocalizations loc) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.BorderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.AccentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month,
                size: 40,
                color: AppTheme.AccentColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              loc.weeklyProgram,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              loc.distributeProgram,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.TextSecondary,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add),
              label: Text(
                loc.addProgram,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.AccentColor,
                foregroundColor: Colors.black,
                padding: EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _employeesTab(AppLocalizations loc) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.CardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.BorderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.PrimaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people, size: 40, color: AppTheme.PrimaryColor),
            ),
            SizedBox(height: 20),
            Text(
              loc.navEmployees,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              loc.distributeProgram,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.TextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
