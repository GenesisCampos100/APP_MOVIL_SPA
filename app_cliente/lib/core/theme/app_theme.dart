import 'package:flutter/material.dart';

class AppColors {
  static const rosa = Color(0xFFF2C4C9);
  static const rosaSuave = Color(0xFFFBE4E6);
  static const rosaFuerte = Color(0xFFD98C97);
  static const texto = Color(0xFF222222);
  static const gris = Color(0xFF8A8A8A);
}

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.rosaFuerte,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.texto,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.rosaSuave,
        ),
      );
}
