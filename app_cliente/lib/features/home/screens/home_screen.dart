import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/servicio.dart';
import '../../../data/repositories/servicios_repository.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../../notifications/screens/notifications_screen.dart';

// ---------------------------------------------------------------
// Imágenes del Inicio: cambia aquí los nombres si tus archivos
// se llaman distinto (deben estar en assets/images/).
// ---------------------------------------------------------------
const String kBannerImagen = 'assets/images/banner_home.jpg';
const String kPromo1Imagen = 'assets/images/promo1.jpg';
const String kPromo2Imagen = 'assets/images/promo2.jpg';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = ServiciosRepository();
  late final Future<List<Servicio>> _futuro = _repo.obtenerServicios();

  void _irCatalogo([String? categoria]) =>
      Navigator.pushNamed(context, AppRoutes.catalogo, arguments: categoria);

  void _irDetalle(Servicio s) =>
      Navigator.pushNamed(context, AppRoutes.detalle, arguments: s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _buscador(context),
            const SizedBox(height: 14),
            _banner(),
            const SizedBox(height: 16),
            _titulo(context.t('home.promociones')),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: _Promo(imagen: kPromo1Imagen, icono: Icons.spa)),
                SizedBox(width: 12),
                Expanded(child: _Promo(imagen: kPromo2Imagen, icono: Icons.local_florist)),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _titulo(context.t('home.categorias'))),
            const SizedBox(height: 10),
            // Categorías: se desliza hacia la izquierda para ver las demás.
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in const ['Facial', 'Corporal', 'Manicure', 'Aromaterapia', 'Pedicure'])
                    SizedBox(
                      width: 84,
                      child: InkWell(
                        onTap: () => _irCatalogo(c),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                          child: Column(
                            children: [
                              Icon(ServicioThumb.iconoDe(c), size: 42, color: AppColors.rosaFuerte),
                              const SizedBox(height: 4),
                              Text(
                                context.tOr('cat.$c', c),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _titulo(context.t('home.destacados')),
            const SizedBox(height: 8),
            FutureBuilder<List<Servicio>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Text(context.t('home.error'));
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final destacados = snap.data!.where((s) => s.destacado);
                return Column(
                  children: [
                    for (final s in destacados) ...[
                      _DestacadoTile(servicio: s, onTap: () => _irDetalle(s)),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) =>
      Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500));

  Widget _buscador(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            onTap: _irCatalogo,
            decoration: InputDecoration(
              hintStyle: TextStyle(color: context.aura.textoSecundario),
              hintText: context.t('home.buscar'),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.gris),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: _irCatalogo, icon: const Icon(Icons.search, size: 28)),
        IconButton(
          onPressed: () => abrirNotificaciones(context),
          icon: const Icon(Icons.notifications_none, size: 28),
        ),
      ],
    );
  }

  /// Banner superior: tu imagen como fondo + el título "Aura Spa" encima.
  Widget _banner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 130,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo: tu imagen (si falta, se ve un degradado rosa)
            Image.asset(
              kBannerImagen,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF7C6CC), Color(0xFFE8A9B3)],
                  ),
                ),
              ),
            ),
            // Capa oscura suave para que el texto se lea sobre cualquier foto
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.black38, Colors.transparent],
                ),
              ),
            ),
            // Título
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aura Spa', // nombre de la marca: no se traduce
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} // <-- esta llave cierra la clase _HomeScreenState

/// Imagen de promoción (diseño propio). Si falta el archivo, muestra un
/// recuadro de color con un ícono para que la app no se rompa.
class _Promo extends StatelessWidget {
  final String imagen;
  final IconData icono;
  const _Promo({required this.imagen, required this.icono});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        imagen,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stack) => Container(
          height: 100,
          color: context.aura.rosaSuave,
          child: Icon(icono, size: 44, color: AppColors.rosaFuerte),
        ),
      ),
    );
  }
}

class _DestacadoTile extends StatelessWidget {
  final Servicio servicio;
  final VoidCallback onTap;
  const _DestacadoTile({required this.servicio, required this.onTap});

  /// Cada dato va en su propia línea para que nada se encime, aunque la
  /// categoría sea larga ("Tratamientos faciales") o el celular tenga el
  /// texto agrandado:
  ///   categoría
  ///   nombre del servicio
  ///   Desde $precio
  ///   duración · estrella ............ [Reservar]
  @override
  Widget build(BuildContext context) {
    final s = servicio;
    final a = context.aura;
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServicioThumb(categoria: s.categoria, imagen: s.imagen, width: 120, height: 120),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoriaBadge(s.categoria),
                const SizedBox(height: 6),
                Text(
                  s.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  context.t('home.desde', {'precio': s.precioTexto}),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              duracionLegible(s.minutos),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: a.textoSecundario),
                            ),
                          ),
                          if (s.rating > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(' ${s.rating}',
                                style: TextStyle(fontSize: 12, color: a.textoSecundario)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: a.boton,
                        foregroundColor: a.textoBoton,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(context.t('home.reservar'),
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
