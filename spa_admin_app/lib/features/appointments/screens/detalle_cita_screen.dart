import 'package:flutter/material.dart';
import 'package:spa_admin_app/features/appointments/widgets/cita_visual_components.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/features/appointments/widgets/estado_badge.dart';
import 'package:spa_admin_app/features/appointments/widgets/estado_asistencia_card.dart';
import 'package:spa_admin_app/features/appointments/widgets/reprogramar_cita_dialog.dart';

/// Detalle de una cita obtenida de GET /api/citas.
/// Confirmación, cancelación, reprogramación y cierre de atención con API real.
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
  bool _reprogramando = false;
  bool _completando = false;
  bool _reportandoInasistencia = false;
  bool _puedeReportarInasistencia = false;
  final CitasRepository _repository = CitasRepository();

  @override
  void initState() {
    super.initState();
    _citaActual = widget.appointment;
    _consultarPermisoInasistencia();
  }

  AppointmentModel get _cita => _citaActual;

  String _t(String es, String en) => StaffPreferences.tr(es, en);

  Future<void> _consultarPermisoInasistencia() async {
    if (_cita.estado != 'Confirmada') return;
    try {
      final ids = await _repository.obtenerIdsInasistenciasHabilitadas();
      if (!mounted) return;
      final id = int.tryParse(_cita.idCita.replaceFirst('#Cita-', '').trim());
      setState(() => _puedeReportarInasistencia = id != null && ids.contains(id));
    } catch (_) {
      // Backend todavía no integrado, permiso denegado o error de red:
      // no mostrar una acción que pueda aparentar funcionar.
      if (mounted) setState(() => _puedeReportarInasistencia = false);
    }
  }

  Future<void> _reportarInasistencia() async {
    if (!mounted || !_puedeReportarInasistencia ||
        _cita.estado != 'Confirmada' || _confirmando || _cancelando ||
        _completando || _reprogramando || _reportandoInasistencia) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text(_t('¿Reportar inasistencia?', 'Report a no-show?')),
        content: Text(_t(
          'Confirma que ${_cita.nombreCliente} no acudió a la cita '
          '${_cita.idCita} y que el horario reservado ya terminó. '
          'La cita quedará Cancelada. Las observaciones del cliente no se modificarán. '
          'Esta acción no podrá deshacerse desde la aplicación.',
          'Confirm that ${_cita.nombreCliente} did not attend appointment '
          '${_cita.idCita} and that the reserved time has ended. '
          'The appointment will be Cancelled. Customer notes will not be changed. '
          'This action cannot be undone in the app.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false),
              child: Text(_t('Volver', 'Back'))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogo, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFAD5965)),
            icon: const Icon(Icons.person_off_outlined),
            label: Text(_t('Sí, reportar', 'Yes, report')),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;
    setState(() => _reportandoInasistencia = true);
    try {
      await _repository.reportarInasistencia(_cita.idCita);
      if (!mounted) return;
      final actualizada = _cita.copyWith(estado: 'Cancelada');
      setState(() {
        _citaActual = actualizada;
        _puedeReportarInasistencia = false;
      });
      widget.onAppointmentUpdated(actualizada);
      mostrarAvisoCita(context, _t('Ausencia registrada: cita Cancelada. Observaciones intactas.', 'No-show recorded: appointment Cancelled. Customer notes unchanged.'),
          tipo: CitaAvisoTipo.advertencia);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarAvisoCita(context, e.message, tipo: CitaAvisoTipo.error);
      await _consultarPermisoInasistencia();
    } catch (_) {
      if (!mounted) return;
      mostrarAvisoCita(context,
          _t('No se pudo registrar la inasistencia. Verifica la conexión.', 'Could not report the no-show. Check your connection.'),
          tipo: CitaAvisoTipo.error);
    } finally {
      if (mounted) setState(() => _reportandoInasistencia = false);
    }
  }


  Future<void> _solicitarCancelacion() async {
    if (_confirmando || _cancelando || _completando ||
        (_cita.estado != 'Pendiente' && _cita.estado != 'Confirmada')) {
      return;
    }
    final aceptada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('Cancelar cita', 'Cancel appointment')),
        content: Text(_t(
          '¿Deseas cancelar la cita ${_cita.idCita} de ${_cita.nombreCliente}? '
          'El registro permanecerá en el historial y el horario quedará disponible. '
          'Esta acción no enviará notificaciones automáticas.',
          'Cancel appointment ${_cita.idCita} for ${_cita.nombreCliente}? '
          'The record will remain in the history and the time slot will become available. '
          'This action will not send automatic notifications.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Volver', 'Back')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB83E4F)),
            child: Text(_t('Sí, cancelar', 'Yes, cancel')),
          ),
        ],
      ),
    );
    if (aceptada == true && mounted) {
      await _ejecutarCancelacion();
    }
  }

  Future<void> _ejecutarCancelacion() async {
    if (!mounted || _confirmando || _cancelando || _completando) return;
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
      if (mounted) setState(() => _puedeReportarInasistencia = false);
      mostrarAvisoCita(context, _t('Cita cancelada correctamente.', 'Appointment cancelled successfully.'), tipo: CitaAvisoTipo.error);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      mostrarAvisoCita(context, e.message, tipo: CitaAvisoTipo.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      mostrarAvisoCita(context, _t('No se pudo cancelar la cita. Verifica la conexión.', 'Could not cancel the appointment. Check your connection.'),
          tipo: CitaAvisoTipo.error);
    }
  }
  Future<void> _confirmarCita() async {
    if (_confirmando || _completando || _cita.estado != 'Pendiente') return;
    final aceptada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('¿Aceptar esta solicitud?', 'Accept this request?')),
        content: Text(_t(
          '¿Deseas aceptar la cita ${_cita.idCita} de ${_cita.nombreCliente}? '
          'Se mostrará como Confirmada al cliente, pero esto no significa que ya confirmó su asistencia.',
          'Accept appointment ${_cita.idCita} for ${_cita.nombreCliente}? '
          'The customer will see it as Confirmed, but this does not mean they confirmed attendance.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Volver', 'Back')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF237A51)),
            child: Text(_t('Sí, aceptar', 'Yes, accept')),
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
      await _consultarPermisoInasistencia();
      mostrarAvisoCita(context, _t('Solicitud aceptada. La asistencia se confirma por separado.', 'Request accepted. Attendance is confirmed separately.'),
          tipo: CitaAvisoTipo.exito);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      mostrarAvisoCita(context, e.message, tipo: CitaAvisoTipo.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      mostrarAvisoCita(context, _t('No se pudo aceptar la solicitud. Verifica la conexión.', 'Could not accept the request. Check your connection.'),
          tipo: CitaAvisoTipo.error);
    }
  }

  Future<void> _reprogramarCita() async {
    if (_confirmando || _cancelando || _completando || _reprogramando ||
        (_cita.estado != 'Pendiente' && _cita.estado != 'Confirmada')) return;
    final id = int.tryParse(_cita.idCita.replaceFirst('#Cita-', '').trim());
    if (id == null || id <= 0) return;
    setState(() => _reprogramando = true);
    try {
      final resultado = await showDialog<ReprogramacionResultado>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ReprogramarCitaDialog(idCita: id),
      );
      if (!mounted) return;
      if (resultado != null) {
        final nueva = _cita.copyWith(
          fecha: resultado.fecha,
          horaInicio: resultado.hora,
          nombreEmpleado: resultado.especialista,
          estado: resultado.estado,
          invalidarDatosAsistencia: true,
        );
        setState(() { _citaActual = nueva; _puedeReportarInasistencia = false; });
        widget.onAppointmentUpdated(nueva);
        mostrarAvisoCita(context, _t('Cita reprogramada. Quedó Pendiente de aceptación; la confirmación de asistencia anterior ya no aplica.', 'Appointment rescheduled and Pending acceptance. Previous attendance confirmation no longer applies.'),
            tipo: CitaAvisoTipo.advertencia);
      }
    } finally {
      if (mounted) setState(() => _reprogramando = false);
    }
  }

  String _fechaLegible(DateTime fecha) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    if (StaffPreferences.language.value == 'en') {
      return MaterialLocalizations.of(context).formatMediumDate(fecha);
    }
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  Future<void> _completarCita() async {
    if (!mounted || _completando || _confirmando || _cancelando || _reprogramando ||
        _reportandoInasistencia || _cita.estado != 'Confirmada') return;
    final aceptada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('¿Marcar cita como completada?', 'Mark appointment as completed?')),
        content: Text(_t(
          'Confirma que el servicio de ${_cita.nombreCliente} ya se realizó. '
          'Solo puede completarse una cita Confirmada después de terminar su horario reservado. '
          'Esta acción no se puede deshacer desde la aplicación.',
          'Confirm that the service for ${_cita.nombreCliente} has been performed. '
          'Only Confirmed appointments can be completed after the reserved time ends. '
          'This action cannot be undone in the app.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Volver', 'Back')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.task_alt),
            label: Text(_t('Sí, completar', 'Yes, complete')),
          ),
        ],
      ),
    );
    if (!mounted || aceptada != true) return;
    setState(() => _completando = true);
    try {
      await _repository.completarCita(_cita.idCita);
      if (!mounted) return;
      final actualizada = _cita.copyWith(estado: 'Completada');
      setState(() => _citaActual = actualizada);
      widget.onAppointmentUpdated(actualizada);
      if (mounted) setState(() => _puedeReportarInasistencia = false);
      mostrarAvisoCita(context, _t('Cita completada correctamente.', 'Appointment completed successfully.'),
          tipo: CitaAvisoTipo.exito);
    } on ApiException catch (e) {
      if (!mounted) return;
      mostrarAvisoCita(context, e.message, tipo: CitaAvisoTipo.error);
    } catch (_) {
      if (!mounted) return;
      mostrarAvisoCita(context, _t('No se pudo completar la cita. Revisa la conexión.', 'Could not complete the appointment. Check your connection.'),
          tipo: CitaAvisoTipo.error);
    } finally {
      if (mounted) setState(() => _completando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sinAnimaciones = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: AdminVisual.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: _t('Volver', 'Back'),
          icon: Icon(Icons.arrow_back_ios, color: AdminVisual.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Detalle de cita', 'Appointment details'),
          style: AppTextStyles.displayExtraBold.copyWith(color: AdminVisual.textDark),
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
              color: AdminVisual.cardBackground,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AdminVisual.cardBorder),
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
                        _t('Información de la reservación', 'Booking information'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading2.copyWith(
                          color: AdminVisual.textDark,
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
                    color: AdminVisual.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Servicio reservado', 'Booked service'),
                        style: TextStyle(fontSize: 12, color: AdminVisual.textMuted),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _cita.nombreServicio,
                        style: AppTextStyles.heading2.copyWith(color: AdminVisual.textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${_cita.precioAplicado.toStringAsFixed(2)} MXN',
                        style: AppTextStyles.heading1.copyWith(
                          color: AdminVisual.primaryPink,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _dato(Icons.person_outline, _t('Cliente', 'Customer'), _cita.nombreCliente),
                const SizedBox(height: 14),
                _dato(Icons.badge_outlined, _t('Especialista', 'Specialist'), _cita.nombreEmpleado),
                const SizedBox(height: 14),
                _dato(Icons.event_outlined, _t('Fecha', 'Date'), _fechaLegible(_cita.fecha)),
                const SizedBox(height: 14),
                _dato(Icons.schedule_outlined, _t('Hora', 'Time'), _cita.horaInicio),
                const SizedBox(height: 14),
                _dato(Icons.timelapse_outlined, _t('Duración', 'Duration'), _cita.duracionAplicada),
                if (_cita.estado == 'Confirmada') ...[
                  const SizedBox(height: 18),
                  EstadoAsistenciaCard(
                    datosDisponibles: _cita.datosAsistenciaDisponibles,
                    fechaConfirmacion: _cita.fechaConfirmacion,
                    fechaLimite: _cita.fechaLimite,
                  ),
                ],
                const SizedBox(height: 18),
                Divider(color: AdminVisual.cardBorder),
                const SizedBox(height: 12),
                Text(
                  _t('Observaciones', 'Notes'),
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminVisual.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminVisual.fieldBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    (_cita.observaciones?.trim().isNotEmpty ?? false)
                        ? _cita.observaciones!
                        : _t('Sin observaciones registradas.', 'No notes recorded.'),
                    style: AppTextStyles.caption.copyWith(color: AdminVisual.textDark),
                  ),
                ),
                const SizedBox(height: 18),
                if (_cita.estado == 'Pendiente')
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_confirmando || _cancelando || _reprogramando || _completando) ? null : _confirmarCita,
                      icon: _confirmando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_confirmando ? _t('Aceptando...', 'Accepting...') : _t('Aceptar solicitud', 'Accept request')),
                    ),
                  ),
                if (_cita.estado == 'Pendiente' || _cita.estado == 'Confirmada') ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_confirmando || _cancelando || _reprogramando || _completando)
                          ? null : _reprogramarCita,
                      icon: const Icon(Icons.event_repeat_outlined),
                      label: Text(_t('Reprogramar cita', 'Reschedule appointment')),
                    ),
                  ),
                ],
                if (_cita.estado == 'Pendiente' || _cita.estado == 'Confirmada')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_confirmando || _cancelando || _reprogramando || _completando)
                          ? null
                          : _solicitarCancelacion,
                      icon: _cancelando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.event_busy_outlined),
                      label: Text(_cancelando ? _t('Cancelando...', 'Cancelling...') : _t('Cancelar cita', 'Cancel appointment')),
                    ),
                  ),
                if (_cita.estado == 'Confirmada') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_confirmando || _cancelando || _reprogramando || _completando)
                          ? null : _completarCita,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF27804F)),
                      icon: _completando
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.task_alt),
                      label: Text(_completando ? _t('Guardando...', 'Saving...') : _t('Marcar como completada', 'Mark as completed')),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t('Solo al finalizar el servicio. El servidor validará la hora.',
                       'Only after the service ends. The server will verify the time.'),
                    style: TextStyle(fontSize: 11, color: AdminVisual.textMuted),
                  ),
                  if (_puedeReportarInasistencia) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (_reportandoInasistencia || _confirmando ||
                                _cancelando || _completando || _reprogramando)
                            ? null : _reportarInasistencia,
                        icon: _reportandoInasistencia
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.person_off_outlined),
                        label: Text(_reportandoInasistencia
                            ? _t('Registrando...', 'Reporting...') : _t('Reportar inasistencia', 'Report no-show')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFAD5965),
                          side: const BorderSide(color: Color(0xFFE2B7C0)),
                        ),
                      ),
                    ),
                    Text(
                      _t('Solo si el cliente no acudió y el horario terminó.',
                         'Only if the customer did not attend and the reserved time has ended.'),
                      style: TextStyle(fontSize: 11, color: AdminVisual.textMuted),
                    ),
                  ],
                ],
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
            color: AdminVisual.primaryPinkSoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icono, color: AdminVisual.primaryPink, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                valor.trim().isEmpty ? _t('No disponible', 'Unavailable') : valor,
                style: AppTextStyles.body.copyWith(
                  color: AdminVisual.textDark,
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
