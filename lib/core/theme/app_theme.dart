import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SIPANTAW — Premium Monochrome Design System
///
/// Inspired by luxury wellness/meal-planner apps.
/// Palette: black & white monochrome + neon pastel accents
/// (neon cyan, soft lime, pastel blue). Large rounded corners,
/// soft floating shadows, airy spacing, elegant sans serif.
///
/// NOTE: Legacy field names (teal/tealDeep/mint/etc.) are kept
/// intentionally so existing feature screens remain compilable —
/// the values are remapped to the new monochrome-accent system.
class AppColors {
  AppColors._();

  // ── Core Monochrome ───────────────────────────────────────
  static const black = Color(0xFF0A0A0A);
  static const ink = Color(0xFF111111);
  static const slate = Color(0xFF1F2024);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAFA);
  static const canvas = Color(0xFFF4F4F6);

  // ── Neon Pastel Accents ───────────────────────────────────
  static const neonCyan = Color(0xFF8BE8F5);   // hero cyan
  static const neonCyanDeep = Color(0xFF5AD7E8);
  static const softLime = Color(0xFFE8FF70);   // signature lime
  static const softLimeDeep = Color(0xFFD9F24A);
  static const pastelBlue = Color(0xFFB9CFFF); // soft blue
  static const pastelBlueDeep = Color(0xFF8CA8F2);
  static const blush = Color(0xFFFFD6E8);

  // ── Backgrounds / Surfaces ────────────────────────────────
  static const bg = canvas;
  static const bgAlt = Color(0xFFEDEDEF);
  static const surface = white;
  static const surfaceMuted = Color(0xFFF1F1F3);
  static const border = Color(0xFFE6E6EA);
  static const divider = Color(0xFFEDEDEF);

  // ── Text (pure monochrome hierarchy) ──────────────────────
  static const textPrimary = Color(0xFF0A0A0A);
  static const textSecondary = Color(0xFF4B4B52);
  static const textMuted = Color(0xFF9A9AA3);
  static const textDisabled = Color(0xFFCFCFD5);

  // ── Semantic (subtle, modern) ─────────────────────────────
  static const success = Color(0xFF3FBF8A);
  static const successSoft = Color(0xFFE6F9F0);
  static const warning = Color(0xFFE8B13A);
  static const warningSoft = Color(0xFFFFF6E2);
  static const danger = Color(0xFFE55A5A);
  static const dangerSoft = Color(0xFFFCECEC);
  static const info = pastelBlueDeep;
  static const infoSoft = Color(0xFFEEF2FF);

  // ── Accent (for category/data viz) ────────────────────────
  static const indigo = pastelBlueDeep;
  static const violet = Color(0xFFC9B7FF);
  static const amber = softLimeDeep;
  static const coral = Color(0xFFFFB9C4);

  // ── Legacy aliases (back-compat for existing screens) ─────
  // These map the old "teal" system to the new black/cyan scheme
  // so no feature page breaks while we roll out the redesign.
  static const teal = black;            // primary → black
  static const tealDeep = ink;          // deeper black
  static const tealSoft = Color(0xFFF1F1F3); // neutral tint
  static const mint = softLime;         // accent mint → lime
  static const aqua = neonCyan;         // highlight → cyan

  // ── Gradients ─────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2024), Color(0xFF0A0A0A)],
  );

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2024), Color(0xFF111111), Color(0xFF0A0A0A)],
    stops: [0.0, 0.55, 1.0],
  );

  static const gradientMint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [softLime, softLimeDeep],
  );

  static const gradientCyan = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonCyanDeep],
  );

  static const gradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F2024), Color(0xFF111111), Color(0xFF000000)],
    stops: [0.0, 0.55, 1.0],
  );

  static const gradientSplash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAFAFA), Color(0xFFF4F4F6), Color(0xFFEDEDEF)],
    stops: [0.0, 0.5, 1.0],
  );
}

/// Premium shadow presets — soft, diffused, floating feel.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get xs => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 40,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floating => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ];

  static List<BoxShadow> tinted(Color color, {double opacity = 0.22}) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
}

/// Radius presets — large, modern, pill-ready.
class AppRadius {
  AppRadius._();
  static const xs = 10.0;
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 26.0;
  static const xl = 32.0;
  static const xxl = 40.0;
  static const pill = 999.0;
}

/// Spacing presets (8pt scale, airy).
class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const huge = 40.0;
}

/// Global ThemeData — premium monochrome material 3.
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const primary = AppColors.black;
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: AppColors.white,
        secondary: AppColors.neonCyan,
        onSecondary: AppColors.black,
        tertiary: AppColors.softLime,
        onTertiary: AppColors.black,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceMuted,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      dividerColor: AppColors.divider,
      splashFactory: InkSparkle.splashFactory,

      // ── Typography ────────────────────────────────────────
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme:
            IconThemeData(color: AppColors.textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // ── Cards ─────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      // ── Inputs ────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.black,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.black, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      // ── Buttons ───────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.surfaceMuted,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.black,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          side: const BorderSide(color: AppColors.black, width: 1.4),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),

      // ── Dialogs / Sheets ──────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.55,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      // ── Misc ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.black,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            color: AppColors.textPrimary,
            height: 1.05,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: AppColors.textPrimary,
            height: 1.05,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            height: 1.55,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
          bodySmall: base.bodySmall?.copyWith(
            color: AppColors.textMuted,
            height: 1.5,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: AppColors.textPrimary,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        )
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );
  }
}

/// Premium decoration helpers for inline use across features.
class AppDecorations {
  AppDecorations._();

  /// Soft floating card — large radius, diffused shadow.
  static BoxDecoration card({
    Color? color,
    double radius = AppRadius.lg,
    List<BoxShadow>? shadow,
    Border? border,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? AppShadows.sm,
        border: border,
      );

  /// Black solid hero card (pill-ish, modern).
  static BoxDecoration heroCard({double radius = AppRadius.xl}) =>
      BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.floating,
      );

  /// Soft subtle border container (no shadow).
  static BoxDecoration outlined({
    Color? color,
    double radius = AppRadius.md,
    Color border = AppColors.border,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      );

  /// Pill badge decoration.
  static BoxDecoration pill(Color tint, {double opacity = 0.14}) =>
      BoxDecoration(
        color: tint.withOpacity(opacity),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      );

  /// Glass-like surface (for floating navbars on light bg).
  static BoxDecoration glass({double radius = AppRadius.pill}) =>
      BoxDecoration(
        color: AppColors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: AppShadows.md,
      );
}
