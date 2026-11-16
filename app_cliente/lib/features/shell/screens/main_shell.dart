import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.t('nav.inicio'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.spa_outlined),
              selectedIcon: const Icon(Icons.spa),
              label: context.t('nav.servicios'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: context.t('nav.citas'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: context.t('nav.perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
