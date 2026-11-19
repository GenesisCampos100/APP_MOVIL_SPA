import 'package:flutter/material.dart';
import '../../core/i18n/textos.dart';
import '../../core/theme/aura_colores.dart';
import '../../core/utils/formato.dart';
import '../../data/models/servicio.dart';
import 'servicio_visual.dart';

/// Tarjeta del catálogo (Figura 12).
class ServicioCard extends StatelessWidget {
  final Servicio servicio;
  final VoidCallback onTap;
  const ServicioCard({super.key, required this.servicio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    final a = context.aura;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: a.superficie,
          border: Border.all(color: a.borde),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ServicioThumb(
                    categoria: s.categoria,
                    imagen: s.imagen,
                    radius: 0,
                    iconSize: 40,
                  ),
                  Positioned(right: 6, bottom: 6, child: CategoriaBadge(s.categoria)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(duracionLegible(s.minutos), style: TextStyle(fontSize: 11, color: a.textoSecundario)),
                      const Spacer(),
                      // La estrella solo aparece si el servicio ya tiene reseñas.
                      if (s.rating > 0) ...[
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        Text(' ${s.rating}', style: TextStyle(fontSize: 11, color: a.textoSecundario)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(context.t('comun.mxn', {'precio': s.precioTexto}),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
