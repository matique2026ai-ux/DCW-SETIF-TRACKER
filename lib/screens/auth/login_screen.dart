import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../director/director_screen.dart';
import '../head/head_screen.dart';
import '../bureau/bureau_screen.dart';
import '../inspector/inspector_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _slideController;
  late AnimationController _shakeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeController, curve: ShakeCurve()));

    _slideController.forward();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'أدخل اسم المستخدم وكلمة المرور');
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      await auth.login(_usernameCtrl.text, _passwordCtrl.text);

      if (!mounted) return;

      Widget nextScreen;
      switch (auth.currentUser?.role) {
        case 'admin':
        case 'director':
          nextScreen = DirectorScreen();
          break;
        case 'head_of_department':
          nextScreen = HeadScreen();
          break;
        case 'bureau_chief':
          nextScreen = BureauScreen();
          break;
        default:
          nextScreen = InspectorScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset(0.1, 0), end: Offset.zero)
                    .animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                    ),
                child: child,
              ),
            );
          },
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1A0A1F), Color(0xFF2D1035), Color(0xFF4C0519)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFD4AF37).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF881337).withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Language toggle
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: () => langProvider.toggleLanguage(),
                  icon: Icon(
                    Icons.language,
                    color: Color(0xFFD4AF37),
                    size: 28,
                  ),
                ),
              ),

              // Main content
              Center(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFD4AF37),
                                Color(0xFFFDE68A),
                                Color(0xFF92400E),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Color(0xFF2D1035),
                                    Color(0xFF1A0A1F),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 48,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Title
                        Text(
                          loc.isArabic
                              ? 'نظام تتبع المفتشين'
                              : 'Suivi des Inspecteurs',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          loc.isArabic
                              ? 'مديرية التجارة — سطيف'
                              : 'Direction du Commerce — Sétif',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        SizedBox(height: 40),

                        // Username field
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                sin(_shakeAnimation.value * 2 * pi * 3) * 5,
                                0,
                              ),
                              child: TextField(
                                controller: _usernameCtrl,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  labelText: loc.loginUsername,
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Color(0xFFD4AF37),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF3D1A45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF4A2050),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFF4A2050),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Color(0xFFD4AF37),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),

                        // Password field
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                          ),
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: loc.loginPassword,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFFD4AF37),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Color(0xFFD4AF37).withValues(alpha: 0.6),
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            filled: true,
                            fillColor: Color(0xFF3D1A45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Color(0xFF4A2050)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Color(0xFF4A2050)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Color(0xFFD4AF37),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),

                        // Error
                        if (_error != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD4AF37),
                              foregroundColor: Color(0xFF1A0A1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF1A0A1F),
                                    ),
                                  )
                                : Text(
                                    loc.loginButton,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Demo users
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Color(0xFF2D1035).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF4A2050).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                loc.isArabic
                                    ? 'حسابات تجريبية'
                                    : 'Comptes de test',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              _demoUser(
                                'directeur',
                                'directeur123',
                                loc.roleDirector,
                              ),
                              _demoUser(
                                'chef_concurrence',
                                'chef123',
                                loc.roleHead,
                              ),
                              _demoUser(
                                'bureau_user',
                                'bureau123',
                                loc.roleBureau,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _demoUser(String username, String password, String role) {
    return InkWell(
      onTap: () {
        _usernameCtrl.text = username;
        _passwordCtrl.text = password;
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.chevron_left, size: 16, color: Colors.white38),
            Spacer(),
            Text(
              '$username / $password',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
            SizedBox(width: 8),
            Text(
              role,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShakeCurve extends Curve {
  @override
  double transformInternal(double t) {
    return sin(t * 3 * pi);
  }
}
