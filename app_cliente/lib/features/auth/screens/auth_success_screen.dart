import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../shared/widgets/pantalla_exito.dart';
import '../auth_flow.dart';

/// Registro completado: palomita verde animada y regreso a la app.
class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaExito(
      titulo: context.t('auth.ok_titulo'),
      mensaje: context.t('auth.ok_msg'),
      textoBoton: context.t('comun.continuar'),
      onContinuar: (ctx) => AuthFlow.terminar(ctx),
    );
  }
}
