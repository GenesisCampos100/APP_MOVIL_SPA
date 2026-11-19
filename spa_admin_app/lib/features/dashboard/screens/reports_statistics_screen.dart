import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';

/// UI 21 — Reportes operativos avanzados derivados de GET /citas (JWT existente).
/// No consulta endpoints nuevos ni modifica citas. La API determina qué datos
/// son visibles para la sesión; los totales se refieren SOLO a esos datos.
class ReportsStatisticsScreen extends StatefulWidget {
  const ReportsStatisticsScreen({super.key});

  @override
  State<ReportsStatisticsScreen> createState() => _ReportsStatisticsScreenState();
}

enum _VistaReporte { general, personal, servicios }
enum _Agrupacion { dia, semana, mes }

/// UI 21: informes operativos sobre los registros que GET /citas permite leer.
/// No modifica datos ni presupone que la API entregue historicos completos.
class _ReportsStatisticsScreenState extends State<ReportsStatisticsScreen> {
  static const _rosa = AppColors.primaryPink;
  static const _violeta = Color(0xFF8F7AB0);
  static const _todos = '__todos__';

  final _repositorio = CitasRepository();
  List<AppointmentModel> _citas = const [];
  late DateTimeRange _periodo;
  _VistaReporte _vista = _VistaReporte.general;
  _Agrupacion _agrupacion = _Agrupacion.dia;
  String _empleado = _todos;
  String _servicio = _todos;
  String _estado = _todos;
  bool _cargando = true;
  String? _error;
  String? _puntoActivo;

  @override
  void initState() {
    super.initState();
    final hoy = _soloFecha(DateTime.now());
    _periodo = DateTimeRange(start: hoy.subtract(const Duration(days: 29)), end: hoy);
    _actualizar();
  }

  static DateTime _soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  static String _fechaCorta(DateTime f) => '${f.day} ${_meses[f.month - 1]} ${f.year}';
  static String _dia(DateTime f) => '${f.day} ${_meses[f.month - 1]}';

  static String _estadoNormalizado(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'confirmada':
      case 'confirmado': return 'Confirmadas';
      case 'pendiente': return 'Pendientes';
      case 'cancelada':
      case 'cancelado': return 'Canceladas';
      case 'completada':
      case 'completado': return 'Completadas';
      default: return 'Otros estados';
    }
  }

  static const _estados = [
    'Confirmadas', 'Pendientes', 'Completadas', 'Canceladas', 'Otros estados',
  ];
  static const _coloresEstado = <String, Color>{
    'Confirmadas': Color(0xFF7C9B6B),
    'Pendientes': Color(0xFFD39A41),
    'Completadas': Color(0xFF8F7AB0),
    'Canceladas': Color(0xFFD06C86),
    'Otros estados': Color(0xFFB6A9AD),
  };

  Future<void> _actualizar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final resultado = await _repositorio.obtenerCitas();
      if (!mounted) return;
      setState(() {
        _citas = resultado;
        if (!_opcionesEmpleados.contains(_empleado)) _empleado = _todos;
        if (!_opcionesServicios.contains(_servicio)) _servicio = _todos;
        _puntoActivo = null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  bool _esNombreValido(String valor) {
    final v = valor.trim().toLowerCase();
    return v.isNotEmpty && !v.startsWith('sin ') && v != '—';
  }

  List<String> _opcionesDe(String Function(AppointmentModel) leer) {
    final valores = _citas.map(leer).map((s) => s.trim())
        .where(_esNombreValido).toSet().toList()..sort();
    return [_todos, ...valores];
  }
  List<String> get _opcionesEmpleados => _opcionesDe((c) => c.nombreEmpleado);
  List<String> get _opcionesServicios => _opcionesDe((c) => c.nombreServicio);

  List<AppointmentModel> _filtrar(
    DateTime desde, DateTime hasta, {
    String? empleado, String? servicio, String? estado,
  }) {
    final inicio = _soloFecha(desde);
    final fin = _soloFecha(hasta);
    final e = empleado ?? _empleado;
    final s = servicio ?? _servicio;
    final t = estado ?? _estado;
    return _citas.where((c) {
      final f = _soloFecha(c.fecha);
      return !f.isBefore(inicio) && !f.isAfter(fin) &&
          (e == _todos || c.nombreEmpleado.trim() == e) &&
          (s == _todos || c.nombreServicio.trim() == s) &&
          (t == _todos || _estadoNormalizado(c.estado) == t);
    }).toList();
  }
  List<AppointmentModel> get _filtradas => _filtrar(_periodo.start, _periodo.end);

  Map<String, int> _conteoEstados(List<AppointmentModel> citas) {
    final resultado = {for (final e in _estados) e: 0};
    for (final c in citas) {
      final e = _estadoNormalizado(c.estado);
      resultado[e] = resultado[e]! + 1;
    }
    return resultado;
  }

  List<MapEntry<String, int>> _ranking(
    List<AppointmentModel> citas,
    String Function(AppointmentModel) nombre, {int limite = 5}
  ) {
    final valores = <String, int>{};
    for (final cita in citas) {
      final etiqueta = nombre(cita).trim();
      if (!_esNombreValido(etiqueta)) continue;
      valores.update(etiqueta, (n) => n + 1, ifAbsent: () => 1);
    }
    final lista = valores.entries.toList()..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return lista.take(limite).toList();
  }

  List<MapEntry<String, int>> _horariosPopulares(List<AppointmentModel> citas) {
    final franjas = <String, int>{};
    for (final cita in citas) {
      final partes = cita.horaInicio.trim().split(':');
      if (partes.length < 2) continue;
      final hora = int.tryParse(partes[0]);
      final minutos = int.tryParse(partes[1]);
      if (hora == null || hora < 0 || hora > 23 ||
          minutos == null || minutos < 0 || minutos > 59) continue;
      final clave = '${hora.toString().padLeft(2, '0')}:00';
      franjas.update(clave, (n) => n + 1, ifAbsent: () => 1);
    }
    final lista = franjas.entries.toList()..sort((a, b) {
      final c = b.value.compareTo(a.value);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
    return lista.take(5).toList();
  }

  /// Unicamente suma minutos explicitamente interpretables como minutos.
  int? _minutosAtendidos(List<AppointmentModel> citas) {
    var suma = 0;
    var validas = 0;
    for (final c in citas) {
      if (_estadoNormalizado(c.estado) != 'Completadas') continue;
      final texto = c.duracionAplicada.trim().toLowerCase();
      final m = RegExp(r'^(\d+)\s*(?:min|mins|minutos)\b').firstMatch(texto);
      final minutos = m == null ? null : int.tryParse(m.group(1)!);
      if (minutos == null || minutos <= 0 || minutos > 1440) continue;
      suma += minutos;
      validas++;
    }
    return validas == 0 ? null : suma;
  }

  /// Agrupa los datos por fecha civil local. La grafica limita columnas,
  /// pero los totales, filtros y reportes siguen usando todo el periodo.
  DateTime _clave(DateTime fecha, _Agrupacion g) {
    final f = DateTime.utc(fecha.year, fecha.month, fecha.day);
    switch (g) {
      case _Agrupacion.dia: return f;
      case _Agrupacion.semana: return f.subtract(Duration(days: f.weekday - 1));
      case _Agrupacion.mes: return DateTime.utc(f.year, f.month, 1);
    }
  }

  DateTime _avanzar(DateTime f, _Agrupacion g) {
    switch (g) {
      case _Agrupacion.dia: return f.add(const Duration(days: 1));
      case _Agrupacion.semana: return f.add(const Duration(days: 7));
      case _Agrupacion.mes: return DateTime.utc(f.year, f.month + 1, 1);
    }
  }

  String _etiquetaGrupo(DateTime f, _Agrupacion g) {
    return g == _Agrupacion.mes ? '${_meses[f.month - 1]} ${f.year}' : _dia(f);
  }

  List<_PuntoEstado> _serie(List<AppointmentModel> citas) {
    final agrupado = <DateTime, Map<String, int>>{};
    for (final c in citas) {
      final key = _clave(c.fecha, _agrupacion);
      final datos = agrupado.putIfAbsent(key, () => {for (final e in _estados) e: 0});
      final estado = _estadoNormalizado(c.estado);
      datos[estado] = datos[estado]! + 1;
    }
    final desde = _clave(_periodo.start, _agrupacion);
    final hasta = _clave(_periodo.end, _agrupacion);
    final fechas = <DateTime>[];
    var fecha = desde;
    // Limite de seguridad para periodos extensos.
    for (var n = 0; !fecha.isAfter(hasta) && n < 15000; n++) {
      fechas.add(fecha);
      fecha = _avanzar(fecha, _agrupacion);
    }
    final visibles = fechas.length > 22 ? fechas.sublist(fechas.length - 22) : fechas;
    return visibles.map((f) => _PuntoEstado(
      clave: f.toIso8601String(),
      etiqueta: _etiquetaGrupo(f, _agrupacion),
      estados: agrupado[f] ?? {for (final e in _estados) e: 0},
    )).toList();
  }

  int get _diasPeriodo => DateTime.utc(_periodo.end.year, _periodo.end.month, _periodo.end.day)
      .difference(DateTime.utc(_periodo.start.year, _periodo.start.month, _periodo.start.day)).inDays + 1;

  List<AppointmentModel> get _periodoPrevio {
    final fin = _soloFecha(_periodo.start).subtract(const Duration(days: 1));
    final inicio = fin.subtract(Duration(days: _diasPeriodo - 1));
    return _filtrar(inicio, fin);
  }

  Future<void> _abrirFiltros() async {
    var periodoElegido = _periodo;
    var empleadoElegido = _empleado;
    var servicioElegido = _servicio;
    var estadoElegido = _estado;
    final hoy = _soloFecha(DateTime.now());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AdminVisual.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (modalContext, cambiar) => SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: .78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Column(children: [
                Align(alignment: Alignment.centerLeft,
                    child: Text(AdminVisual.t('Filtros avanzados', 'Advanced filters'), style: AppTextStyles.heading1)),
                const SizedBox(height: 10),
                Expanded(child: ListView(children: [
                  Text(AdminVisual.t('Rango de fechas', 'Date range'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final elegido = await showDateRangePicker(
                        context: modalContext,
                        initialDateRange: periodoElegido,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(hoy.year + 2),
                        helpText: AdminVisual.t('Selecciona el periodo', 'Select a period'),
                        saveText: AdminVisual.t('Aplicar fechas', 'Apply dates'),
                        cancelText: AdminVisual.t('Cancelar', 'Cancel'),
                      );
                      if (elegido != null) cambiar(() => periodoElegido = elegido);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text('${_fechaCorta(periodoElegido.start)} – ${_fechaCorta(periodoElegido.end)}',
                        style: AppTextStyles.caption),
                  ),
                  Wrap(spacing: 7, runSpacing: 2, children: [
                    for (final dias in [1, 7, 30])
                      ActionChip(
                        label: Text(dias == 1 ? AdminVisual.t('Hoy', 'Today') : AdminVisual.t('$dias días', '$dias days'), style: AppTextStyles.caption),
                        backgroundColor: AdminVisual.primaryPinkSoft,
                        side: BorderSide.none,
                        onPressed: () => cambiar(() => periodoElegido = DateTimeRange(
                          start: hoy.subtract(Duration(days: dias - 1)), end: hoy,
                        )),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  _selector(
                    titulo: AdminVisual.t('Empleado / terapeuta', 'Employee / therapist'),
                    valor: empleadoElegido,
                    opciones: _opcionesEmpleados,
                    etiquetaTodos: AdminVisual.t('Todo el personal', 'All staff'),
                    onChanged: (v) => cambiar(() => empleadoElegido = v),
                  ),
                  const SizedBox(height: 12),
                  _selector(
                    titulo: AdminVisual.t('Servicio', 'Service'),
                    valor: servicioElegido,
                    opciones: _opcionesServicios,
                    etiquetaTodos: AdminVisual.t('Todos los servicios', 'All services'),
                    onChanged: (v) => cambiar(() => servicioElegido = v),
                  ),
                  const SizedBox(height: 12),
                  _selector(
                    titulo: AdminVisual.t('Estado de cita', 'Appointment status'),
                    valor: estadoElegido,
                    opciones: [_todos, ..._estados],
                    etiquetaTodos: AdminVisual.t('Todos los estados', 'All statuses'),
                    traducirEstados: true,
                    onChanged: (v) => cambiar(() => estadoElegido = v),
                  ),
                  const SizedBox(height: 10),
                  Text(AdminVisual.t('Los filtros se aplican juntos a todas las vistas.', 'Filters apply together across all views.'),
                      style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                ])),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => cambiar(() {
                      periodoElegido = DateTimeRange(
                        start: hoy.subtract(const Duration(days: 29)), end: hoy);
                      empleadoElegido = _todos;
                      servicioElegido = _todos;
                      estadoElegido = _todos;
                    }),
                    child: Text(AdminVisual.t('Restablecer', 'Reset'), style: AppTextStyles.body),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _periodo = periodoElegido;
                        _empleado = empleadoElegido;
                        _servicio = servicioElegido;
                        _estado = estadoElegido;
                        _puntoActivo = null;
                      });
                      Navigator.of(modalContext).pop();
                    },
                    style: FilledButton.styleFrom(backgroundColor: _rosa),
                    child: Text(AdminVisual.t('Aplicar', 'Apply'), style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
                  )),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selector({
    required String titulo, required String valor,
    required List<String> opciones, required String etiquetaTodos,
    required ValueChanged<String> onChanged,
    bool traducirEstados = false,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(titulo, style: AppTextStyles.subtitle),
    const SizedBox(height: 6),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AdminVisual.cardBackground, borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AdminVisual.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: opciones.contains(valor) ? valor : _todos,
          borderRadius: BorderRadius.circular(16),
          style: AppTextStyles.body.copyWith(color: AdminVisual.textDark),
          items: opciones.map((opcion) => DropdownMenuItem<String>(
            value: opcion,
            child: Text(opcion == _todos ? etiquetaTodos :
              (traducirEstados ? _estadoVisible(opcion) : opcion),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    ),
  ]);

  String _celdaCsv(String raw) {
    // Proteccion contra inyeccion de formulas en hojas de calculo.
    final texto = RegExp(r'^\s*[=+@\-]').hasMatch(raw) ? "'$raw" : raw;
    return '"${texto.replaceAll('"', '""')}"';
  }

  String _csv(List<AppointmentModel> citas) {
    final estados = _conteoEstados(citas);
    final servicios = _ranking(citas, (c) => c.nombreServicio, limite: 9999);
    final personal = _ranking(citas, (c) => c.nombreEmpleado, limite: 9999);
    final lineas = <String>[
      'Reporte operativo Aura SPA',
      'Desde,${_celdaCsv(_fechaCorta(_periodo.start))}',
      'Hasta,${_celdaCsv(_fechaCorta(_periodo.end))}',
      'Empleado,${_celdaCsv(_empleado == _todos ? 'Todos' : _empleado)}',
      'Servicio,${_celdaCsv(_servicio == _todos ? 'Todos' : _servicio)}',
      'Estado,${_celdaCsv(_estado == _todos ? 'Todos' : _estado)}',
      'Citas totales,${citas.length}',
      ...estados.entries.map((e) => '${_celdaCsv(e.key)},${e.value}'),
      '',
      'Servicio,Citas',
      ...servicios.map((e) => '${_celdaCsv(e.key)},${e.value}'),
      '',
      'Empleado,Citas',
      ...personal.map((e) => '${_celdaCsv(e.key)},${e.value}'),
      '',
      'Fecha,Estado,Empleado,Servicio,Citas',
      ...citas.map((c) => [
        _celdaCsv(_fechaCorta(c.fecha)),
        _celdaCsv(_estadoNormalizado(c.estado)),
        _celdaCsv(c.nombreEmpleado), _celdaCsv(c.nombreServicio), '1',
      ].join(',')),
    ];
    return lineas.join('\r\n');
  }

  Future<void> _copiarCsv(List<AppointmentModel> citas) async {
    await Clipboard.setData(ClipboardData(text: _csv(citas)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AdminVisual.t('Reporte filtrado copiado como CSV. Pégalo en Excel.', 'Filtered CSV copied. Paste it into Excel.')),
    ));
  }

  Widget _vistas() {
    final nombres = <_VistaReporte, String>{
      _VistaReporte.general: AdminVisual.t('General', 'Overview'),
      _VistaReporte.personal: AdminVisual.t('Personal', 'Staff'),
      _VistaReporte.servicios: AdminVisual.t('Servicios', 'Services'),
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AdminVisual.primaryPinkSoft,
        borderRadius: BorderRadius.circular(17)),
      child: Row(children: [
        for (final v in _VistaReporte.values)
          Expanded(child: InkWell(
            key: ValueKey('vista_${v.name}'),
            borderRadius: BorderRadius.circular(13),
            onTap: () => setState(() { _vista = v; _puntoActivo = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
              decoration: BoxDecoration(
                color: _vista == v ? AdminVisual.cardBackground : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                boxShadow: _vista == v ? [BoxShadow(
                  color: _rosa.withValues(alpha: .09),
                  blurRadius: 10, offset: const Offset(0, 2))] : null,
              ),
              child: Center(child: Text(nombres[v]!, maxLines: 1,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: _vista == v ? FontWeight.w700 : FontWeight.w500,
                  color: _vista == v ? _rosa : AdminVisual.textDark,
                ))),
            ),
          )),
      ]),
    );
  }

  Widget _agrupador() => Row(children: [
    Expanded(child: Text(AdminVisual.t('Agrupar por', 'Group by'), style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600))),
    for (final g in _Agrupacion.values)
      Padding(padding: const EdgeInsets.only(left: 4), child: ChoiceChip(
        label: Text(g == _Agrupacion.dia ? AdminVisual.t('Día', 'Day') : g == _Agrupacion.semana ? AdminVisual.t('Semana', 'Week') : AdminVisual.t('Mes', 'Month'),
          style: AppTextStyles.caption.copyWith(fontSize: 10)),
        selected: _agrupacion == g,
        selectedColor: AdminVisual.primaryPinkSoft,
        side: BorderSide(color: _agrupacion == g ? _rosa : AdminVisual.cardBorder),
        showCheckmark: false,
        onSelected: (_) => setState(() {
          _agrupacion = g; _puntoActivo = null;
        }),
      )),
  ]);

  Widget _graficaConDetalle(List<AppointmentModel> citas, String titulo) {
    final puntos = _serie(citas);
    _PuntoEstado? activo;
    for (final p in puntos) {
      if (p.clave == _puntoActivo) { activo = p; break; }
    }
    return Column(children: [
      _TarjetaReporte(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTextStyles.heading2),
          const SizedBox(height: 3),
          Text(AdminVisual.t('Citas agrupadas por estado · Toca una columna para ver el detalle', 'Appointments by status · Tap a column to see details'),
            style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
          const SizedBox(height: 12),
          _agrupador(),
          const SizedBox(height: 14),
          _GraficaEstados(
            puntos: puntos,
            colores: _coloresEstado,
            onSelect: (p) => setState(() => _puntoActivo = p.clave),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 6, children: [
            for (final e in _estados)
              Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(radius: 4, backgroundColor: _coloresEstado[e]),
                const SizedBox(width: 5),
                Text(_estadoVisible(e), style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ]),
          ]),
          if (_periodoSeTrunca) ...[
            const SizedBox(height: 9),
            Text(AdminVisual.t('Se muestran solo los últimos 22 intervalos; los totales y el CSV incluyen todo el periodo.', 'Only the last 22 intervals are shown; totals and CSV cover the entire period.'),
              style: AppTextStyles.caption.copyWith(fontSize: 10, color: AdminVisual.textMuted)),
          ],
        ],
      )),
      if (activo != null) ...[
        const SizedBox(height: 9),
        _TarjetaReporte(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AdminVisual.t('Detalle', 'Detail') + ' · ${activo.etiqueta}', style: AppTextStyles.subtitle),
            const SizedBox(height: 7),
            for (final e in _estados)
              if ((activo.estados[e] ?? 0) > 0)
                Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(
                  children: [
                    Expanded(child: Text(_estadoVisible(e), style: AppTextStyles.caption)),
                    Text('${activo.estados[e]}', style: AppTextStyles.subtitle),
                  ],
                )),
          ],
        )),
      ],
    ]);
  }

  bool get _periodoSeTrunca {
    final inicio = _clave(_periodo.start, _agrupacion);
    final fin = _clave(_periodo.end, _agrupacion);
    var n = 0;
    var f = inicio;
    while (!f.isAfter(fin) && n <= 22) { n++; f = _avanzar(f, _agrupacion); }
    return n > 22;
  }

  Widget _resumenComparativo(List<AppointmentModel> citas) {
    final anterior = _periodoPrevio.length;
    final actual = citas.length;
    final diferencia = actual - anterior;
    final variacion = anterior == 0 ? null : 100 * diferencia / anterior;
    return _TarjetaReporte(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AdminVisual.t('Comparación con el periodo anterior', 'Comparison with previous period'), style: AppTextStyles.heading2),
        const SizedBox(height: 6),
        Text(AdminVisual.t('Mismos filtros, fechas inmediatamente anteriores', 'Same filters, immediately preceding dates'),
          style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _DatoComparativo(etiqueta: AdminVisual.t('Actual', 'Current'), valor: '$actual')),
          Expanded(child: _DatoComparativo(etiqueta: AdminVisual.t('Anterior', 'Previous'), valor: '$anterior')),
          Expanded(child: _DatoComparativo(
            etiqueta: AdminVisual.t('Variación', 'Change'),
            valor: variacion == null ? '—' : '${diferencia > 0 ? '+' : ''}${variacion.toStringAsFixed(1)}%',
          )),
        ]),
        const SizedBox(height: 8),
        Text(anterior == 0
          ? AdminVisual.t('No se calcula un porcentaje cuando el periodo anterior tiene 0 citas.', 'No percentage is calculated when the previous period has zero appointments.')
          : AdminVisual.t('Una variación positiva significa más citas registradas, no necesariamente mayor rendimiento.', 'A positive change means more recorded appointments, not necessarily better performance.'),
          style: AppTextStyles.caption.copyWith(fontSize: 10, color: AdminVisual.textMuted)),
      ],
    ));
  }

  Widget _vistasContenido(List<AppointmentModel> citas, Map<String, int> estados) {
    switch (_vista) {
      case _VistaReporte.general:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Distribucion(estados: estados),
          const SizedBox(height: 14),
          _graficaConDetalle(citas, AdminVisual.t('Evolución de citas', 'Appointment trends')),
          const SizedBox(height: 14),
          _resumenComparativo(citas),
          const SizedBox(height: 14),
          _Ranking(titulo: AdminVisual.t('Horarios de mayor demanda', 'Most requested time slots'),
            icono: Icons.schedule_rounded,
            datos: _horariosPopulares(citas), color: _rosa,
            vacio: AdminVisual.t('No hay horas de inicio válidas en estas citas.', 'No valid start times for these appointments.')),
        ]);
      case _VistaReporte.personal:
        final duracion = _minutosAtendidos(citas);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _selector(
            titulo: AdminVisual.t('Empleado / terapeuta', 'Employee / therapist'), valor: _empleado,
            opciones: _opcionesEmpleados, etiquetaTodos: AdminVisual.t('Todo el personal', 'All staff'),
            onChanged: (v) => setState(() { _empleado = v; _puntoActivo = null; }),
          ),
          const SizedBox(height: 12),
          _TarjetaReporte(child: Row(children: [
            Expanded(child: _DatoComparativo(etiqueta: AdminVisual.t('Citas del filtro', 'Filtered appointments'), valor: '${citas.length}')),
            Expanded(child: _DatoComparativo(etiqueta: AdminVisual.t('Completadas', 'Completed'), valor: '${estados['Completadas']}')),
            Expanded(child: _DatoComparativo(
              etiqueta: AdminVisual.t('Horas atendidas*', 'Service hours*'),
              valor: duracion == null ? '—' : '${(duracion / 60).toStringAsFixed(1)} h',
            )),
          ])),
          const SizedBox(height: 6),
          Text(AdminVisual.t('*Suma de duraciones válidas de citas completadas; no equivale a jornada laboral.', '*Sum of valid completed appointment durations; not working hours.'),
            style: AppTextStyles.caption.copyWith(fontSize: 10, color: AdminVisual.textMuted)),
          const SizedBox(height: 14),
          _graficaConDetalle(citas, AdminVisual.t('Citas por día y estado', 'Appointments by day and status')),
          const SizedBox(height: 14),
          if (_empleado == _todos)
            _Ranking(titulo: AdminVisual.t('Actividad por empleado', 'Activity by employee'),
              icono: Icons.people_outline_rounded,
              datos: _ranking(citas, (c) => c.nombreEmpleado), color: _violeta,
              vacio: AdminVisual.t('No hay empleados identificados en estas citas.', 'No identified employees in these appointments.'))
          else
            _Ranking(titulo: AdminVisual.t('Servicios asignados', 'Assigned services'),
              icono: Icons.spa_outlined,
              datos: _ranking(citas, (c) => c.nombreServicio), color: _violeta,
              vacio: AdminVisual.t('No se identificaron servicios en estas citas.', 'No services identified in these appointments.')),
        ]);
      case _VistaReporte.servicios:
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _selector(
            titulo: AdminVisual.t('Servicio', 'Service'), valor: _servicio,
            opciones: _opcionesServicios, etiquetaTodos: AdminVisual.t('Todos los servicios', 'All services'),
            onChanged: (v) => setState(() { _servicio = v; _puntoActivo = null; }),
          ),
          const SizedBox(height: 12),
          _Ranking(titulo: AdminVisual.t('Servicios más solicitados', 'Most requested services'),
            icono: Icons.spa_outlined,
            datos: _ranking(citas, (c) => c.nombreServicio), color: _rosa,
            vacio: AdminVisual.t('No hay servicios identificados en este periodo.', 'No services identified in this period.')),
          const SizedBox(height: 14),
          _graficaConDetalle(citas, AdminVisual.t('Demanda del servicio por estado', 'Service demand by status')),
          const SizedBox(height: 14),
          _TarjetaReporte(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AdminVisual.t('Cancelaciones del servicio', 'Service cancellations'), style: AppTextStyles.heading2),
              const SizedBox(height: 7),
              Text(citas.isEmpty
                ? AdminVisual.t('Sin registros para calcular el porcentaje.', 'No records to calculate a percentage.')
                : AdminVisual.t('${(100 * (estados['Canceladas'] ?? 0) / citas.length).toStringAsFixed(1)}% de las citas del filtro están canceladas.', '${(100 * (estados['Canceladas'] ?? 0) / citas.length).toStringAsFixed(1)}% of filtered appointments are cancelled.'),
                style: AppTextStyles.body),
              const SizedBox(height: 5),
              Text(AdminVisual.t('Es el estado actual de las citas registradas; no identifica el motivo ni la fecha de cancelación.', 'Based on the current appointment status; cancellation reason or date is not available.'),
                style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
            ],
          )),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final citas = _filtradas;
    final estados = _conteoEstados(citas);
    return Scaffold(
      backgroundColor: AdminVisual.background,
      body: SafeArea(child: RefreshIndicator(
        color: _rosa,
        onRefresh: _actualizar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const _EncabezadoReportes(),
            Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: InkWell(
                    onTap: _abrirFiltros,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(color: AdminVisual.cardBackground,
                        border: Border.all(color: AdminVisual.cardBorder),
                        borderRadius: BorderRadius.circular(15)),
                      child: Row(children: [
                        const Icon(Icons.date_range_outlined, color: _rosa, size: 19),
                        const SizedBox(width: 7),
                        Expanded(child: Text('${_dia(_periodo.start)} – ${_fechaCorta(_periodo.end)}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600, color: AdminVisual.textDark))),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: _rosa),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: AdminVisual.t('Filtros de empleado, servicio y estado', 'Staff, service and status filters'),
                    onPressed: _abrirFiltros,
                    style: IconButton.styleFrom(backgroundColor: AdminVisual.primaryPinkSoft,
                      foregroundColor: _rosa, fixedSize: const Size(48, 48)),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ]),
                if (_cargando) ...[
                  const SizedBox(height: 60),
                  const Center(child: CircularProgressIndicator(color: _rosa)),
                ] else if (_error != null) ...[
                  const SizedBox(height: 20),
                  _TarjetaReporte(child: Column(children: [
                    const Icon(Icons.cloud_off_outlined, color: _rosa, size: 34),
                    const SizedBox(height: 8),
                    Text(AdminVisual.t('No se pudieron consultar las citas', 'Unable to load appointments'), style: AppTextStyles.heading2),
                    const SizedBox(height: 5),
                    Text(_error!, textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                    TextButton.icon(onPressed: _actualizar,
                      icon: const Icon(Icons.refresh_rounded), label: Text(AdminVisual.t('Reintentar', 'Retry'))),
                  ])),
                ] else ...[
                  const SizedBox(height: 15),
                  _vistas(),
                  const SizedBox(height: 18),
                  Text(AdminVisual.t('Resumen del periodo', 'Period summary'), style: AppTextStyles.heading1.copyWith(
                    fontSize: 19, color: AdminVisual.textDark)),
                  const SizedBox(height: 12),
                  _HeroTotal(total: citas.length),
                  const SizedBox(height: 12),
                  _EstadoCompacto(estados: estados),
                  const SizedBox(height: 12),
                  if (_empleado != _todos || _servicio != _todos || _estado != _todos)
                    Padding(padding: const EdgeInsets.only(bottom: 12),
                      child: Text('${AdminVisual.t('Filtros activos', 'Active filters')}: ${_empleado == _todos ? AdminVisual.t('Todo el personal', 'All staff') : _empleado} · '
                        '${_servicio == _todos ? AdminVisual.t('Todos los servicios', 'All services') : _servicio} · '
                        '${_estado == _todos ? AdminVisual.t('Todos los estados', 'All statuses') : _estado}',
                        style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted))),
                  if (citas.isEmpty)
                    _TarjetaReporte(child: Column(children: [
                      const Icon(Icons.event_busy_outlined, color: _rosa, size: 30),
                      const SizedBox(height: 8),
                      Text(AdminVisual.t('Sin citas con estos filtros', 'No appointments match these filters'), style: AppTextStyles.heading2),
                      const SizedBox(height: 5),
                      Text(AdminVisual.t('Prueba otro periodo, empleado, servicio o estado.', 'Try a different period, employee, service or status.'),
                        textAlign: TextAlign.center, style: AppTextStyles.caption),
                    ]))
                  else
                    _vistasContenido(citas, estados),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => _copiarCsv(citas),
                    icon: const Icon(Icons.content_copy_rounded),
                    label: Text(AdminVisual.t('Copiar reporte filtrado (CSV)', 'Copy filtered report (CSV)'),
                      style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
                    style: FilledButton.styleFrom(backgroundColor: _rosa,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                  ),
                  const SizedBox(height: 10),
                  Text(AdminVisual.t('Los resultados incluyen solo las citas entregadas por la API a tu sesión. No representan ingresos ni garantizan un historial completo.', 'Results include only appointments returned by the API to your session. They do not represent revenue or guarantee a complete history.'),
                    textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5, color: AdminVisual.textMuted)),
                ],
              ]),
            ),
          ]),
        ),
      )),
    );
  }
}

class _PuntoEstado {
  final String clave;
  final String etiqueta;
  final Map<String, int> estados;
  const _PuntoEstado({required this.clave, required this.etiqueta, required this.estados});
  int get total => estados.values.fold(0, (s, n) => s + n);
}

class _DatoComparativo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _DatoComparativo({required this.etiqueta, required this.valor});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted, fontSize: 10)),
      const SizedBox(height: 5),
      Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: AppTextStyles.heading1.copyWith(fontSize: 18, color: AdminVisual.textDark)),
    ],
  );
}

/// Columnas apiladas con estados de cita; no utiliza dependencias de graficas.
class _GraficaEstados extends StatelessWidget {
  final List<_PuntoEstado> puntos;
  final Map<String, Color> colores;
  final ValueChanged<_PuntoEstado> onSelect;
  const _GraficaEstados({required this.puntos, required this.colores, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final maximo = math.max(1, puntos.fold<int>(0, (n, p) => math.max(n, p.total)));
    return SizedBox(
      height: 173,
      child: puntos.isEmpty
          ? Center(child: Text(AdminVisual.t('Sin datos para graficar', 'No data to chart'), style: AppTextStyles.caption))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final punto in puntos)
                  InkWell(
                    onTap: () => onSelect(punto),
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(width: 48, height: 173,
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Text('${punto.total}', style: AppTextStyles.caption.copyWith(
                            color: AdminVisual.textDark, fontSize: 9.5)),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 117,
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            for (final estado in punto.estados.keys.toList().reversed)
                              if ((punto.estados[estado] ?? 0) > 0)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: (punto.estados[estado]! / maximo * 111)),
                                  duration: const Duration(milliseconds: 430),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, alto, _) => Container(
                                    width: 29,
                                    height: alto,
                                    margin: const EdgeInsets.only(top: 1),
                                    decoration: BoxDecoration(
                                      color: colores[estado] ?? AdminVisual.primaryPink,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                          ]),
                        ),
                        const SizedBox(height: 7),
                        Text(punto.etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 9)),
                      ]),
                    ),
                  ),
              ]),
            ),
    );
  }
}

class _EncabezadoReportes extends StatelessWidget {
  const _EncabezadoReportes();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvaReportes(),
      child: Container(
        width: double.infinity,
        height: 221,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AdminVisual.dark
                ? const [Color(0xFF342634), Color(0xFF594055)]
                : const [Color(0xFFFFF9FB), Color(0xFFF7DCE7)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 3, bottom: 23, width: 151, height: 161,
              child: CustomPaint(painter: _DibujoReportes()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 9, 155, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: AdminVisual.t('Regresar a Más opciones', 'Back to More options'),
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AdminVisual.primaryPink, size: 20),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text('A U R A  S P A',
                            maxLines: 1,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AdminVisual.primaryPink,
                              fontSize: 10.5,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(AdminVisual.t('Reportes y\nestadísticas', 'Reports and\nstatistics'),
                      maxLines: 2,
                      style: AppTextStyles.heading1.copyWith(
                        height: 1.12,
                        fontSize: 25,
                        color: AdminVisual.dark ? const Color(0xFFFFE5EF) : const Color(0xFF612B41),
                      )),
                  const SizedBox(height: 9),
                  Text(AdminVisual.t('Actividad, citas y servicios\nde tu negocio.', 'Business activity, appointments\nand services.'),
                      style: AppTextStyles.caption.copyWith(
                        color: AdminVisual.textMuted,
                        height: 1.35,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvaReportes extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..lineTo(0, s.height - 29)
    ..cubicTo(s.width * .25, s.height - 4,
        s.width * .42, s.height - 58,
        s.width * .64, s.height - 35)
    ..cubicTo(s.width * .82, s.height - 16,
        s.width * .90, s.height - 4,
        s.width, s.height - 38)
    ..lineTo(s.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant _CurvaReportes oldClipper) => false;
}

class _DibujoReportes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 150, size.height / 160);
    final fondo = Paint()..color = const Color(0xFFF3CAD8).withValues(alpha: .50);
    canvas.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(19, 30, 113, 108), const Radius.circular(18)), fondo);
    final papel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 24, 92, 114), const Radius.circular(13));
    canvas.drawRRect(papel, Paint()..color = const Color(0xFFFFFCFC));
    canvas.drawRRect(papel, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD68DA9));
    final sujetador = RRect.fromRectAndRadius(
      const Rect.fromLTWH(54, 13, 40, 19), const Radius.circular(6));
    canvas.drawRRect(sujetador, Paint()..color = const Color(0xFFCB7996));
    final barras = [22.0, 41.0, 32.0, 59.0];
    for (var i = 0; i < barras.length; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(40 + i * 18, 117 - barras[i], 11, barras[i]),
        const Radius.circular(4)), Paint()..color = i.isEven
            ? const Color(0xFFCE789A) : const Color(0xFFE8B4C5));
    }
    // Lupa: conecta el símbolo de reportes con la identidad visual.
    canvas.drawCircle(const Offset(117, 121), 19, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFFA9476C));
    canvas.drawLine(const Offset(130, 135), const Offset(145, 151), Paint()
      ..color = const Color(0xFFA9476C)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DibujoReportes oldDelegate) => false;
}

class _TarjetaReporte extends StatelessWidget {
  final Widget child;
  const _TarjetaReporte({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminVisual.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AdminVisual.cardBorder.withValues(alpha: .80)),
          boxShadow: [BoxShadow(
            color: AdminVisual.primaryPink.withValues(alpha: .055),
            blurRadius: 16,
            offset: const Offset(0, 5),
          )],
        ),
        child: child,
      );
}

class _HeroTotal extends StatelessWidget {
  final int total;
  const _HeroTotal({required this.total});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          gradient: const LinearGradient(
            colors: [Color(0xFFB96E8A), Color(0xFFA9476C)],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.event_available_outlined,
                  color: Colors.white, size: 33),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total', style: AppTextStyles.displayExtraBold.copyWith(
                      fontSize: 34, color: Colors.white)),
                  Text(AdminVisual.t('Citas totales', 'Total appointments'), style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(AdminVisual.t('En el periodo seleccionado', 'In the selected period'),
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 10.5, color: Colors.white.withValues(alpha: .83))),
                ],
              ),
            ),
            Icon(Icons.spa_outlined, size: 45,
                color: Colors.white.withValues(alpha: .34)),
          ],
        ),
      );
}

class _EstadoCompacto extends StatelessWidget {
  final Map<String, int> estados;
  const _EstadoCompacto({required this.estados});

  @override
  Widget build(BuildContext context) {
    const etiquetas = ['Confirmadas', 'Pendientes', 'Completadas', 'Canceladas'];
    const colores = [
      Color(0xFF7C9B6B), Color(0xFFD39A41),
      Color(0xFF8F7AB0), Color(0xFFD06C86),
    ];
    return _TarjetaReporte(
      child: Column(
        children: [
          for (var i = 0; i < etiquetas.length; i++) ...[
            if (i != 0) Divider(height: 15, color: AdminVisual.cardBorder),
            Row(
              children: [
                Container(
                  width: 7, height: 22,
                  decoration: BoxDecoration(
                    color: colores[i], borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_estadoVisible(etiquetas[i]), style: AppTextStyles.body)),
                Text('${estados[etiquetas[i]]}',
                    style: AppTextStyles.heading2.copyWith(
                        color: AdminVisual.textDark)),
              ],
            ),
          ],
          if ((estados['Otros estados'] ?? 0) > 0) ...[
            Divider(height: 15, color: AdminVisual.cardBorder),
            Row(children: [
              Icon(Icons.info_outline, size: 18, color: AdminVisual.textMuted),
              const SizedBox(width: 8),
              Expanded(child: Text(AdminVisual.t('Otros estados', 'Other statuses'), style: AppTextStyles.body)),
              Text('${estados['Otros estados']}', style: AppTextStyles.heading2),
            ]),
          ],
        ],
      ),
    );
  }
}

class _Distribucion extends StatelessWidget {
  final Map<String, int> estados;
  const _Distribucion({required this.estados});

  static const _colores = <Color>[
    Color(0xFF7C9B6B), Color(0xFFD39A41),
    Color(0xFF8F7AB0), Color(0xFFD06C86), Color(0xFFB6A9AD),
  ];

  @override
  Widget build(BuildContext context) {
    final valores = estados.values.toList();
    final total = valores.fold<int>(0, (a, b) => a + b);
    return _TarjetaReporte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AdminVisual.t('Distribución de citas', 'Appointment distribution'), style: AppTextStyles.heading2),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, fraccion, _) => CustomPaint(
                    painter: _AnilloPainter(valores, _colores, fraccion),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$total', style: AppTextStyles.heading1.copyWith(fontSize: 25)),
                          Text(AdminVisual.t('citas', 'appointments'), style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < estados.length; i++)
                      if (valores[i] > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 4, backgroundColor: _colores[i]),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(_estadoVisible(estados.keys.elementAt(i)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
                              ),
                              const SizedBox(width: 5),
                              Text('${(valores[i] * 100 / total).toStringAsFixed(1)}%',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  final List<int> valores;
  final List<Color> colores;
  final double animacion;
  _AnilloPainter(this.valores, this.colores, this.animacion);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final total = valores.fold<int>(0, (a, b) => a + b);
    canvas.drawCircle(centro, radio, Paint()
      ..color = AdminVisual.primaryPinkSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16);
    if (total == 0) return;
    var angulo = -math.pi / 2;
    for (var i = 0; i < valores.length; i++) {
      if (valores[i] == 0) continue;
      final amplitud = 2 * math.pi * valores[i] / total * animacion;
      canvas.drawArc(rect, angulo, amplitud, false, Paint()
        ..color = colores[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16);
      angulo += 2 * math.pi * valores[i] / total;
    }
  }

  @override
  bool shouldRepaint(covariant _AnilloPainter old) =>
      old.animacion != animacion || old.valores != valores;
}

class _Ranking extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<MapEntry<String, int>> datos;
  final Color color;
  final String vacio;
  const _Ranking({
    required this.titulo,
    required this.icono,
    required this.datos,
    required this.color,
    required this.vacio,
  });

  @override
  Widget build(BuildContext context) {
    final maximo = datos.isEmpty ? 1 : math.max(1, datos.first.value);
    return _TarjetaReporte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, color: AdminVisual.primaryPink, size: 21),
            const SizedBox(width: 9),
            Expanded(child: Text(titulo, style: AppTextStyles.heading2)),
          ]),
          const SizedBox(height: 13),
          if (datos.isEmpty)
            Text(vacio, style: AppTextStyles.caption.copyWith(
                color: AdminVisual.textMuted))
          else
            for (final entrada in datos) ...[
              Row(children: [
                Expanded(child: Text(entrada.key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: 12))),
                const SizedBox(width: 8),
                Text(AdminVisual.t('${entrada.value} citas', '${entrada.value} appointments'),
                    style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600, color: AdminVisual.textDark)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: entrada.value / maximo),
                  duration: const Duration(milliseconds: 580),
                  builder: (context, progreso, _) => LinearProgressIndicator(
                    value: progreso,
                    minHeight: 8,
                    backgroundColor: AdminVisual.primaryPinkSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

// Labels for display only. Never use these values for filters, maps or CSV.
String _estadoVisible(String estado) {
  switch (estado) {
    case 'Confirmadas': return AdminVisual.t('Confirmadas', 'Confirmed');
    case 'Pendientes': return AdminVisual.t('Pendientes', 'Pending');
    case 'Completadas': return AdminVisual.t('Completadas', 'Completed');
    case 'Canceladas': return AdminVisual.t('Canceladas', 'Cancelled');
    case 'Otros estados': return AdminVisual.t('Otros estados', 'Other statuses');
    default: return estado;
  }
}
