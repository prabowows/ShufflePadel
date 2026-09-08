import 'package:flutter/material.dart';

class AppColors {
  // Pure Clean White Backgrounds & Surfaces
  static const Color background = Colors.white;
  static const Color backgroundCanvas = Color(0xFFF8FAF9);
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF1F5F3);
  static const Color surfaceTertiary = Color(0xFFE7ECE9);
  static const Color border = Color(0xFFE2E9E5);
  static const Color borderSubtle = Color(0xFFEEF3F0);

  // Pure Dark Green Palette (Zero Brown, Zero Tan)
  static const Color darkGreen = Color(0xFF0C382B);
  static const Color darkGreenLight = Color(0xFF144D3D);
  static const Color deepForest = Color(0xFF092A20);
  static const Color emerald = Color(0xFF1B7A5A);
  static const Color emeraldLight = Color(0xFF389E78);
  static const Color mintAccent = Color(0xFF48BB78);

  // Status & Badges
  static const Color greenBadge = Color(0xFF0C382B);
  static const Color greenBadgeBg = Color(0xFFE6F4EE);
  static const Color amberBadge = Color(0xFFD97706);
  static const Color amberBadgeBg = Color(0xFFFEF3C7);
  static const Color crimson = Color(0xFFDC2626);
  static const Color crimsonSoft = Color(0xFFFEE2E2);
  static const Color gold = Color(0xFFD97706);
  static const Color silver = Color(0xFF64748B);
  static const Color bronze = Color(0xFFB45309);

  // Text Colors (High Contrast Black/Charcoal)
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Colors.white;

  // Gradients
  static const LinearGradient darkGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF092A20), Color(0xFF0C382B), Color(0xFF144D3D)],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0C382B), Color(0xFF1B7A5A)],
  );
}

class AppTypography {
  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyText => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: AppColors.textSecondary,
      );
}

class AppDecorations {
  static BoxDecoration cleanWhiteCard({
    Color color = Colors.white,
    double borderRadius = 18,
    bool hasShadow = true,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.border,
        width: 1,
      ),
      boxShadow: hasShadow
          ? [
              // Ambient shadow
              BoxShadow(
                color: const Color(0xFF0C382B).withValues(alpha: 0.02),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              // Key shadow
              BoxShadow(
                color: const Color(0xFF0C382B).withValues(alpha: 0.04),
                blurRadius: 8,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
              // Rim shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ]
          : null,
    );
  }

  static BoxDecoration modernCard({
    Color color = Colors.white,
    double borderRadius = 18,
    bool isElevated = true,
    Color? borderColor,
  }) {
    return cleanWhiteCard(
      color: color,
      borderRadius: borderRadius,
      hasShadow: isElevated,
      borderColor: borderColor,
    );
  }

  static BoxDecoration glassCard({
    double borderRadius = 18,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.border.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0C382B).withValues(alpha: 0.04),
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

class ResponsiveBreakpoints {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1100;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100;
}
