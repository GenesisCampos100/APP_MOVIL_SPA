import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/features/appointments/widgets/cita_visual_components.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/features/appointments/screens/manage_appointments_screen.dart';
import 'package:spa_admin_app/features/services/screens/manage_services_screen.dart';
import 'package:spa_admin_app/features/dashboard/screens/dashboard_home_tab.dart';
import 'package:spa_admin_app/features/dashboard/screens/admin_menu_tab.dart';
import 'package:spa_admin_app/features/appointments/widgets/manual_appointment_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _citasVersion = 0;
  int _dashboardVersion = 0;

  Future<void> _crearCita() async {
    final creada = await showDialog<bool>(
      context: context,
      builder: (_) => const ManualAppointmentDialog(),
    );
    if (!mounted || creada != true) return;
    setState(() => _citasVersion++);
    mostrarAvisoCita(context, StaffPreferences.tr('Cita creada correctamente. Quedó Pendiente de confirmación.', 'Appointment created. Waiting for acceptance.'),
        tipo: CitaAvisoTipo.exito);
  }


  // Lista de las 4 pantallas del menú inferior
  List<Widget> get _tabs => [
    DashboardHomeTab(
      key: ValueKey('dashboard_$_citasVersion'),
      refreshVersion: _dashboardVersion,
      onVerAgenda: () => setState(() => _currentIndex = 2),
      onNuevaCita: _crearCita,
      onServicios: () => setState(() => _currentIndex = 1),
      onMenu: () => setState(() => _currentIndex = 3),
    ), // Panel con datos reales y accesos a las pestañas existentes
    const ManageServicesScreen(),
    ManageAppointmentsScreen(key: ValueKey(_citasVersion)),
    const AdminMenuTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    String t(String es, String en) => StaffPreferences.tr(es, en);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _crearCita,
              backgroundColor: dark ? scheme.primary : AppColors.primaryPink,
              foregroundColor: dark ? scheme.onPrimary : Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(t('Nueva cita', 'New appointment')),
            )
          : null,
      // Misma navegación de cuatro pestañas, ahora con etiquetas visibles.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              // IndexedStack conserva las pantallas: refrescar Inicio al volver.
              if (index == 0 && _currentIndex != 0) _dashboardVersion++;
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: scheme.surface,
          elevation: 0,
          selectedItemColor: dark ? scheme.primary : AppColors.primaryPink,
          unselectedItemColor: scheme.onSurfaceVariant,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_outlined, size: 24), label: t('Inicio', 'Home')),
            BottomNavigationBarItem(icon: const Icon(Icons.badge_outlined, size: 24), label: t('Servicios', 'Services')),
            BottomNavigationBarItem(icon: const Icon(Icons.calendar_today_outlined, size: 23), label: t('Citas', 'Appointments')),
            BottomNavigationBarItem(icon: const Icon(Icons.menu, size: 24), label: t('Menú', 'Menu')),
          ],
        ),
      ),
    );
  }
}
