import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/services/data/models/service_model.dart';

class ServiceFormDialog extends StatefulWidget {
  final ServiceModel? serviceToEdit;
  final Function(ServiceModel) onSave;

  const ServiceFormDialog({
    super.key,
    this.serviceToEdit,
    required this.onSave,
  });

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _durationController;
  late TextEditingController _priceController;

  String _selectedCategory = 'Masajes';
  bool _isActive = true;

  final List<String> _categories = ['Masajes', 'Faciales', 'Corporal', 'Estética'];

  @override
  void initState() {
    super.initState();
    final s = widget.serviceToEdit;
    _nameController = TextEditingController(text: s?.nombre ?? '');
    _descController = TextEditingController(text: s?.descripcion ?? '');
    _durationController = TextEditingController(text: s?.duracion ?? '');
    _priceController = TextEditingController(text: s != null ? '\$${s.precio.toStringAsFixed(2)} MXN' : '');
    _selectedCategory = s?.categoria ?? 'Masajes';
    _isActive = s?.estado ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.serviceToEdit != null;

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
            // Cabecera con botón de regresar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    isEditing ? 'Editar servicio' : 'Crear servicio',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 16),

            // Campos del formulario
            _buildLabel('Nombre del servicio:'),
            _buildTextField(_nameController, 'Ej: Masaje relajante'),

            _buildLabel('Descripción:'),
            _buildTextField(_descController, 'Tratamiento corporal...', maxLines: 2),

            _buildLabel('Duración:'),
            _buildTextField(_durationController, '60 minutos'),

            _buildLabel('Precio:'),
            _buildTextField(_priceController, '\$650.00 MXN'),

            _buildLabel('Categoría:'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Estado (Activo / Inactivo)
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
                  final cleanPrice = double.tryParse(
                    _priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
                  ) ?? 0.0;

                  final service = ServiceModel(
                    idServicio: widget.serviceToEdit?.idServicio ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    nombre: _nameController.text,
                    descripcion: _descController.text,
                    duracion: _durationController.text,
                    precio: cleanPrice,
                    categoria: _selectedCategory,
                    estado: _isActive,
                  );

                  widget.onSave(service);
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

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
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
