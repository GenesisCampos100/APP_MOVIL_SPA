import 'package:flutter/material.dart';
import '../../../shared/widgets/pantalla_pendiente.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PantallaPendiente(
      titulo: 'Mis citas',
      icono: Icons.calendar_month,
      descripcion: 'Aquí irá el listado de citas por estado (CU-05, CU-06, CU-07).',
    );
  }
}
