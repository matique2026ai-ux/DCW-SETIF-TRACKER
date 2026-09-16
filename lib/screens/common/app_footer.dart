import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';

class AppFooter extends StatelessWidget {
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  const AppFooter({
    super.key,
    this.showDivider = false,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E0B26).withValues(alpha: 0.90),
                  const Color(0xFF13061A).withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 3D Gold Engineering Medallion Seal Avatar
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/engineering_seal.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.workspace_premium_rounded,
                        size: 14,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Crisp, high-contrast, perfectly readable golden text
                Text(
                  isArabic
                      ? 'جميع حقوق التصميم والبرمجة محفوظة © المهندس عكرور توفيق'
                      : 'Copyright © 2026 ING Akrour ToufiK',
                  style: TextStyle(
                    fontFamily: isArabic ? 'Tajawal' : null,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isArabic ? 0.2 : 0.4,
                    color: const Color(0xFFFFDF7A),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.9),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
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
