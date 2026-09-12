import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/theme.dart';
import '../screens/auth/login_screen.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onPressed;
  final IconData? backIcon;

  const AppBarWidget({
    super.key,
    required this.title,
    this.onPressed,
    this.backIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.PrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
        ),
        textDirection: TextDirection.rtl,
      ),
      leading: backIcon != null
          ? IconButton(
              icon: Icon(backIcon, color: Colors.white),
              onPressed: onPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            context.read<AuthService>().logout();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
