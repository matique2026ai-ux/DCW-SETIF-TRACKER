import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';

class AppFooter extends StatelessWidget {
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  const AppFooter({
    super.key,
    this.showDivider = false,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;

    return Container(
      width: double.infinity,
      padding: padding,
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E0B26).withValues(alpha: 0.85),
                  const Color(0xFF13061A).withValues(alpha: 0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 3D Gold Engineering Medallion Seal Avatar (Micro-Refined)
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/engineering_seal.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.workspace_premium_rounded,
                        size: 10,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Crisp, elegant, micro-refined golden text
                Text(
                  isArabic
                      ? 'جميع حقوق التصميم والبرمجة محفوظة © المهندس عكرور توفيق'
                      : 'Copyright © 2026 ING Akrour ToufiK',
                  style: TextStyle(
                    fontFamily: isArabic ? 'Tajawal' : null,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: isArabic ? 0.2 : 0.4,
                    color: const Color(0xFFFFDF7A),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.9),
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
