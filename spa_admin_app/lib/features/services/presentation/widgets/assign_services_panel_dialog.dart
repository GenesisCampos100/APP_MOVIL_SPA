import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/employees/data/models/employee_model.dart';
import 'package:spa_admin_app/features/services/data/models/service_model.dart';

class AssignServicesPanelDialog extends StatefulWidget {
  final EmployeeModel employee;
  final List<ServiceModel> allServices;
  final Set<String> initiallyAssignedServiceIds;
  final Function(Set<String>) onSave;

  const AssignServicesPanelDialog({
    super.key,
    required this.employee,
    required this.allServices,
    required this.initiallyAssignedServiceIds,
    required this.onSave,
  });

  @override
  State<AssignServicesPanelDialog> createState() => _AssignServicesPanelDialogState();
}

class _AssignServicesPanelDialogState extends State<AssignServicesPanelDialog> {
  late Set<String> _assignedIds;

  @override
  void initState() {
    super.initState();
    _assignedIds = Set.from(widget.initiallyAssignedServiceIds);
  }

  @override
  Widget build(BuildContext context) {
    // Agrupar servicios por categoría
    final Map<String, List<ServiceModel>> groupedServices = {};
    for (var service in widget.allServices) {
      groupedServices.putIfAbsent(service.categoria, () => []).add(service);
    }

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
                      'Asignar servicios a empleado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),

              // Tarjeta de info del empleado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFEFEFEF),
                      child: Icon(Icons.person_outline, color: Colors.black87, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employee.nombreCompleto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Puesto: ${widget.employee.puesto}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de servicios agrupados por categoría
              ...groupedServices.entries.map((entry) {
                final categoryName = entry.key;
                final services = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría: $categoryName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...services.map((service) {
                      final isAssigned = _assignedIds.contains(service.idServicio);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.nombre,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${service.duracion} | \$${service.precio.toStringAsFixed(2)} MXN',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAssigned,
                              activeColor: Colors.white,
                              activeTrackColor: AppColors.primaryPink,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey.shade400,
                              onChanged: (val) {
                                setState(() {
                                  if (val) {
                                    _assignedIds.add(service.idServicio);
                                  } else {
                                    _assignedIds.remove(service.idServicio);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              }),
              const SizedBox(height: 20),

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
                  widget.onSave(_assignedIds);
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
}
