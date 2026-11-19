import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'estado_badge.dart';

/// Tarjeta reutilizable para la agenda, con información real de la API.
/// No realiza escrituras ni cambia estados de citas.
class CitaCardWidget extends StatefulWidget {
  final AppointmentModel appointment;
  final VoidCallback onVerDetalle;
  final VoidCallback? onEditar;
  final VoidCallback? onCancelar;

  const CitaCardWidget({
    super.key,
    required this.appointment,
    required this.onVerDetalle,
    this.onEditar,
    this.onCancelar,
  });

  @override
  State<CitaCardWidget> createState() => _CitaCardWidgetState();
}

class _CitaCardWidgetState extends State<CitaCardWidget> {
  bool _presionada = false;

  @override
  Widget build(BuildContext context) {
    final cita = widget.appointment;
    final sinAnimaciones = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedScale(
      scale: _presionada && !sinAnimaciones ? 0.985 : 1,
      duration: sinAnimaciones ? Duration.zero : const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onVerDetalle,
          onTapDown: (_) => setState(() => _presionada = true),
          onTapCancel: () => setState(() => _presionada = false),
          onTapUp: (_) => setState(() => _presionada = false),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPinkSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 17, color: AppColors.primaryPink),
                          const SizedBox(height: 3),
                          Text(
                            cita.horaInicio,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cita.nombreServicio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cita.idCita,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(child: EstadoBadge(estado: cita.estado)),
                  ],
                ),
                const SizedBox(height: 14),
                _dato(Icons.person_outline, cita.nombreCliente),
                const SizedBox(height: 6),
                _dato(Icons.badge_outlined, cita.nombreEmpleado),
                const SizedBox(height: 6),
                _dato(Icons.timelapse_outlined, cita.duracionAplicada),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.cardBorder),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: widget.onVerDetalle,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Ver detalle'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primaryPink),
                    ),
                    const Spacer(),
                    if (widget.onEditar != null)
                      IconButton(
                        tooltip: 'Editar cita (próximamente)',
                        onPressed: widget.onEditar,
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.textMuted,
                      ),
                    if (widget.onCancelar != null)
                      IconButton(
                        tooltip: 'Cancelar cita (próximamente)',
                        onPressed: widget.onCancelar,
                        icon: const Icon(Icons.event_busy_outlined),
                        color: AppColors.textMuted,
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

  Widget _dato(IconData icono, String valor) {
    return Row(
      children: [
        Icon(icono, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor.trim().isEmpty ? 'Dato no disponible' : valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}
