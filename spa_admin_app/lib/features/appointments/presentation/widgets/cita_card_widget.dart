import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              EstadoBadge(estado: appointment.estado),
            ],
          ),
          const SizedBox(height: 10),

          // Cliente
          Text(
            'Cliente: ${appointment.nombreCliente}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // Servicio y duración
          Text(
            'Servicio: ${appointment.nombreServicio} (${appointment.duracionAplicada})',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),

          // Botón Ver detalle
          Center(
            child: SizedBox(
              width: 140,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAEAEA),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onVerDetalle,
                child: const Text(
                  'Ver detalle',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
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
