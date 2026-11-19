import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';

/// Solo muestra la información que la API proporciona de forma verificable.
/// NO confirma asistencia ni hace solicitudes a servicios nuevos.
class EstadoAsistenciaCard extends StatelessWidget {
  const EstadoAsistenciaCard({
    super.key,
    required this.datosDisponibles,
    this.fechaConfirmacion,
    this.fechaLimite,
    this.onRegistrarRespuesta,
    this.registrandoRespuesta = false,
  });

  final bool datosDisponibles;
  final DateTime? fechaConfirmacion;
  final DateTime? fechaLimite;
  // Solo Recepcion recibe el callback. Administrador permanece en lectura.
  final VoidCallback? onRegistrarRespuesta;
  final bool registrandoRespuesta;

  String _t(String es, String en) => StaffPreferences.tr(es, en);

  String _fechaHora(DateTime fecha) {
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');
    final preposicion = _t('a las', 'at');
    return '$dia/$mes/${local.year} $preposicion $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final confirmada = fechaConfirmacion != null && datosDisponibles;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final titulo = !datosDisponibles
        ? _t('Información todavía no disponible', 'Information not available yet')
        : confirmada
            ? _t('Asistencia confirmada', 'Attendance confirmed')
            : _t('Asistencia aún no registrada', 'Attendance not recorded yet');
    final descripcion = !datosDisponibles
        ? _t(
            'El servidor aún no incluye la confirmación de asistencia en esta consulta. '
            'La reservación aceptada no implica que el cliente ya respondió.',
            'The server does not yet include attendance confirmation in this response. '
            'An accepted booking does not mean the customer has responded.')
        : confirmada
            ? _t('El cliente confirmó que asistirá. Fecha del registro: '
                  '${_fechaHora(fechaConfirmacion!)}.',
                 'The customer confirmed attendance. Recorded on '
                  '${_fechaHora(fechaConfirmacion!)}.')
            : _t(
                'La reservación está aceptada, pero todavía no hay una respuesta '
                'de asistencia registrada.',
                'The booking is accepted, but no attendance response has been recorded.');
    final color = dark
        ? (confirmada ? const Color(0xFFA4E9C3) : const Color(0xFFF4C0D3))
        : (confirmada ? const Color(0xFF25724F) : AppColors.primaryPink);
    final fondo = dark
        ? (confirmada ? const Color(0xFF244237) : const Color(0xFF503744))
        : (confirmada ? const Color(0xFFF0F8F2) : AppColors.primaryPinkSoft);
    final texto = dark ? const Color(0xFFFFEFF5) : AppColors.textDark;
    final tenue = dark ? const Color(0xFFD5C0CC) : AppColors.textMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(confirmada ? Icons.verified_outlined : Icons.event_available_outlined,
                size: 21, color: color),
            const SizedBox(width: 9),
            Expanded(child: Text(_t('Confirmación de asistencia', 'Attendance confirmation'),
                style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700, color: texto))),
          ]),
          const SizedBox(height: 10),
          Text(titulo, style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 5),
          Text(descripcion, style: AppTextStyles.caption.copyWith(
              color: texto)),
          if (datosDisponibles && !confirmada && onRegistrarRespuesta != null) ...[
            const SizedBox(height: 11),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: registrandoRespuesta ? null : onRegistrarRespuesta,
                icon: registrandoRespuesta
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.phone_in_talk_outlined, size: 18),
                label: Text(registrandoRespuesta
                    ? _t('Registrando respuesta...', 'Recording response...')
                    : _t('Registrar confirmación verbal', 'Record verbal confirmation')),
              ),
            ),
            Text(_t('Únicamente si el cliente confirmó por teléfono o presencialmente.', 'Only if the customer confirmed by phone or in person.'),
                style: AppTextStyles.caption.copyWith(color: tenue)),
          ],
          if (datosDisponibles && !confirmada && fechaLimite != null) ...[
            const SizedBox(height: 8),
            Text(_t('Fecha límite indicada por el servidor: ${_fechaHora(fechaLimite!)}', 'Server-provided deadline: ${_fechaHora(fechaLimite!)}'),
                style: AppTextStyles.caption.copyWith(color: tenue)),
          ],
        ],
      ),
    );
  }
}
