import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/appointment_model.dart';
import 'package:spa_admin_app/data/repositories/citas_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/features/appointments/widgets/cita_card_widget.dart';
import 'package:spa_admin_app/features/appointments/screens/detalle_cita_screen.dart';

/// Agenda administrativa basada exclusivamente en GET /api/citas.
/// Los resultados dependen del usuario autenticado y de los permisos del backend.
class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final CitasRepository _repository = CitasRepository();
  List<AppointmentModel> _appointments = [];
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'Todas';
  bool _loading = true;
  bool _firstLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!AuthSession.esAdministrador || !AuthSession.activa) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Inicia sesión como Administrador para consultar las citas.';
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
        _appointments = citas;
        _loading = false;
        if (_firstLoad && citas.isNotEmpty) {
          final ahora = DateTime.now();
          final hoy = DateTime(ahora.year, ahora.month, ahora.day);
          final proximas = citas.where((c) => !c.fecha.isBefore(hoy)).toList();
          _selectedDate = proximas.isNotEmpty ? proximas.first.fecha : citas.last.fecha;
        }
        _firstLoad = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (e.statusCode) {
          401 => 'Tu sesión ya no es válida. Cierra sesión y vuelve a ingresar.',
          403 => 'No tienes permiso para consultar las citas.',
          _ => 'No se pudieron cargar las citas. Intenta nuevamente.',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las citas. Comprueba tu conexión e intenta nuevamente.';
      });
    }
  }

  String _formatDateHeader(DateTime dt) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${months[dt.month - 1]} ${dt.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<AppointmentModel> get _filteredAppointments {
    final filtro = _selectedFilter.toLowerCase();
    return _appointments.where((cita) {
      if (!_isSameDay(cita.fecha, _selectedDate)) return false;
      if (filtro == 'todas') return true;
      final estado = cita.estado.trim().toLowerCase();
      return switch (filtro) {
        'pendientes' => estado == 'pendiente',
        'confirmadas' => estado == 'confirmada',
        'completadas' => estado == 'completada',
        'en proceso' => estado == 'en proceso',
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAppointments;
    final count = _appointments.where((a) => _isSameDay(a.fecha, _selectedDate)).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Citas del negocio',
          style: AppTextStyles.displayExtraBold.copyWith(color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar citas',
            icon: const Icon(Icons.refresh, color: AppColors.primaryPink),
            onPressed: _loading ? null : _loadAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black87),
                  onPressed: () => setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  }),
                ),
                Flexible(
                  child: Text(
                    _formatDateHeader(_selectedDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black87),
                  onPressed: () => setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  }),
                ),
              ],
            ),
          ),
          Text(
            _loading || _error != null ? 'Consultando agenda...' :
                '$count ${count == 1 ? 'cita programada' : 'citas programadas'} para esta fecha',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('Todas'),
                const SizedBox(width: 8),
                _buildFilterChip('Pendientes'),
                const SizedBox(width: 8),
                _buildFilterChip('Confirmadas'),
                const SizedBox(width: 8),
                _buildFilterChip('Completadas'),
                const SizedBox(width: 8),
                _buildFilterChip('En proceso'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _loading
                  ? const Center(
                      key: ValueKey('cargando'),
                      child: CircularProgressIndicator(),
                    )
                  : _error != null
                      ? Center(
                          key: const ValueKey('error'),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off_outlined, size: 42, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _loadAppointments,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          key: const ValueKey('agenda'),
                          onRefresh: _loadAppointments,
                          child: list.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 72),
                                    Icon(Icons.event_busy_outlined, color: AppColors.textMuted, size: 44),
                                    SizedBox(height: 12),
                                    Center(child: Text('No hay citas para la fecha o filtro seleccionado.')),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  itemCount: list.length,
                                  itemBuilder: (context, index) {
                                    final cita = list[index];
                                    final sinAnimaciones =
                                        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                                    return TweenAnimationBuilder<double>(
                                      key: ValueKey(cita.idCita),
                                      tween: Tween(begin: 0, end: 1),
                                      duration: sinAnimaciones
                                          ? Duration.zero
                                          : Duration(milliseconds: 200 + (index < 4 ? index * 45 : 180)),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, progreso, child) => Opacity(
                                        opacity: progreso,
                                        child: Transform.translate(
                                          offset: Offset(0, sinAnimaciones ? 0 : 10 * (1 - progreso)),
                                          child: child,
                                        ),
                                      ),
                                      child: CitaCardWidget(
                                        appointment: cita,
                                        onVerDetalle: () => Navigator.push<void>(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => DetalleCitaScreen(
                                              appointment: cita,
                                              onAppointmentUpdated: (_) => _loadAppointments(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : const Color(0xFFFDE8EE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryPink,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
