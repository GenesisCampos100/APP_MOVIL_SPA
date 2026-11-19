import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/features/staff/screens/staff_more_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/auth/screens/login_admin_screen.dart';
import '../../employee/screens/employee_home_screen.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';
import '../../employee/screens/employee_appointments_screen.dart';

/// Menú exclusivo de empleados especialistas. Acceso verificado en backend.
class EmployeeNavigationScreen extends StatefulWidget {
  const EmployeeNavigationScreen({super.key});

  @override
  State<EmployeeNavigationScreen> createState() => _EmployeeNavigationScreenState();
}

class _EmployeeNavigationScreenState extends State<EmployeeNavigationScreen> {
  int _index = 0;
  int _inicioVersion = 0;
  int _citasVersion = 0;

  void _cambiar(int destino) {
    if (destino == _index) return;
    setState(() {
      _index = destino;
      if (destino == 0) _inicioVersion++;
      if (destino == 1) _citasVersion++;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await mostrarConfirmacion(
      context: context,
      titulo: StaffPreferences.tr('¿Deseas cerrar sesión?', 'Sign out of Aura SPA?'),
      mensaje: StaffPreferences.tr('Tendrás que ingresar nuevamente para usar Aura SPA.', 'You will need to sign in again to use Aura SPA.'),
      textoConfirmar: StaffPreferences.tr('Sí, cerrar sesión', 'Yes, sign out'),
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
    if (!AuthSession.esEspecialista || !AuthSession.activa) {
      return const Scaffold(body: Center(
          child: Text('Acceso exclusivo del personal especialista.')));
    }
    return ValueListenableBuilder<String>(
      valueListenable: StaffPreferences.language,
      builder: (context, lang, _) {
      final tabs = <Widget>[
        EmployeeHomeScreen(refreshVersion: _inicioVersion, onVerCitas: () => _cambiar(1)),
        EmployeeAppointmentsScreen(refreshVersion: _citasVersion),
        StaffMoreOptionsScreen(onLogout: _cerrarSesion),
      ];
      final scheme = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final selectedIconColor = dark
          ? const Color(0xFFFFE6EF) : const Color(0xFF8E3E5E);
      return Scaffold(
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Aura SPA', style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w800)),
          Text(lang == 'en' ? 'SPECIALIST' : 'ESPECIALISTA',
            style: TextStyle(fontSize: 9, letterSpacing: 1.8,
                fontWeight: FontWeight.w700, color: scheme.primary)),
        ]),
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        backgroundColor: scheme.surface,
        indicatorColor: dark
            ? const Color(0xFF664359) : const Color(0xFFF7E0E9),
        selectedIndex: _index,
        onDestinationSelected: _cambiar,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: selectedIconColor),
            label: lang == 'en' ? 'Home' : 'Inicio'),
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: selectedIconColor),
            label: lang == 'en' ? 'My appointments' : 'Mis citas'),
          NavigationDestination(icon: const Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded, color: selectedIconColor),
            label: lang == 'en' ? 'More' : 'Más opciones'),
        ],
      ),
      );
      },
    );
  }
}
