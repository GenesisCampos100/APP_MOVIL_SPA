import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/appointments/data/models/appointment_model.dart';
import 'package:spa_admin_app/features/appointments/presentation/widgets/cita_card_widget.dart';
import 'package:spa_admin_app/features/appointments/presentation/screens/detalle_cita_screen.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final List<AppointmentModel> _appointments = [
    AppointmentModel(
      idCita: '#Cita-001',
      idCliente: '#CLI-045',
      nombreCliente: 'Laura Gómez Rivas',
      nombreServicio: 'Masaje relajante descontracturante',
      precioAplicado: 650.00,
      nombreEmpleado: 'Carlos Mendoza García',
      fecha: DateTime(2026, 9, 25),
      horaInicio: '09:00 AM - 10:00 AM',
      duracionAplicada: '60 min',
      estado: 'Confirmada',
      observaciones: 'Enfoque principal en zona lumbar y cuello. Evitar aceites con aroma a lavanda por sensibilidad. Presión media-alta.',
    ),
    AppointmentModel(
      idCita: '#Cita-002',
      idCliente: '#CLI-082',
      nombreCliente: 'Roberto Sánchez',
      nombreServicio: 'Facial Limpieza Profunda',
      precioAplicado: 500.00,
      nombreEmpleado: 'Ana Sofía Torres',
      fecha: DateTime(2026, 9, 25),
      horaInicio: '11:30 AM - 12:30 PM',
      duracionAplicada: '45 min',
      estado: 'En proceso',
      observaciones: 'Piel sensible. Usar productos hipoalergénicos.',
    ),
    AppointmentModel(
      idCita: '#Cita-003',
      idCliente: '#CLI-019',
      nombreCliente: 'María Elena Rodríguez',
      nombreServicio: 'Manicura y Pedicura Spa',
      precioAplicado: 450.00,
      nombreEmpleado: 'Zinedine Hiram Miranda Campos',
      fecha: DateTime(2026, 9, 25),
      horaInicio: '02:00 PM - 03:00 PM',
      duracionAplicada: '60 min',
      estado: 'Pendiente',
      observaciones: 'Esmaltado en gel.',
    ),
  ];

  DateTime _selectedDate = DateTime(2026, 9, 25);
  String _selectedFilter = 'Todas';

  String _formatDateHeader(DateTime dt) {
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
      bool matchesFilter = true;
      if (_selectedFilter == 'Pendientes') {
        matchesFilter = app.estado == 'Pendiente';
      } else if (_selectedFilter == 'Confirmadas') {
        matchesFilter = app.estado == 'Confirmada';
      } else if (_selectedFilter == 'Completadas') {
        matchesFilter = app.estado == 'Completada';
      } else if (_selectedFilter == 'En proceso') {
        matchesFilter = app.estado == 'En proceso';
      }
      return matchesDate && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAppointments;

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
        title: const Text(
          'Mis citas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: Column(
        children: [
          // Selector de fecha estilo < 25 de Septiembre 2026 >
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  _formatDateHeader(_selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black87),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  },
                ),
              ],
            ),
          ),

          Text(
            '${_appointments.where((a) => _isSameDay(a.fecha, _selectedDate)).length} citas programadas para hoy',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No hay citas programadas para esta fecha.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final appointment = list[index];
                      return CitaCardWidget(
                        appointment: appointment,
                        onVerDetalle: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalleCitaScreen(
                                appointment: appointment,
                                onAppointmentUpdated: (updatedApp) {
                                  setState(() {
                                    final i = _appointments.indexWhere((a) => a.idCita == updatedApp.idCita);
                                    if (i != -1) {
                                      _appointments[i] = updatedApp;
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
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
          color: isSelected ? const Color(0xFFF731C6) : const Color(0xFFFDE8EE),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '[$label]',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFF731C6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
