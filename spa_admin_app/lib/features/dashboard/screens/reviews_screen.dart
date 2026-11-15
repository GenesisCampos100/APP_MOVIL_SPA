import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/employee_model.dart';
import 'package:spa_admin_app/data/models/review_model.dart';
import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/repositories/empleados_repository.dart';
import 'package:spa_admin_app/data/repositories/resenas_repository.dart';
import 'package:spa_admin_app/data/repositories/servicios_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// UI 22 — Solo lectura. No crea, publica, responde ni modera reseñas.
/// Requiere las rutas propuestas /admin/resenas y /admin/resenas/resumen.
/// Si faltan en SpaBackend, muestra un estado informativo y nunca datos ficticios.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ResenasRepository _repository = ResenasRepository();
  final TextEditingController _busquedaController = TextEditingController();
  late final AnimationController _animacion;

  List<ServiceModel> _servicios = const [];
  List<EmployeeModel> _empleados = const [];
  ReviewsPage? _pagina;
  ReviewsSummary? _resumen;
  bool _cargando = true;
  String? _error;
  String? _errorResumen;
  bool _faltaApi = false;
  int _solicitud = 0;
  int _numeroPagina = 1;
  DateTime? _desde;
  DateTime? _hasta;
  String? _idServicio;
  String? _idEmpleado;
  int? _estrellas;
  String _buscar = '';

  @override
  void initState() {
    super.initState();
    _animacion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
    _cargarCatalogos();
    _cargar();
  }

  @override
  void dispose() {
    _solicitud++;
    _animacion.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    // Los catálogos ya existen en la API actual; un fallo en ellos no bloquea
    // la lectura de reseñas. En ese caso los filtros siguen siendo opcionales.
    try {
      final servicios = await ServiciosRepository().obtenerTodosServiciosAdmin();
      if (mounted) setState(() => _servicios = servicios);
    } catch (_) {
      // La pantalla mantiene la opción 'Todos los servicios'.
    }
    try {
      final empleados = await EmpleadosRepository().obtenerEmpleados();
      if (mounted) setState(() => _empleados = empleados);
    } catch (_) {
      // La pantalla mantiene la opción 'Todos los empleados'.
    }
  }

  Future<void> _cargar({bool reiniciarPagina = false}) async {
    if (reiniciarPagina) _numeroPagina = 1;
    final actual = ++_solicitud;
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
      _errorResumen = null;
      _faltaApi = false;
      _pagina = null;
      _resumen = null;
    });
    try {
      final result = await _repository.obtenerResenas(
        desde: _desde,
        hasta: _hasta,
        idServicio: _idServicio,
        idEmpleado: _idEmpleado,
        estrellas: _estrellas,
        buscar: _buscar,
        pagina: _numeroPagina,
      );
      if (!mounted || actual != _solicitud) return;
      setState(() => _pagina = result);
      try {
        final resumen = await _repository.obtenerResumen(
          desde: _desde,
          hasta: _hasta,
          idServicio: _idServicio,
          idEmpleado: _idEmpleado,
        );
        if (!mounted || actual != _solicitud) return;
        setState(() => _resumen = resumen);
      } on ApiException catch (e) {
        if (!mounted || actual != _solicitud) return;
        setState(() => _errorResumen = e.message);
      } catch (_) {
        if (!mounted || actual != _solicitud) return;
        setState(() => _errorResumen = AdminVisual.t('No fue posible cargar el resumen.', 'Unable to load the summary.'));
      }
    } on ApiException catch (e) {
      if (!mounted || actual != _solicitud) return;
      setState(() {
        _faltaApi = e.statusCode == 404;
        _error = e.statusCode == 404
            ? AdminVisual.t('El servidor aún no tiene habilitada la consulta de reseñas. La pantalla está lista para conectarse cuando se implemente la API.', 'The server does not yet expose review endpoints. This screen is ready when the API is available.')
            : e.message;
      });
    } catch (_) {
      if (!mounted || actual != _solicitud) return;
      setState(() => _error = AdminVisual.t('No fue posible cargar las reseñas. Intenta nuevamente.', 'Unable to load reviews. Please try again.'));
    } finally {
      if (mounted && actual == _solicitud) {
        setState(() => _cargando = false);
      }
    }
  }

  int get _cantidadFiltros => [
        _desde != null || _hasta != null,
        _idServicio != null,
        _idEmpleado != null,
        _estrellas != null,
      ].where((activo) => activo).length;

  void _limpiar() {
    _busquedaController.clear();
    setState(() {
      _desde = null;
      _hasta = null;
      _idServicio = null;
      _idEmpleado = null;
      _estrellas = null;
      _buscar = '';
    });
    _cargar(reiniciarPagina: true);
  }

  Future<void> _abrirFiltros() async {
    String servicio = _idServicio ?? '';
    String empleado = _idEmpleado ?? '';
    int estrellas = _estrellas ?? 0;
    DateTime? desde = _desde;
    DateTime? hasta = _hasta;
    final aplicar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AdminVisual.background,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (contextoHoja) => StatefulBuilder(
        builder: (contextoHoja, actualizarHoja) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22, 8, 22, MediaQuery.viewInsetsOf(contextoHoja).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AdminVisual.t('Filtrar opiniones', 'Filter reviews'), style: AppTextStyles.heading1.copyWith(color: AdminVisual.textDark)),
                  const SizedBox(height: 6),
                  Text(AdminVisual.t('Combina los filtros para explorar las reseñas.', 'Combine filters to explore reviews.'),
                      style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                  const SizedBox(height: 20),
                  Text(AdminVisual.t('Periodo', 'Period'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 7),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined, size: 19),
                    label: Text(
                      desde == null || hasta == null
                          ? AdminVisual.t('Todas las fechas', 'All dates')
                          : '${_formatoFecha(desde!)} – ${_formatoFecha(hasta!)}',
                      style: AppTextStyles.caption,
                    ),
                    onPressed: () async {
                      final seleccionado = await showDateRangePicker(
                        context: contextoHoja,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: desde != null && hasta != null
                            ? DateTimeRange(start: desde!, end: hasta!)
                            : null,
                        helpText: AdminVisual.t('Selecciona el periodo', 'Select a period'),
                      );
                      if (seleccionado != null) {
                        actualizarHoja(() {
                          desde = seleccionado.start;
                          hasta = seleccionado.end;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(AdminVisual.t('Servicio', 'Service'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('servicio-$servicio'),
                    initialValue: servicio,
                    isExpanded: true,
                    decoration: _decoracionCampo(),
                    items: [
                      DropdownMenuItem(value: '', child: Text(AdminVisual.t('Todos los servicios', 'All services'))),
                      if (servicio.isNotEmpty &&
                          !_servicios.any((s) => s.idServicio == servicio))
                        DropdownMenuItem(
                          value: servicio,
                          child: Text(AdminVisual.t('Servicio seleccionado ($servicio)', 'Selected service ($servicio)')),
                        ),
                      for (final s in _servicios)
                        DropdownMenuItem(value: s.idServicio, child: Text(s.nombre, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => actualizarHoja(() => servicio = v ?? ''),
                  ),
                  const SizedBox(height: 14),
                  Text(AdminVisual.t('Empleado / terapeuta', 'Employee / therapist'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey('empleado-$empleado'),
                    initialValue: empleado,
                    isExpanded: true,
                    decoration: _decoracionCampo(),
                    items: [
                      DropdownMenuItem(value: '', child: Text(AdminVisual.t('Todos los empleados', 'All employees'))),
                      if (empleado.isNotEmpty &&
                          !_empleados.any((e) => e.idEmpleado == empleado))
                        DropdownMenuItem(
                          value: empleado,
                          child: Text(AdminVisual.t('Empleado seleccionado ($empleado)', 'Selected employee ($empleado)')),
                        ),
                      for (final e in _empleados)
                        DropdownMenuItem(value: e.idEmpleado, child: Text(e.nombreCompleto, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => actualizarHoja(() => empleado = v ?? ''),
                  ),
                  const SizedBox(height: 15),
                  Text(AdminVisual.t('Calificación del servicio', 'Service rating'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 8,
                    children: [
                      for (var n = 0; n <= 5; n++)
                        ChoiceChip(
                          selected: estrellas == n,
                          label: Text(n == 0 ? AdminVisual.t('Todas', 'All') : '$n ★', style: AppTextStyles.caption),
                          selectedColor: AdminVisual.primaryPinkSoft,
                          onSelected: (_) => actualizarHoja(() => estrellas = n),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(contextoHoja, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminVisual.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(AdminVisual.t('Aplicar filtros', 'Apply filters'),
                        style: AppTextStyles.subtitle.copyWith(color: Colors.white)),
                  ),
                  TextButton(
                    onPressed: () => actualizarHoja(() {
                      desde = null;
                      hasta = null;
                      empleado = '';
                      servicio = '';
                      estrellas = 0;
                    }),
                    child: Text(AdminVisual.t('Restablecer selección', 'Reset selection'), style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || aplicar != true) return;
    setState(() {
      _desde = desde;
      _hasta = hasta;
      _idServicio = servicio.isEmpty ? null : servicio;
      _idEmpleado = empleado.isEmpty ? null : empleado;
      _estrellas = estrellas == 0 ? null : estrellas;
    });
    _cargar(reiniciarPagina: true);
  }

  // UI 22 — Detalle editorial. Solo cambia la presentacion del modal:
  // recibe el mismo ReviewModel, sin alterar consultas ni permisos.
  void _abrirDetalle(ReviewModel resena) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      barrierColor: const Color(0xA04B3640),
      builder: (contextoHoja) => FractionallySizedBox(
        heightFactor: 0.91,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Material(
            color: AdminVisual.background,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 340),
                        curve: Curves.easeOutCubic,
                        builder: (context, avance, child) => Opacity(
                          opacity: avance,
                          child: Transform.translate(
                            offset: Offset(0, (1 - avance) * 12),
                            child: child,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _encabezadoDetalle(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, -8),
                                    child: _fichaInformacionResena(resena),
                                  ),
                                  const SizedBox(height: 16),
                                  _tituloDetalle(AdminVisual.t('Calificaciones', 'Ratings')),
                                  const SizedBox(height: 12),
                                  _calificacionDetalle(
                                    AdminVisual.t('Calificación del servicio', 'Service rating'),
                                    resena.estrellasServicio,
                                  ),
                                  const SizedBox(height: 9),
                                  _calificacionDetalle(
                                    AdminVisual.t('Calificación del terapeuta', 'Therapist rating'),
                                    resena.estrellasTerapeuta,
                                  ),
                                  const SizedBox(height: 23),
                                  _tituloDetalle(AdminVisual.t('Comentario', 'Comment')),
                                  const SizedBox(height: 12),
                                  _comentarioDetalle(resena.comentario),
                                  if (resena.aspectosDestacados.isNotEmpty) ...[
                                    const SizedBox(height: 23),
                                    _tituloDetalle(AdminVisual.t('Aspectos destacados', 'Highlights')),
                                    const SizedBox(height: 9),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        for (final aspecto in resena.aspectosDestacados)
                                          Chip(
                                            label: Text(aspecto,
                                                style: AppTextStyles.caption),
                                            backgroundColor: AdminVisual.primaryPinkSoft,
                                            side: BorderSide.none,
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 27),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_outline_rounded,
                                          color: AdminVisual.textMuted, size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          AdminVisual.t('Consulta de solo lectura', 'Read-only view'),
                                          style: AppTextStyles.caption.copyWith(
                                            color: AdminVisual.textMuted,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _encabezadoDetalle() => Container(
        height: 173,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AdminVisual.dark
                ? const [Color(0xFF382837), Color(0xFF584052)]
                : const [Color(0xFFFFF9FA), Color(0xFFF9E1E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: 5,
              bottom: 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: 150,
                  height: 98,
                  child: CustomPaint(
                    painter: _ResenaSpaDecoracionPainter(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 13, 22, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF80616D),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    AdminVisual.t('Detalle de reseña', 'Review details'),
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 23,
                      color: AdminVisual.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 68,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD88CA6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _fichaInformacionResena(ReviewModel resena) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: AdminVisual.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AdminVisual.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x109D5075),
              blurRadius: 17,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _filaDetalle(Icons.person_outline_rounded,
                AdminVisual.t('Cliente', 'Customer'), resena.cliente ?? AdminVisual.t('No indicado', 'Not provided')),
            Divider(height: 1, color: AdminVisual.cardBorder),
            _filaDetalle(Icons.spa_outlined,
                AdminVisual.t('Servicio', 'Service'), resena.servicioNombre ?? AdminVisual.t('No indicado', 'Not provided')),
            Divider(height: 1, color: AdminVisual.cardBorder),
            _filaDetalle(Icons.badge_outlined,
                AdminVisual.t('Especialista', 'Specialist'), resena.empleadoNombre ?? AdminVisual.t('No indicado', 'Not provided')),
            Divider(height: 1, color: AdminVisual.cardBorder),
            _filaDetalle(Icons.event_outlined, AdminVisual.t('Fecha', 'Date'),
                resena.fecha == null ? AdminVisual.t('No indicada', 'Not provided') : _formatoFecha(resena.fecha!)),
          ],
        ),
      );

  Widget _filaDetalle(IconData icono, String titulo, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AdminVisual.primaryPinkSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icono, size: 21, color: AdminVisual.primaryPink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: AppTextStyles.caption.copyWith(
                          color: AdminVisual.textMuted)),
                  const SizedBox(height: 3),
                  Text(valor,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AdminVisual.textDark,
                        fontSize: 14,
                        height: 1.3,
                      )),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _tituloDetalle(String titulo) => Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFD68DA5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              titulo,
              style: AppTextStyles.heading2.copyWith(
                color: AdminVisual.textDark,
                fontSize: 17,
              ),
            ),
          ),
        ],
      );

  Widget _calificacionDetalle(String titulo, int? estrellas) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        decoration: BoxDecoration(
          color: AdminVisual.cardBackground,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AdminVisual.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B9D5075),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AdminVisual.primaryPinkSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.star_border_rounded,
                  size: 21, color: AdminVisual.primaryPink),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(titulo,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AdminVisual.textDark,
                  )),
            ),
            const SizedBox(width: 6),
            if (estrellas == null)
              Text(AdminVisual.t('Sin calificar', 'Not rated'),
                  style: AppTextStyles.caption.copyWith(
                      color: AdminVisual.textMuted))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Estrellas(cantidad: estrellas, size: 15),
                  const SizedBox(height: 2),
                  Text('$estrellas/5',
                      style: AppTextStyles.caption.copyWith(
                        color: AdminVisual.textDark,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
          ],
        ),
      );

  Widget _comentarioDetalle(String? comentario) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 19),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AdminVisual.dark
                ? const [Color(0xFF483645), Color(0xFF302630)]
                : const [Color(0xFFFBE7EE), Color(0xFFFFEFF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote_rounded,
                size: 30, color: Color(0xFFD894AB)),
            const SizedBox(height: 2),
            Text(
              comentario == null || comentario.trim().isEmpty
                  ? AdminVisual.t('El cliente no agregó comentario.', 'The customer left no comment.')
                  : comentario,
              style: AppTextStyles.body.copyWith(
                color: AdminVisual.textDark,
                height: 1.55,
              ),
            ),
          ],
        ),
      );

  static InputDecoration _decoracionCampo() => InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AdminVisual.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      );

  static String _formatoFecha(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }

  Widget _encabezado() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: AdminVisual.dark
                ? const [Color(0xFF332531), Color(0xFF584054)]
                : const [Color(0xFFFFF6F9), Color(0xFFF8DBE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(27),
            bottomRight: Radius.circular(38),
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              right: 8,
              bottom: 0,
              child: IgnorePointer(
                child: Icon(Icons.spa_outlined, size: 96, color: Color(0x44B87E92)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_rounded, color: AdminVisual.textDark),
                  tooltip: AdminVisual.t('Volver a Más opciones', 'Back to More options'),
                ),
                const SizedBox(height: 11),
                Padding(
                  padding: const EdgeInsets.only(left: 9, right: 78),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A U R A   S P A',
                          style: AppTextStyles.caption.copyWith(
                            color: AdminVisual.primaryPink,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          )),
                      const SizedBox(height: 10),
                      Text(AdminVisual.t('Reseñas y opiniones', 'Reviews and ratings'),
                          style: AppTextStyles.heading1.copyWith(
                            color: AdminVisual.textDark,
                            fontSize: 22,
                            height: 1.18,
                          )),
                      const SizedBox(height: 9),
                      Text(AdminVisual.t('Escucha las experiencias de tus clientes.', 'Hear what your customers have to say.'),
                          style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _tarjetaResumen() {
    final resumen = _resumen;
    if (resumen == null) {
      return _marco(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.insights_outlined, color: AdminVisual.primaryPink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AdminVisual.t('Resumen de calificaciones', 'Ratings summary'), style: AppTextStyles.subtitle),
                  const SizedBox(height: 5),
                  Text(_errorResumen ?? AdminVisual.t('El resumen todavía no está disponible.', 'The summary is not available yet.'),
                      style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _marco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AdminVisual.t('Resumen de calificaciones', 'Ratings summary'),
              style: AppTextStyles.heading2.copyWith(color: AdminVisual.textDark)),
          const SizedBox(height: 3),
          Text(AdminVisual.t('${resumen.total} reseña${resumen.total == 1 ? '' : 's'} en el periodo seleccionado', '${resumen.total} review${resumen.total == 1 ? '' : 's'} in the selected period'),
              style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
          const SizedBox(height: 19),
          if (resumen.total == 0)
            Text(AdminVisual.t('Aún no existen valoraciones para este periodo.', 'No ratings for this period yet.'),
                style: AppTextStyles.body.copyWith(color: AdminVisual.textMuted))
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AdminVisual.t('Servicios', 'Services'), style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                      const SizedBox(height: 2),
                      Text(resumen.promedioServicios == null
                          ? '—' : resumen.promedioServicios!.toStringAsFixed(1),
                          style: AppTextStyles.displayBlack.copyWith(color: AdminVisual.primaryPink, fontSize: 33)),
                      if (resumen.promedioServicios != null)
                        _Estrellas(
                          cantidad: resumen.promedioServicios!.round(),
                          color: const Color(0xFFD2A05B),
                          size: 13,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AdminVisual.t('Terapeutas', 'Therapists'), style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                      const SizedBox(height: 4),
                      Text(resumen.promedioTerapeutas == null
                          ? '—' : resumen.promedioTerapeutas!.toStringAsFixed(1),
                          style: AppTextStyles.heading1.copyWith(color: AdminVisual.textDark)),
                      Text(AdminVisual.t('de 5 estrellas', 'out of 5 stars'), style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            if (resumen.distribucionServicios.isNotEmpty) ...[
              Divider(height: 28, color: AdminVisual.cardBorder),
              Text(AdminVisual.t('Distribución · servicios', 'Distribution · services'), style: AppTextStyles.caption),
              const SizedBox(height: 9),
              for (var n = 5; n >= 1; n--)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 28, child: Text('$n ★', style: AppTextStyles.caption.copyWith(fontSize: 10))),
                      const SizedBox(width: 9),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            minHeight: 7,
                            value: resumen.distribucionServicios.values.fold<int>(0, (a, b) => a + b) == 0
                                ? 0
                                : (resumen.distribucionServicios[n] ?? 0) /
                                    resumen.distribucionServicios.values.fold<int>(0, (a, b) => a + b),
                            backgroundColor: AdminVisual.primaryPinkSoft,
                            color: const Color(0xFFC77D97),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 24,
                        child: Text('${resumen.distribucionServicios[n] ?? 0}',
                          textAlign: TextAlign.end,
                          style: AppTextStyles.caption.copyWith(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
            ],
          ],
          if (_estrellas != null || _buscar.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(AdminVisual.t('El resumen no incluye los filtros de búsqueda ni estrellas.', 'The summary excludes text search and star filters.'),
                style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _marco({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AdminVisual.cardBackground,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: AdminVisual.cardBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x0D9D5075), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _contenido() {
    if (_cargando) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 45),
        child: Center(child: CircularProgressIndicator(color: AdminVisual.primaryPink)),
      );
    }
    if (_error != null) {
      return _marco(
        child: Column(
          children: [
            Icon(_faltaApi ? Icons.cloud_off_outlined : Icons.error_outline_rounded,
                color: AdminVisual.primaryPink, size: 39),
            const SizedBox(height: 12),
            Text(_faltaApi ? AdminVisual.t('Conexión de reseñas pendiente', 'Reviews connection pending') : AdminVisual.t('No se pudieron consultar las reseñas', 'Unable to load reviews'),
                style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AdminVisual.textMuted)),
            const SizedBox(height: 13),
            OutlinedButton.icon(
              onPressed: () => _cargar(),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AdminVisual.t('Reintentar', 'Retry'), style: AppTextStyles.caption),
            ),
          ],
        ),
      );
    }
    final page = _pagina;
    if (page == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tarjetaResumen(),
        const SizedBox(height: 21),
        Row(
          children: [
            Expanded(child: Text(AdminVisual.t('Opiniones de clientes', 'Customer reviews'),
                style: AppTextStyles.heading2.copyWith(color: AdminVisual.textDark))),
            Text(AdminVisual.t('${page.total} resultado${page.total == 1 ? '' : 's'}', '${page.total} result${page.total == 1 ? '' : 's'}'),
                style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
          ],
        ),
        const SizedBox(height: 11),
        if (page.resenas.isEmpty)
          _marco(child: Column(
            children: [
              Icon(Icons.rate_review_outlined, size: 36, color: AdminVisual.primaryPink),
              const SizedBox(height: 12),
              Text(AdminVisual.t('No hay reseñas para mostrar', 'No reviews to display'), style: AppTextStyles.subtitle),
              const SizedBox(height: 6),
              Text(AdminVisual.t('Prueba con otras fechas o filtros.', 'Try different dates or filters.'),
                  style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
            ],
          ))
        else
          for (final resena in page.resenas) ...[
            _TarjetaResena(resena: resena, onTap: () => _abrirDetalle(resena)),
            const SizedBox(height: 10),
          ],
        if (page.totalPaginas > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: AdminVisual.t('Página anterior', 'Previous page'),
                onPressed: _numeroPagina <= 1 ? null : () {
                  _numeroPagina--;
                  _cargar();
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(AdminVisual.t('Página ${page.pagina} de ${page.totalPaginas}', 'Page ${page.pagina} of ${page.totalPaginas}'), style: AppTextStyles.caption),
              IconButton(
                tooltip: AdminVisual.t('Página siguiente', 'Next page'),
                onPressed: _numeroPagina >= page.totalPaginas ? null : () {
                  _numeroPagina++;
                  _cargar();
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _animacion, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: AdminVisual.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: fade,
          child: Column(
            children: [
              _encabezado(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _cargar(),
                  color: AdminVisual.primaryPink,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(19, 18, 19, 24),
                    children: [
                      TextField(
                        controller: _busquedaController,
                        style: AppTextStyles.body,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (texto) {
                          setState(() => _buscar = texto.trim());
                          _cargar(reiniciarPagina: true);
                        },
                        decoration: InputDecoration(
                          hintText: AdminVisual.t('Buscar cliente o comentario', 'Search customer or comment'),
                          hintStyle: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted),
                          filled: true,
                          fillColor: AdminVisual.cardBackground,
                          prefixIcon: Icon(Icons.search_rounded, color: AdminVisual.primaryPink),
                          suffixIcon: IconButton(
                            tooltip: AdminVisual.t('Buscar', 'Search'),
                            onPressed: () {
                              setState(() => _buscar = _busquedaController.text.trim());
                              _cargar(reiniciarPagina: true);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AdminVisual.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AdminVisual.cardBorder),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _abrirFiltros,
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: Text(_cantidadFiltros == 0 ? AdminVisual.t('Filtros', 'Filters') : AdminVisual.t('Filtros ($_cantidadFiltros)', 'Filters ($_cantidadFiltros)'),
                                style: AppTextStyles.caption),
                          ),
                          const Spacer(),
                          if (_cantidadFiltros > 0 || _buscar.isNotEmpty)
                            TextButton(
                              onPressed: _limpiar,
                              child: Text(AdminVisual.t('Limpiar filtros', 'Clear filters'), style: AppTextStyles.caption),
                            ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: KeyedSubtree(
                          key: ValueKey('${_cargando}_${_error ?? ''}_${_numeroPagina}_${_resumen?.total ?? ''}'),
                          child: _contenido(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaResena extends StatelessWidget {
  final ReviewModel resena;
  final VoidCallback onTap;

  const _TarjetaResena({required this.resena, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminVisual.cardBackground,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AdminVisual.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AdminVisual.primaryPinkSoft,
                    child: Icon(Icons.person_outline, color: AdminVisual.primaryPink),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resena.cliente ?? AdminVisual.t('Cliente', 'Customer'),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(color: AdminVisual.textDark)),
                        if (resena.servicioNombre != null)
                          Text(resena.servicioNombre!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AdminVisual.primaryPink),
                ],
              ),
              const SizedBox(height: 11),
              if (resena.estrellasServicio != null)
                Row(children: [
                  Text(AdminVisual.t('Servicio  ', 'Service  '), style: TextStyle(fontSize: 11, fontFamily: AppTextStyles.fontFamily)),
                  _Estrellas(cantidad: resena.estrellasServicio!),
                ]),
              if (resena.estrellasTerapeuta != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  Text(AdminVisual.t('Terapeuta  ', 'Therapist  '), style: TextStyle(fontSize: 11, fontFamily: AppTextStyles.fontFamily)),
                  _Estrellas(cantidad: resena.estrellasTerapeuta!),
                ]),
              ],
              if (resena.comentario != null) ...[
                const SizedBox(height: 10),
                Text(resena.comentario!, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(color: AdminVisual.textDark)),
              ],
              if (resena.fecha != null) ...[
                const SizedBox(height: 11),
                Row(children: [
                  Icon(Icons.event_outlined, size: 14, color: AdminVisual.textMuted),
                  const SizedBox(width: 4),
                  Text(_ReviewsScreenState._formatoFecha(resena.fecha!),
                      style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Estrellas extends StatelessWidget {
  final int cantidad;
  final Color color;
  final double size;
  const _Estrellas({required this.cantidad, this.color = const Color(0xFFC99B53), this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= cantidad ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size, color: color),
      ],
    );
  }
}

/// Ilustracion vectorial ligera. Sin archivos ni dependencias adicionales.
/// Solo se utiliza como decoracion del detalle de una resena.
class _ResenaSpaDecoracionPainter extends CustomPainter {
  const _ResenaSpaDecoracionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final piedra = Paint()..color = const Color(0x80BDAAB1);
    final sombra = Paint()..color = const Color(0x73E2B6C7);
    final petalo = Paint()..color = const Color(0xD9F2C4D3);
    final borde = Paint()
      ..color = const Color(0xBFCF819D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawOval(Rect.fromLTWH(size.width * 0.30, size.height * 0.83,
        size.width * 0.66, size.height * 0.12), sombra);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.50, size.height * 0.65,
        size.width * 0.39, size.height * 0.18), piedra);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.55, size.height * 0.49,
        size.width * 0.31, size.height * 0.15), piedra);

    // Petalos con trazos finos, en composicion radial.
    final centro = Offset(size.width * 0.31, size.height * 0.69);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(i * 1.2566370614);
      final hoja = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-11, -23, 0, -37)
        ..quadraticBezierTo(11, -23, 0, 0)
        ..close();
      canvas.drawPath(hoja, petalo);
      canvas.drawPath(hoja, borde);
      canvas.restore();
    }
    canvas.drawCircle(centro, 4.5,
        Paint()..color = const Color(0xFFD88BA5));
  }

  @override
  bool shouldRepaint(covariant _ResenaSpaDecoracionPainter oldDelegate) => false;
}
