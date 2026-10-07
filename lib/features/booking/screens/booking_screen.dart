import 'package:flutter/material.dart';
import '../../../data/models/servicio.dart';
import '../../../shared/widgets/pantalla_pendiente.dart';

class BookingScreen extends StatelessWidget {
  final Servicio? servicio;
  const BookingScreen({super.key, this.servicio});

  @override
  Widget build(BuildContext context) {
    return PantallaPendiente(
      titulo: 'Reservar cita',
      icono: Icons.event_available,
      descripcion:
          'Servicio: ${servicio?.nombre ?? "-"}\n\nAquí irá: fecha y horario, empleado y confirmación (CU-04, CU-17).',
    );
  }
}
