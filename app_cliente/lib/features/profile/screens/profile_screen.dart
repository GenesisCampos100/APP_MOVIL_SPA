import 'package:flutter/material.dart';
import '../../../core/i18n/idioma_state.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../data/models/usuario_sesion.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../auth/auth_state.dart';
import '../../auth/screens/auth_email_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/screens/tema_sheet.dart';
import 'edit_profile_screen.dart';

// Color del botón "Cerrar sesión" del mockup del perfil.
const Color _rojoSesion = Color(0xFFD98C97);

/// Sin sesión: muestra el inicio de sesión. Con sesión: muestra el perfil.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState.instance,
      builder: (context, _) {
        final u = AuthState.instance.usuario;
        if (u == null) return const AuthEmailScreen(embebido: true);
        return _PerfilConSesion(usuario: u);
      },
    );
  }
}

class _PerfilConSesion extends StatelessWidget {
  final UsuarioSesion usuario;
  const _PerfilConSesion({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;

    Future<void> confirmarCerrarSesion() async {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final cc = ctx.aura;
          return Dialog(
            backgroundColor: cc.superficie,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ctx.t('perfil.cerrar_pregunta'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: FilledButton.styleFrom(
                            backgroundColor: cc.boton,
                            foregroundColor: cc.textoBoton,
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
                            backgroundColor: _rojoSesion,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(ctx.t('perfil.cerrar_sesion')),
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
      if (confirmar == true) {
        await AuthState.instance.cerrarSesion();
      }
    }

    return Scaffold(
      backgroundColor: c.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Center(child: _Avatar(usuario: usuario)),
            const SizedBox(height: 14),
            Center(
              child: Text(
                usuario.nombreCompleto,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 28),
            _Tarjeta(children: [
              _FilaMenu(
                icono: Icons.person_outline,
                texto: context.t('perfil.mi_perfil'),
                onTap: () => abrirMiPerfil(context),
              ),
              _FilaMenu(
                icono: Icons.favorite_border,
                texto: context.t('perfil.favoritos'),
                onTap: () => abrirFavoritos(context),
              ),
              _FilaMenu(
                icono: Icons.calendar_today_outlined,
                texto: context.t('perfil.mis_citas'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentsScreen(conAtras: true)),
                ),
              ),
              _FilaMenu(
                icono: Icons.notifications_none,
                texto: context.t('perfil.notificaciones'),
                onTap: () => abrirNotificaciones(context),
              ),
            ]),
            const SizedBox(height: 14),
            _Tarjeta(children: [
              _FilaMenu(
                icono: Icons.settings_outlined,
                texto: context.t('perfil.configuracion'),
                onTap: () => abrirConfiguracion(context),
              ),
              _FilaMenu(
                icono: Icons.language,
                texto: IdiomaState.instance.nombre,
                onTap: () => abrirIdioma(context),
              ),
              _FilaMenu(
                icono: Icons.brightness_6_outlined,
                texto: context.t('perfil.tema'),
                onTap: () => abrirTema(context),
              ),
            ]),
            const SizedBox(height: 14),
            _Tarjeta(children: [
              _FilaMenu(
                icono: Icons.logout,
                texto: context.t('perfil.cerrar_sesion'),
                color: _rojoSesion,
                flecha: false,
                onTap: confirmarCerrarSesion,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Foto de perfil circular. Si no hay foto, muestra la inicial del nombre.
class _Avatar extends StatelessWidget {
  final UsuarioSesion usuario;
  const _Avatar({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final foto = usuario.foto;
    return CircleAvatar(
      radius: 56,
      backgroundColor: AppColors.rosa,
      backgroundImage: foto != null ? NetworkImage(foto) : null,
      child: foto == null
          ? Text(
              usuario.inicial,
              style: const TextStyle(
                fontSize: 44,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
    );
  }
}

/// Tarjeta con borde suave y esquinas redondeadas.
class _Tarjeta extends StatelessWidget {
  final List<Widget> children;
  const _Tarjeta({required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.superficie,
        border: Border.all(color: c.borde),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _FilaMenu extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onTap;
  final Color? color;
  final bool flecha;

  const _FilaMenu({
    required this.icono,
    required this.texto,
    required this.onTap,
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
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 15,
                  color: color ?? c.texto,
                  fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (flecha) Icon(Icons.chevron_right, size: 20, color: c.texto),
          ],
        ),
      ),
    );
  }
}
