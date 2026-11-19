import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/api_config.dart';

/// Las rutas guardadas en PostgreSQL son relativas al servidor, no al teléfono.
class ServiceImagePreview extends StatelessWidget {
  const ServiceImagePreview({super.key, this.imagen, this.size = 64});
  final String? imagen;
  final double size;

  static String? resolverUrl(String? imagen) {
    final valor = imagen?.trim() ?? '';
    if (valor.isEmpty) return null;
    final uri = Uri.tryParse(valor);
    if (uri == null) return null;
    if (uri.hasScheme) {
      if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty) return valor;
      return null;
    }
    if (!RegExp(r'^/uploads/servicios/[a-zA-Z0-9-]+\.(jpg|png|webp)$').hasMatch(valor)) {
      return null;
    }
    return Uri.parse(ApiConfig.baseUrl).replace(path: valor).toString();
  }

  @override
  Widget build(BuildContext context) {
    final url = resolverUrl(imagen);
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: size, height: size,
        color: AdminVisual.primaryPinkSoft,
        child: url == null
            ? const Icon(Icons.spa_outlined, color: AppColors.primaryPink)
            : Image.network(
                url,
                width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const Icon(Icons.image_not_supported_outlined, color: AppColors.primaryPink),
              ),
      ),
    );
  }
}
