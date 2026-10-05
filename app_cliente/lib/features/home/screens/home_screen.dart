import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/servicio.dart';
import '../../../data/repositories/servicios_repository.dart';
import '../../../shared/widgets/servicio_visual.dart';

// se llaman distinto (deben estar en assets/images/).
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
            _buscador(),
            const SizedBox(height: 14),
            _banner(),
            //const SizedBox(height: 16),
            //_titulo('Promociones'),
            const SizedBox(height: 8),
            const Row(
              children: [   // imagenes para la promocion hacia la propia app.
                Expanded(child: _Promo(imagen: kPromo1Imagen, icono: Icons.spa)),
                SizedBox(width: 12),
                Expanded(child: _Promo(imagen: kPromo2Imagen, icono: Icons.local_florist)),
              ],
            ),
            const SizedBox(height: 16),
            Center(child: _titulo('Categorías')),
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
                                c,
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
            _titulo('Servicios Destacados'),
            const SizedBox(height: 8),
            FutureBuilder<List<Servicio>>(
              future: _futuro,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Text('No se pudieron cargar los servicios');
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

  Widget _buscador() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            onTap: _irCatalogo,
            decoration: InputDecoration(
              hintText: 'Buscar.....',
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
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notificaciones: próximamente')),
          ),
          icon: const Icon(Icons.notifications_none, size: 28),
        ),
      ],
    );
  }

  /// Banner superior con la imagen/logo de Aura Spa.
  /// Si la imagen no existe, muestra el diseño anterior (degradado + texto).
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
                alignment: Alignment.center,
                child: Text(
                  'Aura Spa',
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
}

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
          color: AppColors.rosaSuave,
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

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          //El inicio use la imagen del servicio
          ServicioThumb(categoria: s.categoria, imagen: s.imagen, width: 120, height: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CategoriaBadge(s.categoria),
                    Text('Desde ${s.precioTexto}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(s.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(s.duracionTexto, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                    if (s.rating > 0) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' ${s.rating}', style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                    ],
                    const Spacer(),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(0, 28),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Reservar', style: TextStyle(fontSize: 11)),
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
