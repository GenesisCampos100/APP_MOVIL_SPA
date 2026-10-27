import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/schedules/data/models/schedule_model.dart';

class ScheduleFormDialog extends StatefulWidget {
  final ScheduleModel? schedule; // Si es null, es modo creación (Agregar disponibilidad)
  final Function(ScheduleModel) onSave;

  const ScheduleFormDialog({
    super.key,
    this.schedule,
    required this.onSave,
  });

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  late String _selectedEmployee;
  late String _selectedPuesto;
  late List<String> _selectedDays;

  // Selector de horas estilo alarma (igual que en citas)
  late String _startHour;
  late String _startMinute;
  late String _startPeriod;

  late String _endHour;
  late String _endMinute;
  late String _endPeriod;

  late bool _estado;

  final List<String> _allDays = ['L', 'M', 'Mi', 'J', 'V', 'S'];
  final List<String> _dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

  final List<Map<String, String>> _employeesList = [
    {'nombre': 'Carlos Mendoza García', 'puesto': 'Masajista Senior'},
    {'nombre': 'Ana Sofía Torres', 'puesto': 'Cosmetóloga'},
    {'nombre': 'Zinedine Hiram Miranda Campos', 'puesto': 'Terapeuta Spa'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.schedule != null) {
      _selectedEmployee = widget.schedule!.nombreEmpleado;
      _selectedPuesto = widget.schedule!.puesto;
      _selectedDays = List.from(widget.schedule!.diasAsignados);
      _estado = widget.schedule!.estado;

      // Parse hora inicio
      final startParts = widget.schedule!.horaInicio.split(' ');
      if (startParts.length == 2) {
        _startPeriod = startParts[1];
        final timeParts = startParts[0].split(':');
        _startHour = timeParts.isNotEmpty ? timeParts[0] : '09';
        _startMinute = timeParts.length > 1 ? timeParts[1] : '00';
      } else {
        _startHour = '09';
        _startMinute = '00';
        _startPeriod = 'AM';
      }

      // Parse hora fin
      final endParts = widget.schedule!.horaFin.split(' ');
      if (endParts.length == 2) {
        _endPeriod = endParts[1];
        final timeParts = endParts[0].split(':');
        _endHour = timeParts.isNotEmpty ? timeParts[0] : '03';
        _endMinute = timeParts.length > 1 ? timeParts[1] : '00';
      } else {
        _endHour = '03';
        _endMinute = '00';
        _endPeriod = 'PM';
      }
    } else {
      _selectedEmployee = _employeesList[0]['nombre']!;
      _selectedPuesto = _employeesList[0]['puesto']!;
      _selectedDays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
      _startHour = '09';
      _startMinute = '00';
      _startPeriod = 'AM';
      _endHour = '03';
      _endMinute = '00';
      _endPeriod = 'PM';
      _estado = true;
    }
  }

  Widget _buildTimeBox(String currentValue, Function(String) onChanged, List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Text(opt),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.schedule != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.cardBorder, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Modificar horario' : 'Agregar disponibilidad',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Empleado dropdown
            const Text(
              'Empleado:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedEmployee,
                  isExpanded: true,
                  items: _employeesList.map((emp) {
                    return DropdownMenuItem<String>(
                      value: emp['nombre'],
                      child: Text(
                        '${emp['nombre']} (${emp['puesto']})',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedEmployee = val;
                        final found = _employeesList.firstWhere((e) => e['nombre'] == val);
                        _selectedPuesto = found['puesto']!;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Días de trabajo
            const Text(
              'Días de trabajo:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_allDays.length, (index) {
                final dayShort = _allDays[index];
                final dayFull = _dayNames[index];
                final isSelected = _selectedDays.contains(dayFull);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDays.remove(dayFull);
                      } else {
                        _selectedDays.add(dayFull);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPink : const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      dayShort,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Horas de inicio (selector tipo alarma)
            const Text(
              'Horas de inicio:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeBox(_startHour, (val) => setState(() => _startHour = val), ['07', '08', '09', '10', '11', '12', '01', '02', '03', '04', '05', '06']),
                const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                _buildTimeBox(_startMinute, (val) => setState(() => _startMinute = val), ['00', '15', '30', '45']),
                const SizedBox(width: 12),
                _buildTimeBox(_startPeriod, (val) => setState(() => _startPeriod = val), ['AM', 'PM']),
              ],
            ),
            const SizedBox(height: 16),

            // Horas de término (selector tipo alarma)
            const Text(
              'Horas de término:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeBox(_endHour, (val) => setState(() => _endHour = val), ['07', '08', '09', '10', '11', '12', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10']),
                const SizedBox(width: 8),
                const Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                _buildTimeBox(_endMinute, (val) => setState(() => _endMinute = val), ['00', '15', '30', '45']),
                const SizedBox(width: 12),
                _buildTimeBox(_endPeriod, (val) => setState(() => _endPeriod = val), ['AM', 'PM']),
              ],
            ),
            const SizedBox(height: 16),

            // Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estado:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Switch(
                  value: _estado,
                  activeThumbColor: AppColors.primaryPink,
                  onChanged: (val) => setState(() => _estado = val),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Botón Guardar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final horaInicioStr = '$_startHour:$_startMinute $_startPeriod';
                final horaFinStr = '$_endHour:$_endMinute $_endPeriod';

                final newSchedule = ScheduleModel(
                  idHorario: widget.schedule?.idHorario ?? '#Horario-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                  idEmpleado: '#EMP-01',
                  nombreEmpleado: _selectedEmployee,
                  puesto: _selectedPuesto,
                  turno: 'Turno: $horaInicioStr - $horaFinStr',
                  diasAsignados: _selectedDays,
                  horaInicio: horaInicioStr,
                  horaFin: horaFinStr,
                  fecha: widget.schedule?.fecha ?? DateTime(2026, 9, 25),
                  estado: _estado,
                );
                widget.onSave(newSchedule);
                Navigator.pop(context);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
