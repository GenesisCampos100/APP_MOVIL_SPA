import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:flutter/services.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/repositories/servicios_repository.dart';
import 'package:spa_admin_app/features/services/widgets/service_image_preview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Formulario para crear o editar servicios reales.
/// La operación es asíncrona: no se cierra hasta que la API confirme el guardado.
class ServiceFormDialog extends StatefulWidget {
  final ServiceModel? serviceToEdit;
  final Map<String, String> categorias;
  final Future<MapEntry<String, String>> Function(String nombre) onCrearCategoria;
  final Future<void> Function(ServiceModel) onSave;

  const ServiceFormDialog({
    super.key,
    this.serviceToEdit,
    required this.categorias,
    required this.onCrearCategoria,
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

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _bytesImagen;
  String? _mimeImagen;
  bool _quitarImagen = false;
  bool _seleccionandoImagen = false;

  late Map<String, String> _categoriasDisponibles;
  String? _categoriaId;
  bool _creandoCategoria = false;
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
        _categoriaId != _categoriaInicial || _bytesImagen != null || _quitarImagen;
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
    _categoriasDisponibles = Map<String, String>.from(widget.categorias);
    final id = servicio?.idCategoria;
    _categoriaId = id != null && _categoriasDisponibles.containsKey(id)
        ? id
        : _categoriasDisponibles.keys.firstOrNull;
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

  String? _tipoDetectado(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71 &&
        bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  Future<void> _seleccionarImagen() async {
    if (_guardando || _seleccionandoImagen) return;
    setState(() => _seleccionandoImagen = true);
    try {
      final archivo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600, maxHeight: 1600, imageQuality: 82,
        requestFullMetadata: false,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      final mimeType = _tipoDetectado(bytes);
      if (mimeType == null) {
        throw const FormatException('Selecciona una fotografía JPG, PNG o WebP.');
      }
      if (bytes.lengthInBytes > 3 * 1024 * 1024) {
        throw const FormatException('La imagen supera 3 MB. Selecciona una más pequeña.');
      }
      if (mounted) setState(() {
        _bytesImagen = bytes;
        _mimeImagen = mimeType;
        _quitarImagen = false;
        _error = null;
      });
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo abrir la imagen seleccionada.');
    } finally {
      if (mounted) setState(() => _seleccionandoImagen = false);
    }
  }

  Future<void> _crearCategoria() async {
    if (_guardando || _creandoCategoria) return;
    String nombreIngresado = '';
    final key = GlobalKey<FormState>();
    final nombre = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AdminTranslatedText('Nueva categoría', 'New category'),
        content: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              onChanged: (valor) => nombreIngresado = valor,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
              validator: (value) {
                final nombre = value?.trim() ?? '';
                if (nombre.length < 2) return 'Escribe al menos 2 caracteres.';
                if (_categoriasDisponibles.values.any(
                    (c) => c.toLowerCase() == nombre.toLowerCase())) {
                  return 'Ya existe esa categoría.';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            const Text('Se guardará de inmediato en el catálogo, aunque canceles este servicio.',
                style: TextStyle(fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const AdminTranslatedText('Cancelar', 'Cancel')),
          FilledButton(onPressed: () {
            if (key.currentState?.validate() ?? false) {
              Navigator.pop(dialogContext, nombreIngresado.trim());
            }
          }, child: const AdminTranslatedText('Crear categoría', 'Create category')),
        ],
      ),
    );
    if (!mounted || nombre == null) return;
    setState(() { _creandoCategoria = true; _error = null; });
    try {
      final nueva = await widget.onCrearCategoria(nombre);
      if (!mounted) return;
      setState(() {
        _categoriasDisponibles[nueva.key] = nueva.value;
        _categoriaId = nueva.key;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría registrada y seleccionada.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar la categoría.');
    } finally {
      if (mounted) setState(() => _creandoCategoria = false);
    }
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
      categoria: _categoriasDisponibles[idCategoria] ?? '',
      estado: original?.estado ?? true,
      imagen: _quitarImagen ? null : original?.imagen,
    );

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      if (_bytesImagen != null && _mimeImagen != null) {
        nuevo.imagen = await ServiciosRepository().subirImagen(
          _bytesImagen!, mimeType: _mimeImagen!,
        );
      }
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
        backgroundColor: AdminVisual.cardBackground,
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
                      Icon(Icons.spa_outlined, color: AdminVisual.primaryPink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          editando ? 'Editar servicio' : 'Nuevo servicio',
                          style: AppTextStyles.heading2.copyWith(color: AdminVisual.textDark),
                        ),
                      ),
                      IconButton(
                        tooltip: AdminVisual.t('Cerrar', 'Close'),
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
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      key: ValueKey('categoria_$_categoriaId'),
                      value: _categoriaId,
                      isExpanded: true,
                      decoration: _decoracion('Categoría', Icons.category_outlined),
                      items: _categoriasDisponibles.entries.map((entry) =>
                        DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value, overflow: TextOverflow.ellipsis),
                        ),
                      ).toList(),
                      onChanged: _guardando || _creandoCategoria ? null
                          : (v) => setState(() => _categoriaId = v),
                      validator: (v) => v == null ? 'Selecciona una categoría.' : null,
                    )),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Agregar categoría',
                      onPressed: _guardando || _creandoCategoria ? null : _crearCategoria,
                      icon: _creandoCategoria
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_rounded),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes elegir una categoría existente o crear una nueva con +.',
                    style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted),
                  ),
                  const SizedBox(height: 20),
                  AdminTranslatedText('Fotografía del servicio', 'Service photo', style: AppTextStyles.subtitle.copyWith(color: AdminVisual.textDark)),
                  const SizedBox(height: 8),
                  Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: _bytesImagen == null
                          ? ServiceImagePreview(
                              imagen: _quitarImagen ? null : widget.serviceToEdit?.imagen,
                              size: 94,
                            )
                          : Image.memory(_bytesImagen!, width: 94, height: 94, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _guardando || _seleccionandoImagen ? null : _seleccionarImagen,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const AdminTranslatedText('Elegir de galería', 'Choose from gallery'),
                        ),
                        if (_bytesImagen != null ||
                            (!_quitarImagen && (widget.serviceToEdit?.imagen?.isNotEmpty ?? false)))
                          TextButton.icon(
                            onPressed: _guardando ? null : () => setState(() {
                              _bytesImagen = null;
                              _mimeImagen = null;
                              _quitarImagen = true;
                            }),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const AdminTranslatedText('Quitar fotografía', 'Remove photo'),
                          ),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 5),
                  Text('JPG, PNG o WebP · máximo 3 MB. Se guarda la ruta en la base de datos.',
                    style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
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
                          child: const AdminTranslatedText('Cancelar', 'Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminVisual.primaryPink,
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
      prefixIcon: Icon(icono, color: AdminVisual.primaryPink),
      filled: true,
      fillColor: AdminVisual.fieldBackground,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
    );
  }
}
