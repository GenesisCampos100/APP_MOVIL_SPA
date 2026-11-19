import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/preferences/staff_preferences.dart';
import '../../../data/repositories/staff_profile_repository.dart';

class StaffProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const StaffProfileEditScreen({super.key, required this.profile});

  @override
  State<StaffProfileEditScreen> createState() => _StaffProfileEditScreenState();
}

class _StaffProfileEditScreenState extends State<StaffProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellidoP;
  late final TextEditingController _apellidoM;
  bool _guardando = false;
  bool _subiendo = false;
  String? _foto;

  String t(String es, String en) => StaffPreferences.tr(es, en);

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.profile['nombre']?.toString() ?? '');
    _apellidoP = TextEditingController(text: widget.profile['apellido_p']?.toString() ?? '');
    _apellidoM = TextEditingController(text: widget.profile['apellido_m']?.toString() ?? '');
    _foto = widget.profile['foto']?.toString();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellidoP.dispose();
    _apellidoM.dispose();
    super.dispose();
  }

  void _mensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _elegirFoto() async {
    if (_subiendo || _guardando) return;
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 82,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 3 * 1024 * 1024) {
        _mensaje(t('La foto supera los 3 MB.', 'The photo is larger than 3 MB.'));
        return;
      }
      // Determina MIME a partir de bytes, no de la extensión del picker.
      final mime = bytes.length >= 8 &&
          bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78
          ? 'image/png'
          : bytes.length >= 12 && String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
              String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP'
              ? 'image/webp' : 'image/jpeg';
      setState(() => _subiendo = true);
      final response = await StaffProfileRepository.subirFoto(bytes, mime);
      if (!mounted) return;
      setState(() => _foto = response['foto']?.toString());
      _mensaje(t('Fotografía guardada en tu perfil.', 'Profile photo saved.'));
    } catch (err) {
      _mensaje(err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await StaffProfileRepository.editar({
        'nombre': _nombre.text.trim(),
        'apellido_p': _apellidoP.text.trim(),
        'apellido_m': _apellidoM.text.trim().isEmpty ? null : _apellidoM.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (err) {
      _mensaje(err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = StaffProfileRepository.imageUrl(_foto);
    return Scaffold(
      appBar: AppBar(title: Text(t('Editar perfil', 'Edit profile'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(24), children: [
            Center(
              child: Stack(children: [
                CircleAvatar(
                  radius: 49,
                  backgroundColor: colors.primaryContainer,
                  backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
                  child: imageUrl == null ? Icon(Icons.person_outline_rounded,
                      size: 42, color: colors.onPrimaryContainer) : null,
                ),
                Positioned(right: 0, bottom: 0,
                  child: CircleAvatar(radius: 19,
                    backgroundColor: colors.primary,
                    child: IconButton(
                      tooltip: t('Cambiar fotografía', 'Change photo'),
                      onPressed: _subiendo ? null : _elegirFoto,
                      icon: const Icon(Icons.camera_alt_outlined, size: 19, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            if (_subiendo) const Center(child: CircularProgressIndicator()),
            Center(child: Text(t('Elegir fotografía de galería', 'Choose photo from gallery'),
              style: Theme.of(context).textTheme.bodySmall)),
            const SizedBox(height: 32),
            TextFormField(controller: _nombre,
              decoration: InputDecoration(labelText: t('Nombre', 'First name')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? t('Escribe tu nombre.', 'Enter your name.') : null),
            const SizedBox(height: 16),
            TextFormField(controller: _apellidoP,
              decoration: InputDecoration(labelText: t('Apellido paterno', 'Last name')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? t('Escribe tu apellido.', 'Enter your last name.') : null),
            const SizedBox(height: 16),
            TextFormField(controller: _apellidoM,
              decoration: InputDecoration(labelText: t('Apellido materno (opcional)', 'Second last name (optional)'))),
            const SizedBox(height: 12),
            Text(widget.profile['correo']?.toString() ?? '',
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: _guardando || _subiendo ? null : _guardar,
              icon: const Icon(Icons.check_rounded),
              label: Text(_guardando ? t('Guardando...', 'Saving...')
                  : t('Guardar cambios', 'Save changes'))),
          ]),
        ),
      ),
    );
  }
}
