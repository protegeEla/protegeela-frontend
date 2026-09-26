import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6D245D);
  static const primaryDark = Color(0xFF3A1232);
  static const secondary = Color(0xFFC33D88);
  static const accent = Color(0xFFF7DDEA);
  static const background = Color(0xFFFFF8FC);
  static const surfaceSoft = Color(0xFFFDF3F8);
  static const border = Color(0xFFEADDE5);
  static const text = Color(0xFF281822);
  static const textMuted = Color(0xFF665865);
  static const emergency = Color(0xFFE42D22);
  static const safe = Color(0xFF21875C);
  static const warning = Color(0xFFB97813);
}

WidgetStateProperty<Color?> _interactionOverlay(
  Color color, {
  double hoverOpacity = 0.055,
}) {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return null;
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: 0.12);
    }
    if (states.contains(WidgetState.focused)) {
      return color.withValues(alpha: 0.085);
    }
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: hoverOpacity);
    }
    return null;
  });
}

ThemeData buildProtegeElaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.emergency,
    surface: Colors.white,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Inter',
    visualDensity: VisualDensity.standard,
    splashFactory: InkRipple.splashFactory,
    hoverColor: AppColors.primary.withValues(alpha: 0.045),
    focusColor: AppColors.primary.withValues(alpha: 0.08),
    highlightColor: AppColors.primary.withValues(alpha: 0.06),
    splashColor: AppColors.primary.withValues(alpha: 0.08),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: AppColors.primaryDark,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(height: 1.45),
      bodyMedium: TextStyle(height: 1.45),
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.text,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hoverColor: AppColors.surfaceSoft,
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.primary,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Color(0xFFA69BA3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDED4DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDED4DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.emergency),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.emergency, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).copyWith(
        overlayColor: _interactionOverlay(
          Colors.white,
          hoverOpacity: 0.10,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ).copyWith(overlayColor: _interactionOverlay(AppColors.primary)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
        overlayColor: _interactionOverlay(
          AppColors.primary,
          hoverOpacity: 0.045,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ).copyWith(overlayColor: _interactionOverlay(AppColors.primary)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.primary,
      textColor: AppColors.text,
      selectedColor: AppColors.primary,
      selectedTileColor: AppColors.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : const Color(0xFFB8ABB4),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : const Color(0xFFE4DCE2),
      ),
      overlayColor: _interactionOverlay(AppColors.primary),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: const BorderSide(color: Color(0xFFB7AAB3)),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.white,
      ),
      overlayColor: _interactionOverlay(AppColors.primary),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.accent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
