import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/features/staff/screens/staff_more_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:spa_admin_app/features/appointments/widgets/cita_visual_components.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/auth/screens/login_admin_screen.dart';
import 'package:spa_admin_app/features/reception/screens/reception_home_screen.dart';
import 'package:spa_admin_app/features/reception/screens/reception_appointments_screen.dart';
import 'package:spa_admin_app/features/appointments/widgets/manual_appointment_dialog.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Recepción mantiene la agenda general y la creación de citas existente.
class ReceptionNavigationScreen extends StatefulWidget {
  const ReceptionNavigationScreen({super.key});

  @override
  State<ReceptionNavigationScreen> createState() => _ReceptionNavigationScreenState();
}

class _ReceptionNavigationScreenState extends State<ReceptionNavigationScreen> {
  int _index = 0;
  int _agendaVersion = 0;
  int _inicioVersion = 0;

  void _cambiar(int destino) {
    if (destino == _index) return;
    setState(() {
      _index = destino;
      if (destino == 0) _inicioVersion++;
      if (destino == 1) _agendaVersion++;
    });
  }

  Future<void> _crearCita() async {
    final creada = await showDialog<bool>(
      context: context,
      builder: (_) => const ManualAppointmentDialog(),
    );
    if (!mounted || creada != true) return;
    setState(() {
      _agendaVersion++;
      _inicioVersion++;
    });
    mostrarAvisoCita(context,
        StaffPreferences.tr('Cita creada correctamente. Quedó Pendiente de aceptación.',
            'Appointment created. Status: Pending staff acceptance.'),
        tipo: CitaAvisoTipo.exito);
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
    if (!AuthSession.esRecepcionista || !AuthSession.activa) {
      return const Scaffold(body: Center(
          child: Text('Acceso exclusivo del personal de Recepción.')));
    }
    return ValueListenableBuilder<String>(
      valueListenable: StaffPreferences.language,
      builder: (context, lang, _) => Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? 'Aura SPA · Reception' : 'Aura SPA · Recepción'),
      ),
      body: IndexedStack(index: _index, children: [
        ReceptionHomeScreen(refreshVersion: _inicioVersion,
            onVerAgenda: () => _cambiar(1)),
        ReceptionAppointmentsScreen(key: ValueKey(_agendaVersion)),
        StaffMoreOptionsScreen(onLogout: _cerrarSesion),
      ]),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: _crearCita,
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(lang == 'en' ? 'New appointment' : 'Nueva cita'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF6B4053)
            : AppColors.primaryPinkSoft,
        onDestinationSelected: _cambiar,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), label: lang == 'en' ? 'Home' : 'Inicio'),
          NavigationDestination(icon: const Icon(Icons.event_note_outlined), label: lang == 'en' ? 'Schedule' : 'Agenda'),
          NavigationDestination(icon: const Icon(Icons.tune_outlined), label: lang == 'en' ? 'More' : 'Más opciones'),
        ],
      ),
      ),
    );
  }
}
