import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';

class AppFooter extends StatelessWidget {
  final bool showDivider;
  final EdgeInsetsGeometry padding;

  const AppFooter({
    super.key,
    this.showDivider = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0B15).withValues(alpha: 0.85),
        border: showDivider
            ? const Border(
                top: BorderSide(
                  color: Color(0x26D4AF37), // 15% gold subtle border
                  width: 0.8,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: const Icon(
                Icons.code_rounded,
                size: 10,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isArabic
                    ? 'جميع حقوق التصميم والبرمجة محفوظة © المهندس عكرور توفيق'
                    : 'Copyright © 2026 ING Akrour ToufiK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: isArabic ? 'Tajawal' : null,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: isArabic ? 0.2 : 0.5,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
