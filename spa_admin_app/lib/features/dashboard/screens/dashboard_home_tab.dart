import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/appointments/screens/mis_citas_screen.dart';

/// Dashboard administrativo: no contiene citas ni métricas de ejemplo.
class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  final CitasRepository _repository = CitasRepository();
  List<AppointmentModel> _citas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!AuthSession.esAdministrador || !AuthSession.activa) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Inicia sesión como Administrador para ver el resumen.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final citas = await _repository.obtenerCitas();
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (e.statusCode) {
          401 => 'Tu sesión ha finalizado. Cierra sesión y vuelve a ingresar.',
          403 => 'No tienes permiso para consultar las citas.',
          _ => 'No fue posible consultar el resumen de citas.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo conectar con la API de Aura SPA.';
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasStatus(AppointmentModel cita, String status) =>
      cita.estado.trim().toLowerCase() == status;

  DateTime? _appointmentStart(AppointmentModel cita) {
    final partes = cita.horaInicio.split(':');
    if (partes.length < 2) return null;
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null || hora < 0 || hora > 23 || minuto < 0 || minuto > 59) {
      return null;
    }
    return DateTime(cita.fecha.year, cita.fecha.month, cita.fecha.day, hora, minuto);
  }

  AppointmentModel? get _nextAppointment {
    final ahora = DateTime.now();
    for (final cita in _citas) {
      if (_hasStatus(cita, 'cancelada') || _hasStatus(cita, 'completada')) {
        continue;
      }
      final fechaHora = _appointmentStart(cita);
      if (fechaHora != null && !fechaHora.isBefore(ahora)) return cita;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${date.day} ${meses[date.month - 1]} ${date.year}';
  }

  void _openAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const MisCitasScreen()),
    ).then((_) {
      if (mounted) _loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final hoy = _citas.where((c) => _sameDay(c.fecha, ahora)).length;
    final pendientes = _citas.where((c) => _hasStatus(c, 'pendiente')).length;
    final completadas = _citas.where((c) => _hasStatus(c, 'completada')).length;
    final canceladas = _citas.where((c) => _hasStatus(c, 'cancelada')).length;
    final siguiente = _nextAppointment;

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TU ESPACIO DE TRABAJO',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dashboard admin',
              style: AppTextStyles.displayExtraBold.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Resumen operativo y métricas principales:',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPinkSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.spa_outlined, color: AppColors.primaryPink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hola, Admin', style: AppTextStyles.heading1.copyWith(color: AppColors.textDark)),
                        Text('Qué gusto tenerte de vuelta', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 21,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_outline, color: AppColors.primaryPink),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardHeader(Icons.today_outlined, 'Agenda del día'),
                  const SizedBox(height: 10),
                  Text(
                    _loading || _error != null
                        ? 'Consulta las citas reales del negocio.'
                        : hoy == 1 ? 'Hay 1 cita programada para hoy.' : 'Hay $hoy citas programadas para hoy.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month_outlined, size: 19),
                      label: const Text('Ver citas'),
                      onPressed: _openAppointments,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _loading
                  ? _buildCard(
                      key: const ValueKey('loading'),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : _error != null
                      ? _buildCard(
                          key: const ValueKey('error'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _cardHeader(Icons.wifi_off_outlined, 'No se pudo cargar el resumen'),
                              const SizedBox(height: 10),
                              Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _loadSummary,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          key: const ValueKey('real_data'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _cardHeader(Icons.event_available_outlined, 'Siguiente cita'),
                                  const SizedBox(height: 12),
                                  Text(
                                    siguiente == null
                                        ? 'No hay citas próximas registradas.'
                                        : '${siguiente.nombreServicio} · ${_formatDate(siguiente.fecha)} · ${siguiente.horaInicio}',
                                    style: AppTextStyles.subtitle.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (siguiente != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cliente: ${siguiente.nombreCliente} · Especialista: ${siguiente.nombreEmpleado}',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    onPressed: _openAppointments,
                                    icon: const Icon(Icons.visibility_outlined, size: 19),
                                    label: const Text('Consultar agenda'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryPink,
                                      side: const BorderSide(color: AppColors.cardBorder),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _cardHeader(Icons.insights_outlined, 'Resumen de citas'),
                                  const SizedBox(height: 14),
                                  _MetricRow(icon: Icons.calendar_today_outlined, text: 'Citas totales: ${_citas.length}'),
                                  const SizedBox(height: 12),
                                  _MetricRow(icon: Icons.pending_actions_outlined, text: 'Pendientes: $pendientes'),
                                  const SizedBox(height: 12),
                                  _MetricRow(icon: Icons.check_circle_outline, text: 'Completadas: $completadas'),
                                  const SizedBox(height: 12),
                                  _MetricRow(icon: Icons.cancel_outlined, text: 'Canceladas: $canceladas'),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryPinkSoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryPink, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTextStyles.heading2.copyWith(color: AppColors.textDark)),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child, Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
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
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryPinkSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryPink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
