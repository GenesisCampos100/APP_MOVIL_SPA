import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Panel inicial del empleado. Sin métricas o citas ficticias.
class EmployeeHomeScreen extends StatelessWidget {
  final VoidCallback onVerCitas;
  const EmployeeHomeScreen({super.key, required this.onVerCitas});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.spa_outlined, color: AppColors.primaryPink, size: 54),
          const SizedBox(height: 12),
          Text('Bienvenido al equipo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          Text(AuthSession.correo ?? 'Personal del SPA',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 28),
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.event_note_outlined,
                      color: AppColors.primaryPink, size: 34),
                  const SizedBox(height: 12),
                  const Text('Mi agenda',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Consulta las citas que el SPA te ha asignado.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onVerCitas,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Ver mis citas'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
