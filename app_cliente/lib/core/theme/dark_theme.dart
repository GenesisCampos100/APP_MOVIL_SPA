import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Tema oscuro. Toma la tipografía del tema claro, para que los dos usen la
/// misma fuente.
ThemeData crearTemaOscuro() {
  const fondo = Color(0xFF121212);
  const superficie = Color(0xFF1E1E1E);
  const borde = Color(0xFF3A3A3C);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTheme.light.textTheme.bodyMedium?.fontFamily,
    colorSchemeSeed: AppColors.rosaFuerte,
    scaffoldBackgroundColor: fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: fondo,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF1C1C1E),
      indicatorColor: Color(0xFF3A2A2D),
    ),
    dividerTheme: const DividerThemeData(color: borde, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: superficie,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: superficie,
      surfaceTintColor: Colors.transparent,
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(superficie),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
  );
}
