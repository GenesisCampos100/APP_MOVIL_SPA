import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/core/constants/app_text_styles.dart';

class EstadoBadge extends StatelessWidget {
  final String estado; // 'Confirmada', 'En proceso', 'Pendiente', 'Completada', 'Cancelada'

  const EstadoBadge({
    super.key,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;

    switch (estado) {
      case 'Confirmada':
        bgColor = AppColors.statusConfirmada;
        break;
      case 'En proceso':
        bgColor = AppColors.statusEnProceso;
        break;
      case 'Pendiente':
        bgColor = AppColors.statusPendiente;
        break;
      case 'Completada':
        bgColor = AppColors.statusCompletada;
        break;
      case 'Cancelada':
        bgColor = AppColors.statusCancelada;
        break;
      default:
        bgColor = AppColors.statusPendiente;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
