import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/appointments/data/models/appointment_model.dart';
import 'package:spa_admin_app/features/appointments/presentation/widgets/appointment_edit_dialog.dart';
import 'package:spa_admin_app/features/appointments/presentation/widgets/appointment_cancel_dialog.dart';
import 'package:spa_admin_app/features/dashboard/presentation/screens/main_navigation_screen.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  // Lista inicial de citas según la BD y mockups de Figma para Gestionar Citas
  final List<AppointmentModel> _appointments = [
    AppointmentModel(
      idCita: '#Cita-001',
      idCliente: '#CLI-045',
      nombreCliente: 'Laura Gómez Rivas',
      nombreServicio: 'Masaje Relajante Descontracturante (60 min)',
      precioAplicado: 650.00,
      nombreEmpleado: 'Carlos Mendoza García',
      fecha: DateTime(2026, 9, 25),
      horaInicio: '10:00 AM',
      duracionAplicada: '60 min',
      estado: 'Confirmada',
      observaciones: 'Enfoque principal en zona lumbar y cuello.',
    ),
    AppointmentModel(
      idCita: '#Cita-002',
      idCliente: '#CLI-082',
      nombreCliente: 'Roberto Sánchez',
      nombreServicio: 'Facial Limpieza Profunda (45 min)',
      precioAplicado: 500.00,
      nombreEmpleado: 'Ana Sofía Torres',
      fecha: DateTime(2026, 9, 25),
      horaInicio: '11:30 AM',
      duracionAplicada: '45 min',
      estado: 'Pendiente',
      observaciones: 'Piel sensible.',
    ),
    AppointmentModel(
      idCita: '#Cita-003',
      idCliente: '#CLI-019',
      nombreCliente: 'María Elena Rodríguez',
      nombreServicio: 'Manicura y Pedicura Spa',
      precioAplicado: 450.00,
      nombreEmpleado: 'Zinedine Hiram Miranda Campos',
      fecha: DateTime(2026, 9, 25),
      horaInicio: '02:00 PM',
      duracionAplicada: '60 min',
      estado: 'Completada',
      observaciones: 'Esmaltado en gel.',
    ),
    AppointmentModel(
      idCita: '#Cita-004',
      idCliente: '#CLI-102',
      nombreCliente: 'Jorge Hernández',
      nombreServicio: 'Tratamiento Corporal Reductivo',
      precioAplicado: 800.00,
      nombreEmpleado: 'Carlos Mendoza García',
      fecha: DateTime(2026, 9, 26),
      horaInicio: '04:00 PM',
      duracionAplicada: '60 min',
      estado: 'Pendiente',
      observaciones: 'Tratamiento reductivo.',
    ),
  ];

  String _searchQuery = '';
  DateTime _selectedDate = DateTime(2026, 9, 25);
  DateTime _currentMonth = DateTime(2026, 9, 1);
  String _selectedFilter = 'Todas'; // 'Todas', 'Pendientes', 'Confirmadas', 'Completadas'
  bool _showCalendarView = true;

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'Confirmada':
        return const Color(0xFF4CAF50); // Verde
      case 'Pendiente':
        return const Color(0xFFFFC107); // Amarillo
      case 'Completada':
        return const Color(0xFF9C27B0); // Púrpura / Magenta
      case 'Cancelada':
        return const Color(0xFFF44336); // Rojo
      default:
        return Colors.grey;
    }
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${months[dt.month - 1]} ${dt.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<AppointmentModel> get _filteredAppointments {
    return _appointments.where((app) {
      final matchesDate = _isSameDay(app.fecha, _selectedDate);
      final matchesSearch = app.nombreCliente.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.idCita.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.nombreServicio.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.nombreEmpleado.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesFilter = true;
      if (_selectedFilter == 'Pendientes') {
        matchesFilter = app.estado == 'Pendiente';
      } else if (_selectedFilter == 'Confirmadas') {
        matchesFilter = app.estado == 'Confirmada';
      } else if (_selectedFilter == 'Completadas') {
        matchesFilter = app.estado == 'Completada';
      }

      return matchesDate && matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              );
            }
          },
        ),
        title: Column(
          children: [
            const Text(
              'Gestionar citas',
              style: TextStyle(
                color: Colors.black,
                fontSize: 26,
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w400,
              ),
            ),
            if (!_showCalendarView)
              const Text(
                'Citas del dia',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  _showCalendarView ? Icons.format_list_bulleted : Icons.calendar_month,
                  color: AppColors.primaryPink,
                  size: 28,
                ),
                tooltip: _showCalendarView ? 'Ver lista de citas' : 'Ver calendario',
                onPressed: () {
                  setState(() {
                    _showCalendarView = !_showCalendarView;
                  });
                },
              ),
            ),
          ),

          // Campo de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o #cita',
                suffixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: const Color(0xFFEFEFEF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Contenido principal: Calendario o Lista del día
          Expanded(
            child: _showCalendarView
                ? _buildCalendarView()
                : _buildDayAppointmentsView(),
          ),
        ],
      ),
    );
  }

  // --- VISTA 1: CALENDARIO ---
  Widget _buildCalendarView() {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOffset = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMonthYear(_currentMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.black87),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.black87),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DayHeader('D'),
              _DayHeader('L'),
              _DayHeader('M'),
              _DayHeader('M'),
              _DayHeader('J'),
              _DayHeader('V'),
              _DayHeader('S'),
            ],
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + firstDayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              final dayNum = index - firstDayOffset + 1;
              final dayDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
              final isSelected = _isSameDay(dayDate, _selectedDate);

              final dayApps = _appointments.where((a) => _isSameDay(a.fecha, dayDate)).toList();
              final hasApps = dayApps.isNotEmpty;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = dayDate;
                    _showCalendarView = false;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryPink.withValues(alpha: 0.15) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: AppColors.primaryPink, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primaryPink : Colors.black87,
                        ),
                      ),
                      if (hasApps)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayApps.take(3).map((app) {
                              return Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(app.estado),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.list_alt, color: Colors.white),
            label: Text(
              'Ver citas del ${_formatFullDate(_selectedDate)}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              setState(() {
                _showCalendarView = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // --- VISTA 2: LISTA DE CITAS DEL DÍA ---
  Widget _buildDayAppointmentsView() {
    final list = _filteredAppointments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatFullDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18, color: AppColors.primaryPink),
                label: const Text(
                  'Cambiar fecha',
                  style: TextStyle(color: AppColors.primaryPink, fontSize: 12),
                ),
                onPressed: () {
                  setState(() => _showCalendarView = true);
                },
              ),
            ],
          ),
        ),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            children: [
              _buildFilterChip('Todas'),
              const SizedBox(width: 8),
              _buildFilterChip('Pendientes'),
              const SizedBox(width: 8),
              _buildFilterChip('Confirmadas'),
              const SizedBox(width: 8),
              _buildFilterChip('Completadas'),
            ],
          ),
        ),
        const SizedBox(height: 4),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 48, color: Colors.black38),
                      const SizedBox(height: 12),
                      Text(
                        'No hay citas para esta fecha (${_formatFullDate(_selectedDate)})',
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemBuilder: (context, index) {
                    final appointment = list[index];
                    return _buildAppointmentCard(appointment);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = label);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink : const Color(0xFFFDE8EE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '[$label]',
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryPink,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                appointment.idCita,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.estado),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          const Text(
            'Cliente:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField(appointment.nombreCliente),
          const SizedBox(height: 8),

          const Text(
            'Servicio:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField(appointment.nombreServicio),
          const SizedBox(height: 8),

          const Text(
            'Especialista:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField(appointment.nombreEmpleado),
          const SizedBox(height: 8),

          const Text(
            'Hora:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField(appointment.horaInicio),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFEFEF),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AppointmentCancelDialog(
                      appointment: appointment,
                      onCancelConfirmed: () {
                        setState(() {
                          final index = _appointments.indexWhere((a) => a.idCita == appointment.idCita);
                          if (index != -1) {
                            _appointments[index] = appointment.copyWith(estado: 'Cancelada');
                          }
                        });
                      },
                    ),
                  );
                },
                child: const Text(
                  'Cancelar cita',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AppointmentEditDialog(
                      appointment: appointment,
                      onSave: (updated) {
                        setState(() {
                          final index = _appointments.indexWhere((a) => a.idCita == updated.idCita);
                          if (index != -1) {
                            _appointments[index] = updated;
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontSize: 13,
        ),
      ),
    );
  }
}
