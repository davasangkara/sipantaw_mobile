import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/storage/token_storage.dart';
import 'core/services/biometric_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/permission_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFF4F4F6),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final prefs = await SharedPreferences.getInstance();
  final permissionDone = prefs.getBool('permission_onboarding_done') ?? false;

  final isLoggedIn = await TokenStorage.isLoggedIn();
  final canBiometric = await TokenStorage.canLoginWithBiometric();
  final biometricEnabled = await BiometricService.isBiometricEnabled();

  runApp(SipantawApp(
    isLoggedIn: isLoggedIn,
    canBiometricLogin: canBiometric && biometricEnabled,
    showPermissionOnboarding: !permissionDone,
  ));
}

class SipantawApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool canBiometricLogin;
  final bool showPermissionOnboarding;

  const SipantawApp({
    super.key,
    required this.isLoggedIn,
    required this.canBiometricLogin,
    required this.showPermissionOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIPANTAW WFA',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      theme: AppTheme.light(),
      home: showPermissionOnboarding
          ? _PermissionGate(
              isLoggedIn: isLoggedIn,
              canBiometricLogin: canBiometricLogin,
            )
          : SplashScreen(
              isLoggedIn: isLoggedIn,
              canBiometricLogin: canBiometricLogin,
            ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/otp': (context) => const OtpPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
      builder: (context, child) {
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

/// Gate widget — tampilkan permission onboarding, lalu lanjut ke splash
class _PermissionGate extends StatelessWidget {
  final bool isLoggedIn;
  final bool canBiometricLogin;

  const _PermissionGate({
    required this.isLoggedIn,
    required this.canBiometricLogin,
  });

  Future<void> _markDone(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_onboarding_done', true);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            isLoggedIn: isLoggedIn,
            canBiometricLogin: canBiometricLogin,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionPage(
      onDone: () => _markDone(context),
    );
  }
}
