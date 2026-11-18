import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/core/constants/app_text_styles.dart';
import '../../data/models/appointment_model.dart';
import 'estado_badge.dart';

class CitaCardWidget extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onVerDetalle;

  const CitaCardWidget({
    super.key,
    required this.appointment,
    required this.onVerDetalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora y Badge de estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appointment.horaInicio,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMedium,
                ),
              ),
              EstadoBadge(estado: appointment.estado),
            ],
          ),
          const SizedBox(height: 10),

          // Cliente
          Text(
            'Cliente: ${appointment.nombreCliente}',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),

          // Servicio y duración
          Text(
            'Servicio: ${appointment.nombreServicio} (${appointment.duracionAplicada})',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 14),

          // Botón Ver detalle
          Center(
            child: SizedBox(
              width: 140,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.secondaryButton,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onVerDetalle,
                child: Text(
                  'Ver detalle',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
