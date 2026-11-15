import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/models/employee_model.dart';
import 'package:spa_admin_app/data/models/puesto_model.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Formulario real; solo cierra cuando el backend confirma el guardado.
class EmployeeFormDialog extends StatefulWidget {
  final EmployeeModel? employeeToEdit;
  final List<PuestoModel> puestos;
  final Future<PuestoModel> Function(String nombre, {String? descripcion}) onCrearPuesto;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const EmployeeFormDialog({
    super.key,
    this.employeeToEdit,
    required this.puestos,
    required this.onCrearPuesto,
    required this.onSave,
  });

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _paterno;
  late final TextEditingController _materno;
  late final TextEditingController _telefono;
  late final TextEditingController _correo;
  late final TextEditingController _clave;
  late List<PuestoModel> _puestosDisponibles;
  int? _puestoId;
  bool _creandoPuesto = false;
  bool _mostrarClave = false;
  bool _guardando = false;
  bool _confirmandoSalida = false;
  String? _error;
  int? _puestoInicial;

  // Solo advertimos cuando los datos cambiaron con respecto al formulario abierto.
  bool get _hayCambios {
    final original = widget.employeeToEdit;
    return _nombre.text.trim() != (original?.nombre ?? '').trim() ||
        _paterno.text.trim() != (original?.apellidoP ?? '').trim() ||
        _materno.text.trim() != (original?.apellidoM ?? '').trim() ||
        _telefono.text.trim() != (original?.telefono ?? '').trim() ||
        _correo.text.trim().toLowerCase() !=
            (original?.correo ?? '').trim().toLowerCase() ||
        _puestoId != _puestoInicial ||
        _clave.text.isNotEmpty;
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
        mensaje: 'Los cambios que hiciste en este empleado no se guardarán. '
            '¿Deseas salir sin guardar?',
        textoConfirmar: 'Descartar cambios',
        icono: Icons.warning_amber_rounded,
      );
      if (mounted && descartar) Navigator.of(context).pop(false);
    } finally {
      _confirmandoSalida = false;
    }
  }

  bool get _esEdicion => widget.employeeToEdit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employeeToEdit;
    _nombre = TextEditingController(text: e?.nombre ?? '');
    _paterno = TextEditingController(text: e?.apellidoP ?? '');
    _materno = TextEditingController(text: e?.apellidoM ?? '');
    _telefono = TextEditingController(text: e?.telefono ?? '');
    _correo = TextEditingController(text: e?.correo ?? '');
    _clave = TextEditingController();
    _puestosDisponibles = List<PuestoModel>.from(widget.puestos);
    final puestoActual = int.tryParse(e?.idPuesto ?? '');
    _puestoId = _puestosDisponibles.any((p) => p.idPuesto == puestoActual)
        ? puestoActual : null;
    _puestoInicial = _puestoId;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _paterno.dispose();
    _materno.dispose();
    _telefono.dispose();
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _crearPuesto() async {
    if (_guardando || _creandoPuesto) return;
    String nombrePuesto = '';
    String descripcionPuesto = '';
    final key = GlobalKey<FormState>();
    final datos = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AdminTranslatedText('Nuevo puesto', 'New job title'),
        content: Form(key: key, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              onChanged: (valor) => nombrePuesto = valor,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre del puesto'),
              validator: (value) {
                final nombre = value?.trim() ?? '';
                if (nombre.length < 2) return 'Escribe al menos 2 caracteres.';
                if (_puestosDisponibles.any((p) =>
                    p.nombre.toLowerCase() == nombre.toLowerCase())) {
                  return 'Ya existe ese puesto.';
                }
                return null;
              },
            ),
            TextFormField(
              onChanged: (valor) => descripcionPuesto = valor,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
            const Text('El puesto se guardará de inmediato. Los puestos nuevos usan el panel de especialista, no el de Recepción.',
                style: TextStyle(fontSize: 12)),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const AdminTranslatedText('Cancelar', 'Cancel')),
          FilledButton(onPressed: () {
            if (key.currentState?.validate() ?? false) {
              Navigator.pop(dialogContext, {
                'nombre': nombrePuesto.trim(),
                'descripcion': descripcionPuesto.trim(),
              });
            }
          }, child: const AdminTranslatedText('Crear puesto', 'Create job title')),
        ],
      ),
    );
    if (!mounted || datos == null) return;
    setState(() { _creandoPuesto = true; _error = null; });
    try {
      final puesto = await widget.onCrearPuesto(datos['nombre']!,
          descripcion: datos['descripcion']);
      if (!mounted) return;
      setState(() {
        _puestosDisponibles.add(puesto);
        _puestosDisponibles.sort((a, b) => a.nombre.compareTo(b.nombre));
        _puestoId = puesto.idPuesto;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Puesto registrado y seleccionado.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo registrar el puesto.');
    } finally {
      if (mounted) setState(() => _creandoPuesto = false);
    }
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() { _guardando = true; _error = null; });
    final datos = <String, dynamic>{
      'nombre': _nombre.text.trim(),
      'apellido_p': _paterno.text.trim(),
      'apellido_m': _materno.text.trim(),
      'telefono': _telefono.text.trim(),
      'correo': _correo.text.trim().toLowerCase(),
      'id_puesto': _puestoId,
      if (!_esEdicion) 'contrasenia': _clave.text,
    };
    try {
      await widget.onSave(datos);
      if (!mounted) return;
      _clave.clear();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'No se pudieron guardar los cambios.';
      });
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _decoracion(
    String etiqueta, {
    String? pista,
    IconData? icono,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: pista,
      prefixIcon: icono == null
          ? null
          : Icon(icono, size: 20, color: AdminVisual.primaryPink),
      filled: true,
      fillColor: AdminVisual.fieldBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  Widget _espacio() => const SizedBox(height: 13);

  Widget _seccion(String titulo, IconData icono) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 13),
      child: Row(
        children: [
          Icon(icono, color: AdminVisual.primaryPink, size: 20),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AdminVisual.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _intentarCerrar();
      },
      child: Dialog(
        backgroundColor: AdminVisual.cardBackground,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminVisual.primaryPinkSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _esEdicion ? Icons.edit_note_rounded : Icons.person_add_alt_1,
                          color: AdminVisual.primaryPink,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _esEdicion ? AdminVisual.t('Editar empleado', 'Edit staff member') : AdminVisual.t('Registrar empleado', 'Add staff member'),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AdminVisual.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: AdminVisual.t('Cerrar', 'Close'),
                        onPressed: _guardando
                            ? null
                            : _intentarCerrar,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AdminVisual.t('Completa los datos del personal.', 'Enter the staff member details.'),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AdminVisual.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _seccion('Datos personales', Icons.badge_outlined),
                  TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoracion('Nombre *', icono: Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty || v.trim().length > 100)
                      ? 'Escribe un nombre válido.' : null,
                  ),
                  _espacio(),
                  TextFormField(
                    controller: _paterno,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoracion('Apellido paterno *', icono: Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty || v.trim().length > 100)
                      ? 'Escribe un apellido válido.' : null,
                  ),
                  _espacio(),
                  TextFormField(
                    controller: _materno,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoracion('Apellido materno (opcional)', icono: Icons.person_outline),
                    validator: (v) => (v != null && v.trim().length > 100)
                      ? 'El apellido es demasiado largo.' : null,
                  ),
                  _espacio(),
                  TextFormField(
                    controller: _telefono,
                    keyboardType: TextInputType.phone,
                    decoration: _decoracion('Teléfono (opcional)', icono: Icons.phone_outlined),
                    validator: (v) => (v != null && v.trim().length > 25)
                      ? 'El teléfono es demasiado largo.' : null,
                  ),
                  const SizedBox(height: 13),
                  _seccion('Cuenta y puesto', Icons.work_outline_rounded),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _decoracion('Correo electrónico *', icono: Icons.mail_outline),
                    validator: (v) => (v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim()))
                      ? 'Introduce un correo válido.' : null,
                  ),
                  _espacio(),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: DropdownButtonFormField<int>(
                      key: ValueKey('puesto_$_puestoId'),
                      value: _puestoId,
                      isExpanded: true,
                      decoration: _decoracion('Puesto *', icono: Icons.work_outline_rounded),
                      items: _puestosDisponibles.map((p) => DropdownMenuItem<int>(
                        value: p.idPuesto,
                        child: Text(p.nombre, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: _guardando || _creandoPuesto ? null
                          : (v) => setState(() => _puestoId = v),
                      validator: (v) => v == null ? 'Selecciona un puesto.' : null,
                    )),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Agregar puesto',
                      onPressed: _guardando || _creandoPuesto ? null : _crearPuesto,
                      icon: _creandoPuesto
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_rounded),
                    ),
                  ]),
                  if (!_esEdicion) ...[
                    _espacio(),
                    TextFormField(
                      controller: _clave,
                      obscureText: !_mostrarClave,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: _decoracion('Contraseña inicial *', icono: Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          tooltip: _mostrarClave ? 'Ocultar contraseña' : 'Mostrar contraseña',
                          icon: Icon(_mostrarClave ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _mostrarClave = !_mostrarClave),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 12 || utf8.encode(v).length > 72)
                        ? 'Usa entre 12 caracteres y 72 bytes.' : null,
                    ),
                    const SizedBox(height: 6),
                    Text(AdminVisual.t('Por seguridad, la contraseña no volverá a mostrarse después del registro.', 'For security, the password will not be shown again after registration.'),
                      style: TextStyle(color: AdminVisual.textMuted, fontSize: 11)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 22),
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
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AdminVisual.primaryPink,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: _guardando ? null : _guardar,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_guardando ? 'Guardando…' : 'Guardar'),
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
}
