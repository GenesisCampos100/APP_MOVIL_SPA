import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/employees/data/models/employee_model.dart';
import 'package:spa_admin_app/features/services/data/models/service_model.dart';
import 'package:spa_admin_app/features/services/presentation/widgets/assign_services_panel_dialog.dart';
import 'package:spa_admin_app/features/services/presentation/widgets/assignment_summary_dialog.dart';

class AssignServicesScreen extends StatefulWidget {
  const AssignServicesScreen({super.key});

  @override
  State<AssignServicesScreen> createState() => _AssignServicesScreenState();
}

class _AssignServicesScreenState extends State<AssignServicesScreen> {
  // Lista de empleados de ejemplo
  final List<EmployeeModel> _employees = [
    EmployeeModel(
      idEmpleado: 'EMP-001',
      nombreCompleto: 'Zinedine Hiram Miranda Campos',
      telefono: '*** *** ****',
      correo: 'zinedine@gmail.com',
      puesto: 'Masajista Senior',
      estado: true,
    ),
    EmployeeModel(
      idEmpleado: 'EMP-002',
      nombreCompleto: 'Ana Sofía Torres',
      telefono: '*** *** ****',
      correo: 'ana.torres@outlook.com',
      puesto: 'Cosmetóloga',
      estado: false,
    ),
    EmployeeModel(
      idEmpleado: 'EMP-003',
      nombreCompleto: 'Carlos Miranda Campos',
      telefono: '*** *** ****',
      correo: 'carlos@outlook.com',
      puesto: 'Masajista Senior',
      estado: true,
    ),
  ];

  // Catálogo de servicios disponibles
  final List<ServiceModel> _allServices = [
    ServiceModel(
      idServicio: 'S-01',
      nombre: 'Masaje Relajante Descontracturante',
      descripcion: 'Masaje corporal completo',
      duracion: '60 min',
      precio: 650.00,
      categoria: 'Masajes',
      estado: true,
    ),
    ServiceModel(
      idServicio: 'S-02',
      nombre: 'Masaje Piedras Calientes',
      descripcion: 'Terapia con piedras volcánicas',
      duracion: '90 min',
      precio: 850.00,
      categoria: 'Masajes',
      estado: true,
    ),
    ServiceModel(
      idServicio: 'S-03',
      nombre: 'Facial Limpieza Profunda',
      descripcion: 'Extracción e hidratación',
      duracion: '45 min',
      precio: 500.00,
      categoria: 'Faciales',
      estado: true,
    ),
    ServiceModel(
      idServicio: 'S-04',
      nombre: 'Tratamiento Hidratante',
      descripcion: 'Nutrición facial intensiva',
      duracion: '30 min',
      precio: 400.00,
      categoria: 'Faciales',
      estado: true,
    ),
    ServiceModel(
      idServicio: 'S-05',
      nombre: 'Exfoliación Corporal',
      descripcion: 'Renovación celular con sales marinas',
      duracion: '45 min',
      precio: 500.00,
      categoria: 'Corporal & Estética',
      estado: true,
    ),
  ];

  // Mapa de asignaciones: idEmpleado -> Set de idServicio
  final Map<String, Set<String>> _employeeAssignments = {
    'EMP-001': {'S-01', 'S-02', 'S-05'},
    'EMP-002': {},
    'EMP-003': {'S-01', 'S-03'},
  };

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _employees.where((emp) {
      return emp.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.puesto.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Asignar servicios',
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
          // Subtítulo e instrucciones
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asignar servicios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Seleccione un empleado para gestionar su catálogo de servicios:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Campo de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o puesto...',
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

          // Lista de tarjetas de empleados
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmployees.length,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemBuilder: (context, index) {
                final employee = filteredEmployees[index];
                final assignedIds = _employeeAssignments[employee.idEmpleado] ?? {};
                final activeCount = assignedIds.length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  employee.nombreCompleto,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${employee.puesto} | Tel: ${employee.telefono}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  employee.estado
                                      ? 'Servicios asignados: $activeCount activos'
                                      : 'Estado: Inactiva',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFEFEFEF),
                            child: Icon(Icons.person_outline, color: Colors.black87, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Botones inferiores: [Asignar] y [Ícono Lápiz]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFEFEF),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AssignServicesPanelDialog(
                                  employee: employee,
                                  allServices: _allServices,
                                  initiallyAssignedServiceIds: assignedIds,
                                  onSave: (newAssignedIds) {
                                    setState(() {
                                      _employeeAssignments[employee.idEmpleado] = newAssignedIds;
                                    });
                                  },
                                ),
                              );
                            },
                            child: const Text('Asignar', style: TextStyle(color: Colors.black87, fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AssignmentSummaryDialog(
                                  employee: employee,
                                  allServices: _allServices,
                                  assignedServiceIds: assignedIds,
                                  onEditPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AssignServicesPanelDialog(
                                        employee: employee,
                                        allServices: _allServices,
                                        initiallyAssignedServiceIds: assignedIds,
                                        onSave: (newAssignedIds) {
                                          setState(() {
                                            _employeeAssignments[employee.idEmpleado] = newAssignedIds;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                  onClearAllPressed: () {
                                    setState(() {
                                      _employeeAssignments[employee.idEmpleado] = {};
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
