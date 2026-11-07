import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/features/appointments/screens/manage_appointments_screen.dart';
import 'package:spa_admin_app/features/services/screens/manage_services_screen.dart';
import 'package:spa_admin_app/features/dashboard/screens/dashboard_home_tab.dart';
import 'package:spa_admin_app/features/dashboard/screens/admin_menu_tab.dart';

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
      // Misma navegación de cuatro pestañas, ahora con etiquetas visibles.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.cardBorder)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: AppColors.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 24), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.badge_outlined, size: 24), label: 'Servicios'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined, size: 23), label: 'Citas'),
            BottomNavigationBarItem(icon: Icon(Icons.menu, size: 24), label: 'Menú'),
          ],
        ),
      ),
    );
  }
}
