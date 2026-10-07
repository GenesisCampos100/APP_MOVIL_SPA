import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/employees/data/models/employee_model.dart';
import 'package:spa_admin_app/features/employees/presentation/widgets/employee_delete_dialog.dart';
import 'package:spa_admin_app/features/employees/presentation/widgets/employee_form_dialog.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
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
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _employees
        .where((emp) =>
            emp.nombreCompleto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            emp.puesto.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
          'Gestionar empleados',
          style: TextStyle(color: Colors.black, fontSize: 26, fontFamily: 'Georgia', fontWeight: FontWeight.w400),
        ),
      ),
      body: Column(
        children: [
          // Botón rosa '+' para agregar empleado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => EmployeeFormDialog(
                        onSave: (newEmployee) {
                          setState(() => _employees.add(newEmployee));
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(20.0),
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
              itemBuilder: (context, index) {
                final employee = filteredEmployees[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Información del empleado
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  employee.nombreCompleto,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${employee.puesto} | Tel: ${employee.telefono}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Estado: ${employee.estado ? "Activo" : "Inactiva"}',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          // Avatar de perfil
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFFEFEFEF),
                            child: Icon(Icons.person_outline, color: Colors.black87, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Botones de acción inferiores
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFEFEF),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => EmployeeDeleteDialog(
                                  employee: employee,
                                  onDeleteConfirmed: () {
                                    setState(() => _employees.removeWhere((e) => e.idEmpleado == employee.idEmpleado));
                                  },
                                ),
                              );
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.black87, fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.black),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => EmployeeFormDialog(
                                  employeeToEdit: employee,
                                  onSave: (updatedEmp) {
                                    setState(() {
                                      final i = _employees.indexWhere((e) => e.idEmpleado == updatedEmp.idEmpleado);
                                      if (i != -1) _employees[i] = updatedEmp;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      )
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
