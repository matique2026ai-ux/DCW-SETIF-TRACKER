import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'utils/app_localizations.dart';
import 'services/auth_service.dart';
import 'providers/language_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DRHTrackerApp());
}

class DRHTrackerApp extends StatelessWidget {
  const DRHTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return MaterialApp(
            title: 'DCW-SETIF-TRACKER',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            locale: langProvider.locale,
            localizationsDelegates: [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('ar', ''), Locale('fr', '')],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
