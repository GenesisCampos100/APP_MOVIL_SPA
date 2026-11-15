import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
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

void _aviso(BuildContext context, String texto, {SnackBarAction? accion}) {
  // Corazón lleno al agregar, corazón vacío al quitar.
  final icono = texto.startsWith('Agregado') ? Icons.favorite : Icons.favorite_border;
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
  _aviso(context, queda ? 'Agregado a favoritos' : 'Quitado de favoritos');
}

/// Corazón de un especialista.
Future<void> alternarFavoritoEmpleado(BuildContext context, Empleado e) async {
  if (!AuthState.instance.isLoggedIn) {
    final ok = await AuthFlow.iniciar(context);
    if (!ok || !context.mounted) return;
  }
  final queda = FavoritosRepository.instance.alternarEmpleado(e);
  _aviso(context, queda ? 'Agregado a favoritos' : 'Quitado de favoritos');
}

/// Favoritos: dos listas, Servicios y Especialistas. El corazón lleno de cada
/// fila los quita (con "Deshacer").
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const _tabs = ['Servicios', 'Especialistas'];
  String _tab = 'Servicios';

  @override
  Widget build(BuildContext context) {
    final repo = FavoritosRepository.instance;
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final servicios = repo.servicios;
        final empleados = repo.empleados;
        final cantidades = {'Servicios': servicios.length, 'Especialistas': empleados.length};

        return Scaffold(
          appBar: AppBar(
            title: const Text('Favoritos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                              color: f == _tab ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: f == _tab ? Colors.black : Colors.black26),
                            ),
                            child: Text(
                              cantidades[f]! > 0 ? '$f · ${cantidades[f]}' : f,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: f == _tab ? Colors.white : AppColors.gris,
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
                child: _tab == 'Servicios'
                    ? _listaServicios(servicios)
                    : _listaEmpleados(empleados),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _listaServicios(List<Servicio> lista) {
    if (lista.isEmpty) {
      return const _Vacio(
        titulo: 'Sin servicios favoritos',
        mensaje: 'Toca el corazón en el detalle de un servicio para guardarlo aquí.',
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

  Widget _listaEmpleados(List<Empleado> lista) {
    if (lista.isEmpty) {
      return const _Vacio(
        titulo: 'Sin especialistas favoritos',
        mensaje: 'Toca el corazón al elegir a tu especialista para guardarlo aquí.',
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
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.detalle, arguments: s),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE3E3E3)),
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
                      Text('${s.precioTexto} MXN',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      Text(s.duracionTexto,
                          style: const TextStyle(fontSize: 12, color: AppColors.gris)),
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
                  'Quitado de favoritos',
                  accion: SnackBarAction(
                    label: 'Deshacer',
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E3E3)),
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
                Text(e.puesto, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
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
                'Quitado de favoritos',
                accion: SnackBarAction(
                  label: 'Deshacer',
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.rosaSuave,
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
                style: const TextStyle(fontSize: 14, color: AppColors.gris)),
          ],
        ),
      ),
    );
  }
}
