import 'package:flutter/material.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/auth/screens/login_admin_screen.dart';
import '../../employee/screens/employee_home_screen.dart';
import '../../employee/screens/employee_appointments_screen.dart';

/// Menú separado para el empleado: no expone funciones administrativas.
class EmployeeNavigationScreen extends StatefulWidget {
  const EmployeeNavigationScreen({super.key});

  @override
  State<EmployeeNavigationScreen> createState() => _EmployeeNavigationScreenState();
}

class _EmployeeNavigationScreenState extends State<EmployeeNavigationScreen> {
  int _index = 0;

  void _cerrarSesion() {
    AuthSession.cerrar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginAdminScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      EmployeeHomeScreen(onVerCitas: () => setState(() => _index = 1)),
      const EmployeeAppointmentsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura SPA · Personal'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Mis citas'),
        ],
      ),
    );
  }
}
