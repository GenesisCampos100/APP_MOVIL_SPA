import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/employee_model.dart';

/// Tarjeta con la misma distribución visual del catálogo administrativo.
/// No contiene datos de demostración ni realiza solicitudes a la API.
class EmployeeCardWidget extends StatelessWidget {
  final EmployeeModel empleado;
  final bool actualizando;
  final bool accionesDisponibles;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  const EmployeeCardWidget({
    super.key,
    required this.empleado,
    required this.actualizando,
    required this.accionesDisponibles,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final activo = empleado.estado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  empleado.nombreCompleto,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activo
                      ? const Color(0xFFEAF7EC)
                      : const Color(0xFFF0EFF1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activo ? 'Activo' : 'Inactivo',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: activo
                        ? const Color(0xFF297D4A)
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            empleado.puesto.isEmpty ? 'Sin puesto asignado' : empleado.puesto,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (empleado.correo.isNotEmpty) ...[
            _dato(Icons.mail_outline_rounded, empleado.correo),
            const SizedBox(height: 7),
          ],
          if (empleado.telefono.isNotEmpty)
            _dato(Icons.phone_outlined, empleado.telefono),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: accionesDisponibles ? onEditar : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPink,
                  side: const BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Editar'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: accionesDisponibles ? onCambiarEstado : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  icon: actualizando
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          activo
                              ? Icons.pause_circle_outline
                              : Icons.restore_rounded,
                          size: 18,
                        ),
                  label: Text(activo ? 'Desactivar' : 'Reactivar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.primaryPink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
