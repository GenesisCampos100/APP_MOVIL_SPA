import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/auth/screens/login_admin_screen.dart';
import 'package:spa_admin_app/features/reception/screens/reception_home_screen.dart';
import 'package:spa_admin_app/features/reception/screens/reception_appointments_screen.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Panel propio de Recepción. No muestra controles administrativos sensibles.
class ReceptionNavigationScreen extends StatefulWidget {
  const ReceptionNavigationScreen({super.key});

  @override
  State<ReceptionNavigationScreen> createState() => _ReceptionNavigationScreenState();
}

class _ReceptionNavigationScreenState extends State<ReceptionNavigationScreen> {
  int _index = 0;

  Future<void> _cerrarSesion() async {
    final confirmar = await mostrarConfirmacion(
      context: context,
      titulo: '¿Deseas cerrar sesión?',
      mensaje: 'Tendrás que ingresar nuevamente para usar Aura SPA.',
      textoConfirmar: 'Sí, cerrar sesión',
      icono: Icons.logout_rounded,
    );
    if (!mounted || !confirmar) return;
    AuthSession.cerrar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginAdminScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.esRecepcionista || !AuthSession.activa) {
      return const Scaffold(
        body: Center(child: Text('Acceso exclusivo del personal de Recepción.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura SPA · Recepción'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          ReceptionHomeScreen(onVerAgenda: () => setState(() => _index = 1)),
          const ReceptionAppointmentsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: AppColors.primaryPinkSoft,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Agenda'),
        ],
      ),
    );
  }
}
