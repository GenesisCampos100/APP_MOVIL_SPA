import 'package:flutter/material.dart';
import '../../../shared/widgets/pantalla_pendiente.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaPendiente(
      titulo: 'Iniciar sesión',
      icono: Icons.lock_outline,
      descripcion: 'Aquí irá el formulario de acceso y registro (CU-01, CU-02, CU-18, CU-19).',
    );
  }
}
