import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/appointments/data/models/appointment_model.dart';

class AppointmentFormDialog extends StatefulWidget {
  final Function(AppointmentModel) onSave;

  const AppointmentFormDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  final _clientNameController = TextEditingController();
  String _serviceName = 'Masaje Relajante Descontracturante (\$650.00)';
  String _specialistName = 'Carlos Mendoza García';
  DateTime _selectedDate = DateTime.now();
  String _hour = '10';
  String _minute = '00';
  String _period = 'AM';
  String _status = 'Pendiente';

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
  ];

  @override
  void dispose() {
    _clientNameController.dispose();
    super.dispose();
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
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Nueva cita',
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

              // Cliente
              const Text(
                'Nombre del Cliente:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _clientNameController,
                decoration: InputDecoration(
                  hintText: 'Ej. Laura Gómez Rivas',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Servicio
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
                      return DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _serviceName = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Especialista
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
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _specialistName = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Fecha
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

              // Hora
              const Text(
                'Hora de inicio:',
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

              // Estado
              const Text(
                'Estado inicial:',
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
                      return DropdownMenuItem(value: st, child: Text(st));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Crear cita
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final clientName = _clientNameController.text.trim().isEmpty
                      ? 'Cliente'
                      : _clientNameController.text.trim();
                  final cleanServiceName = _serviceName.split(' (')[0];
                  final newAppointment = AppointmentModel(
                    idCita: '#Cita-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    idCliente: '#CLI-${(100 + DateTime.now().second).toString()}',
                    nombreCliente: clientName,
                    nombreServicio: cleanServiceName,
                    precioAplicado: 650.00,
                    nombreEmpleado: _specialistName,
                    fecha: _selectedDate,
                    horaInicio: '$_hour:$_minute $_period',
                    duracionAplicada: '60 min',
                    estado: _status,
                  );
                  widget.onSave(newAppointment);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Crear cita',
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
