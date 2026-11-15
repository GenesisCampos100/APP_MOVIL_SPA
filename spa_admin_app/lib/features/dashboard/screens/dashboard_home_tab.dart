import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Panel operativo del Administrador. Todos los contadores proceden de la API.
/// No modifica estados, no crea citas y no consulta módulos de reportes.
class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({
    super.key,
    required this.onVerAgenda,
    required this.onNuevaCita,
    required this.onServicios,
    required this.onMenu,
    required this.refreshVersion,
  });

  // Se conserva exactamente la interfaz que utiliza MainNavigationScreen.
  final VoidCallback onVerAgenda;
  final VoidCallback onNuevaCita;
  final VoidCallback onServicios;
  final VoidCallback onMenu;
  final int refreshVersion;

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final CitasRepository _repository = CitasRepository();
  late final AnimationController _entrance;
  List<AppointmentModel> _citas = [];
  bool _loading = true;
  String? _error;

  String t(String es, String en) => StaffPreferences.tr(es, en);

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  static const Color _rose = Color(0xFFB85D78);
  static const Color _roseDark = Color(0xFF7F3E53);
  static const Color _ink = Color(0xFF3A2930);
  static const Color _muted = Color(0xFF84737A);
  static const Color _blush = Color(0xFFFFF0F2);
  static const Color _line = Color(0xFFF1E2E4);
  static const Color _green = Color(0xFF486C4B);
  static const Color _gold = Color(0xFF986519);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _loadSummary();
  }

  @override
  void didUpdateWidget(covariant DashboardHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadSummary();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadSummary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    if (!AuthSession.esAdministrador || !AuthSession.activa) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Inicia sesión como Administrador para consultar el panel.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final citas = await _repository.obtenerCitas();
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (e.statusCode) {
          401 => 'Tu sesión ha finalizado. Cierra sesión y vuelve a ingresar.',
          403 => 'No tienes permiso para consultar las citas.',
          _ => 'No fue posible consultar el resumen de citas.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar la información. Verifica la conexión e inténtalo de nuevo.';
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _status(AppointmentModel cita) => cita.estado.trim().toLowerCase();

  DateTime? _start(AppointmentModel cita) {
    final parts = cita.horaInicio.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return DateTime(cita.fecha.year, cita.fecha.month, cita.fecha.day, hour, minute);
  }

  String _date(DateTime day) => MaterialLocalizations.of(context).formatMediumDate(day);

  String _time(AppointmentModel cita) {
    final start = _start(cita);
    if (start == null) return cita.horaInicio;
    final h = start.hour % 12 == 0 ? 12 : start.hour % 12;
    return '$h:${start.minute.toString().padLeft(2, '0')} ${start.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  // Reutiliza la pestaña Citas existente; no crea rutas nuevas.
  void _openAppointments() => widget.onVerAgenda();

  Widget _reveal(Widget child, {double begin = 0}) {
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035), end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _surface({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _dark ? _scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _dark ? _scheme.outlineVariant : _line),
        boxShadow: [
          BoxShadow(color: _roseDark.withValues(alpha: 0.045), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) => Row(
    children: [
      Expanded(
        child: Text(title, style: TextStyle(
          fontFamily: AppTextStyles.fontFamily, fontSize: 19, fontWeight: FontWeight.w700,
          color: _dark ? _scheme.onSurface : _ink, height: 1.12,
        )),
      ),
      if (trailing != null) trailing,
    ],
  );

  Widget _metric({required String value, required String label,
    required Color tint, required Color foreground, required IconData icon}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
      decoration: BoxDecoration(
        color: _dark ? _scheme.surfaceContainerHigh : tint,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _dark ? _scheme.outlineVariant : Colors.white.withValues(alpha: 0.9)),
        boxShadow: [BoxShadow(
          color: foreground.withValues(alpha: 0.07),
          blurRadius: 12, offset: const Offset(0, 5),
        )],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: _dark ? _scheme.primary : foreground, size: 20),
        const SizedBox(height: 7),
        Text(value, style: TextStyle(color: _dark ? _scheme.onSurface : foreground, fontSize: 25,
          fontWeight: FontWeight.w700, height: 1.05)),
        const SizedBox(height: 5),
        FittedBox(fit: BoxFit.scaleDown, child: Text(label,
          maxLines: 1, style: TextStyle(color: _dark ? _scheme.onSurfaceVariant : foreground,
            fontSize: 10.5, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _welcomeCard(DateTime today) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 206),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _dark ? const [Color(0xFF352834), Color(0xFF453243)]
            : const [Color(0xFFFFF8F7), Color(0xFFF9E2E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _dark ? _scheme.outlineVariant : Colors.white, width: 1.4),
        boxShadow: [BoxShadow(color: _roseDark.withValues(alpha: 0.09),
          blurRadius: 22, offset: const Offset(0, 9))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _SpaWelcomePainter())),
        Padding(
          padding: const EdgeInsets.fromLTRB(21, 23, 15, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('A U R A   S P A', style: TextStyle(
              fontFamily: AppTextStyles.fontFamily, fontSize: 14,
              fontWeight: FontWeight.w600, letterSpacing: 2, color: _dark ? _scheme.primary : _roseDark)),
            const SizedBox(height: 25),
            // La sesión actual no proporciona nombre: no se inventan datos.
            Text(t('Bienvenido de nuevo', 'Welcome back'), style: TextStyle(
              fontFamily: AppTextStyles.fontFamily, color: _dark ? _scheme.onSurface : _ink,
              fontWeight: FontWeight.w700, fontSize: 19.5)),
            const SizedBox(height: 4),
            Text(t('Tu jornada, organizada con calma.', 'Your day, thoughtfully organized.'),
              style: TextStyle(fontFamily: AppTextStyles.fontFamily,
                color: _dark ? _scheme.onSurfaceVariant : _muted, fontSize: 11.5)),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: _dark ? _scheme.surfaceContainerHigh : const Color(0xFFF7DAE3).withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(30)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_outlined,
                  size: 14, color: _dark ? _scheme.primary : _roseDark),
                const SizedBox(width: 8),
                Text(_date(today), style: TextStyle(
                  color: _dark ? _scheme.onSurface : _roseDark, fontSize: 11,
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'confirmada' => _green,
      'pendiente' => _gold,
      'completada' => const Color(0xFF79618A),
      'cancelada' => _roseDark,
      _ => _muted,
    };
    final tint = switch (normalized) {
      'confirmada' => const Color(0xFFEAF2E6),
      'pendiente' => const Color(0xFFFFF0D9),
      'completada' => const Color(0xFFF0EAF6),
      'cancelada' => const Color(0xFFFBE5E9),
      _ => const Color(0xFFF4F0F1),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: _dark ? _scheme.surfaceContainerHigh : tint,
        borderRadius: BorderRadius.circular(20)),
      child: Text(switch (normalized) {
          'pendiente' => t('Pendiente', 'Pending'),
          'confirmada' => t('Confirmada', 'Confirmed'),
          'cancelada' => t('Cancelada', 'Cancelled'),
          'completada' => t('Completada', 'Completed'),
          _ => status.isEmpty ? t('Sin estado', 'No status') : status,
        },
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
          color: _dark ? _scheme.onSurface : color),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _appointmentRow(AppointmentModel cita) {
    return InkWell(
      onTap: _openAppointments,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            decoration: BoxDecoration(color: _dark ? _scheme.surfaceContainerHigh : _blush, borderRadius: BorderRadius.circular(13)),
            child: Text(_time(cita), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _dark ? _scheme.primary : _roseDark)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cita.nombreCliente.isEmpty ? t('Cliente sin nombre', 'Unnamed customer') : cita.nombreCliente,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _dark ? _scheme.onSurface : _ink)),
            const SizedBox(height: 3),
            Text(cita.nombreServicio, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: _dark ? _scheme.onSurfaceVariant : _muted)),
          ])),
          const SizedBox(width: 5),
          Flexible(child: _statusChip(cita.estado)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daily = _citas.where((c) => _sameDay(c.fecha, today)).toList();
    int count(String status) => daily.where((c) => _status(c) == status).length;
    final pending = count('pendiente');
    final confirmed = count('confirmada');
    final completed = count('completada');
    final cancelled = count('cancelada');
    // El avance considera solamente las citas no canceladas.
    final active = daily.length - cancelled;
    final progress = active == 0 ? 0.0 : completed / active;
    final upcoming = daily.where((c) {
      if (_status(c) == 'cancelada' || _status(c) == 'completada') return false;
      final start = _start(c);
      return start != null && !start.isBefore(today);
    }).toList()..sort((a, b) => _start(a)!.compareTo(_start(b)!));
    final visibleUpcoming = upcoming.take(3).toList();

    return RefreshIndicator(
      onRefresh: _loadSummary,
      color: _rose,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(18, 31, 18, 30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _reveal(_welcomeCard(today)),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOut,
            child: _loading
                ? _surface(child: const Center(child: Padding(
                    padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: _rose))))
                : _error != null
                    ? _surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t('No se pudo cargar el panel', 'Could not load dashboard'), style: TextStyle(
                          color: _dark ? _scheme.onSurface : _ink, fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 9),
                        Text(_error!, style: TextStyle(color: _dark ? _scheme.onSurfaceVariant : _muted, fontSize: 13)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadSummary, child: Text(t('Reintentar', 'Retry'))),
                      ]))
                    : Column(key: const ValueKey('dashboard_data'),
                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _reveal(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionTitle(t('Tu día de un vistazo', 'Your day at a glance')),
                          const SizedBox(height: 13),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 101),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFC57992), Color(0xFFAA5577),
                              ]),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [BoxShadow(color: _rose.withValues(alpha: 0.15),
                                blurRadius: 15, offset: const Offset(0, 7))],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(children: [
                              const Positioned(right: 59, bottom: -28,
                                child: Opacity(opacity: 0.20,
                                  child: Icon(Icons.calendar_month_rounded,
                                    size: 124, color: Colors.white))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 18),
                                child: Row(children: [
                                  const Icon(Icons.event_available_outlined,
                                    color: Colors.white, size: 30),
                                  Container(height: 49, width: 1, margin:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                    color: Colors.white.withValues(alpha: 0.48)),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t('Citas de hoy', 'Today’s appointments'), style: TextStyle(
                                        color: Colors.white, fontSize: 17,
                                        fontWeight: FontWeight.w700)),
                                      SizedBox(height: 3),
                                      Text(t('Total programadas', 'Total scheduled'), style: TextStyle(
                                        color: Color(0xFFFFE5EC), fontSize: 11.5)),
                                    ],
                                  )),
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 56),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCE4EB),
                                      borderRadius: BorderRadius.circular(16)),
                                    child: Text('${daily.length}', textAlign: TextAlign.center,
                                      style: const TextStyle(color: _roseDark,
                                        fontSize: 27, fontWeight: FontWeight.w700)),
                                  ),
                                ]),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: _metric(value: '$confirmed', label: t('Confirmadas', 'Confirmed'),
                              tint: const Color(0xFFEEF2E8), foreground: _green, icon: Icons.check_circle_outline_rounded)),
                            const SizedBox(width: 7),
                            Expanded(child: _metric(value: '$pending', label: t('Pendientes', 'Pending'),
                              tint: const Color(0xFFFFF0DB), foreground: _gold, icon: Icons.access_time_rounded)),
                            const SizedBox(width: 7),
                            Expanded(child: _metric(value: '$completed', label: t('Completadas', 'Completed'),
                              tint: const Color(0xFFF1EBF4), foreground: const Color(0xFF765B82), icon: Icons.task_alt_rounded)),
                            const SizedBox(width: 7),
                            Expanded(child: _metric(value: '$cancelled', label: t('Canceladas', 'Cancelled'),
                              tint: const Color(0xFFFCE8EB), foreground: _roseDark, icon: Icons.highlight_off_rounded)),
                          ]),
                        ]), begin: 0.12),
                        const SizedBox(height: 19),
                        _reveal(_surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionTitle(t('Actividad del día', 'Today’s activity')),
                          const SizedBox(height: 15),
                          Row(children: [
                            SizedBox(width: 72, height: 72,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                                duration: const Duration(milliseconds: 850),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => Stack(alignment: Alignment.center, children: [
                                  SizedBox.expand(child: CircularProgressIndicator(
                                    value: value, backgroundColor: const Color(0xFFF5E2E6),
                                    color: _rose, strokeWidth: 6, strokeCap: StrokeCap.round)),
                                  Text('${(value * 100).round()}%', style: TextStyle(
                                    color: _dark ? _scheme.onSurface : _roseDark, fontSize: 16, fontWeight: FontWeight.w700)),
                                ]),
                              )),
                            const SizedBox(width: 17),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t('Avance de la jornada', 'Daily progress'), style: TextStyle(
                                color: _dark ? _scheme.onSurface : _ink, fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 5),
                              Text(StaffPreferences.language.value == 'en' ? '$completed of $active active appointments completed' : '$completed de $active citas activas completadas',
                                style: TextStyle(color: _dark ? _scheme.onSurfaceVariant : _muted, fontSize: 12)),
                              const SizedBox(height: 11),
                              ClipRRect(borderRadius: BorderRadius.circular(6),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                                  duration: const Duration(milliseconds: 850),
                                  builder: (_, value, __) => LinearProgressIndicator(
                                    value: value, minHeight: 7,
                                    backgroundColor: const Color(0xFFF6E6E9), color: _rose))),
                            ])),
                          ]),
                          if (pending > 0) ...[
                            const SizedBox(height: 17),
                            Material(color: _dark ? _scheme.surfaceContainerHigh : _blush, borderRadius: BorderRadius.circular(15),
                              child: InkWell(onTap: _openAppointments,
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(padding: const EdgeInsets.all(13),
                                  child: Row(children: [
                                    Icon(Icons.info_outline_rounded, color: _dark ? _scheme.primary : _roseDark, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(StaffPreferences.language.value == 'en' ? '$pending pending ${pending == 1 ? 'appointment' : 'appointments'} to accept' : '$pending ${pending == 1 ? 'cita pendiente' : 'citas pendientes'} de confirmación',
                                        style: TextStyle(color: _dark ? _scheme.onSurface : _roseDark, fontSize: 12.5,
                                          fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 3),
                                      Text(t('Revisa las solicitudes de hoy.', 'Review today’s requests.'),
                                        style: TextStyle(color: _dark ? _scheme.onSurfaceVariant : _muted, fontSize: 11.5)),
                                    ])),
                                    Icon(Icons.chevron_right_rounded, color: _dark ? _scheme.primary : _roseDark, size: 20),
                                  ])),
                              )),
                          ],
                        ])), begin: 0.20),
                        const SizedBox(height: 19),
                        _reveal(_surface(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sectionTitle(t('Próximas citas', 'Upcoming appointments'), trailing: TextButton(
                            onPressed: _openAppointments,
                            style: TextButton.styleFrom(foregroundColor: _roseDark,
                              padding: const EdgeInsets.symmetric(horizontal: 5)),
                            child: Text(t('Ver agenda', 'View schedule'), style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w700)))),
                          const SizedBox(height: 4),
                          if (visibleUpcoming.isEmpty)
                            Padding(padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text(t('No hay citas próximas para el resto del día.', 'No more appointments scheduled for today.'),
                                style: TextStyle(color: _dark ? _scheme.onSurfaceVariant : _muted, fontSize: 13)))
                          else
                            for (var i = 0; i < visibleUpcoming.length; i++) ...[
                              if (i > 0) Divider(color: _dark ? _scheme.outlineVariant : _line, height: 1),
                              _appointmentRow(visibleUpcoming[i]),
                            ],
                        ])), begin: 0.28),
                      ]),
          ),
        ]),
      ),
    );
  }
}

/// Decoración ligera dibujada con Flutter; sin assets ni dependencias nuevas.
/// Se mantiene detrás del contenido y no captura interacciones.
class _SpaWelcomePainter extends CustomPainter {
  const _SpaWelcomePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height - 23)
      ..cubicTo(size.width * 0.40, size.height - 57,
        size.width * 0.62, size.height + 18, size.width, size.height - 38)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFFEFC1CE).withValues(alpha: 0.58));

    // Flor lineal en la esquina derecha, con un tallo y hojas suaves.
    final cx = size.width - 46;
    final cy = 76.0;
    final petal = Paint()
      ..color = const Color(0xFFC9859B).withValues(alpha: 0.77)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(cx, cy);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.rotate(i * 1.25663706);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-22, -25, 0, -49)
        ..quadraticBezierTo(22, -25, 0, 0);
      canvas.drawPath(path, petal);
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 5.5,
      Paint()..color = const Color(0xFFE3A6B6).withValues(alpha: 0.7));
    canvas.restore();

    final leafPaint = Paint()
      ..color = const Color(0xFFD79CAA).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final stem = Path()
      ..moveTo(cx + 5, cy + 18)
      ..quadraticBezierTo(cx + 32, cy + 52, cx + 10, size.height - 8);
    canvas.drawPath(stem, leafPaint);
    for (final leaf in <(double, double, double)>[
      (cx + 17, cy + 43, -1), (cx + 19, cy + 72, 1),
    ]) {
      final x = leaf.$1;
      final y = leaf.$2;
      final side = leaf.$3;
      final shape = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + side * 24, y - 16,
          x + side * 32, y - 34)
        ..quadraticBezierTo(x + side * 3, y - 31, x, y);
      canvas.drawPath(shape, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpaWelcomePainter oldDelegate) => false;
}
