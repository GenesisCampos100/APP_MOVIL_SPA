import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';

const String _titulo = 'Sin registro de actividad';
const String _mensajeSinSesion = 'Inicia sesión para poder ver y gestionar tus citas.';
const String _mensajeConSesion = 'Aquí se llevará el registro de tus citas realizadas.';

/// Sin sesión: mensaje + botón "Inicio de sesión".
/// Con sesión: el mismo diseño con otro mensaje (luego irá la lista de citas).
/// [conAtras] = true cuando se abre desde el Perfil (agrega flecha de regreso).
class AppointmentsScreen extends StatelessWidget {
  final bool conAtras;
  const AppointmentsScreen({super.key, this.conAtras = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState.instance,
      builder: (context, _) {
        final conSesion = AuthState.instance.isLoggedIn;
        return Scaffold(
          appBar: conAtras ? AppBar() : null,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.rosaSuave,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 56,
                        color: AppColors.rosaFuerte,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      _titulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      conSesion ? _mensajeConSesion : _mensajeSinSesion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.gris),
                    ),
                    if (!conSesion) ...[
                      const SizedBox(height: 28),
                      AuthBoton(
                        texto: 'Inicio de sesión',
                        onPressed: () => AuthFlow.iniciar(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
