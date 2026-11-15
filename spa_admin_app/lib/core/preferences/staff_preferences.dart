import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sólo preferencias visuales. Nunca guarda JWT ni contraseñas.
class StaffPreferences {
  StaffPreferences._();

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);
  static final ValueNotifier<String> language = ValueNotifier<String>('es');
  static int? _activeUserId;
  static int _sessionVersion = 0;

  static ThemeMode _parseTheme(String? name) => switch (name) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };

  /// Inicializa preferencias heredadas de versiones anteriores.
  /// No se activa el tema oscuro hasta que el usuario inicia sesion.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    themeMode.value = _parseTheme(prefs.getString('aura_staff_theme'));
    language.value = prefs.getString('aura_staff_language') == 'en' ? 'en' : 'es';
  }

  /// Carga las preferencias del usuario autenticado. La primera cuenta que
  /// migra conserva el ajuste global usado en las versiones anteriores.
  static Future<void> bindToUser(int idUsuario) async {
    final version = ++_sessionVersion;
    _activeUserId = idUsuario;
    final prefs = await SharedPreferences.getInstance();
    var legacyOwner = prefs.getInt('aura_staff_legacy_owner');
    if (legacyOwner == null) {
      await prefs.setInt('aura_staff_legacy_owner', idUsuario);
      legacyOwner = idUsuario;
    }
    final oldTheme = legacyOwner == idUsuario ? prefs.getString('aura_staff_theme') : null;
    final oldLanguage = legacyOwner == idUsuario ? prefs.getString('aura_staff_language') : null;
    final theme = prefs.getString('aura_staff_theme_$idUsuario') ?? oldTheme;
    final lang = prefs.getString('aura_staff_language_$idUsuario') ?? oldLanguage;
    if (version != _sessionVersion || _activeUserId != idUsuario) return;
    themeMode.value = _parseTheme(theme);
    language.value = lang == 'en' ? 'en' : 'es';
  }

  static void unbindUser() {
    _sessionVersion++;
    _activeUserId = null;
  }

  static Future<void> changeTheme(ThemeMode next) async {
    themeMode.value = next;
    final id = _activeUserId;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) await prefs.setString('aura_staff_theme_$id', next.name);
  }

  static Future<void> changeLanguage(String next) async {
    if (next != 'es' && next != 'en') return;
    language.value = next;
    final id = _activeUserId;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) await prefs.setString('aura_staff_language_$id', next);
  }

  static String tr(String es, String en) => language.value == 'en' ? en : es;
}
