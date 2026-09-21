import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drh_setif_tracker/providers/language_provider.dart';
import 'package:drh_setif_tracker/widgets/golden_emblem_coin.dart';

class ModernNavTabItem {
  final IconData icon;
  final String label;
  final int? badgeCount;

  const ModernNavTabItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });
}

class ModernExecutiveNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? badgeText;
  final String subtitle;
  final List<ModernNavTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onRefresh;
  final VoidCallback? onPasswordChange;
  final VoidCallback? onMasterPinChange;
  final VoidCallback? onLogout;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? customTitleWidget;
  final List<Widget>? additionalActions;

  const ModernExecutiveNavbar({
    super.key,
    required this.title,
    this.badgeText,
    required this.subtitle,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onRefresh,
    this.onPasswordChange,
    this.onMasterPinChange,
    this.onLogout,
    this.showBackButton = false,
    this.onBack,
    this.customTitleWidget,
    this.additionalActions,
  });

  @override
  Size get preferredSize {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
      if (view != null) {
        final screenWidth = view.physicalSize.width / view.devicePixelRatio;
        if (screenWidth < 900 && tabs.isNotEmpty) {
          return const Size.fromHeight(116);
        }
      }
    } catch (_) {}
    return const Size.fromHeight(68);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<LanguageProvider>().isArabic;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 900;
    final hasTabs = tabs.isNotEmpty;
    final navHeight = (isCompact && hasTabs) ? 116.0 : (isCompact ? 64.0 : 68.0);

    return Container(
      height: navHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1C0924).withValues(alpha: 0.96),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x33D4AF37),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: isCompact && hasTabs
            ? _buildCompactTwoTierLayout(context, isAr)
            : _buildSingleTierLayout(context, isAr, isCompact),
      ),
    );
  }

  Widget _buildCompactTwoTierLayout(BuildContext context, bool isAr) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top tier: Branding + Title + Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37), size: 18),
                  tooltip: isAr ? 'الرجوع' : 'Retour',
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                const SizedBox(width: 4),
              ],
              const GoldenEmblemCoin(
                size: 30,
                showOuterGlow: false,
                enableFloating: false,
                animateGleam: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: customTitleWidget ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badgeText != null && badgeText!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  badgeText!,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 9.5,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
              ),
              const SizedBox(width: 6),
              if (additionalActions != null) ...additionalActions!,
              _buildActionsCapsule(context, isAr, isCompact: true),
            ],
          ),
        ),
        // Bottom tier: Horizontally Scrollable Segmented Pill Tabs
        Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF100516).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0x33D4AF37),
              width: 0.8,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(tabs.length, (idx) {
                final tab = tabs[idx];
                final isSelected = selectedIndex == idx;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTabSelected(idx),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tab.icon,
                              size: 14,
                              color: isSelected ? const Color(0xFF16061D) : Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFF16061D) : Colors.white70,
                              ),
                            ),
                            if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF16061D) : const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${tab.badgeCount}',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleTierLayout(BuildContext context, bool isAr, bool isCompact) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37), size: 20),
              tooltip: isAr ? 'الرجوع' : 'Retour',
              onPressed: onBack ?? () => Navigator.maybePop(context),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
          ],
          const GoldenEmblemCoin(
            size: 38,
            showOuterGlow: false,
            enableFloating: false,
            animateGleam: false,
          ),
          const SizedBox(width: 12),
          if (customTitleWidget != null)
            customTitleWidget!
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (badgeText != null && badgeText!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText!,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10.5,
                    color: Color(0xFFD4AF37),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          if (!isCompact && tabs.isNotEmpty) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF100516).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0x33D4AF37),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tabs.length, (idx) {
                  final tab = tabs[idx];
                  final isSelected = selectedIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTabSelected(idx),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab.icon,
                                size: 16,
                                color: isSelected ? const Color(0xFF16061D) : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF16061D) : Colors.white70,
                                ),
                              ),
                              if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF16061D) : const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${tab.badgeCount}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFFD4AF37) : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
          ] else ...[
            const Spacer(),
          ],
          if (additionalActions != null) ...additionalActions!,
          _buildActionsCapsule(context, isAr, isCompact: false),
        ],
      ),
    );
  }

  Widget _buildActionsCapsule(BuildContext context, bool isAr, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4, vertical: isCompact ? 1 : 3),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onRefresh != null) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.refresh, color: const Color(0xFFD4AF37), size: isCompact ? 15 : 17),
              tooltip: isAr ? 'تحديث البيانات' : 'Actualiser',
              onPressed: onRefresh,
              padding: isCompact ? const EdgeInsets.all(2) : const EdgeInsets.all(8),
              constraints: isCompact ? const BoxConstraints(minWidth: 26, minHeight: 26) : null,
            ),
            Container(width: 1, height: isCompact ? 12 : 16, color: Colors.white12),
          ],
          if (onPasswordChange != null) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.lock_reset, color: const Color(0xFFD4AF37), size: isCompact ? 15 : 17),
              tooltip: isAr ? 'تغيير كلمة المرور' : 'Changer mot de passe',
              onPressed: onPasswordChange,
              padding: isCompact ? const EdgeInsets.all(2) : const EdgeInsets.all(8),
              constraints: isCompact ? const BoxConstraints(minWidth: 26, minHeight: 26) : null,
            ),
            Container(width: 1, height: isCompact ? 12 : 16, color: Colors.white12),
          ],
          if (onMasterPinChange != null) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.shield, color: const Color(0xFFD4AF37), size: isCompact ? 15 : 17),
              tooltip: isAr ? 'تغيير رمز الأمان السري (Master PIN)' : 'Changer Master PIN',
              onPressed: onMasterPinChange,
              padding: isCompact ? const EdgeInsets.all(2) : const EdgeInsets.all(8),
              constraints: isCompact ? const BoxConstraints(minWidth: 26, minHeight: 26) : null,
            ),
            Container(width: 1, height: isCompact ? 12 : 16, color: Colors.white12),
          ],
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.language, color: Colors.white70, size: isCompact ? 15 : 17),
            tooltip: isAr ? 'تغيير اللغة' : 'Changer de langue',
            onPressed: () => context.read<LanguageProvider>().toggleLanguage(),
            padding: isCompact ? const EdgeInsets.all(2) : const EdgeInsets.all(8),
            constraints: isCompact ? const BoxConstraints(minWidth: 26, minHeight: 26) : null,
          ),
          if (onLogout != null) ...[
            Container(width: 1, height: isCompact ? 12 : 16, color: Colors.white12),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.logout, color: const Color(0xFFEF4444), size: isCompact ? 15 : 17),
              tooltip: isAr ? 'تسجيل الخروج' : 'Déconnexion',
              onPressed: onLogout,
              padding: isCompact ? const EdgeInsets.all(2) : const EdgeInsets.all(8),
              constraints: isCompact ? const BoxConstraints(minWidth: 26, minHeight: 26) : null,
            ),
          ],
        ],
      ),
    );
  }
}
