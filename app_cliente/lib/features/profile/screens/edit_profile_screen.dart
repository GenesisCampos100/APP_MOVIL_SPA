import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/errores.dart';
import '../../../core/utils/formato.dart';
import '../../../shared/widgets/prefijo_telefono.dart';
import '../../../data/models/usuario_sesion.dart';
import '../../../data/repositories/perfil_repository.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../../auth/screens/auth_verify_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
  bool _cargandoFoto = false;
  XFile? _fotoSeleccionada;
  bool _eliminarFotoPendiente = false;
  String? _errNombre, _errApellido, _errTel, _errFecha, _errCorreo;

  @override
  void initState() {
    super.initState();
    final f = _orig.fechaNacimiento;
    if (f != null) {
      _dia = f.day;
      _mes = f.month;
      _anio = f.year;
    }
    for (final c in [_nombre, _apellidoP, _apellidoM, _tel, _correo]) {
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
        _correo.text.trim().toLowerCase() != o.correo.toLowerCase() ||
        _dia != f?.day ||
        _mes != f?.month ||
        _anio != f?.year ||
        _fotoSeleccionada != null ||
        _eliminarFotoPendiente;
  }

  Future<bool> _esLaFotoOriginal(XFile imagen) async {
    final fotoOriginal = _orig.foto;

    if (fotoOriginal == null || fotoOriginal.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(fotoOriginal);

    List<int> bytesOriginales;

    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      final respuesta = await http
          .get(uri)
          .timeout(const Duration(seconds: 20));

      if (respuesta.statusCode != 200) {
        throw Exception('No se pudo comprobar la foto original');
      }

      bytesOriginales = respuesta.bodyBytes;
    } else if (uri != null && uri.scheme == 'file') {
      bytesOriginales = await File.fromUri(uri).readAsBytes();
    } else {
      bytesOriginales = await File(fotoOriginal).readAsBytes();
    }

    final bytesSeleccionados = await imagen.readAsBytes();

    if (bytesSeleccionados.length != bytesOriginales.length) {
      return false;
    }

    for (var i = 0; i < bytesSeleccionados.length; i++) {
      if (bytesSeleccionados[i] != bytesOriginales[i]) {
        return false;
      }
    }

    return true;
  }

  
  bool _validar() {
    final tel = _tel.text.trim();
    final correo = _correo.text.trim();

    String? errFecha;
    final hayAlgo = _dia != null || _mes != null || _anio != null;

    if (hayAlgo) {
      if (_dia == null || _mes == null || _anio == null) {
        errFecha = context.t('edit.err_fecha_completa');
      } else {
        final f = DateTime(_anio!, _mes!, _dia!);

        if (f.month != _mes || f.day != _dia) {
          errFecha = context.t('edit.err_fecha_invalida');
        } else if (f.isAfter(DateTime.now())) {
          errFecha = context.t('edit.err_fecha_futura');
        }
      }
    }

    final errCorreo = correo.isEmpty ||
            correo.length > 254 ||
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)
        ? context.t('edit.err_correo')
        : null;

    setState(() {
      _errNombre =
          _nombre.text.trim().isEmpty ? context.t('edit.err_nombre') : null;

      _errApellido =
          _apellidoP.text.trim().isEmpty ? context.t('edit.err_apellido') : null;

      _errTel = (tel.isNotEmpty && tel.length != 10)
          ? context.t('edit.err_tel')
          : null;

      _errCorreo = errCorreo;
      _errFecha = errFecha;
    });

    return _errNombre == null &&
        _errApellido == null &&
        _errTel == null &&
        _errFecha == null &&
        _errCorreo == null;
  }

  
  Future<bool> _iniciarCambioCorreo(String correo) async {
    // Solicitar el código al correo nuevo.
    await _repo.solicitarCambioCorreo(correo);

    if (!mounted) return false;

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AuthVerifyScreen(
          correo: correo,
          titulo: context.t('edit.verif_titulo'),
          subtitulo: context.t('edit.verif_sub', {'correo': correo}),

          // Utilizar el endpoint específico para cambiar el correo.
          onVerificar: (codigo) async {
            final usuario = await _repo.verificarCambioCorreo(
              correo: correo,
              codigo: codigo,
            );

            await AuthState.instance.actualizarPerfil(usuario);

            return true;
          },

          // Cerrar únicamente la pantalla de verificación.
          onVerificacionExitosa: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );

    return resultado == true;
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    if (_cargandoFoto) return;

    try {
      final picker = ImagePicker();

      final imagen = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (imagen == null || !mounted) return;

      setState(() => _cargandoFoto = true);

      final esOriginal = await _esLaFotoOriginal(imagen);

      if (!mounted) return;

      setState(() {
        if (esOriginal) {
          _fotoSeleccionada = null;
          _eliminarFotoPendiente = false;
        } else {
          _fotoSeleccionada = imagen;
          _eliminarFotoPendiente = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esOriginal
                ? 'Es la misma fotografía. No hay cambios.'
                : 'Vista previa actualizada. Guarda para confirmar.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo seleccionar la foto: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cargandoFoto = false);
      }
    }
  }

  Future<void> _eliminarFoto() async {
    if (_cargandoFoto) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar fotografía'),
        content: const Text(
          'La fotografía se eliminará cuando guardes los cambios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Color(0xFFE5174D)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _fotoSeleccionada = null;
      _eliminarFotoPendiente = _orig.foto != null;
    });
  }



    
  Future<void> _guardar() async {
    if (!_validar()) return;

    setState(() => _cargando = true);

    try {
      final materno = _apellidoM.text.trim();
      final tel = _tel.text.trim();
      final correoNuevo = _correo.text.trim().toLowerCase();

      final fecha = _dia != null && _mes != null && _anio != null
    ? DateTime(_anio!, _mes!, _dia!)
    : null;

      final cambioCorreo =
          correoNuevo != _orig.correo.trim().toLowerCase();

      // Guardar los demás datos del perfil.
      final nuevo = await _repo.guardar(
        nombre: _nombre.text.trim(),
        apellido: _apellidoP.text.trim(),
        apellidoMaterno: materno.isEmpty ? null : materno,
        telefono: tel.isEmpty ? null : '+52$tel',
        fechaNacimiento: fecha,
      );
      await AuthState.instance.actualizarPerfil(nuevo);

      // Aplicar cambios pendientes de fotografía.
      if (_eliminarFotoPendiente) {
        await _repo.eliminarFotoPerfil();

        await AuthState.instance.actualizarFoto(null);
      } else if (_fotoSeleccionada != null) {
        final foto = await _repo.subirFotoPerfil(
          _fotoSeleccionada!.path,
        );

        if (foto == null || foto.isEmpty) {
          throw Exception('No se recibió la URL de la fotografía');
        }

        await AuthState.instance.actualizarFoto(foto);
      }

      if (!mounted) return;

      // Si el correo cambió, iniciar el proceso de verificación.
      if (cambioCorreo) {
        final verificado = await _iniciarCambioCorreo(correoNuevo);

        if (!mounted) return;

        if (!verificado) {
          setState(() => _cargando = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.t('edit.solo_datos'),
              ),
            ),
          );

          return;
        }
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            cambioCorreo
                ? context.t('edit.ok_correo')
                : context.t('edit.ok'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t('edit.err_guardar', {'detalle': textoError(context, error)}),
          ),
        ),
      );
    }
  }

  ImageProvider? _crearImagenOriginal() {
    debugPrint('FOTO ORIGINAL: ${_orig.foto}');
    
    final foto = _orig.foto;

    if (foto == null || foto.isEmpty) return null;

    final uri = Uri.tryParse(foto);

    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return NetworkImage(foto);
    }

    if (uri != null && uri.scheme == 'file') {
      return FileImage(File.fromUri(uri));
    }

    // Si es una ruta local sin esquema.
    return FileImage(File(foto));
  }


  @override
  Widget build(BuildContext context) {
    final anioActual = DateTime.now().year;
    final ac = context.aura;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('edit.titulo'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _cargandoFoto ? null : _abrirOpcionesFoto,
                child: Stack(
                  children: [
                    ListenableBuilder(
                      listenable: AuthState.instance,
                      builder: (context, child) {
                        ImageProvider? imagen;

                        if (_fotoSeleccionada != null) {
                          imagen = FileImage(File(_fotoSeleccionada!.path));
                        } else if (!_eliminarFotoPendiente) {
                          imagen = _crearImagenOriginal();
                        }

                        return CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.rosa,
                          backgroundImage: imagen,
                          child: imagen == null
                              ? Text(
                                  _orig.inicial,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                    
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ac.boton,
                          shape: BoxShape.circle,
                          border: Border.all(color: ac.fondo, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_outlined, size: 17, color: ac.textoBoton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AuthCampo(
              label: context.t('edit.nombre'),
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
                    label: context.t('edit.apellido_p'),
                    controller: _apellidoP,
                    errorText: _errApellido,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AuthCampo(
                    label: context.t('edit.apellido_m'),
                    controller: _apellidoM,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AuthCampo(
              label: context.t('edit.correo'),
              controller: _correo,
              errorText: _errCorreo,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                context.t('edit.correo_nota'),
                style: TextStyle(fontSize: 11, color: ac.textoSecundario),
              ),
            ),
            const SizedBox(height: 14),
            Text(context.t('edit.telefono'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PrefijoTelefono(),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _tel,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: decoracionCampo(
                      context,
                      errorText: _errTel,
                      relleno: PrefijoTelefono.relleno,
                      sinContador: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(context.t('edit.fecha'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _combo(
                    hint: context.t('edit.dia'),
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
                    hint: context.t('edit.mes'),
                    valor: _mes,
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text(nombreMes(m))),
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
                    hint: context.t('edit.anio'),
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
            texto: context.t('edit.guardar'),
            cargando: _cargando,
            onPressed: _hayCambios ? _guardar : null,
          ),
        ),
      ),
    );
  }

  void _abrirOpcionesFoto() {
    final tieneFoto = _fotoSeleccionada != null ||
    (_orig.foto != null && !_eliminarFotoPendiente);
    void proximamente(BuildContext ctx, String que) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('comun.proximamente', {'que': que}))),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.aura.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foto de perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(ctx.t('edit.foto'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(_orig.foto == null ? ctx.t('edit.foto_subir') : ctx.t('edit.foto_cambiar')),
                onTap: () => proximamente(ctx, ctx.t('edit.q_subir')),
                title: Text(
                  tieneFoto
                      ? 'Cambiar desde la galería'
                      : 'Subir desde la galería',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarFoto(ImageSource.gallery);
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(ctx.t('edit.foto_tomar')),
                onTap: () => proximamente(ctx, ctx.t('edit.q_tomar')),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarFoto(ImageSource.camera);
                },
              ),

              if (tieneFoto)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFE5174D),
                  ),
                  title: const Text(
                    'Eliminar foto',
                    style: TextStyle(
                      color: Color(0xFFE5174D),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _eliminarFoto();
                  },
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
    final ac = context.aura;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _errFecha != null ? Colors.red : ac.bordeCampo),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: valor,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(fontSize: 14, color: ac.textoSecundario)),
          style: TextStyle(fontSize: 14, color: ac.texto),
          dropdownColor: ac.superficie,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}