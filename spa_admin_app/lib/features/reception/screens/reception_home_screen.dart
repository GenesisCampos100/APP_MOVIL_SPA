import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

class ReceptionHomeScreen extends StatelessWidget {
  final VoidCallback onVerAgenda;

  const ReceptionHomeScreen({super.key, required this.onVerAgenda});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primaryPinkSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined, color: AppColors.primaryPink, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Bienvenido a Recepción',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  AuthSession.correo ?? 'Equipo Aura SPA',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consulta la agenda general y da seguimiento a las reservaciones del SPA.',
                  style: TextStyle(color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Card(
            color: AppColors.cardBackground,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: AppColors.primaryPink, size: 32),
                  const SizedBox(height: 10),
                  const Text(
                    'Agenda general',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consulta las citas de todos los especialistas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onVerAgenda,
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Abrir agenda'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryPink),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Próxima fase: crear clientes y citas manuales, confirmar, cancelar y reprogramar desde Recepción.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
