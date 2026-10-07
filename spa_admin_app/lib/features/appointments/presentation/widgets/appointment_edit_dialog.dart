import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/appointments/data/models/appointment_model.dart';

class AppointmentEditDialog extends StatefulWidget {
  final AppointmentModel appointment;
  final Function(AppointmentModel) onSave;

  const AppointmentEditDialog({
    super.key,
    required this.appointment,
    required this.onSave,
  });

  @override
  State<AppointmentEditDialog> createState() => _AppointmentEditDialogState();
}

class _AppointmentEditDialogState extends State<AppointmentEditDialog> {
  late String _serviceName;
  late String _specialistName;
  late DateTime _selectedDate;
  late String _hour;
  late String _minute;
  late String _period;
  late String _status;

  final List<String> _servicesList = [
    'Masaje Relajante Descontracturante (\$650.00)',
    'Facial Limpieza Profunda (\$500.00)',
    'Manicura y Pedicura Spa (\$450.00)',
    'Tratamiento Corporal Reductivo (\$800.00)',
  ];

  final List<String> _specialistsList = [
    'Carlos Mendoza García',
    'Ana Sofía Torres',
    'Zinedine Hiram Miranda Campos',
    'María Elena Rodríguez',
  ];

  final List<String> _statusList = [
    'Pendiente',
    'Confirmada',
    'Completada',
    'Cancelada',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill fields from existing appointment
    _serviceName = _servicesList.firstWhere(
      (s) => s.contains(widget.appointment.nombreServicio) || widget.appointment.nombreServicio.contains(s.split(' (')[0]),
      orElse: () => _servicesList.first,
    );
    _specialistName = _specialistsList.contains(widget.appointment.nombreEmpleado)
        ? widget.appointment.nombreEmpleado
        : _specialistsList.first;
    _selectedDate = widget.appointment.fecha;

    // Parse hora_inicio "10:00 AM"
    final timeParts = widget.appointment.horaInicio.split(' ');
    if (timeParts.length == 2) {
      _period = timeParts[1];
      final hm = timeParts[0].split(':');
      if (hm.length == 2) {
        _hour = hm[0];
        _minute = hm[1];
      } else {
        _hour = '10';
        _minute = '00';
      }
    } else {
      _hour = '10';
      _minute = '00';
      _period = 'AM';
    }

    _status = _statusList.contains(widget.appointment.estado)
        ? widget.appointment.estado
        : 'Pendiente';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${dt.day} de ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con botón atrás y título
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Editar cita',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),

              // Cliente (solo lectura)
              const Text(
                'Cliente (solo lectura):',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.appointment.nombreCliente} (${widget.appointment.idCliente})',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 14),

              // Servicio contratado
              const Text(
                'Servicio contratado:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _serviceName,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    items: _servicesList.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _serviceName = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Especialista asignado
              const Text(
                'Especialista asignado:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _specialistName,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    items: _specialistsList.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _specialistName = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Fecha de la cita
              const Text(
                'Fecha de la cita:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Horas de inicio
              const Text(
                'Horas de inicio:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeBox(_hour, (val) => setState(() => _hour = val), ['08', '09', '10', '11', '12', '01', '02', '03', '04', '05', '06']),
                  const SizedBox(width: 8),
                  _buildTimeBox(_minute, (val) => setState(() => _minute = val), ['00', '15', '30', '45']),
                  const SizedBox(width: 8),
                  _buildTimeBox(_period, (val) => setState(() => _period = val), ['AM', 'PM']),
                ],
              ),
              const SizedBox(height: 14),

              // Estado de la cita
              const Text(
                'Estado de la cita:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    items: _statusList.map((st) {
                      return DropdownMenuItem(
                        value: st,
                        child: Text(st),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar cambios
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final cleanServiceName = _serviceName.split(' (')[0];
                  final updated = widget.appointment.copyWith(
                    nombreServicio: cleanServiceName,
                    nombreEmpleado: _specialistName,
                    fecha: _selectedDate,
                    horaInicio: '$_hour:$_minute $_period',
                    estado: _status,
                  );
                  widget.onSave(updated);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Guardar cambios',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox(String currentValue, Function(String) onChanged, List<String> options) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
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
}
