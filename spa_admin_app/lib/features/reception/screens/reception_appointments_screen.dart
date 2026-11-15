import 'package:flutter/material.dart';
import 'package:spa_admin_app/features/appointments/widgets/cita_visual_components.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/appointments/widgets/reprogramar_cita_dialog.dart';
import 'package:spa_admin_app/features/appointments/widgets/estado_asistencia_card.dart';

/// Vistas de consulta: la lista conserva sus filtros y acciones originales.
/// Mes, Semana y Dia reutilizan las mismas citas recibidas del backend.
enum _VistaRecepcion { lista, mes, semana, dia }

/// Agenda de Recepción: confirmar, cancelar, reprogramar y completar citas.
/// El backend revalida rol, puesto y estado en cada solicitud.
class ReceptionAppointmentsScreen extends StatefulWidget {
  ReceptionAppointmentsScreen({super.key});

  @override
  State<ReceptionAppointmentsScreen> createState() => _ReceptionAppointmentsScreenState();
}

class _ReceptionAppointmentsScreenState extends State<ReceptionAppointmentsScreen> {
  String tr(String es, String en) => StaffPreferences.tr(es, en);
  String status(String value) => switch (value) {
    'Pendiente' => tr('Pendiente', 'Pending'),
    'Confirmada' => tr('Confirmada', 'Confirmed'),
    'Completada' => tr('Completada', 'Completed'),
    'Cancelada' => tr('Cancelada', 'Cancelled'),
    _ => value,
  };

  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _citas = [];
  bool _cargando = true;
  String? _error;
  String _busqueda = '';
  String _filtro = 'Próximas';
  _VistaRecepcion _vista = _VistaRecepcion.lista;
  DateTime _fechaSeleccionada = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _mesVisible = DateTime(DateTime.now().year, DateTime.now().month);

  int? _procesandoId;
  Set<int> _idsInasistenciaHabilitados = <int>{};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  static String _fechaTexto(dynamic valor) {
    final texto = (valor ?? '').toString();
    return texto.length >= 10 ? texto.substring(0, 10) : texto;
  }

  static String _texto(dynamic valor, [String defecto = 'No disponible']) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? defecto : texto;
  }

  static DateTime? _parseFechaAsistencia(dynamic valor) {
    if (valor == null || valor.toString().trim().isEmpty) return null;
    return DateTime.tryParse(valor.toString());
  }

  Future<void> _cargar() async {
    if (!AuthSession.esRecepcionista || !AuthSession.activa) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No tienes permiso para consultar la agenda general.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final respuesta = await _api.get('/personal/agenda');
      if (respuesta is! Map<String, dynamic> || respuesta['citas'] is! List) {
        throw ApiException(message: 'El servidor devolvió un formato inesperado.');
      }
      final citas = <Map<String, dynamic>>[];
      for (final dato in respuesta['citas'] as List) {
        if (dato is! Map) {
          throw ApiException(message: 'La agenda contiene datos inválidos.');
        }
        citas.add(Map<String, dynamic>.from(dato));
      }
      // Consulta opcional: si Vanessa todavía no integró la ruta, no mostrar botón.
      var idsHabilitados = <int>{};
      try {
        final capacidades = await _api.get(
            '/personal/citas-manuales/inasistencias-habilitadas');
        if (capacidades is Map && capacidades['ids_habilitados'] is List) {
          idsHabilitados = (capacidades['ids_habilitados'] as List)
              .map((v) => int.tryParse('$v'))
              .whereType<int>()
              .where((id) => id > 0)
              .toSet();
        }
      } catch (_) {
        // No convertir la falta del módulo en un error de la agenda general.
      }
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _idsInasistenciaHabilitados = idsHabilitados;
        _cargando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar la agenda. Revisa la conexión.';
      });
    }
  }


  Future<void> _cambiarEstado(Map<String, dynamic> cita, String accion) async {
    if (_procesandoId != null) return;
    final id = int.tryParse('${cita['id_cita'] ?? ''}');
    if (id == null || id <= 0) return;
    final confirmar = accion == 'confirmar';
    final completar = accion == 'completar';
    final aprobado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(completar ? tr('¿Marcar cita como completada?', 'Mark appointment as completed?')
            : confirmar ? tr('¿Aceptar esta solicitud?', 'Accept this request?') : tr('¿Cancelar esta cita?', 'Cancel this appointment?')),
        content: Text(completar
            ? tr('Confirma que se realizó el servicio. Solo puede completarse una cita Confirmada cuyo horario ya terminó. Esta acción no se puede deshacer desde aquí.', 'Confirm the service was provided. Only a Confirmed appointment whose scheduled time has ended can be completed. This action cannot be undone here.')
            : confirmar
                ? tr('La cita quedará Confirmada y el cliente verá su reservación aceptada. Esto no significa que ya confirmó su asistencia.', 'The booking will become Confirmed. The client still needs to confirm attendance separately.')
                : tr('La cita quedará Cancelada, el horario se liberará y el registro seguirá en el historial. No se enviarán notificaciones automáticas desde aquí.', 'The booking will be Cancelled and the time slot released. The record remains in history. No automated notification is sent here.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: Text(tr('Volver', 'Back'))),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            style: FilledButton.styleFrom(
              backgroundColor: (confirmar || completar)
                  ? Color(0xFF27804F) : Color(0xFFC03945),
            ),
            child: Text(completar ? tr('Completar cita', 'Complete appointment')
                : confirmar ? tr('Aceptar solicitud', 'Accept request') : tr('Cancelar cita', 'Cancel appointment')),
          ),
        ],
      ),
    );
    if (!mounted || aprobado != true) return;
    setState(() => _procesandoId = id);
    try {
      await _api.patch('/personal/citas-manuales/$id/$accion', body: <String, dynamic>{});
      if (!mounted) return;
      mostrarAvisoCita(
        context,
        completar ? tr('Cita completada correctamente.', 'Appointment completed.')
            : confirmar ? tr('Solicitud aceptada. La asistencia se confirma por separado.', 'Request accepted. Attendance is confirmed separately.') : tr('Cita cancelada correctamente.', 'Appointment cancelled.'),
        tipo: confirmar || completar ? CitaAvisoTipo.exito : CitaAvisoTipo.error,
      );
      await _cargar();
    } on ApiException catch (error) {
      if (!mounted) return;
      mostrarAvisoCita(context, error.message, tipo: CitaAvisoTipo.error);
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      mostrarAvisoCita(context, tr('No se pudo actualizar la cita. Revisa la conexión.', 'Unable to update the booking. Check your connection.'),
          tipo: CitaAvisoTipo.error);
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  // Registro excepcional: Recepcion solo captura una respuesta real del cliente.
  // El backend verifica permiso, estado Confirmada y ventana de 48 horas.
  Future<void> _registrarRespuestaVerbal(Map<String, dynamic> cita) async {
    if (_procesandoId != null || !AuthSession.esRecepcionista || !AuthSession.activa ||
        cita['estado'] != 'Confirmada' ||
        cita['puede_registrar_asistencia'] != true ||
        cita['fecha_confirmacion'] != null) return;
    final id = int.tryParse('${cita['id_cita'] ?? ''}');
    if (id == null || id <= 0) return;
    String medio = 'telefono';
    final seleccionado = await showDialog<String>(
      context: context,
      builder: (dialogo) => StatefulBuilder(
        builder: (dialogo, actualizarDialogo) => AlertDialog(
          title: Text(tr('Registrar confirmación verbal', 'Record verbal confirmation')),
          content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('¿${_texto(cita['cliente'], 'El cliente')} confirmó personalmente que asistirá a esta cita? No registres una respuesta supuesta.',
                  'Did ${_texto(cita['cliente'], 'the client')} personally confirm they will attend? Do not record an assumed response.')),
              SizedBox(height: 16),
              Text(tr('¿Cómo confirmó el cliente?', 'How did the client confirm?'),
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                ChoiceChip(label: Text(tr('Por teléfono', 'By phone')),
                  selected: medio == 'telefono',
                  onSelected: (_) => actualizarDialogo(() { medio = 'telefono'; })),
                ChoiceChip(label: Text(tr('Presencialmente', 'In person')),
                  selected: medio == 'presencial',
                  onSelected: (_) => actualizarDialogo(() { medio = 'presencial'; })),
              ]),
              SizedBox(height: 12),
              Text(tr('La cita seguirá Confirmada. Solo se guardará la fecha de confirmación de asistencia.',
                  'The booking remains Confirmed; only the attendance confirmation date is saved.'),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogo),
              child: Text(tr('Volver', 'Back'))),
            FilledButton(onPressed: () => Navigator.pop(dialogo, medio),
              child: Text(tr('Sí, registrar respuesta', 'Yes, record confirmation'))),
          ],
        ),
      ),
    );
    if (!mounted || seleccionado == null) return;
    setState(() => _procesandoId = id);
    try {
      await _api.patch('/personal/citas-manuales/$id/confirmar-asistencia',
          body: <String, dynamic>{'medio': seleccionado});
      if (!mounted) return;
      mostrarAvisoCita(context,
          tr('Respuesta del cliente registrada correctamente.', 'Client confirmation recorded successfully.'),
          tipo: CitaAvisoTipo.exito);
      await _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarAvisoCita(context, e.message, tipo: CitaAvisoTipo.error);
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      mostrarAvisoCita(context,
          tr('No fue posible guardar la respuesta. Verifica la conexión.', 'Could not save the response. Check the connection.'),
          tipo: CitaAvisoTipo.error);
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  Future<void> _reportarInasistencia(Map<String, dynamic> cita) async {
    if (_procesandoId != null || !AuthSession.esRecepcionista || !AuthSession.activa ||
        cita['estado'] != 'Confirmada') return;
    final id = int.tryParse('${cita['id_cita'] ?? ''}');
    if (id == null || !_idsInasistenciaHabilitados.contains(id)) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(tr('¿Reportar inasistencia?', 'Report a no-show?')),
        content: Text(tr('${_texto(cita['cliente'], 'El cliente')} no se presentó al servicio. Asegúrate de que el horario terminó. La cita quedará Cancelada, sin modificar las observaciones del cliente; no podrá revertirse desde la aplicación.',
            '${_texto(cita['cliente'], 'The client')} did not attend. Confirm that the appointment time has ended. It will be marked Cancelled; client notes remain untouched and this cannot be undone here.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false),
              child: Text(tr('Volver', 'Back'))),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFAD5965)),
            child: Text(tr('Sí, reportar', 'Yes, report')),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;
    setState(() => _procesandoId = id);
    try {
      await _api.patch('/personal/citas-manuales/$id/reportar-inasistencia',
          body: <String, dynamic>{});
      if (!mounted) return;
      mostrarAvisoCita(context, tr('Ausencia registrada: cita Cancelada. Observaciones intactas.', 'No-show recorded: booking Cancelled. Client notes unchanged.'),
          tipo: CitaAvisoTipo.advertencia);
      await _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarAvisoCita(context, e.message, tipo: CitaAvisoTipo.error);
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      mostrarAvisoCita(context, tr('No fue posible registrar la inasistencia.', 'Unable to record the no-show.'),
          tipo: CitaAvisoTipo.error);
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  Future<void> _reprogramarCita(Map<String, dynamic> cita) async {
    if (_procesandoId != null) return;
    final id = int.tryParse('${cita['id_cita'] ?? ''}');
    if (id == null || id <= 0) return;
    setState(() => _procesandoId = id);
    try {
      final resultado = await showDialog<ReprogramacionResultado>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReprogramarCitaDialog(idCita: id),
      );
      if (!mounted) return;
      if (resultado != null) {
        mostrarAvisoCita(context, tr('Cita reprogramada. Quedó Pendiente de aceptación; la confirmación de asistencia anterior ya no aplica.', 'Booking rescheduled to Pending. The previous attendance confirmation no longer applies.'),
            tipo: CitaAvisoTipo.advertencia);
        await _cargar();
      }
    } finally {
      if (mounted) setState(() => _procesandoId = null);
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final busqueda = _busqueda.trim().toLowerCase();
    final resultado = _citas.where((cita) {
      final fecha = DateTime.tryParse(_fechaTexto(cita['fecha']));
      if (fecha == null) return false;
      if (_filtro == 'Hoy' &&
          (fecha.year != hoy.year || fecha.month != hoy.month || fecha.day != hoy.day)) {
        return false;
      }
      if (_filtro == 'Próximas' && fecha.isBefore(hoy)) return false;
      if (busqueda.isEmpty) return true;
      final campos = [
        cita['cliente'], cita['servicio'], cita['empleado'],
        cita['estado'], cita['id_cita'],
      ].join(' ').toLowerCase();
      return campos.contains(busqueda);
    }).toList();
    resultado.sort((a, b) {
      final fechaA = _fechaTexto(a['fecha']);
      final fechaB = _fechaTexto(b['fecha']);
      final orden = fechaA.compareTo(fechaB);
      if (orden != 0) return orden;
      return _texto(a['hora_inicio'], '').compareTo(_texto(b['hora_inicio'], ''));
    });
    return resultado;
  }

  // Los filtros antiguos (Próximas/Hoy/Todas) siguen intactos en la vista Lista.
  // Las vistas de calendario muestran exclusivamente la fecha seleccionada.
  List<Map<String, dynamic>> get _citasFechaSeleccionada {
    final busqueda = _busqueda.trim().toLowerCase();
    final resultado = _citas.where((cita) {
      final fecha = DateTime.tryParse(_fechaTexto(cita['fecha']));
      if (fecha == null || !_mismoDia(fecha, _fechaSeleccionada)) return false;
      if (busqueda.isEmpty) return true;
      return [cita['cliente'], cita['servicio'], cita['empleado'],
        cita['estado'], cita['id_cita']].join(' ').toLowerCase().contains(busqueda);
    }).toList();
    resultado.sort((a, b) =>
        _texto(a['hora_inicio'], '').compareTo(_texto(b['hora_inicio'], '')));
    return resultado;
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _lunesDe(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day - fecha.weekday + 1);

  void _seleccionarFecha(DateTime fecha) {
    setState(() {
      _fechaSeleccionada = DateTime(fecha.year, fecha.month, fecha.day);
      _mesVisible = DateTime(fecha.year, fecha.month);
    });
  }

  void _irAHoy() => _seleccionarFecha(DateTime.now());

  void _navegarFecha(int paso) {
    final fecha = _fechaSeleccionada;
    if (_vista == _VistaRecepcion.mes) {
      final nuevoMes = DateTime(_mesVisible.year, _mesVisible.month + paso);
      final maximo = DateUtils.getDaysInMonth(nuevoMes.year, nuevoMes.month);
      _seleccionarFecha(DateTime(nuevoMes.year, nuevoMes.month,
          fecha.day > maximo ? maximo : fecha.day));
    } else if (_vista == _VistaRecepcion.semana) {
      _seleccionarFecha(DateTime(fecha.year, fecha.month, fecha.day + 7 * paso));
    } else {
      _seleccionarFecha(DateTime(fecha.year, fecha.month, fecha.day + paso));
    }
  }

  // Contar citas por fecha sin modificar la consulta ni los estados del servidor.
  Map<String, int> _conteosFechas() {
    final totales = <String, int>{};
    for (final cita in _citas) {
      final fecha = _fechaTexto(cita['fecha']);
      if (DateTime.tryParse(fecha) == null) continue;
      totales[fecha] = (totales[fecha] ?? 0) + 1;
    }
    return totales;
  }

  String _claveFecha(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

  Widget _selectorVista() {
    final scheme = Theme.of(context).colorScheme;
    const opciones = <_VistaRecepcion>[
      _VistaRecepcion.lista, _VistaRecepcion.mes,
      _VistaRecepcion.semana, _VistaRecepcion.dia,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(tr('Explorar agenda', 'Explore schedule'),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
              color: scheme.onSurface)),
      const SizedBox(height: 9),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final vista in opciones) ...[
            ChoiceChip(
              avatar: Icon(switch (vista) {
                _VistaRecepcion.lista => Icons.view_agenda_outlined,
                _VistaRecepcion.mes => Icons.calendar_month_outlined,
                _VistaRecepcion.semana => Icons.date_range_outlined,
                _VistaRecepcion.dia => Icons.today_outlined,
              }, size: 16, color: _vista == vista ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
              label: Text(switch (vista) {
                _VistaRecepcion.lista => tr('Lista', 'List'),
                _VistaRecepcion.mes => tr('Mes', 'Month'),
                _VistaRecepcion.semana => tr('Semana', 'Week'),
                _VistaRecepcion.dia => tr('Día', 'Day'),
              }),
              selected: _vista == vista,
              onSelected: (_) => setState(() => _vista = vista),
            ),
            const SizedBox(width: 7),
          ],
        ]),
      ),
    ]);
  }

  Widget _celdaFecha(DateTime fecha, Map<String, int> conteos,
      {bool compacta = false}) {
    final scheme = Theme.of(context).colorScheme;
    final seleccionada = _mismoDia(fecha, _fechaSeleccionada);
    final ahora = DateTime.now();
    final esHoy = _mismoDia(fecha, ahora);
    final cantidad = conteos[_claveFecha(fecha)] ?? 0;
    return Semantics(
      label: '${MaterialLocalizations.of(context).formatMediumDate(fecha)}, '
          '$cantidad ${tr('citas', 'appointments')}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _seleccionarFecha(fecha),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: seleccionada ? scheme.primaryContainer
                  : esHoy ? scheme.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seleccionada ? scheme.primary.withValues(alpha: 0.55)
                    : esHoy ? scheme.primary.withValues(alpha: 0.28) : Colors.transparent,
              ),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${fecha.day}', style: TextStyle(
                fontSize: compacta ? 15 : 13,
                fontWeight: seleccionada || esHoy ? FontWeight.w900 : FontWeight.w600,
                color: seleccionada ? scheme.onPrimaryContainer : scheme.onSurface,
              )),
              const SizedBox(height: 3),
              if (cantidad > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: seleccionada ? scheme.primary : scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text('$cantidad', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                      color: seleccionada ? scheme.onPrimary : scheme.onSecondaryContainer)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _panelCalendario() {
    if (_vista == _VistaRecepcion.lista) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    final conteos = _conteosFechas();
    final semanaInicio = _lunesDe(_fechaSeleccionada);
    final semanaFin = DateTime(semanaInicio.year, semanaInicio.month, semanaInicio.day + 6);
    final titulo = switch (_vista) {
      _VistaRecepcion.mes => loc.formatMonthYear(_mesVisible),
      _VistaRecepcion.semana =>
        '${loc.formatMediumDate(semanaInicio)} – ${loc.formatMediumDate(semanaFin)}',
      _ => loc.formatMediumDate(_fechaSeleccionada),
    };
    final diasSemana = StaffPreferences.language.value == 'en'
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.event_available_outlined, color: scheme.primary, size: 21),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface))),
          TextButton(
            onPressed: _irAHoy,
            child: Text(tr('Hoy', 'Today')),
          ),
          IconButton(
            tooltip: tr('Anterior', 'Previous'),
            onPressed: () => _navegarFecha(-1),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: tr('Siguiente', 'Next'),
            onPressed: () => _navegarFecha(1),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
        if (_vista == _VistaRecepcion.mes) ...[
          const SizedBox(height: 12),
          Row(children: [
            for (final nombre in diasSemana)
              Expanded(child: Center(child: Text(nombre,
                style: TextStyle(color: scheme.onSurfaceVariant,
                  fontSize: 11, fontWeight: FontWeight.w800)))),
          ]),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DateTime(_mesVisible.year, _mesVisible.month, 1).weekday - 1 +
                DateUtils.getDaysInMonth(_mesVisible.year, _mesVisible.month),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 5,
              crossAxisSpacing: 4, childAspectRatio: 0.84,
            ),
            itemBuilder: (context, index) {
              final inicio = DateTime(_mesVisible.year, _mesVisible.month, 1).weekday - 1;
              if (index < inicio) return const SizedBox.shrink();
              return _celdaFecha(DateTime(_mesVisible.year, _mesVisible.month, index - inicio + 1), conteos);
            },
          ),
        ] else if (_vista == _VistaRecepcion.semana) ...[
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(child: Column(children: [
                Text(diasSemana[i], style: TextStyle(color: scheme.onSurfaceVariant,
                    fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                SizedBox(height: 60, child: _celdaFecha(DateTime(
                    semanaInicio.year, semanaInicio.month, semanaInicio.day + i),
                    conteos, compacta: true)),
              ])),
          ]),
        ],
        const SizedBox(height: 13),
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 12),
        Row(children: [
          Icon(Icons.schedule_rounded, color: scheme.primary, size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text(
            '${tr('Citas del', 'Appointments for')} '
            '${loc.formatMediumDate(_fechaSeleccionada)}',
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700,
                fontSize: 13),
          )),
          Text('${_citasFechaSeleccionada.length}',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Color _colorEstado(String estado) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    switch (estado.toLowerCase()) {
      case 'confirmada': return dark ? const Color(0xFF85D4A6) : const Color(0xFF2E7D32);
      case 'pendiente': return dark ? const Color(0xFFF2C779) : const Color(0xFFAC780D);
      case 'cancelada': return dark ? const Color(0xFFF1A2B2) : const Color(0xFFC03945);
      case 'completada': return dark ? const Color(0xFFC5B5F2) : const Color(0xFF7954A7);
      default: return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _resumenEstado(String nombre, int total, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.23)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 7),
        Text('$nombre $total',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  Widget _lineaDato(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(children: [
        Icon(icono, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 16),
        SizedBox(width: 8),
        Expanded(child: Text('$etiqueta: $valor',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface))),
      ]),
    );
  }

  Widget _tarjetaCita(Map<String, dynamic> cita) {
    final estado = _texto(cita['estado'], 'Pendiente');
    final color = _colorEstado(estado);
    final fecha = _fechaTexto(cita['fecha']);
    final fechaValor = DateTime.tryParse(fecha);
    final hora = _texto(cita['hora_inicio'], '--:--');
    final horaCorta = hora.length >= 5 ? hora.substring(0, 5) : hora;
    final id = int.tryParse('${cita['id_cita'] ?? ''}');
    final procesando = id != null && _procesandoId == id;
    const meses = <String>[
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(
          color: Theme.of(context).shadowColor.withValues(alpha: 0.06),
          blurRadius: 15,
          offset: Offset(0, 5),
        )],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Text(fechaValor == null ? '--' : '${fechaValor.day}',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary)),
                Text(fechaValor == null ? 'FECHA' :
                  meses[fechaValor.month - 1],
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary)),
              ]),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_texto(cita['servicio']),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface)),
              SizedBox(height: 4),
              Text('$horaCorta h · Cita #${_texto(cita['id_cita'], '-')}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            ])),
          ]),
          SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(estado == 'Confirmada' || estado == 'Completada'
                ? Icons.check_circle_rounded : estado == 'Cancelada'
                  ? Icons.cancel_rounded : estado == 'Inasistencia'
                    ? Icons.person_off_outlined : Icons.schedule_rounded,
                size: 15, color: color),
              SizedBox(width: 6),
              Text(status(estado), style: TextStyle(color: color,
                fontSize: 12, fontWeight: FontWeight.w800)),
            ]),
          ),
          SizedBox(height: 5),
          _lineaDato(Icons.person_outline_rounded, tr('Cliente', 'Client'), _texto(cita['cliente'])),
          _lineaDato(Icons.spa_outlined, tr('Especialista', 'Specialist'), _texto(cita['empleado'])),
          _lineaDato(Icons.schedule_outlined, tr('Hora', 'Time'), horaCorta),
          if (estado == 'Confirmada' && cita.containsKey('fecha_confirmacion')) ...[
            SizedBox(height: 12),
            EstadoAsistenciaCard(
              datosDisponibles: cita.containsKey('fecha_confirmacion'),
              fechaConfirmacion: _parseFechaAsistencia(cita['fecha_confirmacion']),
              fechaLimite: _parseFechaAsistencia(cita['fecha_limite']),
              onRegistrarRespuesta: cita['puede_registrar_asistencia'] == true &&
                      cita['fecha_confirmacion'] == null &&
                      (_procesandoId == null || _procesandoId == cita['id_cita'])
                  ? () => _registrarRespuestaVerbal(cita)
                  : null,
              registrandoRespuesta: _procesandoId == cita['id_cita'],
            ),
          ],
          if (procesando) ...[
            SizedBox(height: 12),
            LinearProgressIndicator(minHeight: 3),
          ],
          if (estado == 'Pendiente' || estado == 'Confirmada') ...[
            SizedBox(height: 14),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (estado == 'Pendiente')
                FilledButton.tonalIcon(
                  onPressed: _procesandoId != null ? null : () => _cambiarEstado(cita, 'confirmar'),
                  icon: Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(tr('Aceptar solicitud', 'Accept request')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _procesandoId != null ? null : () => _reprogramarCita(cita),
                icon: Icon(Icons.event_repeat_outlined, size: 18),
                label: Text(tr('Reprogramar', 'Reschedule')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              if (estado == 'Confirmada')
                FilledButton.tonalIcon(
                  onPressed: _procesandoId != null ? null : () => _cambiarEstado(cita, 'completar'),
                  icon: Icon(Icons.task_alt_rounded, size: 18),
                  label: Text(tr('Completar', 'Complete')),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              if (estado == 'Confirmada' && id != null &&
                  _idsInasistenciaHabilitados.contains(id))
                OutlinedButton.icon(
                  onPressed: _procesandoId != null ? null : () => _reportarInasistencia(cita),
                  icon: Icon(Icons.person_off_outlined, size: 18),
                  label: Text(tr('Reportar inasistencia', 'Report no-show')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: .5)),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _procesandoId != null ? null : () => _cambiarEstado(cita, 'cancelar'),
                icon: Icon(Icons.cancel_outlined, size: 18),
                label: Text(tr('Cancelar', 'Cancel')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error.withValues(alpha: .5)),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final citas = _vista == _VistaRecepcion.lista ? _filtradas : _citasFechaSeleccionada;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Text(tr('RECEPCIÓN  /  AURA SPA', 'RECEPTION  /  AURA SPA'),
            style: TextStyle(fontSize: 10, letterSpacing: 1.3, fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary)),
          SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: Theme.of(context).brightness == Brightness.dark
                ? [Color(0xFF44313C), Color(0xFF2C242C)]
                : [Color(0xFFFFF0F4), Color(0xFFFFFAFB)]),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary, size: 26),
                SizedBox(width: 9),
                Expanded(child: Text(tr('Agenda general', 'General schedule'), style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface))),
              ]),
              SizedBox(height: 7),
              Text(tr('Consulta citas y gestiona cada etapa de atención.', 'View appointments and manage each step of care.'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _resumenEstado(tr('Pendientes', 'Pending'), _citas.where((c) => c['estado'] == 'Pendiente').length,
                  Color(0xFFAC780D)),
                _resumenEstado(tr('Confirmadas', 'Confirmed'), _citas.where((c) => c['estado'] == 'Confirmada').length,
                  Color(0xFF237A51)),
                _resumenEstado(tr('Completadas', 'Completed'), _citas.where((c) => c['estado'] == 'Completada').length,
                  Color(0xFF755297)),
                _resumenEstado(tr('Canceladas', 'Cancelled'), _citas.where((c) => c['estado'] == 'Cancelada').length,
                  Color(0xFFC03945)),
              ]),
            ]),
          ),
          if (_citas.isNotEmpty &&
              !_citas.any((cita) => cita.containsKey('fecha_confirmacion'))) ...[
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                SizedBox(width: 8),
                Expanded(child: Text(tr(
                  'La consulta de agenda todavía no informa asistencia confirmada.',
                  'The schedule API does not yet provide attendance confirmations.'),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                )),
              ]),
            ),
          ],
          SizedBox(height: 16),
          _selectorVista(),
          _panelCalendario(),
          TextField(
            onChanged: (valor) => setState(() => _busqueda = valor),
            decoration: InputDecoration(
              hintText: tr('Buscar cliente, servicio o especialista', 'Search client, service or specialist'),
              prefixIcon: Icon(Icons.search_outlined),
            ),
          ),
          SizedBox(height: 12),
          if (_vista == _VistaRecepcion.lista)
          Wrap(
            spacing: 8,
            children: ['Próximas', 'Hoy', 'Todas'].map((filtro) {
              return ChoiceChip(
                label: Text(switch (filtro) { 'Próximas' => tr('Próximas', 'Upcoming'), 'Hoy' => tr('Hoy', 'Today'), _ => tr('Todas', 'All') }),
                selected: filtro == _filtro,
                onSelected: (_) => setState(() => _filtro = filtro),
              );
            }).toList(),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('${citas.length} citas', '${citas.length} appointments'),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              TextButton.icon(
                onPressed: _cargando ? null : _cargar,
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text(tr('Actualizar', 'Refresh')),
              ),
            ],
          ),
          if (_cargando)
            Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_cargando && _error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.wifi_off_outlined, size: 34),
                  SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  SizedBox(height: 10),
                  OutlinedButton(onPressed: _cargar, child: Text(tr('Reintentar', 'Retry'))),
                ]),
              ),
            ),
          if (!_cargando && _error == null && citas.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text(_vista == _VistaRecepcion.lista
                  ? tr('No hay citas que coincidan con el filtro.', 'No appointments match the filter.')
                  : tr('No hay citas para esta fecha con la búsqueda actual.', 'No appointments for this date match your search.'),
                    textAlign: TextAlign.center),
              ),
            ),
          if (!_cargando && _error == null)
            ...citas.map(_tarjetaCita),
          if (!_cargando && _error == null && _citas.length >= 500)
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(tr('Se muestran hasta 500 citas. La paginación se agregará después.', 'Up to 500 appointments are shown. Pagination will be added later.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
