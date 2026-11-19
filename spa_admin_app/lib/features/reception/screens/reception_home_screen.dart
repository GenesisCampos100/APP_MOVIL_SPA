import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/features/staff/widgets/staff_daily_widgets.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Inicio operativo de Recepción, consultado desde la API protegida.
/// La consulta /personal/agenda puede devolver hasta 500 citas: el panel
/// advierte cuando alcanza ese límite para no sugerir totales exhaustivos.
class ReceptionHomeScreen extends StatefulWidget {
  final VoidCallback onVerAgenda;
  final int refreshVersion;

  const ReceptionHomeScreen({
    super.key,
    required this.onVerAgenda,
    this.refreshVersion = 0,
  });

  @override
  State<ReceptionHomeScreen> createState() => _ReceptionHomeScreenState();
}

class _ReceptionHomeScreenState extends State<ReceptionHomeScreen>
    with WidgetsBindingObserver {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _citas = [];
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
  void didUpdateWidget(covariant ReceptionHomeScreen oldWidget) {
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
    if (!AuthSession.activa || !AuthSession.esRecepcionista) {
      if (!mounted) return;
      setState(() { _cargando = false; _error = 'Esta información es exclusiva de Recepción.'; });
      return;
    }
    setState(() { _cargando = true; _error = null; });
    try {
      final datos = await _api.get('/personal/agenda');
      if (datos is! Map || datos['citas'] is! List) {
        throw ApiException(message: 'La agenda devolvió datos no válidos.');
      }
      final citas = <Map<String, dynamic>>[];
      for (final dato in datos['citas'] as List) {
        if (dato is! Map) throw ApiException(message: 'La agenda contiene una cita inválida.');
        citas.add(Map<String, dynamic>.from(dato));
      }
      if (!mounted || version != _solicitud) return;
      setState(() { _citas = citas; _cargando = false; });
    } on ApiException catch (e) {
      if (!mounted || version != _solicitud) return;
      setState(() { _error = e.message; _cargando = false; });
    } catch (_) {
      if (!mounted || version != _solicitud) return;
      setState(() {
        _error = 'No se pudo consultar la agenda. Verifica tu conexión.';
        _cargando = false;
      });
    }
  }

  DateTime? _fecha(Map<String, dynamic> cita) {
    final texto = '${cita['fecha'] ?? ''}';
    if (texto.length < 10) return null;
    return DateTime.tryParse(texto.substring(0, 10));
  }

  DateTime? _inicio(Map<String, dynamic> cita) {
    final d = _fecha(cita);
    if (d == null) return null;
    final hora = '${cita['hora_inicio'] ?? ''}'.split(':');
    if (hora.length < 2) return null;
    final h = int.tryParse(hora[0]);
    final m = int.tryParse(hora[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return DateTime(d.year, d.month, d.day, h, m);
  }

  bool _esHoy(Map<String, dynamic> cita) {
    final dia = _fecha(cita);
    final hoy = DateTime.now();
    return dia != null && dia.year == hoy.year && dia.month == hoy.month && dia.day == hoy.day;
  }

  String tr(String es, String en) => StaffPreferences.tr(es, en);

  @override
  Widget build(BuildContext context) {
    final hoy = _citas.where(_esHoy).toList();
    final pendientes = hoy.where((c) => c['estado'] == 'Pendiente').length;
    final confirmadas = hoy.where((c) => c['estado'] == 'Confirmada').length;
    final completadas = hoy.where((c) => c['estado'] == 'Completada').length;
    final canceladas = hoy.where((c) => c['estado'] == 'Cancelada').length;
    final ahora = DateTime.now();
    final proximas = _citas.where((c) {
      final inicio = _inicio(c);
      return inicio != null && !inicio.isBefore(ahora) &&
          (c['estado'] == 'Pendiente' || c['estado'] == 'Confirmada');
    }).toList()..sort((a, b) => _inicio(a)!.compareTo(_inicio(b)!));
    final activas = pendientes + confirmadas + completadas;
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(19, 19, 19, 34),
        children: [
          StaffDailyHeader(reception: true, refreshVersion: widget.refreshVersion),
          const SizedBox(height: 20),
          StaffSectionHeading(title: tr('Agenda de hoy', 'Today’s schedule'),
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
            StaffProgressCard(label: tr('Progreso de atención', 'Service progress'),
                completed: completadas, total: activas),
            if (pendientes > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr('$pendientes citas de hoy esperan aceptación.',
                      '$pendientes bookings today await acceptance.'),
                    style: TextStyle(color: scheme.onSurface, fontSize: 12))),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            StaffSectionHeading(title: tr('Próximas reservaciones', 'Upcoming bookings')),
            const SizedBox(height: 8),
            if (proximas.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(18),
                child: Text(tr('No hay reservaciones próximas.', 'No upcoming bookings.'),
                  textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant))))
            else
              ...proximas.take(4).map((cita) {
                final fecha = _fecha(cita);
                final hora = (cita['hora_inicio'] ?? '—').toString().split(':').take(2).join(':');
                return StaffUpcomingCard(
                  service: '${cita['servicio'] ?? tr('Servicio', 'Service')}',
                  person: '${cita['cliente'] ?? tr('Cliente', 'Client')} · ${cita['empleado'] ?? tr('Especialista', 'Specialist')}',
                  when: '${fecha?.day ?? '—'}/${fecha?.month ?? '—'}\n$hora',
                );
              }),
            if (_citas.length >= 500)
              Padding(padding: const EdgeInsets.only(top: 12),
                child: Text(tr('La API devuelve hasta 500 citas; el resumen podría ser parcial.',
                  'The API returns up to 500 bookings; the summary may be incomplete.'),
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))),
            Align(alignment: Alignment.centerRight,
              child: TextButton.icon(onPressed: widget.onVerAgenda,
                icon: const Icon(Icons.calendar_month_outlined, size: 17),
                label: Text(tr('Consultar agenda', 'View schedule')))),
          ],
        ],
      ),
    );
  }
}
