import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Edge-to-edge premium feel — transparent system bars.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF4F4F6),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final isLoggedIn = await TokenStorage.isLoggedIn();

  runApp(
    SipantawApp(isLoggedIn: isLoggedIn),
  );
}

class SipantawApp extends StatelessWidget {
  final bool isLoggedIn;

  const SipantawApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPANTAW',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(isLoggedIn: isLoggedIn),
        '/login': (context) => const LoginPage(),
        '/otp': (context) => const OtpPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
      builder: (context, child) {
        // Clamp text scaling to keep layouts premium & consistent.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
