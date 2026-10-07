import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/employees/data/models/employee_model.dart';

class EmployeeFormDialog extends StatefulWidget {
  final EmployeeModel? employeeToEdit;
  final Function(EmployeeModel) onSave;

  const EmployeeFormDialog({
    super.key,
    this.employeeToEdit,
    required this.onSave,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  String _selectedRole = 'Masajista';
  bool _isActive = true;

  final List<String> _roles = ['Masajista', 'Cosmetóloga', 'Estética', 'Recepcionista'];

  @override
  void initState() {
    super.initState();
    final emp = widget.employeeToEdit;
    _nameController = TextEditingController(text: emp?.nombreCompleto ?? '');
    _phoneController = TextEditingController(text: emp?.telefono ?? '');
    _emailController = TextEditingController(text: emp?.correo ?? '');
    _selectedRole = emp?.puesto ?? 'Masajista';
    _isActive = emp?.estado ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employeeToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    isEditing ? 'Editar empleado' : 'Agregar empleado',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 12),

            // Campos del formulario
            _buildLabel('Nombre completo del empleado:'),
            _buildTextField(_nameController, 'Carlos Mendoza García'),

            _buildLabel('Id:'),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: isEditing ? widget.employeeToEdit!.idEmpleado : 'Auto-generado',
                filled: true,
                fillColor: const Color(0xFFEFEFEF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            _buildLabel('Telefono:'),
            _buildTextField(_phoneController, '*** *** ****', keyboardType: TextInputType.phone),

            _buildLabel('Correo:'),
            _buildTextField(_emailController, 'ejemplo@outlook.com', keyboardType: TextInputType.emailAddress),

            _buildLabel('Puesto:'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  items: _roles.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Selector de Estado (Activo / Inactivo)
            _buildLabel('Estado:'),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isActive = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isActive ? AppColors.primaryPink : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Activo', style: TextStyle(color: _isActive ? Colors.white : Colors.black54, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isActive = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isActive ? AppColors.primaryPink : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Inactivo', style: TextStyle(color: !_isActive ? Colors.white : Colors.black54, fontSize: 12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Opción de Foto de perfil
            _buildLabel(isEditing ? 'Foto de perfil:' : 'Agregar foto:'),
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFEFEFEF),
                  child: Icon(Icons.person_outline, color: Colors.black54, size: 28),
                ),
                if (isEditing) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEFEF),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    child: const Text('Cambiar foto', style: TextStyle(color: Colors.black87, fontSize: 12)),
                  ),
                ]
              ],
            ),

            const SizedBox(height: 24),

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final employee = EmployeeModel(
                    idEmpleado: widget.employeeToEdit?.idEmpleado ?? 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    nombreCompleto: _nameController.text,
                    telefono: _phoneController.text,
                    correo: _emailController.text,
                    puesto: _selectedRole,
                    estado: _isActive,
                  );

                  widget.onSave(employee);
                  Navigator.pop(context);
                },
                child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEFEFEF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
