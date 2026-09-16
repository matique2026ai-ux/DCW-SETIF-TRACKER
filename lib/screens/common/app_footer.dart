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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF140A1A).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.06),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 12,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 5),
                Text(
                  isArabic
                      ? 'جميع حقوق التصميم والبرمجة محفوظة © المهندس عكرور توفيق'
                      : 'Copyright © 2026 ING Akrour ToufiK',
                  style: TextStyle(
                    fontFamily: isArabic ? 'Tajawal' : null,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: isArabic ? 0.25 : 0.5,
                    color: const Color(0xFFD4AF37),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1.0,
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
