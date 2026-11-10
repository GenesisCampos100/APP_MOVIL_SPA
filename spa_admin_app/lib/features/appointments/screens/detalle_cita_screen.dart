import 'package:flutter/material.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/features/appointments/widgets/estado_badge.dart';

/// Detalle de una cita obtenida de GET /api/citas.
/// Las acciones de escritura se mantienen informativas hasta tener API real.
class DetalleCitaScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final Function(AppointmentModel) onAppointmentUpdated;

  const DetalleCitaScreen({
    super.key,
    required this.appointment,
    required this.onAppointmentUpdated,
  });

  @override
  State<DetalleCitaScreen> createState() => _DetalleCitaScreenState();
}

class _DetalleCitaScreenState extends State<DetalleCitaScreen> {
  late AppointmentModel _citaActual;
  bool _confirmando = false;
  bool _cancelando = false;
  final CitasRepository _repository = CitasRepository();

  @override
  void initState() {
    super.initState();
    _citaActual = widget.appointment;
  }

  AppointmentModel get _cita => _citaActual;

  Future<void> _solicitarCancelacion() async {
    if (_confirmando || _cancelando ||
        (_cita.estado != 'Pendiente' && _cita.estado != 'Confirmada')) {
      return;
    }
    final aceptada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text(
          '¿Deseas cancelar la cita ${_cita.idCita} de ${_cita.nombreCliente}? '
          'El registro permanecerá en el historial. Esta acción no enviará notificaciones automáticas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (aceptada == true && mounted) {
      await _ejecutarCancelacion();
    }
  }

  Future<void> _ejecutarCancelacion() async {
    if (!mounted || _confirmando || _cancelando) return;
    setState(() => _cancelando = true);
    try {
      await _repository.cancelarCita(_cita.idCita);
      if (!mounted) return;
      final actualizada = _cita.copyWith(estado: 'Cancelada');
      setState(() {
        _citaActual = actualizada;
        _cancelando = false;
      });
      widget.onAppointmentUpdated(actualizada);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita cancelada correctamente.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cancelar la cita. Verifica la conexión.')),
      );
    }
  }
  Future<void> _confirmarCita() async {
    if (_confirmando || _cita.estado != 'Pendiente') return;
    final aceptada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar cita'),
        content: Text('¿Deseas confirmar la cita ${_cita.idCita} de ${_cita.nombreCliente}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, confirmar'),
          ),
        ],
      ),
    );
    if (aceptada != true || !mounted) return;

    setState(() => _confirmando = true);
    try {
      await _repository.confirmarCita(_cita.idCita);
      if (!mounted) return;
      final citaConfirmada = _cita.copyWith(estado: 'Confirmada');
      setState(() {
        _citaActual = citaConfirmada;
        _confirmando = false;
      });
      widget.onAppointmentUpdated(citaConfirmada);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita confirmada correctamente.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo confirmar la cita. Verifica la conexión.')),
      );
    }
  }

  String _fechaLegible(DateTime fecha) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  Future<void> _accionPendiente(String accion) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primaryPink),
            SizedBox(width: 10),
            Expanded(child: Text('Función en preparación')),
          ],
        ),
        content: Text(
          'Todavía no es posible $accion desde esta pantalla. '
          'No se realizaron cambios en la cita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sinAnimaciones = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalle de cita',
          style: AppTextStyles.displayExtraBold.copyWith(color: AppColors.textDark),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: sinAnimaciones ? Duration.zero : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, progreso, child) => Opacity(
          opacity: progreso,
          child: Transform.translate(
            offset: Offset(0, sinAnimaciones ? 0 : 12 * (1 - progreso)),
            child: child,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Información de la reservación',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading2.copyWith(
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    EstadoBadge(estado: _cita.estado),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Servicio reservado',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _cita.nombreServicio,
                        style: AppTextStyles.heading2.copyWith(color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_cita.precioAplicado.toStringAsFixed(2)} MXN',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.primaryPink,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _dato(Icons.person_outline, 'Cliente', _cita.nombreCliente),
                const SizedBox(height: 14),
                _dato(Icons.badge_outlined, 'Especialista', _cita.nombreEmpleado),
                const SizedBox(height: 14),
                _dato(Icons.event_outlined, 'Fecha', _fechaLegible(_cita.fecha)),
                const SizedBox(height: 14),
                _dato(Icons.schedule_outlined, 'Hora', _cita.horaInicio),
                const SizedBox(height: 14),
                _dato(Icons.timelapse_outlined, 'Duración', _cita.duracionAplicada),
                const SizedBox(height: 18),
                const Divider(color: AppColors.cardBorder),
                const SizedBox(height: 12),
                Text(
                  'Observaciones',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    (_cita.observaciones?.trim().isNotEmpty ?? false)
                        ? _cita.observaciones!
                        : 'Sin observaciones registradas.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textDark),
                  ),
                ),
                const SizedBox(height: 18),
                if (_cita.estado == 'Pendiente')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_confirmando || _cancelando) ? null : _confirmarCita,
                      icon: _confirmando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_confirmando ? 'Confirmando...' : 'Confirmar cita'),
                    ),
                  ),
                if (_cita.estado == 'Pendiente' || _cita.estado == 'Confirmada')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_confirmando || _cancelando)
                          ? null
                          : _solicitarCancelacion,
                      icon: _cancelando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.event_busy_outlined),
                      label: Text(_cancelando ? 'Cancelando...' : 'Cancelar cita'),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Reportar inasistencia e iniciar servicio estarán disponibles próximamente.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _accionPendiente('reportar una inasistencia'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Reportar inasistencia',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _accionPendiente('iniciar el servicio'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Iniciar servicio',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String etiqueta, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primaryPinkSoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icono, color: AppColors.primaryPink, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                valor.trim().isEmpty ? 'No disponible' : valor,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
