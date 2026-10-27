import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/core/constants/app_text_styles.dart';
import 'package:spa_admin_app/features/appointments/presentation/screens/mis_citas_screen.dart';

class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // 1. Título principal estilo elegante
          Text(
            'Dashboard admin',
            style: AppTextStyles.displayExtraBold.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen operativo y métricas principales:',
            style: AppTextStyles.caption.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // 2. Tarjeta 1: Hola, Admin
          _buildCard(
            child: Column(
              children: [
                Text(
                  'Hola, Admin',
                  style: AppTextStyles.heading1.copyWith(color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(
                      Icons.notifications_none_outlined,
                      size: 28,
                      color: Colors.black87,
                    ),
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFE0E0E0),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.black87,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Tarjeta botón acceso directo a "Mis citas" del día
          _buildCard(
            child: Column(
              children: [
                Text(
                  'Agenda del día',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consulte e inicie las citas asignadas para hoy.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MisCitasScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: Text(
                      'Ver mis citas',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Tarjeta 2: Siguiente Cita
          _buildCard(
            child: Column(
              children: [
                Text(
                  'Siguiente cita:',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.textDark, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masaje relajante - 4:00 PM',
                  style: AppTextStyles.body.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  '(Cliente: Maria G.)',
                  style: AppTextStyles.caption.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MisCitasScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'Iniciar servicio',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Tarjeta 3: Métricas
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _MetricRow(
                    icon: Icons.calendar_today_outlined,
                    text: 'Citas Totales: 18',
                  ),
                  SizedBox(height: 10),
                  _MetricRow(
                    icon: Icons.check,
                    text: 'Completadas: 14',
                  ),
                  SizedBox(height: 10),
                  _MetricRow(
                    icon: Icons.close,
                    text: 'Canceladas: 2',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetricRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
