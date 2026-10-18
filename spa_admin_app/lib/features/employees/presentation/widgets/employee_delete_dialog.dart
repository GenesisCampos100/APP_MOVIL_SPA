import 'package:flutter/material.dart';
import 'package:spa_admin_app/features/employees/data/models/employee_model.dart';

class EmployeeDeleteDialog extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onDeleteConfirmed;

  const EmployeeDeleteDialog({
    super.key,
    required this.employee,
    required this.onDeleteConfirmed,
  });

  void _showConfirmationModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Seguro que desea eliminar a este empleado?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC4C4C4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                      onDeleteConfirmed();
                    },
                    child: const Text('Sí, eliminar', style: TextStyle(color: Colors.black87, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEFEF),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Volver', style: TextStyle(color: Colors.black87, fontSize: 12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Eliminar empleado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Modo de eliminación: Confirme los datos del empleado antes de borrar.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),

            _buildDisabledField('Nombre completo del empleado(Disable):', employee.nombreCompleto),
            _buildDisabledField('Id(Disable):', employee.idEmpleado),
            _buildDisabledField('Telefono(Disable):', employee.telefono),
            _buildDisabledField('Correo(Disable):', employee.correo),
            _buildDisabledField('Puesto(Disable):', employee.puesto),
            _buildDisabledField('Estado(Disable):', employee.estado ? 'Activo' : 'Inactivo'),

            const SizedBox(height: 8),
            const Text(
              'Nota: Al eliminar o deshabilitar este empleado, las citas futuras asignadas deberán reasignarse.',
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFEFEF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _showConfirmationModal(context),
                child: const Text('Borrar', style: TextStyle(color: Colors.black87, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(value, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
