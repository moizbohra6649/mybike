import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

/// MYBIKE Theme Configuration
///
/// Material 3 ThemeData for Light and Dark modes.
/// Yellow is used as the primary accent strategically.
/// The overall feel is premium automotive + modern fintech.
abstract final class AppTheme {
  // ═══════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,

      // ─── Color Scheme ───
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.primaryBlack,
        primaryContainer: AppColors.primaryYellowSubtle,
        onPrimaryContainer: AppColors.primaryBlack,
        secondary: AppColors.primaryBlack,
        onSecondary: AppColors.white,
        secondaryContainer: Color(0xFFF0F0ED),
        onSecondaryContainer: AppColors.primaryBlack,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightPrimaryText,
        onSurfaceVariant: AppColors.lightSecondaryText,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightDivider,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.errorDark,
      ),

      // ─── Scaffold ───
      scaffoldBackgroundColor: AppColors.lightBackground,

      // ─── AppBar ───
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightPrimaryText,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightPrimaryText,
          height: 1.4,
        ),
        iconTheme: IconThemeData(
          color: AppColors.lightPrimaryText,
          size: AppDimensions.iconLg,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        color: AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Elevated Button (Primary CTA — Yellow) ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.primaryBlack,
          disabledBackgroundColor: AppColors.lightBorder,
          disabledForegroundColor: AppColors.lightMutedText,
          elevation: 0,
          minimumSize: const Size(
            double.minPositive,
            AppDimensions.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimaryText,
          disabledForegroundColor: AppColors.lightMutedText,
          elevation: 0,
          minimumSize: const Size(
            double.minPositive,
            AppDimensions.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.borderWidth,
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlack,
          minimumSize: const Size(
            double.minPositive,
            AppDimensions.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ─── Input / TextField ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightHintText,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightSecondaryText,
        ),
        errorStyle: AppTypography.captionLarge.copyWith(
          color: AppColors.error,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.lightBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryYellow,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.lightDivider,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBackground,
        selectedColor: AppColors.primaryYellowSubtle,
        disabledColor: AppColors.lightDivider,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.lightPrimaryText,
        ),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing4,
        ),
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: AppDimensions.borderWidthThin,
        space: 0,
      ),

      // ─── Bottom Navigation ───
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.lightMutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // ─── Navigation Rail ───
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedIconTheme: IconThemeData(
          color: AppColors.primaryYellow,
          size: AppDimensions.iconLg,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.lightMutedText,
          size: AppDimensions.iconLg,
        ),
        indicatorColor: AppColors.primaryYellowSubtle,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.lightPrimaryText,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightSecondaryText,
        ),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.lightBorder,
      ),

      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryBlack,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryBlack,
        unselectedLabelColor: AppColors.lightMutedText,
        indicatorColor: AppColors.primaryYellow,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.lightDivider,
      ),

      // ─── Floating Action Button ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.primaryBlack,
        elevation: 2,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ─── Popup Menu ───
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        elevation: 4,
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightPrimaryText,
        ),
      ),

      // ─── Text Theme ───
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.captionLarge.copyWith(
          color: AppColors.white,
        ),
      ),

      // ─── Checkbox ───
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryYellow;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.primaryBlack),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        ),
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlack;
          }
          return AppColors.lightMutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryYellow;
          }
          return AppColors.lightBorder;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ─── Radio ───
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryYellow;
          }
          return AppColors.lightMutedText;
        }),
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryYellow,
        linearTrackColor: AppColors.lightDivider,
        circularTrackColor: AppColors.lightDivider,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.fontFamily,

      // ─── Color Scheme ───
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.primaryBlack,
        primaryContainer: Color(0xFF3A2E10),
        onPrimaryContainer: AppColors.primaryYellow,
        secondary: AppColors.white,
        onSecondary: AppColors.primaryBlack,
        secondaryContainer: Color(0xFF2A2A2A),
        onSecondaryContainer: AppColors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkPrimaryText,
        onSurfaceVariant: AppColors.darkSecondaryText,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkDivider,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: Color(0xFF3C1111),
        onErrorContainer: AppColors.errorLight,
      ),

      // ─── Scaffold ───
      scaffoldBackgroundColor: AppColors.darkBackground,

      // ─── AppBar ───
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkPrimaryText,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkPrimaryText,
          height: 1.4,
        ),
        iconTheme: IconThemeData(
          color: AppColors.darkPrimaryText,
          size: AppDimensions.iconLg,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ─── Card ───
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.cardBorderWidth,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Elevated Button ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.primaryBlack,
          disabledBackgroundColor: AppColors.darkBorder,
          disabledForegroundColor: AppColors.darkMutedText,
          elevation: 0,
          minimumSize: const Size(
            double.minPositive,
            AppDimensions.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ─── Outlined Button ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimaryText,
          disabledForegroundColor: AppColors.darkMutedText,
          elevation: 0,
          minimumSize: const Size(
            double.minPositive,
            AppDimensions.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing24,
            vertical: AppDimensions.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.borderWidth,
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ─── Text Button ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryYellow,
          minimumSize: const Size(
            double.minPositive,
            AppDimensions.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      // ─── Input ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing14,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkHintText,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkSecondaryText,
        ),
        errorStyle: AppTypography.captionLarge.copyWith(
          color: AppColors.error,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.darkBorder,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryYellow,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.darkDivider,
            width: AppDimensions.borderWidth,
          ),
        ),
      ),

      // ─── Chip ───
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkCard,
        selectedColor: const Color(0xFF3A2E10),
        disabledColor: AppColors.darkDivider,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        side: const BorderSide(color: AppColors.darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing4,
        ),
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: AppDimensions.borderWidthThin,
        space: 0,
      ),

      // ─── Bottom Navigation ───
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.darkMutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
      ),

      // ─── Navigation Rail ───
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedIconTheme: IconThemeData(
          color: AppColors.primaryYellow,
          size: AppDimensions.iconLg,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppColors.darkMutedText,
          size: AppDimensions.iconLg,
        ),
        indicatorColor: Color(0xFF3A2E10),
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkSecondaryText,
        ),
      ),

      // ─── Bottom Sheet ───
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.darkBorder,
      ),

      // ─── Snack Bar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.white,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.primaryBlack,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // ─── Tab Bar ───
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryYellow,
        unselectedLabelColor: AppColors.darkMutedText,
        indicatorColor: AppColors.primaryYellow,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.darkDivider,
      ),

      // ─── FAB ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.primaryBlack,
        elevation: 2,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ─── Popup Menu ───
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
        elevation: 4,
        textStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
      ),

      // ─── Text Theme ───
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.darkSecondaryText,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.darkPrimaryText,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.darkSecondaryText,
        ),
      ),

      // ─── Tooltip ───
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        textStyle: AppTypography.captionLarge.copyWith(
          color: AppColors.primaryBlack,
        ),
      ),

      // ─── Checkbox ───
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryYellow;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.primaryBlack),
        side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
        ),
      ),

      // ─── Switch ───
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlack;
          }
          return AppColors.darkMutedText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryYellow;
          }
          return AppColors.darkBorder;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ─── Radio ───
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryYellow;
          }
          return AppColors.darkMutedText;
        }),
      ),

      // ─── Progress Indicator ───
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryYellow,
        linearTrackColor: AppColors.darkDivider,
        circularTrackColor: AppColors.darkDivider,
      ),
    );
  }
}
