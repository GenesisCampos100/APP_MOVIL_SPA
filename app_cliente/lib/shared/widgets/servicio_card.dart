import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
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
                      Text(s.duracionTexto, style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                      const Spacer(),
                      // La estrella solo aparece si el servicio ya tiene reseñas.
                      if (s.rating > 0) ...[
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        Text(' ${s.rating}', style: const TextStyle(fontSize: 11, color: AppColors.gris)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${s.precioTexto} MXN',
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
