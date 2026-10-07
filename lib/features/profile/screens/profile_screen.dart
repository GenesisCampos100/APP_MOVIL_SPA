import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/pantalla_pendiente.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaPendiente(
      titulo: 'Perfil',
      icono: Icons.person_outline,
      descripcion: 'Aún no has iniciado sesión. Aquí irá tu perfil cuando haya una sesión activa.',
      acciones: [
        FilledButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
          style: FilledButton.styleFrom(backgroundColor: Colors.black),
          child: const Text('Iniciar sesión'),
        ),
      ],
    );
  }
}
