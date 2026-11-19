import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/servicio.dart';
import '../../../data/repositories/favoritos_repository.dart';
import '../../../shared/widgets/boton_favorito.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../../auth/auth_state.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../widgets/resenas_seccion.dart';

/// Detalle del servicio: imagen grande, "Acerca del servicio" y reseñas.
/// La barra de abajo (nombre, precio, corazón y "Agregar") queda fija al
/// hacer scroll.
class ServiceDetailScreen extends StatelessWidget {
  final Servicio servicio;
  const ServiceDetailScreen({super.key, required this.servicio});

  Widget _imagen(double alto) => ServicioThumb(
        categoria: servicio.categoria,
        imagen: servicio.imagen,
        width: double.infinity,
        height: alto,
        radius: 20,
        iconSize: 80,
      );

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    final a = context.aura;
    // La imagen ocupa buen espacio, pero deja ver el título "Reseñas" abajo.
    final altoImagen = (MediaQuery.of(context).size.height * 0.27).clamp(180.0, 280.0);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          _imagen(altoImagen),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(context.tOr('cat.${s.categoria}', s.categoria),
                        style: TextStyle(fontSize: 12, color: a.textoSecundario)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (s.rating > 0) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        Text(' ${s.rating}', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  ListenableBuilder(
                    listenable: Listenable.merge([FavoritosRepository.instance, AuthState.instance]),
                    builder: (context, _) => BotonFavorito(
                      esFavorito: FavoritosRepository.instance.esFavoritoServicio(s.id),
                      size: 40,
                      onPressed: () => alternarFavoritoServicio(context, s),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: a.superficie,
              border: Border.all(color: a.borde),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('detalle.acerca'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  (s.descripcion == null || s.descripcion!.isEmpty)
                      ? context.t('detalle.sin_descripcion')
                      : s.descripcion!,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ResenasSeccion(idServicio: s.id),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: a.superficie,
          border: Border(top: BorderSide(color: a.borde)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${s.nombre} - ${context.tOr('cat.${s.categoria}', s.categoria)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(context.t('comun.mxn', {'precio': s.precioTexto}),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 12),
                          Text(duracionLegible(s.minutos),
                              style: TextStyle(fontSize: 13, color: a.textoSecundario)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.agendar, arguments: s),
                  style: FilledButton.styleFrom(
                    backgroundColor: a.boton,
                    foregroundColor: a.textoBoton,
                    minimumSize: const Size(110, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(context.t('detalle.agregar')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
