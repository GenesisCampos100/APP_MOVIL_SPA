import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/notificacion.dart';
import '../../../data/repositories/notificaciones_repository.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';
import '../../shell/shell_controller.dart';

const Color _rojo = Color(0xFFE5174D);
const Color _verde = Color(0xFF4CAF50);

/// Abre las notificaciones desde cualquier parte (campana del Inicio o Perfil).
/// Si no hay sesión, primero pide iniciar sesión.
Future<void> abrirNotificaciones(BuildContext context) async {
  if (!AuthState.instance.isLoggedIn) {
    final ok = await AuthFlow.iniciar(context);
    if (!ok || !context.mounted) return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
  );
}

/// Lista de notificaciones del ciclo de una cita:
/// registrada -> confirma tu cita (24 h antes) -> confirmada / cancelada
///  - Deslizar una hacia un lado la elimina (con "Deshacer").
///  - El ícono de basura limpia todas (con confirmación).
///  - "Confirma tu cita" no se puede borrar hasta que se confirme.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final repo = NotificacionesRepository.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      repo.cargar().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final items = repo.items;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.t('noti.titulo'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: context.t('noti.limpiar_todo'),
                  onPressed: () => _confirmarLimpiar(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              const SizedBox(width: 4),
            ],
          ),
          body: _contenido(),
        );
      },
    );
  }

  Widget _contenido() {
    if (repo.cargando) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (repo.errorCarga != null && repo.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: AppColors.gris,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudieron cargar las notificaciones.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => repo.cargar().catchError((_) {}),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (repo.items.isEmpty) {
      return const _Vacio();
    }

    return _Lista(
      items: repo.items,
      noLeidas: repo.noLeidas,
    );
  }


  Future<void> _confirmarLimpiar(BuildContext context) async {
    final hayPendientes = NotificacionesRepository.instance.hayPendientes;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.aura.superficie,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctx.t('noti.limpiar_pregunta'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (hayPendientes) ...[
                const SizedBox(height: 8),
                Text(
                  ctx.t('noti.limpiar_conservan'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: ctx.aura.textoSecundario),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: FilledButton.styleFrom(
                        backgroundColor: ctx.aura.boton,
                        foregroundColor: ctx.aura.textoBoton,
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
                      child: Text(ctx.t('noti.limpiar')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmar == true) NotificacionesRepository.instance.limpiarTodo();
  }
}

class _Lista extends StatelessWidget {
  final List<Notificacion> items;
  final int noLeidas;
  const _Lista({required this.items, required this.noLeidas});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (noLeidas > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
            child: Row(
              children: [
                Text(context.t('noti.sin_leer', {'n': '$noLeidas'}),
                    style: TextStyle(fontSize: 12, color: context.aura.textoSecundario)),
                const Spacer(),
                TextButton(
                  onPressed: NotificacionesRepository.instance.marcarTodasLeidas,
                  child: Text(context.t('noti.marcar_leidas'),
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        for (final n in items) _Tarjeta(notificacion: n),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Notificacion notificacion;
  const _Tarjeta({required this.notificacion});

  static IconData _icono(String tipo) {
    switch (tipo) {
      case Notificacion.citaCreada:
        return Icons.event_available;
      case Notificacion.confirmarCita:
        return Icons.alarm;
      case Notificacion.citaConfirmada:
        return Icons.check_circle_outline;
      case Notificacion.citaCancelada:
        return Icons.event_busy_outlined;
      case Notificacion.resena:
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications_none;
    }
  }

  static Color _color(String tipo) {
    switch (tipo) {
      case Notificacion.citaConfirmada:
        return _verde;
      case Notificacion.citaCancelada:
        return _rojo;
      default:
        return AppColors.rosaFuerte;
    }
  }

  /// Título y mensaje en el idioma elegido. Si la notificación trae datos
  /// (servicio, hora) se arma con el diccionario; si no, se muestra el texto
  /// tal como llega de la base de datos.
  static String _titulo(BuildContext context, Notificacion n) {
    final clave = 'noti.t.${n.tipo}';
    final traducido = context.tOr(clave, '');
    if (n.datos.isEmpty || traducido.isEmpty) {
      // Sin datos: solo el título genérico del tipo si existe y el texto no vino de la BD.
      return n.titulo.isNotEmpty ? n.titulo : context.t(clave);
    }
    return traducido;
  }

  static String _mensaje(BuildContext context, Notificacion n) {
    if (n.datos.isEmpty) return n.mensaje;
    final variante = n.datos['variante'];
    final clave = (n.tipo == Notificacion.citaConfirmada && variante == 'manual')
        ? 'noti.m.cita_confirmada_manual'
        : 'noti.m.${n.tipo}';
    final hora = n.datos['hora'];
    return context.t(clave, {
      'servicio': n.datos['servicio'] ?? '',
      'hora': hora == null ? '' : hora12(hora),
    });
  }

  Widget _fondoBorrar(AlignmentGeometry alineacion) => Container(
        color: _rojo,
        alignment: alineacion,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      );

  void _abrir(BuildContext context) {
    final n = notificacion;
    NotificacionesRepository.instance.marcarLeida(n.id);
    if (n.idCita != null) {
      // Las notificaciones de citas llevan a la pestaña "Citas".
      ShellController.irA(2);
      Navigator.popUntil(context, ModalRoute.withName(AppRoutes.shell));
    }
  }

  void _confirmar(BuildContext context) {
    NotificacionesRepository.instance.confirmarAsistencia(notificacion.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.t('noti.cita_confirmada'))));
  }


  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final repo = NotificacionesRepository.instance;
    final color = _color(n.tipo);
    final pendiente = n.requiereAccion;
    final a = context.aura;

    return Dismissible(
      key: ValueKey(n.id),
      // Una "Confirma tu cita" pendiente no se puede borrar deslizando.
      direction: pendiente ? DismissDirection.none : DismissDirection.horizontal,
      background: _fondoBorrar(Alignment.centerLeft),
      secondaryBackground: _fondoBorrar(Alignment.centerRight),
      onDismissed: (_) {
        repo.eliminar(n.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.t('noti.eliminada')),
              action: SnackBarAction(
                label: context.t('comun.deshacer'),
                onPressed: () => repo.restaurar(n),
              ),
            ),
          );
      },
      child: InkWell(
        onTap: () => _abrir(context),
        child: Container(
          color: n.leida ? a.fondo : a.rosaSuave.withValues(alpha: 0.6),
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icono(n.tipo), size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titulo(context, n),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: n.leida ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _mensaje(context, n),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, height: 1.3, color: a.textoSecundario),
                    ),
                    const SizedBox(height: 6),
                    Text(tiempoRelativo(n.fechaEnvio),
                        style: TextStyle(fontSize: 11, color: a.textoSecundario)),
                    if (pendiente) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: () async => await _confirmar(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: a.boton,
                            foregroundColor: a.textoBoton,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(context.t('noti.confirmar_cita'),
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ] else if (n.tipo == Notificacion.confirmarCita && n.atendida) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: _verde),
                          const SizedBox(width: 4),
                          Text(context.t('noti.cita_confirmada'),
                              style: const TextStyle(fontSize: 11, color: _verde)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!n.leida)
                Container(
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.rosaFuerte,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    final a = context.aura;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: a.rosaSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none, size: 56, color: AppColors.rosaFuerte),
            ),
            const SizedBox(height: 24),
            Text(context.t('noti.vacio_t'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              context.t('noti.vacio_m'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: a.textoSecundario),
            ),
          ],
        ),
      ),
    );
  }
}
