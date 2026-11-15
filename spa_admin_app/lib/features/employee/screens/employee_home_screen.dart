import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/features/staff/widgets/staff_daily_widgets.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Inicio del empleado: solo citas asignadas por el backend según el JWT.
/// No utiliza métricas ficticias ni permite modificar citas.
class EmployeeHomeScreen extends StatefulWidget {
  final VoidCallback onVerCitas;
  final int refreshVersion;

  const EmployeeHomeScreen({
    super.key,
    required this.onVerCitas,
    this.refreshVersion = 0,
  });

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with WidgetsBindingObserver {
  final CitasRepository _repository = CitasRepository();
  List<AppointmentModel> _citas = [];
  bool _cargando = true;
  String? _error;
  int _solicitud = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void didUpdateWidget(covariant EmployeeHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) _cargar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _solicitud++;
    super.dispose();
  }

  Future<void> _cargar() async {
    final version = ++_solicitud;
    if (!AuthSession.activa || !AuthSession.esEspecialista) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Inicia sesión como empleado para consultar tu jornada.';
      });
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      final citas = await _repository.obtenerCitas();
      if (!mounted || version != _solicitud) return;
      setState(() { _citas = citas; _cargando = false; });
    } on ApiException catch (e) {
      if (!mounted || version != _solicitud) return;
      setState(() { _cargando = false; _error = e.message; });
    } catch (_) {
      if (!mounted || version != _solicitud) return;
      setState(() {
        _cargando = false;
        _error = 'No fue posible consultar tus citas. Revisa la conexión.';
      });
    }
  }

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
  }

  DateTime? _inicio(AppointmentModel cita) {
    final partes = cita.horaInicio.split(':');
    if (partes.length < 2) return null;
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null || hora < 0 || hora > 23 || minuto < 0 || minuto > 59) return null;
    return DateTime(cita.fecha.year, cita.fecha.month, cita.fecha.day, hora, minuto);
  }

  String tr(String es, String en) => StaffPreferences.tr(es, en);

  @override
  Widget build(BuildContext context) {
    final citasHoy = _citas.where((c) => _esHoy(c.fecha)).toList();
    final pendientes = citasHoy.where((c) => c.estado == 'Pendiente').length;
    final confirmadas = citasHoy.where((c) => c.estado == 'Confirmada').length;
    final completadas = citasHoy.where((c) => c.estado == 'Completada').length;
    final canceladas = citasHoy.where((c) => c.estado == 'Cancelada').length;
    final ahora = DateTime.now();
    final proximas = _citas.where((c) {
      final inicio = _inicio(c);
      return inicio != null && !inicio.isBefore(ahora) &&
          (c.estado == 'Pendiente' || c.estado == 'Confirmada');
    }).toList()..sort((a, b) => _inicio(a)!.compareTo(_inicio(b)!));
    final activas = pendientes + confirmadas + completadas;
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(19, 19, 19, 34),
        children: [
          StaffDailyHeader(reception: false, refreshVersion: widget.refreshVersion),
          const SizedBox(height: 20),
          StaffSectionHeading(title: tr('Resumen de hoy', 'Today’s summary'),
              onRefresh: _cargando ? null : _cargar),
          const SizedBox(height: 8),
          if (_cargando) const Padding(padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
              const Icon(Icons.wifi_off_outlined),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _cargar, child: Text(tr('Reintentar', 'Retry'))),
            ])))
          else ...[
            Row(children: [
              Expanded(child: StaffNumberCard(label: tr('Pendientes', 'Pending'), count: pendientes, accent: const Color(0xFFC29148))),
              const SizedBox(width: 10),
              Expanded(child: StaffNumberCard(label: tr('Confirmadas', 'Confirmed'), count: confirmadas, accent: const Color(0xFF69A586))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: StaffNumberCard(label: tr('Completadas', 'Completed'), count: completadas, accent: const Color(0xFF9C89C2))),
              const SizedBox(width: 10),
              Expanded(child: StaffNumberCard(label: tr('Canceladas', 'Cancelled'), count: canceladas, accent: const Color(0xFFD17E8B))),
            ]),
            const SizedBox(height: 15),
            StaffProgressCard(label: tr('Progreso de mi jornada', 'My day’s progress'),
                completed: completadas, total: activas),
            const SizedBox(height: 24),
            StaffSectionHeading(title: tr('Próximas citas', 'Upcoming appointments')),
            const SizedBox(height: 8),
            if (proximas.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(18),
                child: Text(tr('No tienes citas próximas asignadas.', 'No upcoming appointments assigned.'),
                  textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant))))
            else
              ...proximas.take(3).map((cita) => StaffUpcomingCard(
                service: cita.nombreServicio,
                person: cita.nombreCliente,
                when: '${cita.fecha.day}/${cita.fecha.month}\n${cita.horaInicio}',
              )),
            Align(alignment: Alignment.centerRight,
              child: TextButton.icon(onPressed: widget.onVerCitas,
                icon: const Icon(Icons.calendar_month_outlined, size: 17),
                label: Text(tr('Consultar mis citas', 'View my appointments')))),
          ],
        ],
      ),
    );
  }
}
