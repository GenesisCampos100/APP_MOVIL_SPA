import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/servicio.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../widgets/resenas_seccion.dart';

/// Detalle del servicio: imagen grande, "Acerca del servicio" y reseñas.
/// La barra de abajo (nombre, precio y "Agregar") queda fija al hacer scroll.
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
                    Text(s.categoria, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                  ],
                ),
              ),
              if (s.rating > 0)
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    Text(' ${s.rating}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE3E3E3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Acerca del servicio',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  (s.descripcion == null || s.descripcion!.isEmpty)
                      ? 'Este servicio aún no tiene descripción.'
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE3E3E3))),
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
                        '${s.nombre} - ${s.categoria}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${s.precioTexto} MXN',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 12),
                          Text(s.duracionTexto,
                              style: const TextStyle(fontSize: 13, color: AppColors.gris)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.agendar, arguments: s),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(110, 42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
