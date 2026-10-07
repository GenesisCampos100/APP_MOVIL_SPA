import 'package:flutter/material.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../catalog/screens/catalog_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../shell_controller.dart';

/// Contenedor con el menú inferior de 4 pestañas.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<Widget> _pantallas = [
    HomeScreen(),
    CatalogScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ShellController.tab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(index: index, children: _pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: ShellController.irA,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.spa_outlined), selectedIcon: Icon(Icons.spa), label: 'Servicios'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Citas'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
