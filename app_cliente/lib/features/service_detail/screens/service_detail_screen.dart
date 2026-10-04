import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/servicio.dart';
import '../../../shared/widgets/servicio_visual.dart';

/// Detalle de servicio (14.4.3). Variantes y reseñas se agregan después.
class ServiceDetailScreen extends StatelessWidget {
  final Servicio servicio;
  const ServiceDetailScreen({super.key, required this.servicio});

  @override
  Widget build(BuildContext context) {
    final s = servicio;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del servicio')),
      body: ListView(
        children: [
          ServicioThumb(categoria: s.categoria, height: 220, radius: 0, iconSize: 72),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoriaBadge(s.categoria),
                const SizedBox(height: 8),
                Text(s.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(s.duracionTexto, style: const TextStyle(color: AppColors.gris)),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    Text(' ${s.rating}', style: const TextStyle(color: AppColors.gris)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${s.precioTexto} MXN',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('Pendiente: selector de variantes y reseñas (CU-20, CU-24).',
                    style: TextStyle(color: AppColors.gris)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.reservar, arguments: s),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Reservar'),
          ),
        ),
      ),
    );
  }
}
