import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Formulario para crear o editar servicios reales.
/// La operación es asíncrona: no se cierra hasta que la API confirme el guardado.
class ServiceFormDialog extends StatefulWidget {
  final ServiceModel? serviceToEdit;
  final Map<String, String> categorias;
  final Future<void> Function(ServiceModel) onSave;

  const ServiceFormDialog({
    super.key,
    this.serviceToEdit,
    required this.categorias,
    required this.onSave,
  });

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;

  String? _categoriaId;
  bool _guardando = false;
  bool _confirmandoSalida = false;
  String? _error;
  String? _categoriaInicial;

  bool get _hayCambios {
    final servicio = widget.serviceToEdit;
    final duracionOriginal = RegExp(r'\d+').firstMatch(servicio?.duracion ?? '');
    return _nameController.text.trim() != (servicio?.nombre ?? '').trim() ||
        _descController.text.trim() != (servicio?.descripcion ?? '').trim() ||
        _durationController.text.trim() != (duracionOriginal?.group(0) ?? '') ||
        _priceController.text.trim() !=
            (servicio == null ? '' : servicio.precio.toStringAsFixed(2)) ||
        _categoriaId != _categoriaInicial;
  }

  Future<void> _intentarCerrar() async {
    if (_guardando || _confirmandoSalida) return;
    if (!_hayCambios) {
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    _confirmandoSalida = true;
    try {
      final descartar = await mostrarConfirmacion(
        context: context,
        titulo: '¿Descartar cambios?',
        mensaje: 'Los cambios que hiciste en este servicio no se guardarán. '
            '¿Deseas salir sin guardar?',
        textoConfirmar: 'Descartar cambios',
        icono: Icons.warning_amber_rounded,
      );
      if (mounted && descartar) Navigator.of(context).pop(false);
    } finally {
      _confirmandoSalida = false;
    }
  }

  @override
  void initState() {
    super.initState();
    final servicio = widget.serviceToEdit;
    _nameController = TextEditingController(text: servicio?.nombre ?? '');
    _descController = TextEditingController(text: servicio?.descripcion ?? '');
    final duracion = RegExp(r'\d+').firstMatch(servicio?.duracion ?? '');
    _durationController = TextEditingController(text: duracion?.group(0) ?? '');
    _priceController = TextEditingController(
      text: servicio == null ? '' : servicio.precio.toStringAsFixed(2),
    );
    final id = servicio?.idCategoria;
    _categoriaId = id != null && widget.categorias.containsKey(id)
        ? id
        : widget.categorias.keys.firstOrNull;
    _categoriaInicial = _categoriaId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    final idCategoria = _categoriaId;
    if (idCategoria == null) {
      setState(() => _error = 'No hay categorías disponibles para este servicio.');
      return;
    }

    final original = widget.serviceToEdit;
    final nuevo = ServiceModel(
      idServicio: original?.idServicio ?? '',
      idCategoria: idCategoria,
      nombre: _nameController.text.trim(),
      descripcion: _descController.text.trim(),
      duracion: _durationController.text.trim(),
      precio: double.parse(_priceController.text.trim()),
      categoria: widget.categorias[idCategoria] ?? '',
      estado: original?.estado ?? true,
      imagen: original?.imagen,
    );

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      await widget.onSave(nuevo);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar el servicio. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.serviceToEdit != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _intentarCerrar();
      },
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.spa_outlined, color: AppColors.primaryPink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          editando ? 'Editar servicio' : 'Nuevo servicio',
                          style: AppTextStyles.heading2.copyWith(color: AppColors.textDark),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: _guardando ? null : _intentarCerrar,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_guardando,
                    maxLength: 120,
                    decoration: _decoracion('Nombre del servicio', Icons.spa_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Escribe el nombre del servicio.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    enabled: !_guardando,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: _decoracion('Descripción (opcional)', Icons.notes_rounded),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          enabled: !_guardando,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _decoracion('Minutos', Icons.schedule_outlined),
                          validator: (v) {
                            final minutos = int.tryParse(v?.trim() ?? '');
                            return minutos == null || minutos <= 0
                                ? 'Duración inválida'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          enabled: !_guardando,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                          decoration: _decoracion('Precio MXN', Icons.payments_outlined),
                          validator: (v) {
                            final precio = double.tryParse(v?.trim() ?? '');
                            return precio == null || !precio.isFinite || precio < 0
                                ? 'Precio inválido'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: _categoriaId,
                    isExpanded: true,
                    decoration: _decoracion('Categoría', Icons.category_outlined),
                    items: widget.categorias.entries.map((entry) =>
                      DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value, overflow: TextOverflow.ellipsis),
                      ),
                    ).toList(),
                    onChanged: _guardando ? null : (v) => setState(() => _categoriaId = v),
                    validator: (v) => v == null ? 'Selecciona una categoría.' : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Las categorías se obtienen de los servicios activos del catálogo.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _guardando ? null : _intentarCerrar,
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _guardando ? null : _guardar,
                          child: _guardando
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(editando ? 'Guardar cambios' : 'Crear servicio'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: AppColors.primaryPink),
      filled: true,
      fillColor: AppColors.fieldBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
    );
  }
}
