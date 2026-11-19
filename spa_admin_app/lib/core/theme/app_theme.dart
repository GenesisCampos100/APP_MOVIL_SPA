import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tema visual existente de Aura SPA, extraído de main.dart sin alterar colores.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPink,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textDark,
          ),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: AppColors.fieldBackground,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.7),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
  );
  // Tema ciruela para componentes que respetan ThemeData. Algunos módulos
  // anteriores usan colores fijos; se revisarán antes de declarar oscuridad total.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF211A21),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD99AB2),
          brightness: Brightness.dark,
          surface: const Color(0xFF302630),
        ),
        appBarTheme: const AppBarThemeData(
          backgroundColor: Color(0xFF211A21),
          foregroundColor: Color(0xFFFFEFF5),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFEFF5),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF302630),
          indicatorColor: const Color(0xFF6B4053),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontFamily: 'Poppins', fontSize: 11),
          ),
        ),
        // Tonos coherentes para las superficies modales del personal.
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF312730),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titleTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 18,
              fontWeight: FontWeight.w700, color: Color(0xFFFFEDF5)),
          contentTextStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: Color(0xFFF2DEE7)),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF312730),
          modalBackgroundColor: Color(0xFF312730),
          surfaceTintColor: Colors.transparent,
          dragHandleColor: Color(0xFFBBA0AD),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: const Color(0xFF312730),
          headerBackgroundColor: const Color(0xFF634154),
          headerForegroundColor: const Color(0xFFFFEFF5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: const Color(0xFF382C37),
          labelStyle: const TextStyle(color: Color(0xFFEFCCD9)),
          hintStyle: const TextStyle(color: Color(0xFFBCA8B5)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF655362)),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5A6BD), width: 1.5),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF392D39)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFF2B6CB)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFAD6584),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF6CADB),
            side: const BorderSide(color: Color(0xFF866577)),
          ),
        ),
      );

}
