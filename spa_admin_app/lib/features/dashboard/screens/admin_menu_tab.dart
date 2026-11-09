import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/sesion_service.dart';
import '../../auth/screens/login_admin_screen.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';
import '../../services/screens/admin_manage_services_screen.dart';
import '../../services/screens/assign_services_screen.dart';
import '../../employees/screens/manage_employees_screen.dart';
import '../../schedules/screens/manage_schedules_screen.dart';

class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Título principal estilizado
              Text(
                'Más opciones',
                style: AppTextStyles.displayExtraBold.copyWith(
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // Tarjeta blanca principal
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Menú administrativo',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- SECCIÓN 1 ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sección 1: Catálogo y servicios',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildMenuOption(
                      icon: Icons.badge_outlined,
                      title: 'Gestionar servicios',
                      subtitle: 'Administrar servicios activos e inactivos, editar y reactivar.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminManageServicesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuOption(
                      icon: Icons.link,
                      title: 'Asignar servicios',
                      subtitle: 'Vincular qué empleados/terapeutas están capacitados para realizar cada servicio.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AssignServicesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // --- SECCIÓN 2 ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sección 2: Personal y Operación',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildMenuOption(
                      icon: Icons.badge,
                      title: 'Gestionar empleados',
                      subtitle: 'Dar de alta, editar información general (puesto, datos) o desactivar empleados.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageEmployeesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuOption(
                      icon: Icons.access_time_outlined,
                      title: 'Gestionar horarios',
                      subtitle: 'Definir turnos de trabajo, días laborales y bloques de descanso para el personal.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageSchedulesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildMenuOption(
                      icon: Icons.bar_chart_rounded,
                      title: 'Reportes y Estadísticas',
                      subtitle: 'Histórico de servicios top y rendimiento global.',
                      onTap: () {
                        // TODO: Implementar vista de Reportes
                      },
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    _buildMenuOption(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar sesión',
                      subtitle: 'Salir de tu cuenta de manera segura.',
                      onTap: () async {
                        final confirmar = await mostrarConfirmacion(
                          context: context,
                          titulo: '¿Deseas cerrar sesión?',
                          mensaje: 'Tendrás que ingresar nuevamente para usar Aura SPA.',
                          textoConfirmar: 'Sí, cerrar sesión',
                          icono: Icons.logout_rounded,
                        );
                        if (!context.mounted || !confirmar) return;
                        AuthSession.cerrar();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginAdminScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget reutilizable para los botones rosados del menú
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.primaryPinkSoft, // Superficie suave de las opciones
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 23, color: AppColors.primaryPink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
