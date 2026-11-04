import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/snackbar_theme.dart';
import 'core/theme/tema_state.dart';

class AuraSpaApp extends StatelessWidget {
  const AuraSpaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Se vuelve a construir cuando el usuario cambia el tema en el Perfil.
    return ListenableBuilder(
      listenable: TemaState.instance,
      builder: (context, _) => MaterialApp(
        title: 'Aura Spa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light.copyWith(snackBarTheme: temaAvisos),
        darkTheme: crearTemaOscuro().copyWith(snackBarTheme: temaAvisos),
        themeMode: TemaState.instance.modo,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
  }
}
