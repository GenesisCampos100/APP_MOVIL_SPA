import 'package:flutter/material.dart';

import 'core/i18n/idioma_state.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/aura_colores.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/snackbar_theme.dart';
import 'core/theme/tema_state.dart';

class AuraSpaApp extends StatelessWidget {
  const AuraSpaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // IdiomaScope: las pantallas se reconstruyen al cambiar de idioma.
    // ListenableBuilder: se reconstruye al cambiar el tema.
    return IdiomaScope(
      state: IdiomaState.instance,
      child: ListenableBuilder(
        listenable: TemaState.instance,
        builder: (context, _) => MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Aura Spa',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light.copyWith(
            snackBarTheme: temaAvisos,
            extensions: [AuraColores.claro],
          ),
          darkTheme: crearTemaOscuro().copyWith(
            snackBarTheme: temaAvisos.copyWith(
              backgroundColor: const Color(0xFF3A3A3C),
            ),
            extensions: [AuraColores.oscuro],
          ),
          themeMode: TemaState.instance.modo,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.generate,
        ),
      ),
    );
  }
}
