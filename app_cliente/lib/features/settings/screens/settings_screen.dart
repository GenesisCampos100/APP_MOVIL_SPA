import 'package:flutter/material.dart';
import '../../../core/i18n/idioma_state.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../auth/auth_state.dart';
import '../ajustes_state.dart';
import 'change_password_screen.dart';

const Color _rojo = Color(0xFFE5174D);

/// Abre la pantalla de Configuración (desde el Perfil).
void abrirConfiguracion(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}

/// Abre el selector de idioma (fila del idioma en el Perfil).
void abrirIdioma(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ListenableBuilder(
      listenable: IdiomaState.instance,
      builder: (ctx, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ctx.t('idioma.titulo'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _OpcionIdioma(codigo: 'es', nombre: 'Español', cerrar: () => Navigator.pop(ctx)),
              _OpcionIdioma(codigo: 'en', nombre: 'English', cerrar: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _OpcionIdioma extends StatelessWidget {
  final String codigo;
  final String nombre;
  final VoidCallback cerrar;
  const _OpcionIdioma({required this.codigo, required this.nombre, required this.cerrar});

  @override
  Widget build(BuildContext context) {
    final elegido = IdiomaState.instance.codigo == codigo;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language),
      title: Text(nombre),
      trailing: elegido ? const Icon(Icons.check, color: AppColors.rosaFuerte) : null,
      onTap: () {
        IdiomaState.instance.cambiar(codigo);
        cerrar();
      },
    );
  }
}

/// Configuración: preferencias de notificaciones, cuenta, legal y
/// eliminar cuenta.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final correo = AuthState.instance.usuario?.correo ?? '';

    return Scaffold(
      backgroundColor: c.fondo,
      appBar: AppBar(
        title: Text(context.t('config.titulo'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: AjustesState.instance,
        builder: (context, _) {
          final ajustes = AjustesState.instance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _Seccion(
                titulo: context.t('config.notificaciones'),
                filas: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    secondary: Icon(Icons.alarm, color: c.texto),
                    title: Text(context.t('config.recordatorios'),
                        style: const TextStyle(fontSize: 15)),
                    subtitle: Text(context.t('config.recordatorios_sub'),
                        style: TextStyle(fontSize: 12, color: c.textoSecundario)),
                    value: ajustes.recordatorios,
                    onChanged: ajustes.setRecordatorios,
                  ),
                ],
              ),
              _Seccion(
                titulo: context.t('config.cuenta'),
                filas: [
                  _Fila(
                    icono: Icons.mail_outline,
                    texto: context.t('config.correo'),
                    valor: correo,
                  ),
                  _Fila(
                    icono: Icons.lock_outline,
                    texto: context.t('config.cambiar_contrasena'),
                    onTap: () => abrirCambiarContrasena(context),
                  ),
                ],
              ),
              _Seccion(
                titulo: context.t('config.legal'),
                filas: [
                  _Fila(
                    icono: Icons.privacy_tip_outlined,
                    texto: context.t('config.privacidad'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _TextoScreen(claveTitulo: 'config.privacidad'),
                      ),
                    ),
                  ),
                  _Fila(
                    icono: Icons.description_outlined,
                    texto: context.t('config.terminos'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _TextoScreen(claveTitulo: 'config.terminos'),
                      ),
                    ),
                  ),
                ],
              ),
              _Seccion(
                titulo: '',
                filas: [
                  _Fila(
                    icono: Icons.delete_outline,
                    texto: context.t('config.eliminar_cuenta'),
                    color: _rojo,
                    flecha: false,
                    onTap: () => _confirmarEliminar(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(context.t('config.version'),
                    style: TextStyle(fontSize: 11, color: c.textoSecundario)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.aura;
        return Dialog(
          backgroundColor: c.superficie,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ctx.t('config.eliminar_pregunta'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  ctx.t('config.eliminar_aviso'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: c.textoSecundario),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.boton,
                          foregroundColor: c.textoBoton,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(ctx.t('comun.cancelar')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: _rojo,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(ctx.t('config.eliminar')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmar != true || !context.mounted) return;

    // DEMOSTRACIÓN: solo cierra la sesión. Con la API sería DELETE /cuenta,
    // que desactiva la cuenta (usuarios.estado = false).
    final messenger = ScaffoldMessenger.of(context);
    final mensaje = context.t('config.cuenta_eliminada');
    AuthState.instance.cerrarSesion();
    Navigator.popUntil(context, ModalRoute.withName(AppRoutes.shell));
    messenger.showSnackBar(SnackBar(content: Text(mensaje)));
  }
}

/// Título gris + tarjeta con borde que agrupa varias filas.
class _Seccion extends StatelessWidget {
  final String titulo;
  final List<Widget> filas;
  const _Seccion({required this.titulo, required this.filas});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final contenido = <Widget>[];
    for (var i = 0; i < filas.length; i++) {
      if (i > 0) contenido.add(Divider(height: 1, color: c.borde));
      contenido.add(filas[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
              child: Text(titulo,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: c.textoSecundario)),
            ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.superficie,
              border: Border.all(color: c.borde),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: contenido),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? valor; // texto gris a la derecha (sin flecha)
  final VoidCallback? onTap;
  final Color? color;
  final bool flecha;

  const _Fila({
    required this.icono,
    required this.texto,
    this.valor,
    this.onTap,
    this.color,
    this.flecha = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icono, size: 22, color: color ?? c.texto),
            const SizedBox(width: 18),
            Text(
              texto,
              style: TextStyle(
                fontSize: 15,
                color: color ?? c.texto,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (valor != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  valor!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.textoSecundario),
                ),
              ),
            ] else
              const Spacer(),
            if (flecha && valor == null) Icon(Icons.chevron_right, size: 20, color: c.texto),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de texto simple para Política de privacidad y Términos.
class _TextoScreen extends StatelessWidget {
  final String claveTitulo;
  const _TextoScreen({required this.claveTitulo});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final titulo = context.t(claveTitulo);
    return Scaffold(
      backgroundColor: c.fondo,
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.t('config.texto_pendiente', {'titulo': titulo}),
            style: TextStyle(fontSize: 14, height: 1.4, color: c.textoSecundario),
          ),
        ],
      ),
    );
  }
}
