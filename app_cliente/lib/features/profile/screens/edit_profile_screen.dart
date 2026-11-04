import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/usuario_sesion.dart';
import '../../../data/repositories/perfil_repository.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

/// Abre "Mi perfil" (solo con sesión iniciada).
void abrirMiPerfil(BuildContext context) {
  if (!AuthState.instance.isLoggedIn) return;
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
  );
}

/// Mi perfil: editar nombre, apellidos, teléfono y fecha de nacimiento.
/// El correo se muestra pero no se puede cambiar.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repo = PerfilRepository();
  late final UsuarioSesion _orig = AuthState.instance.usuario!;

  late final _nombre = TextEditingController(text: _orig.nombre);
  late final _apellidoP = TextEditingController(text: _orig.apellido);
  late final _apellidoM = TextEditingController(text: _orig.apellidoMaterno ?? '');
  late final _tel = TextEditingController(text: (_orig.telefono ?? '').replaceFirst('+52', ''));
  late final _correo = TextEditingController(text: _orig.correo);

  int? _dia, _mes, _anio;
  bool _cargando = false;
  String? _errNombre, _errApellido, _errTel, _errFecha;

  @override
  void initState() {
    super.initState();
    final f = _orig.fechaNacimiento;
    if (f != null) {
      _dia = f.day;
      _mes = f.month;
      _anio = f.year;
    }
    for (final c in [_nombre, _apellidoP, _apellidoM, _tel]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellidoP.dispose();
    _apellidoM.dispose();
    _tel.dispose();
    _correo.dispose();
    super.dispose();
  }

  bool get _hayCambios {
    final o = _orig;
    final telOrig = (o.telefono ?? '').replaceFirst('+52', '');
    final f = o.fechaNacimiento;
    return _nombre.text.trim() != o.nombre ||
        _apellidoP.text.trim() != o.apellido ||
        _apellidoM.text.trim() != (o.apellidoMaterno ?? '') ||
        _tel.text.trim() != telOrig ||
        _dia != f?.day ||
        _mes != f?.month ||
        _anio != f?.year;
  }

  bool _validar() {
    final tel = _tel.text.trim();
    String? errFecha;
    final hayAlgo = _dia != null || _mes != null || _anio != null;
    if (hayAlgo) {
      if (_dia == null || _mes == null || _anio == null) {
        errFecha = 'Completa la fecha';
      } else {
        final f = DateTime(_anio!, _mes!, _dia!);
        if (f.month != _mes || f.day != _dia) {
          errFecha = 'Fecha inválida';
        } else if (f.isAfter(DateTime.now())) {
          errFecha = 'La fecha no puede ser futura';
        }
      }
    }
    setState(() {
      _errNombre = _nombre.text.trim().isEmpty ? 'Ingresa tu nombre' : null;
      _errApellido = _apellidoP.text.trim().isEmpty ? 'Ingresa tu apellido' : null;
      _errTel = (tel.isNotEmpty && tel.length != 10) ? 'Ingresa un número de 10 dígitos' : null;
      _errFecha = errFecha;
    });
    return _errNombre == null && _errApellido == null && _errTel == null && _errFecha == null;
  }

  Future<void> _guardar() async {
    if (!_validar()) return;
    setState(() => _cargando = true);
    try {
      final materno = _apellidoM.text.trim();
      final tel = _tel.text.trim();
      final fecha = (_dia != null && _mes != null && _anio != null)
          ? DateTime(_anio!, _mes!, _dia!)
          : null;
      final nuevo = await _repo.guardar(
        _orig,
        nombre: _nombre.text.trim(),
        apellido: _apellidoP.text.trim(),
        apellidoMaterno: materno.isEmpty ? null : materno,
        telefono: tel.isEmpty ? null : '+52$tel',
        fechaNacimiento: fecha,
      );
      AuthState.instance.actualizarPerfil(nuevo);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final anioActual = DateTime.now().year;
    OutlineInputBorder borde(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _abrirOpcionesFoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.rosa,
                      backgroundImage: _orig.foto != null ? NetworkImage(_orig.foto!) : null,
                      child: _orig.foto == null
                          ? Text(
                        _orig.inicial,
                        style: const TextStyle(
                            fontSize: 40, color: Colors.white, fontWeight: FontWeight.w500),
                      )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined, size: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AuthCampo(
              label: 'Nombre',
              controller: _nombre,
              errorText: _errNombre,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AuthCampo(
                    label: 'Apellido paterno',
                    controller: _apellidoP,
                    errorText: _errApellido,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthCampo(
                    label: 'Apellido materno',
                    controller: _apellidoM,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AuthCampo(label: 'Correo electrónico', controller: _correo, enabled: false),
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 2),
              child: Text('El correo no se puede cambiar.',
                  style: TextStyle(fontSize: 11, color: AppColors.gris)),
            ),
            const SizedBox(height: 14),
            const Text('Teléfono', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('+52', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tel,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      errorText: _errTel,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: borde(Colors.black54),
                      enabledBorder: borde(Colors.black54),
                      focusedBorder: borde(Colors.black),
                      errorBorder: borde(Colors.red),
                      focusedErrorBorder: borde(Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Fecha de nacimiento',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _combo(
                    hint: 'Día',
                    valor: _dia,
                    items: [for (var d = 1; d <= 31; d++) DropdownMenuItem(value: d, child: Text('$d'))],
                    onChanged: (v) => setState(() {
                      _dia = v;
                      _errFecha = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _combo(
                    hint: 'Mes',
                    valor: _mes,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text(_meses[m - 1])),
                    ],
                    onChanged: (v) => setState(() {
                      _mes = v;
                      _errFecha = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _combo(
                    hint: 'Año',
                    valor: _anio,
                    items: [
                      for (var a = anioActual - 5; a >= anioActual - 100; a--)
                        DropdownMenuItem(value: a, child: Text('$a')),
                    ],
                    onChanged: (v) => setState(() {
                      _anio = v;
                      _errFecha = null;
                    }),
                  ),
                ),
              ],
            ),
            if (_errFecha != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(_errFecha!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AuthBoton(
            texto: 'Guardar cambios',
            cargando: _cargando,
            onPressed: _hayCambios ? _guardar : null,
          ),
        ),
      ),
    );
  }

  void _abrirOpcionesFoto() {
    void proximamente(BuildContext ctx, String que) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$que: próximamente')),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Foto de perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(_orig.foto == null ? 'Subir desde la galería' : 'Cambiar desde la galería'),
                onTap: () => proximamente(ctx, 'Subir foto'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () => proximamente(ctx, 'Tomar foto'),
              ),
              if (_orig.foto != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFE5174D)),
                  title: const Text('Eliminar foto', style: TextStyle(color: Color(0xFFE5174D))),
                  onTap: () => proximamente(ctx, 'Eliminar foto'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _combo({
    required String hint,
    required int? valor,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _errFecha != null ? Colors.red : Colors.black54),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: valor,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.gris)),
          style: const TextStyle(fontSize: 14, color: Colors.black),
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}