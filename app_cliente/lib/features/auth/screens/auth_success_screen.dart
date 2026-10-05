import 'package:flutter/material.dart';
import '../../../shared/widgets/pantalla_exito.dart';
import '../auth_flow.dart';

/// Registro completado: palomita verde animada y regreso a la app.
class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaExito(
      titulo: '¡Cuenta creada!',
      mensaje: 'Tu registro se completó correctamente.\nYa puedes reservar tus servicios.',
      textoBoton: 'Continuar',
      onContinuar: (ctx) => AuthFlow.terminar(ctx),
    );
  }
}
