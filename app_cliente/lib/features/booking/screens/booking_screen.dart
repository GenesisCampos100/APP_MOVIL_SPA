import 'package:flutter/material.dart';
import '../../../data/models/servicio.dart';
import '../../../shared/widgets/pantalla_pendiente.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';

class BookingScreen extends StatefulWidget {
  final Servicio? servicio;
  const BookingScreen({super.key, this.servicio});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  /// Al confirmar el horario: si no hay sesión, abre el login y, al
  /// terminar, regresa aquí para continuar.
  Future<void> _confirmarHorario() async {
    if (!AuthState.instance.isLoggedIn) {
      final ok = await AuthFlow.iniciar(context);
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sesión activa: ${AuthState.instance.usuario!.nombre}. '
          'Aquí continuará: teléfono y confirmación de la cita.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaPendiente(
      titulo: 'Reservar cita',
      icono: Icons.event_available,
      descripcion:
          'Servicio: ${widget.servicio?.nombre ?? "-"}\n\nAquí irá: fecha y horario, empleado y confirmación (CU-04, CU-17).',
      acciones: [
        FilledButton(
          onPressed: _confirmarHorario,
          style: FilledButton.styleFrom(backgroundColor: Colors.black),
          child: const Text('Confirmar horario (prueba)'),
        ),
      ],
    );
  }
}
