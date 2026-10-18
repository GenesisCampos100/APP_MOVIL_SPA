import 'package:flutter/material.dart';
import 'package:spa_admin_app/features/appointments/presentation/screens/manage_appointments_screen.dart';
import 'package:spa_admin_app/features/services/presentation/screens/manage_services_screen.dart';
import 'package:spa_admin_app/features/dashboard/presentation/tabs/dashboard_home_tab.dart';
import 'package:spa_admin_app/features/dashboard/presentation/tabs/admin_menu_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Lista de las 4 pantallas del menú inferior
  final List<Widget> _tabs = [
    const DashboardHomeTab(), // Resumen y métricas
    const ManageServicesScreen(),
    const ManageAppointmentsScreen(),
    const AdminMenuTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      // Barra de navegación inferior
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 28), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.badge_outlined, size: 28), label: 'Servicios'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined, size: 26), label: 'Citas'),
            BottomNavigationBarItem(icon: Icon(Icons.menu, size: 28), label: 'Menú'),
          ],
        ),
      ),
    );
  }
}
