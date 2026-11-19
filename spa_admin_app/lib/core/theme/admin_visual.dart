import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Colores de presentación del Administrador; nunca representa estados de BD.
/// Las preferencias se aplican únicamente durante la sesión autenticada.
class AdminVisual {
  const AdminVisual._();

  static bool get dark {
    if (!AuthSession.temaPersonalActivo.value) return false;
    switch (StaffPreferences.themeMode.value) {
      case ThemeMode.dark: return true;
      case ThemeMode.light: return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  static Color get background => dark ? const Color(0xFF211A21) : AppColors.background;
  static Color get cardBackground => dark ? const Color(0xFF302630) : AppColors.cardBackground;
  static Color get fieldBackground => dark ? const Color(0xFF382C37) : AppColors.fieldBackground;
  static Color get cardBorder => dark ? const Color(0xFF584654) : AppColors.cardBorder;
  static Color get textDark => dark ? const Color(0xFFFFEFF5) : AppColors.textDark;
  static Color get textMuted => dark ? const Color(0xFFD5C0CC) : AppColors.textMuted;
  static Color get primaryPinkSoft => dark ? const Color(0xFF503744) : AppColors.primaryPinkSoft;
  static Color get primaryPink => dark ? const Color(0xFFB46E8A) : AppColors.primaryPink;
  static Color get accentText => dark ? const Color(0xFFF3B8CE) : AppColors.primaryPink;
  static Color get statusBackground => dark ? const Color(0xFF3E343D) : const Color(0xFFF0EFF1);
  static Color get greenBackground => dark ? const Color(0xFF244237) : const Color(0xFFEAF7EC);
  static Color get greenText => dark ? const Color(0xFF9EE3B7) : const Color(0xFF297D4A);

  static const Map<String, String> _labels = {
    'Todos': 'All', 'Activos': 'Active', 'Inactivos': 'Inactive',
    'Activo': 'Active', 'Inactivo': 'Inactive',
    'Editar': 'Edit', 'Desactivar': 'Deactivate', 'Reactivar': 'Reactivate',
    'Lunes': 'Monday', 'Martes': 'Tuesday', 'Miercoles': 'Wednesday',
    'Jueves': 'Thursday', 'Viernes': 'Friday', 'Sabado': 'Saturday',
    'Domingo': 'Sunday', 'Lun': 'Mon', 'Mar': 'Tue', 'Mié': 'Wed',
    'Jue': 'Thu', 'Vie': 'Fri', 'Sáb': 'Sat', 'Dom': 'Sun',
    'Miércoles': 'Wednesday', 'Sábado': 'Saturday',
  };
  static String ui(String value) =>
      StaffPreferences.language.value == 'en' ? (_labels[value] ?? value) : value;
  static String t(String es, String en) => StaffPreferences.tr(es, en);
}

/// Un rótulo constante que responde al idioma sin cambiar los datos del negocio.
/// No traduce nombres de servicios, personas, notas ni claves técnicas.
class AdminTranslatedText extends StatelessWidget {
  const AdminTranslatedText(this.es, this.en, {super.key, this.style,
    this.textAlign, this.maxLines, this.overflow, this.softWrap});
  final String es;
  final String en;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) => Text(
    Localizations.localeOf(context).languageCode == 'en' ? en : es,
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
  );
}
