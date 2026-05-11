import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// OtpPage — alur OTP sudah ditangani di LoginPage.
/// File ini tetap ada untuk route '/otp' dan redirect ke login.
class OtpPage extends StatelessWidget {
  const OtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return const Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.black),
      ),
    );
  }
}
