import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/services/auth_service.dart';
import 'package:drh_setif_tracker/utils/app_localizations.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/screens/director/director_screen.dart';
import 'package:drh_setif_tracker/screens/head/head_screen.dart';
import 'package:drh_setif_tracker/screens/bureau/bureau_screen.dart';
import 'package:drh_setif_tracker/screens/inspector/inspector_screen.dart';

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
      duration: const Duration(milliseconds: 800),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
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
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
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
      await auth.login(username, password);

      if (!mounted) return;

      Widget nextScreen;
      switch (auth.currentUser?.role) {
        case 'admin':
        case 'director':
          nextScreen = const DirectorScreen();
          break;
        case 'head_of_department':
          nextScreen = const HeadScreen();
          break;
        case 'bureau_chief':
          nextScreen = const BureauScreen();
          break;
        default:
          nextScreen = const InspectorScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => nextScreen,
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
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
        decoration: const BoxDecoration(
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
                        const Color(0xFFD4AF37).withValues(alpha: 0.08),
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
                        const Color(0xFF881337).withValues(alpha: 0.1),
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
                  icon: const Icon(
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
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
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(
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
                              child: const Center(
                                child: Icon(
                                  Icons.shield_outlined,
                                  size: 48,
                                  color: Color(0xFFD4AF37),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          loc.isArabic
                              ? 'نظام تتبع المفتشين'
                              : 'Suivi des Inspecteurs',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          loc.isArabic
                              ? 'مديرية التجارة — سطيف'
                              : 'Direction du Commerce — Sétif',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 40),

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
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  labelText: loc.loginUsername,
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFFD4AF37),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF3D1A45),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4A2050),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4A2050),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFD4AF37),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                          ),
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: loc.loginPassword,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: Color(0xFFD4AF37),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3D1A45),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF4A2050)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF4A2050)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFD4AF37),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Error
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: Color(0xFFEF4444),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Login button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: const Color(0xFF1A0A1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF1A0A1F),
                                    ),
                                  )
                                : Text(
                                    loc.loginButton,
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Demo users
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D1035).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4A2050).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                loc.isArabic
                                    ? 'حسابات تجريبية'
                                    : 'Comptes de test',
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
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
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.chevron_left, size: 16, color: Colors.white38),
            const Spacer(),
            Text(
              '$username / $password',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.white54,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              role,
              style: const TextStyle(
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
