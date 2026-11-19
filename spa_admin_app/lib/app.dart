import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/preferences/staff_preferences.dart';
import 'data/services/sesion_service.dart';

/// Configuracion global de Aura SPA.
/// Tema e idioma por cuenta autenticada. El login permanece claro y en español.
/// No modifica permisos, JWT ni operaciones del backend.
class SpaAdminApp extends StatelessWidget {
  const SpaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthSession.temaPersonalActivo,
      builder: (context, personalActivo, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: StaffPreferences.themeMode,
        builder: (context, preferenciaPersonal, _) => ValueListenableBuilder<String>(
          valueListenable: StaffPreferences.language,
          builder: (context, idiomaPersonal, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Aura Spa Admin',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // El idioma solo cambia al iniciar sesión; el login mantiene español.
            locale: Locale(personalActivo ? idiomaPersonal : 'es'),
            supportedLocales: const [Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: personalActivo ? preferenciaPersonal : ThemeMode.light,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generate,
          ),
        ),
      ),
    );
  }
}
