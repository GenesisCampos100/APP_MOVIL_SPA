import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Imagen del servicio. Si [imagen] es una ruta de assets (assets/images/...)
/// o una URL (http...), muestra la foto. Si no hay imagen o no se puede
/// cargar, muestra un degradado con ícono según la categoría.
class ServicioThumb extends StatelessWidget {
  final String categoria;
  final String? imagen;
  final double? width;
  final double? height;
  final double radius;
  final double iconSize;

  const ServicioThumb({
    super.key,
    required this.categoria,
    this.imagen,
    this.width,
    this.height,
    this.radius = 8,
    this.iconSize = 36,
  });

  static IconData iconoDe(String categoria) {
    switch (categoria) {
      case 'Corporal':
        return Icons.self_improvement;
      case 'Facial':
        return Icons.face_retouching_natural;
      case 'Manicure':
        return Icons.back_hand_outlined;
      case 'Aromaterapia':
        return Icons.water_drop_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  static List<Color> coloresDe(String categoria) {
    switch (categoria) {
      case 'Corporal':
        return const [Color(0xFF5B4636), Color(0xFFB98F6E)];
      case 'Facial':
        return const [Color(0xFFE8C9C0), Color(0xFFC99A94)];
      case 'Manicure':
        return const [Color(0xFFF2C4C9), Color(0xFFD98C97)];
      case 'Aromaterapia':
        return const [Color(0xFFC9B8A0), Color(0xFF8F7A5C)];
      default:
        return const [Color(0xFFD8C3B0), Color(0xFFA98B72)];
    }
  }

  Widget _degradado() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          colors: coloresDe(categoria),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(iconoDe(categoria), color: Colors.white, size: iconSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ruta = imagen;
    if (ruta == null || ruta.isEmpty) return _degradado();

    final foto = ruta.startsWith('http')
        ? Image.network(
            ruta,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _degradado(),
          )
        : Image.asset(
            ruta,
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _degradado(),
          );
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: foto);
  }
}

class CategoriaBadge extends StatelessWidget {
  final String texto;
  const CategoriaBadge(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.rosaSuave,
        border: Border.all(color: AppColors.rosaFuerte),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 10, color: AppColors.rosaFuerte)),
    );
  }
}
