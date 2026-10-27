import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/core/constants/app_text_styles.dart';
import 'package:spa_admin_app/features/dashboard/presentation/screens/main_navigation_screen.dart';
import 'package:spa_admin_app/features/schedules/data/models/schedule_model.dart';
import 'package:spa_admin_app/features/schedules/presentation/widgets/schedule_form_dialog.dart';
import 'package:spa_admin_app/features/schedules/presentation/widgets/schedule_delete_dialog.dart';

class ManageSchedulesScreen extends StatefulWidget {
  const ManageSchedulesScreen({super.key});

  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  final List<ScheduleModel> _schedules = [
    ScheduleModel(
      idHorario: '#H-001',
      idEmpleado: '#EMP-01',
      nombreEmpleado: 'Carlos Mendoza García',
      puesto: 'Masajista Senior',
      turno: 'Turno matutino: 09:00 AM - 03:00 PM',
      diasAsignados: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
      horaInicio: '09:00 AM',
      horaFin: '03:00 PM',
      fecha: DateTime(2026, 9, 25),
      estado: true,
    ),
    ScheduleModel(
      idHorario: '#H-002',
      idEmpleado: '#EMP-02',
      nombreEmpleado: 'Ana Sofía Torres',
      puesto: 'Cosmetóloga',
      turno: 'Turno Vespertino: 02:00 PM - 08:00 PM',
      diasAsignados: ['Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'],
      horaInicio: '02:00 PM',
      horaFin: '08:00 PM',
      fecha: DateTime(2026, 9, 25),
      estado: true,
    ),
  ];

  DateTime _selectedDate = DateTime(2026, 9, 25);
  DateTime _currentMonth = DateTime(2026, 9, 1);
  String _selectedFilter = 'Todos'; // 'Todos', 'Mañana', 'Tarde'
  bool _showCalendarView = true;

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

  List<ScheduleModel> get _filteredSchedules {
    return _schedules.where((sch) {
      final matchesDate = _isSameDay(sch.fecha, _selectedDate);
      bool matchesFilter = true;
      if (_selectedFilter == 'Mañana') {
        matchesFilter = sch.horaInicio.contains('AM') || sch.horaInicio.startsWith('09');
      } else if (_selectedFilter == 'Tarde') {
        matchesFilter = sch.horaInicio.contains('PM') && !sch.horaInicio.startsWith('09');
      }
      return matchesDate && matchesFilter;
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
            Text(
              'Gestionar horarios',
              style: AppTextStyles.displayExtraBold.copyWith(
                color: AppColors.textDark,
              ),
            ),
            if (!_showCalendarView)
              const Text(
                'Horarios asignados',
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
          // Botón superior: Agregar disponibilidad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    _showCalendarView ? Icons.format_list_bulleted : Icons.calendar_month,
                    color: AppColors.primaryPink,
                    size: 28,
                  ),
                  tooltip: _showCalendarView ? 'Ver lista' : 'Ver calendario',
                  onPressed: () => setState(() => _showCalendarView = !_showCalendarView),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ScheduleFormDialog(
                        onSave: (newSch) {
                          setState(() {
                            _schedules.add(newSch);
                            _selectedDate = newSch.fecha;
                          });
                        },
                      ),
                    );
                  },
                  child: const Text(
                    'Agregar disponibilidad',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _showCalendarView
                ? _buildCalendarView()
                : _buildSchedulesListView(),
          ),
        ],
      ),
    );
  }

  // --- VISTA 1: CALENDARIO DE HORARIOS ---
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

              final daySch = _schedules.where((s) => _isSameDay(s.fecha, dayDate)).toList();
              final hasSch = daySch.isNotEmpty;

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
                      if (hasSch)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: daySch.take(3).map<Widget>((s) {
                              return Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: s.estado ? const Color(0xFF4CAF50) : Colors.grey,
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

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Ver horarios del ${_formatFullDate(_selectedDate)}',
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

  // --- VISTA 2: LISTA DE HORARIOS ASIGNADOS ---
  Widget _buildSchedulesListView() {
    final list = _filteredSchedules;

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
              TextButton(
                child: const Text(
                  'Cambiar fecha',
                  style: TextStyle(color: AppColors.primaryPink, fontSize: 12),
                ),
                onPressed: () => setState(() => _showCalendarView = true),
              ),
            ],
          ),
        ),

        // Filtros Todos / Mañana / Tarde
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
          child: Row(
            children: [
              _buildFilterChip('Todos'),
              const SizedBox(width: 8),
              _buildFilterChip('Mañana'),
              const SizedBox(width: 8),
              _buildFilterChip('Tarde'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    'No hay horarios asignados para ${_formatFullDate(_selectedDate)}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemBuilder: (context, index) {
                    final schedule = list[index];
                    return _buildScheduleCard(schedule);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildScheduleCard(ScheduleModel schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nombre y puesto:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField('${schedule.nombreEmpleado} (${schedule.puesto})'),
          const SizedBox(height: 10),

          const Text(
            'Horario y turno:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField(schedule.turno),
          const SizedBox(height: 10),

          const Text(
            'Días asignados:',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          _buildInfoField(schedule.diasAsignados.join(', ')),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFEFEF),
                  side: BorderSide(color: AppColors.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ScheduleDeleteDialog(
                      schedule: schedule,
                      onDeleteConfirmed: () {
                        setState(() {
                          _schedules.removeWhere((s) => s.idHorario == schedule.idHorario);
                        });
                      },
                    ),
                  );
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ScheduleFormDialog(
                      schedule: schedule,
                      onSave: (updated) {
                        setState(() {
                          final i = _schedules.indexWhere((s) => s.idHorario == updated.idHorario);
                          if (i != -1) {
                            _schedules[i] = updated;
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
        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
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
