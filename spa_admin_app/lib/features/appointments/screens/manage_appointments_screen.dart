import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/appointments/screens/detalle_cita_screen.dart';
import 'package:spa_admin_app/features/shell/screens/main_navigation_screen.dart';

/// Modos visuales del calendario. No alteran el estado de las citas.
enum _VistaAgenda { mes, semana, dia }

/// Agenda del Administrador. Este archivo solo modifica la presentacion:
/// consultas, estados y acciones permanecen en el repositorio y el detalle.
class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() =>
      _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  String t(String es, String en) => StaffPreferences.tr(es, en);
  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  final CitasRepository _repository = CitasRepository();
  List<AppointmentModel> _appointments = [];
  bool _cargando = true;
  String? _error;
  bool _primeraCarga = true;

  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _searchQuery = '';
  String _selectedFilter = 'Todas';
  _VistaAgenda _vistaActual = _VistaAgenda.mes;
  static const _mesesCortos = <String>[
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];
  static const _mesesCortosEn = <String>[
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  static const _dias = <String>['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    if (!AuthSession.esAdministrador || !AuthSession.activa) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Inicia sesión como Administrador para consultar las citas.';
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final citas = await _repository.obtenerCitas();
      if (!mounted) return;
      setState(() {
        _appointments = citas;
        _cargando = false;
        if (_primeraCarga && citas.isNotEmpty) {
          final ahora = DateTime.now();
          final hoy = DateTime(ahora.year, ahora.month, ahora.day);
          final futuras = citas.where((c) => !c.fecha.isBefore(hoy)).toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));
          final fechaFoco = futuras.isNotEmpty ? futuras.first.fecha : citas.last.fecha;
          _selectedDate = fechaFoco;
          _currentMonth = DateTime(fechaFoco.year, fechaFoco.month);
        }
        _primeraCarga = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = switch (e.statusCode) {
          401 => 'La sesión ya no es válida. Cierra sesión y vuelve a ingresar.',
          403 => 'No tienes permiso para consultar las citas.',
          _ => 'No se pudieron cargar las citas. Intenta nuevamente.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudieron consultar las citas. Comprueba tu conexión e intenta nuevamente.';
      });
    }
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fechaLegible(DateTime fecha) => MaterialLocalizations.of(context).formatMediumDate(fecha);

  String _mesCorto(int mes) =>
      (StaffPreferences.language.value == 'en' ? _mesesCortosEn : _mesesCortos)[mes - 1];

  DateTime _inicioSemana(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day - fecha.weekday + 1);

  void _irAHoy() {
    final hoy = DateTime.now();
    setState(() {
      _selectedDate = DateTime(hoy.year, hoy.month, hoy.day);
      _currentMonth = DateTime(hoy.year, hoy.month);
    });
  }

  void _moverMes(int meses) {
    final nuevoMes = DateTime(_currentMonth.year, _currentMonth.month + meses);
    final ultimoDia = DateUtils.getDaysInMonth(nuevoMes.year, nuevoMes.month);
    final dia = _selectedDate.day > ultimoDia ? ultimoDia : _selectedDate.day;
    setState(() {
      _currentMonth = nuevoMes;
      _selectedDate = DateTime(nuevoMes.year, nuevoMes.month, dia);
    });
  }

  void _moverDia(int dias) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day + dias,
      );
      _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  void _moverSemana(int semanas) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day + semanas * 7,
      );
      _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  String _horaCorta(String hora) => hora.length >= 5 ? hora.substring(0, 5) : hora;

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Confirmada':
        return _dark ? const Color(0xFF77D4A8) : const Color(0xFF237A51);
      case 'Pendiente':
        return _dark ? const Color(0xFFF0C677) : const Color(0xFFAC780D);
      case 'Cancelada':
        return _dark ? const Color(0xFFF4A3AE) : const Color(0xFFB83E4F);
      case 'Completada':
        return _dark ? const Color(0xFFC9AFF1) : const Color(0xFF7954A7);
      case 'Inasistencia':
        return _dark ? const Color(0xFFE9AEB9) : const Color(0xFFAD5965);
      default:
        return AppColors.textMuted;
    }
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'Confirmada':
        return Icons.check_circle_rounded;
      case 'Cancelada':
        return Icons.cancel_rounded;
      case 'Completada':
        return Icons.task_alt_rounded;
      case 'Inasistencia':
        return Icons.person_off_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  List<AppointmentModel> get _citasDelDia =>
      _appointments.where((c) => _mismoDia(c.fecha, _selectedDate)).toList();

  List<AppointmentModel> get _filtradas {
    final busqueda = _searchQuery.trim().toLowerCase();
    final citas = _citasDelDia.where((c) {
      final busca = busqueda.isEmpty ||
          c.nombreCliente.toLowerCase().contains(busqueda) ||
          c.nombreServicio.toLowerCase().contains(busqueda) ||
          c.nombreEmpleado.toLowerCase().contains(busqueda) ||
          c.idCita.toLowerCase().contains(busqueda);
      final estadoBuscado = switch (_selectedFilter) {
        'Pendientes' => 'Pendiente',
        'Confirmadas' => 'Confirmada',
        'Completadas' => 'Completada',
        'Canceladas' => 'Cancelada',
        _ => null,
      };
      final coincideEstado = estadoBuscado == null || c.estado == estadoBuscado;
      return busca && coincideEstado;
    }).toList();
    citas.sort((a, b) => a.horaInicio.compareTo(b.horaInicio));
    return citas;
  }

  void _seleccionarDia(DateTime dia) {
    setState(() {
      _selectedDate = dia;
      _currentMonth = DateTime(dia.year, dia.month);
      _vistaActual = _VistaAgenda.dia;
    });
  }

  void _abrirDetalle(AppointmentModel cita) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetalleCitaScreen(
          appointment: cita,
          onAppointmentUpdated: (_) => _cargarCitas(),
        ),
      ),
    );
  }

  BoxDecoration _tarjetaDecoracion({Color? borde}) => BoxDecoration(
        color: _dark ? _scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borde ?? (_dark ? _scheme.outlineVariant : const Color(0xFFF0E2E7))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF715766).withValues(alpha: 0.055),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      );

  Widget _resumen(String nombre, int cantidad, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _dark ? _scheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text('$nombre $cantidad',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      );

  Widget _resumenDia() {
    final citas = _citasDelDia;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _resumen(t('Pendientes', 'Pending'), citas.where((c) => c.estado == 'Pendiente').length,
            _colorEstado('Pendiente')),
        const SizedBox(width: 8),
        _resumen(t('Confirmadas', 'Confirmed'), citas.where((c) => c.estado == 'Confirmada').length,
            _colorEstado('Confirmada')),
        const SizedBox(width: 8),
        _resumen(t('Completadas', 'Completed'), citas.where((c) => c.estado == 'Completada').length,
            _colorEstado('Completada')),
        const SizedBox(width: 8),
        _resumen(t('Canceladas', 'Cancelled'), citas.where((c) => c.estado == 'Cancelada').length,
            _colorEstado('Cancelada')),
        const SizedBox(width: 8),
      ]),
    );
  }

  Widget _encabezadoDia({bool mostrarCambio = true}) => Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('Citas del día', 'Appointments for the day'), style: TextStyle(
                color: _scheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 3),
              Text(_fechaLegible(_selectedDate),
                style: TextStyle(color: _scheme.onSurface,
                    fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          )),
          if (mostrarCambio)
            TextButton.icon(
              onPressed: () => setState(() => _vistaActual = _VistaAgenda.mes),
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(t('Ver mes', 'View month')),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryPink),
            ),
        ],
      );

  String _traducirEstado(String estado) => switch (estado) {
    'Pendiente' => t('Pendiente', 'Pending'),
    'Confirmada' => t('Confirmada', 'Confirmed'),
    'Cancelada' => t('Cancelada', 'Cancelled'),
    'Completada' => t('Completada', 'Completed'),
    _ => estado,
  };

  Widget _insigniaEstado(String estado) {
    final color = _colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_iconoEstado(estado), color: color, size: 15),
        const SizedBox(width: 5),
        Text(_traducirEstado(estado), style: TextStyle(
          color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _lineaDato(IconData icono, String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icono, size: 16, color: _scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text('$etiqueta: $valor',
            style: TextStyle(fontSize: 13, color: _scheme.onSurface))),
        ]),
      );

  Widget _tarjetaCita(AppointmentModel cita) {
    final estadoColor = _colorEstado(cita.estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: _tarjetaDecoracion(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirDetalle(cita),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 57,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(children: [
                    Text('${cita.fecha.day}', style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: AppColors.primaryPink)),
                    Text(_mesCorto(cita.fecha.month), style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: AppColors.primaryPink)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cita.nombreServicio, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: _scheme.onSurface)),
                    const SizedBox(height: 5),
                    Text('${_horaCorta(cita.horaInicio)} h  ·  ${cita.idCita}',
                      style: TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant)),
                  ],
                )),
              ]),
              const SizedBox(height: 12),
              _insigniaEstado(cita.estado),
              _lineaDato(Icons.person_outline_rounded, t('Cliente', 'Client'), cita.nombreCliente),
              _lineaDato(Icons.spa_outlined, t('Especialista', 'Specialist'), cita.nombreEmpleado),
              _lineaDato(Icons.schedule_outlined, t('Duración', 'Duration'), cita.duracionAplicada),
              const SizedBox(height: 12),
              Divider(height: 1, color: _scheme.outlineVariant),
              const SizedBox(height: 9),
              Row(children: [
                Expanded(child: Text('${t('Estado', 'Status')}: ${_traducirEstado(cita.estado)}', style: TextStyle(
                  color: estadoColor, fontSize: 12, fontWeight: FontWeight.w700))),
                TextButton.icon(
                  onPressed: () => _abrirDetalle(cita),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(t('Ver detalle y acciones', 'Details and actions')),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryPink),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  /// Tarjeta compacta para las vistas Semana y Dia.
  /// Solo abre el mismo detalle de cita; no agrega nuevas operaciones.
  Widget _tarjetaAgendaCompacta(AppointmentModel cita) {
    final colorEstado = _colorEstado(cita.estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _tarjetaDecoracion(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirDetalle(cita),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 4, height: 66,
                decoration: BoxDecoration(
                  color: colorEstado,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 50,
                child: Text(_horaCorta(cita.horaInicio), style: TextStyle(
                  color: _scheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cita.nombreServicio,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _scheme.onSurface,
                      fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(cita.nombreCliente,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12)),
                  Text(cita.nombreEmpleado,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 12)),
                  const SizedBox(height: 8),
                  _insigniaEstado(cita.estado),
                ],
              )),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                size: 20, color: _scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _vacio(String mensaje) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 35),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_busy_outlined, size: 42, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(mensaje, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant)),
          ]),
        ),
      );

  Widget _calendarioMensual() {
    final anio = _currentMonth.year;
    final mes = _currentMonth.month;
    final diasEnMes = DateUtils.getDaysInMonth(anio, mes);
    final primerDia = DateTime(anio, mes, 1).weekday - 1; // lunes = 0
    final hoy = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _tarjetaDecoracion(),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.calendar_month_rounded, color: AppColors.primaryPink, size: 22),
          const SizedBox(width: 9),
          Expanded(child: Text(MaterialLocalizations.of(context).formatMonthYear(DateTime(anio, mes)),
            style: TextStyle(fontWeight: FontWeight.w800,
                fontSize: 17, color: _scheme.onSurface))),
          TextButton(
            onPressed: _irAHoy,
            style: TextButton.styleFrom(
              foregroundColor: _dark ? _scheme.primary : AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(t('Hoy', 'Today'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: t('Mes anterior', 'Previous month'),
            onPressed: () => _moverMes(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: t('Mes siguiente', 'Next month'),
            onPressed: () => _moverMes(1),
            icon: const Icon(Icons.chevron_right_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final dia in (StaffPreferences.language.value == 'en' ? const ['M','T','W','T','F','S','S'] : _dias))
            Expanded(child: Center(child: Text(dia, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: _scheme.onSurfaceVariant)))),
        ]),
        const SizedBox(height: 9),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: primerDia + diasEnMes,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 0.89,
          ),
          itemBuilder: (context, index) {
            if (index < primerDia) return const SizedBox.shrink();
            final fecha = DateTime(anio, mes, index - primerDia + 1);
            final seleccionada = _mismoDia(fecha, _selectedDate);
            final esHoy = _mismoDia(fecha, hoy);
            final citas = _appointments.where((c) => _mismoDia(c.fecha, fecha)).toList();
            return Semantics(
              label: '${_fechaLegible(fecha)}, ${citas.length} ${t('citas', 'appointments')}',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _seleccionarDia(fecha),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: seleccionada ? AppColors.primaryPink :
                          esHoy ? AppColors.primaryPink.withValues(alpha: 0.10) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: esHoy && !seleccionada
                          ? Border.all(color: AppColors.primaryPink.withValues(alpha: 0.60))
                          : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${fecha.day}', style: TextStyle(
                        fontWeight: seleccionada || esHoy ? FontWeight.w800 : FontWeight.w500,
                        color: seleccionada ? Colors.white : _scheme.onSurface,
                        fontSize: 13,
                      )),
                      const SizedBox(height: 4),
                      if (citas.isNotEmpty)
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (final cita in citas.take(3))
                            Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: seleccionada ? Colors.white : _colorEstado(cita.estado),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (citas.length > 3)
                            Text('+${citas.length - 3}', style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w800,
                              color: seleccionada ? Colors.white : _scheme.onSurfaceVariant,
                            )),
                        ]),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.circle, size: 9, color: Color(0xFFAC780D)),
          const SizedBox(width: 5),
          Text(t('Pendiente', 'Pending'), style: TextStyle(fontSize: 10, color: _scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          const Icon(Icons.circle, size: 9, color: Color(0xFF237A51)),
          const SizedBox(width: 5),
          Text(t('Confirmada', 'Confirmed'), style: TextStyle(fontSize: 10, color: _scheme.onSurfaceVariant)),
          const SizedBox(width: 12),
          const Icon(Icons.circle, size: 9, color: Color(0xFFB83E4F)),
          const SizedBox(width: 5),
          Text(t('Cancelada', 'Cancelled'), style: TextStyle(fontSize: 10, color: _scheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  /// Selector semanal de 7 dias: solo cambia la fecha seleccionada.
  /// Los marcadores se calculan a partir de las mismas citas cargadas.
  Widget _calendarioSemanal() {
    final lunes = _inicioSemana(_selectedDate);
    final domingo = DateTime(lunes.year, lunes.month, lunes.day + 6);
    final hoy = DateTime.now();
    final dias = List<DateTime>.generate(7,
        (i) => DateTime(lunes.year, lunes.month, lunes.day + i));
    final nombresDias = StaffPreferences.language.value == 'en'
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : _dias;

    return Container(
      decoration: _tarjetaDecoracion(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.date_range_rounded,
              color: AppColors.primaryPink, size: 21),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('Semana', 'Week'), style: TextStyle(
                  color: _scheme.onSurfaceVariant,
                  fontSize: 11, fontWeight: FontWeight.w700)),
              Text('${lunes.day} – ${_fechaLegible(domingo)}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _scheme.onSurface,
                  fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          )),
          TextButton(
            onPressed: _irAHoy,
            style: TextButton.styleFrom(
              foregroundColor: _dark ? _scheme.primary : AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(t('Hoy', 'Today'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: t('Semana anterior', 'Previous week'),
            onPressed: () => _moverSemana(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: t('Semana siguiente', 'Next week'),
            onPressed: () => _moverSemana(1),
            icon: const Icon(Icons.chevron_right_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (var i = 0; i < dias.length; i++)
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _celdaSemana(dias[i], nombresDias[i], hoy),
            )),
        ]),
      ]),
    );
  }

  Widget _celdaSemana(DateTime fecha, String nombreDia, DateTime hoy) {
    final seleccionada = _mismoDia(fecha, _selectedDate);
    final esHoy = _mismoDia(fecha, hoy);
    final citas = _appointments.where((c) => _mismoDia(c.fecha, fecha)).toList();
    final colorTexto = seleccionada ? Colors.white : _scheme.onSurface;
    return Semantics(
      label: '${_fechaLegible(fecha)}, ${citas.length} ${t('citas', 'appointments')}',
      button: true,
      selected: seleccionada,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => setState(() {
            _selectedDate = fecha;
            _currentMonth = DateTime(fecha.year, fecha.month);
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
            decoration: BoxDecoration(
              color: seleccionada ? AppColors.primaryPink
                  : (esHoy ? AppColors.primaryPink.withValues(alpha: 0.09) : Colors.transparent),
              borderRadius: BorderRadius.circular(13),
              border: esHoy && !seleccionada
                  ? Border.all(color: AppColors.primaryPink.withValues(alpha: 0.60))
                  : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(nombreDia, style: TextStyle(fontSize: 10,
                  color: seleccionada ? Colors.white70 : _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text('${fecha.day}', style: TextStyle(fontSize: 15,
                  color: colorTexto, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              if (citas.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: seleccionada ? Colors.white.withValues(alpha: 0.18)
                        : AppColors.primaryPink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text('${citas.length}', style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: seleccionada ? Colors.white
                        : (_dark ? _scheme.primary : AppColors.primaryPink),
                  )),
                )
              else
                const SizedBox(height: 17),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _filtros() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final filtro in const [
            'Todas', 'Pendientes', 'Confirmadas', 'Completadas', 'Canceladas'
          ]) ...[
            ChoiceChip(
              label: Text(switch (filtro) {
                'Todas' => t('Todas', 'All'),
                'Pendientes' => t('Pendientes', 'Pending'),
                'Confirmadas' => t('Confirmadas', 'Confirmed'),
                'Completadas' => t('Completadas', 'Completed'),
                'Canceladas' => t('Canceladas', 'Cancelled'),
                _ => filtro,
              }),
              selected: _selectedFilter == filtro,
              selectedColor: _dark ? _scheme.primaryContainer : AppColors.primaryPinkSoft,
              backgroundColor: _scheme.surface,
              side: BorderSide(color: _selectedFilter == filtro
                  ? AppColors.primaryPink : AppColors.cardBorder),
              labelStyle: TextStyle(
                color: _selectedFilter == filtro
                    ? (_dark ? _scheme.onPrimaryContainer : AppColors.primaryPink) : _scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() => _selectedFilter = filtro),
            ),
            const SizedBox(width: 8),
          ],
        ]),
      );

  /// Vista mensual con una vista previa del dia seleccionado.
  Widget _contenidoCalendario() {
    final citas = _filtradas;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
      children: [
        _calendarioMensual(),
        const SizedBox(height: 18),
        _encabezadoDia(mostrarCambio: false),
        const SizedBox(height: 11),
        _resumenDia(),
        const SizedBox(height: 14),
        _filtros(),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(
            StaffPreferences.language.value == 'en'
                ? '${citas.length} appointments shown'
                : '${citas.length} citas visibles',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: _scheme.onSurfaceVariant),
          )),
          TextButton.icon(
            onPressed: () => setState(() => _vistaActual = _VistaAgenda.dia),
            icon: const Icon(Icons.view_day_outlined, size: 18),
            label: Text(t('Ver día', 'View day')),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryPink),
          ),
        ]),
        if (citas.isEmpty)
          _vacio(t('No hay citas que coincidan con la búsqueda en este día.',
              'No appointments match your search for this day.')),
        for (final cita in citas.take(3)) _tarjetaCita(cita),
        if (citas.length > 3)
          Center(child: TextButton(
            onPressed: () => setState(() => _vistaActual = _VistaAgenda.dia),
            child: Text(StaffPreferences.language.value == 'en'
                ? 'View all ${citas.length} appointments'
                : 'Ver las ${citas.length} citas'),
          )),
      ],
    );
  }

  /// Vista semanal: el selector superior comparte filtros y agenda diaria.
  Widget _contenidoSemana() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: _calendarioSemanal(),
        ),
        Expanded(child: _contenidoAgenda(semana: true)),
      ]);

  /// Vista diaria: conserva los mismos filtros, tarjetas y acceso al detalle.
  Widget _contenidoAgenda({bool semana = false}) {
    final citas = _filtradas;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 0),
        child: semana
            ? _encabezadoDia(mostrarCambio: false)
            : Row(children: [
                Expanded(child: _encabezadoDia(mostrarCambio: false)),
                TextButton(
                  onPressed: _irAHoy,
                  style: TextButton.styleFrom(
                    foregroundColor: _dark ? _scheme.primary : AppColors.primaryPink,
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                  ),
                  child: Text(t('Hoy', 'Today')),
                ),
                IconButton(
                  tooltip: t('Día anterior', 'Previous day'),
                  onPressed: () => _moverDia(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: t('Día siguiente', 'Next day'),
                  onPressed: () => _moverDia(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: _resumenDia(),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: _filtros(),
      ),
      const SizedBox(height: 8),
      Expanded(child: citas.isEmpty
          ? _vacio(t('No hay citas que coincidan con los filtros para esta fecha.',
              'No appointments match the filters for this date.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 105),
              itemCount: citas.length,
              itemBuilder: (context, index) => _tarjetaAgendaCompacta(citas[index]),
            )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: _scheme.onSurface, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
            }
          },
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('Agenda de citas', 'Appointment schedule'), style: TextStyle(
            color: _scheme.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
          Text(t('Administración', 'Administration'), style: TextStyle(
            color: _scheme.onSurfaceVariant, fontWeight: FontWeight.w500, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            tooltip: t('Actualizar citas', 'Refresh appointments'),
            onPressed: _cargando ? null : _cargarCitas,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPink),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: _dark ? _scheme.surfaceContainerHigh : AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(children: [
              Expanded(child: _botonVista(
                t('Mes', 'Month'), Icons.calendar_month_outlined, _VistaAgenda.mes)),
              const SizedBox(width: 5),
              Expanded(child: _botonVista(
                t('Semana', 'Week'), Icons.calendar_view_week_outlined, _VistaAgenda.semana)),
              const SizedBox(width: 5),
              Expanded(child: _botonVista(
                t('Día', 'Day'), Icons.view_day_outlined, _VistaAgenda.dia)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: TextField(
            onChanged: (valor) => setState(() => _searchQuery = valor),
            decoration: InputDecoration(
              hintText: t('Buscar cliente, servicio, especialista o #cita', 'Search client, service, specialist or appointment #'),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPink),
              filled: true,
              fillColor: _scheme.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5)),
            ),
          ),
        ),
        Expanded(child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off_rounded, size: 38, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center,
                        style: TextStyle(color: _scheme.onSurface)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _cargarCitas, child: Text(t('Reintentar', 'Retry'))),
                    ]),
                  ))
                : switch (_vistaActual) {
                    _VistaAgenda.mes => _contenidoCalendario(),
                    _VistaAgenda.semana => _contenidoSemana(),
                    _VistaAgenda.dia => _contenidoAgenda(),
                  }),
      ]),
    );
  }

  Widget _botonVista(String texto, IconData icono, _VistaAgenda vista) {
    final activo = _vistaActual == vista;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _vistaActual = vista),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 9),
        decoration: BoxDecoration(
          color: activo ? _scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: activo ? [BoxShadow(
            color: const Color(0xFF715766).withValues(alpha: 0.06),
            blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icono, size: 18, color: activo ? (_dark ? _scheme.primary : AppColors.primaryPink) : _scheme.onSurfaceVariant),
          const SizedBox(width: 7),
          Flexible(child: Text(texto, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: activo ? (_dark ? _scheme.primary : AppColors.primaryPink) : _scheme.onSurfaceVariant))),
        ]),
      ),
    );
  }
}
