import 'package:flutter/material.dart';

class AppColors {
  // --- FONDOS Y TARJETAS ---
  static const Color background = Colors.white; // Fondo blanco puro FFFFFF
  static const Color cardBackground = Color(0xFFFAFAFA); // Fondo gris muy sutil para distinguir tarjetas
  static const Color cardBorder = Color(0xFF505050); // Borde gris oscuro de alto contraste
  static const Color transparent = Colors.transparent;

  // --- BOTONES Y ACCIONES PRINCIPALES ---
  static const Color primaryButton = Color(0xFF000000); // Negro para botones principales
  static const Color primaryPink = Color(0xFF000000); // // Color(0xFFFF007A); Comentado por cambio de diseño
  static const Color secondaryButton = Color(0xFFEFEFEF); // Botones secundarios grises

  // --- MENÚ ADMINISTRATIVO (Exclusivo para personalizar opciones del menú admin) ---
  static const Color adminMenuButtonBg = Color(0xFF727070); // // Color(0xFFFDE8EE); Comentado por cambio de diseño a negro
  static const Color adminMenuButtonText = Colors.white; // Color de texto e íconos en el menú admin

  // --- TEXTOS ---
  static const Color textDark = Color(0xFF2D2D2D);
  static const Color textMedium = Color(0xFF424242); // Reemplazo de Colors.black87
  static const Color textLight = Color(0xFF757575); // Reemplazo de Colors.black54
  static const Color textSubtle = Color(0xFF9E9E9E); // Reemplazo de Colors.black45
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // --- CONTENEDORES Y INPUTS ---
  static const Color inputFill = Color(0xFFF7F7F7);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color avatarBg = Color(0xFFE0E0E0);
  static const Color chipInactive = Color(0xFFEFEFEF);

  // --- ESTADOS Y BADGES ---
  static const Color statusConfirmada = Color(0xFF4CAF50); // Verde
  static const Color statusEnProceso = Color(0xFFFF9800); // Naranja
  static const Color statusPendiente = Color(0xFF9E9E9E); // Gris
  static const Color statusCompletada = Color(0xFF9C27B0); // Púrpura
  static const Color statusCancelada = Color(0xFFF44336); // Rojo
}
