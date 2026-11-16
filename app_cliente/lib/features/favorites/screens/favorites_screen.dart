import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/empleado.dart';
import '../../../data/models/servicio.dart';
import '../../../data/repositories/favoritos_repository.dart';
import '../../../shared/widgets/boton_favorito.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';

/// Abre Favoritos (si no hay sesión, primero pide iniciar sesión).
Future<void> abrirFavoritos(BuildContext context) async {
  if (!AuthState.instance.isLoggedIn) {
    final ok = await AuthFlow.iniciar(context);
    if (!ok || !context.mounted) return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FavoritesScreen()),
  );
}

void _aviso(BuildContext context, {required bool agregado, SnackBarAction? accion}) {
  // Corazón lleno al agregar, corazón vacío al quitar.
  final icono = agregado ? Icons.favorite : Icons.favorite_border;
  final texto = context.t(agregado ? 'fav.agregado' : 'fav.quitado');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, size: 18, color: AppColors.rosa),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
        action: accion,
      ),
    );
}

/// Corazón de un servicio. Si no hay sesión, pide iniciar sesión primero
/// y después lo agrega.
Future<void> alternarFavoritoServicio(BuildContext context, Servicio s) async {
  if (!AuthState.instance.isLoggedIn) {
    final ok = await AuthFlow.iniciar(context);
    if (!ok || !context.mounted) return;
  }
  final queda = FavoritosRepository.instance.alternarServicio(s);
  _aviso(context, agregado: queda);
}

/// Corazón de un especialista.
Future<void> alternarFavoritoEmpleado(BuildContext context, Empleado e) async {
  if (!AuthState.instance.isLoggedIn) {
    final ok = await AuthFlow.iniciar(context);
    if (!ok || !context.mounted) return;
  }
  final queda = FavoritosRepository.instance.alternarEmpleado(e);
  _aviso(context, agregado: queda);
}

/// Favoritos: dos listas, Servicios y Especialistas. El corazón lleno de cada
/// fila los quita (con "Deshacer").
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _tabs = ['servicios', 'especialistas'];
  String _tab = 'servicios';

  @override
  Widget build(BuildContext context) {
    final repo = FavoritosRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final servicios = repo.servicios;
        final empleados = repo.empleados;
        final cantidades = {'servicios': servicios.length, 'especialistas': empleados.length};
        final a = context.aura;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.t('fav.titulo'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    for (final f in _tabs) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: f == _tab ? a.boton : a.superficie,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: f == _tab ? a.boton : a.borde),
                            ),
                            child: Text(
                              cantidades[f]! > 0
                                  ? '${context.t('fav.$f')} · ${cantidades[f]}'
                                  : context.t('fav.$f'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: f == _tab ? a.textoBoton : a.textoSecundario,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (f != _tabs.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _tab == 'servicios'
                    ? _listaServicios(context, servicios)
                    : _listaEmpleados(context, empleados),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _listaServicios(BuildContext context, List<Servicio> lista) {
    if (lista.isEmpty) {
      return _Vacio(
        titulo: context.t('fav.vacio_serv_t'),
        mensaje: context.t('fav.vacio_serv_m'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        for (final s in lista) ...[
          _FilaServicio(servicio: s),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _listaEmpleados(BuildContext context, List<Empleado> lista) {
    if (lista.isEmpty) {
      return _Vacio(
        titulo: context.t('fav.vacio_esp_t'),
        mensaje: context.t('fav.vacio_esp_m'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        for (final e in lista) ...[
          _FilaEmpleado(empleado: e),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _FilaServicio extends StatelessWidget {
  final Servicio servicio;
  const _FilaServicio({required this.servicio});

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    final a = context.aura;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.detalle, arguments: s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: a.superficie,
          border: Border.all(color: a.borde),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ServicioThumb(
              categoria: s.categoria,
              imagen: s.imagen,
              width: 84,
              height: 68,
              radius: 10,
              iconSize: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  CategoriaBadge(s.categoria),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(context.t('comun.mxn', {'precio': s.precioTexto}),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Text(duracionLegible(s.minutos),
                          style: TextStyle(fontSize: 12, color: a.textoSecundario)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BotonFavorito(
              esFavorito: true,
              size: 38,
              onPressed: () {
                final repo = FavoritosRepository.instance;
                repo.alternarServicio(s);
                _aviso(
                  context,
                  agregado: false,
                  accion: SnackBarAction(
                    label: context.t('comun.deshacer'),
                    onPressed: () => repo.alternarServicio(s),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaEmpleado extends StatelessWidget {
  final Empleado empleado;
  const _FilaEmpleado({required this.empleado});

  @override
  Widget build(BuildContext context) {
    final e = empleado;
    final foto = e.foto;
    final a = context.aura;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: a.superficie,
        border: Border.all(color: a.borde),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.rosa,
            backgroundImage: foto != null ? NetworkImage(foto) : null,
            child: foto == null
                ? Text(e.inicial,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nombreCompleto,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(e.puesto, style: TextStyle(fontSize: 12, color: a.textoSecundario)),
                if (e.rating > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' ${e.rating}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          BotonFavorito(
            esFavorito: true,
            size: 38,
            onPressed: () {
              final repo = FavoritosRepository.instance;
              repo.alternarEmpleado(e);
              _aviso(
                context,
                agregado: false,
                accion: SnackBarAction(
                  label: context.t('comun.deshacer'),
                  onPressed: () => repo.alternarEmpleado(e),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String titulo;
  final String mensaje;
  const _Vacio({required this.titulo, required this.mensaje});

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
              child: const Icon(Icons.favorite_border, size: 56, color: AppColors.rosaFuerte),
            ),
            const SizedBox(height: 24),
            Text(titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: a.textoSecundario)),
          ],
        ),
      ),
    );
  }
}
