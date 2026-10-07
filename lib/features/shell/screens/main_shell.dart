import 'package:flutter/material.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../catalog/screens/catalog_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Contenedor con el menú inferior de 4 pestañas.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<Widget> _pantallas = const [
    HomeScreen(),
    CatalogScreen(),
    AppointmentsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.spa_outlined), selectedIcon: Icon(Icons.spa), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Citas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
