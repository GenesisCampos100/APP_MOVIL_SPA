import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Vistas de consulta. Nunca habilitan acciones operativas del Administrador.
enum _VistaEmpleado { lista, mes, semana, dia }

/// Agenda de solo lectura del especialista.
/// Las citas llegan ya autorizadas por el backend a partir de su JWT.
class EmployeeAppointmentsScreen extends StatefulWidget {
  const EmployeeAppointmentsScreen({super.key, this.refreshVersion = 0});
  final int refreshVersion;

  @override
  State<EmployeeAppointmentsScreen> createState() =>
      _EmployeeAppointmentsScreenState();
}

class _EmployeeAppointmentsScreenState extends State<EmployeeAppointmentsScreen>
    with WidgetsBindingObserver {
  final CitasRepository _repository = CitasRepository();
  List<AppointmentModel> _citas = [];
  bool _cargando = true;
  String? _error;
  String _filtro = 'Próximas';
  String _busqueda = '';
  int _solicitud = 0;
  _VistaEmpleado _vista = _VistaEmpleado.lista;
  DateTime _fechaSeleccionada = DateUtils.dateOnly(DateTime.now());
  DateTime _mesVisible = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargar();
  }

  @override
  void didUpdateWidget(covariant EmployeeAppointmentsScreen oldWidget) {
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
        _error = 'Esta agenda es exclusiva del personal especialista.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final citas = await _repository.obtenerCitas();
      if (!mounted || version != _solicitud) return;
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted || version != _solicitud) return;
      setState(() {
        _cargando = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted || version != _solicitud) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo consultar tu agenda. Verifica la conexión.';
      });
    }
  }

  String tr(String es, String en) => StaffPreferences.tr(es, en);

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _esHoy(DateTime fecha) => _mismoDia(fecha, DateTime.now());

  DateTime _lunesDe(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day - fecha.weekday + 1);

  String _claveFecha(DateTime fecha) =>
      '${fecha.year}-${fecha.month}-${fecha.day}';

  bool _coincideBusqueda(AppointmentModel cita) {
    final texto = _busqueda.trim().toLowerCase();
    if (texto.isEmpty) return true;
    return '${cita.nombreCliente} ${cita.nombreServicio} '
            '${cita.estado} ${cita.idCita}'
        .toLowerCase()
        .contains(texto);
  }

  void _ordenar(List<AppointmentModel> citas) {
    citas.sort((a, b) {
      final fecha = a.fecha.compareTo(b.fecha);
      return fecha != 0 ? fecha : a.horaInicio.compareTo(b.horaInicio);
    });
  }

  /// Conserva exactamente los filtros originales de la vista Lista.
  List<AppointmentModel> get _filtradas {
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final citas = _citas.where((c) {
      if (_filtro == 'Hoy' && !_esHoy(c.fecha)) return false;
      if (_filtro == 'Próximas' && (c.fecha.isBefore(hoySinHora) ||
          (c.estado != 'Pendiente' && c.estado != 'Confirmada'))) {
        return false;
      }
      return _coincideBusqueda(c);
    }).toList();
    _ordenar(citas);
    return citas;
  }

  /// Calendario: fecha + búsqueda. Los chips de Lista no limitan estas vistas.
  List<AppointmentModel> get _citasDeFecha {
    final citas = _citas.where((c) =>
        _mismoDia(c.fecha, _fechaSeleccionada) && _coincideBusqueda(c)).toList();
    _ordenar(citas);
    return citas;
  }

  Map<String, int> _conteosFechas() {
    final conteos = <String, int>{};
    for (final cita in _citas) {
      if (!_coincideBusqueda(cita)) continue;
      final clave = _claveFecha(cita.fecha);
      conteos[clave] = (conteos[clave] ?? 0) + 1;
    }
    return conteos;
  }

  int get _totalHoy => _citas.where((c) => _esHoy(c.fecha)).length;

  int get _totalProximas {
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    return _citas.where((c) => !c.fecha.isBefore(hoySinHora) &&
        (c.estado == 'Pendiente' || c.estado == 'Confirmada')).length;
  }

  String _estado(String estado) => switch (estado) {
    'Pendiente' => tr('Pendiente', 'Pending'),
    'Confirmada' => tr('Confirmada', 'Confirmed'),
    'Completada' => tr('Completada', 'Completed'),
    'Cancelada' => tr('Cancelada', 'Cancelled'),
    _ => estado,
  };

  Color _colorEstado(String estado) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (estado) {
      'Confirmada' => dark ? const Color(0xFF85D4A6) : const Color(0xFF2C7954),
      'Pendiente' => dark ? const Color(0xFFF2C779) : const Color(0xFFA77B21),
      'Cancelada' => dark ? const Color(0xFFF1A2B2) : const Color(0xFFB35A65),
      'Completada' => dark ? const Color(0xFFC5B5F2) : const Color(0xFF705AA5),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  void _seleccionarFecha(DateTime fecha) {
    setState(() {
      _fechaSeleccionada = DateTime(fecha.year, fecha.month, fecha.day);
      _mesVisible = DateTime(fecha.year, fecha.month);
    });
  }

  void _irAHoy() => _seleccionarFecha(DateTime.now());

  void _navegarFecha(int paso) {
    if (_vista == _VistaEmpleado.mes) {
      final siguiente = DateTime(_mesVisible.year, _mesVisible.month + paso);
      final maxDia = DateUtils.getDaysInMonth(siguiente.year, siguiente.month);
      final dia = _fechaSeleccionada.day > maxDia
          ? maxDia : _fechaSeleccionada.day;
      _seleccionarFecha(DateTime(siguiente.year, siguiente.month, dia));
      return;
    }
    final dias = _vista == _VistaEmpleado.semana ? 7 : 1;
    _seleccionarFecha(DateTime(_fechaSeleccionada.year,
        _fechaSeleccionada.month, _fechaSeleccionada.day + dias * paso));
  }

  Widget _resumenRapido(String etiqueta, int numero, IconData icono) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(child: Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 10, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: scheme.primary, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$numero', style: TextStyle(fontSize: 21, height: 1,
                fontWeight: FontWeight.w800, color: scheme.onSurface)),
            const SizedBox(height: 5),
            Text(etiqueta, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        )),
      ]),
    ));
  }

  Widget _encabezado() {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final loc = MaterialLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Expanded(child: Text(tr('AURA SPA  /  MI JORNADA', 'AURA SPA  /  MY DAY'),
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800,
              letterSpacing: 1.4, fontSize: 10))),
        IconButton.filledTonal(
          tooltip: tr('Actualizar agenda', 'Refresh schedule'),
          onPressed: _cargando ? null : _cargar,
          icon: const Icon(Icons.refresh_rounded, size: 19),
        ),
      ]),
      const SizedBox(height: 7),
      Text(tr('Mi agenda', 'My schedule'),
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800,
            height: 1.1, color: scheme.onSurface)),
      const SizedBox(height: 7),
      Text(tr('Consulta tus servicios asignados, por fecha y horario.',
              'See your assigned services by date and time.'),
        style: TextStyle(fontSize: 12, height: 1.5,
            color: scheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: dark ? const Color(0xFF44303D) : const Color(0xFFF8E8EE),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 17,
              color: dark ? const Color(0xFFF4BDD2) : const Color(0xFFA34B6F)),
          const SizedBox(width: 10),
          Expanded(child: Text(loc.formatMediumDate(DateTime.now()),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: dark ? const Color(0xFFF9DBE7) : const Color(0xFF7B3D57)))),
          Text(tr('ESPECIALISTA', 'SPECIALIST'), style: TextStyle(
              fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w800,
              color: dark ? const Color(0xFFF4BDD2) : const Color(0xFFA34B6F))),
        ]),
      ),
      if (!_cargando && _error == null) ...[
        const SizedBox(height: 12),
        Row(children: [
          _resumenRapido(tr('Citas de hoy', 'Today'), _totalHoy,
              Icons.today_outlined),
          const SizedBox(width: 10),
          _resumenRapido(tr('Próximas', 'Upcoming'), _totalProximas,
              Icons.event_available_outlined),
        ]),
      ],
    ]);
  }

  Widget _selectorVista() {
    final scheme = Theme.of(context).colorScheme;
    final nombres = <_VistaEmpleado, String>{
      _VistaEmpleado.lista: tr('Lista', 'List'),
      _VistaEmpleado.mes: tr('Mes', 'Month'),
      _VistaEmpleado.semana: tr('Semana', 'Week'),
      _VistaEmpleado.dia: tr('Día', 'Day'),
    };
    final iconos = <_VistaEmpleado, IconData>{
      _VistaEmpleado.lista: Icons.view_agenda_outlined,
      _VistaEmpleado.mes: Icons.calendar_month_outlined,
      _VistaEmpleado.semana: Icons.date_range_outlined,
      _VistaEmpleado.dia: Icons.today_outlined,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final vista in _VistaEmpleado.values) ...[
          ChoiceChip(
            showCheckmark: false,
            avatar: Icon(iconos[vista], size: 17,
              color: _vista == vista
                  ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
            label: Text(nombres[vista]!),
            selected: _vista == vista,
            onSelected: (_) => setState(() => _vista = vista),
          ),
          const SizedBox(width: 8),
        ],
      ]),
    );
  }

  Widget _selectorFiltros() {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(spacing: 8, runSpacing: 5, children: [
      for (final filtro in const ['Próximas', 'Hoy', 'Todas'])
        ChoiceChip(
          showCheckmark: false,
          label: Text(switch (filtro) {
            'Próximas' => tr('Próximas', 'Upcoming'),
            'Hoy' => tr('Hoy', 'Today'),
            _ => tr('Todas', 'All'),
          }),
          selected: _filtro == filtro,
          selectedColor: scheme.primaryContainer,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: _filtro == filtro
                ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          ),
          onSelected: (_) => setState(() => _filtro = filtro),
        ),
    ]);
  }

  Widget _celdaFecha(DateTime fecha, Map<String, int> conteos,
      {bool compacta = false}) {
    final scheme = Theme.of(context).colorScheme;
    final seleccionada = _mismoDia(fecha, _fechaSeleccionada);
    final esHoy = _esHoy(fecha);
    final total = conteos[_claveFecha(fecha)] ?? 0;
    return Semantics(
      label: '${MaterialLocalizations.of(context).formatMediumDate(fecha)}, '
          '$total ${tr('citas', 'appointments')}',
      button: true,
      child: Material(color: Colors.transparent,
        child: InkWell(
          onTap: () => _seleccionarFecha(fecha),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: seleccionada ? scheme.primaryContainer
                  : esHoy ? scheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: seleccionada
                  ? scheme.primary.withValues(alpha: .45)
                  : esHoy ? scheme.primary.withValues(alpha: .24)
                  : Colors.transparent),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${fecha.day}', style: TextStyle(
                  fontSize: compacta ? 15 : 13,
                  fontWeight: seleccionada || esHoy
                      ? FontWeight.w800 : FontWeight.w500,
                  color: seleccionada
                      ? scheme.onPrimaryContainer : scheme.onSurface,
                )),
                const SizedBox(height: 3),
                if (total > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 17),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: seleccionada ? scheme.primary : scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$total', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                          color: seleccionada
                              ? scheme.onPrimary : scheme.onSecondaryContainer)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panelCalendario() {
    final scheme = Theme.of(context).colorScheme;
    final loc = MaterialLocalizations.of(context);
    final conteos = _conteosFechas();
    final lunes = _lunesDe(_fechaSeleccionada);
    final domingo = DateTime(lunes.year, lunes.month, lunes.day + 6);
    final titulo = switch (_vista) {
      _VistaEmpleado.mes => loc.formatMonthYear(_mesVisible),
      _VistaEmpleado.semana =>
        '${loc.formatMediumDate(lunes)} – ${loc.formatMediumDate(domingo)}',
      _ => loc.formatMediumDate(_fechaSeleccionada),
    };
    final dias = StaffPreferences.language.value == 'en'
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return Container(
      margin: const EdgeInsets.only(top: 13, bottom: 16),
      padding: const EdgeInsets.fromLTRB(13, 15, 13, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.event_available_outlined, color: scheme.primary, size: 19)),
          const SizedBox(width: 9),
          Expanded(child: Text(titulo, maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                color: scheme.onSurface))),
          TextButton(onPressed: _irAHoy, child: Text(tr('Hoy', 'Today'))),
          IconButton(
            tooltip: tr('Anterior', 'Previous'),
            onPressed: () => _navegarFecha(-1),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_left_rounded)),
          IconButton(
            tooltip: tr('Siguiente', 'Next'),
            onPressed: () => _navegarFecha(1),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        if (_vista == _VistaEmpleado.mes) ...[
          const SizedBox(height: 14),
          Row(children: [
            for (final nombre in dias)
              Expanded(child: Center(child: Text(nombre,
                style: TextStyle(color: scheme.onSurfaceVariant,
                    fontSize: 10, fontWeight: FontWeight.w800)))),
          ]),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DateTime(_mesVisible.year, _mesVisible.month, 1).weekday - 1
                + DateUtils.getDaysInMonth(_mesVisible.year, _mesVisible.month),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 3,
              childAspectRatio: .83,
            ),
            itemBuilder: (context, index) {
              final inicio = DateTime(_mesVisible.year, _mesVisible.month, 1).weekday - 1;
              if (index < inicio) return const SizedBox.shrink();
              return _celdaFecha(DateTime(_mesVisible.year, _mesVisible.month,
                  index - inicio + 1), conteos);
            },
          ),
        ] else if (_vista == _VistaEmpleado.semana) ...[
          const SizedBox(height: 14),
          Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(child: Column(children: [
                Text(dias[i], style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                SizedBox(height: 58,
                  child: _celdaFecha(DateTime(lunes.year, lunes.month,
                      lunes.day + i), conteos, compacta: true)),
              ])),
          ]),
        ],
        const SizedBox(height: 13),
        Divider(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: 13),
        Row(children: [
          Icon(Icons.schedule_rounded, size: 17, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(
            '${tr('Citas del', 'Appointments for')} '
                '${loc.formatMediumDate(_fechaSeleccionada)}',
            style: TextStyle(color: scheme.onSurface,
                fontSize: 12, fontWeight: FontWeight.w700))),
          Text('${_citasDeFecha.length}',
            style: TextStyle(fontWeight: FontWeight.w900,
                fontSize: 16, color: scheme.primary)),
        ]),
      ]),
    );
  }

  Widget _datoDetalle(IconData icono, String etiqueta, String valor) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icono, size: 17, color: scheme.primary)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: TextStyle(fontSize: 11,
                color: scheme.onSurfaceVariant)),
            const SizedBox(height: 3),
            Text(valor, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: scheme.onSurface)),
          ])),
      ]),
    );
  }

  void _verDetalle(AppointmentModel cita) {
    final scheme = Theme.of(context).colorScheme;
    final estadoColor = _colorEstado(cita.estado);
    final fecha = MaterialLocalizations.of(context).formatMediumDate(cita.fecha);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scheme.surface,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .82),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
                Text(tr('DETALLE DE LA CITA', 'APPOINTMENT DETAILS'),
                  style: TextStyle(fontSize: 10, letterSpacing: 1.3,
                      fontWeight: FontWeight.w800, color: scheme.primary)),
                const SizedBox(height: 8),
                Text(cita.nombreServicio, style: TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800,
                    color: scheme.onSurface)),
                const SizedBox(height: 11),
                Container(padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(30)),
                  child: Text(_estado(cita.estado),
                    style: TextStyle(color: estadoColor,
                        fontSize: 12, fontWeight: FontWeight.w800))),
                const SizedBox(height: 16),
                Divider(color: scheme.outlineVariant),
                _datoDetalle(Icons.person_outline_rounded,
                    tr('Cliente', 'Client'), cita.nombreCliente),
                _datoDetalle(Icons.event_outlined,
                    tr('Fecha', 'Date'), fecha),
                _datoDetalle(Icons.schedule_outlined,
                    tr('Hora', 'Time'), cita.horaInicio),
                _datoDetalle(Icons.timelapse_outlined,
                    tr('Duración', 'Duration'), cita.duracionAplicada),
                const SizedBox(height: 6),
                Text(tr('Observaciones del cliente', 'Client notes'),
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w800, color: scheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: .045),
                    borderRadius: BorderRadius.circular(13)),
                  child: Text(cita.observaciones?.trim().isNotEmpty == true
                      ? cita.observaciones!.trim()
                      : tr('Sin observaciones registradas.', 'No notes provided.'),
                    style: TextStyle(fontSize: 12, height: 1.5,
                        color: scheme.onSurfaceVariant)),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(tr('Cerrar', 'Close')))),
              ]),
          ),
        ),
      ),
    );
  }

  Widget _tarjeta(AppointmentModel cita) {
    final scheme = Theme.of(context).colorScheme;
    final estadoColor = _colorEstado(cita.estado);
    final fecha = MaterialLocalizations.of(context).formatMediumDate(cita.fecha);
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(19),
          side: BorderSide(color: scheme.outlineVariant)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _verDetalle(cita),
          child: Container(
            decoration: BoxDecoration(border: Border(
                left: BorderSide(color: estadoColor, width: 4))),
            child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule_rounded, color: scheme.primary, size: 17),
                        const SizedBox(width: 6),
                        Text(cita.horaInicio,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                              color: scheme.onSurface)),
                        const Spacer(),
                        Flexible(child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: estadoColor.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(20)),
                          child: Text(_estado(cita.estado),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: estadoColor,
                                fontWeight: FontWeight.w800, fontSize: 10)),
                        )),
                      ]),
                    const SizedBox(height: 12),
                    Text(cita.nombreServicio,
                      style: TextStyle(fontSize: 15, height: 1.35,
                          fontWeight: FontWeight.w800, color: scheme.onSurface)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.person_outline_rounded,
                          size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(child: Text(cita.nombreCliente,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12,
                            color: scheme.onSurfaceVariant))),
                    ]),
                    const SizedBox(height: 11),
                    Divider(height: 1, color: scheme.outlineVariant),
                    const SizedBox(height: 10),
                    Row(children: [
                      Icon(Icons.event_outlined,
                          size: 15, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Expanded(child: Text(fecha, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11,
                            color: scheme.onSurfaceVariant))),
                      Text(tr('Ver detalle', 'View details'),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                            color: scheme.primary)),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: scheme.primary),
                    ]),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _estadoVacio({required bool esCalendario}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 27, 22, 27),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: [
        Icon(Icons.event_busy_outlined, size: 35,
          color: scheme.primary.withValues(alpha: .75)),
        const SizedBox(height: 10),
        Text(tr('Sin citas para mostrar', 'No appointments to show'),
          style: TextStyle(fontWeight: FontWeight.w800,
              color: scheme.onSurface)),
        const SizedBox(height: 6),
        Text(esCalendario
              ? tr('No tienes citas asignadas para esta fecha.',
                  'No appointments assigned for this date.')
              : tr('No hay citas que coincidan con los filtros.',
                  'No appointments match these filters.'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.5,
              color: scheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _estadoError() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(children: [
        Icon(Icons.wifi_off_rounded, size: 30, color: scheme.primary),
        const SizedBox(height: 9),
        Text(_error == 'No se pudo consultar tu agenda. Verifica la conexión.'
            ? tr('No se pudo consultar tu agenda. Verifica la conexión.',
                'Could not load your schedule. Check the connection.')
            : _error == 'Esta agenda es exclusiva del personal especialista.'
                ? tr('Esta agenda es exclusiva del personal especialista.',
                    'This schedule is only available to specialists.')
                : _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextButton.icon(onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('Reintentar', 'Retry'))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vistaLista = _vista == _VistaEmpleado.lista;
    final citas = vistaLista ? _filtradas : _citasDeFecha;
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 34),
        children: [
          _encabezado(),
          const SizedBox(height: 23),
          Text(tr('Explora tu agenda', 'Explore your schedule'),
            style: TextStyle(fontSize: 15,
              fontWeight: FontWeight.w800, color: scheme.onSurface)),
          const SizedBox(height: 10),
          _selectorVista(),
          const SizedBox(height: 15),
          TextField(
            onChanged: (value) => setState(() => _busqueda = value),
            decoration: InputDecoration(
              hintText: tr('Buscar cliente o servicio', 'Search client or service'),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          if (vistaLista) ...[
            const SizedBox(height: 12),
            _selectorFiltros(),
          ] else if (!_cargando && _error == null) _panelCalendario(),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text(vistaLista
                ? tr('Citas asignadas', 'Assigned appointments')
                : tr('Citas de la fecha', 'Appointments for this date'),
              style: TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 15, color: scheme.onSurface))),
            if (!_cargando && _error == null)
              Text('${citas.length} ${tr('citas', 'appointments')}',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 11),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 38),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null) _estadoError()
          else if (citas.isEmpty) _estadoVacio(esCalendario: !vistaLista)
          else ...citas.map(_tarjeta),
          const SizedBox(height: 8),
          if (!_cargando && _error == null)
            Center(child: Text(tr('Solo consulta · Tus citas asignadas',
                    'View only · Your assigned appointments'),
              style: TextStyle(color: scheme.onSurfaceVariant,
                  fontSize: 10))),
        ],
      ),
    );
  }
}
