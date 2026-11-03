import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const String fontFamily = 'Poppins';

  // --- TÍTULOS Y ENCABEZADOS ---

  // Para números grandes o impactos visuales máximos (Poppins-Black)
  static const TextStyle displayBlack = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w900,
  );

  // Para títulos principales de pantallas (Poppins-ExtraBold)
  static const TextStyle displayExtraBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
  );

  // Títulos de sección o encabezados de tarjetas (Poppins-Bold)
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold, // w700 -> Poppins-Bold.ttf
  );

  // Subtítulos destacados (Poppins-SemiBold)
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600, // w600 -> Poppins-SemiBold.ttf
  );

  // --- TEXTOS GENERALES Y UI ---

  // Subtítulos o textos secundarios importantes (Poppins-Medium)
  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500, // w500 -> Poppins-Medium.ttf
  );

  // Texto estándar para párrafos, listas y formularios (Poppins-Regular)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal, // w400 -> Poppins-Regular.ttf
  );

  // Texto secundario más suave (Poppins-Light)
  static const TextStyle bodyLight = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w300, // w300 -> Poppins-Light.ttf
  );

  // --- DETALLES Y ETIQUETAS PEQUEÑAS ---

  // Textos muy pequeños, fechas o etiquetas (Poppins-Regular / Light)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400, // w400 -> Poppins-Regular.ttf
  );
}